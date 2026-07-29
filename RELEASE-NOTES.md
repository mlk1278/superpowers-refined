# Toolbelt Release Notes

Toolbelt is a fork of [Superpowers](https://github.com/obra/superpowers). It diverged at upstream v6.1.1 (2026-07-02); every release up to and including that one is upstream's work, and those notes live at https://github.com/obra/superpowers.

## v7.3.0 (2026-07-28)

Leaner planning guidance and updated default agent routes.

- **Brainstorming drops two redundant mandates.** The one-question-per-message and repeated YAGNI rules are gone, leaving the surrounding guidance to scale discovery and design to the work.
- **Plan review is explicitly cross-family.** A plan written by Claude must be reviewed by GPT, and vice versa, rather than relying on model-identity independence alone.
- **Default routes reflect the daily workflow.** Claude Opus 5 now leads implementation, exploration, planning, errands, and monitoring, while Codex GPT-5.6 Sol leads independent review; native dispatch and in-context bounded reads are preferred where available.

## v7.2.0 (2026-07-26)

Six guardrails closing gaps the same parallel-lane run exposed after v7.1.0 shipped.

- **A gate is a separate command.** Toolbelt mandates a project's quiet-run wrapper for suite output but never said what it costs: a buffered wrapper releases nothing until the command exits, so any check reading that command's own output confirms the precondition only after every write has landed. `subagent-driven-development` and the implementer prompt now state that a check deciding whether something runs is its own command, run to completion first, and `writing-plans` carries the timing variant of "checks that can't fail."
- **Deletions account for the coverage they remove.** Tests for behaviour a deletion keeps share files, blocks, and fixtures with tests for behaviour it removes, so a change correct about code is silently wrong about coverage — the compiler is quiet, the suite is green, and the assertions are gone. A new gotcha class requires the coverage-delta inventory and relocation proved green before the delete lands; the task reviewer checks for it.
- **Orchestrator returns carry a question.** The rule against progress check-ins covered only a human partner. It now covers a dispatched orchestrator returning to its dispatcher: return a decision you cannot make, a completed handoff, or a durable block.
- **Completion notifications are not terminality.** Background agents notify whenever they momentarily hold no live children, and one task may notify several times. `delivery` reads terminality from the monitor's returned merge state and the PR itself.
- **Provider staleness is a named condition.** `pr-monitor` keeps a consecutive-miss count per provider and records a provider silent across two requested heads in the PR body *before* merging, leaving the policy file to decide whether it blocks. A provider that never recovers withdraws its independent judgement from every head after the first while all the merge conditions still read clean.
- **The documented SDD workspace path matches the one the script creates** (`<plan-basename>-<digest>`).

## v7.1.0 (2026-07-26)

A comparison against upstream Superpowers v6.2.0, plus findings from an overnight run of eight PRs across five parallel worktree lanes. The theme is catching problems before implementation rather than improvising around them mid-task.

### Planning

- **`writing-plans` explores before it drafts.** It went from scope check straight to file structure, mapping files and drawing task boundaries without reading the code those tasks would touch. It now fans out explorers per surface first, hunts a named taxonomy of gotchas — assertions that can never pass, checks that can't fail, tooling traps, ordering prerequisites, shared contracts, environment drift — and requires each one leave the pass either resolved in the plan or named with an instruction to escalate. A gotcha that is neither is a plan defect, alongside the other placeholder failures. Findings land per-task and plan-wide, and the plan reviewer may fan out its own explorers rather than reading the plan as a document.
- **Plans get a review gate.** Required, mirroring the one `writing-specs` already had, resolved through a new `plan` reviewer specialty. Note that independence is enforced on model identity, not family: configure the `plan` specialty to a different family than `planner` if you want cross-family review.

### Subagent-driven development

- **The fix loop is bounded.** Three rounds per task: rounds 1-2 resume the original implementer, round 3 dispatches a fresh one. At the cap a breaker trips — adjudicate each open finding, park it with a ruling in the ledger, or stop on load-bearing ones. Previously "repeat until approved," with no exit. Adjudicating before the cap is forbidden; it is pre-judging with a different name.
- **Re-reviews are scoped.** A new template verdicts each finding ADDRESSED or NOT ADDRESSED, confines new-breakage hunting to the fix diff, and routes out-of-scope observations to the ledger where they cannot extend the loop.
- **Workspaces are scoped per plan.** A flat `.toolbelt/sdd/` meant two plans overwrote each other's `task-N` briefs and misread each other's ledgers. Directories are now the plan basename plus a digest of its repo-relative path, so same-named plans in different directories stay separate.
- **Negative assertions carry evidence they can fail.** For any test asserting an absence, a guard, or a negative, the implementer reports its TDD RED or a recorded mutate-and-revert; the reviewer treats a missing demonstration as a finding. Tests that pass while proving nothing were the dominant defect class across the observed run.

### Delivery and integration

- **A PR ends in a named owner.** `finishing-a-development-branch` creates the PR and hands it to `pr-monitor`, or returns it to a caller that already owns monitoring. "PR is open" is not a terminal state.
- **Monitors escalate instead of overruling reviewers.** A monitor that suspects a finding is invalid takes it to the orchestrator or a high-effort reviewer with code evidence. Complying with a wrong finding and rebutting a right one are both real failures, and neither is a low-effort judgement.
- **Squash merges are never judged from commit ancestry**, which shows every branch commit as unmerged.
- **Concurrent slices that edit the same files are one PR**, however cleanly the outcomes divide. Sequential slices may revisit a file once the first has merged.
- **A dead-looking agent that owns external state gets that state checked** before a second owner is created.

### Testing and configuration

- **`testing-anti-patterns.md` became `writing-good-tests.md`** — shorter, and adds name-the-break, mirror assertions, change detectors, behavior-not-text, the rule that an absence assertion must exclude its own evidence, and a mutation check.
- **New optional `.toolbelt/worktree-policy.md`** for port ranges, sidecar containers, per-worktree data, and teardown, read by `using-git-worktrees` before it creates anything. Parallel lanes that each grab the default database, API, and web ports collide in ways that read as code bugs.
- **Bundled reviewer specialties now resolve.** They were only ever consulted in project config, so the bundled `code`, `spec`, and `ux` routes had no effect on `--reviewer-specialty` lookups. Precedence is project specialty, project role, bundled specialty, bundled role.

## v7.0.0 (2026-07-25)

The first Toolbelt release. Everything since the fork point, in one version — the
major bump marks the break, not a single change within it. Installs are not
compatible with the `superpowers`/`workstack-` names; see the migration table in
[docs/ADOPTING-IN-A-PROJECT.md](docs/ADOPTING-IN-A-PROJECT.md).

### Identity

- **Renamed the framework to Toolbelt.** Package, both plugin manifests, both marketplace manifests, the session-start hook, and every skill that named the framework. `using-superpowers` became `using-toolbelt`, and the bootstrap it injects now says "You have a toolbelt." The `workstack-*` skills lost their prefix — `workstack-delivery` is `delivery`, `workstack-quick-task` is `quick-task`, and so on — and `tests/workstack/` became `tests/toolbelt/`.
- **Rewrote CLAUDE.md and README for this fork.** CLAUDE.md was entirely upstream-contribution guidance — rejection rates, PR templates, which branch to target — all of it false here and all of it loaded into every session before anything else. It now covers how skills are structured, what must not be broken, the no-project-assumptions constraint, and the acceptance test. The `.github` issue and PR templates and `FUNDING.yml` are gone.
- **Dropped the telemetry beacon.** The brainstorming visual companion loaded its logo from `primeradiant.com` with the version string attached, which upstream documents as a usage beacon. A renamed fork should not be reporting Superpowers versions to anyone. Branding is local text now, the env-var opt-outs went with it, and the branding test asserts the inverse of what it used to: no remote asset references in the served HTML at all.
- **Removed the upstream-tracking apparatus.** The divergence allowlist, its checker script, `UPSTREAM-UPDATES.md`, and the tests that enforced them existed to keep a merge path open. There is no upstream remote and no plan to merge back.

### Harnesses

- **Dropped every harness except Claude Code and Codex.** Cursor, Kimi, OpenCode, Pi, and Antigravity lose their plugin manifests, install docs, tool-mapping references, hook configs, and test suites; the dead Gemini extension manifest and `GEMINI.md` go with them, and the Copilot CLI branch is out of the session-start hook. That is roughly 2,000 lines of support for platforms this fork does not use. `docs/porting-to-a-new-harness.md` still describes the hook contract if one gets added back.

### Delivery

- **A delivery pipeline for approved plans.** `delivery` takes an approved plan, selects one shippable slice, runs it through subagent-driven development, and hands the PR to `pr-monitor`, which owns it through CI, review providers, fix loops, and merge. `quick-task` is the small-change entry point: decision-complete work, one PR, a scratch mini-plan, no product shaping. `ux-gate` verifies changed user-visible surfaces by scripted capture rather than interactive browsing. `finishing-a-development-branch` gained a declared completion route so the pipeline can hand off to it without ambiguity.
- **Consolidated the pipeline down to its entry points.** The first pass shipped seven public skills — `workstack-start`, `-resume`, `-slice-gate`, `-spec-review`, and their reference docs. Those seams were plan bookkeeping the plan itself already carried, so they were folded into `delivery` and `quick-task`, taking about 680 lines with them.
- **PR monitoring can run in the background.** The orchestrator may start the next task while a monitor runs, when the work is independent and at most one PR is in flight. The monitor's return is always processed, and a merged PR rebases in-flight lanes before their final review.
- **Verification and UX capture are proportional to change risk.** A verification-scope ladder — focused tests while iterating, affected package suites at the task gate, one workspace run at the final gate, CI owns post-push regression — replaces running the full suite at every step. UX capture matrices are enumerated from the diff and the acceptance criteria instead of imposed wholesale by the plan.

### Skills

- **Subagents are routed by logical role from a session-start brief.** Two routing systems had been running side by side: core skills hard-coded "Subagent (general-purpose)" in six places while the delivery skills resolved logical roles through `resolve-agent`. Core skills now name a role, and `using-toolbelt` loads the routing brief before the first dispatch. `resolve-agent --brief` resolves every role in one call — harness, model, effort, per-role instructions, reviewer specialties. Reviewer independence would normally break under a single session-start call, since the author's model is not knowable then, so the brief emits a reviewer per author model and the rule stays fail-closed. The `operator` role is renamed `errand` and bounded to side work: it never edits repository files.
- **Nothing under `skills/` assumes a specific project.** The plugin installs globally, so hard-coded repo paths resolved nowhere in a consuming project. Scripts are referenced relative to their own skill directory, Linear is generalized to "the issue tracker", and per-project behavior comes from optional files in the consuming repo — `.toolbelt/agents.json`, `.toolbelt/pr-policy.md`, `docs/REVIEW-GUIDANCE.md`, `AGENTS.md`. `.toolbelt/` is also where scratch lands: `sdd/`, `quick/`, `brainstorm/`.
- **Split `writing-specs` out of `brainstorming` and removed `executing-plans`.** Spec writing and its document gate were a distinct entry condition buried inside brainstorming; they get their own skill and their own description. `executing-plans` overlapped with the delivery path and is gone.
- **Condensed the core skills.** `test-driven-development`, `systematic-debugging`, `receiving-code-review`, `dispatching-parallel-agents`, and `writing-skills` were written for models that needed the process restated three times. Roughly 1,200 lines of restatement removed; the forceful blocks — hard gates, entry gates, Red Flags tables, rationalization lists — are preserved verbatim, because that phrasing is what survives compaction. `subagent-driven-development`, `brainstorming`, `requesting-code-review`, `writing-plans`, and `verification-before-completion` got the same treatment.
