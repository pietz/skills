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

# Calendar database location
CAL_DB="$HOME/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"

if [[ ! -f "$CAL_DB" ]]; then
  echo "Calendar database not found. Falling back to AppleScript." >&2
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
  exit 0
fi

# Escape UID for SQL
escaped_uid="${uid//\'/\'\'}"

# Core Foundation epoch offset
CF_OFFSET=978307200

# Query the event
result=$(sqlite3 -separator '|' "$CAL_DB" "
SELECT
    ci.unique_identifier,
    ci.summary,
    ci.start_date,
    ci.end_date,
    ci.all_day,
    c.title,
    COALESCE(l.title, ''),
    COALESCE(ci.description, '')
FROM CalendarItem ci
JOIN Calendar c ON ci.calendar_id = c.ROWID
LEFT JOIN Location l ON ci.location_id = l.ROWID
WHERE ci.unique_identifier = '${escaped_uid}';
")

if [[ -z "$result" ]]; then
  echo "Event not found"
  exit 0
fi

IFS='|' read -r uid summary start_date end_date all_day calendar location description <<< "$result"

echo "Summary: $summary"
echo "Calendar: $calendar"

# Convert dates
start_unix=$((${start_date%.*} + CF_OFFSET))
end_unix=$((${end_date%.*} + CF_OFFSET))
start_str=$(date -r "$start_unix" "+%Y-%m-%d %H:%M:%S")
end_str=$(date -r "$end_unix" "+%Y-%m-%d %H:%M:%S")

echo "Start: $start_str"
echo "End: $end_str"

if [[ "$all_day" == "1" ]]; then
  echo "All Day: true"
else
  echo "All Day: false"
fi

if [[ -n "$location" ]]; then
  echo "Location: $location"
fi

if [[ -n "$description" ]]; then
  # Truncate if too long
  if [[ ${#description} -gt 500 ]]; then
    description="${description:0:500}..."
  fi
  echo ""
  echo "Description:"
  echo "$description"
fi

# Try to get attendees (Participant table)
attendees=$(sqlite3 -separator '|' "$CAL_DB" "
SELECT
    COALESCE(p.email, ''),
    COALESCE(i.display_name, p.email, '')
FROM Participant p
LEFT JOIN Identity i ON p.identity_id = i.ROWID
WHERE p.owner_id IN (
    SELECT ROWID FROM CalendarItem WHERE unique_identifier = '${escaped_uid}'
);
" 2>/dev/null || true)

if [[ -n "$attendees" ]]; then
  echo ""
  echo "Attendees:"
  echo "$attendees" | while IFS='|' read -r email name; do
    if [[ -n "$name" && "$name" != "$email" ]]; then
      echo "• $name <$email>"
    elif [[ -n "$email" ]]; then
      echo "• $email"
    fi
  done
fi
