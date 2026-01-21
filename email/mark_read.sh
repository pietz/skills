#!/usr/bin/env bash
set -euo pipefail

id=""
status="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      id="$2"; shift 2 ;;
    --status)
      status="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$id" ]]; then
  echo "Usage: $(basename "$0") --id <message_id> [--status true|false]" >&2
  exit 1
fi

osascript - "$id" "$status" <<'APPLESCRIPT'
on run argv
    set targetId to item 1 of argv as integer
    set statusText to item 2 of argv
    set newStatus to false
    if statusText is "true" then set newStatus to true

    tell application "Mail"
        try
            set msg to first message of inbox whose id is targetId
            set read status of msg to newStatus
            if newStatus then
                return "Marked as read"
            else
                return "Marked as unread"
            end if
        on error
            return "Message not found"
        end try
    end tell
end run
APPLESCRIPT
