---
name: email
description: Use this skill when the user asks about email - reading, searching, sending, drafting, archiving, or managing emails.
---

# Email Automation via macOS Mail.app

This skill uses small bash scripts (AppleScript under the hood) to automate the native macOS Mail.app. Scripts live in the `scripts/` subfolder and are intended to be called with parameters instead of editing AppleScript snippets inline.

## Requirements

- Mail.app must be configured. Initially assume that it is.
- macOS will prompt for automation permissions the first time.
- ALWAYS confirm with the user before any write action (send, delete, archive, mark read).

## Suggested workflow

Use these scripts as a small toolbox. The typical path is:

1. Discover accounts and mailbox names with `list_accounts.sh`. Treat this as the source of truth for localized mailbox names.
2. When you need a specific message, start with `list_recent.sh` or `search_inbox.sh` to get IDs.
3. If the message is older, switch to `search_mailbox.sh` using the exact mailbox name from step 1.
4. Use IDs for precise actions: `read_by_id.sh` to inspect, `open_by_id.sh` to show in Mail.app, `reply.sh` to draft a reply.
5. For write actions (`send.sh`, `archive_*.sh`, `delete.sh`, `mark_read.sh`), always confirm with the user first and double-check the ID.

This keeps the skill portable across different languages and account setups without hardcoded aliases.

## Scripts

- `scripts/list_accounts.sh` list accounts and mailboxes.
- `scripts/list_recent.sh [limit]` list recent inbox messages (default 10).
- `scripts/list_unread.sh` list unread inbox messages.
- `scripts/read_by_id.sh --id <id> [--account <name|email>] [--mailbox <name>] [--max-chars <n>]` read full email.
- `scripts/open_by_id.sh --id <id>` open email in Mail.app.
- `scripts/search_inbox.sh --term <text> [--field subject|sender|content] [--limit <n>]` search inbox.
- `scripts/search_mailbox.sh --account <name|email> --mailbox <name> --term <text> [--field subject|sender|content] [--limit <n>]` search a specific mailbox (archive, etc.), includes IDs.
- `scripts/compose.sh --from <email> --to <email[,email]> [--cc ...] [--bcc ...] [--subject ...] [--body ...]` open compose window.
- `scripts/send.sh --from <email> --to <email[,email]> [--cc ...] [--bcc ...] [--subject ...] [--body ...]` send immediately (confirm first).
- `scripts/reply.sh --id <id>` open reply window.
- `scripts/mark_read.sh --id <id> [--status true|false]` mark as read/unread.
- `scripts/archive_exchange.sh --id <id> [--mailbox <archive_mailbox>]` archive for Exchange/Outlook.
- `scripts/archive_gmail.sh --id <id> --account <name|email> [--inbox <mailbox>] [--all-mail <mailbox>]` archive for Gmail.
- `scripts/delete.sh --id <id> [--account <name|email>] [--mailbox <name>] [--trash <mailbox>]` move to trash (use account/mailbox for Sent, Archive, etc.).

## Examples

```bash
./scripts/list_accounts.sh
./scripts/list_recent.sh 5
./scripts/search_inbox.sh --term "invoice" --field subject --limit 5
./scripts/read_by_id.sh --id 12345 --max-chars 1000
./scripts/compose.sh --from "me@example.com" --to "you@example.com" --subject "Hello" --body $'Line 1\nLine 2'
```

## Notes

- IDs are integers from listings; use them for read/open/reply/archive/delete.
- If a message is not in inbox, use `search_mailbox.sh` and then `read_by_id.sh` with `--account`/`--mailbox`.
- Some mailbox names vary by provider and language; use `list_accounts.sh` to confirm. Scripts accept account name or account email and try a partial mailbox-name match if the exact name is not found.
