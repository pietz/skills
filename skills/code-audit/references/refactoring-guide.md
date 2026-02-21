# Refactoring Guide

Structured refactoring workflow for AI coding agents. Addresses the key failure modes: incomplete multi-file refactors, lost state across edits, duplication increase, and plausible-but-wrong patches.

## Before You Start

### 1. Understand Scope and Intent

Ask or determine:
- What is the goal of this refactoring? (consolidation, extraction, migration, simplification)
- Which files and symbols are involved?
- What behavior must be preserved?
- Are there tests covering the affected code?

### 2. Assess Test Coverage

Before refactoring, verify:
- Do tests exist for the code being changed?
- Do they cover the key behaviors (not just happy paths)?
- If coverage is insufficient, **write tests first** before refactoring. This creates the safety net.

### 3. Extract Conventions

Scan the repo for:
- Naming patterns and code style
- Common abstractions and utilities that should be reused
- Architectural boundaries (which modules import which)
- Error handling and logging patterns

## The Refactor Ledger

For any refactoring that touches more than 2 files, create and maintain a refactor ledger. This is a structured plan that tracks progress and prevents partial refactors.

### Ledger Format

```markdown
## Refactor Ledger

**Goal:** [One sentence describing the refactoring objective]
**Preserved behavior:** [What must not change]

### Targets
| # | Symbol/File | Action | Status |
|---|------------|--------|--------|
| 1 | `UserService.fetchData()` | Rename to `getUser()` | pending |
| 2 | `controllers/auth.ts:login` | Update call site | pending |
| 3 | `jobs/report.ts:generate` | Update call site | pending |
| 4 | `tests/user.test.ts` | Update test references | pending |

### Invariants
- [ ] All existing tests pass
- [ ] No new type errors
- [ ] API response shape unchanged
```

### Ledger Rules

1. **Build the ledger before making any changes.** Use search/grep to find ALL references to the symbols being changed. Don't rely on memory.
2. **Update the ledger after each atomic change.** Mark steps as `done` when completed and verified.
3. **Never skip a step.** If a step seems unnecessary, verify why and note the reason — don't just skip it.
4. **If interrupted, the ledger is the resume point.** Another agent (or your next turn) can pick up from the first `pending` item.

## Execution Pattern

### Step 1: Search Exhaustively

Before changing anything, find all references:

```
For each symbol being refactored:
  1. Search for exact name (grep/search)
  2. Search for string references (e.g., in configs, templates, logs)
  3. Search for dynamic references (e.g., dict['method_name'])
  4. Check re-exports and barrel files
  5. Check generated code and type definitions
```

Record every reference in the ledger.

### Step 2: Apply Changes Incrementally

Follow this loop for each ledger item:

```
1. Make ONE atomic change (single file or tightly coupled pair)
2. Run type checker / linter
3. Run relevant tests (not full suite — the tests that cover this file)
4. If green → mark ledger item as done → next item
5. If red → fix immediately before moving on
6. NEVER batch multiple unrelated changes between verification steps
```

### Step 2.5: Differential Verification

For refactorings that touch critical logic or have weak test coverage, test passage alone is insufficient — research shows 19-35% of LLM-generated refactorings produce functionally non-equivalent code, and ~21% of those non-equivalences are missed by existing test suites.

Before refactoring critical functions:
1. Identify representative inputs (happy path, edge cases, error cases)
2. Capture the function's outputs on those inputs (return values, side effects, error behavior)
3. After refactoring, verify the outputs match exactly
4. If outputs differ, investigate whether the difference is intentional or a regression

This is especially important for:
- Functions with complex branching or state management
- Code where test coverage is thin or only covers happy paths
- Compound refactorings that change multiple interacting functions

When feasible, prefer property-based or differential testing over manual input selection.

### Step 3: Full Verification

After all ledger items are done:

```
1. Run the full test suite
2. Search again for any remaining references to old symbols
3. Verify no new duplication was introduced
4. Check that the ledger has no remaining "pending" items
```

## The Reuse-First Contract

Before writing new code (new functions, new classes, new utilities), follow this protocol:

1. **Search** for existing code that does something similar.
2. **Evaluate** whether existing code can be reused, extended, or generalized.
3. **Justify** if creating new code: "I searched for X, found Y, but it doesn't work because Z."

Concrete checks:
- Is there an existing utility function for this?
- Is there an existing type/interface that covers this?
- Is there a pattern elsewhere in the repo that handles this case?
- Am I about to duplicate logic that already exists in another module?

If the answer to any of these is "yes", prefer reusing over creating.

## Refactoring Types and Guidance

### Rename / Move

Lowest risk, highest success rate for AI agents.

- Use the ledger to track all references
- Don't forget: string references in configs, logs, error messages, comments, documentation
- Verify: search for the OLD name after refactoring — it should appear nowhere

### Extract Function / Method

Moderate risk. Common failure: extracting but not consolidating duplicate call sites.

- Identify ALL places the extracted logic appears (there may be duplicates)
- Extract once, then replace all occurrences
- Ensure the extracted function has a clear single responsibility
- Add tests for the extracted function independently

### Consolidate Duplicates

The most impactful refactoring for AI-generated codebases.

- Use clone detection (or manual search) to find similar code blocks
- Identify the "canonical" version (usually the most tested or most general)
- Create or extend a shared abstraction
- Replace all duplicates with calls to the shared version
- Verify each replacement individually

### Change Interface / API

Highest risk. Requires the most thorough ledger.

- Map ALL consumers before changing the interface
- Consider backward compatibility: can you support both old and new temporarily?
- Update in dependency order: interface first, then implementations, then consumers
- Pay special attention to external consumers (other services, public APIs)

### Architectural Refactoring

AI agents struggle most here. Be extra cautious.

- Map the current architecture explicitly before proposing changes
- Make changes in small, verifiable steps — not a big bang
- Prefer creating the new structure alongside the old, then migrating piece by piece
- At no point should the system be in a broken intermediate state

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | What to Do Instead |
|---|---|---|
| **Big bang refactor** | Changing 20 files at once without intermediate verification | Change 1-2 files at a time, verify each step |
| **Refactor while adding features** | Mixing behavior changes with structural changes makes both harder to verify | Separate refactoring commits from feature commits |
| **Removing "dead" code you don't fully understand** | It might be a security check, fallback, or used dynamically | Investigate why it exists before removing |
| **Optimizing during refactoring** | Different goals: refactoring preserves behavior, optimization changes it | Do them in separate passes |
| **Skipping tests because "it's just a rename"** | Renames can break string references, dynamic lookups, serialization | Always verify, even for "trivial" changes |
