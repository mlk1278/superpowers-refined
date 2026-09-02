---
name: delivery
description: Use when an approved implementation plan is ready to be implemented and shipped.
---

# Delivery

**Announce:** "I'm using delivery to deliver this approved plan."

**Entry:** an approved implementation plan.
**Exit:** every PR boundary merged, reconciled when applicable, and cleaned up.

## 1. Read and loop

Read the plan. Do not redesign approved requirements. Return any unresolved product decision to your human partner.

Loop over the plan's `## PR Boundaries` table in order, running steps 2–5 for each.

Each boundary is one coherent delivery slice. A slice is bounded by the number of independent judgements a reviewer must make, not by lines changed. Two slices you would run concurrently and that edit the same files are one PR. Sequential slices may revisit the same file once the first has merged.

## 2. Resolve routes

Read the optional `## Agent Routing` section. It may route the implementer, task reviewer, and final reviewer. The session agent remains the orchestrator and is never plan-routed. Resolve each role with agent-routing. Precedence is plan route, then project route, then bundled default. Resolve the monitor from project routing or the bundled default. Resolve an `errand` gate operator the same way for a UX-gated boundary. Fail closed when either reviewer lacks an independent route. The only exception is agent-routing's provider-outage emergency override.

## Role ownership

Task briefs, gate bundles, and dispatch prompts must not reassign these roles.

| Work | Owner |
|---|---|
| Implementation, tests, commits, task report | Implementer subagent (fresh per task) |
| Task briefs, review packages, dispatch context, verdict handling | Orchestrator (session agent) — dispatch and synthesis only; never implements or captures. Reads fix-report tables to close a fix round (SDD orchestrator close); never re-reads test output beyond that table |
| UX capture (scripted Playwright screenshots) | A gate operator (role `errand`) the orchestrator dispatches to run ux-gate — never the orchestrator itself, never the implementer |
| UX judgment | Vision-capable reviewer routed with specialty `ux` |
| Task reviews and the broad final review | Reviewer subagents routed via agent-routing |
| PR publication | finishing-a-development-branch (step 5, declared completion route) |
| GitHub review, exact-head CI, fix loops, rebases and retargets of published branches, merge, for one PR chain | pr-monitor |
| Issue-tracker reconciliation and cleanup | This skill, after the monitor returns |

## 3. Prepare and execute

A dependent boundary is one whose `Depends on` names a boundary whose PR is open and unmerged. Fetch the predecessor's remote head. Name that SHA as the worktree's source ref. An independent boundary branches from the base branch.

Then create the worktree with toolbelt:using-git-worktrees and apply the repository's worktree rules. Branch names are `<plan-slug>/pr-<N>`, where `<plan-slug>` is the plan file's basename without date and extension and `<N>` is the boundary number.

Execute the boundary with toolbelt:subagent-driven-development, supplying the resolved routes. Keep its task briefs, reports, review packages, reviews, and fix loops unchanged.

## 4. Gate the boundary

When the boundary materially changes a user-visible surface, supply ux-gate as SDD's optional pre-final gate. It runs after task reviews.

That broad final review is the slice gate; do not add another whole-slice review.

## 5. Ship

After approval, invoke toolbelt:finishing-a-development-branch with the pull-request completion route and target base branch declared. A dependent boundary's PR targets the predecessor's branch; an independent boundary's targets the base branch. This is a manual PR chain and does not depend on GitHub's native stack feature.

Record one line per boundary in the SDD ledger: `Boundary <N>: branch <name>, PR #<num>, base <branch>, state <open|merged|blocked>`.

Once the boundary's broad final review is clean and its PR is open, start the next boundary immediately. Any number of boundaries may be open.

Each chain has exactly one pr-monitor. Start it when its bottom PR opens. Always run it in the background. When a dependent boundary's PR opens, resume that chain's monitor with the new layer's number, branch, and head. An independent boundary starts its own chain.

Process each monitor's return when it arrives — merged: run step 6; blocked: surface it to your human partner. Never report the slice complete or end the session while the monitor runs. A completion notification is not that return. Background agents notify whenever they momentarily hold no live children. Read merge state from the monitor's return and the PR.

A monitor that looks dead is not grounds to start a second one. Before re-dispatching any agent that owns external state, check that state directly. Agents owning only local work re-dispatch as-is.

A chain whose bottom PR closed without merging returns `CLOSED` plus a durable blocker for every layer above. Surface it to your human partner and open no further boundaries in that chain.

## Who rebases

Ownership follows publication. Delivery owns a boundary's branch until its PR opens. When a lower PR's branch moves, delivery rebases the unpublished branch at its next task boundary — always before that lane's broad final review — and appends `Boundary <N>: rebased <old7> → <new7>` to the ledger. Once the PR is open, only the monitor moves the branch. Implementers and fixers never rebase.

## 6. Reconcile and clean up

Run once per boundary, when the monitor returns that layer merged. Reconcile the issue tracker only when the plan is linked to one. Confirm the remote PR state the monitor returned — never commit ancestry — then remove the worktree, branch, and ignored scratch.

Normal continuation stays in the current session. After an interruption, recover from the approved plan, git history, branch and worktree state, SDD scratch, and current PR state — do not create separate resume bookkeeping.
