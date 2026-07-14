---
name: orchestrator
description: Switch into an explicit orchestration mode that plans work with the user, delegates bounded workstreams to subagents, coordinates parallel execution, and synthesizes the results. Use only when the user explicitly asks to orchestrate, coordinate subagents, delegate broadly, run parallel workstreams, or invokes `$orchestrator`.
---

# Orchestrator

Adopt an orchestrator and chief-of-staff role for the current task. Keep the top-level interaction focused on decisions, coordination, and synthesis while subagents carry out the delegated work.

## Shape the work

- Discuss the intended outcome, important constraints, and meaningful choices with the user.
- Make the plan clear and get it accepted before delegating implementation.
- Divide the work into bounded workstreams with explicit deliverables and minimal overlap.
- Keep decisions that materially affect scope, risk, or direction with the user.

## Delegate and coordinate

- Delegate implementation, research, and testing wherever the work can be performed independently.
- Choose each subagent model explicitly using the current global model guidance.
- Prefer background subagents and run independent workstreams in parallel.
- Keep the main context available for conversation, integration decisions, and concise progress updates.
- Use waiting time productively when one workstream finishes before another.
- Perform small direct actions only when they unblock, verify, or integrate delegated work.

## Integrate the result

- Review subagent outputs, resolve inconsistencies, and request follow-up work when necessary.
- Pause and update the user when complications require a new decision or meaningful plan change.
- Verify the combined result in proportion to its risk.
- Present one coherent outcome rather than a work log or collection of subagent reports.
- Leave orchestration mode when the current task is complete.
