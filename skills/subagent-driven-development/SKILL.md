---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Continuous execution:** Do not pause to check in with your human partner between tasks unless given a BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete.

## The Process

1. Read the plan once. Note context and global constraints; create todos and a progress ledger.
2. Pre-flight scan (below), then per task:
   - Record BASE (current head) and dispatch the implementer with its task brief.
   - Answer any questions it asks before it proceeds.
   - On DONE, build the review package and dispatch the task reviewer.
   - Run the fix loop; adjudicate anything its re-review leaves open.
   - Mark the task complete in the todo list and the ledger.
3. After all tasks: dispatch the final whole-branch reviewer ([code-reviewer.md](../requesting-code-review/code-reviewer.md)). It runs before the branch is published — a reviewer that sees only the diff and the spec reads commits a PR reviewer asked for as scope creep. If one must run after PR review rounds have landed commits, its brief carries those accepted findings.
4. Hand off to toolbelt:finishing-a-development-branch.

**Optional pre-final gate:** If the caller supplies a pre-final gate, run it after all task reviews and before the broad final review. Otherwise, follow the normal path unchanged. When the caller defines a role-ownership table (e.g. delivery's), it governs who runs each gate and who captures its evidence — task briefs must not reassign those roles.

## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for tasks that contradict each other or the Global Constraints, and for anything the plan mandates that the review rubric treats as a defect. Present everything you find as one batched question — each finding beside the plan text that mandates it, asking which governs — before execution begins. If the scan is clean, proceed without comment.

## Model Selection

**Caller routing takes precedence:** plan route, then project route, then the session routing brief. A routed role bypasses selection for that role; the session agent remains the orchestrator.

Every role you dispatch comes from the brief — implementer, reviewer, explorer, errand. If no route resolves, stop and tell your human partner; do not substitute your own judgment for a missing route. The brief's routes already encode the model floors that matter; the final whole-branch review gets the most capable route offered.

**Always specify the model explicitly when dispatching** — an omitted model silently inherits your session's model.

## Handling Implementer Status

**A progress message is not completion.** Only the subagent's final answer — the one carrying the Status token — is its report. If your harness's wait returns an intermediate message, or the wait is interrupted by an unrelated event, the agent is still running: resume waiting on the same agent.

- **DONE:** run `scripts/review-package --plan PLAN_FILE BASE HEAD` (from this skill's directory — it prints the path it wrote) and dispatch the task reviewer with that path. BASE is the commit you recorded before dispatching — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task.
- **DONE_WITH_CONCERNS:** read the concerns first. Correctness or scope concerns get addressed before review; observations get noted and you proceed.
- **NEEDS_CONTEXT:** provide what was missing and re-dispatch.
- **BLOCKED:** something has to change before any retry — more context, a more capable routed model, a smaller task, or escalation to the human if the plan itself is wrong.

**Reviewer ⚠️ items:** the task reviewer reports "⚠️ Cannot verify from diff" for requirements living in unchanged code or spanning tasks. These don't block the rest of the review, but you resolve each one yourself before marking the task complete — you hold the cross-task context the reviewer lacks. A confirmed gap is a failed spec review: it enters the fix loop with the other findings.

## The Fix Loop

The loop triggers on spec ❌, any Critical or Important finding, or a ⚠️ item you confirmed as a real gap. Two routes leave it before it starts:

- **Minor findings** go to the ledger's roll-up and never enter the loop.
- **Plan-mandated findings** — anything conflicting with what the plan's text requires — are the human's decision. Present the finding beside the plan text and ask which governs.

**One fix round per task.** Resume the original implementer with the open findings verbatim — its context is intact: it knows the task, the code, and its own choices. If your harness cannot message a live subagent, dispatch a fresh implementer with the brief path, the report-file path, and the findings; the report file is the persistent memory either way.

The round ends with a scoped re-review ([re-review-prompt.md](re-review-prompt.md)) over the fix delta only: `scripts/review-package --plan PLAN_FILE FIX_BASE HEAD`, where FIX_BASE is the head the previous review saw. The re-reviewer verdicts each finding ADDRESSED or NOT ADDRESSED and flags new breakage **in the fix diff only**. New Critical/Important breakage there joins the open findings; out-of-scope observations go to the ledger as deferred minors and never extend the loop. Append to the ledger: `Task <N>: fix round (<X> addressed, <Y> open — <one-liners>; commits <a7>..<b7>)`.

**Adjudication.** A finding that survives an honest fix round is usually a judgment call, not a failed implementer. Adjudicate each finding still open yourself — you hold the plan and cross-task context the reviewer lacks:

- **Reviewer is wrong, or the point is contestable** — park it: `Task <N>: parked — <finding> — ruling: <why the code stands>`. The final review sees both sides.
- **Real, but nothing downstream builds on it** — park it the same way, with a ruling saying it's real and deferred.
- **Real and load-bearing** — a later task builds on it, or it reveals a plan defect: **STOP.** Append `Task <N>: BLOCKED — <reason>` and report to your human partner with the finding, the plan text it collides with, and the fix history.

Adjudicate **only** after the re-review — adjudicating instead of running the fix round is pre-judging with a different name. Every adjudication is a ledger entry; a silent discard is forbidden.

Never fix findings yourself in the controller session — your context stays clean for coordination, and controller fixes skip review.

## Verification Scope

Verification is proportional to the change. Before any suite-level run, ask: what did the diff touch, and what is the smallest command that proves it?

- **Iterating:** focused tests for the code being changed.
- **Task gate:** the affected package suite(s) once — the packages the diff touches plus direct consumers of a changed shared contract. High-risk changes (auth, tenancy, migrations, shared schemas, cross-package behavior) add targeted cross-package checks, not a workspace run.
- **Fix rounds:** covering tests only.
- **Workspace-wide suite:** once, at the final gate. toolbelt:finishing-a-development-branch Step 1 owns its evidence, reuse, and docs-only cases. Task gates never run it, and nobody reruns it because a PR opened — exact-head CI owns suite-level regression after push.

Do not repeat recorded verification. Reviewers and orchestrators read the implementer's test evidence on unchanged source instead of re-running it. Implementers and fixers always produce their own fresh evidence for the change they ship.

Keep suite output out of context: run through the project's quiet-run wrapper when it provides one and read back exit status, pass count, and failure tail only. A buffered wrapper releases nothing until the command exits, so it never carries a check that gates that command — a gate is a separate command, run to completion first.

A plan or brief mandating broader verification than this policy is a conflict to surface to your human partner — do not silently obey or silently override it.

## Constructing Reviewer Prompts

Per-task reviews are task-scoped gates; the broad review happens once, at the end.

- **Don't pre-judge findings.** Never tell a reviewer what not to flag or pre-rate a finding's severity — let it raise the finding and settle it in the fix loop or at adjudication.
- **The global-constraints block is the reviewer's attention lens.** Copy binding requirements verbatim from the plan's Global Constraints or the spec: exact values, exact formats, stated relationships between components.
- **`[REVIEW_NUANCE]`** takes concise task-specific context and concrete risks. It may direct attention but must not override requirements, suppress findings, or pre-judge severity. Use `None` when there is none.
- **`docs/REVIEW-GUIDANCE.md` is reviewer-only.** Do not read it while orchestrating or pass it to implementers, fixers, explorers, planners, errands, or monitors. Reviewer templates tell the reviewer to read it when it exists.
- **A dispatch prompt describes one task, not the session's history.** Do not paste accumulated prior-task summaries into later dispatches.
- **Findings that conflict with the plan are the human's decision.** Present the finding and the plan text and ask which governs.
- **Fix dispatches carry the implementer contract:** the fixer re-runs the tests covering its change and reports results. Before re-dispatching the reviewer, confirm the fix report contains the covering tests, the command, and the output.
- **Minor findings go in the ledger,** and you point the final review at that list so it can triage what must be fixed before merge.
- **Final-review findings get ONE fix subagent** with the complete list — not one fixer per finding. Then run exactly one scoped re-review of the fix wave and adjudicate any residual findings as at the task loop. There is no second fix wave — residual load-bearing findings surface to your human partner when finishing-a-development-branch presents the options.

## File Handoffs

Everything you paste into a dispatch prompt — and everything a subagent prints back — stays resident in your context for the rest of the session. Hand artifacts over as files.

- **Task brief:** run `scripts/task-brief PLAN_FILE N` before dispatching an implementer; it writes the task's full text to a file and prints the path. The dispatch itself contains: (1) one line on where this task fits; (2) the brief path, introduced as "read this first — it is your requirements, with the exact values to use verbatim"; (3) interfaces and decisions from earlier tasks the brief cannot know, plus the plan's Global Constraints and Known Gotchas; (4) your resolution of any ambiguity you spotted; (5) the report-file path and report contract. Exact values — numbers, magic strings, signatures, test cases — appear **only** in the brief.
- **Report file:** name it after the brief (`…/task-N-brief.md` → `…/task-N-report.md`). The implementer writes its full report there and returns only status, commits, a one-line test summary, and concerns.
- **Reviewer inputs:** three paths — the brief, the report, the review package — plus the global constraints binding the task.
- **Review package:** `scripts/review-package --plan PLAN_FILE BASE HEAD` for tasks, `scripts/review-package --plan PLAN_FILE MERGE_BASE HEAD` for the final review (MERGE_BASE = `git merge-base main HEAD`). Pass the printed path as the reviewer's `[DIFF_FILE]`; the output never enters your context.
- Fix dispatches append their fix report (with test results) to the same report file and return a short summary; re-reviews read the updated file.

## Durable Progress

Conversation memory does not survive compaction; a controller that loses its place re-dispatches completed work. Track progress in a ledger file, not only in todos.

**Each plan owns a workspace.** At skill start run `scripts/sdd-workspace PLAN_FILE`; it prints this plan's git-ignored directory (`<repo-root>/.toolbelt/sdd/<plan-basename>-<digest>/`), home to every artifact for THIS plan — ledger, briefs, reports, review packages. Another plan's directory is never yours to read or write.

Check for this plan's ledger at `<workspace>/progress.md`. Tasks marked complete there are DONE — do not re-dispatch them; resume at the first task not marked complete. A ledger whose header names a different plan file is another plan's progress: leave it in place and start your own, fresh.

Keep the ledger in this shape, updating it in the same message as your other bookkeeping:

- **Header:** branch, plan path, and the current exact head SHA. The plan path is the ledger's identity.
- **One line per task:** complete — `Task N: complete (commits <base7>..<head7>, review clean, report <path>)`; otherwise `Task N: in-progress (agent <id>)` or `Task N: blocked (<why>)`.
- **Active agents:** one line per live dispatch; remove it when that agent's final answer arrives.
- **Minor findings:** the running roll-up the final review triages, plus findings parked with rulings.
- **Exactly one `Next:` line** naming the single next expected event (e.g. `Next: task 4 review verdict`).

After compaction, trust the ledger and `git log` over your own recollection — the commits it names exist in git even when your context no longer remembers creating them. When the final whole-branch review is clean and its fixes are merged, delete this plan's workspace — git history is the record now.

## Prompt Templates

- [implementer-prompt.md](implementer-prompt.md) — implementer subagent
- [task-reviewer-prompt.md](task-reviewer-prompt.md) — task reviewer (spec compliance + code quality)
- [re-review-prompt.md](re-review-prompt.md) — scoped re-review after the fix round
- [code-reviewer.md](../requesting-code-review/code-reviewer.md) — final whole-branch review

## Red Flags

**Never:**

- Start implementation on main/master without explicit user consent
- Dispatch multiple implementation subagents in parallel (conflicts)
- Skip the task review, or accept an implementer's own confidence in place of one — all review dispatch belongs to the orchestrator, and a self-arranged review does not count
- Fix findings yourself in the controller session instead of dispatching a fixer (context pollution, and controller fixes skip review)
- Re-dispatch a task the ledger already marks complete — check the ledger and `git log` after compaction or resume

## Integration

- **toolbelt:using-git-worktrees** — isolated workspace, before you start
- **toolbelt:writing-plans** — creates the plan this skill executes
- **toolbelt:requesting-code-review** — template for the final whole-branch review
- **toolbelt:finishing-a-development-branch** — completes the branch after all tasks
- **toolbelt:test-driven-development** — subagents follow TDD per task
