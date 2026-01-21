#!/usr/bin/env bash
set -euo pipefail

id=""
archive_mailbox="Archive"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      id="$2"; shift 2 ;;
    --mailbox)
      archive_mailbox="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$id" ]]; then
  echo "Usage: $(basename "$0") --id <message_id> [--mailbox <archive_mailbox>]" >&2
  exit 1
fi

osascript - "$id" "$archive_mailbox" <<'APPLESCRIPT'
on run argv
    set targetId to item 1 of argv as integer
    set archiveName to item 2 of argv

    tell application "Mail"
        try
            set msg to first message of inbox whose id is targetId
            set archiveBox to mailbox archiveName of account of mailbox of msg
            move msg to archiveBox
            return "Archived"
        on error
            return "Message not found or archive mailbox missing"
        end try
    end tell
end run
APPLESCRIPT
