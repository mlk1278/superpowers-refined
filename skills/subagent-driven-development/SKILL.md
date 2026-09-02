---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

**Continuous execution:** Do not check in with your human partner between tasks unless you hit an unresolvable BLOCKED status, blocking ambiguity, or the end of the plan.

## The Process

1. Read the plan once. Create todos and the ledger.
2. Pre-flight scan, then per task: record BASE (current head), dispatch the implementer with its brief, answer its questions, build the review package on DONE, dispatch the task reviewer, run the fix loop, mark the task complete in todos and the ledger.
3. After all tasks, dispatch the final whole-branch reviewer ([code-reviewer.md](../requesting-code-review/code-reviewer.md)) before the branch is published. If it must run after PR review rounds landed commits, put those accepted findings in its brief.
4. Hand off to toolbelt:finishing-a-development-branch.

**Optional pre-final gate:** If the caller supplies a pre-final gate, run it after all task reviews and before the broad final review. A caller's role-ownership table governs who runs each gate and captures its evidence; task briefs must not reassign those roles.

**Pre-flight scan.** Before Task 1, scan the plan for tasks that contradict each other or the Global Constraints, and for anything it mandates that the review rubric treats as a defect. Ask about all findings in one batched question, each beside the plan text that mandates it.

## Model Selection

**Caller routing takes precedence:** plan route, then project route, then the session routing brief. Every role you dispatch — implementer, reviewer, explorer, errand — comes from the brief; you stay the orchestrator. If no route resolves, stop and tell your human partner; do not substitute your own judgment for a missing route. The final whole-branch review gets the most capable route offered. **Always specify the model explicitly**; an omitted model inherits your session's model.

## Handling Implementer Status

Only the final answer carrying the Status token is the report. On an intermediate message or an interrupted wait, resume waiting on the same agent.

