# Toolbelt Release Notes

Toolbelt is a fork of [Superpowers](https://github.com/obra/superpowers). It diverged at upstream v6.1.1 (2026-07-02); every release up to and including that one is upstream's work, and those notes live at https://github.com/obra/superpowers.

## Unreleased

Everything since the fork point. No Toolbelt release has been cut — the version string still reads `6.1.1`, inherited.

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
