# Toolbelt Workflow Summary

Canonical two-paragraph workflow explanation for a consuming project's `AGENTS.md`. If a new capability cannot fit here or needs a third entry point, redesign the capability, not this summary.

New or ambiguous work uses `brainstorming` and `writing-plans`. Delivery starts from either a small decision-complete request or an approved implementation plan; tracker reconciliation is optional and happens only when the plan is linked to it.

Delivery selects one coherent slice, runs upstream subagent-driven development in an isolated worktree, optionally gates material user-visible changes, uses SDD's broad final review as the slice gate, and owns one PR through merge and cleanup.

Two public entry points:

- `quick-task`: a small decision-complete change, straight to one reviewed, merged PR.
- `delivery`: an approved implementation plan, through one coherent slice to a reviewed, merged PR and cleanup.
