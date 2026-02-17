#!/usr/bin/env bash
set -euo pipefail

from=""
to=""
cc=""
bcc=""
subject=""
body=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      from="$2"; shift 2 ;;
    --to)
      to="$2"; shift 2 ;;
    --cc)
      cc="$2"; shift 2 ;;
    --bcc)
      bcc="$2"; shift 2 ;;
    --subject)
      subject="$2"; shift 2 ;;
    --body)
      body="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$from" || -z "$to" ]]; then
  echo "Usage: $(basename "$0") --from <email> --to <email[,email]> [--cc <email[,email]>] [--bcc <email[,email]>] [--subject <text>] [--body <text>]" >&2
  exit 1
fi

osascript - "$from" "$to" "$cc" "$bcc" "$subject" "$body" <<'APPLESCRIPT'
on run argv
    set fromAddr to item 1 of argv
    set toAddrs to item 2 of argv
    set ccAddrs to item 3 of argv
    set bccAddrs to item 4 of argv
    set subj to item 5 of argv
    set bodyText to item 6 of argv

    tell application "Mail"
        set newMsg to make new outgoing message with properties {subject:subj, content:bodyText, visible:false, sender:fromAddr}
        tell newMsg
            set AppleScript's text item delimiters to ","
            repeat with addr in text items of toAddrs
                if addr is not "" then make new to recipient with properties {address:addr}
            end repeat
            if ccAddrs is not "" then
                repeat with addr in text items of ccAddrs
                    if addr is not "" then make new cc recipient with properties {address:addr}
                end repeat
            end if
            if bccAddrs is not "" then
                repeat with addr in text items of bccAddrs
                    if addr is not "" then make new bcc recipient with properties {address:addr}
                end repeat
            end if
        end tell
        send newMsg
        return "Email sent"
    end tell
end run
APPLESCRIPT
