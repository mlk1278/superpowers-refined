# Faster Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use toolbelt:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `docs/toolbelt/specs/2026-09-01-faster-delivery-design.md`: default execution tracks, a task size ceiling, a per-test RED step, conditional re-review, PR chains in delivery and pr-monitor, a worktree source ref, and a plain-language rewrite of the planning skills.

**Architecture:** Each task rewrites one or two skill files completely, applying the rule changes restated in the task and the prose rules in Global Constraints in one pass, and updates the tests that pin that file's text. Three tracks run concurrently over disjoint files after one mainline task. One integration task enforces the word-count test, runs the tests the tracks touched, and bumps the version.

**Tech Stack:** Markdown skills, bash tests under `tests/toolbelt/` (`assert_contains` / `assert_not_contains` / `assert_before` with `grep -F`), `scripts/lint-shell.sh` (ShellCheck), `scripts/bump-version.sh`.

## Global Constraints

Copied from the spec:

- Skills hard-code no consuming repository, review provider, or model. GitHub stays the supported PR host, as it is today. Per-project values live in `.toolbelt/pr-policy.md` and `.toolbelt/worktree-policy.md`.
- The forceful blocks (`<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags tables, rationalization lists) keep their wording except where a rule in this spec changes what they say.
- One skill names exactly one next skill. Handoff chains do not change.
- Every `tests/toolbelt/*.sh` assertion that a change makes false is updated in the same commit.
- Frontmatter descriptions do not change, except pr-monitor's (Task 8).
- Version bumps to 7.9.0 with `scripts/bump-version.sh 7.9.0`, verified by `scripts/bump-version.sh --check`.

Repository rules this plan adds:

- "Your human partner" stays. Never "the user" in skill text.
- `assert_no_model_names` in `test-delivery.sh`, `test-pr-monitor.sh`, and `test-quick-task.sh` fails on the regex `gpt-[0-9]|opus-|sonnet|haiku|-sol|Sol (high|medium|low)`.
- Codex `agents/openai.yaml` `short_description` is 25–64 bytes (`test-interactive-design.sh:35-40` enforces the contract for that skill; commit c7fd2ca applied it to all).
- Every test needle listed in a task's Gotchas is kept byte-identical, or that task changes the test in the same commit. Needles are matched with `grep -F`: backticks, asterisks, and em-dashes are literal.
- Prose rules (spec Component 7): one idea per sentence; imperative mood for instructions; say each rule once; delete restatements and rationales for the obvious; no metaphor or rhetorical framing; no intensifiers ("ruthlessly", "genuinely", "silently", "the whole point", "is the tell", "however independent they look"); keep every exact command, path, quoted user-facing message, and table verbatim unless a rule in the task changes it.
- Word-count ceilings are fixed. If a file cannot hold its mandated text under its ceiling, stop and report BLOCKED with the count. Do not cut a rule and do not raise the number.

| File | Ceiling |
|---|---|
| `skills/brainstorming/SKILL.md` | 740 |
| `skills/writing-specs/SKILL.md` | 420 |
| `skills/writing-plans/SKILL.md` | 2300 |
| `skills/subagent-driven-development/SKILL.md` | 2140 |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | 590 |
| `skills/subagent-driven-development/re-review-prompt.md` | 340 |
| `skills/dispatching-parallel-agents/SKILL.md` | 350 |
| `skills/using-git-worktrees/SKILL.md` | 910 |
| `skills/subagent-driven-development/implementer-prompt.md` | 400 |
| `skills/delivery/SKILL.md` | 940 |
| `skills/pr-monitor/SKILL.md` | 860 |
| `skills/quick-task/SKILL.md` | 200 |
| `docs/WORKFLOW.md` | 290 |

Amended during execution (orchestrator ruling, Tasks 2 and 4 BLOCKED): the 60% figure was computed without excluding fenced templates and tables, which the prose rules forbid changing. writing-plans (639 fixed words) is capped at 2300 (the task reviewer's independent rules-only estimate of ~2270, rounded up) and subagent-driven-development at 2140 (measured rules-only floor after two compression passes; the remaining 237 words are whole rules). pr-monitor is capped at 860: it gains the 214-word Chain rules section, so no-growth was wrong for it (measured faithful rewrite 852). Task 11 copies this table into the test.

## Known Gotchas

- **Tests run one file at a time:** `bash tests/toolbelt/<name>.sh`. There is no aggregate runner. New or changed shell tests also pass `scripts/lint-shell.sh tests/toolbelt/<name>.sh`.
- **`grep -Fq "$text"` without `--` breaks on a needle that starts with `-`.** `test-pr-monitor.sh` and `test-quick-task.sh` lack `--`; `test-delivery.sh` and `test-final-review-gate.sh` have it. Task 8 fixes pr-monitor's helper before adding `--force-with-lease`. New tests use `grep -Fq --`.
- **Needles containing `$` must be single-quoted** in the test, and the file gets `# shellcheck disable=SC2016` above that line, or ShellCheck fails the lint.
- **Edits here do not reach the running session.** Both harnesses install from a cached copy (CLAUDE.md, "Verifying a change"). Tests are the gate; the acceptance drill is a human step after Task 11.
- **`test-execution-tracks.sh` asserts on three files** across three tracks. Task 2 owns it. Tasks 4 and 9 keep its SDD and worktree needles byte-identical.
- **`docs/WORKFLOW.md` is asserted by `test-delivery.sh`**, so both belong to Task 7.

---

## PR Boundaries

| PR | Outcome | Tasks | Depends on | Independent verification |
|---|---|---|---|---|
| 1 | Toolbelt 7.9.0: faster delivery rules and plain-language planning skills | 1–11 | none | every `bash tests/toolbelt/*.sh` exits 0; `scripts/bump-version.sh --check` reports 7.9.0 everywhere |

One PR. The prose-only tasks (3, 6, 10) could stand alone. They are folded in because a docs-only PR round with its own monitor buys no verification the tests do not already give, and the release version must cover every file at once. The rule tasks (2, 4, 5, 7, 8, 9) cannot ship apart: writing-plans hands the whole plan to delivery, delivery's role table names SDD's orchestrator close, and delivery hands chains to pr-monitor, so a partial merge leaves contradictory handoffs live in the installed plugin.

## Execution Tracks

| Track | Tasks | Depends on | Files touched (summary) | Why safe |
|---|---|---|---|---|
| serial-1 | 1 | — | tests/toolbelt/test-word-counts.sh | mainline |
| planning | 2–3 | serial-1 | skills/writing-plans/SKILL.md, skills/brainstorming/SKILL.md, skills/writing-specs/SKILL.md, tests/toolbelt/test-writing-plans.sh, tests/toolbelt/test-execution-tracks.sh | disjoint from execution, shipping |
| execution | 4–6 | serial-1 | skills/subagent-driven-development/*.md, skills/dispatching-parallel-agents/SKILL.md, tests/toolbelt/test-final-review-gate.sh, tests/toolbelt/test-fix-loop.sh | disjoint from planning, shipping |
| shipping | 7–10 | serial-1 | skills/delivery/**, skills/pr-monitor/**, skills/using-git-worktrees/SKILL.md, skills/quick-task/SKILL.md, docs/WORKFLOW.md, tests/toolbelt/test-delivery.sh, tests/toolbelt/test-pr-monitor.sh, tests/toolbelt/test-chain-rebase.sh, tests/toolbelt/test-worktree-source-ref.sh | disjoint from planning, execution |
| serial-2 | 11 | planning, execution, shipping | tests/toolbelt/test-word-counts.sh, version files, RELEASE-NOTES.md | merge point |

No track consumes another track's `Produces:`. Task 2 and Task 4 both write the words `Produces: none`, each from the spec; neither reads the other's file. The spec is the frozen contract.

---

### Task 1: Word-count test, report-only

**Files:**
- Create: `tests/toolbelt/test-word-counts.sh`

**Interfaces:**
- Consumes: nothing
- Produces: `tests/toolbelt/test-word-counts.sh`, a `ceilings` table of `path:integer` pairs that Task 11 switches to enforcing

**Gotchas:**
- The test must not fail on mainline while tracks are in flight. Until Task 11 it prints and exits 0 unless `ENFORCE=1`.

- [ ] **Step 1: Write the test**

`set -euo pipefail`; `repo_root=$(git rev-parse --show-toplevel)`; a `ceilings` bash array of `path:integer` pairs, one per row of the Global Constraints table, in that order; a loop that reads `wc -w < "$repo_root/$path"`, prints `<count>/<ceiling> <path>`, and, when `ENFORCE=1`, prints `not ok - <path> exceeds ceiling` to stderr and exits 1 on the first count above its ceiling. Without `ENFORCE=1` it exits 0 after printing.

- [ ] **Step 2: Run it both ways**

Run: `bash tests/toolbelt/test-word-counts.sh`
Expected: 13 lines printed, exit 0.

Run: `ENFORCE=1 bash tests/toolbelt/test-word-counts.sh`
Expected: `not ok - skills/brainstorming/SKILL.md exceeds ceiling`, exit 1.

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
- Consumes: nothing
- Produces: none

**Gotchas:**
- Needles to keep (`test-writing-plans.sh`): `nearest instructions`, `` 2–3 targeted inline `rg` searches ``, `` agent-routing's `explorer` role ``, `completeness inventory`, `invisible trap`, `plan-shaping existence question`, `Start with one explorer`, `unfamiliar, independent subsystems`, `checkable paths and pointers`, `get wrong here?`, `An absence check must exclude its own evidence`, `A gotcha that is neither is a plan defect`, `## Known Gotchas`, `**Gotchas:**`, `## PR Boundaries`, `| PR | Outcome | Tasks | Depends on | Independent verification |`, `Every task number appears in exactly one boundary`, `why no smaller independently verifiable outcome exists`, `core plus one representative consumer`, `repeat the same reviewer judgment`, `Novel lifecycle, export, or rollout work stays separate`, `Coverage that leaves with the code`, `a precondition read from output the gated command itself produces`, `It may fan out its own explorers`, `**Unflagged gotchas**`, `**PR boundaries**`, `missing, horizontal, overlapping, or unjustified`. Must stay absent: `fan out explorers — one per surface the plan will touch`, `No need to re-review`.
- Needles to keep (`test-execution-tracks.sh`): `## Execution Tracks`, `No file is created or modified by two concurrent tracks`, `contract-freeze`, `Every fork closes with a mainline integration task`.
- Headings that keep their text: `## Exploration Before Drafting`, `## File Structure`, `## PR Boundaries`, `## Task Structure`, `## Execution Tracks`, `## Plan Review Gate`, `## Execution Handoff`.

**Rule changes (the contract; exact wording below is mandatory where quoted):**

1. Execution Tracks. Replace "Optional. ... Omit the section and the plan runs fully serial." with: the section is required for every plan with more than one PR boundary or more than three tasks; a plan whose tracks are all `serial-N` "states in one sentence why no tasks can run concurrently". Declaration rules, threshold, integration-task rule, and the cap of 3 are unchanged.
2. Self-Review item 6 and the Plan Review Gate tracks bullet: replace "reject bogus or missing track declarations as plan defects ... never with optimistic tracks" with: check the declaration rules; a plan whose tracks pass them is accepted; "a plan with no concurrent tracks and no one-sentence justification is a defect". A plan with no section and one PR boundary and three or fewer tasks is still valid.
3. Task Right-Sizing gains four rules: "A task's **Files:** block is closed" (it lists every file created or modified; "plus every caller", "compiler-led", "wherever else it is referenced" are placeholders and fail No Placeholders); "A task lists at most 8 files" as a hard limit, with about 400 lines of change as a guide the plan reviewer flags; the one exception is a mechanical sweep, one uniform behavior-neutral transformation with one verification command, marked "Mechanical sweep:" naming the command; a task that adds or changes a migration, shared schema, shared type, or shared contract owns the code that keeps it correct, fencing that code into a later task is a defect, and if the result exceeds 8 files it splits into serial tasks that each leave the contract correct.
4. Task Structure Step 2 becomes: `Run: <command>` then `Expected, per test:` then one line per test `- <test name> — FAIL: <reason>`. Add the rule: a guard or negative assertion (a permission check, a tenant filter, a rejection path) lists its red as the failure seen "when the guard is absent", not when the module is absent.
5. Task Structure `Produces:` line adds: write `Produces: none` when nothing downstream depends on this task.
6. Execution Handoff quotes: "Plan complete and saved to `docs/toolbelt/plans/<filename>.md`, reviewed through <reviewer harness>. Handing the plan to delivery." and says delivery owns boundary order. The REQUIRED SUB-SKILL line stays.

- [ ] **Step 1: Update the tests**

`test-writing-plans.sh`: replace the needle `one declared PR boundary at a time` with `Handing the plan to delivery`. Add `assert_contains` for: `states in one sentence why no tasks can run concurrently`, `A task's **Files:** block is closed`, `at most 8 files`, `Mechanical sweep:`, `Expected, per test:`, `when the guard is absent`, `Produces: none`.

`test-execution-tracks.sh`: replace `bogus or missing track declarations` with `a plan with no concurrent tracks and no one-sentence justification is a defect`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-writing-plans.sh; bash tests/toolbelt/test-execution-tracks.sh`
Expected: `not ok` on `Handing the plan to delivery` and on the replaced tracks needle, exit 1 each.

- [ ] **Step 3: Rewrite the skill**

Apply rule changes 1–6, then the prose rules from Global Constraints to the rest of the file.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-writing-plans.sh && bash tests/toolbelt/test-execution-tracks.sh && scripts/lint-shell.sh tests/toolbelt/test-writing-plans.sh tests/toolbelt/test-execution-tracks.sh && wc -w skills/writing-plans/SKILL.md`
Expected: exit 0; count ≤ 1880.

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
- Consumes: nothing
- Produces: none

**Gotchas:**
- Needles to keep (`test-interactive-design.sh`), brainstorming: `inside that skill is authorized`, `we could go frontend-first`, `The offer MUST be its own message`, `invoke it and no other`, `or to interactive-design when they accepted`. writing-specs: `Arriving from interactive-design with a reconciled contract ledger`.
- Verbatim: `<HARD-GATE>` and `<ENTRY-GATE>` blocks; the frontend-first offer, its Claude Design variant, the visual companion offer; the writing-specs user-review message; every checklist item and terminal-state line; every next-skill name.
- No rule changes.

- [ ] **Step 1: Confirm the current test passes**

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
- Consumes: nothing
- Produces: `tests/toolbelt/test-fix-loop.sh` with helpers `assert_contains FILE TEXT DESCRIPTION` and `assert_not_contains FILE TEXT DESCRIPTION` (file-parameterized, `grep -Fq --`), which Task 5 extends

**Gotchas:**
- Needles to keep (`test-final-review-gate.sh`): `plan route, then project route, then the session routing brief`, `do not substitute your own judgment for a missing route`, `If the caller supplies a pre-final gate, run it after all task reviews and before the broad final review.`, `` scripts/review-package --plan PLAN_FILE MERGE_BASE HEAD` for the final review ``, `**Final-review findings get ONE fix subagent**`, `with the complete list — not one fixer per finding.`, `contains the covering tests, the command, and the output`, `read the implementer's test evidence on unchanged source instead of re-running it`, `Implementers and fixers always produce their own fresh evidence`, `**Workspace-wide suite:** once, at the final gate.`, `Then run exactly one scoped re-review of the fix wave`, `There is no second fix wave`, `**One fix round per task.**`, `Adjudicate **only** after the re-review`, `out-of-scope observations go to the ledger as deferred minors and never extend the loop`, `it never carries a check that gates that command`. Must stay absent: `### Final whole-branch gate`, `REVIEW_HEAD=$(git rev-parse HEAD)`, `approved SHA`, `After any compaction or resume`.
- Needles to keep (`test-reviewer-context.sh`): `Do not read it`, `while orchestrating or pass it to implementers, fixers, explorers, planners,`, `` Use `None` when there is none. ``.
- Needles to keep (`test-execution-tracks.sh`): `## Parallel Tracks`, `At most 3 tracks run concurrently`, `## Decisions & drift risks`, `A textual conflict is a plan defect`, `Dispatch multiple implementation subagents into the same worktree`, `Parallelize tracks the plan did not declare`. Must stay absent: `Dispatch multiple implementation subagents in parallel (conflicts)`.
- `Adjudicate **only** after the re-review` stays as a sentence; add that orchestrator close is the other exit and adjudication applies after either.
- Red Flags block and Parallel Tracks section: verbatim.

**Rule changes (the contract):**

1. The Fix Loop: replace the paragraph starting "The round ends with a scoped re-review" with two exits. **Re-review** "when the task's `Interfaces: Produces:` block is non-empty" (a later task builds on this one) "or when any open finding was Critical": dispatch the scoped re-review as today (`scripts/review-package --plan PLAN_FILE FIX_BASE HEAD`, re-review-prompt.md, ADDRESSED / NOT ADDRESSED verdicts, new breakage in the fix diff only). The plan template writes `Produces: none` when nothing downstream depends on the task. **Orchestrator close** otherwise: read the fix report's findings table; every row must name the finding, the commit, the covering test command, and its passing output; if every row is complete, mark the task complete; if a row is missing or its result is a claim without the command's output, resume the implementer once for that row; if still incomplete, "escalate to your human partner as a BLOCKED task". Ledger line: `Task <N>: fix round closed by orchestrator (<X> findings, commits <a7>..<b7>)`. The existing re-review ledger line stays for the re-review exit.
2. Durable Progress task lines: in-progress `Task N: in-progress (agent <id>, route <harness>/<model>/<effort>)`; complete `Task N: complete (commits <base7>..<head7>, review clean, route <harness>/<model>/<effort>, report <path>)`. The route is the resolved one from agent-routing, copied from the dispatch.

- [ ] **Step 1: Write the test**

`tests/toolbelt/test-fix-loop.sh`: helpers as in Produces; `sdd="$repo_root/skills/subagent-driven-development/SKILL.md"`. Assert the SDD skill contains: `` when the task's `Interfaces: Produces:` block is non-empty ``, `or when any open finding was Critical`, `**Orchestrator close**`, `Task <N>: fix round closed by orchestrator`, `escalate to your human partner as a BLOCKED task`, `Task N: in-progress (agent <id>, route <harness>/<model>/<effort>)`, `route <harness>/<model>/<effort>, report <path>`, `Produces: none`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-fix-loop.sh`
Expected: `not ok` on the first needle, exit 1.

- [ ] **Step 3: Rewrite the skill**

Apply rule changes 1–2, then the prose rules to the rest of the file.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-fix-loop.sh && bash tests/toolbelt/test-final-review-gate.sh && bash tests/toolbelt/test-reviewer-context.sh && bash tests/toolbelt/test-execution-tracks.sh && scripts/lint-shell.sh tests/toolbelt/test-fix-loop.sh && wc -w skills/subagent-driven-development/SKILL.md`
Expected: all exit 0; count ≤ 1760.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md tests/toolbelt/test-fix-loop.sh tests/toolbelt/test-final-review-gate.sh
git commit -m "sdd: conditional re-review, orchestrator close, route in ledger, plain language"
```

---

### Task 5: SDD prompt templates — guard-absent seen-red, fix-report table, out-of-scope line

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/re-review-prompt.md`
- Modify: `tests/toolbelt/test-fix-loop.sh`

**Interfaces:**
- Consumes: `tests/toolbelt/test-fix-loop.sh` helpers from Task 4
- Produces: none

**Gotchas:**
- Needles to keep (`test-reviewer-context.sh`), task-reviewer-prompt: `This read is an explicit exception to the limits on`, `docs/REVIEW-GUIDANCE.md`, `This file is reviewer-only.`, `[REVIEW_NUANCE]`, `does not override requirements,`, `[SMELLS_FILE]`. implementer-prompt must not contain `docs/REVIEW-GUIDANCE.md` or `smell-baseline`.
- The implementer template's Status tokens (DONE, DONE_WITH_CONCERNS, BLOCKED, NEEDS_CONTEXT), the "under 15 lines" rule, and the report-file contract stay.

**Rule changes (the contract):**

1. implementer-prompt seen-red paragraph becomes: "A guard or negative assertion counts only when you have seen it fail against code that lacks the guard, not against a missing module. Report the command and the failing output in TDD Evidence, one line per guard." The TDD Evidence bullet adds "for each guard, the seen-red command and output."
2. implementer-prompt "After Review Findings" gains the required table `| Finding | Commit | Covering test command | Result |` with a header separator row, and the sentence: `Result` is the command's last passing line, pasted.
3. re-review-prompt gains the line: findings "outside the fix diff go to the ledger and never extend the loop".

- [ ] **Step 1: Extend the test**

Append to `test-fix-loop.sh`: `implementer="$repo_root/skills/subagent-driven-development/implementer-prompt.md"`, `rereview="$repo_root/skills/subagent-driven-development/re-review-prompt.md"`; assert implementer contains `against code that lacks the guard` and `| Finding | Commit | Covering test command | Result |`; assert rereview contains `outside the fix diff go to the ledger and never extend the loop`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-fix-loop.sh`
Expected: `not ok` on `against code that lacks the guard`, exit 1.

- [ ] **Step 3: Rewrite the three templates**

Apply rule changes 1–3, then the prose rules.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-fix-loop.sh && bash tests/toolbelt/test-reviewer-context.sh && scripts/lint-shell.sh tests/toolbelt/test-fix-loop.sh && wc -w skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/task-reviewer-prompt.md skills/subagent-driven-development/re-review-prompt.md`
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
- Consumes: nothing
- Produces: none

**Gotchas:**
- No test pins this file. Keep the "Don't use when" bullet that sends plan-task parallelism to subagent-driven-development's Execution Tracks. Keep the example prompt block and the Common Mistakes pairs.

- [ ] **Step 1: Rewrite**

Prose rules from Global Constraints.

- [ ] **Step 2: Verify**

Run: `wc -w skills/dispatching-parallel-agents/SKILL.md`
Expected: ≤ 350.

- [ ] **Step 3: Commit**

```bash
git add skills/dispatching-parallel-agents/SKILL.md
git commit -m "dispatching-parallel-agents: plain-language rewrite"
```

---

### Task 7: delivery — boundary loop, PR chains, ownership by publication, WORKFLOW.md

**Files:**
- Modify: `skills/delivery/SKILL.md`
- Modify: `skills/delivery/agents/openai.yaml`
- Modify: `docs/WORKFLOW.md`
- Modify: `tests/toolbelt/test-delivery.sh`

**Interfaces:**
- Consumes: nothing
- Produces: none

**Gotchas:**
- Needles to keep (`test-delivery.sh`, skill): `name: delivery`, `Use when an approved implementation plan is ready to be implemented and shipped`, `I'm using delivery to deliver this approved plan.`, `one coherent delivery slice`, `## Agent Routing`, `plan route, then project route, then bundled default`, `session agent remains the orchestrator`, `toolbelt:using-git-worktrees`, `toolbelt:subagent-driven-development`, `ux-gate`, `broad final review is the slice gate`, `toolbelt:finishing-a-development-branch`, `pr-monitor`, `run it in the background`, `Never report the slice complete or end the session while the monitor runs`, `always before that lane's broad final review`, `Reconcile the issue tracker only when the plan is linked to one`, `remove the worktree, branch, and ignored scratch`, `run concurrently and that edit the same files are one PR`, `Sequential slices may revisit the same file once the first has merged`, `is not grounds to start a second one`, `check that state directly`, `never commit ancestry`, `A completion notification is not that return`. Must stay absent: `workstack-slice-gate`, `progress ledger`. Order (`assert_before`): `ux-gate` before `broad final review is the slice gate` before `toolbelt:finishing-a-development-branch`. `assert_no_model_names` runs on the skill. `openai.yaml` must contain `display_name`.
- Needles to keep (`test-delivery.sh`, `docs/WORKFLOW.md`): `` `brainstorming` and `writing-plans` ``, `one coherent delivery slice`, `## Agent Routing`, `implementation report and review-package path`, `without independently rereading the implementation or verification output`, `No separate resume state machine`. Must stay absent: `workstack-resume`.
- Needles that change: `The next work is independent` (deleted from test), `At most one PR is in background monitoring` (becomes an absence check), WORKFLOW.md `one monitored PR at a time` → `one pr-monitor per chain`.
- `openai.yaml` `short_description`: `Deliver an approved plan through PR chains to merge` (51 bytes).

**Rule changes (the contract):**

1. Entry: an approved implementation plan. Exit: every PR boundary merged, reconciled when applicable, and cleaned up.
2. Step 1: delivery runs a loop over the plan's `## PR Boundaries` table in order. For each boundary it runs Steps 2–5. The slice definition paragraph (containing `one coherent delivery slice`, `run concurrently and that edit the same files are one PR`, `Sequential slices may revisit the same file once the first has merged`) stays.
3. Step 5 replaces the bulleted wait conditions with: after the boundary's broad final review is clean and its PR is open, start the next boundary immediately. Dependent boundary (its `Depends on` names a boundary whose PR is open and unmerged): fetch the predecessor's remote head, create the worktree from that SHA with toolbelt:using-git-worktrees naming it as the source ref, and open its PR against the predecessor's branch; this is a manual PR chain and does not depend on GitHub's native stack feature. Independent boundary: worktree from the base branch, PR against the base branch. Branch names are `<plan-slug>/pr-<N>` (`<plan-slug>` = plan file basename without date and extension, `<N>` = boundary number). The SDD ledger records one line per boundary: `Boundary <N>: branch <name>, PR #<num>, base <branch>, state <open|merged|blocked>`. Any number of boundaries may be open. Each chain has exactly one pr-monitor, started when its bottom PR opens; when a dependent boundary's PR opens, delivery resumes that chain's monitor with the new layer's number, branch, and head. An independent boundary starts its own chain. Delete "Dependent work waits for the merge — no stacked branches" and the "At most one PR is in background monitoring" bullet. Keep: `run it in the background`, the monitor-tracking rules (`Never report the slice complete or end the session while the monitor runs`, `A completion notification is not that return`, `is not grounds to start a second one`, `check that state directly`).
4. New paragraph "Who rebases": "Ownership follows publication." Delivery owns a boundary's branch until its PR opens; when a lower PR's branch moves, delivery rebases the unpublished branch at its next task boundary, `always before that lane's broad final review`, and appends `Boundary <N>: rebased <old7> → <new7>` to the ledger. Once the PR is open, only the monitor moves the branch. Implementers and fixers never rebase.
5. Step 6 runs once per merged boundary, when the monitor returns that layer merged. Error handling: a chain whose bottom PR closed without merging comes back from the monitor as `CLOSED` plus a durable blocker for every layer above; delivery surfaces it to your human partner and does not open further boundaries in that chain.
6. Role table: pr-monitor row reads "GitHub review, exact-head CI, fix loops, rebases and retargets of published branches, merge, for one PR chain." Orchestrator row adds "reads fix-report tables to close a fix round (SDD orchestrator close); never re-reads test output beyond that table."
7. `docs/WORKFLOW.md` delivery paragraph: boundaries run as PR chains; one pr-monitor per chain; unpublished lanes rebase at task boundaries before their final review. Keep every needle listed above.

- [ ] **Step 1: Update the test**

`test-delivery.sh`: delete the `The next work is independent` and `At most one PR is in background monitoring` assertions; add `assert_not_contains "$skill" "no stacked branches" ...`, `assert_not_contains "$skill" "At most one PR" ...`; add `assert_contains "$skill"` for `<plan-slug>/pr-<N>`, `Boundary <N>: branch`, `exactly one pr-monitor`, `Ownership follows publication`, `Boundary <N>: rebased`; replace the workflow needle `one monitored PR at a time` with `one pr-monitor per chain`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-delivery.sh`
Expected: `not ok` on `<plan-slug>/pr-<N>`, exit 1.

- [ ] **Step 3: Rewrite the skill, metadata, and WORKFLOW.md**

Apply rule changes 1–7, then the prose rules.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-delivery.sh && scripts/lint-shell.sh tests/toolbelt/test-delivery.sh && wc -w skills/delivery/SKILL.md docs/WORKFLOW.md`
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
- Consumes: nothing
- Produces: none

**Gotchas:**
- Needles to keep (`test-pr-monitor.sh`): `name: pr-monitor`, `sole source of PR review, CI, fix-loop, and merge mechanics`, `.toolbelt/pr-policy.md`, `exact-head green CI, zero unresolved review threads, and no requested-changes review`, `Never hard-code a provider this file does not name.`, `The local final gate must have approved this exact head before monitoring begins.`, `Bind all evidence to the current head`, `at most once per head request each policy-named provider`, `fail closed on unavailable`, `Once every awaited provider has completed on the current head`, `judge it yourself`, `fix what is real inline`, `Push all fixes as one batch`, `next round on the new head is the re-review`, `drops out of the awaited set for that head`, `Record the fallback reason`, `` confirm the remote PR is `MERGED` ``, `The caller owns post-merge reconciliation.`, `Do not nest another watcher.`, `genuinely entangled`, `the policy file decides whether a recorded fallback blocks`, `in the PR body before merging`. `assert_no_model_names` runs on the skill; `openai.yaml` must contain `display_name`.
- `genuinely entangled` is pinned and stays despite the intensifier rule.
- Needle that changes: `Own exactly one PR` → `Own one chain`.
- `test-pr-monitor.sh`'s helper is `grep -Fq "$text"`; change it to `grep -Fq -- "$text"` before adding `--force-with-lease`.
- `openai.yaml` `short_description`: `Own a PR chain through CI, review, fixes, and merge` (51 bytes).
- `test-chain-rebase.sh` uses git only: `tmp=$(mktemp -d)`, `git -C "$tmp" init -q -b main`, identity via `-c user.name=t -c user.email=t@t` on every commit, `trap 'rm -rf "$tmp"' EXIT`.

**Rule changes (the contract):**

1. Description: "Own one pull request, or a chain of dependent pull requests, from current heads through CI, configured review providers, fix loops, rebases, and merge or a durable blocker. Internal helper started by delivery after a PR opens."
2. Opening paragraph: "Own one chain: one PR, or PRs each targeting the one below it." Preflight records every layer's number, branch, head SHA, base branch, and local-gate SHA. A resume carrying a new layer appends it to the chain. The sole-source sentence stays.
3. New section `## Chain rules` with four bolded rules: **Lowest first.** The lowest unmerged PR gets all attention until it merges; review threads on higher layers are read and batched, never fixed while the bottom is not merge-ready. **Fix in the owner.** A finding lands in the lowest PR whose diff contains the code; after pushing it, rebase every layer above with `git rebase --onto <owner-head> <old-owner-head> <layer-branch>` and push each with `--force-with-lease`; every rebased head starts a new evidence cycle (exact-head CI, provider review, mergeability, threads); local review repeats only when a layer's `git patch-id --stable` changed. **One topology writer.** Only the monitor rebases, retargets, or force-pushes a published branch. **Merge bottom-up.** Squash-merge the bottom layer and delete its branch; GitHub then retargets the next layer to the deleted branch's base; confirm with `gh pr view --json baseRefName` and set it with `gh pr edit --base` if it did not happen; rebase the next layer with `git rebase --onto <base-branch> <merged-layer-old-head> <layer-branch>` so the squashed commits are not replayed; push with `--force-with-lease`; re-run the merge preflight; continue; stop at the first layer that is not merge-ready and keep monitoring it.
4. Error handling: a rebase conflict stops the operation, `git rebase --abort` leaves the branch as it was, and the layer returns as blocked with the conflicting paths. A bottom PR closed without merging returns `CLOSED` for it and a durable blocker for every layer above.
5. Fallback: "default 20 minutes" replaces 60; `.toolbelt/pr-policy.md` overrides in either direction.
6. Return, per layer: PR number, final head SHA, remote state (`MERGED`, `OPEN`, `CLOSED`), merge commit OID when merged, target branch, blocker reason when not merged. Lower layers that merged before a higher layer blocked appear as `MERGED` with their OIDs.

- [ ] **Step 1: Update and write the tests**

`test-pr-monitor.sh`: change the helper to `grep -Fq -- "$text"`; replace `Own exactly one PR` with `Own one chain`; add `assert_contains` for `## Chain rules`, `**Lowest first.**`, `**Fix in the owner.**`, `**One topology writer.**`, `**Merge bottom-up.**`, `--force-with-lease`, `git patch-id --stable`, `gh pr edit --base`, `git rebase --abort`, `default 20 minutes`.

`test-chain-rebase.sh`: in the temp repo, commit `base.txt` on main; branch `pr-1`, commit `one.txt`; branch `pr-2` from pr-1, commit `two.txt`; record `old=$(git rev-parse pr-1)`; on main run `git merge --squash pr-1` and commit; run `git rebase --onto main "$old" pr-2`; assert `git rev-list --count main..pr-2` prints `1` and `git ls-tree --name-only pr-2` lists `base.txt`, `one.txt`, `two.txt`. Print `ok - chain rebase recipe` on success.

- [ ] **Step 2: Run tests to verify they fail / pass**

Run: `bash tests/toolbelt/test-pr-monitor.sh`
Expected: `not ok - ... Own one chain`, exit 1.

Run: `bash tests/toolbelt/test-chain-rebase.sh`
Expected: `ok - chain rebase recipe`, exit 0. It tests git, not the skill, and must pass before the skill quotes the recipe.

- [ ] **Step 3: Rewrite the skill and metadata**

Apply rule changes 1–6, then the prose rules.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-pr-monitor.sh && bash tests/toolbelt/test-chain-rebase.sh && scripts/lint-shell.sh tests/toolbelt/test-pr-monitor.sh tests/toolbelt/test-chain-rebase.sh && wc -w skills/pr-monitor/SKILL.md`
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
- Consumes: nothing
- Produces: none

**Gotchas:**
- Needles to keep (`test-worktree-baseline.sh`): `smallest focused checks that prove a clean start`, `not a workspace or package-wide`, `cite that instead of re-running`, `docs-only work`, `Baseline: <focused tests passing`, `Satisfy Step 3 now`, `.toolbelt/worktree-policy.md`, `non-conflicting`. (`test-execution-tracks.sh`): `parallel-workspace rules`, `concurrency limit lower than 3`.
- The rationalization table, the native-tool-first rule, and the sandbox fallback paragraph stay verbatim.
- The command needle contains `$path`, `$BRANCH_NAME`, `${SOURCE_REF:-HEAD}`: single-quote it in the test and put `# shellcheck disable=SC2016` on the line above; use `grep -Fq --`.

**Rule changes (the contract):**

1. The fallback command becomes `git worktree add "$path" -b "$BRANCH_NAME" "${SOURCE_REF:-HEAD}"`.
2. New rule: a caller may name a source ref (a SHA or branch the new worktree starts from). When one is named, use the native tool only if it accepts a source ref; otherwise run the fallback command. When the session is already in a linked worktree and the caller asks for a new sibling, the skill "creates it rather than skipping creation".
3. Sandbox denial with a source ref: the existing fallback (work in place) and report, unchanged.

- [ ] **Step 1: Write the test**

`test-worktree-source-ref.sh`: `assert_contains` helper with `grep -Fq --`; assert the skill contains the exact fallback command from rule 1, `source ref`, and `creates it rather than skipping creation`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/toolbelt/test-worktree-source-ref.sh`
Expected: `not ok` on the command needle, exit 1.

- [ ] **Step 3: Rewrite the skill**

Apply rule changes 1–3, then the prose rules.

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
- Consumes: nothing
- Produces: none

**Gotchas:**
- Needles to keep (`test-quick-task.sh`): `name: quick-task`, `I'm using quick-task to ship this.`, `the ask itself is the spec`, `` use `brainstorming` and `writing-plans` ``, `never creates one to mirror a tiny local change`, `.toolbelt/quick/`, `one-task implementation plan`, `` Invoke `delivery` with the mini-plan path ``, `Delivery owns the worktree, routing, SDD, optional UX gate, PR, merge, and cleanup.`
- Heading order (`assert_before`): `## 1. Scope check` before `## 2. Mini-plan` before `## 3. Deliver`.
- Must stay absent (regex): `workstack-(start|resume|spec-review|slice-gate)`, `## Global Constraints`, `toolbelt:subagent-driven-development`, `toolbelt:finishing-a-development-branch`, `pr-monitor`, `ux-gate`. `assert_no_model_names` runs on the skill.

- [ ] **Step 1: Rewrite**

Prose rules. Most sentences are pinned; cut only what is not.

- [ ] **Step 2: Verify**

Run: `bash tests/toolbelt/test-quick-task.sh && wc -w skills/quick-task/SKILL.md`
Expected: exit 0; ≤ 200.

- [ ] **Step 3: Commit**

```bash
git add skills/quick-task/SKILL.md
git commit -m "quick-task: plain-language pass"
```

---

### Task 11: Integration — enforce word counts, run the touched tests, version 7.9.0

**Files:**
- Modify: `tests/toolbelt/test-word-counts.sh`
- Modify: `package.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json` (via `scripts/bump-version.sh`)
- Modify: `RELEASE-NOTES.md`

**Interfaces:**
- Consumes: every track's rewritten files; `tests/toolbelt/test-word-counts.sh` from Task 1
- Produces: none

**Gotchas:**
- Its brief includes each merged track's `Decisions & drift risks` entries. Read them first. A track that reported an over-ceiling file was BLOCKED under Global Constraints and will not have merged; if one did, stop and report.
- `scripts/bump-version.sh --check` reports drift; the marketplace entry is at 7.7.0 today and the bump fixes it.
- The acceptance drill (CLAUDE.md "Verifying a change") is a human step: note it in the report, do not run it.
- Integration scope is the tests whose asserted files the tracks changed, listed in Step 2. The full `tests/` and `tests/hooks/` run belongs to the final branch gate, not here.

- [ ] **Step 1: Enforce the ceilings**

Remove the `ENFORCE` guard from `test-word-counts.sh` so any over-ceiling file fails the test.

- [ ] **Step 2: Run the touched tests**

Run:
```bash
for t in test-word-counts test-writing-plans test-execution-tracks test-interactive-design test-fix-loop test-final-review-gate test-reviewer-context test-delivery test-pr-monitor test-chain-rebase test-worktree-source-ref test-worktree-baseline test-quick-task test-claude-agent-definitions; do bash "tests/toolbelt/$t.sh" >/dev/null || { echo "FAIL $t"; exit 1; }; done && scripts/lint-shell.sh tests/toolbelt/test-word-counts.sh && echo ALL-OK
```
Expected: `ALL-OK`, exit 0.

- [ ] **Step 3: Bump the version and write the release note**

Run: `scripts/bump-version.sh 7.9.0 && scripts/bump-version.sh --check`
Expected: all four files report 7.9.0.

`RELEASE-NOTES.md`: add `## v7.9.0 (2026-09-01)` above v7.8.0, in the existing format, with one bullet per change: tracks by default and the 8-file task ceiling; per-test RED and guard-absent seen-red; conditional re-review with orchestrator close and the fix-report table; PR chains in delivery with ownership by publication; pr-monitor chain rules and the 20-minute provider timeout; worktree source ref; plain-language rewrite with word-count ceilings.

- [ ] **Step 4: Verify**

Run: `bash tests/toolbelt/test-word-counts.sh && scripts/bump-version.sh --check`
Expected: exit 0; 7.9.0 in all four files.

- [ ] **Step 5: Commit**

```bash
git add tests/toolbelt/test-word-counts.sh package.json .claude-plugin .codex-plugin RELEASE-NOTES.md
git commit -m "chore: enforce word-count ceilings; release 7.9.0"
```
