---
name: railway
description: Deploy and manage applications on railway.com. Use when the user asks to deploy, host, or ship an app to Railway, add databases or services to Railway, configure Railway projects, or troubleshoot Railway deployments.
---

# Railway Deployment

## CLI Basics

The Railway CLI has built-in help for all commands:

```bash
railway --help
railway <command> --help
```

**Important:** The CLI has interactive menus that don't work in automated contexts. Always provide all required parameters explicitly to avoid prompts (e.g., `--workspace`, `--service`, `--name`).

## Common Commands

```bash
# Create project (always specify workspace to avoid prompt)
railway init --name "my-project" --workspace "Workspace Name"

# Deploy from a template (get ID from template URL on railway.com)
railway init --template <template-id>

# Add PostgreSQL database
railway add --database postgres

# Add empty service for your app
railway add --service api

# Link local directory to service
railway service link api

# Set environment variables (use references for database URLs)
railway variables --service api --set 'DATABASE_URL=${{Postgres.DATABASE_URL}}'

# Deploy
railway up

# Generate public domain
railway domain --service api

# View logs
railway logs --service api
railway logs --service api --build    # build logs

# SSH into running service
railway ssh --service api
```

## More Commands

These are less common but useful — run `railway <command> --help` for details:

```bash
railway status --json          # full project overview (services, deployments, domains)
railway metrics --service api  # CPU, memory, network, disk usage
railway redeploy --service api # redeploy latest deployment
railway restart --service api  # restart without redeploying
railway down --service api     # take a service offline
```

## Variable Wiring

Reference variables across services with `${{ServiceName.VARIABLE}}`:

```bash
# Wire a database to your app
railway variables --service api --set 'DATABASE_URL=${{Postgres.DATABASE_URL}}'
railway variables --service api --set 'REDIS_URL=${{Redis.REDIS_URL}}'

# Wire backend URL to frontend
railway variables --service web --set 'API_URL=${{api.RAILWAY_PUBLIC_DOMAIN}}'
```

Railway also provides built-in variables: `RAILWAY_PUBLIC_DOMAIN`, `RAILWAY_PRIVATE_DOMAIN`, `RAILWAY_PROJECT_ID`, `RAILWAY_ENVIRONMENT_NAME`, etc.

## GraphQL API

For operations not available in the CLI, Railway has a GraphQL API:
- Endpoint: `https://backboard.railway.com/graphql/v2`
- Auth token: `~/.railway/config.json` → `user.token` (use as `Bearer` token)
- API docs: https://docs.railway.com/api/llms-docs.md

Always bind your app to `0.0.0.0:$PORT` - Railway injects the PORT variable.

## Logging (Python)

Railway parses single-line JSON on stdout, colors by `level` field, and makes all JSON fields queryable via `@field:value` in the Log Explorer. For the full setup guide, patterns, and pitfalls, see [logging-python.md](logging-python.md).
