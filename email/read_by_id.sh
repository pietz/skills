#!/usr/bin/env bash
set -euo pipefail

id=""
account=""
mailbox=""
max_chars="2000"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      id="$2"; shift 2 ;;
    --account)
      account="$2"; shift 2 ;;
    --mailbox)
      mailbox="$2"; shift 2 ;;
    --max-chars)
      max_chars="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$id" ]]; then
  echo "Usage: $(basename "$0") --id <message_id> [--account <name>] [--mailbox <name>] [--max-chars <n>]" >&2
  exit 1
fi

osascript - "$id" "$account" "$mailbox" "$max_chars" <<'APPLESCRIPT'
on run argv
    set targetId to item 1 of argv as integer
    set acctName to item 2 of argv
    set mbName to item 3 of argv
    set maxChars to item 4 of argv as integer

    tell application "Mail"
        try
            if acctName is not "" and mbName is not "" then
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
                set msg to first message of targetBox whose id is targetId
            else if mbName is not "" then
                set targetBox to first mailbox whose name is mbName
                set msg to first message of targetBox whose id is targetId
            else
                set msg to first message of inbox whose id is targetId
            end if

            set output to "Subject: " & (subject of msg) & linefeed
            set output to output & "From: " & (sender of msg) & linefeed
            set output to output & "Date: " & (date received of msg as string) & linefeed
            set output to output & "Account: " & (name of account of mailbox of msg) & linefeed

            set toList to ""
            repeat with r in to recipients of msg
                set toList to toList & (address of r) & ", "
            end repeat
            set output to output & "To: " & toList & linefeed & linefeed

            set output to output & "--- Content ---" & linefeed
            set msgContent to content of msg
            if (count of msgContent) > maxChars then
                set msgContent to text 1 thru maxChars of msgContent & linefeed & "[truncated...]"
            end if
            set output to output & msgContent
            return output
        on error
            return "Message not found"
        end try
    end tell
end run
APPLESCRIPT
