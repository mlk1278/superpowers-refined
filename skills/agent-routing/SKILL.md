---
name: agent-routing
description: Use when a delivery entry point must resolve a logical implementation, review, or monitoring role before dispatch.
---

# Agent Routing

Callers request logical roles; they never select concrete agents themselves.

## Resolve a route

Run `scripts/resolve-agent --project-root <root> --role <role>` before dispatch. Add `--harness`, `--workflow`, `--reviewer-specialty`, or explicit `--override-*` arguments only when the caller has that context. Always pass `--author-model` for a reviewer.

Record the normalized JSON result in the work log before dispatch. Dispatch the returned primary route and retain `fallbacks` in their returned order. Do not reconstruct or guess a route when resolution fails. In particular, fail closed on reviewer-independence errors.

## Provider-outage emergency override

Reviewer independence has exactly one documented exception. The trigger is **dispatch-time provider failure, never a resolver error**: resolution succeeded (an independent route is configured), but dispatching the resolved reviewer and each of its configured independent fallbacks failed with provider availability errors on repeated attempts. A `RoutingError` (no independent route configured) is a configuration problem — fix the configuration; it never activates this override. When the trigger is met, the orchestrator may manually dispatch a **fresh instance** of the most capable reachable model as the reviewer, even when that matches the author's model. Constraints:

- Record the audit trail before invoking it: each failed route, the error, and the attempt times.

- Never the author's own thread or instance — always a fresh dispatch with independently constructed context.
- The review report and any resulting PR body must carry an explicit `EMERGENCY SAME-MODEL REVIEW` flag naming the outage.
- Do not downgrade to a lower-capability model to manufacture independence; a capable same-model review beats an incapable independent one.
- The override lasts only as long as the outage: resume normal resolution — including for delta re-gates of work reviewed under the override — the moment an independent model is reachable.
- Project routing policy may name the concrete emergency model and models excluded from review; it governs.

Plan-supplied routes are explicit run overrides. For public workflow decisions, precedence is plan, project, bundled. Within project configuration, reviewer specialty, workflow, harness, and project role retain their existing resolver precedence. A plan may route implementer, task-reviewer, and final-reviewer work, but never the session orchestrator.

## Project configuration

Read optional overrides from `<project-root>/.toolbelt/agents.json`. It accepts these top-level keys:

- `version`: integer `1`.
- `roles`: default role-to-route overrides.
- `harnesses`: harness names containing role-to-route overrides.
- `workflows`: workflow names containing role-to-route overrides.
- `reviewer_specialties`: specialty-to-route overrides.

Each route requires string `harness`, `model`, and `effort` values. It may contain `fallbacks`, an ordered array of routes. Treat invalid JSON or an incomplete selected route as a configuration error; never guess its meaning.
