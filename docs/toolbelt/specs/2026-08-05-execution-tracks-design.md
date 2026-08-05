# Execution Tracks Design

**Status:** Approved in conversation on 2026-08-05.

Plan-declared, track-level parallelism for subagent-driven development. Plans may
declare independent chains of tasks ("tracks") that execute concurrently, each in
its own sub-worktree, merged back at a declared integration point. Serial
execution remains the default; parallelism exists only where a plan explicitly
declares it safe.

## Goal

Cut wall-clock time on plans containing independent work (multiple screens,
frontend/backend behind a frozen contract) without adding merge conflicts, drift,
or orchestration layers. Only low-risk parallelizations qualify; anything that
needs an essay to justify its independence stays serial.

## Constraints

- **One orchestrator.** The session agent orchestrates every track directly.
  No nested orchestrators, no lane-level sub-orchestrators — sandboxes cannot
  spawn sibling sandboxes, and extra layers destroy observability.
- **Plan-declared only.** Execution never invents parallelism. No Execution
  Tracks section in the plan means fully serial execution, exactly as today.
- **Concurrency cap: 3 tracks.** A project's worktree policy may lower this,
  never raise it.
- **Nothing project-specific in skills.** DB naming, setup commands, and
  resource rules live in the consuming project's `.toolbelt/worktree-policy.md`.
  Skills never invent a resource scheme when the policy is silent.
- **Sub-worktrees are plain local git** (`git worktree add`) — no new sandboxes,
  no cross-sandbox communication.

## Component 1: `skills/writing-plans/SKILL.md` — declaring tracks

A new optional plan-header section, `## Execution Tracks`, placed after
`## PR Boundaries`. When present:

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

- Track ids are kebab-case slugs (they become branch names and worktree
  directory names). Mainline segments are tracks named `serial-N`.
- Every task number appears in exactly one track. Tasks within a track run in
  numeric order.
- `Depends on` names tracks, forming a DAG. Tracks with identical satisfied
  dependencies may run concurrently.
- Mainline segments (`serial-N`) execute in the primary worktree; named tracks
  execute in sub-worktrees.

Declaration rules (what makes a split low-risk enough to declare):

- **Disjoint file sets.** No file is created or modified by two concurrent
  tracks. Test files, fixtures, and generated-file sources count.
- **No contract-shaped work in tracks.** Migrations, shared schema, shared
  types, and shared API contracts belong in a mainline task before the fork —
  the contract-freeze pattern. A track consumes the frozen contract; it never
  changes it.
- **No cross-track interfaces.** No track's task may list another concurrent
  track's `Produces:` in its `Consumes:`. Anything consumed across tracks must
  be produced by a mainline task before the fork. Mechanically checkable from
  the existing `Interfaces:` blocks.
- **Threshold.** A track must be substantial enough to beat roughly 2–5 minutes
  of per-worktree setup: at least 2 tasks, or one large task. Work below the
  threshold stays in the mainline.
- **Every fork closes with a mainline integration task.** It merges nothing
  itself (the orchestrator merges); it runs the integration scope — E2E,
  cross-package tests — and fixes what breaks, under the standard fix loop.
  Its task text states that its brief will include each merged track's
  `Decisions & drift risks` entries.

Gate additions:

- **Self-review** gains one check: every track declaration satisfies the rules
  above — file sets disjoint, no contract work or cross-track interfaces inside
  tracks, thresholds met, an integration task at every merge point, every task
  in exactly one track.
- **Plan review gate** (`plan-document-reviewer-prompt.md` criteria list in the
  skill) gains the same check, phrased for the reviewer: reject bogus or missing
  track declarations as plan defects. A plan whose tracks fail the rules ships
  serial or gets restructured; it does not ship with optimistic tracks.

## Component 2: `skills/subagent-driven-development/SKILL.md` — executing tracks

A new `## Parallel Tracks` section, active only when the plan contains
`## Execution Tracks`. Without it, the skill is unchanged and serial.

**Wave execution.** The orchestrator walks the track DAG:

1. When a fork's mainline prerequisites are complete and reviewed, create one
   sub-worktree per ready track:
   `git worktree add <sdd-workspace>/tracks/<track-id> -b <feature-branch>--<track-id>`
   branched from the current feature-branch head. Apply the project's
   worktree-policy setup rules to each (install, codegen, per-workspace
   resources). Record each track's base SHA in the ledger.
2. Dispatch each ready track's first implementer — all in the same message so
   they run concurrently. **At most 3 tracks run concurrently.** When more are
   ready, run the largest (by task count) first; the rest queue and launch as
   slots free.
3. **Inside a track, the existing process is unchanged:** serial tasks, fresh
   implementer per task, per-task review with review packages, the 3-round fix
   loop, BASE/HEAD recorded per task on the track branch. Briefs, reports, and
   review packages live in the plan's existing SDD workspace, named per task as
   today.
4. When a track's last task is reviewed clean, the orchestrator merges the
   track branch into the feature branch with `--no-ff`, then removes the
   sub-worktree and branch. The merge is expected clean because file sets are
   disjoint. **A textual conflict is a plan defect:** stop, do not hand-resolve,
   surface to your human partner with the conflicting paths and the track
   declarations they contradict.
