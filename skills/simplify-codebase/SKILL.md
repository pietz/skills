---
name: simplify-codebase
description: Find and remove incidental architectural complexity in an existing codebase — structure that accreted through many locally-reasonable edits until the whole became more complex than the problem warrants. Preserves what the software does for its callers while simplifying how it's built. NOT for bug fixes, feature work, formatting/style cleanup, or refactors whose change is already obvious.
metadata:
  version: "1.0.0"
---
# Simplifying a codebase

Your enemy is **anchoring**. The moment you read the existing implementation, its structure becomes your mental model of what the system "must" be, and you produce cosmetic tidying instead of seeing that a large structure could be radically smaller. The workflow below exists to break that anchor: you derive what the code *does* from the outside, then design its replacement from that alone — never from the current code. The rules after it hold at every step.

## Workflow

**1. Agree on a target.** Survey the codebase and propose where to focus. Prefer one bounded piece (a module, a subsystem) over "everything at once," and say why — a bounded target gets a real redesign, a sprawling one gets hand-waving. Let the user pick the scope or override your suggestion. Don't go deeper until they've chosen.

**2. Write the behavior contract.** Record what the target does **as observed by its callers**: inputs and outputs, errors raised, effects on stored/persisted data, ordering guarantees, timing, permissions, and compatibility expectations. Read the old code and its tests to *discover* this — but record only what's externally observable. Parallel sub-agents fit here: fan the reading out across modules and merge into one contract. Non-functional constraints belong in it too, stated as requirements, never as mechanisms: when you hit something clever (a cache, a retry dance, a hand-rolled pool), record the requirement it serves ("p95 under 200ms", "concurrent webhooks must not race"), not the technique: the fresh design either reinvents something equivalent (proof it was necessary) or satisfies the requirement more simply (proof it was incidental). If nobody can name what a piece of cleverness serves, keep it and flag it as a question for the user. Structure the contract by capability, not by source file: the old module layout is itself an anchor. (See the contract rule below; getting this right is the whole game.)

**3. Attack the contract.** Everything downstream is generated from the contract alone, so an omission is silent behavior loss. Spawn a fresh sub-agent that reads the old code and tests with one job: find externally observable behaviors the contract misses: error cases, defaults, ordering, side effects. Fold real findings back in; repeat until a pass comes back empty.

**4. Design fresh from the contract.** Working **only from the contract**, design the simplest thing that satisfies it, as if the current implementation didn't exist. **Do this in a single sub-agent that is given only the contract and no access to the existing code** — being structurally unable to peek beats resolving not to, because the anchor pulls harder than you expect. Give that one agent the *whole* contract; don't split the design across per-subsystem agents, or you bury the cross-cutting wins (one error shape, one shared gate) that only surface when one designer holds the entire surface at once. (If your environment truly can't spawn an isolated agent, do it yourself from the contract alone, and if you catch yourself reaching back to the old structure for the shape of the new one, stop and re-derive.) Output two things: the lean design, and what you deliberately *didn't* build and why (abstractions, layers, options, generality the contract doesn't demand).

**5. Compare against the real code, with evidence.** Now — and only now — set the lean design beside the actual implementation. For each place the real code is heavier, point to the concrete location and explain *why* it exceeds what the contract requires (e.g. an abstraction with one caller, a layer that only forwards, state that's never read). Give the user enough to tell real bloat from complexity that exists for a reason they may know and you don't. Run the comparison in the other direction too: where the design handles a contract clause differently than the real code does, either the contract or the design is wrong, and it must be resolved before any code changes.

**6. Get approval, then implement in stages.** Stop after presenting the analysis and plan; implementation needs the user's go-ahead. When approved, first pick the oracle: sort existing tests into behavior-level (must pass throughout) and structure-level (expected to die with the old internals), and write tests for any unverified contract behaviors against the *old* code first, so they're proven to capture current behavior. Then change the code in small stages, keeping the external behavior (the contract) intact at every step, so the work can be checked and stopped at any point.

## Rules that hold throughout

**The contract is behavior-only.** It must never mention specific libraries, data structures, algorithms, internal function/class names, or layering. If a line would change when someone rewrites the internals without changing what a caller sees, it's implementation detail — delete it. The test: could you hand this contract to someone who has never seen the code and have them build a drop-in replacement? If it leaks *how*, it fails — and the fresh design will just rebuild what exists.

**Preserve anything you can't prove is dead.** Quirks, edge cases, odd timing, undocumented-but-relied-upon behavior: presume all of it load-bearing unless you can show otherwise. Not understanding why something exists is never license to remove it — it's a reason to keep it and flag it.

**"Already lean" is a real answer.** If your independent design converges on roughly what exists, that's a trustworthy verdict that the code is healthy — report it as a success. Do not invent simplifications to justify the exercise; manufactured cleanup is worse than none.

**Line count is a symptom, not the goal.** Fewer lines tends to follow from a simpler design, but preserving behavior always outranks shrinking the code.
