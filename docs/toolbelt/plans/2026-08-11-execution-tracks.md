# Execution Tracks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use toolbelt:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach the toolbelt skills plan-declared, track-level parallelism: plans may declare independent task chains ("tracks") that SDD executes concurrently in sub-worktrees, merged back at declared integration points.

**Architecture:** Skill text only — four SKILL.md edits plus one new content-assertion test file. writing-plans gains the declaration grammar and its review gates; subagent-driven-development gains the execution machinery (waves, drift log, ledger, failure semantics) and amended Red Flags; using-git-worktrees documents parallel-workspace policy rules; dispatching-parallel-agents gets a one-line boundary. No hooks, manifests, or scripts change.

**Tech Stack:** Markdown skill documents; bash `assert_contains`-style tests in `tests/toolbelt/`.

**Spec:** `docs/toolbelt/specs/2026-08-05-execution-tracks-design.md` — each task names the spec component that is its requirements source. Read that component before implementing the task.

## Global Constraints

Copied from the spec's Constraints section and this repo's CLAUDE.md; every task implicitly includes them.

- **One orchestrator.** The session agent orchestrates every track directly. No nested orchestrators, no lane-level sub-orchestrators.
- **Plan-declared only.** Execution never invents parallelism. No `## Execution Tracks` section in the plan means fully serial execution, exactly as today.
- **Concurrency cap: 3 tracks.** A project's worktree policy may lower this, never raise it.
- **Nothing project-specific in skills.** DB naming, setup commands, and resource rules live in the consuming project's `.toolbelt/worktree-policy.md`. Skills never invent a resource scheme when the policy is silent.
- **Sub-worktrees are plain local git** (`git worktree add`) — no new sandboxes, no cross-sandbox communication, no native worktree tools for track worktrees.
- **Skill-editing house rules (CLAUDE.md):** additions are gates and rules in skill register — condense the spec, never copy its rationale prose (Goal/Constraints sections) into skills. Write "your human partner", never "the user". Red Flags phrasing is fixed verbatim in the Data Model below — do not smooth it.
- **Serial by default is untouched:** every edit must leave existing serial behavior byte-compatible — the new SDD section is active only when the plan contains `## Execution Tracks`; the new writing-plans section is optional.

## Known Gotchas

- **`grep -Fq` single-line assertions.** Every Asserted Phrase in the Data Model must appear verbatim and unbroken on one line of its skill file. When wrapping prose, wrap before or after the phrase, never inside it — even if the line runs past 80 columns.
- **Test-file conventions.** Copy the header pattern from `tests/toolbelt/test-writing-plans.sh:1-17`: `#!/usr/bin/env bash`, `# shellcheck disable=SC2016`, `set -euo pipefail`, and single-quoted assertion strings (they contain backticks). `scripts/lint-shell.sh` with no arguments picks up changed and untracked shell files automatically.
- **`## Execution Tracks` appears twice in writing-plans** — once as the skill's section heading, once inside the fenced example table block. Presence assertions (`grep -Fq`) are fine with that. Do not write ordering checks in the style of `grep -n '^## Execution Tracks' | cut -d: -f1` — the multi-match makes the numeric compare a syntax error. None are planned; do not add any.
- **Existing tests are a live gate on the files being edited.** `tests/toolbelt/test-writing-plans.sh` asserts section ordering and phrases in writing-plans; `tests/toolbelt/test-worktree-baseline.sh` asserts phrases in the exact Project Worktree Policy section being extended. Run them as regressions in Tasks 1 and 3 respectively.
- **No native tools for track worktrees.** The Parallel Tracks text states the `git worktree add` command itself (Data Model) precisely so an orchestrator never routes track-worktree creation through using-git-worktrees Step 1a (`EnterWorktree` etc.) — the spec forbids new sandboxes. Do not word the section as "create a worktree per the using-git-worktrees skill".
- **This plan declares no Execution Tracks.** Tasks 1–3 all touch `tests/toolbelt/test-execution-tracks.sh`, so their file sets are not disjoint; the plan runs serially, and Task 2's textual references to Task 1's section names are satisfied by numeric order.

## Data Model

The cross-skill contract: names, formats, and exact strings shared between the skills and the tests. Tasks reference this section instead of restating it.

**Declaration grammar** (writing-plans defines, SDD consumes):

