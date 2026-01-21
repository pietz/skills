#!/usr/bin/env bash
set -euo pipefail

# Calendar database location
CAL_DB="$HOME/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"

if [[ ! -f "$CAL_DB" ]]; then
  echo "Calendar database not found. Falling back to AppleScript." >&2
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
  exit 0
fi

# Core Foundation epoch offset (seconds between 1970-01-01 and 2001-01-01)
CF_OFFSET=978307200

# Get today's start and end in CF time
today_start=$(date -v0H -v0M -v0S +%s)
today_end=$((today_start + 86400))
cf_today_start=$((today_start - CF_OFFSET))
cf_today_end=$((today_end - CF_OFFSET))

echo "Today's Events:"
echo ""

sqlite3 -separator '|' "$CAL_DB" "
SELECT
    ci.unique_identifier,
    ci.summary,
    ci.start_date,
    ci.end_date,
    ci.all_day,
    c.title,
    COALESCE(l.title, '')
FROM CalendarItem ci
JOIN Calendar c ON ci.calendar_id = c.ROWID
LEFT JOIN Location l ON ci.location_id = l.ROWID
WHERE ci.start_date >= $cf_today_start
  AND ci.start_date < $cf_today_end
ORDER BY ci.start_date;
" | while IFS='|' read -r uid summary start_date end_date all_day calendar location; do
  echo "• $summary"
  echo "  UID: $uid"
  echo "  Calendar: $calendar"

  if [[ "$all_day" == "1" ]]; then
    echo "  All Day"
  else
    # Convert CF time to readable format
    start_unix=$((${start_date%.*} + CF_OFFSET))
    end_unix=$((${end_date%.*} + CF_OFFSET))
    start_str=$(date -r "$start_unix" "+%Y-%m-%d %H:%M")
    end_str=$(date -r "$end_unix" "+%H:%M")
    echo "  Time: $start_str - $end_str"
  fi

  if [[ -n "$location" ]]; then
    echo "  Location: $location"
  fi

  echo ""
done
