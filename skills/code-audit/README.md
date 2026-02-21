# Code Audit Skill

A coding agent skill that performs structural health assessments on codebases using parallel multi-lens analysis. This file is documentation for humans — it is not read by the agent during execution.

## What This Skill Does

When a user asks to "audit this codebase," "assess code quality," or "find technical debt," this skill runs a structured three-phase workflow:

1. **Context Assembly** — Reads the codebase, extracts conventions, maps dependencies, inventories utilities, and optionally runs static analysis tools. All of this happens before any judgment is made.
2. **Parallel Lens Analysis** — Dispatches independent sub-agents, each with a focused checklist, to analyze the code from different angles simultaneously.
3. **Synthesis** — Collects findings, deduplicates, groups by theme, assigns priority, and produces a structured report with a structural health summary.

The output is a prioritized, evidence-backed report grouped by theme — not a flat list of line-level nits.

## What This Skill Does NOT Do

- **Line-level correctness checking.** Finding logic bugs, off-by-one errors, and incorrect branching is the domain of tests, type checkers, and change-level review tools. The correctness lens exists but is opt-in only — it runs only when the user explicitly asks for it.
- **Code modification.** The skill is read-only. It analyzes and reports but never changes code files. Report artifacts (e.g., saving an `audit.md`) are only persisted when the user explicitly requests it.
- **Change-level review.** This skill does not review PRs, diffs, or individual commits. It assesses the structural health of the codebase as it stands. Change-level review is a commoditizing space well-served by existing tools.
- **Exhaustive security audit.** The security lens checks for common vulnerability patterns and adversarial concerns, but it is not a replacement for dedicated security tooling, penetration testing, or compliance audits.

## Why This Skill Exists

Built-in AI code review tools operate at the **change level** — they review PRs and diffs. They're good at catching issues in the code you just wrote. But they don't assess:

- How well modules interact with each other (cross-module coherence)
- Whether the codebase has accumulated structural debt over time
- Whether conventions have drifted across different parts of the repo
- Whether duplicated logic should be consolidated
- Whether dependency directions are being violated

These are **structural health** concerns. They're invisible when looking at individual files or changes, but they compound over time and become the primary source of maintenance burden. This is the gap this skill fills.

## Architecture

### The Three Phases

| Phase | Runs As | Purpose |
|-------|---------|---------|
| Phase 1: Context Assembly | Inline (main agent) | Build the context that all lenses need. No judgment yet. |
| Phase 2: Lens Analysis | Parallel sub-agents | Each lens runs independently with its own checklist. |
| Phase 3: Synthesis | Inline (main agent) | Merge, deduplicate, prioritize, and format the report. |

### The Lens System

Each lens is a sub-agent with a specific checklist. This design is based on research showing that LLMs perform significantly better with directed checklists than with open-ended "review thoroughly" prompts.

| Lens | Scope | Role | Default |
|------|-------|------|---------|
| Code Health & Conventions | File | Duplication, complexity, convention violations, missed reuse | Always |
| Cross-Module Coherence | Module / System | Broken contracts, boundary violations, coupling, drift | Always |
| Refactoring Opportunities | Structural | Code smells, dead code, consolidation/extraction candidates | Always |
| Security & Performance | Cross-cutting | Vulnerabilities, adversarial patterns, perf anti-patterns | Always |
| Correctness & Logic | Line / Function | Logic errors, edge cases, type safety, state transitions | Opt-in only |

### Why Parallel Lenses?

Research (SWRBench, 2025) showed a +43.67% F1 improvement when aggregating multiple independent reviews versus a single-pass review. Each lens has a narrow focus, which means:

- Higher precision per lens (directed attention beats generic scanning)
- Independent failure modes (one bad lens doesn't corrupt the others)
- Parallelizable (all lenses run concurrently)

### Why Not Correctness by Default?

The correctness lens was deliberately excluded from the default set after expert review. The reasoning:

1. **Scope discipline.** This skill's differentiator is structural health analysis — the area where existing tools don't operate. Correctness checking is exactly what line-level review tools already do well.
2. **Cost efficiency.** Adding correctness to every audit increases token cost without proportional structural insight.
3. **Signal dilution.** Mixing line-level logic findings with structural findings makes the report harder to act on.

The correctness lens remains available for users who explicitly request it. When activated, it focuses on high-risk logic: complex branching, state transitions, error paths, and cross-module contract assumptions.

## Scalability

The skill uses tiered routing based on codebase size:

| Tier | Scope | Strategy |
|------|-------|----------|
| Small | <~30 files | Read everything. Run all lenses. Full coverage. |
| Medium | ~30–100 files | Module-parallelized context assembly. Prioritized lens ordering. |
| Large | 100+ files | Architecture map first, then risk-based sampling with explicit context budget. |

For large repos, the skill requires:
- A **context budget plan** before lens analysis begins (which modules, which files, why, what's deferred)
- An explicit **coverage declaration** in the output (what was audited, what was excluded, what's queued for follow-up)
- **No implicit completeness claims** — if the audit didn't cover everything, it says so

## Evidence Standards

The skill enforces evidence requirements at multiple levels:

- **Every finding** must reference at least one concrete code location (file + line or function). No location, no finding.
- **P0/P1 findings** (Critical/High) require either tool confirmation (static analysis, type checker, build error) or concrete code evidence with a reproducible failure path. If a finding can't meet this bar, it gets downgraded to P2 or moved to Questions.
- **Cross-module findings** require evidence from multiple files. If only one side of an inconsistency can be demonstrated, the finding is classified as a Question, not an assertion.
- **Dependency mapping** must be tool-grounded (grep, glob, reference tracing) — not inferred from naming conventions or assumptions.

These rules exist because LLM nondeterminism makes false positives the primary trust barrier. A high-precision, lower-volume report is more useful than a noisy comprehensive one.

## Static Analysis Integration

Before any lens runs, the skill attempts to detect and run available static analysis tools in the project (linters, type checkers, build checks). The output is injected into every lens prompt. This serves two purposes:

1. **Grounding.** Tool-confirmed issues are higher confidence than LLM-only hypotheses. Lenses cross-reference static analysis output before raising their own findings.
2. **Deduplication.** If a linter already flagged something, the lens doesn't need to independently discover it — it can focus its attention on issues that tools can't detect.

If no static analysis tools are available, this is explicitly noted in the lens context.

## Security: Adversarial Controls

The security lens includes checks specifically for AI-assisted development workflows:

- **Prompt injection in repo content** — comments, docs, or scripts designed to manipulate LLM behavior
- **Command-execution abuse paths** — configs or scripts that could steer an agent into unintended commands
- **Secret/data exfiltration paths** — credentials leaking through logs, CI, or tool outputs
- **Unsafe permission boundary assumptions** — agent workflows assuming permissions they shouldn't have

These are relevant because the skill itself reads code into prompts. The codebase being audited is an attack surface.

## Finding Format

Each finding includes:

| Field | Purpose |
|-------|---------|
| Priority | P0 (Critical) through P3 (Low) |
| Complexity | Effort/risk to fix: low, medium, high |
| Validity | How objective the finding is: high, medium, low |
| Location | File and line reference |
| Evidence | Specific code observation |
| Impact | What goes wrong or what's at risk |
| Suggestion | Concrete fix or investigation step |
| Validation | Specific tests, checks, or CI steps to verify the fix |

Findings are grouped by theme (e.g., "Error handling inconsistencies across modules") with a remediation path and estimated effort per theme. The report ends with a structural health summary, coverage declaration, and recommended next steps.

## Research Basis

This skill was built on a curated research base of 46 verified arXiv papers (2025-01 to 2026-02) plus vendor documentation. Key findings that shaped the design:

| Finding | Source | Impact on Skill |
|---------|--------|----------------|
| Directed checklists improve precision from 64% to 82% | ECSA, 2025 | Each lens has a specific checklist, not generic "review thoroughly" prompts |
| Multi-review aggregation improves F1 by +43.67% | SWRBench, 2025 | Parallel independent lenses rather than single-pass review |
| Structured rules achieve 75% precision | BitsAI-CR, 2025 | Rule-based checklists per scope level |
| 19-35% of LLM refactorings are non-equivalent | Multiple, 2025 | Differential verification in refactoring guide |
| ~21% of non-equivalences are missed by tests | Multiple, 2025 | Emphasis on semantic preservation, not just test passage |
| Medium-granularity problems are underserved | Gap analysis | Cross-Module Coherence as a primary lens |

**Evidence quality tiers used during research:**
- **High confidence:** Claims backed by multiple primary papers and benchmark evidence
- **Medium confidence:** Claims backed by one paper or one experience report
- **Low confidence:** Vendor/blog claims without independent replication

The full research base, paper index, and analysis reports are maintained separately from the skill source.

## Limitations

1. **LLM nondeterminism.** Different runs on the same codebase will produce somewhat different findings. The severity gating rule and evidence requirements mitigate this but don't eliminate it.
2. **Context window constraints.** Large codebases can't be fully read into context. The scalability routing and context budget system manage this, but some information loss is inevitable at scale.
3. **No runtime analysis.** The skill analyzes static code only. It cannot detect issues that only manifest at runtime (race conditions under load, performance under real data volumes, etc.).
4. **Dependency on code quality of context.** The lens analysis is only as good as the context it receives. If Phase 1 misses a dependency or mischaracterizes a convention, downstream lenses may produce lower-quality findings.
5. **No historical awareness.** Each audit is a point-in-time snapshot. The skill does not track findings across audits or differentiate between new and pre-existing issues. (This is a candidate for future development.)
6. **Security lens is not a security audit.** The security checks cover common patterns and adversarial concerns but are not a substitute for dedicated security tools, penetration testing, or compliance reviews.
7. **Language agnostic but not equally strong.** The skill works on any language, but the underlying LLM may have stronger pattern recognition for widely-used languages (Python, JavaScript/TypeScript, Java, Go) than for niche ones.

## File Structure

```
code-audit/
├── SKILL.md                          ← Main skill file (read by the agent)
├── README.md                         ← This file (human documentation, not read by agent)
└── references/
    ├── lens-code-health.md           ← Checklist for Code Health & Conventions lens
    ├── lens-cross-module.md          ← Checklist for Cross-Module Coherence lens
    ├── lens-refactoring.md           ← Checklist for Refactoring Opportunities lens
    ├── lens-security-performance.md  ← Checklist for Security & Performance lens
    ├── lens-correctness.md           ← Checklist for Correctness & Logic lens (opt-in)
    └── refactoring-guide.md          ← Structured refactoring workflow (separate from audit)
```

Only `SKILL.md` is loaded by the agent when the skill is triggered. It references the lens files and refactoring guide as needed during execution.
