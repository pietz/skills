# Skills

A collection of my personal skills for AI coding agents.

## Source Of Truth

This repo is the single editable source of truth for skills under `skills/`.
Installed agents consume these skills via per-skill symlinks (not by copying).

## Link Into Agents

```bash
scripts/link-skills.sh         # dry run
scripts/link-skills.sh --apply # apply safe symlinks
```

## Available Skills

- **calendar** - Calendar management via macOS Calendar app
- **email** - Email operations via macOS Mail app
- **fastapi** - FastAPI project patterns and best practices
- **railway** - Deploy and manage apps on Railway
