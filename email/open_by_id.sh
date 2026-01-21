#!/usr/bin/env bash
set -euo pipefail

id=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      id="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$id" ]]; then
  echo "Usage: $(basename "$0") --id <message_id>" >&2
  exit 1
fi

osascript - "$id" <<'APPLESCRIPT'
on run argv
    set targetId to item 1 of argv as integer
    tell application "Mail"
        try
            set msg to first message of inbox whose id is targetId
            open msg
            return "Opened: " & (subject of msg)
        on error
            return "Message not found"
        end try
    end tell
end run
APPLESCRIPT
