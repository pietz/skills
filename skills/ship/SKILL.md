---
name: ship
description: Finish a build session by shipping the work. Ensure tests exist and pass, validate the functionality, spawn a fresh-eyes subagent review when the change is large or risky, then commit and push to main. Use when the user says "ship", "ship it", "wrap this up and push", "test, commit and push", or otherwise wants the session's changes tested, reviewed, committed, and pushed.
metadata:
  version: "1.1.2"
---

Finish what you were tasked with, if you haven't already, and ship it to
main. Invoking this skill is the explicit permission to commit and push.

Make sure the work is tested and validated in proportion to what it is: add
missing tests, run the full suite, and where it means something, exercise the
feature the way a user would rather than trusting the tests alone.

If the change is large or risky enough that you can no longer see it with
fresh eyes, spawn a subagent to review the diff cold. It might over-report;
that's the cost of fresh eyes. Its findings are input, not a to-do list: you
have the session context, so judge each one yourself. Fix what's material,
drop the nitpicks, and ask the user only when a finding is genuinely
debatable.

Then commit and push: stage only what belongs to this session's work, merge to
main if you're on a branch, never force push. Say so if the push triggers a
deploy.
