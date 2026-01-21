---
name: Railway Deployment
description: A set of best practices and instructions when deploying applications on railway.com
---

## CLI Commands

```bash
# Create new project
railway init --name "my-project"

# Link to existing project
railway link

# Add database (postgres, mysql, redis, mongo)
railway add -d postgres

# Add service with env vars
railway add -s "api" -v "KEY=value"

# Deploy current directory
railway up

# Add persistent volume (mount path)
railway volume add -m /app/data

# Generate public domain for service
railway domain -s api

# View logs
railway logs -s api
railway logs --build  # build logs only

# Set environment variables
railway variables --set KEY=value -s api
```

## railway.toml

```toml
"$schema" = "https://railway.com/railway.schema.json"

[build]
builder = "DOCKERFILE"  # RAILPACK (default), DOCKERFILE, NIXPACKS
dockerfilePath = "Dockerfile"
buildCommand = "pip install -r requirements.txt"
watchPatterns = ["src/**", "*.py"]

[deploy]
startCommand = "uvicorn main:app --host 0.0.0.0 --port $PORT"
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"  # ON_FAILURE, ALWAYS, NEVER

# Environment-specific overrides
[environments.staging.deploy]
startCommand = "uvicorn main:app --reload"
```

## Notes

- Services auto-detect `$PORT` — always bind to `0.0.0.0:$PORT`
- Database URLs are auto-injected as env vars (e.g., `DATABASE_URL`)
- Config in `railway.toml` overrides dashboard settings
