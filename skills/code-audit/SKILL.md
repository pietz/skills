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

**Cost note:** Token and runtime cost scales with scope and the number of active lenses. For large repositories, narrow the audit scope before running.

**Model note:** This skill performs deep analytical work. Use the most capable model available.

## Core Principles

1. **Context before judgment** — Map the codebase before auditing anything. The scout builds the map, the lenses investigate.
2. **Directed attention** — Each lens has a specific checklist. Generic scanning produces surface-level results.
3. **Convention-aware** — Audit against *this repo's* actual patterns, not generic best practices.
4. **Evidence-based** — Every finding must include file location, code evidence, and impact. No vague opinions.
5. **High signal** — 5 actionable findings beat 20 vague ones. Prefer precision over volume.
6. **Pull, don't push** — Sub-agents read files themselves from disk. Never paste entire file contents into prompts.

## Workflow Routing

| User Request | Workflow |
|---|---|
| "Audit this codebase / module / directory" | **Codebase Audit** — Three-phase lens analysis below |
| "Assess code quality / code health" | **Codebase Audit** — Same workflow |
| "Refactor this code" | **Refactoring** — Read [references/refactoring-guide.md](references/refactoring-guide.md) and follow that workflow |

**Before starting:** Inform the user that a multi-lens code audit is a thorough, multi-step process that will consume a significant number of tokens. Confirm the audit scope (which directory, module, or repo) and proceed only after the user acknowledges.

---

## Setup

1. Determine the audit target: full repo, specific directory, or module.
2. Note the user's specific audit focus, if any (e.g., "focus on security", "look at the API layer").
3. Note the target repository path (`{repo_path}`).
4. Note this skill's base directory (`{skill_dir}`) — provided when the skill is loaded.
5. Create the output directory: `{repo_path}/.audit/`

---

## Phase 1: Scout

Spawn a scout sub-agent to map the codebase. The scout reads files and produces a structured codemap — the orchestrator does not read source files itself.

**Dispatch via Task tool:**

```
Read your instructions at {skill_dir}/phases/phase-1-scout.md.

Target repository: {repo_path}
Audit focus: {user_focus or "general structural health assessment"}

Create the directory {repo_path}/.audit/ if it doesn't exist.
Write your output to:
- {repo_path}/.audit/codemap.md
- {repo_path}/.audit/static-analysis.md
```

Wait for the scout to complete before proceeding.

---

## Phase 2: Parallel Lens Analysis

### Lens Selection

**Always run:** Code Health, Cross-Module Coherence, Refactoring Opportunities, Security/Performance (Lenses 1-4).

**Correctness (Lens 5) is not included by default.** This skill focuses on structural health assessment — line-level correctness checking is the domain of tests, type checkers, and change-level review tools. Only include the correctness lens when the user explicitly requests it.

### The 5 Lenses

| # | Lens | Reference File | Role |
|---|------|---------------|------|
| 1 | Code Health & Conventions | [lens-code-health.md](references/lens-code-health.md) | **Primary** — structural quality |
| 2 | Cross-Module Coherence | [lens-cross-module.md](references/lens-cross-module.md) | **Primary** — the differentiator |
| 3 | Refactoring Opportunities | [lens-refactoring.md](references/lens-refactoring.md) | **Primary** — structural debt |
| 4 | Security & Performance | [lens-security-performance.md](references/lens-security-performance.md) | Standard |
| 5 | Correctness & Logic | [lens-correctness.md](references/lens-correctness.md) | Opt-in (user request only) |

### Dispatch

Launch all active lenses **simultaneously in a single message** using the Task tool. Each lens receives a minimal prompt — the lens reads its own instructions and the codemap from disk.

**Per-lens prompt:**

```
You are performing a focused code audit.

Read your lens instructions at {skill_dir}/references/lens-{name}.md.
Read the codemap at {repo_path}/.audit/codemap.md.
Read static analysis output at {repo_path}/.audit/static-analysis.md (if it exists).

Target repository: {repo_path}
Audit focus: {user_focus or "general structural health assessment"}

Write your findings to {repo_path}/.audit/lens-{name}.md.

If you find no issues, write that explicitly to the output file.
```

Wait for all lenses to complete before proceeding to Phase 3.

---

## Phase 3: Synthesis & Verification

### Step 1 — Collect & Verify

