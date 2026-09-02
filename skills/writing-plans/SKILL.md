---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write the plan for a capable engineer with **zero context for our codebase**. Decide what they cannot see: the files each task touches, the contracts, each test's purpose, the verification. DRY. YAGNI. TDD. Frequent commits.

**The plan decides everything; the implementer writes the code.**

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** An isolated worktree should already exist, created via the `toolbelt:using-git-worktrees` skill.

**Save plans to:** `docs/toolbelt/plans/YYYY-MM-DD-<feature-name>.md`
- Use your human partner's location when they name one.

## Scope Check

If the spec covers independent subsystems, propose one plan each. Every plan produces working, testable software on its own.

## Exploration Before Drafting

Read the nearest instructions for the target files. Run 2–3 targeted inline `rg` searches for the named symbols, neighboring tests, and existing pattern.

Dispatch through toolbelt:agent-routing's `explorer` role only for a completeness inventory, an invisible trap, or a plan-shaping existence question. Start with one explorer. More explorers require unfamiliar, independent subsystems whose answers do not depend on each other.

Ask for checkable paths and pointers: paths with line ranges, one reference implementation to copy, contracts to match, prerequisites, gotchas. End every brief with: **"What would a competent implementer, working only from a written plan and unable to see this code, get wrong here?"**

### The Gotcha Hunt

- **Assertions that can never pass.** An absence check must exclude its own evidence.
- **Checks that can't fail.** A guard whose setup never reaches its branch, or a precondition read from output the gated command itself produces. A gate is a separate command that exits first.
- **Coverage that leaves with the code.** Name the kept surfaces losing assertions, relocate that coverage green, then delete.
- **Tooling traps.** Inverted exit codes (`git grep` 0 = matched = FAIL), tools missing on CI.
- **Order and prerequisites.** Codegen, migrations, or fixtures the tests need first.
- **Shared contracts.** Who else consumes this signature, table, or event.
- **Environment drift.** Where local and CI disagree.

Every gotcha leaves this pass **resolved** — the plan shows the code, exclusion, or ordering handling it — or **named**, with an instruction to escalate. A gotcha that is neither is a plan defect.

## File Structure

Map the files the work creates or modifies and what each is responsible for.

- One responsibility and a defined interface per file; prefer small files.
- Files that change together live together. Split by responsibility, not by layer.
- Follow the codebase's patterns. Split a file you already modify, not the rest.

## Task Right-Sizing

A task is the smallest unit worth its own test cycle and a fresh reviewer's gate. Fold setup, configuration, scaffolding, and documentation into the task whose deliverable needs them. Split only where a reviewer could reject one task and approve its neighbor. Every task ends with an independently testable deliverable.

- A task's **Files:** block is closed. It lists every file the task creates or modifies. "Plus every caller", "compiler-led", and "wherever else it is referenced" are placeholders and fail No Placeholders.
- A task lists at most 8 files, as a hard limit. As a guide its change reads in one sitting, around 400 lines; the plan reviewer flags tasks that look larger.
- The one exception is a mechanical sweep: one uniform, behavior-neutral transformation (a rename, an import path change) with one verification command. The task says "Mechanical sweep:" and names that command.
- A task that adds or changes a migration, shared schema, shared type, or shared contract owns the code that keeps that change correct. Fencing that code into a later task is a defect. If the result exceeds 8 files, split it into serial tasks that each leave the contract correct.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use toolbelt:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## Known Gotchas

[Cross-cutting traps exploration surfaced, one line each, with the decision
that handles each. Task-specific traps belong on their task instead. Every
task implicitly includes this section.]

## Data Model

[When the work adds or changes schema, migrations, shared types, or
contracts: the complete code, here, once. Tasks reference it instead of
repeating it. Omit the section when there is none.]

