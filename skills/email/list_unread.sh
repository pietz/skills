#!/usr/bin/env bash
set -euo pipefail

osascript - <<'APPLESCRIPT'
tell application "Mail"
    set unreadMsgs to (messages of inbox whose read status is false)
    set output to "Unread: " & (count of unreadMsgs) & linefeed & linefeed
    repeat with msg in unreadMsgs
        set output to output & "ID: " & (id of msg) & " | " & (subject of msg) & linefeed
        set output to output & "From: " & (sender of msg) & linefeed & "---" & linefeed
    end repeat
    return output
end tell
APPLESCRIPT
