---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `toolbelt:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/toolbelt/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Exploration Before Drafting

A plan is only as good as its author's grasp of the code it touches. Before mapping file structure or drafting a single task, fan out explorers — one per surface the plan will touch, all dispatched in the same message so they run concurrently (toolbelt:dispatching-parallel-agents). Route them through toolbelt:agent-routing's `explorer` role; they are read-only.

Breadth scales with the plan: a single-surface change gets one explorer, a change crossing API, schema, and UI gets one each. Slice by surface, not by task — tasks don't exist yet, and their boundaries are one of the things this pass decides.

Each explorer returns, for its surface: exact paths and line ranges; the pattern already in use, with one reference implementation worth copying; the contracts the plan must match; what must exist or run first; and gotchas.

End every explorer brief with the same question: **"What would a competent implementer, working only from a written plan and unable to see this code, get wrong here?"** That question is what turns an inventory into a warning.

### The Gotcha Hunt

Gotchas are the point of this pass. They prevent an implementer meeting a trap mid-task and inventing a way around it. Point explorers at these classes:

- **Assertions that can never pass.** An absence check must exclude its own evidence — applied migrations, lockfiles and vendored trees in scope, or a sweep that includes the doc naming the string being retired.
- **Checks that can't fail.** A guard or negative assertion that passes because setup never reached the branch it claims to cover.
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

---
```

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

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task
- A named gotcha carrying neither a decision nor an instruction to escalate

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

Fix what you find inline. If you find a spec requirement with no task, add the task.

## Plan Review Gate

**Required.** After self-review, save the plan and have it reviewed by a model independent of the one that wrote it. A plan is the most expensive artifact to get wrong — every task inherits its mistakes, and the implementer executing Task 7 has no way to see that Task 3 made it impossible.

The resolver enforces independence on model *identity*, not family, so a same-family pairing can satisfy it. Cross-family review (Claude reviews GPT, GPT reviews Claude) is worth having: configure the project's `plan` specialty to a different family than its `planner` route.

Resolve the reviewer through toolbelt:agent-routing, which reads the project's `.toolbelt/agents.json`:

```bash
scripts/resolve-agent --project-root <root> --role reviewer \
  --reviewer-specialty plan --author-model <model that wrote the plan>
```

The `plan` specialty is where a project names its dedicated plan-review route; `--author-model` is what enforces family independence. If resolution fails, stop and tell your human partner — do not review the plan with the model that wrote it, and do not pick a reviewer yourself.

Dispatch the resolved reviewer with the plan path and the spec path. It may fan out its own explorers — judging a plan against the real code beats reading it as a document. Ask it to judge:

- **Spec coverage** — every spec requirement traceable to a task; nothing invented that the spec doesn't ask for
- **Task decomposition** — each task independently testable, right-sized, in a workable order
- **Interface consistency** — types, signatures, and names agree across tasks
- **Placeholders** — any step that defers a decision instead of making it
- **Unflagged gotchas** — traps in the touched code the plan does not warn about
- **Global Constraints** — present, with exact values copied from the spec

Handle what comes back the way writing-specs does: small technical gaps — fix the plan and proceed. A rework large enough to change the approach — bring it to your human partner. Unsure — ask.

## Execution Handoff

After the plan review is clean, tell your human partner it's ready and hand off:

> "Plan complete and saved to `docs/toolbelt/plans/<filename>.md`, reviewed by <reviewer model>. I'll execute it with subagent-driven development — a fresh subagent per task, reviewed between tasks."

**REQUIRED SUB-SKILL:** Use toolbelt:subagent-driven-development. Fresh
subagent per task, task review (spec + quality) after each, broad
whole-branch review at the end.
