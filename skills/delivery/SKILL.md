---
name: delivery
description: Use when an approved implementation plan is ready to be implemented and shipped.
---

# Delivery

**Announce:** "I'm using delivery to deliver this approved plan."

**Entry:** an approved implementation plan.
**Exit:** one coherent delivery slice merged, reconciled when applicable, and cleaned up.

## 1. Read and select

Read the plan and select one coherent delivery slice that can ship in one PR. Do not redesign approved requirements. If the plan leaves a product decision unresolved, stop and return it to your human partner.

## 2. Resolve routes

Read the optional `## Agent Routing` section. It may name routes for the implementer, task reviewer, and final reviewer; the session agent remains the orchestrator and is never plan-routed. Resolve each role with agent-routing. Precedence is plan route, then project route, then bundled default. Resolve the monitor from project routing or the bundled default. When the slice will run the UX gate, also resolve an `errand` route for the gate operator. Fail closed when either reviewer lacks an independent route; the sole exception is agent-routing's provider-outage emergency override, which triggers only on recorded dispatch-time provider failures, never on a routing error.

## Role ownership

This table is authoritative for who does what across the slice. Task briefs, gate bundles, and dispatch prompts must not reassign these roles.

| Work | Owner |
|---|---|
| Implementation, tests, commits, task report | Implementer subagent (fresh per task) |
| Task briefs, review packages, dispatch context, verdict handling | Orchestrator (session agent) — dispatch and synthesis only; never implements, captures, or re-reads verification output |
| UX capture (scripted Playwright screenshots) | A gate operator (role `errand`, resolved in step 2) the orchestrator dispatches to run ux-gate — scripted only; never the orchestrator itself, never the implementer |
| UX judgment | Vision-capable reviewer routed with specialty `ux` |
| Task reviews and the broad final review | Reviewer subagents routed via agent-routing |
| PR publication | finishing-a-development-branch (step 5, declared completion route) |
| GitHub review, exact-head CI, fix loops, merge | pr-monitor |
| Issue-tracker reconciliation and cleanup | This skill, after the monitor returns |

## 3. Prepare and execute

Create an isolated worktree with toolbelt:using-git-worktrees and apply the repository's worktree rules. Execute the slice with toolbelt:subagent-driven-development, supplying the resolved routes. Keep its task briefs, implementation reports, review packages, task reviews, and fix loops unchanged.

## 4. Gate the slice

When the slice materially changes a user-visible surface, supply ux-gate as SDD's optional pre-final gate. It runs after task reviews and before SDD's broad final review. Dispatch the gate operator on the `errand` route resolved in step 2 to run the gate skill — the orchestrator supplies the context bundle and receives the verdict, but never runs capture itself.

That broad final review is the slice gate; do not add another whole-slice review.

## 5. Ship

After approval, invoke toolbelt:finishing-a-development-branch with the pull-request completion route and target base branch declared. Hand the resulting PR to pr-monitor.

Either wait for the monitor's return, or run it in the background and begin the next task while it monitors — only when all of these hold:

- The next work is independent: it does not build on the in-flight PR's changes and touches no surface its active contract reserves. Dependent work waits for the merge — no stacked branches.
- At most one PR is in background monitoring; do not open another PR until this one resolves (merged or durably blocked).
- The monitor stays tracked. Process its return when it arrives — merged: run step 6 for that slice; blocked: surface it to your human partner. Never report the slice complete or end the session while the monitor runs.

The next task starts in its own worktree branched from the current base branch, under the repository's worktree rules (including port isolation). When the monitored PR merges, rebase in-flight lane(s) onto the updated base branch at the next task boundary — always before that lane's broad final review.

## 6. Reconcile and clean up

Reconcile the issue tracker only when the plan is linked to one. After merge, confirm the remote state, then remove the worktree, branch, and ignored scratch.

Normal continuation stays in the current session. After an interruption, recover from the approved plan, git history, branch and worktree state, SDD scratch, and current PR state — do not create separate resume bookkeeping.
