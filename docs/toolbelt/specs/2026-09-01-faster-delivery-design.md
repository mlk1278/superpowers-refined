# Faster Delivery Design

**Status:** Approved in conversation on 2026-09-01.

Make the brainstorming → spec → plan → subagent-driven development → delivery
chain faster without changing its shape. Five rule changes, one template fix,
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

- Skills stay project-agnostic. Nothing here names a repo, a provider, or a
  model. Per-project values live in `.toolbelt/pr-policy.md` and
  `.toolbelt/worktree-policy.md`.
- The forceful blocks (`<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags tables,
  rationalization lists) keep their wording except where a rule in this spec
  changes what they say.
- One skill names exactly one next skill. Handoff chains do not change.
- Section headings that `tests/toolbelt/*.sh` grep for keep their exact text,
  or the test changes in the same commit.
- Version bumps to 7.9.0 in `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`.

## Component 1: `skills/writing-plans/SKILL.md`

### Tracks are the default

`## Execution Tracks` stops being optional. Every plan with more than one PR
boundary or more than three tasks has the section. A plan whose tracks are all
`serial-N` states in one sentence why no tasks can run concurrently, the same
way a one-PR plan justifies having one PR today.

The three declaration rules stay as written: disjoint file sets, no
contract-shaped work inside a track, no cross-track `Produces:`/`Consumes:`.
The threshold rule ("at least 2 tasks, or one large task") stays. The
concurrency cap stays at 3, lowerable by worktree policy.

The self-review item 6 and the plan-review bullet for tracks change from
"reject bogus or missing declarations" to: check the three rules
mechanically; a plan whose tracks pass them is accepted; a plan with no
concurrent tracks and no one-sentence justification is a defect.

Backend and frontend against a frozen contract is the reference shape and
stays as the example table. Vertical slices qualify under the same rules.

### Task size ceiling

Added to "Task Right-Sizing":

- A task's `**Files:**` block is closed. It lists every file the task
  creates or modifies. "Plus every caller," "compiler-led," and "wherever
  else it is referenced" are placeholders and fail the No Placeholders
  check.
- A task changes at most 8 files or roughly 400 lines of expected change,
  whichever is hit first. Larger work splits. Mechanical sweeps (a rename
  across many files) are the one exception and say so on the task.
- A task that adds or changes a migration, shared schema, shared type, or
  shared contract owns the code that keeps that change correct. It is a
  defect to fence that code into a later task. Split the other way: the
  contract task grows, the consumer task shrinks.

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

### Prose

Rewritten under Component 6. Headings `## Exploration Before Drafting`,
`## File Structure`, `## PR Boundaries`, `## Task Structure`,
`## Execution Tracks`, `## Plan Review Gate` keep their text.

## Component 2: `skills/subagent-driven-development/`

### Orchestrator-derived tracks

Replaces the "Active only when the plan declares" opening of Parallel Tracks
and the two Red Flags about undeclared parallelism.

When a plan has no `## Execution Tracks` section, or its section is all
`serial-N`, the orchestrator may derive tracks itself before dispatching Task
1. It applies the same three declaration rules from each task's `Files:` and
`Interfaces:` blocks, writes the derived table into the ledger under a
`Derived tracks:` heading with one line per rule stating it was checked, and
then executes exactly as if the plan had declared it. A derivation that fails
any rule is not recorded and the plan runs serial. Derived tracks never
override a plan that declared tracks.

Red Flags change to:

- Dispatch multiple implementation subagents into the same worktree —
  concurrent implementers are one per track worktree
- Run tracks concurrently without a declared or derived track table in the
  ledger that records all three rule checks

### Conditional re-review

The Fix Loop paragraph beginning "The round ends with a scoped re-review"
becomes:

The round ends one of two ways.

- **Re-review** when the task's `Files:` block touches a migration, shared
  schema, shared type, shared contract, or a permission or tenancy check, or
  when any open finding was Critical. Dispatch the scoped re-review as today.
- **Orchestrator close** otherwise. Read the fix report. Confirm it names
  each finding, the change made, and the covering test command with passing
  output. If every finding is covered, mark the task complete. If any is
  missing or the evidence is a claim without output, resume the implementer
  once for the gap, then close. Ledger line:
  `Task <N>: fix round closed by orchestrator (<X> findings, commits <a7>..<b7>)`.

Adjudication rules are unchanged and apply after either route.

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

### Stacked slices

Step 1 selects boundaries in plan order, not one slice at a time. Step 5
replaces the bulleted conditions with:

After the slice's broad final review is clean and its PR is open, start the
next boundary immediately:

- **Dependent boundary** (its `Depends on` names an open, unmerged PR):
  branch from that PR's branch, in a new worktree. Its PR targets that
  branch. This is a GitHub stack.
- **Independent boundary**: branch from the base branch, in a new worktree.

Any number of boundaries may be open. Each stack has exactly one pr-monitor,
started when its bottom PR opens and handed each new layer as it opens. An
independent boundary is its own stack of one.

When a stack's bottom PR merges, GitHub retargets the layer above it. The
monitor confirms the retarget and rebases if needed. In-flight worktrees for
higher layers rebase at their next task boundary, before their final review.

Never report the plan complete or end the session while a monitor runs. Read
merge state from the monitor's return and the PR, not from notifications.

The sentence "Dependent work waits for the merge — no stacked branches" and
the "At most one PR is in background monitoring" bullet are deleted.

### Prose

Rewritten under Component 6. Role ownership table keeps its rows; the
pr-monitor row reads "GitHub review, exact-head CI, fix loops, rebases,
merge, for one stack."

## Component 4: `skills/pr-monitor/SKILL.md`

### One monitor, one stack

The opening paragraph changes from "Own exactly one PR" to "Own one stack:
one PR, or a chain of PRs each targeting the one below it." Preflight records
every layer's number, branch, head SHA, base branch, and local-gate SHA.

Added section, `## Stack rules`:

- **Lowest first.** The lowest unmerged PR gets all attention until it
  merges. Review threads on higher layers are read and batched, never fixed
  while the bottom is not merge-ready.
- **Fix in the owner.** A finding lands in the lowest PR whose diff contains
  the code. After pushing, rebase every layer above it (`gh stack rebase` or
  `git rebase --onto`), push with `--force-with-lease`, and re-verify only
  layers whose patch changed (compare `git patch-id` before and after).
- **One topology writer.** Only the monitor rebases, retargets, or
  force-pushes a stack branch. Implementers and fixers never do.
- **Merge bottom-up.** Merge one layer, confirm `MERGED`, confirm the next
  layer retargeted to the base branch, re-run the merge preflight on it, then
  continue. Stop at the first layer that is not merge-ready and keep
  monitoring it.

### Timeout

Fallback default drops from 60 minutes to 20. `.toolbelt/pr-policy.md`
overrides in either direction.

### Return

Returns per layer: PR number, merged SHA, merge commit, or the durable
blocker.

## Component 5: `skills/quick-task/SKILL.md`, `skills/brainstorming/SKILL.md`, `skills/writing-specs/SKILL.md`, `skills/dispatching-parallel-agents/SKILL.md`

Prose only, under Component 6. No rule changes. dispatching-parallel-agents'
"Don't use when: executing plan tasks in parallel" bullet now points at SDD's
declared or derived tracks.

## Component 6: Plain-language rewrite

Applies to every file in Components 1–5 plus the three SDD prompt templates
and `docs/WORKFLOW.md`. Target: roughly half the current word count per file.

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
- Descriptions in frontmatter do not change; they decide triggering.

The `<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags, and rationalization blocks are
excluded from the rewrite except where Component 2 changes two Red Flags
lines.

## Error handling

- A derived track table that fails a rule mid-execution (a track touches a
  file another track touched): stop, surface the paths and the recorded
  derivation to the human partner, same as a declared-track conflict today.
- A stack whose bottom PR is closed without merging: the monitor returns a
  durable blocker for every layer; delivery surfaces it.
- `gh stack` unavailable: the monitor uses `git rebase --onto` and
  `gh pr edit --base`. The rules are the same.
- Orchestrator close finds a fix report with no covering-test output: one
  resume of the implementer for the evidence, then close or escalate.

## Testing

`tests/toolbelt/` gains or changes assertions:

- `test-writing-plans.sh`: Execution Tracks is required; Files block closed;
  8-file / 400-line ceiling text present; per-test RED expectations in the
  task template.
- `test-execution-tracks.sh`: derived-track ledger heading present in SDD;
  old "opportunistic parallelism is forbidden" text absent.
- New `test-fix-loop.sh`: conditional re-review text present; orchestrator
  close ledger line format present; route in in-progress ledger line.
- `test-delivery.sh`: "no stacked branches" absent; "At most one PR" absent;
  dependent boundary branches from the open PR's branch.
- `test-pr-monitor.sh`: `## Stack rules` present with all four rules; default
  timeout 20.
- Word-count check: each rewritten SKILL.md is at or under 60% of its
  pre-rewrite word count, recorded in the test as a fixed number per file.

Acceptance drill from CLAUDE.md after the cache refresh: "Let's make a react
todo list" triggers brainstorming in both harnesses.

## Out of scope

- An Invariants block in the task template.
- A per-boundary review depth column.
- Changing the concurrency cap.
- Dropping the alternate-harness spec or plan review.
- Any change to agent-routing, ux-gate, interactive-design, or
  finishing-a-development-branch beyond what Component 3's base-branch
  declaration already uses.
