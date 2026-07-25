# WorkStack Simplification Design

**Status:** Approved in conversation on 2026-07-20. **Historical — superseded.**

Kept verbatim as the record of the design this framework came out of. It predates
the rename to Toolbelt and uses the vocabulary of that time: "upstream Superpowers"
for the inherited skills, "WorkStack" for the delivery layer on top, and
`workstack-`-prefixed skill names that no longer exist. The prefix is gone and the
two layers are one framework. `docs/WORKFLOW.md` describes the current design; read
that instead unless you want the reasoning behind it.

## Goal

Keep upstream Superpowers as the implementation inner loop and reduce WorkStack to the project-specific delivery behavior that upstream does not provide.

## Decisions

1. Restore upstream `brainstorming`, `writing-plans`, and task-brief extraction. WorkStack does not alter their handoffs or prepend a plan-wide constraints block to every task.
2. Preserve upstream subagent-driven development, including file-based task briefs, reports, and `review-package` diff bundles.
3. Retain only surgical SDD additions:
   - reviewers may read `docs/REVIEW-GUIDANCE.md` and receive concise review nuance;
   - caller-supplied agent routes override normal model selection;
   - an optional caller-supplied UX gate runs after task reviews and before the broad final review;
   - final-review fixes are verified and returned to the same reviewer as a delta bundle.
4. Keep the declared-route behavior in `finishing-a-development-branch`.
5. Keep `workstack-agent-routing`, `workstack-quick-task`, `workstack-ux-gate`, and `workstack-pr-monitor`.
6. Replace `workstack-start`, `workstack-resume`, `workstack-spec-review`, and `workstack-slice-gate` with one thin `workstack-delivery` entry point and one concise workflow document.
7. Use upstream brainstorming and writing-plans normally. After a plan is approved, `workstack-delivery` owns worktree setup, SDD, optional UX review, one PR, monitoring, merge, Linear reconciliation when applicable, and cleanup.
8. A plan may optionally name implementer, task reviewer, and final reviewer routes. Plan routes override project routing, which overrides bundled defaults. The session agent remains the orchestrator and is never selected by the plan.
9. Keep reviewer independence as the default validation.
10. Keep the controller-context rule in WorkStack project guidance: between implementer and reviewer, pass the report and bundle without independently rereading the implementation or verification output.

## Public entry points

- `workstack-quick-task` for one small, decision-complete change.
- `workstack-delivery` for an approved implementation plan.

New or ambiguous work uses upstream `brainstorming` followed by upstream `writing-plans`; it does not need a WorkStack wrapper.

## Major delivery sequence

1. Read the approved plan and optional agent-routing section.
2. Select one coherent delivery slice and create an isolated worktree.
3. Resolve implementer, task-reviewer, final-reviewer, and monitor routes.
4. Execute the slice with upstream subagent-driven development and its file handoffs.
5. Run the UX gate before the broad final review when the slice materially changes a user-visible surface.
6. Treat SDD's broad final review as the slice review; do not add a second slice-gate skill.
7. Complete one pull request, monitor it through CI and configured review, merge, reconcile Linear when applicable, and clean up.

## Recovery

Normal continuation uses the current agent session. After interruption, recover from the implementation plan, Git history, current branch/worktree, SDD progress ledger, and PR state. No separate resume state machine is required.

## Non-goals

- Replacing upstream brainstorming, planning, TDD, implementation, task review, final review, or branch completion.
- Requiring Linear tickets or a durable living plan for small changes.
- Adding an orchestrator model to plan routing.
- Requiring exact-head ledger bookkeeping when a current review package and delta re-review establish what was reviewed.
