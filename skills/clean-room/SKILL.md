---
name: clean-room
description: Clean-room review of a module or a whole product. A fresh designer who never sees the code designs it from a brief; comparing that design with the real implementation shows what to protect, simplify or change. Use only when the user explicitly invokes it.
disable-model-invocation: true
metadata:
  version: "2.2.0"
---
# Clean-room review

Your enemy is **anchoring**. Once you have read an implementation, its structure becomes your picture of what the system "must" be, and you propose variations of it instead of seeing that it could be much smaller or shaped differently. So a fresh designer who has never seen the code designs it from a brief, and you compare that design with the real one.

You, the lead, read the code: you write the brief and do the comparison, but **you never do the design**.

Two modes:

- **Refactor** (one module or subsystem): the brief is a behavior contract the new design must keep. Output: a leaner implementation plan.
- **Concept review** (a whole product): the brief is the product idea, hard constraints and use cases, and the point is to find where the product's concepts should change. Output: a review. Building any change is a separate task.

## Workflow

**1. Agree on target and mode.** If the user named them, take them. Otherwise propose one bounded target and a mode, and let the user choose.

**2. Write the brief.** It is the only thing the designer sees.

- *Refactor:* what the target does **as observed by its callers**: inputs and outputs, errors, effects on stored data, ordering, timing, permissions, compatibility. Test: could someone who never saw the code build a drop-in replacement from it?
- *Concept review:* the product in a paragraph, the hard constraints, the question ("what is the smallest set of concepts from which these use cases fall out?"), and 20-40 concrete use cases. Include use cases the product can't handle today, taken from what users of this kind of product expect; use cases drawn only from the current product can show "simpler" but never "missing".

Write requirements, never mechanisms: no libraries, internal names, data structures or layering. Where you find something clever (a cache, a retry loop), write down the need it serves, not the technique.

**3. Audit the brief.** A fresh agent reads the code and the brief once and reports behavior or use cases the brief misses and lines that leak *how*. Fix the brief.

**4. Get the design.** Start a fresh agent, top tier, with only the brief. Tell it not to read the repository or look up the product, and why: designs made after reading an implementation only propose variations of it. Ask for the smallest set of concepts, a walk through every use case or clause showing how it is handled, and what it deliberately didn't build and why. If you can't start a fresh agent, give the user the brief to run in a new session; don't design it yourself.

**5. Compare with the real code.** Check the design covers every clause first: smaller because it dropped something is not simpler. Then:

- **Where the design matches what exists:** probably right. Protect it.
- **Where it differs:** a candidate for change. Check what the code does today and point to where.
- **Where the code is heavier than the brief needs:** say where and why (an abstraction with one caller, a layer that only forwards, state that's never read).

**6. Report, then stop.** In plain words: what to protect, and each candidate with what happens today, what the design does instead, an example, and your recommendation. "Already lean" is a valid result; don't invent changes. Any change needs the user's go-ahead.

## Implementing an approved refactor

Sort existing tests into behavior tests (must keep passing) and structure tests (expected to go with the old internals). Add tests for any untested contract behavior against the *old* code first. Then change the code in small stages, keeping the contract intact at every step. Keep anything you can't prove is dead and flag it.
