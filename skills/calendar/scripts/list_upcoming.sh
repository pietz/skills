#!/usr/bin/env bash
set -euo pipefail

days_ahead=14
calendar_name=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--days N] [--calendar NAME]

Lists upcoming events for the next N days (default: 14).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days|-d)
      days_ahead="${2:-}"
      shift 2
      ;;
    --calendar|-c)
      calendar_name="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! [[ "$days_ahead" =~ ^[0-9]+$ ]]; then
  echo "--days must be an integer" >&2
  exit 1
fi

# Calendar database location
CAL_DB="$HOME/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"

if [[ ! -f "$CAL_DB" ]]; then
  echo "Calendar database not found. Falling back to AppleScript." >&2
  osascript - "$days_ahead" "$calendar_name" <<'APPLESCRIPT'
on run argv
    set daysAhead to (item 1 of argv) as integer
    set calName to item 2 of argv
    tell application "Calendar"
        set today to current date
        set endDate to today + (daysAhead * days)
        set output to "Upcoming Events (next " & daysAhead & " days):" & linefeed & linefeed
        if calName is not "" then
            try
                set targetCalendars to {first calendar whose name is calName}
            on error
                return "Calendar not found: " & calName
            end try
        else
            set targetCalendars to every calendar
        end if

        repeat with cal in targetCalendars
            set calEvents to (every event of cal whose start date >= today and start date <= endDate)
            repeat with evt in calEvents
                set output to output & "• " & (summary of evt) & linefeed
                set output to output & "  UID: " & (uid of evt) & linefeed
                set output to output & "  Calendar: " & (name of cal) & linefeed
                if allday event of evt then
                    set output to output & "  All Day" & linefeed
                else
                    set output to output & "  Time: " & (start date of evt as string) & " - " & (end date of evt as string) & linefeed
                end if
                set output to output & linefeed
            end repeat
        end repeat
        return output
    end tell
end run
APPLESCRIPT
  exit 0
fi

# Core Foundation epoch offset (seconds between 1970-01-01 and 2001-01-01)
CF_OFFSET=978307200

# Get date range in CF time
now=$(date +%s)
end_time=$((now + days_ahead * 86400))
cf_now=$((now - CF_OFFSET))
cf_end=$((end_time - CF_OFFSET))

# Build calendar filter if specified
if [[ -n "$calendar_name" ]]; then
  escaped_cal="${calendar_name//\'/\'\'}"
  cal_filter="AND c.title LIKE '%${escaped_cal}%'"
else
  cal_filter=""
fi

echo "Upcoming Events (next $days_ahead days):"
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
WHERE ci.start_date >= $cf_now
  AND ci.start_date < $cf_end
  $cal_filter
ORDER BY ci.start_date;
" | while IFS='|' read -r uid summary start_date end_date all_day calendar location; do
  echo "• $summary"
  echo "  UID: $uid"
  echo "  Calendar: $calendar"

  if [[ "$all_day" == "1" ]]; then
    # For all-day events, show the date
    start_unix=$((${start_date%.*} + CF_OFFSET))
    date_str=$(date -r "$start_unix" "+%Y-%m-%d")
    echo "  All Day: $date_str"
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
