#!/usr/bin/env bash
set -euo pipefail

calendar_name=""
summary=""
start_raw=""
end_raw=""
start_epoch=""
end_epoch=""
location=""
description=""
all_day=false
confirm=false

usage() {
  cat <<USAGE
Usage: $(basename "$0") --calendar NAME --summary TEXT --start "YYYY-MM-DD HH:MM" [--end "YYYY-MM-DD HH:MM"] [--start-epoch SECONDS] [--end-epoch SECONDS] [--location TEXT] [--description TEXT] [--all-day] [--confirm]

Creates a calendar event. If --all-day is set and --end is omitted, end defaults to start + 1 day.
USAGE
}

parse_datetime() {
  local input="$1"
  if ! date -j -f "%Y-%m-%d %H:%M" "$input" "+%s" >/dev/null 2>&1; then
    return 1
  fi
  date -j -f "%Y-%m-%d %H:%M" "$input" "+%s"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --calendar|-c)
      calendar_name="${2:-}"
      shift 2
      ;;
    --summary|-s)
      summary="${2:-}"
      shift 2
      ;;
    --start)
      start_raw="${2:-}"
      shift 2
      ;;
    --end)
      end_raw="${2:-}"
      shift 2
      ;;
    --start-epoch)
      start_epoch="${2:-}"
      shift 2
      ;;
    --end-epoch)
      end_epoch="${2:-}"
      shift 2
      ;;
    --location|-l)
      location="${2:-}"
      shift 2
      ;;
    --description|-d)
      description="${2:-}"
      shift 2
      ;;
    --all-day)
      all_day=true
      shift
      ;;
    --confirm)
      confirm=true
      shift
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

if [[ -z "$calendar_name" || -z "$summary" ]]; then
  usage >&2
  exit 1
fi

if [[ -n "$start_epoch" ]]; then
  :
elif [[ -n "$start_raw" ]]; then
  start_epoch="$(parse_datetime "$start_raw")" || {
    echo "Invalid --start format. Use YYYY-MM-DD HH:MM" >&2
    exit 1
  }
else
  echo "--start or --start-epoch is required" >&2
  exit 1
fi

if [[ -n "$end_epoch" ]]; then
  :
elif [[ -n "$end_raw" ]]; then
  end_epoch="$(parse_datetime "$end_raw")" || {
    echo "Invalid --end format. Use YYYY-MM-DD HH:MM" >&2
    exit 1
  }
elif [[ "$all_day" == true ]]; then
  end_epoch=$((start_epoch + 86400))
else
  echo "--end or --end-epoch is required" >&2
  exit 1
fi

if (( end_epoch <= start_epoch )); then
  echo "End time must be after start time" >&2
  exit 1
fi

if [[ "$confirm" != true ]]; then
  echo "Refusing to create event without --confirm" >&2
  exit 1
fi

mac_start=$((start_epoch - 978307200))
mac_end=$((end_epoch - 978307200))

osascript - "$calendar_name" "$summary" "$mac_start" "$mac_end" "$location" "$description" "$all_day" <<'APPLESCRIPT'
on run argv
    set calName to item 1 of argv
    set summaryText to item 2 of argv
    set startSeconds to (item 3 of argv) as integer
    set endSeconds to (item 4 of argv) as integer
    set locationText to item 5 of argv
    set descriptionText to item 6 of argv
    set allDayFlag to item 7 of argv

    tell application "Calendar"
        try
            set targetCal to first calendar whose name is calName
        on error
            return "Calendar not found: " & calName
        end try

        -- Create reference date for Mac epoch (January 1, 2001 00:00:00)
        set referenceDate to current date
        set year of referenceDate to 2001
        set month of referenceDate to 1
        set day of referenceDate to 1
        set hours of referenceDate to 0
        set minutes of referenceDate to 0
        set seconds of referenceDate to 0

        set eventStart to referenceDate + startSeconds
        set eventEnd to referenceDate + endSeconds

        set newEvent to make new event at end of events of targetCal with properties {summary:summaryText, start date:eventStart, end date:eventEnd}

        if locationText is not "" then
            set location of newEvent to locationText
        end if
        if descriptionText is not "" then
            set description of newEvent to descriptionText
        end if
        if allDayFlag is "true" then
            set allday event of newEvent to true
        end if

        return "Created event: " & (summary of newEvent) & linefeed & "UID: " & (uid of newEvent)
    end tell
end run
APPLESCRIPT
