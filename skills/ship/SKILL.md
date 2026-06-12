---
name: ship
description: Finish a build session by shipping the work. Ensure tests exist and pass, validate the functionality, spawn a fresh-eyes subagent review when the change is large or risky, then commit and push to main. Use when the user says "ship", "ship it", "wrap this up and push", "test, commit and push", or otherwise wants the session's changes tested, reviewed, committed, and pushed.
metadata:
  version: "1.0.0"
---

# Ship

Take the work from this session to done: tested, validated, reviewed if warranted, committed, pushed to main. Invoking this skill is the explicit instruction to commit and push, no further confirmation needed. You are the orchestrator and stay in the driver's seat for every judgment call below.

## 1. Take stock

Look at `git status` and the diff to see exactly what's about to ship. Restate to yourself what the change is supposed to do. That's the bar everything below is measured against.

## 2. Test

- Make sure the new behavior is covered by tests. Add what's missing; a feature that only works when poked manually isn't done.
- Run the full test suite, not just the new tests. Everything passes before moving on.

## 3. Validate

Tests prove the parts work; validation proves the feature works. Where feasible, exercise the functionality the way a user would: run the app, hit the endpoint, run the CLI on real input. Skip this only when the tests genuinely cover the full behavior, like a pure library function.

## 4. Fresh eyes (your call)

After a long session you're anchored: you've read your own code so often you see what you meant, not what's there. A subagent reading the diff cold doesn't have that problem. Spawn a review subagent when anchoring is a real risk:

- the diff spans several files or crosses subsystem boundaries
- it touches risky surfaces: auth, data migrations, deletion paths, money, concurrency
- the session involved a lot of rework or design decisions worth challenging
- you've been at it long enough that you can't honestly claim a fresh perspective

Skip it for small mechanical changes, single-file fixes, docs, or copy edits. Skipping is fine; the step is optional by design.

Give the reviewer the diff plus a short statement of intent, and ask for real problems only: bugs, broken edge cases, security issues, violations of existing codebase patterns. Explicitly not style nitpicks.

## 5. Triage findings

Fresh reviewers over-report; that's the cost of fresh eyes. You have the session context they lack, so you decide:

- **Fix** findings that are real and material: bugs, broken edge cases, anything that would embarrass the change in production. Re-run the tests after.
- **Drop** nitpicks and theoretical concerns that are too small to matter given the big picture. Don't burn time polishing what nobody asked about.
- **Ask the user** when in doubt: subjective tradeoffs, scope questions, anything where a reasonable person could go either way. A quick question beats a wrong unilateral call.

## 6. Commit and push

- Commit on main. If on a feature branch, merge it into main and delete the branch.
- Match the repo's existing commit message style (check `git log`). One focused commit per logical change; usually that's one commit.
- Push. If no remote or upstream is configured, say so instead of failing quietly.
- Close with a short summary: what shipped, how it was tested and validated, what the reviewer found if one was spawned, and what was fixed vs dropped.
