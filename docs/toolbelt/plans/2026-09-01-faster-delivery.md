# Faster Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use toolbelt:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `docs/toolbelt/specs/2026-09-01-faster-delivery-design.md`: default execution tracks, a task size ceiling, a per-test RED step, conditional re-review, stacked PR chains in delivery and pr-monitor, a worktree source ref, and a plain-language rewrite of the planning skills.

**Architecture:** Each task rewrites one or two skill files completely, applying both the spec's rule changes and its prose rules in one pass, and updates the tests that pin that file's text. Three tracks run concurrently over disjoint files. One integration task adds the word-count test, runs every test, and bumps the version.

**Tech Stack:** Markdown skills, bash tests under `tests/toolbelt/` (`assert_contains` / `assert_not_contains` with `grep -F`), `scripts/lint-shell.sh`, `scripts/bump-version.sh`.

## Global Constraints

- Skills hard-code no consuming repository, review provider, or model. `assert_no_model_names` in `test-delivery.sh` and `test-pr-monitor.sh` fails on `gpt-`, `opus-`, `sonnet`, `haiku`, `-sol`.
- `<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags tables, and rationalization lists keep their wording. They are excluded from the prose rewrite.
- One skill names exactly one next skill. Every existing "invoke X. Do NOT invoke any other skill" handoff stays.
- "Your human partner" stays. Never "the user" in skill text.
- Frontmatter `description` lines do not change, except `skills/pr-monitor/SKILL.md` (Task 8).
- Every test needle listed in a task's Gotchas is kept byte-identical, or that task changes the test in the same commit.
- Codex `agents/openai.yaml` `short_description` is 25–64 characters.
- Prose rules (spec Component 7): one idea per sentence; imperative mood for instructions; say each rule once; no metaphor or rhetorical framing; no intensifiers ("ruthlessly", "genuinely", "silently", "the whole point", "is the tell", "however independent they look"); keep every exact command, path, quoted user-facing message, and table verbatim unless a spec rule changes it.
- Word-count ceilings (Task 11 pins them; each rewrite task checks its own with `wc -w`):

| File | Ceiling |
|---|---|
| `skills/brainstorming/SKILL.md` | 740 |
| `skills/writing-specs/SKILL.md` | 420 |
| `skills/writing-plans/SKILL.md` | 1880 |
| `skills/subagent-driven-development/SKILL.md` | 1760 |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | 590 |
| `skills/subagent-driven-development/re-review-prompt.md` | 340 |
| `skills/dispatching-parallel-agents/SKILL.md` | 350 |
| `skills/using-git-worktrees/SKILL.md` | 910 |
| `skills/subagent-driven-development/implementer-prompt.md` | 400 |
| `skills/delivery/SKILL.md` | 940 |
| `skills/pr-monitor/SKILL.md` | 640 |
| `skills/quick-task/SKILL.md` | 200 |
| `docs/WORKFLOW.md` | 290 |

The first eight are 60% of the pre-rewrite count rounded up to 10. The last five gain rule text or are already short; their ceiling is the pre-rewrite count rounded up to 10.

## Known Gotchas

- **Needles are `grep -F` exact.** A changed em-dash, backtick, or asterisk breaks the test. Each task lists its file's needles; copy them from the current file, not from memory.
- **Tests run one file at a time:** `bash tests/toolbelt/<name>.sh`. There is no aggregate runner. New shell tests also pass `scripts/lint-shell.sh tests/toolbelt/<name>.sh`.
- **Edits here do not reach the running session.** Both harnesses install from a cached copy (CLAUDE.md, "Verifying a change"). Tests are the gate; the acceptance drill is a human step after Task 11.
- **`test-execution-tracks.sh` asserts on three files** across three tracks. It belongs to Task 2. Tasks 4 and 9 keep its SDD and worktree needles byte-identical so the test stays green from any track.
- **`docs/WORKFLOW.md` is asserted by `test-delivery.sh`**, so both belong to Task 7.
- **Spec-mandated wording wins over the ceiling.** If a file cannot fit its rules under the ceiling, report DONE_WITH_CONCERNS with the count; do not cut a rule.

---

## PR Boundaries

| PR | Outcome | Tasks | Depends on | Independent verification |
|---|---|---|---|---|
| 1 | Toolbelt 7.9.0: faster delivery rules and plain-language planning skills | 1–11 | none | every `bash tests/toolbelt/*.sh` exits 0; `scripts/bump-version.sh --check` reports 7.9.0 everywhere |

One PR: the plugin ships as one version, and the skills reference each other's handoffs (writing-plans → delivery → pr-monitor, delivery's role table ↔ SDD's orchestrator close). A partial merge leaves contradictory handoffs live in the installed plugin. The three tracks below give the same isolation a PR split would, without a release that contradicts itself.

## Execution Tracks

| Track | Tasks | Depends on | Files touched (summary) | Why safe |
|---|---|---|---|---|
| planning | 2–3 | — | writing-plans, brainstorming, writing-specs, test-writing-plans.sh, test-execution-tracks.sh | disjoint from execution, shipping |
| execution | 4–6 | — | subagent-driven-development/**, dispatching-parallel-agents, test-final-review-gate.sh, test-fix-loop.sh | disjoint from planning, shipping |
| shipping | 7–10 | — | delivery/**, pr-monitor/**, using-git-worktrees, quick-task, docs/WORKFLOW.md, test-delivery.sh, test-pr-monitor.sh, test-chain-rebase.sh, test-worktree-source-ref.sh | disjoint from planning, execution |
| serial-2 | 11 | planning, execution, shipping | test-word-counts.sh, version files, RELEASE-NOTES.md | merge point |

Task 1 is a mainline task that runs before the fork. No track's task consumes another track's `Produces:`; the spec is the shared contract.

---

### Task 1: Pre-rewrite word counts and needle inventory

**Files:**
- Create: `tests/toolbelt/test-word-counts.sh`

**Interfaces:**
- Consumes: nothing
- Produces: `tests/toolbelt/test-word-counts.sh` with a `ceilings` table (path, integer) that Task 11 enables

**Gotchas:**
- The test must not fail on mainline while tracks are in flight. Until Task 11, it runs in report-only mode: it prints each file's count and ceiling and exits 0.

- [ ] **Step 1: Write the test in report-only mode**

`tests/toolbelt/test-word-counts.sh`: `set -euo pipefail`; `repo_root=$(git rev-parse --show-toplevel)`; a `ceilings` array of `path:integer` pairs copied from Global Constraints; a loop that runs `wc -w < "$repo_root/$path"`, prints `<count>/<ceiling> <path>`, and, when `ENFORCE=1`, prints `not ok - <path> exceeds ceiling` and exits 1 for any count above its ceiling. Without `ENFORCE=1` it exits 0 after printing.

- [ ] **Step 2: Run it both ways**

Run: `bash tests/toolbelt/test-word-counts.sh`
Expected: 13 lines printed, exit 0.

Run: `ENFORCE=1 bash tests/toolbelt/test-word-counts.sh`
Expected: `not ok - skills/brainstorming/SKILL.md exceeds ceiling` (the first over-ceiling file), exit 1.

Run: `scripts/lint-shell.sh tests/toolbelt/test-word-counts.sh`
Expected: exit 0.

- [ ] **Step 3: Commit**

```bash
git add tests/toolbelt/test-word-counts.sh
git commit -m "test: word-count ceilings for the planning skills (report-only until enforced)"
```

---

### Task 2: writing-plans — default tracks, size ceiling, per-test RED, whole-plan handoff

**Files:**
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `tests/toolbelt/test-writing-plans.sh`
- Modify: `tests/toolbelt/test-execution-tracks.sh`

**Interfaces:**
- Consumes: spec Component 1 and Component 7
- Produces: none

**Gotchas:**
- Needles to keep byte-identical (`test-writing-plans.sh`): `nearest instructions`, `` 2–3 targeted inline `rg` searches ``, `` agent-routing's `explorer` role ``, `completeness inventory`, `invisible trap`, `plan-shaping existence question`, `Start with one explorer`, `unfamiliar, independent subsystems`, `checkable paths and pointers`, `get wrong here?`, `An absence check must exclude its own evidence`, `A gotcha that is neither is a plan defect`, `## Known Gotchas`, `**Gotchas:**`, `## PR Boundaries`, `| PR | Outcome | Tasks | Depends on | Independent verification |`, `Every task number appears in exactly one boundary`, `why no smaller independently verifiable outcome exists`, `core plus one representative consumer`, `repeat the same reviewer judgment`, `Novel lifecycle, export, or rollout work stays separate`, `Coverage that leaves with the code`, `a precondition read from output the gated command itself produces`, `It may fan out its own explorers`, `**Unflagged gotchas**`, `**PR boundaries**`, `missing, horizontal, overlapping, or unjustified`. Absent needles stay absent: `fan out explorers — one per surface the plan will touch`, `No need to re-review`.
- Needles to keep (`test-execution-tracks.sh`, plans file): `## Execution Tracks`, `No file is created or modified by two concurrent tracks`, `contract-freeze`, `Every fork closes with a mainline integration task`.
- Headings that keep their text: `## Exploration Before Drafting`, `## File Structure`, `## PR Boundaries`, `## Task Structure`, `## Execution Tracks`, `## Plan Review Gate`.
- The Task Structure template's `Produces:` line gains "`Produces: none` when nothing downstream depends on this task" (spec Component 2 relies on it).

- [ ] **Step 1: Update the tests**

`test-writing-plans.sh`: replace the `one declared PR boundary at a time` needle with `Handing the plan to delivery`. Add needles: `Execution Tracks` required wording — `states in one sentence why no tasks can run concurrently`; `A task's **Files:** block is closed`; `at most 8 files`; `Mechanical sweep:`; `Expected, per test:`; `when the guard is absent`; `Produces: none`.

`test-execution-tracks.sh`: replace `bogus or missing track declarations` with `a plan with no concurrent tracks and no one-sentence justification is a defect`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-writing-plans.sh; bash tests/toolbelt/test-execution-tracks.sh`
Expected: `not ok - ...` on the first new needle in each, exit 1.

- [ ] **Step 3: Rewrite the skill**

Apply spec Component 1 in full: Execution Tracks required (replace "Optional. ... Omit the section and the plan runs fully serial." with the required rule and the one-sentence justification); Task Right-Sizing gains the closed Files block, the 8-file hard limit with the 400-line guide, the Mechanical sweep exception, and the contract-task ownership rule; Task Structure Step 2 becomes the per-test list with the guard-absent rule; `Produces: none` in the template; Self-Review item 6 and the Plan Review Gate tracks bullet use the new acceptance wording; Execution Handoff quotes the new message. Then rewrite the rest of the prose under the Global Constraints prose rules.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-writing-plans.sh && bash tests/toolbelt/test-execution-tracks.sh && wc -w skills/writing-plans/SKILL.md`
Expected: both exit 0; count ≤ 1880.

- [ ] **Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md tests/toolbelt/test-writing-plans.sh tests/toolbelt/test-execution-tracks.sh
git commit -m "writing-plans: tracks by default, 8-file task ceiling, per-test RED, plain language"
```

---

### Task 3: brainstorming and writing-specs — prose rewrite

**Files:**
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-specs/SKILL.md`

**Interfaces:**
- Consumes: spec Component 6 and Component 7
- Produces: none

**Gotchas:**
- Needles to keep (`test-interactive-design.sh`), brainstorming: `inside that skill is authorized`, `we could go frontend-first`, `The offer MUST be its own message`, `invoke it and no other`, `or to interactive-design when they accepted`. writing-specs: `Arriving from interactive-design with a reconciled contract ledger`.
- Both quoted offers (frontend-first, its Claude Design variant, the visual companion offer) and the writing-specs user-review message are user-facing quotes: verbatim.
- `<HARD-GATE>` and `<ENTRY-GATE>` blocks: verbatim.
- No rule changes. The checklist items, terminal states, and next-skill names stay.

- [ ] **Step 1: Confirm the current tests pass**

Run: `bash tests/toolbelt/test-interactive-design.sh`
Expected: exit 0.

- [ ] **Step 2: Rewrite both files**

Prose rules from Global Constraints. Keep every section heading.

- [ ] **Step 3: Verify**

Run: `bash tests/toolbelt/test-interactive-design.sh && wc -w skills/brainstorming/SKILL.md skills/writing-specs/SKILL.md`
Expected: exit 0; brainstorming ≤ 740, writing-specs ≤ 420.

- [ ] **Step 4: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/writing-specs/SKILL.md
git commit -m "brainstorming, writing-specs: plain-language rewrite"
```

---

### Task 4: subagent-driven-development — conditional re-review, ledger route, prose

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `tests/toolbelt/test-final-review-gate.sh`
- Create: `tests/toolbelt/test-fix-loop.sh`

**Interfaces:**
- Consumes: spec Component 2
- Produces: `tests/toolbelt/test-fix-loop.sh` (Task 5 appends prompt needles to it)

**Gotchas:**
- Needles to keep (`test-final-review-gate.sh`): `plan route, then project route, then the session routing brief`, `do not substitute your own judgment for a missing route`, `If the caller supplies a pre-final gate, run it after all task reviews and before the broad final review.`, `` scripts/review-package --plan PLAN_FILE MERGE_BASE HEAD` for the final review ``, `**Final-review findings get ONE fix subagent**`, `with the complete list — not one fixer per finding.`, `contains the covering tests, the command, and the output`, `read the implementer's test evidence on unchanged source instead of re-running it`, `Implementers and fixers always produce their own fresh evidence`, `**Workspace-wide suite:** once, at the final gate.`, `Then run exactly one scoped re-review of the fix wave`, `There is no second fix wave`, `**One fix round per task.**`, `Adjudicate **only** after the re-review`, `out-of-scope observations go to the ledger as deferred minors and never extend the loop`, `it never carries a check that gates that command`. Absent: `### Final whole-branch gate`, `REVIEW_HEAD=$(git rev-parse HEAD)`, `approved SHA`, `After any compaction or resume`.
- Needles to keep (`test-reviewer-context.sh`): `Do not read it`, `while orchestrating or pass it to implementers, fixers, explorers, planners,`, `` Use `None` when there is none. ``.
- Needles to keep (`test-execution-tracks.sh`): `## Parallel Tracks`, `At most 3 tracks run concurrently`, `## Decisions & drift risks`, `A textual conflict is a plan defect`, `Dispatch multiple implementation subagents into the same worktree`, `Parallelize tracks the plan did not declare`. Absent: `Dispatch multiple implementation subagents in parallel (conflicts)`.
- `Adjudicate **only** after the re-review` must still read correctly once re-review is conditional: keep the sentence and add that orchestrator close is the other exit.
- Red Flags block: verbatim.

- [ ] **Step 1: Write the tests**

`test-fix-loop.sh` (same `assert_contains` helper as `test-final-review-gate.sh`), against the SDD skill: `Produces:` and `Critical` in the re-review condition — needle `when the task's `Interfaces: Produces:` block is non-empty`; `**Orchestrator close**`; `Task <N>: fix round closed by orchestrator`; `route <harness>/<model>/<effort>`; `escalate to your human partner as a BLOCKED task`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-fix-loop.sh`
Expected: `not ok` on the first needle, exit 1.

- [ ] **Step 3: Rewrite the skill**

Apply spec Component 2: replace the re-review paragraph of The Fix Loop with the two-exit text; add the route to the in-progress ledger line; keep Parallel Tracks and Red Flags as they are. Then rewrite the rest under the prose rules.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-fix-loop.sh && bash tests/toolbelt/test-final-review-gate.sh && bash tests/toolbelt/test-reviewer-context.sh && bash tests/toolbelt/test-execution-tracks.sh && scripts/lint-shell.sh tests/toolbelt/test-fix-loop.sh && wc -w skills/subagent-driven-development/SKILL.md`
Expected: all exit 0; count ≤ 1760.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md tests/toolbelt/test-fix-loop.sh tests/toolbelt/test-final-review-gate.sh
git commit -m "sdd: conditional re-review, orchestrator close, route in ledger, plain language"
```

---

### Task 5: SDD prompt templates — seen-red, fix-report table, out-of-scope line

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/re-review-prompt.md`
- Modify: `tests/toolbelt/test-fix-loop.sh`

**Interfaces:**
- Consumes: `tests/toolbelt/test-fix-loop.sh` from Task 4
- Produces: none

**Gotchas:**
- Needles to keep (`test-reviewer-context.sh`), task-reviewer-prompt: `This read is an explicit exception to the limits on`, `docs/REVIEW-GUIDANCE.md`, `This file is reviewer-only.`, `[REVIEW_NUANCE]`, `does not override requirements,`, `[SMELLS_FILE]`. implementer-prompt must NOT contain `docs/REVIEW-GUIDANCE.md` or `smell-baseline`.
- The implementer template's Status tokens, report contract, and "under 15 lines" rule stay.

- [ ] **Step 1: Extend the test**

Append to `test-fix-loop.sh`: implementer-prompt contains `against code that lacks the guard` and `| Finding | Commit | Covering test command | Result |`; re-review-prompt contains `outside the fix diff go to the ledger and never extend the loop`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-fix-loop.sh`
Expected: `not ok` on `against code that lacks the guard`, exit 1.

- [ ] **Step 3: Rewrite the three templates**

implementer-prompt: the seen-red paragraph and TDD Evidence bullet per spec; the fix-report table under "After Review Findings" with `Result` defined as the command's last passing line. re-review-prompt: the out-of-scope line. All three: prose rules.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-fix-loop.sh && bash tests/toolbelt/test-reviewer-context.sh && wc -w skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/task-reviewer-prompt.md skills/subagent-driven-development/re-review-prompt.md`
Expected: exit 0; ≤ 400, ≤ 590, ≤ 340.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/*.md tests/toolbelt/test-fix-loop.sh
git commit -m "sdd prompts: guard-absent seen-red, fix-report table, re-review scope line"
```

---

### Task 6: dispatching-parallel-agents — prose rewrite

**Files:**
- Modify: `skills/dispatching-parallel-agents/SKILL.md`

**Interfaces:**
- Consumes: spec Component 6
- Produces: none

**Gotchas:**
- No test pins this file. Keep the "Don't use when" bullet that points plan-task parallelism at SDD's Execution Tracks.

- [ ] **Step 1: Rewrite**

Prose rules. Keep the example prompt block and the Common Mistakes pairs.

- [ ] **Step 2: Verify**

Run: `wc -w skills/dispatching-parallel-agents/SKILL.md`
Expected: ≤ 350.

- [ ] **Step 3: Commit**

```bash
git add skills/dispatching-parallel-agents/SKILL.md
git commit -m "dispatching-parallel-agents: plain-language rewrite"
```

---

### Task 7: delivery — boundary loop, PR chains, role table, WORKFLOW.md

**Files:**
- Modify: `skills/delivery/SKILL.md`
- Modify: `skills/delivery/agents/openai.yaml`
- Modify: `docs/WORKFLOW.md`
- Modify: `tests/toolbelt/test-delivery.sh`

**Interfaces:**
- Consumes: spec Component 3
- Produces: none

**Gotchas:**
- Needles to keep (`test-delivery.sh`, skill): `name: delivery`, `Use when an approved implementation plan is ready to be implemented and shipped`, `I'm using delivery to deliver this approved plan.`, `## Agent Routing`, `plan route, then project route, then bundled default`, `session agent remains the orchestrator`, `toolbelt:using-git-worktrees`, `toolbelt:subagent-driven-development`, `ux-gate`, `broad final review is the slice gate`, `toolbelt:finishing-a-development-branch`, `pr-monitor`, `run it in the background`, `Never report the slice complete or end the session while the monitor runs`, `always before that lane's broad final review`, `Reconcile the issue tracker only when the plan is linked to one`, `remove the worktree, branch, and ignored scratch`, `run concurrently and that edit the same files are one PR`, `Sequential slices may revisit the same file once the first has merged`, `is not grounds to start a second one`, `check that state directly`, `never commit ancestry`, `A completion notification is not that return`. Absent: `workstack-slice-gate`, `progress ledger`.
- Needles that change: `one coherent delivery slice` (skill and WORKFLOW.md) → keep the phrase in the slice definition paragraph (it still defines what one boundary is); `The next work is independent` → delete needle; `At most one PR is in background monitoring` → replace with `assert_not_contains`; WORKFLOW.md `one monitored PR at a time` → replace with `one pr-monitor per chain`.
- Routing needles (`Plan-supplied routes are explicit run overrides`, `plan, project, bundled`) are in agent-routing, untouched.
- `openai.yaml` short_description: `Deliver an approved plan through PR chains to merge` (49 chars).

- [ ] **Step 1: Update the test**

`test-delivery.sh`: delete the `The next work is independent` and `At most one PR is in background monitoring` needles; add `assert_not_contains "$skill" "no stacked branches"` and `assert_not_contains "$skill" "At most one PR"`; add needles `<plan-slug>/pr-<N>`, `Boundary <N>: branch`, `one pr-monitor`, `Ownership follows publication`, `Boundary <N>: rebased`. WORKFLOW.md: replace `one monitored PR at a time` with `one pr-monitor per chain`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-delivery.sh`
Expected: `not ok` on `<plan-slug>/pr-<N>`, exit 1.

- [ ] **Step 3: Rewrite the skill and WORKFLOW.md**

Apply spec Component 3: entry/exit, the boundary loop, Stacked slices, Who rebases, the role table rows, Step 6 per merged boundary. Rewrite `docs/WORKFLOW.md`'s delivery paragraph to match (chains, one monitor per chain, rebases at task boundaries). Prose rules throughout.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-delivery.sh && wc -w skills/delivery/SKILL.md docs/WORKFLOW.md`
Expected: exit 0; ≤ 940, ≤ 290.

- [ ] **Step 5: Commit**

```bash
git add skills/delivery/SKILL.md skills/delivery/agents/openai.yaml docs/WORKFLOW.md tests/toolbelt/test-delivery.sh
git commit -m "delivery: boundary loop with PR chains, ownership by publication"
```

---

### Task 8: pr-monitor — one chain, chain rules, 20-minute timeout, rebase test

**Files:**
- Modify: `skills/pr-monitor/SKILL.md`
- Modify: `skills/pr-monitor/agents/openai.yaml`
- Modify: `tests/toolbelt/test-pr-monitor.sh`
- Create: `tests/toolbelt/test-chain-rebase.sh`

**Interfaces:**
- Consumes: spec Component 4
- Produces: none

**Gotchas:**
- Needles to keep (`test-pr-monitor.sh`): `name: pr-monitor`, `sole source of PR review, CI, fix-loop, and merge mechanics`, `.toolbelt/pr-policy.md`, `exact-head green CI, zero unresolved review threads, and no requested-changes review`, `Never hard-code a provider this file does not name.`, `The local final gate must have approved this exact head before monitoring begins.`, `Bind all evidence to the current head`, `at most once per head request each policy-named provider`, `fail closed on unavailable`, `Once every awaited provider has completed on the current head`, `judge it yourself`, `fix what is real inline`, `Push all fixes as one batch`, `next round on the new head is the re-review`, `drops out of the awaited set for that head`, `Record the fallback reason`, `` confirm the remote PR is `MERGED` ``, `The caller owns post-merge reconciliation.`, `Do not nest another watcher.`, `genuinely entangled`, `the policy file decides whether a recorded fallback blocks`, `in the PR body before merging`.
- `genuinely entangled` is a pinned needle and stays despite the intensifier rule.
- Needle that changes: `Own exactly one PR` → `Own one chain`.
- Description line changes per spec; `openai.yaml` short_description: `Own a PR chain through CI, review, fixes, and merge` (51 chars).
- `test-chain-rebase.sh` needs `git` only. Use `mktemp -d`, `git init -q -b main`, commit identity via `-c user.name=t -c user.email=t@t`. Squash-merge with `git merge --squash pr-1 && git commit`. The recipe under test: `git rebase --onto main <pr-1-old-head> pr-2`. Assert `git log --oneline main..pr-2 | wc -l` equals 1 and that pr-2's tree contains both pr-1's file and pr-2's file.

- [ ] **Step 1: Update and write the tests**

`test-pr-monitor.sh`: replace `Own exactly one PR` with `Own one chain`; add `## Chain rules`, `**Lowest first.**`, `**Fix in the owner.**`, `**One topology writer.**`, `**Merge bottom-up.**`, `--force-with-lease`, `git patch-id --stable`, `gh pr edit --base`, `default 20 minutes`. `test-chain-rebase.sh` as in Gotchas.

- [ ] **Step 2: Run tests to verify they fail / pass**

Run: `bash tests/toolbelt/test-pr-monitor.sh`
Expected: `not ok - ... Own one chain`, exit 1.

Run: `bash tests/toolbelt/test-chain-rebase.sh`
Expected: exit 0 (it tests git, not the skill; it must pass before the skill quotes the recipe).

- [ ] **Step 3: Rewrite the skill**

Apply spec Component 4: description, opening paragraph, preflight per layer, `## Chain rules` with the four rules and exact commands, timeout `default 20 minutes`, the per-layer Return. Prose rules throughout.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-pr-monitor.sh && bash tests/toolbelt/test-chain-rebase.sh && scripts/lint-shell.sh tests/toolbelt/test-chain-rebase.sh && wc -w skills/pr-monitor/SKILL.md`
Expected: exit 0; ≤ 640.

- [ ] **Step 5: Commit**

```bash
git add skills/pr-monitor tests/toolbelt/test-pr-monitor.sh tests/toolbelt/test-chain-rebase.sh
git commit -m "pr-monitor: own one PR chain; chain rules; 20-minute provider timeout"
```

---

### Task 9: using-git-worktrees — source ref and prose

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md`
- Create: `tests/toolbelt/test-worktree-source-ref.sh`

**Interfaces:**
- Consumes: spec Component 5
- Produces: none

**Gotchas:**
- Needles to keep (`test-worktree-baseline.sh`): `smallest focused checks that prove a clean start`, `not a workspace or package-wide`, `cite that instead of re-running`, `docs-only work`, `Baseline: <focused tests passing`, `Satisfy Step 3 now`, `.toolbelt/worktree-policy.md`, `non-conflicting`. (`test-execution-tracks.sh`): `parallel-workspace rules`, `concurrency limit lower than 3`.
- The rationalization table and the native-tool-first rule stay verbatim.

- [ ] **Step 1: Write the test**

`test-worktree-source-ref.sh`: asserts `git worktree add "$path" -b "$BRANCH_NAME" "${SOURCE_REF:-HEAD}"`, `source ref`, and `creates it rather than skipping creation`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-worktree-source-ref.sh`
Expected: `not ok` on the command needle, exit 1.

- [ ] **Step 3: Rewrite the skill**

Apply spec Component 5: the fallback command with `SOURCE_REF`; a rule that a caller may name a source ref and the native tool is used only when it accepts one; the sibling-worktree rule. Prose rules throughout.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-worktree-source-ref.sh && bash tests/toolbelt/test-worktree-baseline.sh && scripts/lint-shell.sh tests/toolbelt/test-worktree-source-ref.sh && wc -w skills/using-git-worktrees/SKILL.md`
Expected: exit 0; ≤ 910.

- [ ] **Step 5: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md tests/toolbelt/test-worktree-source-ref.sh
git commit -m "using-git-worktrees: caller-named source ref; plain language"
```

---

### Task 10: quick-task — prose rewrite

**Files:**
- Modify: `skills/quick-task/SKILL.md`

**Interfaces:**
- Consumes: spec Component 6
- Produces: none

**Gotchas:**
- Needles to keep (`test-quick-task.sh`): `name: quick-task`, `I'm using quick-task to ship this.`, `the ask itself is the spec`, `` use `brainstorming` and `writing-plans` ``, `never creates one to mirror a tiny local change`, `.toolbelt/quick/`, `one-task implementation plan`, `` Invoke `delivery` with the mini-plan path ``, `Delivery owns the worktree, routing, SDD, optional UX gate, PR, merge, and cleanup.`

- [ ] **Step 1: Rewrite**

Prose rules. The file is short; most sentences are pinned. Cut only what is not.

- [ ] **Step 2: Verify**

Run: `bash tests/toolbelt/test-quick-task.sh && wc -w skills/quick-task/SKILL.md`
Expected: exit 0; ≤ 200.

- [ ] **Step 3: Commit**

```bash
git add skills/quick-task/SKILL.md
git commit -m "quick-task: plain-language pass"
```

---

### Task 11: Integration — enforce word counts, full test run, version 7.9.0

**Files:**
- Modify: `tests/toolbelt/test-word-counts.sh`
- Modify: `package.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json` (via `scripts/bump-version.sh`)
- Modify: `RELEASE-NOTES.md`

**Interfaces:**
- Consumes: every track's rewritten files; `tests/toolbelt/test-word-counts.sh` from Task 1
- Produces: none

**Gotchas:**
- Its brief includes each merged track's `Decisions & drift risks` entries. Read them before running the suite; a track that reported an over-ceiling file with a reason is resolved here by raising that one ceiling to the reported count rounded up to 10, recorded in the commit message.
- `scripts/bump-version.sh --check` reports drift; the marketplace entry is at 7.7.0 today and the bump fixes it.
- The acceptance drill (CLAUDE.md "Verifying a change") is a human step: note it in the report, do not run it.

- [ ] **Step 1: Enforce the ceilings**

Remove the `ENFORCE` guard from `test-word-counts.sh` so any over-ceiling file fails the test.

- [ ] **Step 2: Run every test**

Run: `for t in tests/toolbelt/*.sh tests/hooks/*.sh; do bash "$t" >/dev/null || echo "FAIL $t"; done; echo done`
Expected: `done` with no `FAIL` lines.

- [ ] **Step 3: Bump the version and write the release note**

Run: `scripts/bump-version.sh 7.9.0 && scripts/bump-version.sh --check`
Expected: all four files report 7.9.0.

`RELEASE-NOTES.md`: add `## v7.9.0 (2026-09-01)` above v7.8.0, in the existing format, with one bullet per spec component (tracks by default and the task ceiling; conditional re-review and the fix-report table; PR chains in delivery; pr-monitor chain rules and the 20-minute timeout; worktree source ref; plain-language rewrite with word-count ceilings).

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-word-counts.sh && scripts/bump-version.sh --check`
Expected: exit 0; 7.9.0 in all four files.

- [ ] **Step 5: Commit**

```bash
git add tests/toolbelt/test-word-counts.sh package.json .claude-plugin .codex-plugin RELEASE-NOTES.md
git commit -m "chore: enforce word-count ceilings; release 7.9.0"
```