- Plan section name: `## Execution Tracks`, optional, placed after `## PR Boundaries` in the plan document.
- Track ids are kebab-case slugs (they become branch names and worktree directory names). Mainline segments are tracks named `serial-N` and execute in the primary worktree; named tracks execute in sub-worktrees.
- Example table, reproduced verbatim in the writing-plans section as a fenced markdown block:

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

**Execution formats** (SDD):

- Track worktree creation, stated as a literal command in the Parallel Tracks section:
  `git worktree add <sdd-workspace>/tracks/<track-id> -b <feature-branch>--<track-id>`
  branched from the current feature-branch head.
- Ledger track lines, alongside task lines:
  `Track B: in-progress (task 8/9, worktree <path>, base <sha7>)` →
  `Track B: merged (<sha7>, worktree removed)`
- Track merge-back: `git merge --no-ff` of the track branch into the feature branch, then remove the sub-worktree and branch.
- Drift-log report section name: `## Decisions & drift risks` (required in track implementer reports; `None` is a valid entry).

**Red Flags replacement** (SDD, verbatim — the existing `## Red Flags` bullet reading `- Dispatch multiple implementation subagents in parallel (conflicts)` becomes):

```markdown
- Dispatch multiple implementation subagents into the same worktree —
  concurrent implementers are only ever one-per-track-worktree, declared by
  the plan's Execution Tracks section
- Parallelize tracks the plan did not declare — opportunistic parallelism at
  execution time is forbidden, however independent two tasks look
```

**Asserted Phrases** — each must appear verbatim, on one line, in the named file. These are the test contract; Tasks 1–3 assert exactly these.

| Phrase | File |
|---|---|
| `## Execution Tracks` | skills/writing-plans/SKILL.md |
| `No file is created or modified by two concurrent tracks` | skills/writing-plans/SKILL.md |
| `contract-freeze` | skills/writing-plans/SKILL.md |
| `Every fork closes with a mainline integration task` | skills/writing-plans/SKILL.md |
| `bogus or missing track declarations` | skills/writing-plans/SKILL.md |
| `## Parallel Tracks` | skills/subagent-driven-development/SKILL.md |
| `At most 3 tracks run concurrently` | skills/subagent-driven-development/SKILL.md |
| `## Decisions & drift risks` | skills/subagent-driven-development/SKILL.md |
| `A textual conflict is a plan defect` | skills/subagent-driven-development/SKILL.md |
| `Dispatch multiple implementation subagents into the same worktree` | skills/subagent-driven-development/SKILL.md |
| `Parallelize tracks the plan did not declare` | skills/subagent-driven-development/SKILL.md |
| `parallel-workspace rules` | skills/using-git-worktrees/SKILL.md |
| `concurrency limit lower than 3` | skills/using-git-worktrees/SKILL.md |

And one absence: `Dispatch multiple implementation subagents in parallel (conflicts)` must no longer appear in skills/subagent-driven-development/SKILL.md.

---

## PR Boundaries

| PR | Outcome | Tasks | Depends on | Independent verification |
|---|---|---|---|---|
| 1 | Skills declare, execute, and provision plan-declared execution tracks | 1–3 | none | `bash tests/toolbelt/test-execution-tracks.sh && bash tests/toolbelt/test-writing-plans.sh && bash tests/toolbelt/test-worktree-baseline.sh && scripts/lint-shell.sh tests/toolbelt/test-execution-tracks.sh` all succeed |

One PR because no smaller independently verifiable outcome exists: the three components are one contract — a declaration grammar with no executor is dead text a live session would declare and silently ignore, and the executor is unreviewable without the grammar it consumes. The whole change is four small text edits plus one test file; splitting it adds review rounds without adding an independently shippable outcome.

## Task 1: writing-plans declares tracks

**Spec source:** Component 1.

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (insert section between `## PR Boundaries` and `## Plan Altitude: Contracts, Not Implementations`; add item 6 to `## Self-Review`; add a bullet to the `## Plan Review Gate` "Ask it to judge" list)
- Create: `tests/toolbelt/test-execution-tracks.sh`

**Interfaces:**
- Consumes: Data Model — declaration grammar, example table, Asserted Phrases rows 1–5.
- Produces: the plan-section grammar Task 2's executor text references by name: section `## Execution Tracks`, table columns `Track | Tasks | Depends on | Files touched (summary) | Why safe`, kebab-case track ids, `serial-N` mainline naming, the integration-task rule.