---
```

## PR Boundaries

Partition the plan into independently verifiable pull requests before writing tasks.

| PR | Outcome | Tasks | Depends on | Independent verification |
|---|---|---|---|---|
| 1 | [one reviewable outcome] | [exact task numbers] | [boundary numbers or none] | [command or observable result] |

Every task number appears in exactly one boundary. Verification passes without later boundaries. A one-PR plan states why no smaller independently verifiable outcome exists.

For shared substrate, put the core plus one representative consumer in the first boundary. Later consumers may share a PR only when they repeat the same reviewer judgment. Novel lifecycle, export, or rollout work stays separate.

## Execution Tracks

Tracks are chains of tasks run concurrently, each in its own sub-worktree, merged at a declared integration point.

**Required** for every plan with more than one PR boundary or more than three tasks. A plan whose tracks are all `serial-N` states in one sentence why no tasks can run concurrently. The section follows `## PR Boundaries`:

```markdown
## Execution Tracks

| Track | Tasks | Depends on | Files touched (summary) | Why safe |
|---|---|---|---|---|
| serial-1 | 1–2 | — | shared types, API contract | mainline (contract freeze) |
| backend | 3–6 | serial-1 | src/server/** | disjoint from frontend, e2e-specs |
| frontend | 7–9 | serial-1 | src/app/settings/** | disjoint from backend, e2e-specs |
| e2e-specs | 10 | serial-1 | e2e/** | disjoint from backend, frontend |
| serial-2 | 11 | backend, frontend, e2e-specs | (integration) | merge point |
```

Structure rules:

- Track ids are kebab-case slugs, used as branch and worktree directory names. `serial-N` tracks run in the primary worktree, named tracks in sub-worktrees.
- Every task number appears in exactly one track, in numeric order within it.
- `Depends on` names tracks, forming a DAG. Tracks with identical satisfied dependencies run concurrently.

Declaration rules:

- **Disjoint file sets.** No file is created or modified by two concurrent tracks. Test files, fixtures, and generated-file sources count.
- **No contract-shaped work in tracks.** Migrations, shared schema, shared types, and shared API contracts belong in a mainline task before the fork — the **contract-freeze** pattern. A track consumes the frozen contract; it never changes it.
- **No cross-track interfaces.** No track's task may list another concurrent track's `Produces:` in its `Consumes:`. Anything consumed across tracks comes from a mainline task before the fork.
- **Threshold.** A track must beat roughly 2–5 minutes of per-worktree setup: at least 2 tasks, or one large task. Less stays in the mainline.
- **Every fork closes with a mainline integration task.** The orchestrator merges; the task does not. It runs the integration scope — targeted cross-package checks and E2E over the merged tracks' seams, within SDD's Verification Scope policy, never workspace-wide — and fixes what breaks. Its text states that its brief carries each merged track's `Decisions & drift risks` entries.

## Plan Altitude: Contracts, Not Implementations

Specify each artifact at the altitude where the decision lives:

| Artifact | The plan writes |
|---|---|
| Data model — schema, migrations, shared types | Complete code, once, in the `## Data Model` section at the top. Every task derives from it |
| Constants, config values, fixtures | Complete — exact values |
| Functions and services | Signature stubs: exact name, parameters, return type, error behavior. Add the load-bearing lines (a lock order, a tricky query, a non-obvious algorithm) only when those lines are themselves the decision |
| Endpoints | Method, path, request/response shape, status codes, capability — exact |
| Tests | One line per test: name — setup — assertion. Full test code only when the harness itself is a trap with no in-repo precedent |
| UI components | Name, props contract, states, which existing primitives to compose |
| Anything with in-repo precedent | The decision plus the reference to copy: `path:line` |

**The altitude test:** a step is fully specified when two capable implementers working independently from it produce behaviorally interchangeable code.

How the code is written is the implementer's call.

## Task Structure

A guard or negative assertion (a permission check, a tenant filter, a rejection path) lists its red as the failure seen when the guard is absent, not when the module is absent.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.
  Write `Produces: none` when nothing downstream depends on this task.]

