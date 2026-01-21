#!/usr/bin/env bash
set -euo pipefail

osascript <<'APPLESCRIPT'
tell application "Calendar"
    set today to current date
    set hours of today to 0
    set minutes of today to 0
    set seconds of today to 0
    set tomorrow to today + (1 * days)
    set output to "Today's Events:" & linefeed & linefeed
    repeat with cal in every calendar
        set calEvents to (every event of cal whose start date >= today and start date < tomorrow)
        repeat with evt in calEvents
            set output to output & "• " & (summary of evt) & linefeed
            set output to output & "  UID: " & (uid of evt) & linefeed
            set output to output & "  Calendar: " & (name of cal) & linefeed
            if allday event of evt then
                set output to output & "  All Day" & linefeed
            else
                set output to output & "  Time: " & (start date of evt as string) & " - " & (end date of evt as string) & linefeed
            end if
            try
                if (location of evt) is not missing value and (location of evt) is not "" then
                    set output to output & "  Location: " & (location of evt) & linefeed
                end if
            end try
            set output to output & linefeed
        end repeat
    end repeat
    return output
end tell
APPLESCRIPT