**Gotchas:**
- The insertion point is between `## PR Boundaries` and `## Plan Altitude: Contracts, Not Implementations`. `test-writing-plans.sh` checks that `^## PR Boundaries` precedes `^## Task Structure` — an insertion between them preserves that; verify by running the test, not by eye.
- The test file defines both `assert_contains` and `assert_not_contains` taking three arguments `(file, text, description)` — unlike the existing single-file tests, this file asserts across three skills, so the helper is parameterized by file. Define both helpers now; Task 2 uses `assert_not_contains`.

- [ ] **Step 1: Write the failing tests**

Create `tests/toolbelt/test-execution-tracks.sh` following the header conventions in the Known Gotchas. Resolve `$repo_root` via `git rev-parse --show-toplevel`; set `plans=`, `sdd=`, `worktrees=` to the three SKILL.md paths. Add the two three-argument helpers, then the Task 1 assertions — phrase — description:
- `## Execution Tracks` in `$plans` — "plans may declare execution tracks"
- `No file is created or modified by two concurrent tracks` in `$plans` — "concurrent tracks require disjoint file sets"
- `contract-freeze` in `$plans` — "shared contracts freeze on the mainline before the fork"
- `Every fork closes with a mainline integration task` in `$plans` — "every merge point gets an integration task"
- `bogus or missing track declarations` in `$plans` — "plan review gate rejects bad track declarations"

End the file with `echo "PASS"`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-execution-tracks.sh`
Expected: `not ok - plans may declare execution tracks`, exit 1.

- [ ] **Step 3: Implement the writing-plans section and gates**

Insert a `## Execution Tracks` section into `skills/writing-plans/SKILL.md` immediately after the `## PR Boundaries` section. It must state, in skill register (condensed from spec Component 1, rationale omitted):

- The section is optional; when present it follows `## PR Boundaries` in the plan document; the example table from the Data Model, verbatim, in a fenced block.
- Structure rules: kebab-case track ids that become branch and worktree names; `serial-N` mainline segments run in the primary worktree, named tracks in sub-worktrees; every task number in exactly one track; tasks within a track run in numeric order; `Depends on` names tracks forming a DAG; tracks with identical satisfied dependencies may run concurrently.
- Declaration rules, each a bold-led bullet: disjoint file sets (containing the asserted phrase, and noting test files, fixtures, and generated-file sources count); no contract-shaped work in tracks — migrations, shared schema, shared types, and API contracts belong in a mainline task before the fork, named as the `contract-freeze` pattern; no cross-track interfaces — no task may list a concurrent track's `Produces:` in its `Consumes:`, anything consumed across tracks comes from a mainline task before the fork (mechanically checkable from `Interfaces:` blocks); threshold — a track must beat roughly 2–5 minutes of per-worktree setup: at least 2 tasks or one large task, smaller work stays mainline; the integration-task rule (containing the asserted phrase) — the integration task merges nothing itself, runs the integration scope (targeted cross-package checks and E2E over the merged tracks' seams, within SDD's Verification Scope policy, never a workspace-wide run) and fixes what breaks under the standard fix loop, and its task text states that its brief will include each merged track's `Decisions & drift risks` entries.

Extend **Self-Review** with item **6. Execution tracks:** when the plan declares tracks, every declaration satisfies the rules — file sets disjoint, no contract work or cross-track interfaces inside tracks, thresholds met, an integration task at every merge point, every task in exactly one track.

Extend the **Plan Review Gate** "Ask it to judge" list with one bullet — **Execution tracks** — phrased for the reviewer: reject bogus or missing track declarations as plan defects; a plan whose tracks fail the rules ships serial or gets restructured, never with optimistic tracks. The bullet must not read as penalizing serial plans: a plan with no `## Execution Tracks` section is valid and serial; "missing" means a declared split that lacks a required element (e.g. a merge point with no integration task, a task in no track).

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/toolbelt/test-execution-tracks.sh && bash tests/toolbelt/test-writing-plans.sh && scripts/lint-shell.sh tests/toolbelt/test-execution-tracks.sh`
Expected: both tests print PASS; lint reports no findings.

- [ ] **Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md tests/toolbelt/test-execution-tracks.sh
git commit -m "feat: writing-plans declares execution tracks"
```

## Task 2: subagent-driven-development executes tracks

**Spec source:** Components 2 and 4 (the dispatching-parallel-agents boundary line).

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md` (insert `## Parallel Tracks` between the `## Durable Progress` and `## Prompt Templates` sections; in `## Red Flags`, replace the old parallel-dispatch bullet per the Data Model)
- Modify: `skills/dispatching-parallel-agents/SKILL.md` (one bullet in the `## When to Use` "Don't use when" list)
- Modify: `tests/toolbelt/test-execution-tracks.sh` (append assertions)

