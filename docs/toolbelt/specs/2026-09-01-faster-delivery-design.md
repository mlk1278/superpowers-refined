# Faster Delivery Design

**Status:** Approved in conversation on 2026-09-01. Revised the same day after
a Codex (GPT-5.6 Sol, high) spec review: 12 of 14 findings accepted.

Make the brainstorming → spec → plan → subagent-driven development → delivery
chain faster without changing its shape. Four rule changes, one template fix,
and a plain-language rewrite of the planning skills.

## Goal

Multi-day feature workflows should take hours. The evidence behind each change
came from reading every review, ledger, and fix report across six SDD
workspaces (about 186 findings). Three things dominate the wall clock:

1. Tracks run serially even when the plan's tasks touch disjoint files. The
   execution-tracks machinery (spec 2026-08-05) is merged and works, but the
   rules around it mean it almost never runs.
2. Every task pays a fixed chain: implementer, reviewer, fix round, re-review,
   adjudication. About 65% of blocking findings are load-bearing, so the
   per-task review stays. The re-review is where the chain can be shortened.
3. The next PR waits for the current one to merge. Delivery allows one PR in
   flight and forbids stacked branches.

The evidence also showed where defects come from. Of 26 load-bearing findings
traced to their brief: 9 were things the brief never said, 4 were things the
brief said wrong, 8 were implementer misses against a quotable line, 2 were
tasks far too big (a 123-word brief governing a 20,632-line diff), and 3 were a
mismatch between the plan template's RED step and the reviewer's seen-red rule.
Two of those causes get a fix here: task size and the RED step.

Trade-off accepted by the human partner: a little reliability for speed, and
nothing that adds surface area the evidence does not clearly justify.

## Constraints

- Skills hard-code no consuming repository, review provider, or model.
  GitHub stays the supported PR host, as it is today. Per-project values live
  in `.toolbelt/pr-policy.md` and `.toolbelt/worktree-policy.md`.
