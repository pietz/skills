# Code Audit Skill

A coding agent skill that performs structural health assessments on codebases using parallel multi-lens analysis. This file is documentation for humans — it is not read by the agent during execution.

## What This Skill Does

When a user asks to "audit this codebase," "assess code quality," or "find technical debt," this skill runs a structured three-phase workflow:

1. **Scout** — A sub-agent maps the codebase: file inventory, architecture, conventions, dependency graph, utility inventory, and risk hotspots. Writes a structured codemap to `.audit/codemap.md`. Optionally runs static analysis tools.
2. **Parallel Lens Analysis** — Independent sub-agents, each with a focused checklist, investigate the codebase from different angles simultaneously. Each lens reads the codemap and uses Grep/Read to examine relevant files on demand.
3. **Synthesis & Verification** — The orchestrator collects findings, verifies P0/P1 evidence by reading cited code, deduplicates, groups by theme, and writes the final report to `.audit/report.md`.

The output is a prioritized, evidence-backed report grouped by theme — not a flat list of line-level nits.

## Architecture: Pull-Based Design

The skill uses a **pull-based architecture** where agents read files from disk on demand, rather than having all code pushed into prompts. This was designed to scale from small repos (~10 files) to large ones (500+ files) without hitting context window limits.

```
Orchestrator (thin — never reads source code)
│
├── Phase 1: Scout sub-agent
│   ├── Reads and maps the codebase
│   └── Writes: .audit/codemap.md, .audit/static-analysis.md
│
├── Phase 2: Lens sub-agents (parallel)
│   ├── Each reads codemap from disk
│   ├── Each uses Grep/Read to investigate relevant files
│   └── Each writes: .audit/lens-{name}.md
│
└── Phase 3: Synthesis (orchestrator)
    ├── Reads lens outputs from disk
    ├── Verifies P0/P1 findings by reading cited code
    └── Writes: .audit/report.md
```

### Key Design Decisions

- **Scout writes to disk, lenses read from disk** — avoids passing large payloads through prompts
- **Lens agents are self-directed** — they receive a codemap and use tools to investigate, rather than receiving all code in their prompt
- **Orchestrator stays lightweight** — it dispatches agents and synthesizes results, never reading source code directly (except for P0/P1 verification)
- **Verification step** — the orchestrator spot-checks high-severity findings, catching hallucinated evidence and overblown severity

### Runtime Artifacts

Each audit creates an `.audit/` directory in the target repo:

```
{repo}/.audit/
├── codemap.md              ← Phase 1: codebase structure map
├── static-analysis.md      ← Phase 1: linter/type checker output
├── lens-code-health.md     ← Phase 2: lens findings
├── lens-cross-module.md
├── lens-refactoring.md
├── lens-security.md
├── lens-correctness.md     ← Only if correctness lens was requested
└── report.md               ← Phase 3: final synthesized report
```

## What This Skill Does NOT Do

- **Line-level correctness checking.** The correctness lens exists but is opt-in only.
- **Code modification.** The skill analyzes and reports but never changes code files.
- **Change-level review.** Does not review PRs, diffs, or individual commits.
- **Exhaustive security audit.** Not a replacement for dedicated security tooling or penetration testing.

## The Lens System

Each lens is a sub-agent with a specific checklist. Research shows LLMs perform significantly better with directed checklists than with open-ended "review thoroughly" prompts.

| Lens | Scope | Role | Default |
|------|-------|------|---------|
| Code Health & Conventions | File | Duplication, complexity, convention violations, missed reuse | Always |
| Cross-Module Coherence | Module / System | Broken contracts, boundary violations, coupling, drift | Always |
| Refactoring Opportunities | Structural | Code smells, dead code, consolidation/extraction candidates | Always |
| Security & Performance | Cross-cutting | Vulnerabilities, adversarial patterns, perf anti-patterns | Always |
| Correctness & Logic | Line / Function | Logic errors, edge cases, type safety, state transitions | Opt-in only |

### Why Parallel Lenses?

Research (SWRBench, 2025) showed a +43.67% F1 improvement when aggregating multiple independent reviews versus a single-pass review. Each lens has a narrow focus, which means higher precision per lens, independent failure modes, and full parallelizability.

## Evidence Standards

- **Every finding** must reference at least one concrete code location. No location, no finding.
- **P0/P1 findings** require tool confirmation or concrete code evidence with a reproducible failure path. Findings that can't meet this bar get downgraded or moved to Questions.
- **Cross-module findings** require evidence from multiple files.
- **Dependency mapping** must be tool-grounded (grep/glob), not inferred from naming.

## Research Basis

Built on a curated research base of 46 verified arXiv papers (2025-01 to 2026-02). Key findings that shaped the design:

| Finding | Source | Impact on Skill |
|---------|--------|----------------|
| Directed checklists: 64% → 82% precision | ECSA, 2025 | Specific checklists per lens |
| Multi-review aggregation: +43.67% F1 | SWRBench, 2025 | Parallel independent lenses |
| Structured rules: 75% precision | BitsAI-CR, 2025 | Rule-based checklists per scope |
| 19-35% of LLM refactorings are non-equivalent | Multiple, 2025 | Differential verification in refactoring guide |

## File Structure

```
code-audit/
├── SKILL.md                          ← Orchestrator flow (read by agent at trigger)
├── README.md                         ← This file (human docs, not read by agent)
├── phases/
│   └── phase-1-scout.md              ← Scout agent instructions (read by scout sub-agent)
└── references/
    ├── lens-code-health.md           ← Code Health lens: checklist + operating instructions
    ├── lens-cross-module.md          ← Cross-Module Coherence lens
    ├── lens-refactoring.md           ← Refactoring Opportunities lens
    ├── lens-security-performance.md  ← Security & Performance lens
    ├── lens-correctness.md           ← Correctness & Logic lens (opt-in)
    └── refactoring-guide.md          ← Structured refactoring workflow (separate from audit)
```

Only `SKILL.md` is loaded by the agent when the skill is triggered. Sub-agents read their instruction files from disk during execution.
