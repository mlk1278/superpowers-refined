# Toolbelt Workflow

New or ambiguous work uses `brainstorming` and `writing-plans`. Planning decides behavior and divides work into coherent delivery slices; each slice must fit one pull request. Delivery begins only when a decision-complete quick task or an approved implementation plan exists.

An approved plan may include `## Agent Routing` entries for the implementer, task reviewer, and final reviewer. Those routes override project routing, which overrides bundled defaults. The session agent remains the orchestrator and is never selected by the plan.

`delivery` loops over the plan's PR boundaries. Each boundary is one coherent delivery slice with its own worktree, routes, and subagent-driven development. New user flows, material interaction/layout/responsive changes, or an explicit request run the UX gate after task reviews and before SDD's broad final review, which is the slice gate. Branch completion creates one PR; the PR monitor owns CI, configured review, fixes, and merge. A boundary starts as soon as the previous PR opens. Dependent boundaries run as PR chains, each PR branched from and targeting its predecessor, with one pr-monitor per chain. Unpublished lanes rebase at task boundaries before their final review; once a PR opens only its monitor moves that branch. The project's issue tracker is reconciled only when the plan is linked to one, then the worktree, branch, and scratch are removed.

Between an implementer and reviewer, the controller passes the implementation report and review-package path without independently rereading the implementation or verification output. This preserves controller context and reviewer independence.

Normal continuation stays in the current agent session. After interruption, recover from the approved plan, Git history, branch and worktree state, SDD scratch, and current PR state. No separate resume state machine is required.

`quick-task` creates a one-task mini-plan for a small decision-complete change, then enters the same delivery path.