- The forceful blocks (`<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags tables,
  rationalization lists) keep their wording except where a rule in this spec
  changes what they say.
- One skill names exactly one next skill. Handoff chains do not change.
- Every `tests/toolbelt/*.sh` assertion that a change makes false is updated
  in the same commit. The Testing section lists the known ones.
- Frontmatter descriptions do not change, except pr-monitor's (Component 4).
- Version bumps to 7.9.0 with `scripts/bump-version.sh 7.9.0`, verified by
  `scripts/bump-version.sh --check`.

## Component 1: `skills/writing-plans/SKILL.md`

### Tracks are the default

`## Execution Tracks` stops being optional. Every plan with more than one PR
boundary or more than three tasks has the section. A plan whose tracks are all
`serial-N` states in one sentence why no tasks can run concurrently, the same
way a one-PR plan justifies having one PR today.

The declaration rules, threshold, integration-task rule, and the cap of 3 stay
as written. Self-review item 6 and the plan-review bullet for tracks change
from "reject bogus or missing declarations" to: check the declaration rules;
a plan whose tracks pass them is accepted; a plan with no concurrent tracks
and no one-sentence justification is a defect.

Backend and frontend against a frozen contract is the reference shape and
stays as the example table. Vertical slices qualify under the same rules.

### Task size ceiling

Added to "Task Right-Sizing":

- A task's `**Files:**` block is closed. It lists every file the task
  creates or modifies. "Plus every caller," "compiler-led," and "wherever
  else it is referenced" are placeholders and fail the No Placeholders
  check.
- A task lists at most 8 files. This is a hard limit. As a guide, a task's
  change should be readable in one sitting, around 400 lines; the plan
  reviewer flags tasks that look larger.
- The one exception is a mechanical sweep: one uniform, behavior-neutral
  transformation (a rename, an import path change) with one verification
  command. The task says "Mechanical sweep:" and names the command.
- A task that adds or changes a migration, shared schema, shared type, or
  shared contract owns the code that keeps that change correct. Fencing
  that code into a later task is a defect. If the result exceeds 8 files,
  split it into serial tasks that each leave the contract correct.

### RED step names the failure

Task Structure Step 2 changes from one expected failure for the whole file to
one line per test:

```markdown
- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/path/test.py -v`
Expected, per test:
- `test_rejects_duplicate_key` — FAIL: `create_definition` not defined
- `test_defaults_type_to_text` — FAIL: `create_definition` not defined
```

Added rule under Task Structure: a guard or negative assertion (a permission
check, a tenant filter, a rejection path) lists its red as the failure seen
when the guard is absent, not when the module is absent. The implementer
proves it that way (Component 2).

### Execution handoff

The handoff paragraph changes from one boundary at a time to the whole plan:

> "Plan complete and saved to `docs/toolbelt/plans/<filename>.md`, reviewed
> through <reviewer harness>. Handing the plan to delivery."

Delivery owns boundary order from there (Component 3).

### Prose

Rewritten under Component 6. Headings `## Exploration Before Drafting`,
`## File Structure`, `## PR Boundaries`, `## Task Structure`,
`## Execution Tracks`, `## Plan Review Gate` keep their text.

## Component 2: `skills/subagent-driven-development/`

### Tracks

Parallel Tracks keeps "active only when the plan declares." The Red Flag
"Parallelize tracks the plan did not declare" stays. Runtime derivation was
considered and dropped: mandatory tracks in the plan, checked by the plan
reviewer, cover the same ground without a second, unreviewed partition.

### Conditional re-review

The Fix Loop paragraph beginning "The round ends with a scoped re-review"
becomes:

The round ends one of two ways.

- **Re-review** when the task's `Interfaces: Produces:` block is non-empty
  (a later task builds on this one) or when any open finding was Critical.
  Dispatch the scoped re-review as today. The plan template writes
  `Produces: none` when nothing downstream depends on the task, so the
  block is never ambiguous.
- **Orchestrator close** otherwise. Read the fix report's findings table
  (below). Every row must name the finding, the commit, the covering test
  command, and its passing output. If every row is complete, mark the task
  complete. If a row is missing or its output is a claim without the
  command's output, resume the implementer once for that row. If it is still
  incomplete, escalate to your human partner as a BLOCKED task. Ledger line:
  `Task <N>: fix round closed by orchestrator (<X> findings, commits <a7>..<b7>)`.

Adjudication rules are unchanged and apply after either route.

The fix report gains a required table, added to `implementer-prompt.md` under
"After Review Findings":

```markdown
| Finding | Commit | Covering test command | Result |
|---|---|---|---|
```

`Result` is the command's last passing line, pasted.

### Ledger records the implementer route

Durable Progress, task lines: `Task N: in-progress (agent <id>, route
<harness>/<model>/<effort>)`. The route is the resolved one from
agent-routing, copied from the dispatch. Complete lines keep the route.

### Implementer template RED evidence

`implementer-prompt.md`, the seen-red paragraph becomes:

> A guard or negative assertion counts only when you have seen it fail
> against code that lacks the guard, not against a missing module. Report the
> command and the failing output in TDD Evidence, one line per guard.

Report Format's TDD Evidence bullet adds: "for each guard, the seen-red
command and output."

### Prose

Rewritten under Component 6. `re-review-prompt.md` adds one line: findings
outside the fix diff go to the ledger and never extend the loop. (The rule
exists in SKILL.md; the prompt did not carry it, and one task ran seven
rounds because of it.)

## Component 3: `skills/delivery/SKILL.md`

### Entry and loop

Entry: an approved plan. Exit: every PR boundary merged, reconciled, and
cleaned up.

Delivery runs a loop over the plan's `## PR Boundaries` table in order.
For each boundary it runs Steps 2–5 as today. Step 5 no longer waits for
merge before the next boundary starts.

### Stacked slices

Step 5 replaces the bulleted wait conditions with:

After the boundary's broad final review is clean and its PR is open, start
the next boundary immediately.

- **Dependent boundary** (its `Depends on` names a boundary whose PR is open
  and unmerged): fetch the predecessor's remote head, then create the
  worktree from that SHA. Its PR targets the predecessor's branch. This is a
  manual PR chain; it does not depend on GitHub's native stack feature.
- **Independent boundary**: create the worktree from the base branch. Its PR
  targets the base branch.

Branch names are `<plan-slug>/pr-<N>` where `<plan-slug>` is the plan file's
basename without date and extension and `<N>` is the boundary number. The
SDD ledger for the plan records one line per boundary:
`Boundary <N>: branch <name>, PR #<num>, base <branch>, state <open|merged|blocked>`.

Any number of boundaries may be open. Each chain has exactly one pr-monitor,
started when its bottom PR opens. When a dependent boundary's PR opens,
delivery hands it to that chain's monitor by resuming the monitor with the
new layer's number, branch, and head. An independent boundary starts its
own chain.

### Who rebases

Ownership follows publication. Delivery owns a boundary's branch until its
PR opens: when a lower PR's branch moves, delivery rebases the unpublished
branch at its next task boundary, before its final review, and appends
`Boundary <N>: rebased <old7> → <new7>` to the ledger. Once the PR is open,
only the monitor moves the branch. Implementers and fixers never rebase.

Never report the plan complete or end the session while a monitor runs. Read
merge state from the monitor's return and the PR, not from notifications.

The sentence "Dependent work waits for the merge — no stacked branches" and
the "At most one PR is in background monitoring" bullet are deleted. Step 6
runs once per merged boundary, when the monitor returns that layer merged.

### Role table

The pr-monitor row reads "GitHub review, exact-head CI, fix loops, rebases
and retargets of published branches, merge, for one PR chain." The
orchestrator row adds "reads fix-report tables to close a fix round (SDD
orchestrator close); never re-reads test output beyond that table."

### Prose

Rewritten under Component 6.

## Component 4: `skills/pr-monitor/SKILL.md`

### One monitor, one chain

Description becomes: "Own one pull request, or a chain of dependent pull
requests, from current heads through CI, configured review providers, fix
loops, rebases, and merge or a durable blocker. Internal helper started by
delivery after a PR opens."

The opening paragraph changes from "Own exactly one PR" to "Own one chain:
one PR, or PRs each targeting the one below it." Preflight records every
layer's number, branch, head SHA, base branch, and local-gate SHA. A resume
carrying a new layer appends it to the chain.

### Chain rules

Added section, `## Chain rules`:

- **Lowest first.** The lowest unmerged PR gets all attention until it
  merges. Review threads on higher layers are read and batched, never fixed
  while the bottom is not merge-ready.
- **Fix in the owner.** A finding lands in the lowest PR whose diff contains
  the code. After pushing it, rebase every layer above with
  `git rebase --onto <owner-head> <old-owner-head> <layer-branch>` and push
  each with `--force-with-lease`. Every rebased head starts a new evidence
  cycle: exact-head CI, provider review, mergeability, and threads all
  re-run. Local review repeats only when a layer's
  `git patch-id --stable` changed.
- **One topology writer.** Only the monitor rebases, retargets, or
  force-pushes a published branch.
- **Merge bottom-up.** Squash-merge the bottom layer and delete its branch.
  GitHub then retargets the next layer to the deleted branch's base; confirm
  it with `gh pr view --json baseRefName`, and set it with
  `gh pr edit --base` if it did not happen. Rebase the next layer with
  `git rebase --onto <base-branch> <merged-layer-old-head> <layer-branch>`
  so the squashed commits are not replayed, push with `--force-with-lease`,
  re-run the merge preflight, then continue. Stop at the first layer that is
  not merge-ready and keep monitoring it.

### Timeout

Fallback default drops from 60 minutes to 20. `.toolbelt/pr-policy.md`
overrides in either direction.

### Return

Per layer: PR number, final head SHA, remote state (`MERGED`, `OPEN`,
`CLOSED`), the merge commit OID when merged, target branch, and the blocker
reason when not merged. Lower layers that merged before a higher layer
blocked appear as `MERGED` with their OIDs.

## Component 5: `skills/using-git-worktrees/SKILL.md`

The fallback command gains a source ref, and the skill gains a rule that a
caller may name one:

```bash
git worktree add "$path" -b "$BRANCH_NAME" "${SOURCE_REF:-HEAD}"
```

When the caller (delivery) names a source ref, the native tool is used only
if it accepts one; otherwise the fallback runs. When the session is already
in a linked worktree and the caller asks for a new sibling, the skill creates
it rather than skipping creation.

## Component 6: `skills/quick-task/SKILL.md`, `skills/brainstorming/SKILL.md`, `skills/writing-specs/SKILL.md`, `skills/dispatching-parallel-agents/SKILL.md`

Prose only, under Component 7. No rule changes.

## Component 7: Plain-language rewrite

Applies to every file in Components 1–6 plus the three SDD prompt templates
and `docs/WORKFLOW.md`. Target: roughly half the current word count per file.
The human partner asked for this directly; it is in scope on that basis.

Rules for the rewrite:

- One idea per sentence. Short declarative sentences. Imperative mood for
  instructions.
- Say the rule once. Delete restatements, rationales for the obvious, and
  sentences that explain why the previous sentence is true.
- No metaphor, no rhetorical framing ("wearing the language of," "the whole
  point," "is the tell"). No intensifiers ("ruthlessly," "genuinely,"
  "silently," "however independent they look").
- Keep every gate, every exact command, every exact path, every quoted
  user-facing message, and every table verbatim unless a rule above changes
  it.
- "Your human partner" stays.
- Before rewriting a file, list the lines `tests/toolbelt/*.sh` and
  `tests/hooks/*` assert on for that file. Those lines are kept verbatim or
  their tests change in the same commit.

The `<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags, and rationalization blocks are
excluded from the rewrite.

## Error handling

- A chain whose bottom PR is closed without merging: the monitor returns
  `CLOSED` for it and a durable blocker for every layer above; delivery
  surfaces it to the human partner.
- A rebase conflict in the monitor: stop, leave the branch as it was (abort
  the rebase), return the layer as blocked with the conflicting paths.
- Orchestrator close finds an incomplete fix-report row after the one
  resume: BLOCKED, escalate.
- `git worktree add` with a source ref denied by the sandbox: existing
  fallback (work in place), reported as today.

## Testing

Existing assertions that become false, each replaced in the same commit:

- `test-writing-plans.sh:103` "one declared PR boundary at a time" → the new
  handoff line.
- `test-execution-tracks.sh`: any needle on "Optional." for the tracks
  section → "required" wording.
- `test-final-review-gate.sh`: the final-review re-review assertions stay;
  add the conditional task re-review needles.
- `test-delivery.sh`: needles on one slice / one monitored PR → chain
  wording.
- `test-pr-monitor.sh:30` "Own exactly one PR" → "Own one chain".
- `test-interactive-design.sh` and `test-workflow-summary.sh`: re-check
  every needle against brainstorming, writing-specs, and `docs/WORKFLOW.md`
  after the rewrite.

New assertions:

- `test-writing-plans.sh`: Execution Tracks required; closed Files block;
  "at most 8 files"; per-test RED expectations; "Mechanical sweep:".
- New `test-fix-loop.sh`: re-review condition names `Produces:` and
  Critical; orchestrator-close ledger line format; route in the in-progress
  ledger line; fix-report table header in `implementer-prompt.md`;
  re-review prompt's out-of-scope line.
- `test-delivery.sh`: "no stacked branches" absent; "At most one PR" absent;
  branch name format; boundary ledger line format.
- `test-pr-monitor.sh`: `## Chain rules` present with all four rule names;
  default 20 minutes; `--force-with-lease`; `git patch-id --stable`.
- New `test-worktree-source-ref.sh`: the fallback command carries
  `SOURCE_REF`.
- New `test-chain-rebase.sh`: in a temporary git repository, build main →
  pr-1 → pr-2, squash-merge pr-1 into main, run the Component 4 rebase
  recipe on pr-2, and assert pr-2 contains only its own commit on top of
  main. This is the one mechanic where a wrong recipe destroys work.
- Word count: a table in `tests/toolbelt/test-word-counts.sh` with one
  integer ceiling per rewritten file, set at implementation to 60% of the
  pre-rewrite count, rounded up to the nearest 10.

Acceptance drill from CLAUDE.md after the cache refresh: "Let's make a react
todo list" triggers brainstorming in both harnesses.

## Out of scope

- Orchestrator-derived tracks at execution time.
- An Invariants block in the task template.
- A per-boundary review depth column.
- Changing the concurrency cap.
- Dropping the alternate-harness spec or plan review.
- GitHub's native stacked-PR feature (`gh stack`). The manual chain works
  with or without it.
- Any change to agent-routing, ux-gate, interactive-design, or
  finishing-a-development-branch beyond what Component 3's base-branch
  declaration already uses.