**Interfaces:**
- Consumes: Task 1's grammar — section name `## Execution Tracks`, `serial-N` naming, track-id slugs, the integration-task rule; Data Model — execution formats, Red Flags replacement, Asserted Phrases rows 6–11 plus the absence check.
- Produces: nothing later tasks rely on.

**Gotchas:**
- **`implementer-prompt.md` stays untouched.** The drift-log requirement lives in the Parallel Tracks section as an instruction to the orchestrator: track implementer dispatches add a required report section `## Decisions & drift risks`; serial dispatches stay byte-identical. Do not add a conditional to the shared prompt template.
- The Red Flags edit is a verbatim replacement from the Data Model — replace the old line, add the new flag directly after it, change nothing else in the list.
- No test asserts the dispatching-parallel-agents line (the spec's test list deliberately omits it); it is verified by the task reviewer reading the diff.

- [ ] **Step 1: Write the failing tests**

Append to `tests/toolbelt/test-execution-tracks.sh`, before the final `echo "PASS"` — phrase — description:
- `## Parallel Tracks` in `$sdd` — "sdd carries the parallel-tracks section"
- `At most 3 tracks run concurrently` in `$sdd` — "concurrency cap is 3"
- `## Decisions & drift risks` in `$sdd` — "track reports carry a drift log"
- `A textual conflict is a plan defect` in `$sdd` — "track merge conflicts stop, never hand-resolved"
- `Dispatch multiple implementation subagents into the same worktree` in `$sdd` — "red flag scopes concurrency to one implementer per track worktree"
- `Parallelize tracks the plan did not declare` in `$sdd` — "undeclared parallelism is a red flag"
- assert_not_contains `Dispatch multiple implementation subagents in parallel (conflicts)` in `$sdd` — "old unconditional parallel-dispatch flag is gone"

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-execution-tracks.sh`
Expected: Task 1's assertions print ok, then `not ok - sdd carries the parallel-tracks section`, exit 1.

- [ ] **Step 3: Implement the SDD section, Red Flags, and the boundary line**

Insert a `## Parallel Tracks` section into `skills/subagent-driven-development/SKILL.md` between `## Durable Progress` and `## Prompt Templates`. Open it with the activation gate: active only when the plan **declares** an `## Execution Tracks` section — a top-level section of the plan document; a mention of the heading inside a code fence or prose is not a declaration. Without a declared section this skill is unchanged and serial. It must state, condensed to skill register from spec Component 2:

- **Wave execution**, as a numbered list mirroring the spec's five steps: (1) when a fork's mainline prerequisites are complete and reviewed, create one sub-worktree per ready track with the literal command from the Data Model, apply the project's worktree-policy setup rules to each, record each track's base SHA in the ledger; (2) dispatch each ready track's first implementer in the same message so they run concurrently, with the cap sentence containing the asserted phrase and the queue rule — when more are ready, largest by task count first, the rest queue and launch as slots free; (3) inside a track the existing process is unchanged — serial tasks, fresh implementer per task, per-task review with review packages, the fix loop, BASE/HEAD recorded per task on the track branch, with briefs, reports, and review packages in the plan's existing SDD workspace named per task as today; (4) when a track's last task is reviewed clean, merge the track branch into the feature branch with `--no-ff`, then remove the sub-worktree and branch — the merge is expected clean because file sets are disjoint, and a textual conflict is a plan defect (asserted phrase): stop, do not hand-resolve, surface to your human partner with the conflicting paths and the track declarations they contradict; (5) when every track at a fork has merged, dispatch the fork's integration task in the primary worktree as a normal task.
- **Working directories:** every dispatch for a track task — implementer, fixer, and reviewer alike — names the track worktree as its working directory (the implementer template's `Work from:` line carries it; reviewer dispatches state it the same way). Briefs, reports, review packages, and the ledger stay in the plan's SDD workspace under the primary worktree, reachable from every track by absolute path. The orchestrator runs `scripts/review-package` with the recorded BASE/HEAD SHAs, which resolve from any worktree because the object store is shared.
- **Drift log:** track implementer dispatches add a required report section `## Decisions & drift risks` — assumptions about the frozen contract, gametime decisions, anything a sibling track might contradict; `None` is valid. The orchestrator carries one ledger line per non-empty entry and pastes all merged tracks' entries into the integration task's brief.
- **Ledger:** one line per track alongside task lines, in the Data Model's format; after compaction, the ledger plus `git worktree list` plus `git log` reconstruct wave state. The existing single-`Next:`-line rule holds during a wave: still exactly one `Next:` line, aggregating the wave's pending events (e.g. `Next: wave — backend task 5 review; frontend task 8 report`).
- **Failure semantics:** a BLOCKED track does not stop its siblings — they run to completion while the orchestrator handles the block under existing rules; the fork's integration task waits for every track at that fork; fix-loop breaker rules unchanged. A `git worktree add` failure (sandbox denial) falls back to serial execution in the primary worktree for the affected tracks, reporting the downgrade. A discovered declaration-rule violation at execution time is surfaced like any plan defect, not silently serialized.
- One closing line: model selection, routing, reviewer prompts, and file handoffs are unchanged — track implementers and reviewers resolve through the same routes as serial ones.

Apply the Red Flags replacement from the Data Model in the `## Red Flags` list — replace the old bullet in place, keep the rest of the list untouched.

In `skills/dispatching-parallel-agents/SKILL.md`, add one bullet to the "Don't use when" list: **Executing plan tasks in parallel** — that belongs to subagent-driven-development's Execution Tracks, declared in the plan; this skill stays ad-hoc independent work (e.g., multi-cause debugging) in one workspace.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/toolbelt/test-execution-tracks.sh && scripts/lint-shell.sh tests/toolbelt/test-execution-tracks.sh`
Expected: test prints PASS; lint reports no findings.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md skills/dispatching-parallel-agents/SKILL.md tests/toolbelt/test-execution-tracks.sh
git commit -m "feat: sdd executes plan-declared parallel tracks"
```

## Task 3: worktree policy carries parallel-workspace rules

**Spec source:** Component 3.

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md` (extend the `## Project Worktree Policy` section)
- Modify: `tests/toolbelt/test-execution-tracks.sh` (append assertions)

**Interfaces:**
- Consumes: Data Model — Asserted Phrases rows 12–13; the pre-existing `## Project Worktree Policy` contract this task extends. No dependency on Task 2: both tasks reference the policy contract that already exists today — Task 2's "apply the project's worktree-policy setup rules" is meaningful with or without this extension.
- Produces: nothing later tasks rely on.

**Gotchas:**
- `tests/toolbelt/test-worktree-baseline.sh` asserts phrases in this exact section (`.toolbelt/worktree-policy.md`, `non-conflicting`) — extend the section, do not reword its existing two paragraphs.

- [ ] **Step 1: Write the failing tests**

Append to `tests/toolbelt/test-execution-tracks.sh`, before the final `echo "PASS"`:
- `parallel-workspace rules` in `$worktrees` — "policy contract covers parallel workspaces"
- `concurrency limit lower than 3` in `$worktrees` — "policy may lower the track cap, never raise it"

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-execution-tracks.sh`
Expected: earlier assertions ok, then `not ok - policy contract covers parallel workspaces`, exit 1.

- [ ] **Step 3: Implement the policy-contract extension**

Extend the `## Project Worktree Policy` section of `skills/using-git-worktrees/SKILL.md` with a short block stating that a policy may additionally declare **parallel-workspace rules** (asserted phrase):

- How to derive a per-workspace database name (or equivalent isolated resource) from the worktree/branch name.
- Which resources are per-workspace and which are safely shared.
- Setup commands to run per workspace (e.g., client codegen, migrations against the derived database).
- An optional concurrency limit lower than 3 when the machine cannot support three concurrent setups; subagent-driven-development honors the lower number.

Close with: subagent-driven-development applies these rules to every track worktree it creates and reports the claimed resource set per track in this skill's existing report shape; with no policy file, defaults apply exactly as today; a track that visibly needs isolated stateful resources with no policy declaring how is a gap to report, not improvise around.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/toolbelt/test-execution-tracks.sh && bash tests/toolbelt/test-worktree-baseline.sh && scripts/lint-shell.sh tests/toolbelt/test-execution-tracks.sh`
Expected: both tests print PASS; lint reports no findings.

- [ ] **Step 5: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md tests/toolbelt/test-execution-tracks.sh
git commit -m "feat: worktree policy carries parallel-workspace rules"
```

---

## Post-merge verification (not a task)

Per the spec's Testing section, the interactive suites are not extended. Live verification after release is the standard acceptance test plus one plan-with-tracks dry run in a consuming project — this happens in the normal release flow, outside this plan.
