---
name: code-audit
description: >
  Structural health assessment for codebases. Use when the user asks to audit
  code quality, assess code health, review a codebase, find technical debt,
  clean up code structure, or identify refactoring opportunities. Also use
  when asked to do a "code audit", "codebase review", "quality assessment",
  or "tech debt analysis". Provides parallel multi-lens analysis via sub-agents
  with specialized checklists for code health, cross-module coherence,
  refactoring detection, and security.
---

# Code Audit

Multi-lens audit system that uses parallel sub-agents with directed checklists to assess the structural health of a codebase. Built on research showing that LLMs find significantly more issues when given specific, scoped checklists than when asked to "review thoroughly" (BitsAI-CR: 75% precision with structured rules; ECSA: 64%→82% precision with prompt detail; SWRBench: +43.67% F1 with multi-review aggregation).

**Cost note:** Token and runtime cost scales with scope and the number of active lenses. For large repositories, narrow the audit scope before running — see Scalability Routing below.

**Model note:** This skill performs deep analytical work. Use the most capable model available.

## Core Principles

1. **Context before judgment** — Assemble architecture, conventions, dependency map, and utility inventory before auditing anything.
2. **Directed attention** — Each lens has a specific checklist. Generic scanning produces surface-level results.
3. **Convention-aware** — Audit against *this repo's* actual patterns, not generic best practices.
4. **Evidence-based** — Every finding must include file location, code evidence, and impact. No vague opinions.
5. **High signal** — 5 actionable findings beat 20 vague ones. Prefer precision over volume.
6. **Read-only** — The audit agent must not modify code files. If the user explicitly asks to persist report artifacts (e.g., saving an `audit.md`), ask for confirmation first. Report persistence is optional and user-driven, never default.

## Workflow Routing

| User Request | Workflow |
|---|---|
| "Audit this codebase / module / directory" | **Codebase Audit** — Three-phase lens analysis below |
| "Assess code quality / code health" | **Codebase Audit** — Same workflow |
| "Refactor this code" | **Refactoring** — Read [references/refactoring-guide.md](references/refactoring-guide.md) and follow that workflow |

**Uncommitted changes:** If the codebase has uncommitted changes, include them as additional context during the audit. They are part of the current state and may surface recent issues or in-progress patterns.

**Before starting:** Inform the user that a multi-lens code audit is a thorough, multi-step process that will consume a significant number of tokens. Confirm the audit scope (which directory, module, or repo) and proceed only after the user acknowledges.

## Scalability Routing

Before starting Phase 1, determine the scope tier and follow the corresponding strategy:

| Tier | Scope | Strategy |
|------|-------|----------|
| **Small** | Single module or <~30 files | Read everything. Run all lenses. |
| **Medium** | Multi-module or ~30–100 files | Full context assembly with module-parallelization. Run all lenses with prioritized ordering. |
| **Large** | 100+ files / full repo | Build architecture map first, then risk-based sampling and targeted deep dives. |

**Large tier requirements:**
- **Prioritization criteria:** Select modules for deep audit based on dependency fan-out, churn frequency, complexity, critical-path ownership, and security exposure.
- **Context budget plan** (before Phase 2): Document which modules are selected, which files are sampled, why they were selected, and what is deferred.
- **Hard rule:** If the audit does not cover the full codebase, say so explicitly. No implicit completeness claims.

**Coverage output** (required in Phase 3 for all tiers):
- `Coverage`: audited X/Y files, with selection criteria for Medium/Large tiers
- `Excluded Areas`: what was not inspected and why
- `Follow-Up Queue`: ordered list of next-pass targets for incomplete audits

---

## Phase 1: Context Assembly

**Run this inline (not as a sub-agent). This must complete before Phase 2.**

Gather everything the lenses need. Don't audit code yet — just build context.

### Step 0 — Static Analysis Pre-Pass

Detect and run any available static analysis, type checking, linting, or build checks in the project:
- Look for configured tools (e.g., `eslint`, `ruff`, `mypy`, `tsc --noEmit`, `clippy`, `go vet`)
- Run them and capture the output
- This output will be injected into lens prompts under `### Static Analysis Output`
- If no tools are available or configured, explicitly note `No static analysis tools available` in the lens context

**Priority rule:** Tool-confirmed issues (type errors, lint violations, build failures) are higher confidence than LLM-only hypotheses. Lenses should cross-reference static analysis output before raising their own findings on the same locations.

### Step 1 — Scope Mapping

- Identify the audit target: full repo, specific directory, or module.
- Map the target area's directory structure, entry points, and key modules.
- Understand the data flow and component relationships.
- Read the files in the audit scope.
- If uncommitted changes exist, note which files are affected and what changed.

### Step 2 — Convention Extraction

