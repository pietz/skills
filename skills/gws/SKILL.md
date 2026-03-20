---
name: gws
description: >
  Access Google Workspace (Gmail + Calendar) via the `gws` CLI.
  Use when the user asks to read, search, send, reply to, or manage emails,
  or to view, create, update, or delete calendar events.
---

# Google Workspace CLI (`gws`)

## First-time setup

1. Check if `gws` is installed: `gws --help`
2. If not, install it: `npm install -g @anthropic-ai/gws` (or follow the gws project README)
3. Authenticate: `gws auth login` — this opens a browser for OAuth consent
4. Verify: `gws gmail users labels list --params '{"userId": "me"}'` — should return labels

Ask the user for their Google account email if needed for calendar operations.

```
gws --help          # full CLI reference
gws gmail --help    # Gmail commands + helpers
gws calendar --help # Calendar commands + helpers
```

## Key conventions

- Always use `"userId": "me"` for Gmail operations.
- Search with `q` across all mail, not just INBOX, unless specifically asked for unread/inbox items.
- Always ask for confirmation before sending emails or creating/modifying/deleting calendar events.
- Discover calendars with `gws calendar calendarList list` before assuming calendar IDs.

## Gmail

### List & search messages

```bash
# Recent inbox messages
gws gmail users messages list --params '{"userId": "me", "labelIds": "INBOX", "maxResults": 10}'

# Search all mail (includes archive)
gws gmail users messages list --params '{"userId": "me", "q": "from:alice subject:dinner", "maxResults": 10}'

# Common q operators: from: to: subject: has:attachment after:2026/03/01 before:2026/03/12 is:unread label:INBOX
```

List only returns `id` + `threadId`. Fetch full content with get.

### Read a message

```bash
# Metadata only (headers: Subject, From, To, Date)
gws gmail users messages get --params '{"userId": "me", "id": "MSG_ID", "format": "metadata"}'

# Full message with body
gws gmail users messages get --params '{"userId": "me", "id": "MSG_ID", "format": "full"}'
```

The body is in `payload.parts[]` or `payload.body.data` (base64url-encoded).

### Triage helper

```bash
# Quick unread inbox summary (subject, sender, date)
gws gmail +triage
```

### Send email

```bash
# Helper (preferred)
gws gmail +send --params '{"userId": "me"}' --json '{
  "to": "recipient@example.com",
  "subject": "Hello",
  "body": "Message text here"
}'

# Reply (preserves threading)
gws gmail +reply --params '{"userId": "me", "id": "MSG_ID"}' --json '{
  "body": "Reply text"
}'

# Reply all
gws gmail +reply-all --params '{"userId": "me", "id": "MSG_ID"}' --json '{
  "body": "Reply text"
}'

# Forward
gws gmail +forward --params '{"userId": "me", "id": "MSG_ID"}' --json '{
  "to": "someone@example.com",
  "body": "FYI see below"
}'
```

### Modify labels (archive, mark read/unread, star)

```bash
# Archive (remove from inbox)
gws gmail users messages modify --params '{"userId": "me", "id": "MSG_ID"}' --json '{"removeLabelIds": ["INBOX"]}'

# Mark as read
gws gmail users messages modify --params '{"userId": "me", "id": "MSG_ID"}' --json '{"removeLabelIds": ["UNREAD"]}'

# Mark as unread
gws gmail users messages modify --params '{"userId": "me", "id": "MSG_ID"}' --json '{"addLabelIds": ["UNREAD"]}'

# Star
gws gmail users messages modify --params '{"userId": "me", "id": "MSG_ID"}' --json '{"addLabelIds": ["STARRED"]}'

# Trash
gws gmail users messages trash --params '{"userId": "me", "id": "MSG_ID"}'
```

### List labels

```bash
gws gmail users labels list --params '{"userId": "me"}'
```

## Calendar

### View upcoming events

```bash
# Agenda helper (all calendars)
gws calendar +agenda

# List from primary calendar
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-03-12T00:00:00Z",
  "timeMax": "2026-03-19T00:00:00Z",
  "singleEvents": true,
  "orderBy": "startTime",
  "maxResults": 20
}'
```

Timed events use `start.dateTime` / `end.dateTime`. All-day events use `start.date` / `end.date`.

### Create an event

```bash
gws calendar +insert --params '{"calendarId": "primary", "sendUpdates": "all"}' --json '{
  "summary": "Team sync",
  "location": "Office",
  "start": {"dateTime": "2026-03-15T19:00:00", "timeZone": "Europe/Berlin"},
  "end": {"dateTime": "2026-03-15T21:00:00", "timeZone": "Europe/Berlin"},
  "attendees": [{"email": "colleague@example.com"}],
  "reminders": {"useDefault": true}
}'
```

### Update an event

```bash
gws calendar events update --params '{"calendarId": "primary", "eventId": "EVENT_ID", "sendUpdates": "all"}' --json '{
  "summary": "Updated title",
  "start": {"dateTime": "2026-03-15T20:00:00", "timeZone": "Europe/Berlin"},
  "end": {"dateTime": "2026-03-15T22:00:00", "timeZone": "Europe/Berlin"}
}'
```

### Delete an event

```bash
gws calendar events delete --params '{"calendarId": "primary", "eventId": "EVENT_ID", "sendUpdates": "all"}'
```

### Check free/busy

```bash
gws calendar freebusy query --json '{
  "timeMin": "2026-03-15T00:00:00Z",
  "timeMax": "2026-03-15T23:59:59Z",
  "items": [{"id": "primary"}]
}'
```

## Pagination

For large result sets, use `--page-all` to auto-paginate (NDJSON, one page per line):

```bash
gws gmail users messages list --params '{"userId": "me", "q": "from:amazon"}' --page-all --page-limit 5
```

## Output formats

Default is JSON. Use `--format table` for human-readable output, `--format csv` for export.
