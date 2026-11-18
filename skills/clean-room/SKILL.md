---
name: clean-room
description: Clean-room redesign of existing software. Describe what the system must do without reference to how it is built, have isolated agents that cannot see the code design it from scratch, then compare their designs with the real thing to find what to protect and what to simplify or change. Use for refactoring accreted complexity, reviewing whether a product's core concepts are right, or deciding on a rewrite. NOT for bug fixes, feature work, style cleanup, or refactors whose change is already obvious.
disable-model-invocation: true
metadata:
  version: "2.0.0"
---
# Clean-room redesign

Your enemy is **anchoring**. Once you have read an implementation, its structure becomes your picture of what the system "must" be, and you propose variations of it instead of seeing that it could be much smaller or shaped differently. A clean-room design breaks the anchor: the designer gets a description of *what* the system must do and is structurally unable to see *how* it is done today. Comparing that design with the real one is the review.

The method works at two scales:

- **Refactor:** one module or subsystem. Input is a behavior contract; output is a leaner implementation plan.
- **Concept review:** a whole product. Input is the product idea, hard constraints and use cases; output is which core concepts to protect and which to change.

## Workflow

**1. Agree on a target and a mode.** Survey the codebase and propose where to focus and which scale fits. Prefer one bounded piece over "everything at once", and say why: a bounded target gets a real redesign, a sprawling one gets hand-waving. Let the user pick or override. Don't go deeper until they have chosen.

**2. Write the brief.** This is the only thing the clean-room designers will see, so getting it right is the whole game.

- *Refactor:* a behavior contract. Record what the target does **as observed by its callers**: inputs and outputs, errors, effects on stored data, ordering, timing, permissions, compatibility. Read the old code and its tests to *discover* this, but record only what is externally observable. Fan the reading out over parallel sub-agents and merge into one contract. Structure it by capability, not by source file: the old module layout is itself an anchor.
- *Concept review:* the product in a paragraph, the hard constraints (platform, size budget, performance rules, security model), the question to answer ("what is the smallest set of concepts from which these use cases fall out?"), and a numbered list of concrete use cases, roughly 20 to 40, grouped by area. Use cases are the contract here: write each as what a user does and expects, never as how the current product does it.

Either way, non-functional constraints go in as requirements, never as mechanisms. When you hit something clever (a cache, a retry dance, a hand-rolled pool), record the requirement it serves ("p95 under 200ms", "concurrent webhooks must not race"), not the technique. The fresh design either reinvents something equivalent, proving it was necessary, or meets the requirement more simply, proving it was incidental. If nobody can name what a piece of cleverness serves, keep it and flag it as a question for the user.

**3. Attack the brief.** Everything downstream comes from the brief alone, so an omission is silent behavior loss. Spawn a fresh sub-agent that reads the old code, tests and docs with one job: find observable behaviors or use cases the brief misses (error cases, defaults, ordering, side effects) and any line that leaks *how*. Fold real findings back in; repeat until a pass comes back empty.

**4. Run the clean-room designs.** Give the whole brief to designer agents that **must not read the repository**: no source, docs, specs, READMEs or git history. Make that structural wherever you can (an agent or workspace without the repo), and state it explicitly in the prompt either way, with the reason: "an implementation exists; designs made after reading it only ever propose variations of it." Web search for facts about competitors or prior art is fine.

- **Use two designers from different model families** (e.g. one Claude, one GPT) at top tier. One design is an opinion; two independent designs that agree are evidence.
- **Give each designer the whole brief.** Don't split the design across per-subsystem agents, or you bury the cross-cutting wins (one error shape, one shared gate, one concept that replaces three) that only show up when one designer holds the entire surface.
- **Ask for:** the smallest set of concepts, contracts and connection points; a walk through every use case or contract clause showing how it falls out; and what they deliberately *didn't* build and why.
- It is a thinking and writing task: designers change no files.

If you truly can't spawn an isolated agent, design it yourself from the brief alone, and when you catch yourself reaching back to the old structure for the shape of the new one, stop and re-derive.

**5. Compare against the real code, with evidence.** Only now set the designs beside the actual implementation. Sort every difference into one of these:

- **Both designs landed on what exists:** the foundation is probably right. List it under *what to protect*.
- **Both designs differ from what exists, in the same direction:** a strong candidate for change, of the kind someone who had read the code would not think of.
- **The designs disagree with each other:** an open question for the user, not a recommendation.
- **The real code is heavier than either design needs:** point to the concrete location and explain *why* it exceeds the brief (an abstraction with one caller, a layer that only forwards, state that's never read, the same concept described in four places).

Run the comparison the other way too: where a design handles a clause differently from the real code, either the brief or the design is wrong, and that must be resolved before any code changes. Check every sharp claim in the code yourself before you report it, and mark it verified.

Optional extra lenses for a concept review, run alongside the designers: a **hands-on walkthrough** (an agent writes and runs real examples against today's contract and reports where it hurts) and **archaeology** (what earlier versions had, and which dropped ideas were lost by accident rather than on purpose).

**6. Present, get approval, then implement in stages.** Write the result up in plain words: what to protect, the candidates for change (each with what happens today, what the designs do instead, a concrete example and why it matters), open questions, and what you deliberately left alone. Candidates are not recommendations until the user has weighed them. Stop here; implementation needs the user's go-ahead.

When approved, first pick the oracle: sort existing tests into behavior-level (must pass throughout) and structure-level (expected to die with the old internals), and write tests for any unverified contract behavior against the *old* code first, so they are proven to capture current behavior. Then change the code in small stages, keeping the contract intact at every step, so the work can be checked and stopped at any point.

## Rules that hold throughout

**The brief is behavior-only.** It never mentions specific libraries, data structures, algorithms, internal names or layering. If a line would change when someone rewrites the internals without changing what a user or caller sees, it is implementation detail: delete it. The test: could you hand the brief to someone who has never seen the code and have them build a drop-in replacement? If it leaks *how*, the fresh design will just rebuild what exists.

**Isolation is structural, not a promise.** A designer that can open the repo will, and the anchor pulls harder than you expect. Never paste code, file names or excerpts of the current design into a designer's prompt.

**Preserve anything you can't prove is dead.** Quirks, edge cases, odd timing, undocumented but relied-upon behavior: presume it is load-bearing unless you can show otherwise. Not understanding why something exists is a reason to keep it and flag it, never license to remove it.

**"Already lean" is a real answer.** If the independent designs converge on roughly what exists, that is a trustworthy verdict that the code is healthy: report it as a success. Don't invent simplifications to justify the exercise; manufactured cleanup is worse than none.

**Line count is a symptom, not the goal.** Fewer lines tends to follow from a simpler design, but preserving behavior always outranks shrinking the code.
