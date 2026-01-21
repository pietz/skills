#!/usr/bin/env bash
set -euo pipefail

osascript - <<'APPLESCRIPT'
tell application "Mail"
    set output to ""
    repeat with acct in every account
        set output to output & "Account: " & (name of acct) & linefeed
        set output to output & "  Email: " & (email addresses of acct as string) & linefeed
        set mbNames to {}
        repeat with mb in every mailbox of acct
            set end of mbNames to name of mb
        end repeat
        set AppleScript's text item delimiters to ", "
        set output to output & "  Mailboxes: " & (mbNames as string) & linefeed
    end repeat
    return output
end tell
APPLESCRIPT