**Gotchas:**
- [Traps in this task's code, each with the decision that handles it, or
  the constraint and an instruction to escalate. Omit the field if none.]

- [ ] **Step 1: Write the failing tests**

In `tests/exact/path/to/test.py`, one line per test — name — setup — assertion:
- `test_rejects_duplicate_key` — org already has a definition with key `size` — `create_definition` raises `DuplicateKeyError`
- `test_defaults_type_to_text` — input omits `type` — created row has `type == "TEXT"`

- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/path/test.py -v`
Expected, per test:
- `test_rejects_duplicate_key` — FAIL: `create_definition` not defined
- `test_defaults_type_to_text` — FAIL: `create_definition` not defined

- [ ] **Step 3: Implement to the contract**

```python
def create_definition(org_id: str, input: CreateDefinitionInput) -> Definition:
    """Raises DuplicateKeyError (-> 409 DUPLICATE_KEY) when org already has input.key."""
```

Decisions the stub can't carry, one line each: [take the definition locks
before the entity row; copy the tenancy filter from `definitions/service.py:88`]

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/path/test.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

A placeholder is an **undecided decision**, not unwritten code. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases" — name the exact behavior instead
- "Write tests for the above" — enumerate each test: name — setup — assertion
- "Similar to Task N" — restate this task's contract in full
- References to types, functions, or methods not defined in any task

## Self-Review

Check the plan against the spec yourself, not with a subagent. Fix findings inline; add a task for any spec requirement with none.

**1-5.** Run the Plan Review Gate's judgments below against your own plan: spec coverage, placeholders, type consistency across tasks, PR boundaries, and altitude.

**6. Execution tracks:** check the declaration rules and accept a plan whose tracks pass them. A plan with no concurrent tracks and no one-sentence justification is a defect. A plan with no `## Execution Tracks` section, one PR boundary, and three or fewer tasks is valid.

## Plan Review Gate

**Required.** After self-review, save the plan and have a different harness review it.

Invoke toolbelt:agent-routing and resolve the reviewer with role `reviewer`,
specialty `plan`, and the harness that wrote the plan as `author-harness`. Follow
that skill's resolver-path contract; the resolver is not relative to the project.

`--author-harness` drops same-harness routes case-insensitively and fails closed if none remain. If resolution fails, stop and tell your human partner. Never review the plan through the harness that wrote it, and never pick a reviewer yourself.

Dispatch the reviewer with the plan and spec paths. It may fan out its own explorers. Ask it to judge:

- **Spec coverage** — every requirement traceable to a task, nothing extra
- **Task decomposition** — independently testable, within the 8-file limit, workable order
- **Interface consistency** — types, signatures, and names agree across tasks
- **Placeholders** — any step that defers a decision
- **Altitude** — implementation code where a contract belongs; a Data Model section missing or repeated
- **Unflagged gotchas** — traps in the touched code the plan does not warn about
- **Global Constraints** — present, with exact values from the spec
- **PR boundaries** — missing, horizontal, overlapping, or unjustified boundaries are plan defects; every task appears once, each PR independently verifiable
- **Execution tracks** — the declaration rules, accepting a plan whose tracks pass them; a plan with no concurrent tracks and no one-sentence justification is a defect

Handle what comes back the way writing-specs does: small technical gaps — fix and proceed. A rework large enough to change the approach — bring it to your human partner. Unsure — ask.

## Execution Handoff

After the plan review is clean, hand your human partner the whole plan. Delivery owns boundary order.

> "Plan complete and saved to `docs/toolbelt/plans/<filename>.md`, reviewed through <reviewer harness>. Handing the plan to delivery."

**REQUIRED SUB-SKILL:** Use toolbelt:subagent-driven-development. Fresh
subagent per task, task review (spec + quality) after each, broad
whole-branch review at the end.
