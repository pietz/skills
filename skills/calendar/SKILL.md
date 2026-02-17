---
name: calendar
description: Use this skill when the user asks about calendar management - viewing events, scheduling meetings, checking availability, or managing appointments.
---

# Calendar Automation via macOS Calendar.app

This skill automates Calendar.app with small, focused scripts stored in the `scripts/` subfolder. Use them for listing events, searching by summary/location/description, and targeting events by UID. Scripts are written to work across different languages and calendar naming schemes by discovering actual calendar names first.

## Important Notes

- Calendar.app must be set up (assume that it is)
- Events are identified by UID (unique string like `91ADA44E-B3BA-44F5-9006-3C077D94DACF`)
- Always include UIDs in output so the user can reference specific events
- Default time window is upcoming (next 1-4 weeks), not past
- When in doubt about which calendar to use, ask the user
- Always confirm with the user before create/delete operations

## Suggested Workflow

1. Run `./scripts/list_calendars.sh` to discover calendar names (including localized names).
2. Use `./scripts/list_today.sh` or `./scripts/list_upcoming.sh --days 14` to see upcoming events and get UIDs.
3. If you need a specific event, search with `./scripts/search_events.sh "term" --field summary --days 30` and copy the UID.
4. Use the UID with `./scripts/get_by_uid.sh <uid>` for full details or `./scripts/open_by_uid.sh <uid>` to show it in Calendar.app.
5. Only after explicit user approval, create or delete with `./scripts/create_event.sh ... --confirm` or `./scripts/delete_event.sh <uid> --confirm`.

## Scripts

```bash
./scripts/list_calendars.sh
```

Lists all calendars (marks read-only calendars).

```bash
./scripts/list_today.sh
```

Lists today's events across all calendars.

```bash
./scripts/list_upcoming.sh --days 14
./scripts/list_upcoming.sh --days 7 --calendar "Work"
```

Lists upcoming events for the next N days (default: 14). Optional calendar filter.

```bash
./scripts/search_events.sh "meeting" --field summary --days 30
./scripts/search_events.sh "berlin" --field location --calendar "Work"
```

Searches events by summary/location/description in the next N days. Optional calendar filter.

```bash
./scripts/get_by_uid.sh "91ADA44E-B3BA-44F5-9006-3C077D94DACF"
```

Shows full event details for a UID (including attendees when available).

```bash
./scripts/open_by_uid.sh "91ADA44E-B3BA-44F5-9006-3C077D94DACF"
```

Opens the event in Calendar.app.

```bash
./scripts/create_event.sh --calendar "Work" --summary "Planning" --start "2025-01-01 10:00" --end "2025-01-01 11:00" --location "Room 2" --confirm
./scripts/create_event.sh --calendar "Personal" --summary "Day Off" --start "2025-01-01 00:00" --all-day --confirm
```

Creates an event. Use `--start-epoch`/`--end-epoch` if you already have Unix timestamps.

```bash
./scripts/delete_event.sh "91ADA44E-B3BA-44F5-9006-3C077D94DACF" --confirm
```

Deletes an event by UID (requires `--confirm`).
