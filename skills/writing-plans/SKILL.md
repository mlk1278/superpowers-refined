---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans for a highly capable engineer who has **zero context for our codebase**. They write excellent code and tests; what they lack is everything they can't see from inside one task: our conventions, what already exists, which decisions were made and why, and where the traps are. Document every decision they would otherwise have to make: which files to touch for each task, the contracts to build against, each test's purpose, docs they might need to check, how to verify. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**The plan decides everything; the implementer writes the code.** A plan that writes the code instead is a PR-sized diff authored blind — code that has never been run, carrying the authority of an approved document, which implementers copy rather than question. Length is the tell: plans run hundreds of lines, not thousands.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `toolbelt:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/toolbelt/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Exploration Before Drafting

A plan is only as good as its author's grasp of the code it touches. Before mapping file structure or drafting a task, read the nearest instructions for the target files, then run 2–3 targeted inline `rg` searches for the named symbols, neighboring tests, and existing pattern.

Dispatch through toolbelt:agent-routing's `explorer` role only when the remaining question is a completeness inventory, an invisible trap, or a plan-shaping existence question. Start with one explorer when justified. Additional explorers require unfamiliar, independent subsystems whose answers do not depend on each other.

Each explorer brief requests checkable paths and pointers: exact paths and line ranges; one reference implementation worth copying; contracts the plan must match; prerequisites; and gotchas. Ask for evidence, not a convention summary.

End every explorer brief with the same question: **"What would a competent implementer, working only from a written plan and unable to see this code, get wrong here?"** That question is what turns an inventory into a warning.

### The Gotcha Hunt

Gotchas are the point of this pass. They prevent an implementer meeting a trap mid-task and inventing a way around it. Point explorers at these classes:

- **Assertions that can never pass.** An absence check must exclude its own evidence — applied migrations, lockfiles and vendored trees in scope, or a sweep that includes the doc naming the string being retired.
- **Checks that can't fail.** A guard or negative assertion that passes because setup never reached the branch it claims to cover. Timing counts too: a precondition read from output the gated command itself produces is a post-mortem, since the command has already run by the time the line is readable. A gate is a separate command that exits first.
- **Coverage that leaves with the code.** Tests for behaviour a deletion keeps share files, blocks, and fixtures with tests for behaviour it removes. Name which kept surfaces lose assertions, relocate that coverage and prove it green, then delete — in that order, since relocating afterwards leaves a window with no coverage and the suite is green either way.
- **Tooling traps.** Inverted exit codes (`git grep` 0 = matched = FAIL), tools absent on the CI runner.
- **Order and prerequisites.** Codegen, migrations, or fixtures that must run before the task's tests mean anything.
- **Shared contracts.** Who else consumes this signature, table, or event.
- **Environment drift.** Where local and CI disagree.

Findings go into the plan, not into your head — a gotcha you route around silently while drafting is one the implementer rediscovers.

### Resolve, Don't Defer

Every gotcha leaves this pass **resolved** — the plan decides, and shows the code, exclusion, or ordering that handles it — or **named**, stating the trap and the constraint and saying to escalate rather than improvise. A gotcha that is neither is a plan defect: "watch out for X" with no decision is the same failure as "add appropriate error handling."

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

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

Before writing tasks, partition the plan into independently verifiable pull requests. Each row names one outcome, the exact task numbers it contains, its dependencies, and verification that can pass without later boundaries.

| PR | Outcome | Tasks | Depends on | Independent verification |
|---|---|---|---|---|
| 1 | [one reviewable outcome] | [exact task numbers] | [boundary numbers or none] | [command or observable result] |

Every task number appears in exactly one boundary: no gaps and no overlap. A one-PR plan must state why no smaller independently verifiable outcome exists.

For shared substrate, put the core plus one representative consumer in the first boundary. Later consumers may share a PR only when they repeat the same reviewer judgment. Novel lifecycle, export, or rollout work stays separate.

## Execution Tracks

Optional. A plan may declare independent chains of tasks ("tracks") that execution runs concurrently, each in its own sub-worktree, merged back at a declared integration point. Omit the section and the plan runs fully serial. When present, it follows `## PR Boundaries` in the plan document:

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

- Track ids are kebab-case slugs — they become branch names and worktree directory names. Mainline segments are tracks named `serial-N` and run in the primary worktree; named tracks run in sub-worktrees.
- Every task number appears in exactly one track. Tasks within a track run in numeric order.
- `Depends on` names tracks, forming a DAG. Tracks with identical satisfied dependencies may run concurrently.

Declaration rules — what makes a split safe enough to declare; anything that needs an essay to justify its independence stays serial:

- **Disjoint file sets.** No file is created or modified by two concurrent tracks. Test files, fixtures, and generated-file sources count.
- **No contract-shaped work in tracks.** Migrations, shared schema, shared types, and shared API contracts belong in a mainline task before the fork — the **contract-freeze** pattern. A track consumes the frozen contract; it never changes it.
- **No cross-track interfaces.** No track's task may list another concurrent track's `Produces:` in its `Consumes:`. Anything consumed across tracks comes from a mainline task before the fork. Mechanically checkable from the `Interfaces:` blocks.
- **Threshold.** A track must beat roughly 2–5 minutes of per-worktree setup: at least 2 tasks, or one large task. Work below the threshold stays in the mainline.
- **Every fork closes with a mainline integration task.** It merges nothing itself (the orchestrator merges); it runs the integration scope — targeted cross-package checks and E2E covering the merged tracks' seams, within SDD's Verification Scope policy, never a workspace-wide run — and fixes what breaks under the standard fix loop. Its task text states that its brief will include each merged track's `Decisions & drift risks` entries.

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

