# Branch lifecycle

## Ledger and evidence

At entry, resolve the installed SDD skill’s `scripts/sdd-workspace` and run it with the plan path from the starting worktree. Keep delivery’s `delivery.md` in that returned workspace. Record its absolute path in each boundary’s SDD ledger header. Boundary entries live here, with pointers to their SDD workspaces; keep this file until every boundary closes. Retain the starting worktree while it holds this record. Before execution record the prepared boundary’s branch, predecessor PR, fork SHA, and SDD workspace.

SDD records `Final review: clean at <full SHA>, route <harness/model/effort>, report <absolute path>` before handing off. Supply its ledger path to branch completion and require it to record `Suite: passed at <full SHA>, command <command>, output <absolute path>` (or its documented docs-only exemption) before publishing. This records Step 1’s existing verification; it adds no test run.

After interruption, verify the recorded report and suite output against the current head before publication. Reuse matching evidence; missing or invalid evidence requires only the missing gate. Pass the verified final-review SHA as the monitor’s local-gate SHA. Record the PR when opened; check remote state before retrying publication.

## Rebases

Ownership follows publication. Delivery owns an unpublished boundary; afterwards only its monitor moves the branch. Implementers and fixers never rebase.

At task boundaries check the predecessor PR and fetch its remote head. After it merges, use the updated base branch and the recorded pre-merge parent head; retarget the unpublished boundary’s planned PR base. Closure without merge blocks descendants. If the parent moved, stop opening new tracks, finish and merge active tracks, and wait for primary-worktree implementers, fixers, and reviewers. Rebase with `git rebase --onto <parent-new> <parent-old> <boundary-branch>`, serialized with other branch operations — always before that lane's broad final review. Abort on conflict and report the paths.

Append `Boundary <N>: rebased <old7> → <new7>`, mapping old task ranges to new ranges. Review evidence may carry forward only when the task’s `git patch-id --stable`, consumed contracts, and relevant dependencies are unchanged; record that comparison. Otherwise obtain affected review and test evidence again. Reuse UX evidence only under ux-gate’s rendered-dependency rule. Branch completion still requires its exact-head suite evidence or docs-only exemption.

## Cleanup

After confirmed merge and linked-issue reconciliation, remove the worktree, branch, and ignored scratch for that boundary. First preserve its merged record in the delivery ledger. Never remove a workspace with live agents, unmerged track work, or evidence another open boundary needs. Keep prototype baselines until their consumers finish. Remove the delivery ledger and its containing scratch only after every boundary closes. Explicit abandonment requires your human partner’s instruction.
