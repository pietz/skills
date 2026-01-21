#!/usr/bin/env bash
set -euo pipefail

account=""
mailbox=""
field="subject"
term=""
limit="10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account)
      account="$2"; shift 2 ;;
    --mailbox)
      mailbox="$2"; shift 2 ;;
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

if [[ -z "$account" || -z "$mailbox" || -z "$term" ]]; then
  echo "Usage: $(basename "$0") --account <name> --mailbox <name> --term <text> [--field subject|sender|content] [--limit <n>]" >&2
  exit 1
fi

# Find the Mail database (version may vary: V9, V10, V11, etc.)
MAIL_DB=$(find "$HOME/Library/Mail" -name "Envelope Index" -path "*/MailData/*" -type f 2>/dev/null | head -1)

if [[ -z "$MAIL_DB" || ! -f "$MAIL_DB" ]]; then
  echo "Mail database not found. Falling back to AppleScript." >&2
  osascript - "$account" "$mailbox" "$field" "$term" "$limit" <<'APPLESCRIPT'
on run argv
    set acctName to item 1 of argv
    set mbName to item 2 of argv
    set fieldName to item 3 of argv
    set searchTerm to item 4 of argv
    set maxCount to item 5 of argv as integer

    tell application "Mail"
        set acct to missing value
        try
            if acctName contains "@" then
                set acct to first account whose email addresses contains acctName
            else
                set acct to account acctName
            end if
        on error
            return "Account not found"
        end try

        set targetBox to missing value
        try
            set targetBox to first mailbox of acct whose name is mbName
        on error
            try
                set targetBox to first mailbox of acct whose name contains mbName
            on error
                return "Mailbox not found"
            end try
        end try
        if fieldName is "subject" then
            set foundMsgs to (messages of targetBox whose subject contains searchTerm)
        else if fieldName is "sender" then
            set foundMsgs to (messages of targetBox whose sender contains searchTerm)
        else if fieldName is "content" then
            set foundMsgs to (messages of targetBox whose content contains searchTerm)
        else
            return "Invalid field. Use subject, sender, or content."
        end if

        set output to "Found " & (count of foundMsgs) & " messages in " & mbName & ":" & linefeed
        set limitCount to count of foundMsgs
        if maxCount < limitCount then set limitCount to maxCount
        repeat with i from 1 to limitCount
            set msg to item i of foundMsgs
            set output to output & "• [" & (id of msg) & "] " & (date received of msg as string) & " | " & (subject of msg) & linefeed
        end repeat
        return output
    end tell
end run
APPLESCRIPT
  exit 0
fi

# Escape single quotes in search terms for SQL
escaped_term="${term//\'/\'\'}"
escaped_account="${account//\'/\'\'}"
escaped_mailbox="${mailbox//\'/\'\'}"

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
    osascript - "$account" "$mailbox" "$field" "$term" "$limit" <<'APPLESCRIPT'
on run argv
    set acctName to item 1 of argv
    set mbName to item 2 of argv
    set fieldName to item 3 of argv
    set searchTerm to item 4 of argv
    set maxCount to item 5 of argv as integer

    tell application "Mail"
        set acct to missing value
        try
            if acctName contains "@" then
                set acct to first account whose email addresses contains acctName
            else
                set acct to account acctName
            end if
        on error
            return "Account not found"
        end try

        set targetBox to missing value
        try
            set targetBox to first mailbox of acct whose name is mbName
        on error
            try
                set targetBox to first mailbox of acct whose name contains mbName
            on error
                return "Mailbox not found"
            end try
        end try
        set foundMsgs to (messages of targetBox whose content contains searchTerm)
        set output to "Found " & (count of foundMsgs) & " messages in " & mbName & ":" & linefeed
        set limitCount to count of foundMsgs
        if maxCount < limitCount then set limitCount to maxCount
        repeat with i from 1 to limitCount
            set msg to item i of foundMsgs
            set output to output & "• [" & (id of msg) & "] " & (date received of msg as string) & " | " & (subject of msg) & linefeed
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

# Mailbox filter: match by account UUID (in URL) and mailbox name (in URL)
# Account can be a name or email - we match against the URL which contains the UUID
# We do a fuzzy match on mailbox name since URL-encoding may differ
mailbox_filter="(mb.url LIKE '%${escaped_account}%' OR mb.url LIKE '%${escaped_mailbox}%')"
# More specific: match mailbox name in the path part
mailbox_filter="mb.url LIKE '%${escaped_mailbox}%'"

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

echo "Found $total messages in $mailbox:"

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

  echo "• [$id] $date_received | $subject"
  echo "  From: $sender"
done
