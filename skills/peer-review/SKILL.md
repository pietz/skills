---
name: peer-review
description: Get alternative perspectives from other LLMs. Use this when stuck on a problem, seeking a second opinion, validating an approach, or wanting diverse viewpoints on complex decisions.
---

# Peer Review

Query multiple LLM CLIs in parallel and collect their responses.

## Available CLIs

All three should be invoked via the Bash tool as background tasks, run in parallel:

- **Claude**: `unset CLAUDECODE && claude -p "$PROMPT"`
- **Codex**: `codex exec -m "gpt-5.2" --skip-git-repo-check "$PROMPT"`
- **Gemini**: `gemini -m "gemini-3-pro-preview" -p "$PROMPT"`

## Workflow

1. Craft a clear, self-contained prompt. The CLIs have no history — fully re-brief them each time.
2. Check which CLIs are installed (`which claude codex gemini`).
3. Launch all available CLIs as **parallel background Bash tasks**.
4. Collect results from all three using `TaskOutput`.
5. **Report transparently**: before synthesizing, tell the user which models responded, which failed or timed out, and any issues encountered.
6. Present each model's response in its own section with clear attribution.
7. Provide a unified synthesis highlighting where the models agree, disagree, and what unique insights each contributed.

## Guidelines

- Think about how much you want to reveal about your own opinion when crafting the prompt.
- Do NOT spawn sub-agents via the Task tool — that would create three Claude agents instead of querying three different LLMs.
- If a CLI fails or times out, report it immediately and continue with the results you have.
