---
name: advisor
description: Consult a single top-tier advisor model for a focused second opinion on one hard, high-stakes question, then continue your own work. Pack a self-contained briefing, spawn the strongest available model as a read-only advisor, wait for its guidance, and decide. Use only when explicitly asked for advice or a second opinion, when stuck on a hard design or debugging decision, before committing to a risky approach, before declaring a hard task done, or when invoking `/advisor` or `$advisor`.
---

# Advisor

Summon a top-tier advisor to think hard about one focused question, then apply its guidance and keep working. This is the escalation pattern: a cheaper model drives the main loop and consults a stronger model at the decisions that determine the outcome.

You, the calling agent, stay in charge. The advisor gives an opinion; you decide. Any agent or subagent can invoke this.

The advisor is briefed, not shown the conversation. A scoped briefing beats dumping the full transcript: it is cheaper, it does not anchor the advisor to your existing reasoning traces, and it keeps its attention on the core question.

## When to use

- A hard design or architecture decision with real tradeoffs.
- A bug or failure that keeps recurring after reasonable attempts.
- A sanity check before committing to a risky or expensive approach.
- A final review before declaring a hard task done.

Reach for it proactively at these points, not only when the user asks. Skip it for routine work, quick lookups, or anything where the answer is already clear. It adds little when every step is easy and it costs a top-tier model call. For a multi-model council rather than one advisor, use `moa` or `peer-review` instead.

## Pick the advisor model

Use the strongest model available to your harness. The advisor must be at least as capable as you are.

- Claude Code: spawn a subagent with model `fable`, falling back to `opus` if Fable is unavailable, at the highest reasoning effort (`effort: max`, else `high`).
- Codex: spawn a subagent on the strongest model (GPT-5.x "Sol") at high reasoning.
- Any other harness: use its most capable model at its highest reasoning setting.

## Write a self-contained briefing

The advisor starts blind. It does not see this conversation. Pack everything it needs into the prompt:

- The one specific question or decision. Keep it to a single question.
- All relevant context inline: the code, error output, constraints, and requirements, pasted directly.
- What you have already tried and why it did not work.
- The options you are weighing, if any.
- The output you want back: a recommendation with reasoning, a chosen option, or a specific answer.

If the briefing would be too large to pack, narrow the question rather than sending the advisor exploring.

## Constrain the advisor

- Read-only: no edits, no writes, no shell mutations.
- Prefer to answer purely from the briefing. Allow at most 3 file reads and 1 web search, and only when genuinely needed to answer; then answer even if imperfect.
- No multi-step research and no open-ended exploration.
- The advisor is a leaf: it must not spawn its own subagents or call `/advisor`. In Claude Code, set `disallowedTools: Agent` on the advisor to guarantee this.

## Use the result

- Wait for the advisor's answer; you need it before continuing, so this consult is deliberately blocking.
- Weigh the advice against what you know. You own the decision, not the advisor.
- If the advice conflicts with the user's stated constraints, surface it rather than silently following it.
- If the advice went wrong because the briefing missed something, send a follow-up to the same advisor with the added context rather than starting over; it keeps its thread.
- Integrate the outcome and continue. Act on the advice; do not paste the raw advisor transcript at the user.
