# WorkStack Workflow

New or ambiguous work uses upstream `brainstorming` and `writing-plans`. Planning decides behavior and divides work into coherent delivery slices; each slice must fit one pull request. WorkStack begins only when a decision-complete quick task or an approved implementation plan exists.

An approved plan may include `## Agent Routing` entries for the implementer, task reviewer, and final reviewer. Those routes override project routing, which overrides bundled defaults. The session agent remains the orchestrator and is never selected by the plan.

`delivery` selects one coherent delivery slice, creates an isolated worktree, resolves routes, and runs upstream subagent-driven development. A materially user-visible slice runs the UX gate after task reviews and before SDD's broad final review. That broad review is the slice gate. Branch completion creates one PR; the PR monitor owns CI, configured review, fixes, merge, and confirmation. The monitor may run in the background while the orchestrator starts the next independent slice — one monitored PR at a time; its return is processed when it arrives, and in-flight lanes rebase onto the updated base before their final review. Linear is reconciled only when the plan is linked to it, then the worktree, branch, and scratch are removed.

Between an implementer and reviewer, the controller passes the implementation report and review-package path without independently rereading the implementation or verification output. This preserves controller context and reviewer independence while leaving detailed verification with the agents assigned to it.

Normal continuation stays in the current agent session. After interruption, recover from the approved plan, Git history, branch and worktree state, SDD scratch, and current PR state. No separate resume state machine is required.

`quick-task` creates a one-task mini-plan for a small decision-complete change, then enters the same delivery path.