- **DONE:** run `scripts/review-package --plan PLAN_FILE BASE HEAD` (from this skill's directory; it prints the path it wrote) and dispatch the task reviewer with that path. BASE is the commit you recorded before dispatching, never `HEAD~1`.
- **DONE_WITH_CONCERNS:** address correctness and scope concerns before review; note observations and proceed.
- **NEEDS_CONTEXT:** supply what was missing and re-dispatch.
- **BLOCKED:** change something before retrying — more context, a more capable routed model, a smaller task, or escalation if the plan is wrong.

Resolve every reviewer "⚠️ Cannot verify from diff" item yourself before marking the task complete. A confirmed gap enters the fix loop.

## The Fix Loop

Trigger: spec ❌, any Critical or Important finding, or a ⚠️ item you confirmed. Two routes leave before it starts:

- **Minor findings** go to the ledger roll-up.
- **Plan-mandated findings** are the human's decision. Present the finding beside the plan text and ask which governs.

**One fix round per task.** Resume the original implementer with the open findings verbatim. If your harness cannot message a live subagent, dispatch a fresh implementer with the brief path, the report-file path, and the findings.

**Re-review** when the task's `Interfaces: Produces:` value is anything other than exactly `none`, or when any open finding was Critical. Dispatch the scoped re-review ([re-review-prompt.md](re-review-prompt.md)) over the fix delta: `scripts/review-package --plan PLAN_FILE FIX_BASE HEAD`, FIX_BASE being the head the previous review saw. It verdicts each finding ADDRESSED or NOT ADDRESSED and flags new breakage **in the fix diff only**; Critical or Important breakage there joins the open findings, and out-of-scope observations go to the ledger as deferred minors and never extend the loop. Append `Task <N>: fix round (<X> addressed, <Y> open — <one-liners>; commits <a7>..<b7>)`.

**Orchestrator close** otherwise — the plan template writes `Produces: none` when nothing downstream depends on the task. Read the fix report's findings table against the open findings: it must hold exactly one complete row per open finding, each naming the finding, the commit, the covering test command, and its passing output. Mark the task complete when every row is complete. If a row is missing, or its result is a claim without the command's output, resume the implementer once for that row; if it is still incomplete, escalate to your human partner as a BLOCKED task. Append `Task <N>: fix round closed by orchestrator (<X> findings, commits <a7>..<b7>)`.

Adjudicate **only** after the re-review or the orchestrator close, and rule on each finding still open yourself:

- **Reviewer is wrong, or contestable** — park it: `Task <N>: parked — <finding> — ruling: <why the code stands>`.
- **Real, but nothing downstream builds on it** — park it the same way, ruled real and deferred.
- **Real and load-bearing** — **STOP.** Append `Task <N>: BLOCKED — <reason>` and give your human partner the finding, the plan text it collides with, and the fix history.

Every adjudication is a ledger entry.

## Verification Scope

Run the smallest command that proves what the diff touched.

- **Iterating:** focused tests for the code being changed.
- **Task gate:** the affected package suite(s) once — packages the diff touches plus direct consumers of a changed shared contract. High-risk changes (auth, tenancy, migrations, shared schemas, cross-package behavior) add targeted cross-package checks, not a workspace run.
- **Fix rounds:** covering tests only.
- **Workspace-wide suite:** once, at the final gate. toolbelt:finishing-a-development-branch Step 1 owns its evidence, reuse, and docs-only cases. Task gates never run it, and nobody reruns it because a PR opened.

Reviewers and orchestrators read the implementer's test evidence on unchanged source instead of re-running it. Implementers and fixers always produce their own fresh evidence.

Run suites through the project's quiet-run wrapper when it has one, reading back exit status, pass count, and failure tail. A buffered wrapper releases nothing until the command exits, so it never carries a check that gates that command — run the gate first, as its own command.

Surface any plan or brief that mandates broader verification than this policy; do not obey or override it on your own.

## Constructing Reviewer Prompts

- Never tell a reviewer what not to flag, and never pre-rate a severity.
- Copy binding requirements verbatim from the plan's Global Constraints or the spec: exact values, exact formats, stated relationships.
- `[REVIEW_NUANCE]` takes task-specific context and risks. It must not override requirements, suppress findings, or pre-judge severity. Use `None` when there is none.
- `docs/REVIEW-GUIDANCE.md` is reviewer-only. Do not read it while orchestrating or pass it to implementers, fixers, explorers, planners, errands, or monitors.
- Describe one task per dispatch prompt, never the session's history.
- Fix dispatches carry the implementer contract: the fixer re-runs the tests covering its change and reports results. Before ending the round, confirm the fix report contains the covering tests, the command, and the output.
- Point the final review at the ledger's minor findings, to triage before merge.
- **Final-review findings get ONE fix subagent** with the complete list — not one fixer per finding. Then run exactly one scoped re-review of the fix wave, and adjudicate residual findings as at the task loop. There is no second fix wave; residual load-bearing findings go to your human partner at finishing-a-development-branch.

## File Handoffs

Hand artifacts over as files.

- **Task brief:** run `scripts/task-brief PLAN_FILE N`. The dispatch carries: where the task fits, in one line; the brief path, introduced as "read this first — it is your requirements, with the exact values to use verbatim"; interfaces and decisions from earlier tasks, plus the plan's Global Constraints and Known Gotchas; your resolution of any ambiguity you spotted; the report-file path and report contract. Exact values appear **only** in the brief.
- **Report file:** named after the brief (`…/task-N-brief.md` → `…/task-N-report.md`). The implementer writes its full report there and returns status, commits, a one-line test summary, and concerns.
- **Reviewer inputs:** the brief, the report, the review package, the smell baseline (`../requesting-code-review/smell-baseline.md`), and the global constraints binding the task.
- **Review package:** `scripts/review-package --plan PLAN_FILE BASE HEAD` for tasks, `scripts/review-package --plan PLAN_FILE MERGE_BASE HEAD` for the final review (MERGE_BASE = `git merge-base main HEAD`). Pass the printed path as `[DIFF_FILE]`.
- Fix dispatches append their fix report to the same report file; re-reviews read it.

## Durable Progress

Track progress in a ledger file, not only in todos.

At skill start run `scripts/sdd-workspace PLAN_FILE`; it prints this plan's git-ignored directory (`<repo-root>/.toolbelt/sdd/<plan-basename>-<digest>/`) holding every artifact for THIS plan. Another plan's directory is never yours to read or write.

Read this plan's ledger at `<workspace>/progress.md`. Tasks marked complete there are DONE; resume at the first task not marked complete. A ledger whose header names a different plan file belongs to that plan: leave it and start your own.

Update the ledger with your other bookkeeping:

- **Header:** branch, plan path, current exact head SHA. The plan path is the ledger's identity.
- **One line per task:** `Task N: in-progress (agent <id>, route <harness>/<model>/<effort>)`, `Task N: blocked (<why>)`, or `Task N: complete (commits <base7>..<head7>, review clean, route <harness>/<model>/<effort>, report <path>)`. The route is the resolved one from agent-routing, copied from the dispatch.
- **Active agents:** one line per live dispatch; remove it when that agent's final answer arrives.
- **Minor findings:** the running roll-up the final review triages, plus findings parked with rulings.
- **Exactly one `Next:` line** naming the next expected event (e.g. `Next: task 4 review verdict`).

When the final review is clean and its fixes are merged, delete this plan's workspace.

## Parallel Tracks

Active only when the plan **declares** a top-level `## Execution Tracks` section; the heading inside a code fence or prose is not a declaration. Otherwise this skill is serial.

**Wave execution.** Walk the track DAG:

1. When a fork's mainline prerequisites are complete and reviewed, create one sub-worktree per ready track from the current feature-branch head: `git worktree add <sdd-workspace>/tracks/<track-id> -b <feature-branch>--<track-id>`. Apply the project's worktree-policy setup rules. Record each track's base SHA in the ledger.
2. Dispatch every ready track's first implementer in one message. At most 3 tracks run concurrently; a lower worktree-policy limit governs. Start the largest track (by task count) first; the rest queue for free slots.
3. Inside a track the process is unchanged, with BASE/HEAD recorded per task on the track branch.
4. When a track's last task is reviewed clean, merge its branch into the feature branch with `--no-ff`, then remove the sub-worktree and branch. A textual conflict is a plan defect: stop, do not hand-resolve, and give your human partner the conflicting paths and the track declarations they contradict.
5. When every track at a fork has merged, dispatch the fork's integration task in the primary worktree as a normal task.

**Working directories.** Every track dispatch — implementer, fixer, reviewer — names the track worktree as its working directory, carried by the implementer template's `Work from:` line. Briefs, reports, review packages, and the ledger stay in the primary worktree's SDD workspace, reached by absolute path; recorded BASE/HEAD SHAs resolve from any worktree.

**Drift log.** Track implementer dispatches require a `## Decisions & drift risks` report section: assumptions about the frozen contract, gametime decisions, anything a sibling track might contradict. `None` is a valid entry. Carry one ledger line per non-empty entry, and paste all merged tracks' entries into the integration task's brief.

**Ledger.** One line per track: `Track B: in-progress (task 8/9, worktree <path>, base <sha7>)` → `Track B: merged (<sha7>, worktree removed)`. During a wave keep exactly one `Next:` line, aggregating pending events (e.g. `Next: wave — backend task 5 review; frontend task 8 report`).

**Failure semantics.** A BLOCKED track does not stop its siblings; a fork's integration task waits for every track at that fork. A `git worktree add` failure falls back to serial execution in the primary worktree for the affected tracks; report the downgrade. Surface a declaration-rule violation found at execution time like any plan defect.

## Prompt Templates

[implementer-prompt.md](implementer-prompt.md), [task-reviewer-prompt.md](task-reviewer-prompt.md), [re-review-prompt.md](re-review-prompt.md), [code-reviewer.md](../requesting-code-review/code-reviewer.md).

## Red Flags

**Never:**

- Start implementation on main/master without explicit user consent
- Dispatch multiple implementation subagents into the same worktree —
  concurrent implementers are only ever one-per-track-worktree, declared by
  the plan's Execution Tracks section
- Parallelize tracks the plan did not declare — opportunistic parallelism at
  execution time is forbidden, however independent two tasks look
- Skip the task review, or accept an implementer's own confidence in place of one — all review dispatch belongs to the orchestrator, and a self-arranged review does not count
- Fix findings yourself in the controller session instead of dispatching a fixer (context pollution, and controller fixes skip review)
- Re-dispatch a task the ledger already marks complete — check the ledger and `git log` after compaction or resume

## Integration

toolbelt:using-git-worktrees (isolated workspace first), toolbelt:writing-plans (creates the plan), toolbelt:requesting-code-review (final review template), toolbelt:finishing-a-development-branch (completes the branch), toolbelt:test-driven-development (subagents follow TDD).
