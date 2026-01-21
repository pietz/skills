#!/usr/bin/env bash
set -euo pipefail

search_term=""
days_ahead=30
field="summary"
calendar_name=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") <search-term> [--days N] [--field summary|location|description] [--calendar NAME]

Searches events by field for the next N days (default: 30).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days|-d)
      days_ahead="${2:-}"
      shift 2
      ;;
    --field|-f)
      field="${2:-}"
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
      if [[ -z "$search_term" ]]; then
        search_term="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$search_term" ]]; then
  usage >&2
  exit 1
fi

if ! [[ "$days_ahead" =~ ^[0-9]+$ ]]; then
  echo "--days must be an integer" >&2
  exit 1
fi

case "$field" in
  summary|location|description) ;;
  *)
    echo "--field must be summary, location, or description" >&2
    exit 1
    ;;
esac

osascript - "$search_term" "$days_ahead" "$field" "$calendar_name" <<'APPLESCRIPT'
on run argv
    set searchTerm to item 1 of argv
    set daysAhead to (item 2 of argv) as integer
    set fieldName to item 3 of argv
    set calName to item 4 of argv

    tell application "Calendar"
        set today to current date
        set endDate to today + (daysAhead * days)
        set output to ""

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
                set isMatch to false
                if fieldName is "summary" then
                    if (summary of evt) contains searchTerm then set isMatch to true
                else if fieldName is "location" then
                    try
                        if (location of evt) contains searchTerm then set isMatch to true
                    end try
                else if fieldName is "description" then
                    try
                        if (description of evt) contains searchTerm then set isMatch to true
                    end try
                end if

                if isMatch then
                    set output to output & "• " & (summary of evt) & linefeed
                    set output to output & "  UID: " & (uid of evt) & linefeed
                    set output to output & "  Calendar: " & (name of cal) & linefeed
                    if allday event of evt then
                        set output to output & "  All Day" & linefeed
                    else
                        set output to output & "  Time: " & (start date of evt as string) & " - " & (end date of evt as string) & linefeed
                    end if
                    set output to output & linefeed
                end if
            end repeat
        end repeat

        if output is "" then
            return "No events found"
        end if

        return output
    end tell
end run
APPLESCRIPT