5. When every track at a fork has merged, dispatch the fork's integration task
   in the primary worktree as a normal task.

**Drift log.** Track implementer reports gain a required
`## Decisions & drift risks` section: assumptions made about the frozen
contract, gametime decisions, anything a sibling track might contradict.
`None` is a valid entry. The orchestrator carries one ledger line per non-empty
entry and pastes all merged tracks' entries into the integration task's brief.

**Ledger extensions.** One line per track alongside task lines:
`Track B: in-progress (task 8/9, worktree <path>, base <sha7>)` →
`Track B: merged (<sha7>, worktree removed)`. After compaction, the ledger plus
`git worktree list` plus `git log` reconstruct wave state.

**Failure semantics.** A BLOCKED track does not stop its siblings — they run to
completion while the orchestrator handles the block under existing rules. The
fork's integration task waits for every track at that fork. Fix-loop breaker
rules are unchanged.

**Red Flags changes.** The existing line

> Dispatch multiple implementation subagents in parallel (conflicts)

becomes

> Dispatch multiple implementation subagents into the same worktree —
> concurrent implementers are only ever one-per-track-worktree, declared by the
> plan's Execution Tracks section

plus one new flag:

> Parallelize tracks the plan did not declare — opportunistic parallelism at
> execution time is forbidden, however independent two tasks look

**Model selection, routing, reviewer prompts, file handoffs:** unchanged. Track
implementers and reviewers resolve through the same routes as serial ones.

## Component 3: `skills/using-git-worktrees/SKILL.md` — policy contract extension

The "Project Worktree Policy" section (where the `.toolbelt/worktree-policy.md`
contract is defined) documents that a policy may additionally declare
**parallel-workspace rules**:

- How to derive a per-workspace database name (or equivalent isolated resource)
  from the worktree/branch name.
- Which resources are per-workspace and which are safely shared.
- Setup commands to run per workspace (e.g., client codegen, migrations against
  the derived database).
- An optional concurrency limit lower than 3 when the machine cannot support
  three concurrent setups; SDD honors the lower number.

SDD applies these rules to every track worktree it creates and reports the
claimed resource set per track, in the skill's existing report shape. With no
policy file, defaults apply exactly as today: worktrees are created, auto-
detected setup runs, and no naming or allocation scheme is invented. A track
that visibly needs isolated stateful resources with no policy declaring how is
a gap to report, not improvise around — consistent with the skill's existing
rationalization table.

## Component 4: boundary cleanup

- `skills/dispatching-parallel-agents/SKILL.md` gains one boundary line in
  "When to Use": executing plan tasks in parallel belongs to
  subagent-driven-development's Execution Tracks, not this skill. Its scope
  stays ad-hoc independent work (e.g., multi-cause debugging) in one workspace.
- `skills/delivery/SKILL.md`, `skills/finishing-a-development-branch/SKILL.md`,
  the final whole-branch review, `writing-specs`, and `brainstorming` are
  untouched. Tracks live entirely inside one slice and one PR; the
  one-background-PR rule stands.

## Error handling

| Failure | Handling |
|---|---|
| Textual merge conflict on track merge-back | Plan defect: stop, surface conflicting paths and track declarations; never hand-resolve |
| Track BLOCKED | Siblings continue; existing BLOCKED handling applies to the track; integration waits for all tracks at the fork |
| Integration task finds semantic drift | Standard fix loop on the integration task, informed by the tracks' drift logs |
| More ready tracks than slots | Largest first, rest queue; never exceed the cap |
| `git worktree add` fails (sandbox denial) | Fall back to serial execution in the primary worktree for the affected tracks; report the downgrade |
| Plan declares tracks violating declaration rules | Caught at plan self-review/review gate; at execution time, a discovered violation is surfaced like any plan defect, not silently serialized |

## Testing

`tests/toolbelt/` assertions:

- Existing: `test-worktree-baseline.sh` asserts `.toolbelt/worktree-policy.md`
  is consulted — unaffected. No existing test asserts the amended Red Flag line.
- New content assertions, following the existing `assert_contains` style:
  - writing-plans contains `## Execution Tracks` and the integration-task rule.
  - subagent-driven-development contains the same-worktree Red Flag phrasing
    and the undeclared-parallelism flag.
  - using-git-worktrees mentions parallel-workspace rules in the policy
    section.
- The interactive suites (`tests/claude-code/`, `tests/explicit-skill-requests/`)
  are not extended; live verification is the standard acceptance test plus one
  plan-with-tracks dry run in a consuming project.

## Out of scope

- Parallel PR lanes / multiple concurrent PRs (delivery's one-background-PR
  rule is unchanged).
- Task-level (per-task worktree) parallelism — rejected for setup overhead;
  tracks amortize setup across their tasks.
- Any scheduler smarter than "ready tracks, largest first, cap 3".
- Cross-harness changes: this is skill text only; no hook or manifest changes,
  so no plugin-cache refresh subtleties beyond the normal release flow.
