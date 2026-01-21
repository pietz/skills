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
