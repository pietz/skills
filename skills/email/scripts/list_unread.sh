#!/usr/bin/env bash
set -euo pipefail

# Find the Mail database (version may vary: V9, V10, V11, etc.)
MAIL_DB=$(find "$HOME/Library/Mail" -name "Envelope Index" -path "*/MailData/*" -type f 2>/dev/null | head -1)

if [[ -z "$MAIL_DB" || ! -f "$MAIL_DB" ]]; then
  echo "Mail database not found. Falling back to AppleScript." >&2
  osascript - <<'APPLESCRIPT'
tell application "Mail"
    set unreadMsgs to (messages of inbox whose read status is false)
    set output to "Unread: " & (count of unreadMsgs) & linefeed & linefeed
    repeat with msg in unreadMsgs
        set output to output & "ID: " & (id of msg) & " | " & (subject of msg) & linefeed
        set output to output & "From: " & (sender of msg) & linefeed & "---" & linefeed
    end repeat
    return output
end tell
APPLESCRIPT
  exit 0
fi

# Count unread messages (inbox only - unread in archive doesn't make sense)
count=$(sqlite3 "$MAIL_DB" "
SELECT COUNT(*)
FROM messages m
JOIN mailboxes mb ON m.mailbox = mb.ROWID
WHERE m.read = 0
  AND m.deleted = 0
  AND (mb.url LIKE '%/Inbox' OR mb.url LIKE '%/INBOX');
")

echo "Unread: $count"
echo ""

sqlite3 -separator '|' "$MAIL_DB" "
SELECT
    m.ROWID,
    s.subject,
    a.address,
    a.comment
FROM messages m
JOIN subjects s ON m.subject = s.ROWID
JOIN addresses a ON m.sender = a.ROWID
JOIN mailboxes mb ON m.mailbox = mb.ROWID
WHERE m.read = 0
  AND m.deleted = 0
  AND (mb.url LIKE '%/Inbox' OR mb.url LIKE '%/INBOX')
ORDER BY m.date_received DESC;
" | while IFS='|' read -r id subject sender_addr sender_name; do
  # Format sender
  if [[ -n "$sender_name" && "$sender_name" != "$sender_addr" ]]; then
    sender="$sender_name <$sender_addr>"
  else
    sender="$sender_addr"
  fi

  echo "ID: $id | $subject"
  echo "From: $sender"
  echo "---"
done
