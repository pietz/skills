#!/usr/bin/env bash
set -euo pipefail

limit="${1:-10}"
if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
  echo "Usage: $(basename "$0") [limit]" >&2
  exit 1
fi

# Find the Mail database (version may vary: V9, V10, V11, etc.)
MAIL_DB=$(find "$HOME/Library/Mail" -name "Envelope Index" -path "*/MailData/*" -type f 2>/dev/null | head -1)

if [[ -z "$MAIL_DB" || ! -f "$MAIL_DB" ]]; then
  echo "Mail database not found. Falling back to AppleScript." >&2
  # Fallback to AppleScript if database doesn't exist
  osascript - "$limit" <<'APPLESCRIPT'
on run argv
    set maxCount to (item 1 of argv as integer)
    tell application "Mail"
        set totalCount to count of messages of inbox
        if totalCount is 0 then return "No messages in inbox."
        if maxCount < 1 then return "Limit must be >= 1"
        if maxCount > totalCount then set maxCount to totalCount
        set output to ""
        set recentMsgs to messages 1 thru maxCount of inbox
        repeat with msg in recentMsgs
            set acctName to name of account of mailbox of msg
            set msgRead to read status of msg
            set readFlag to "[ ]"
            if msgRead then set readFlag to "[x]"
            set output to output & readFlag & " [" & acctName & "] " & (subject of msg) & linefeed
            set output to output & "    ID: " & (id of msg) & " | From: " & (sender of msg) & linefeed
            set output to output & "    Date: " & (date received of msg as string) & linefeed
        end repeat
        return output
    end tell
end run
APPLESCRIPT
  exit 0
fi

sqlite3 -separator '|' "$MAIL_DB" "
SELECT
    m.ROWID,
    CASE WHEN m.read = 1 THEN '[x]' ELSE '[ ]' END,
    s.subject,
    a.address,
    a.comment,
    datetime(m.date_received, 'unixepoch', 'localtime'),
    mb.url
FROM messages m
JOIN subjects s ON m.subject = s.ROWID
JOIN addresses a ON m.sender = a.ROWID
JOIN mailboxes mb ON m.mailbox = mb.ROWID
WHERE mb.url LIKE '%/Inbox' OR mb.url LIKE '%/INBOX'
ORDER BY m.date_received DESC
LIMIT $limit;
" | while IFS='|' read -r id read_status subject sender_addr sender_name date_received mailbox_url; do
  # Extract account identifier from mailbox URL (protocol://UUID/...)
  account=$(echo "$mailbox_url" | sed -E 's|^[^:]+://([^/]+)/.*|\1|' | cut -c1-8)

  # Format sender
  if [[ -n "$sender_name" && "$sender_name" != "$sender_addr" ]]; then
    sender="$sender_name <$sender_addr>"
  else
    sender="$sender_addr"
  fi

  echo "$read_status [$account] $subject"
  echo "    ID: $id | From: $sender"
  echo "    Date: $date_received"
done
