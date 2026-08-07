---
name: pr-monitor
description: Own one pull request from its current head through CI, configured review providers, fix loops, and merge or a durable blocker. Internal helper started by delivery entry points after a slice PR opens.
---

# PR Monitor

Own exactly one PR and its worktree until it is merged or genuinely blocked. This skill is the sole source of PR review, CI, fix-loop, and merge mechanics; callers start it once and wait for its return. You monitor, judge findings, fix, push, and merge yourself — one agent, no dispatched fixers.

## Project policy

Read `.toolbelt/pr-policy.md` at the repository root when it exists. It names the review providers to await, how to request them, complexity lanes, and timeout policy. Without it, the required conditions are exact-head green CI, zero unresolved review threads, and no requested-changes review. Never hard-code a provider this file does not name. The statements in this skill are SECONDARY to repository specifics.

## Preflight

Capture the PR number, branch, current full head SHA, merge state, and the local-gate SHA. The local final gate must have approved this exact head before monitoring begins. Bind all evidence to the current head; any push starts a new evidence cycle. Exception: a push touching only Markdown under `docs/**` or the repository root, or `.toolbelt/**` scratch, carries local-gate and completed-review evidence forward — record the range. CI is never carried forward, and a file the application builds, renders, or serves, or that CI executes, never qualifies.

## Monitor loop

1. Refresh the PR head, merge state, and unresolved threads. A conflicting PR schedules no CI; resolve the conflict first.
2. Refresh exact-head CI (`gh pr checks` or the policy file's command). Distinguish failed from pending from unavailable, and fail closed on unavailable — it is not a green result.
3. Await, and at most once per head request each policy-named provider. Only a current-head review object or an authenticated completion naming the current commit counts as completion; acknowledgements and reactions never do.
4. Once every awaited provider has completed on the current head, verify each finding against the code and judge it yourself: fix what is real inline, rebut what is not on the thread with the code evidence. Each fix carries fresh passing covering-test evidence; never rerun a local workspace suite — exact-head CI owns suite-level regression. Push all fixes as one batch. The push starts a new evidence cycle, and the awaited providers' next round on the new head is the re-review — they are the independent check on your fixes, so no extra review loop. A genuinely entangled finding — colliding with the plan, another in-flight lane, or a decision above this PR — goes to the caller with the code evidence.
5. If no action is ready, wait one bounded interval (default 180 seconds; policy may override) and refresh. Do not nest another watcher.

## Fallback

A provider that reaches the policy timeout on one head (default 60 minutes), or explicitly fails, skips, or rate-limits, drops out of the awaited set for that head. Record the fallback reason in the PR body before merging and in your return; the policy file decides whether a recorded fallback blocks. Every remaining condition still applies. Do not switch to a provider the policy does not name.

## Merge and return

Immediately before merging, re-verify on the expected head (or one differing only by recorded docs-only carry-forward): policy-named providers or the recorded fallback, exact-head green CI, mergeability, and zero unresolved threads. Merge when all pass, confirm the remote PR is `MERGED`, and return the exact merge state — PR number, merged SHA, and merge commit. The caller owns post-merge reconciliation.
