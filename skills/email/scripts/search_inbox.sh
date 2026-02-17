#!/usr/bin/env bash
set -euo pipefail

field="subject"
term=""
limit="10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --field)
      field="$2"; shift 2 ;;
    --term)
      term="$2"; shift 2 ;;
    --limit)
      limit="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$term" ]]; then
  echo "Usage: $(basename "$0") --term <text> [--field subject|sender|content] [--limit <n>]" >&2
  exit 1
fi

# Find the Mail database (version may vary: V9, V10, V11, etc.)
MAIL_DB=$(find "$HOME/Library/Mail" -name "Envelope Index" -path "*/MailData/*" -type f 2>/dev/null | head -1)

if [[ -z "$MAIL_DB" || ! -f "$MAIL_DB" ]]; then
  echo "Mail database not found. Falling back to AppleScript." >&2
  osascript - "$field" "$term" "$limit" <<'APPLESCRIPT'
on run argv
    set fieldName to item 1 of argv
    set searchTerm to item 2 of argv
    set maxCount to item 3 of argv as integer

    tell application "Mail"
        if fieldName is "subject" then
            set foundMsgs to (messages of inbox whose subject contains searchTerm)
        else if fieldName is "sender" then
            set foundMsgs to (messages of inbox whose sender contains searchTerm)
        else if fieldName is "content" then
            set foundMsgs to (messages of inbox whose content contains searchTerm)
        else
            return "Invalid field. Use subject, sender, or content."
        end if

        set output to "Found " & (count of foundMsgs) & " messages:" & linefeed
        set limitCount to count of foundMsgs
        if maxCount < limitCount then set limitCount to maxCount
        repeat with i from 1 to limitCount
            set msg to item i of foundMsgs
            set output to output & "• [" & (id of msg) & "] " & (subject of msg) & linefeed
            set output to output & "  From: " & (sender of msg) & linefeed
        end repeat
        return output
    end tell
end run
APPLESCRIPT
  exit 0
fi

# Escape single quotes in term for SQL (double them)
escaped_term="${term//\'/\'\'}"

# Build the WHERE clause based on field
case "$field" in
  subject)
    field_condition="s.subject LIKE '%${escaped_term}%'"
    ;;
  sender)
    field_condition="(a.address LIKE '%${escaped_term}%' OR a.comment LIKE '%${escaped_term}%')"
    ;;
  content)
    # Content search falls back to AppleScript since body isn't in SQLite
    echo "Content search requires AppleScript (body not in database)." >&2
    osascript - "$field" "$term" "$limit" <<'APPLESCRIPT'
on run argv
    set fieldName to item 1 of argv
    set searchTerm to item 2 of argv
    set maxCount to item 3 of argv as integer

    tell application "Mail"
        set foundMsgs to (messages of inbox whose content contains searchTerm)
        set output to "Found " & (count of foundMsgs) & " messages:" & linefeed
        set limitCount to count of foundMsgs
        if maxCount < limitCount then set limitCount to maxCount
        repeat with i from 1 to limitCount
            set msg to item i of foundMsgs
            set output to output & "• [" & (id of msg) & "] " & (subject of msg) & linefeed
            set output to output & "  From: " & (sender of msg) & linefeed
        end repeat
        return output
    end tell
end run
APPLESCRIPT
    exit 0
    ;;
  *)
    echo "Invalid field. Use subject, sender, or content." >&2
    exit 1
    ;;
esac

# Mailbox filter: Exclude trash, spam, drafts, outbox (negative filter is more universal across languages)
# This covers: Deleted Items, Trash, Papierkorb, Junk Email, Spam, Drafts, Entwürfe, Outbox, etc.
mailbox_filter="(
    mb.url NOT LIKE '%Deleted%'
    AND mb.url NOT LIKE '%Trash%'
    AND mb.url NOT LIKE '%Papierkorb%'
    AND mb.url NOT LIKE '%Junk%'
    AND mb.url NOT LIKE '%Spam%'
    AND mb.url NOT LIKE '%Draft%'
    AND mb.url NOT LIKE '%Entwu%'
    AND mb.url NOT LIKE '%Outbox%'
    AND mb.url NOT LIKE '%Notes%'
    AND mb.url NOT LIKE '%Journal%'
    AND mb.url NOT LIKE '%Tasks%'
)"

# First get total count
total=$(sqlite3 "$MAIL_DB" "
SELECT COUNT(*)
FROM messages m
JOIN subjects s ON m.subject = s.ROWID
JOIN addresses a ON m.sender = a.ROWID
JOIN mailboxes mb ON m.mailbox = mb.ROWID
WHERE m.deleted = 0
  AND $mailbox_filter
  AND $field_condition;
")

echo "Found $total messages:"

sqlite3 -separator '|' "$MAIL_DB" "
SELECT
    m.ROWID,
    s.subject,
    a.address,
    a.comment,
    datetime(m.date_received, 'unixepoch', 'localtime')
FROM messages m
JOIN subjects s ON m.subject = s.ROWID
JOIN addresses a ON m.sender = a.ROWID
JOIN mailboxes mb ON m.mailbox = mb.ROWID
WHERE m.deleted = 0
  AND $mailbox_filter
  AND $field_condition
ORDER BY m.date_received DESC
LIMIT $limit;
" | while IFS='|' read -r id subject sender_addr sender_name date_received; do
  if [[ -n "$sender_name" && "$sender_name" != "$sender_addr" ]]; then
    sender="$sender_name <$sender_addr>"
  else
    sender="$sender_addr"
  fi

  echo "• [$id] $subject"
  echo "  From: $sender | Date: $date_received"
done
