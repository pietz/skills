# AGENTS.md

Guidelines for creating and managing LLM skills in this repository.

This repo is a shared library of skills: small, composable instruction sets
and optional scripts/resources that agents can load on demand. The goal is to
reduce context bloat while making agent behavior consistent and reusable.

## How This Repo Is Used (Source Of Truth)

- The single editable source of truth is this repo: `/Users/pietz/Private/skills/skills/<skill>/...`
- Installed agents consume these skills via per-skill symlinks in their native skill directories:
  - Claude Code: `~/.claude/skills/<skill>` -> this repo
  - Codex: `~/.codex/skills/<skill>` -> this repo (leave `~/.codex/skills/.system` intact)
  - Gemini CLI: `~/.gemini/skills/<skill>` -> this repo (Gemini also has built-in/extension skills)
- We intentionally do NOT symlink the entire agent skill root directories, to avoid breaking agent-native
  skills and internal/system folders.

### Linking / Syncing (One-Time + As-Needed)

Run from the repo root:

```bash
scripts/link-skills.sh         # dry run (shows actions + conflicts)
scripts/link-skills.sh --apply # apply safe symlinks
```

Conflict policy:

- Missing target: create symlink.
- Existing symlink to repo: do nothing.
- Existing non-symlink but identical to repo: replace with symlink.
- Existing non-symlink and different: report conflict and skip (manual merge needed).

### Privacy Rules (Non-Negotiable)

- Skills must never contain secrets (passwords, API keys, tokens), personal IPs/hostnames, or private paths.
- Put machine-specific configuration in the appropriate place:
  - SSH: `~/.ssh/config` + keys
  - Runtime config: environment variables, Keychain/1Password, or local untracked config files
- Treat this repo as publishable even if you keep it private.

### Third-Party Skills

- If you install a third-party/public skill, vendor it into `skills/<name>/` and then symlink agents to it.
- If you customize a third-party skill (e.g., WorkGenius design language), the customized version lives here
  as the canonical copy.

## Principles

- Use progressive disclosure: keep `SKILL.md` lean; move rarely used details
  into separate files referenced by name.
- Optimize for recall: the `description` should make it obvious when to use the
  skill.
- Prefer deterministic code for complex operations; keep instructions for
  judgment and decisions.
- Keep scope narrow; one clear job per skill.
- Avoid unnecessary refactors of existing skills unless requested.

## Skill anatomy

Each skill lives in its own folder:

```
skill-name/
  SKILL.md
  reference.md (optional)
  scripts/ (optional)
```

`SKILL.md` must start with YAML frontmatter:

```
---
name: calendar
description: Use this skill when the user asks about calendar management...
---
```

The `name` and `description` are loaded as lightweight metadata for routing.
Keep `name` short and `description` specific and action-oriented.

## When to create a skill

Create a skill when:

- You repeat the same workflow or instruction set across tasks.
- The workflow needs tool usage, scripts, or consistent output formats.
- You want to keep the main conversation minimal and load details on demand.

Do not create a skill for:

- One-off tasks or generic advice.
- Broad or vague domains that belong in project instructions.
- Data access needs (use MCP servers for that; skills explain how to use data).

## Authoring guidelines

- Start with a single `SKILL.md`. Split only after it grows or contains
  mutually exclusive sections.
- Use short, imperative headings: "Gather Inputs", "Run Script", "Respond".
- Include exact commands or snippets if they must be executed verbatim.
- If user confirmation is required for sensitive actions, say so explicitly.
- Prefer ASCII; avoid special characters unless required by the tool.

## Scripts and resources

- Keep scripts small, deterministic, and runnable without network access.
- Document inputs/outputs and example usage in `SKILL.md`.
- Avoid adding dependencies unless they are already in the environment.
- If a script mutates files, call out safety checks and expected paths.

## Safety and trust

- Treat skills like code: only add from trusted sources and review carefully.
- Avoid instructions that exfiltrate secrets or prompt unsafe tool usage.
- Make "read-only" defaults explicit where possible.
- If a skill needs elevated permissions, document why and how to opt in.

## Review checklist

Before adding or updating a skill:

- Does the description clearly match the intended trigger?
- Is `SKILL.md` short enough to load without crowding context?
- Are optional files referenced by name and only when needed?
- Are commands safe, deterministic, and limited in scope?
- Are user confirmations required for destructive actions?

## Template

Use this structure for new skills:

```
---
name: short-skill-name
description: Use this skill when the user asks for [specific task].
---

# Title

## Purpose
- What this skill does and does not do.

## Inputs
- Required info from the user (ask if missing).

## Procedure
1. Step-by-step guidance.
2. Commands or scripts to run.

## Outputs
- Format requirements or sample output.

## Optional references
- See `reference.md` for edge cases.
```

## Repository conventions

- Keep folder names lowercase and dash-separated.
- Store all skill content in its folder; avoid cross-skill coupling.
- Update this `AGENTS.md` when patterns or conventions change.

## Suggested next steps

When a skill proves valuable, consider:

1. Adding a small reference file with edge cases.
2. Adding a test script or a sanity-check command sequence.
3. Writing a short "anti-patterns" section if the skill is often misused.
