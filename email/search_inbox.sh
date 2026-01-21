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
