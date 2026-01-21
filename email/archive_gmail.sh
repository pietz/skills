#!/usr/bin/env bash
set -euo pipefail

id=""
account=""
inbox_mailbox="INBOX"
all_mail_mailbox="All Mail"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      id="$2"; shift 2 ;;
    --account)
      account="$2"; shift 2 ;;
    --inbox)
      inbox_mailbox="$2"; shift 2 ;;
    --all-mail)
      all_mail_mailbox="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$id" || -z "$account" ]]; then
  echo "Usage: $(basename "$0") --id <message_id> --account <name> [--inbox <mailbox>] [--all-mail <mailbox>]" >&2
  exit 1
fi

osascript - "$id" "$account" "$inbox_mailbox" "$all_mail_mailbox" <<'APPLESCRIPT'
on run argv
    set targetId to item 1 of argv as integer
    set acctName to item 2 of argv
    set inboxName to item 3 of argv
    set allMailName to item 4 of argv

    tell application "Mail"
        try
            set acct to missing value
            if acctName contains "@" then
                set acct to first account whose email addresses contains acctName
            else
                set acct to account acctName
            end if
            set inboxBox to first mailbox of acct whose name is inboxName
            set allMail to first mailbox of acct whose name is allMailName
            set msg to first message of inboxBox whose id is targetId
            move msg to allMail
            return "Archived (removed from inbox)"
        on error
            return "Message not found or mailbox missing"
        end try
    end tell
end run
APPLESCRIPT
