#!/usr/bin/env bash
set -euo pipefail

limit="${1:-10}"
if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
  echo "Usage: $(basename "$0") [limit]" >&2
  exit 1
fi

osascript - "$limit" <<'APPLESCRIPT'
on run argv
    set maxCount to (item 1 of argv as integer)
    tell application "Mail"
        set totalCount to count of messages of inbox
        if totalCount is 0 then return "No messages in inbox."
        if maxCount < 1 then return "Limit must be >= 1"
        if maxCount > totalCount then set maxCount to totalCount
        set output to ""
        set recentMsgs to messages 1 thru maxCount of inbox
        repeat with msg in recentMsgs
            set acctName to name of account of mailbox of msg
            set msgRead to read status of msg
            set readFlag to "[ ]"
            if msgRead then set readFlag to "[x]"
            set output to output & readFlag & " [" & acctName & "] " & (subject of msg) & linefeed
            set output to output & "    ID: " & (id of msg) & " | From: " & (sender of msg) & linefeed
            set output to output & "    Date: " & (date received of msg as string) & linefeed
        end repeat
        return output
    end tell
end run
APPLESCRIPT
