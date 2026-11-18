---
name: clean-room
description: Clean-room review of a module or a whole product. Independent designers who never see the code design it from a brief; comparing their designs with the real implementation shows what to protect, simplify or change. Use only when the user explicitly invokes it.
disable-model-invocation: true
metadata:
  version: "2.1.0"
---
# Clean-room review

Your enemy is **anchoring**. Once you have read an implementation, its structure becomes your picture of what the system "must" be, and you propose variations of it instead of seeing that it could be much smaller or shaped differently. A clean-room design breaks the anchor: a designer gets a description of *what* the system must do and has no way to see *how* it is done today. Comparing that design with the real one is the review.

You, the lead, will read the code. That makes you the most anchored party in the run: you write the brief and do the comparison, but you never do the design.

Two modes:

- **Refactor** (one module or subsystem): the brief is a behavior contract, and the new design must keep it. Output: a leaner implementation plan.
- **Concept review** (a whole product): the brief is the product idea, hard constraints and use cases, and the point is to find where the contract itself should change. Output: a review document. Building any change is a separate task.

Save every artifact (brief, designs, comparison) to files in a working folder outside the repo as you go, so a long run survives context compaction.

## Workflow

**1. Agree on target, mode and cost.** If the user already named the target and mode, take them. Otherwise survey the codebase and propose one bounded target and a mode, and say why: a bounded target gets a real redesign, a sprawling one gets hand-waving. Say roughly what the run costs (two top-tier designers plus a few reading agents) before you start.

**2. Write the brief.** It is the only thing the designers see, so getting it right is the whole game.

- *Refactor:* record what the target does **as observed by its callers**: inputs and outputs, errors, effects on stored data, ordering, timing, permissions, compatibility. Read the old code and tests to *discover* this, but write down only what is externally observable. For a large target, fan the reading out over parallel sub-agents. Keep exact public names and formats where callers depend on them. Structure it by capability, not by source file.
- *Concept review:* the product in a paragraph, the hard constraints (platform, size budget, performance rules, security model), the question ("what is the smallest set of concepts from which these use cases fall out?"), and 20-40 numbered use cases grouped by area. Take the use cases from what users of this category expect (competitors, the roadmap, the user), **including ones the product can't do today**. Use cases drawn only from the current product can show "simpler" but never "missing".

Mark each item **required**, **observed today**, or **unknown**, and keep your evidence for it in a separate file the designers never see. Don't turn guesses into requirements: a cache is not proof of a latency target. When something clever has no requirement anyone can name, leave it out of the brief, list it separately, and ask the user.

Write requirements, never mechanisms. Avoid the product's name and its internal nouns where a plain description works: every internal term you use hands the existing concept to the designers.

**3. Audit the brief once.** A fresh sub-agent reads the old code, tests and docs and reports (a) observable behavior or use cases the brief misses, (b) any line that leaks *how*, and (c) internal nouns or groupings that mirror the existing structure. Fold in the real findings. Run a second pass only if the first changed something material; after that, list remaining gaps in the report rather than looping.

**4. Run the clean-room designs.** Isolation must be structural; asking a designer not to look is not enough.

- Put the brief in a new empty folder outside the repo. Start each designer **there**, as a fresh session with no conversation history: a delegated task or a separate CLI process (`claude -p`, `codex exec --skip-git-repo-check`, `pi -p`). A designer started inside the repo gets its `CLAUDE.md`/`AGENTS.md` loaded automatically, and a sub-agent that inherits your conversation has already seen the code.
- Tell each designer it must not read the repository or search the web for the product itself, and why: "an implementation exists; designs made after reading it only propose variations of it." Searching for competitors and prior art is fine.
- Use **two designers from different model families** (e.g. one Claude, one GPT), top tier, each with the **whole** brief. Splitting the design across agents buries the cross-cutting wins that only show up when one designer holds the entire surface.
- Ask each for: the smallest set of concepts, contracts and connection points; a walk through every use case or clause showing how it falls out; and what they deliberately didn't build and why. Designers write; they change no files.
- Afterwards, check each designer's tool log. Discard and rerun any design whose author opened project files or looked the product up.

If you can't start an isolated designer, don't design it yourself. Hand the user the brief, ready to paste into a fresh session, and mark the design step as pending. With only one designer, report it as one opinion and make no claims about convergence.

Optional lenses for a concept review, run in parallel with the designers: a **hands-on walkthrough** (an agent writes and runs real examples against today's contract and reports where it hurts) and **archaeology** (what earlier versions had, and which dropped ideas were lost by accident rather than on purpose).

**5. Compare against the real code.** First check each design against every clause: a design that is smaller because it dropped a clause is not a simplification. Then, for every consequential difference, cite the clause, verify what today's code does (mark that observation verified), and sort it:

- **Both designs match what exists:** probably right, *if the brief didn't hand them the concept*. List it under what to protect.
- **Both differ from what exists, in the same direction:** a strong candidate for change.
- **The designs differ from each other:** often both are valid. Find a case that tells them apart, weigh complexity, migration cost and user impact, and recommend one. Leave it to the user only when it turns on a product preference or an unknown requirement.
- **The real code is heavier than the brief needs:** point to the location and say why it exceeds the brief (an abstraction with one caller, a layer that only forwards, state that's never read, one concept described in four places).

For a concept review, also score every use case as clean, awkward or impossible today; the awkward and impossible ones usually drive the findings. For a refactor, where a design's observable behavior differs from the old code, either the brief or the design is wrong: resolve it before any code changes.

**6. Report, then stop.** Write it up in plain words: what to protect; each candidate with what happens today, what the designs do instead, a concrete example, why it matters, your recommendation and how strong the evidence is; open questions; and what you deliberately left alone. "Already lean" is a real answer: if two isolated designs converge on roughly what exists, report that as a success and don't invent simplifications. Stop here; any change needs the user's go-ahead.

## Implementing an approved refactor

First pick the oracle: sort existing tests into behavior-level (must pass throughout) and structure-level (expected to die with the old internals), and write tests for any unverified contract behavior against the *old* code first, so they are proven to capture current behavior. Then change the code in small stages, keeping the contract intact at every step, so the work can be checked and stopped at any point. Preserve anything you can't prove is dead: not understanding why something exists is a reason to keep it and flag it.

For an approved product change from a concept review, record the change, an example that proves it works, and what happens to existing users and data, then treat it as ordinary feature work.
