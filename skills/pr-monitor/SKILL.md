---
name: pr-monitor
description: Own one WorkStack pull request from its current head through CI, configured review providers, fix loops, and merge or a durable blocker. Internal helper started by WorkStack entry points after a slice PR opens.
---

# WorkStack PR Monitor

Own exactly one PR and its worktree until it is merged or genuinely blocked. This skill is the sole source of WorkStack PR review, CI, fix-loop, and merge mechanics; callers start it once and wait for its return.

## Project policy

Read `.toolbelt/pr-policy.md` at the repository root when it exists. It names the review providers to await, how to request them, complexity lanes, and timeout policy. Without it, the required conditions are exact-head green CI, zero unresolved review threads, and no requested-changes review. Never hard-code a provider this file does not name.

## Preflight

Capture the PR number, branch, current full head SHA, merge state, and the approved local-gate SHA. The local final gate must have approved this exact head before monitoring begins. Bind all evidence to the current head; any push starts a new evidence cycle. Exception: a push whose commits touch only Markdown files under `docs/**` or at the repository root, or `.toolbelt/**` scratch, carries local-gate and completed-review evidence forward — record it explicitly ("gate at `<sha>`; head advanced by docs-only `<sha>..<sha>`"). A file the application builds, renders, or serves, or that CI executes, never qualifies regardless of path. CI is never carried forward: exact-head green CI is still required on the new head. For provider completion, a review object naming the recorded carried-forward predecessor head counts as current-head completion — do not request a new provider review for a docs-only push.

## Monitor loop

1. Refresh the PR head, merge state, and unresolved threads. A conflicting PR schedules no CI; resolve the conflict before diagnosing missing checks.
2. Refresh exact-head CI (`gh pr checks` or the policy file's command). Distinguish failed from pending from unavailable, and fail closed on unavailable — it is not a green result.
3. Await, and at most once per head request each policy-named provider. Only a current-head review object or an authenticated completion naming the current commit counts as completion; acknowledgements and reactions never do.
4. Once every awaited provider has completed on the current head, verify findings against the code. Dispatch fixer(s) routed via agent-routing — one agent for a small or entangled set, several in parallel when findings are independent and touch separate surfaces — confirm each fixer's fresh passing covering-test evidence and inspect the fixes (never rerun a local workspace suite — exact-head CI owns suite-level regression), then push all fixes as one batch. Concretely rebut invalid findings on the PR. The push starts a new evidence cycle; the awaited providers' next round on the new head is the re-review.
5. If no action is ready, wait one bounded interval (default 180 seconds; policy may override) and refresh. Do not nest another watcher.

## Fallback

A provider that reaches the policy timeout on one head (default 60 minutes), or explicitly fails, skips, or rate-limits, drops out of the awaited set for that head. Record the fallback reason. Every remaining condition still applies — the other awaited providers, exact-head green CI, and the recorded local gate approval. Do not switch to a provider the policy does not name.

## Merge and return

Immediately before merging, re-verify on the expected head (or a head that differs from it only by recorded docs-only carry-forward commits): policy-named providers or the recorded fallback, exact-head green CI, mergeability, and zero unresolved threads. Merge when all pass, confirm the remote PR is `MERGED`, and return the exact merge state — PR number, merged SHA, and merge commit — to the caller. The caller owns post-merge reconciliation.
