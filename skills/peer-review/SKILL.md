---
name: peer-review
description: Get alternative perspectives from other LLMs. Use when seeking a second opinion, validating an approach, or wanting diverse viewpoints on complex decisions.
---

# Peer Review

Query three LLM CLI tools for alternative opinions.

## CLI Syntax

| Tool | Command |
|------|---------|
| Claude | `claude -p "prompt"` |
| Codex | `codex exec --skip-git-repo-check "prompt"` |
| Gemini | `gemini "prompt"` |

## Usage

- Run all three as bash commands in parallel using `run_in_background: true`.
- Do NOT spawn sub-agents via the Task tool - that would create three Claude agents instead of querying three different LLMs.
- Collect responses from whichever CLIs are installed. Do not install them.
- Think about how much you want to reveal about your opinion when prompting.
- The CLIs don't keep history between calls. Fully re-brief them each time.