1. Read all `.audit/lens-*.md` files.
2. **Verification pass for P0/P1 findings:** For any finding rated P0 or P1 by a lens agent, read the cited code location(s) yourself to verify the evidence is real and the severity is warranted. This catches hallucinated evidence and overblown severity. Downgrade or remove findings that don't hold up.
3. **Cross-lens conflict resolution:** If two lenses contradict each other on the same code (e.g., one says "extract this" and another says "this duplication is intentional"), read the code and make the call.

### Step 2 — Deduplicate & Group

Merge findings from all lenses. If two lenses flag the same location for the same underlying issue, merge — keep the more detailed evidence and the higher severity.

Group findings into themes based on the underlying issue pattern. Examples:
- "Error handling inconsistencies across modules"
- "Duplication cluster in authentication logic"
- "Module boundary violations in data layer"

Each theme group should include:
- All related findings with their evidence
- A brief remediation path (what to fix and in what order)
- Estimated effort (low / medium / high)

### Step 3 — Prioritize & Assess

Map each finding to the priority scale:

| Priority | Criteria |
|---|---|
| **P0** (Critical) | Security vulnerabilities, data loss risk, broken core functionality, crashes in production paths |
| **P1** (High) | Logic bugs, broken contracts, inconsistent interfaces, missing call site updates, regression risk |
| **P2** (Medium) | Convention violations, duplication clusters, missing tests, incomplete error handling, performance concerns |
| **P3** (Low) | Style suggestions, minor optimization, refactoring opportunities that aren't urgent |

**Severity gating:** P0 and P1 findings require either tool confirmation (static analysis, type checker, build error) or concrete code evidence with a specific failure path. If a finding can't meet this bar, downgrade to P2 or move to Questions.

For each finding, also assess:

- **Complexity** (effort and risk to fix): low / medium / high
- **Validity** (how objective): high / medium / low

### Step 4 — Write Report

Write the final report to `{repo_path}/.audit/report.md` using this format:

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

Order: themes by highest-priority finding first. Within each theme, P0 → P3. Within same priority, high validity first.

Include a **Questions** section for uncertain items:

```markdown
## Questions

1. **[Question]** at `file:line` — [why this is unclear and what would resolve it]
```

End with the **Structural Health Summary:**

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

**Lenses applied:** [list which ran] | **Scope:** [what was audited]

### Coverage
[Sourced from the codemap's coverage notes — what was examined, what wasn't]

### Recommended Next Steps
[Ordered list of what to tackle first, considering priority x effort x blast radius]
```

### Step 5 — Present to User

After writing the report, present a concise summary to the user:
- Overall assessment (1-2 sentences)
- Top 3 systemic issues
- Findings count by priority
- Note: "Full report written to `.audit/report.md`"

---

## Known AI Blind Spots

Watch for these during synthesis and verification:

| Blind Spot | What Happens | Mitigation |
|---|---|---|
| **Invisible coupling** | Modules appear independent but share implicit contracts via shared state, config, or conventions | Scout dependency map + cross-module lens |
| **Duplication creep** | Same logic reimplemented across modules instead of using shared utilities | Scout utility inventory + code health lens |
| **Plausible code** | Code looks right but is semantically wrong or subtly inconsistent | Cross-module contract checks + static analysis. For deeper analysis, request the correctness lens. |
| **Convention drift** | Different parts of the codebase follow different conventions that evolved over time | Scout convention fingerprint + code health lens |
| **Partial migrations** | Old and new patterns coexist with no clear boundary or completion path | Cross-module migration completeness checks |
| **Security regression** | A "redundant" check was a security guard; removing it creates a vulnerability | Security lens explicit checklist |
| **Architectural violation** | Imports cross layer boundaries the project doesn't allow | Cross-module dependency direction checks |

---

## Refactoring Workflow

For refactoring tasks (executing changes after an audit identifies opportunities), read the detailed guide: [references/refactoring-guide.md](references/refactoring-guide.md)

Key concepts:
- **Refactor Ledger** — Externalized state tracking for multi-step refactors
- **Reuse-First Contract** — Search before creating new code
- **Incremental Verification** — Test after every atomic change
- **Differential Verification** — Capture outputs before refactoring, compare after
- **Semantic Preservation** — Verify behavior equivalence, not just test passage
