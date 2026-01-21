# AGENTS.md

Guidelines for creating and managing LLM skills in this repository.

This repo is a shared library of skills: small, composable instruction sets
and optional scripts/resources that agents can load on demand. The goal is to
reduce context bloat while making agent behavior consistent and reusable.

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