Scan the codebase for patterns. Produce a **convention fingerprint** (10-20 bullet points):
- Naming: variables, functions, classes, files, directories
- Error handling: how errors are caught, reported, propagated
- Code organization: file structure, export patterns, module layout
- Testing: naming, framework, setup/teardown, assertion style
- Common idioms: logging, config access, dependency injection, validation

### Step 3 — Dependency Map

Dependency mapping must be tool-grounded — use search, glob, grep, and reference tracing. Do not infer dependencies from naming conventions or assumptions.

For each public function, type, class, or export in the audit scope:
1. Grep/search for ALL callers and importers across the codebase
2. Identify downstream consumers and upstream producers
3. Record the dependency graph (which files depend on what)
4. For each critical dependency edge, include the observed location(s) as evidence

This is critical — the Cross-Module Coherence lens needs this to assess contract health and identify coupling issues. Hallucinated dependency graphs poison all downstream lenses.

### Step 4 — Utility Inventory

Note reusable helpers, shared types, constants, and common patterns that:
- Code in the audit scope should leverage (but might not)
- Exist as alternatives to duplicated implementations

### Step 5 — Lens Selection

**Always run:** Code Health, Cross-Module Coherence, Refactoring Opportunities, Security/Performance (Lenses 1-4).

**Correctness (Lens 5) is not included by default.** This skill focuses on structural health assessment — line-level correctness checking (logic bugs, off-by-one errors, incorrect branching) is the domain of tests, type checkers, and change-level review tools. Only include the correctness lens when the user explicitly requests it.

---

## Phase 2: Parallel Lens Analysis

**Dispatch sub-agents in parallel.** Launch all applicable lenses simultaneously in a single message using the Task tool.

### Lens Configuration

For each lens:
1. Read its reference file from `references/lens-*.md`
2. Construct the sub-agent prompt using the template below
3. Launch as a sub-agent using the Task tool
4. All lenses run concurrently — they are independent analyses

### The 5 Lenses

| # | Lens | Reference File | Scope | Role |
|---|------|---------------|-------|------|
| 1 | Code Health & Conventions | [lens-code-health.md](references/lens-code-health.md) | File | **Primary** — structural quality |
| 2 | Cross-Module Coherence | [lens-cross-module.md](references/lens-cross-module.md) | Module / system | **Primary** — the differentiator |
| 3 | Refactoring Opportunities | [lens-refactoring.md](references/lens-refactoring.md) | Proactive detection | **Primary** — structural debt |
| 4 | Security & Performance | [lens-security-performance.md](references/lens-security-performance.md) | Cross-cutting | Standard |
| 5 | Correctness & Logic | [lens-correctness.md](references/lens-correctness.md) | Line / function | Opt-in (user request only) |

### Sub-Agent Prompt Template

Each sub-agent receives this prompt structure:

```
You are performing a focused codebase audit analysis. Use ONLY the checklist
provided below — do not audit for concerns outside your checklist.
Return structured findings. If nothing is found, say so explicitly.

## Audit Context

### Audit Goal
[What we're assessing and why — from Phase 1]

### Static Analysis Output
[Output from Step 0, or "No static analysis tools available"]

### Convention Fingerprint
[Bullet list from Step 2]

### Dependency Map
[Dependency graph from Step 3]

### Utility Inventory
[Available helpers/types from Step 4]

### Files Under Audit
[File contents in the audit scope]

## Your Checklist
[Paste the full contents of the lens reference file here]
```

### Parallel Dispatch

Launch all active lenses in a **single message** with multiple Task tool calls:

```
Task 1: Lens — Code Health & Conventions
Task 2: Lens — Cross-Module Coherence
Task 3: Lens — Refactoring Opportunities
Task 4: Lens — Security & Performance
Task 5: Lens — Correctness & Logic  ← only if explicitly requested by user
```

Wait for all to complete before proceeding to Phase 3.

---

## Phase 3: Synthesis

**Run this inline after all lenses complete.**

### Step 1 — Collect & Deduplicate

Gather findings from all lenses. If two lenses flag the same location for the same underlying issue, merge them — keep the more detailed evidence and the higher severity suggestion.

### Step 2 — Group by Theme

Group findings into themes based on the underlying issue pattern. Examples:
- "Error handling inconsistencies across modules"
- "Duplication cluster in authentication logic"
- "Module boundary violations in data layer"
- "Missing test coverage for core business logic"

Each theme group should include:
- All related findings with their evidence
- A brief remediation path (what to fix and in what order)
- Estimated effort (low / medium / high)

### Step 3 — Assign Priority

Map each finding to the priority scale:

| Priority | Criteria |
|---|---|
| **P0** (Critical) | Security vulnerabilities, data loss risk, broken core functionality, crashes in production paths |
| **P1** (High) | Logic bugs, broken contracts, inconsistent interfaces, missing call site updates, regression risk |
| **P2** (Medium) | Convention violations, duplication clusters, missing tests, incomplete error handling, performance concerns |
| **P3** (Low) | Style suggestions, minor optimization, refactoring opportunities that aren't urgent |

**Severity gating rule:** Every finding must reference at least one concrete code location (file + line or function). No location, no finding. Additionally, P0 and P1 findings require either:
- Tool confirmation (static analysis, type checker, build error), or
- Concrete code evidence with a reproducible failure path or specific validation steps

If a finding cannot meet this evidence bar, downgrade it to P2 or move it to Questions.

### Step 4 — Assess Complexity & Validity

For each finding add:

**Complexity** (effort and risk to fix):
- **low** — Mechanical fix, single location, no risk of regression
- **medium** — Multiple files or requires design decision, moderate regression risk
- **high** — Architectural change, high regression risk, requires careful planning

**Validity** (how objective the finding is):
- **high** — Objectively wrong (bug, vulnerability, broken contract)
- **medium** — Convention violation backed by evidence, or clear anti-pattern
- **low** — Style/taste judgment, or uncertainty about whether it's actually a problem

### Step 5 — Format Output

Present findings grouped by theme, ordered by priority within each theme (P0 first → P3 last). Within the same priority, order by validity (high first).

```markdown
## Theme: [Theme title]

**Remediation path:** [Brief description of how to address this theme]
**Estimated effort:** low / medium / high

### P[0-3]: [Finding title]
**Priority:** P0/P1/P2/P3 | **Complexity:** low/medium/high | **Validity:** low/medium/high

**Location:** `file:line`
**Evidence:** [specific code observation]
**Impact:** [what goes wrong or what's at risk]
**Suggestion:** [concrete fix or investigation step]
**Validation:** [specific tests, checks, or CI steps to verify the fix]
```

### Questions Section

If any lens flagged uncertain items, list them as questions:

```markdown
## Questions

1. **[Question]** at `file:line` — [why this is unclear and what would resolve it]
```

### Structural Health Summary

End with an overall assessment:

```markdown
## Structural Health Summary

### Overall Assessment
[1-2 sentence diagnosis of the codebase's structural health]

### Top Systemic Issues
1. [Most impactful structural problem — what it is, why it matters, what to do]
2. [Second most impactful]
3. [Third most impactful]

### Findings Overview
| Priority | Count |
|----------|-------|
| P0       | N     |
| P1       | N     |
| P2       | N     |
| P3       | N     |

**Lenses applied:** [list which ran] | **Scope:** [single-module / multi-module / full-repo]

### Coverage
- **Audited:** [X/Y files]
- **Selection criteria:** [why these files were selected — for Medium/Large tiers]

### Excluded Areas
[What was not inspected and why — or "None, full coverage" for Small tier]

### Follow-Up Queue
[Ordered list of next-pass targets for incomplete audits — or "N/A" for full coverage]

### Recommended Next Steps
[Ordered list of what to tackle first, considering priority × effort × blast radius]
```

If no findings from any lens: state that the audit found no issues, note which lenses ran and the scope analyzed.

---

## Known AI Blind Spots

Actively watch for these during all phases:

| Blind Spot | What Happens | Mitigation |
|---|---|---|
| **Invisible coupling** | Modules appear independent but share implicit contracts via shared state, config, or conventions | Phase 1 dependency map + Lens 2 contract checks |
| **Duplication creep** | Same logic reimplemented across modules instead of using shared utilities | Phase 1 utility inventory + Lens 1 duplication checks |
| **Plausible code** | Code looks right and tests pass, but is semantically wrong or subtly inconsistent | Lens 2 contract drift checks + static analysis pre-pass. For deeper analysis, request the correctness lens explicitly. |
| **Convention drift** | Different parts of the codebase follow different conventions that evolved over time | Phase 1 convention fingerprint + Lens 1 adherence |
| **Partial migrations** | Old and new patterns coexist with no clear boundary or completion path | Lens 2 migration completeness checks |
| **Security regression** | A "redundant" check was a security guard; removing or bypassing it creates a vulnerability | Lens 4 explicit security checklist |
| **Architectural violation** | Imports cross layer boundaries the project doesn't allow | Lens 2 dependency direction checks |

---

## Refactoring Workflow

For refactoring tasks (executing changes after an audit identifies opportunities), read the detailed guide: [references/refactoring-guide.md](references/refactoring-guide.md)

Key concepts:
- **Refactor Ledger** — Externalized state tracking for multi-step refactors
- **Reuse-First Contract** — Search before creating new code
- **Incremental Verification** — Test after every atomic change
- **Differential Verification** — Capture outputs before refactoring, compare after
- **Semantic Preservation** — Verify behavior equivalence, not just test passage
