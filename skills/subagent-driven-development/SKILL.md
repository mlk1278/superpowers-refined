---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Why subagents:** you delegate to agents with isolated context. They never inherit your session's history — you construct exactly what each one needs, which keeps them focused and preserves your context for coordination.

**Narration:** between tool calls, narrate at most one short line — the ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

## The Process

1. Read the plan once. Note context and global constraints; create todos and a progress ledger.
2. Pre-flight scan (below), then per task:
   - Record BASE (current head) and dispatch the implementer with its task brief.
   - Answer any questions it asks before it proceeds.
   - On DONE, build the review package and dispatch the task reviewer.
   - Dispatch a fix subagent for Critical/Important findings, then re-review. Repeat until spec ✅ and quality approved.
   - Mark the task complete in the todo list and the ledger.
3. After all tasks: dispatch the final whole-branch reviewer ([code-reviewer.md](../requesting-code-review/code-reviewer.md)).
4. Hand off to toolbelt:finishing-a-development-branch.

**Optional pre-final gate:** If the caller supplies a pre-final gate, run it after all task reviews and before the broad final review. Otherwise, follow the normal path unchanged. When the caller defines a role-ownership table (e.g. delivery's), it governs who runs each gate and who captures its evidence — task briefs must not reassign those roles.

## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for tasks that contradict each other or the Global Constraints, and for anything the plan mandates that the review rubric treats as a defect (a test that asserts nothing, verbatim duplication of a logic block).

Present everything you find as one batched question — each finding beside the plan text that mandates it, asking which governs — before execution begins, not one interrupt per discovery mid-plan. If the scan is clean, proceed without comment.

## Model Selection

**Caller routing takes precedence:** plan route, then project route, then your own judgment. A routed role bypasses selection for that role; the session agent remains the orchestrator.

Absent a route, use the least powerful model that can handle the role, with these floors: **turn count beats token price** — the cheapest models routinely take 2-3× the turns on multi-step work and cost more overall. Mid-tier is the floor for reviewers and for implementers working from prose. Cheapest tier is right when the plan text contains the complete code to write (transcription plus testing) or for single-file mechanical fixes. The final whole-branch review gets the most capable model available.

**Always specify the model explicitly when dispatching.** An omitted model inherits your session's model — often the most capable and most expensive — which silently defeats this section.

## Handling Implementer Status

**A progress message is not completion.** Only the subagent's final answer — the one carrying the Status token — is its report. If your harness's wait returns an intermediate message, or the wait is interrupted by an unrelated event (such as a new user message), the agent is still running: resume waiting on the same agent. Never treat an interrupted or intermediate message as failure, and never act on a status the agent has not yet reported.

- **DONE:** run `scripts/review-package BASE HEAD` (from this skill's directory — it prints the path it wrote) and dispatch the task reviewer with that path. BASE is the commit you recorded before dispatching — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task.
- **DONE_WITH_CONCERNS:** read the concerns first. Correctness or scope concerns get addressed before review; observations ("this file is getting large") get noted and you proceed.
- **NEEDS_CONTEXT:** provide what was missing and re-dispatch.
- **BLOCKED:** diagnose before retrying — more context and the same model, a more capable model, a smaller task, or escalation to the human if the plan itself is wrong. **Never** ignore an escalation or force the same model to retry unchanged. If the implementer said it's stuck, something has to change.

**Reviewer ⚠️ items:** the task reviewer reports "⚠️ Cannot verify from diff" for requirements living in unchanged code or spanning tasks. These don't block the rest of the review, but you resolve each one yourself before marking the task complete — you hold the cross-task context the reviewer lacks. A confirmed gap is a failed spec review: send it back and re-review.

## Verification Scope

Verification is proportional to the change. Before any suite-level run, ask: what did the diff touch, and what is the smallest command that proves it?

- **Iterating:** focused tests for the code being changed.
- **Task gate:** the affected package suite(s) once — the packages the diff touches plus direct consumers of a changed shared contract. High-risk changes (auth, tenancy, migrations, shared schemas, backend authority, cross-package behavior) add targeted cross-package checks, not a workspace run.
- **Fix rounds:** covering tests only.
- **Workspace-wide suite:** once, at the final gate. toolbelt:finishing-a-development-branch Step 1 owns its evidence, reuse, and docs-only cases. Task gates never run it, and nobody reruns it because a PR opened — exact-head CI owns suite-level regression after push.

Do not repeat recorded verification. Reviewers and orchestrators read the implementer's test evidence on unchanged source instead of re-running it; a fresh worktree needs only the smallest checks proving a clean start, never a workspace baseline over an unchanged tree. Implementers and fixers always produce their own fresh evidence for the change they ship.

Keep suite output out of context: run through the project's quiet-run wrapper when it provides one and read back exit status, pass count, and failure tail only.

A plan or brief mandating broader verification than this policy is a conflict to surface to your human partner — do not silently obey or silently override it.

## Constructing Reviewer Prompts

Per-task reviews are task-scoped gates; the broad review happens once, at the end.

- **Don't pre-judge findings.** Never instruct a reviewer to ignore or not flag an issue. If you think a finding would be a false positive, let the reviewer raise it and adjudicate in the loop. If your prompt contains "do not flag," "don't treat X as a defect," "at most Minor," or "the plan chose" — stop: you are pre-judging, usually to spare yourself a review loop.
- **Don't add open-ended directives** ("check all uses", "run race tests if useful") without a concrete, task-specific reason, and don't ask a reviewer to re-run tests the implementer already ran on the same code.
- **The global-constraints block is the reviewer's attention lens.** Copy binding requirements verbatim from the plan's Global Constraints or the spec: exact values, exact formats, stated relationships between components ("same layout as X", "matches Y"). The template already carries the process rules — this block is for what THIS project's spec demands.
- **`[REVIEW_NUANCE]`** takes concise task-specific context and concrete risks. It may direct attention but must not override requirements, suppress findings, or pre-judge severity. Use `None` when there is none.
- **`docs/REVIEW-GUIDANCE.md` is reviewer-only.** Do not read it while orchestrating or pass it to implementers, fixers, explorers, planners, operators, or monitors. Reviewer templates tell the reviewer to read it when it exists.
- **A dispatch prompt describes one task, not the session's history.** Do not paste accumulated prior-task summaries ("state after Tasks 1-3") into later dispatches — a real session's dispatch hit 42k chars of which 99% was pasted history. A fresh subagent needs its task, the interfaces it touches, and the global constraints. Nothing else.
- **Findings that conflict with the plan are the human's decision.** Present the finding and the plan text and ask which governs. Do not dismiss a finding because the plan mandates it, and do not dispatch a fix that contradicts the plan without asking.
- **Fix dispatches carry the implementer contract:** the fixer re-runs the tests covering its change and reports results. Name the covering test files — a one-line fix does not need the whole suite. Before re-dispatching the reviewer, confirm the fix report contains the covering tests, the command, and the output.
- **Minor findings go in the ledger,** and you point the final review at that list so it can triage what must be fixed before merge. A roll-up nobody reads is a silent discard.
- **Final-review findings get ONE fix subagent** with the complete list — not one fixer per finding. Per-finding fixers each rebuild context and re-run suites; a real session's final-review fix wave cost more than all its tasks combined. Resume the same reviewer thread with a `review-package` for the fix delta, and repeat until approved.

## File Handoffs

Everything you paste into a dispatch prompt — and everything a subagent prints back — stays resident in your context for the rest of the session and is re-read on every later turn. Hand artifacts over as files.

- **Task brief:** run `scripts/task-brief PLAN_FILE N` before dispatching an implementer; it writes the task's full text to a uniquely named file and prints the path. The dispatch itself contains: (1) one line on where this task fits; (2) the brief path, introduced as "read this first — it is your requirements, with the exact values to use verbatim"; (3) interfaces and decisions from earlier tasks the brief cannot know; (4) your resolution of any ambiguity you spotted; (5) the report-file path and report contract. Exact values — numbers, magic strings, signatures, test cases — appear **only** in the brief.
- **Report file:** name it after the brief (`…/task-N-brief.md` → `…/task-N-report.md`). The implementer writes its full report there and returns only status, commits, a one-line test summary, and concerns.
- **Reviewer inputs:** three paths — the brief, the report, the review package — plus the global constraints binding the task.
- **Review package:** `scripts/review-package BASE HEAD` for tasks, `scripts/review-package MERGE_BASE HEAD` for the final review (MERGE_BASE = `git merge-base main HEAD`). Pass the printed path as the reviewer's `[DIFF_FILE]` — both the task-reviewer and code-reviewer templates take one. The output never enters your context; the reviewer gets commit list, stat summary, and full diff in one Read.
- Fix dispatches append their fix report (with test results) to the same report file and return a short summary; re-reviews read the updated file.

## Durable Progress

Conversation memory does not survive compaction. In real sessions, controllers that lost their place have re-dispatched entire completed task sequences — the single most expensive failure observed. Track progress in a ledger file, not only in todos.

At skill start, check for one: `cat "$(git rev-parse --show-toplevel)/.toolbelt/sdd/progress.md"`. Tasks marked complete there are DONE — do not re-dispatch them; resume at the first task not marked complete.

Keep the ledger in this shape, updating it in the same message as your other bookkeeping:

- **Header:** branch, plan path, and the current exact head SHA (update the SHA whenever you append).
- **One line per task:** complete — `Task N: complete (commits <base7>..<head7>, review clean, report <path>)`; otherwise `Task N: in-progress (agent <id>)` or `Task N: blocked (<why>)`, with no commit/review fields until they exist.
- **Active agents:** one line per live dispatch (id or handle, scope); remove it when that agent's final answer arrives.
- **Minor findings:** the running roll-up the final review triages.
- **Exactly one `Next:` line** naming the single next expected event (e.g. `Next: task 4 review verdict`).

After compaction, trust the ledger and `git log` over your own recollection — the commits it names exist in git even when your context no longer remembers creating them. `git clean -fdx` destroys the ledger (it's git-ignored scratch); recover from `git log` if that happens.

## Prompt Templates

- [implementer-prompt.md](implementer-prompt.md) — implementer subagent
- [task-reviewer-prompt.md](task-reviewer-prompt.md) — task reviewer (spec compliance + code quality)
- [code-reviewer.md](../requesting-code-review/code-reviewer.md) — final whole-branch review

## Red Flags

**Never:**

- Start implementation on main/master without explicit user consent
- Skip task review, or accept a report missing either verdict — spec compliance AND task quality are both required
- Move to the next task while the review has open Critical/Important issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Let an implementer, fixer, or reviewer dispatch its own review or re-review — all review dispatch belongs to the orchestrator, and a self-arranged review does not count as the task review
- Skip the task review because the implementer reported its own work as clean — an implementer's confidence is not a review
- Make a subagent read the whole plan file — hand it its task brief instead
- Dispatch a task reviewer without a diff file — generate it first and name the printed path
- Tell a reviewer what not to flag, or pre-rate a finding's severity ("treat it as Minor at most") — the plan's example code is a starting point, not evidence that its weaknesses were chosen
- Accept "close enough" on spec compliance — the reviewer found spec issues means not done
- Skip scene-setting context, or push a subagent past its questions
- Fix a failed task yourself instead of dispatching a fixer (context pollution)
- Re-dispatch a task the ledger already marks complete — check the ledger and `git log` after any compaction or resume

## Integration

- **toolbelt:using-git-worktrees** — isolated workspace, before you start
- **toolbelt:writing-plans** — creates the plan this skill executes
- **toolbelt:requesting-code-review** — template for the final whole-branch review
- **toolbelt:finishing-a-development-branch** — completes the branch after all tasks
- **toolbelt:test-driven-development** — subagents follow TDD per task