**The altitude test:** a step is fully specified when two capable implementers, working independently from it, would produce behaviorally interchangeable code — differing in variable names and line order, not in behavior. "Add appropriate error handling" fails the test. "Rejects a duplicate key with 409 `DUPLICATE_KEY`" passes it, no code block needed.

The bounds are strict; the pen is theirs. The plan owns every behavior, name, and contract; within those, how the code is written is the implementer's call — do not prescribe it.

## Task Structure

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
  block is how they learn the names and types neighboring tasks use.]

**Gotchas:**
- [Traps in this task's code, each with the decision that handles it, or
  the constraint and an instruction to escalate. Omit the field if none.]

- [ ] **Step 1: Write the failing tests**

In `tests/exact/path/to/test.py`, one line per test — name — setup — assertion:
- `test_rejects_duplicate_key` — org already has a definition with key `size` — `create_definition` raises `DuplicateKeyError`
- `test_defaults_type_to_text` — input omits `type` — created row has `type == "TEXT"`

- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/path/test.py -v`
Expected: FAIL with "create_definition not defined"

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

A placeholder is an **undecided decision**, not unwritten code. Every step must pass the altitude test. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases" — name the exact behavior instead
- "Write tests for the above" — enumerate each test: name — setup — assertion
- "Similar to Task N" (restate this task's contract in full — the engineer may be reading tasks out of order)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Every behavior decided — exact names, types, and outcomes in every step
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. PR boundaries:** Reject boundaries that are missing, horizontal technical layers instead of outcomes, overlapping, or unjustified. Verify every task appears exactly once, dependencies form a workable order, each boundary can be independently verified, and any one-PR justification explains why no smaller outcome can stand alone. Missing, horizontal, overlapping, or unjustified boundaries are plan defects.

**5. Altitude:** Scan the code fences. Any fence outside the Data Model section longer than ~15 lines is implementation that belongs to the implementer — pull it back to a stub plus the decisions it can't carry. A plan that is mostly code fences has failed this check regardless of its quality.

**6. Execution tracks:** When the plan declares tracks, every declaration satisfies the rules — file sets disjoint, no contract work or cross-track interfaces inside tracks, thresholds met, an integration task at every merge point, every task in exactly one track.

Fix what you find inline. If you find a spec requirement with no task, add the task.

## Plan Review Gate

**Required.** After self-review, save the plan and have it reviewed through a different harness from the one that wrote it. A plan is the most expensive artifact to get wrong — every task inherits its mistakes, and the implementer executing Task 7 has no way to see that Task 3 made it impossible.

Invoke toolbelt:agent-routing and resolve the reviewer with role `reviewer`,
specialty `plan`, and the harness that wrote the plan as `author-harness`. Follow
that skill's resolver-path contract; the resolver is not relative to the project.

The `plan` specialty is where a project names its dedicated plan-review route; `--author-harness` removes same-harness routes case-insensitively and fails closed if none remain. If resolution fails, stop and tell your human partner — do not review the plan through the harness that wrote it, and do not pick a reviewer yourself.

Dispatch the resolved reviewer with the plan path and the spec path. It may fan out its own explorers — judging a plan against the real code beats reading it as a document. Ask it to judge:

- **Spec coverage** — every spec requirement traceable to a task; nothing invented that the spec doesn't ask for
- **Task decomposition** — each task independently testable, right-sized, in a workable order
- **Interface consistency** — types, signatures, and names agree across tasks
- **Placeholders** — any step that defers a decision instead of making it
- **Altitude** — implementation code where a contract belongs; full test files where a case list belongs; a Data Model section missing or repeated across tasks
- **Unflagged gotchas** — traps in the touched code the plan does not warn about
- **Global Constraints** — present, with exact values copied from the spec
- **PR boundaries** — reject missing, horizontal, overlapping, or unjustified boundaries; every task appears exactly once, dependencies are workable, and each PR has one outcome with independent verification
- **Execution tracks** — reject bogus or missing track declarations as plan defects: a plan whose tracks fail the declaration rules ships serial or gets restructured, never with optimistic tracks. A plan with no `## Execution Tracks` section is valid and serial; "missing" means a declared split lacking a required element (a merge point with no integration task, a task in no track)

Handle what comes back the way writing-specs does: small technical gaps — fix the plan and proceed. A rework large enough to change the approach — bring it to your human partner. Unsure — ask.

## Execution Handoff

After the plan review is clean, tell your human partner it's ready and hand off one declared PR boundary at a time:

> "Plan complete and saved to `docs/toolbelt/plans/<filename>.md`, reviewed through <reviewer harness>. I'll hand PR Boundary 1 to delivery; later boundaries follow only after their declared dependencies."

**REQUIRED SUB-SKILL:** Use toolbelt:subagent-driven-development. Fresh
subagent per task, task review (spec + quality) after each, broad
whole-branch review at the end.
