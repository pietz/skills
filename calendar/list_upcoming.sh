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
