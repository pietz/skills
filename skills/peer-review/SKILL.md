---
name: peer-review
description: Ask a group of LLM tools for their opinion on a given task. Use this when stuck on a problem, seeking a second opinion, validating an approach, or wanting diverse viewpoints on complex decisions.
---

# Peer Review

Query multiple LLM CLIs in parallel and collect their responses.

## Available CLIs

All three should be invoked via the Bash tool as background tasks, run in parallel:

- **Claude**: `unset CLAUDECODE && claude --model opus -p "$PROMPT"`
- **Codex**: `codex exec -m "gpt-5.2" --skip-git-repo-check "$PROMPT"`
- **Gemini**: `gemini -m "gemini-3.1-pro-preview" -p "$PROMPT"`

## Self-invocation rule

The orchestrating agent (the one running this skill) must NOT call its own CLI via Bash — it will fail or produce empty output. Instead, it should use a **subagent** (e.g., Task tool with `model: "opus"`) for its own model's contribution. Only use Bash CLI commands for the **other** models.

For example:
- If **Claude** is the orchestrator: use subagent for Claude, Bash for Codex and Gemini.
- If **Codex** is the orchestrator: use subagent for Codex, Bash for Claude and Gemini.
- If **Gemini** is the orchestrator: use subagent for Gemini, Bash for Claude and Codex.

## Workflow

1. Craft a clear, self-contained prompt. The CLIs have no history — fully re-brief them each time.
2. Identify which agent you are (the orchestrator) so you know which CLI to skip.
3. Check which of the remaining CLIs are installed (`which claude codex gemini`).
4. Launch the other CLIs as **parallel background Bash tasks** and your own model as a **subagent**, all in parallel.
5. Collect results from all models.
6. **Report transparently**: before synthesizing, tell the user which models responded, which failed or timed out, and any issues encountered.
7. Present each model's response in its own section with clear attribution.
8. Provide a unified synthesis highlighting where the models agree, disagree, and what unique insights each contributed.

## Guidelines

- Think about how much you want to reveal about your own opinion when crafting the prompt.
- If a CLI fails or times out, report it and continue with the results you have.
