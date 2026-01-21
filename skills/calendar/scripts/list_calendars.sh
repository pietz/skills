#!/usr/bin/env bash
set -euo pipefail

osascript <<'APPLESCRIPT'
tell application "Calendar"
    set output to ""
    repeat with cal in every calendar
        set writableFlag to ""
        if not writable of cal then set writableFlag to " (read-only)"
        set output to output & "• " & (name of cal) & writableFlag & linefeed
    end repeat
    return output
end tell
APPLESCRIPT
