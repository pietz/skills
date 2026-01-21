#!/usr/bin/env bash
set -euo pipefail

uid=""
calendar_name=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") <uid> [--calendar NAME]

Fetches a single event by UID.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --calendar|-c)
      calendar_name="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$uid" ]]; then
        uid="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$uid" ]]; then
  usage >&2
  exit 1
fi

osascript - "$uid" "$calendar_name" <<'APPLESCRIPT'
on run argv
    set targetUID to item 1 of argv
    set calName to item 2 of argv

    tell application "Calendar"
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
            try
                set evt to first event of cal whose uid is targetUID
                set output to output & "Summary: " & (summary of evt) & linefeed
                set output to output & "Calendar: " & (name of cal) & linefeed
                set output to output & "Start: " & (start date of evt as string) & linefeed
                set output to output & "End: " & (end date of evt as string) & linefeed
                set output to output & "All Day: " & (allday event of evt) & linefeed
                try
                    if (location of evt) is not missing value and (location of evt) is not "" then
                        set output to output & "Location: " & (location of evt) & linefeed
                    end if
                end try
                try
                    set descText to description of evt
                    if descText is not missing value and descText is not "" then
                        if (count of descText) > 500 then
                            set descText to text 1 thru 500 of descText & "..."
                        end if
                        set output to output & linefeed & "Description:" & linefeed & descText & linefeed
                    end if
                end try
                set attendeeList to every attendee of evt
                if (count of attendeeList) > 0 then
                    set output to output & linefeed & "Attendees:" & linefeed
                    repeat with att in attendeeList
                        try
                            set output to output & "• " & (display name of att) & " <" & (email of att) & "> - " & (participation status of att as string) & linefeed
                        end try
                    end repeat
                end if
                exit repeat
            end try
        end repeat
        if output is "" then set output to "Event not found"
        return output
    end tell
end run
APPLESCRIPT
