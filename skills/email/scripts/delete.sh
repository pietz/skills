#!/usr/bin/env bash
set -euo pipefail

id=""
trash_mailbox=""
account=""
mailbox=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      id="$2"; shift 2 ;;
    --trash)
      trash_mailbox="$2"; shift 2 ;;
    --account)
      account="$2"; shift 2 ;;
    --mailbox)
      mailbox="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$id" ]]; then
  echo "Usage: $(basename "$0") --id <message_id> [--account <name>] [--mailbox <name>] [--trash <mailbox>]" >&2
  exit 1
fi

osascript - "$id" "$trash_mailbox" "$account" "$mailbox" <<'APPLESCRIPT'
on run argv
    set targetId to item 1 of argv as integer
    set trashOverride to item 2 of argv
    set acctNameOverride to item 3 of argv
    set mailboxOverride to item 4 of argv

    tell application "Mail"
        try
            if acctNameOverride is not "" and mailboxOverride is not "" then
                set acct to missing value
                try
                    if acctNameOverride contains "@" then
                        set acct to first account whose email addresses contains acctNameOverride
                    else
                        set acct to account acctNameOverride
                    end if
                on error
                    return "Account not found"
                end try
                set targetBox to missing value
                try
                    set targetBox to first mailbox of acct whose name is mailboxOverride
                on error
                    try
                        set targetBox to first mailbox of acct whose name contains mailboxOverride
                    on error
                        return "Mailbox not found"
                    end try
                end try
                set msg to first message of targetBox whose id is targetId
            else if mailboxOverride is not "" then
                set targetBox to first mailbox whose name is mailboxOverride
                set msg to first message of targetBox whose id is targetId
            else
                set msg to first message of inbox whose id is targetId
            end if
            set acct to account of mailbox of msg
            set acctName to name of acct

            set trashName to "Trash"
            if trashOverride is not "" then
                set trashName to trashOverride
            else if acctName contains "Outlook" or acctName contains "Exchange" then
                set trashName to "Deleted Items"
            else if acctName contains "Gmail" then
                set trashName to "Trash"
            end if

            set trashBox to first mailbox of acct whose name is trashName
            move msg to trashBox
            return "Moved to trash"
        on error
            return "Message not found or trash mailbox missing"
        end try
    end tell
end run
APPLESCRIPT
