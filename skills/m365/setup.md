# M365 CLI Setup

Follow these steps in order. Once `m365 status` shows `"authType": "secret"`, setup is complete and you can return to the original task.

## 1. Install the CLI

Check if `m365` is available:

```bash
m365 --version
```

If not found, install it (requires Node.js v20+):

```bash
npm install -g @pnp/cli-microsoft365
```

## 2. Check for an Existing Connection

The CLI may already have a stored app registration connection from a previous setup:

```bash
m365 connection list --output json
```

If a connection with `"authType": "secret"` exists, activate it and skip to step 4:

```bash
m365 connection use --name "<connection-name>"
```

If no such connection exists, continue with step 3.

## 3. Authenticate

Ask the user for three values from their Azure AD app registration:

| What to ask for | Azure Portal label | CLI flag |
|---|---|---|
| Client ID | Application (client) ID | `--appId` |
| Tenant ID | Directory (tenant) ID | `--tenant` |
| Client Secret | Client secret **value** (not the secret ID) | `--secret` |

The app registration needs these application permissions with admin consent granted: `Mail.Read`, `Mail.Send`, `Calendar.ReadWrite`.

Then log in:

```bash
m365 login --authType secret --appId <client-id> --tenant <tenant-id> --secret '<client-secret>'
```

## 4. Verify

```bash
m365 status --output json
```

You should see `"authType": "secret"`. If so, setup is complete - return to `SKILL.md` and continue with the original task.
