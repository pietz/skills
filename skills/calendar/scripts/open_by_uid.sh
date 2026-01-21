#!/usr/bin/env bash
set -euo pipefail

uid=""
calendar_name=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") <uid> [--calendar NAME]

Opens an event in Calendar.app by UID.
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
                show evt
                return "Opened event: " & (summary of evt)
            end try
        end repeat
        return "Event not found"
    end tell
end run
APPLESCRIPT
