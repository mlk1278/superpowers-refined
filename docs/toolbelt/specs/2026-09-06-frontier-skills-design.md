# Frontier Skills Design

**Status:** Approved in conversation on 2026-09-06 after three Fable 5.1
research passes (skill unslopping, visual verification, review cadence).
Research reports and the project observations they drew on are summarised in
Background; the reports themselves are session scratch and not committed.

Three changes to the toolbelt, shipped as one release, 8.0.0:

1. Rewrite every skill for frontier models: plain imperatives, the reason
   once, forceful blocks only where a failure is expensive. About 27,000
   words become about 16,500.
2. Make the UX gate catch visual glitches and design misses: mechanical
   checks first, pixel diff against a baseline, a per-task smoke pass by the
   implementer, and a two-pass vision review that is allowed to judge design
   against the project's design system.
3. Review by risk, not by task: contract and risk-class tasks keep an
   immediate reviewer; the rest self-check with evidence and batch to gates
   reviewed by one top-tier cross-harness reviewer.

## Background

The owner's recent skill runs repeated instructions, spent too much time
verifying unchanged work, and missed visible frontend defects. The observed
UX problems included unfinished controls, truncated labels, inconsistent
loading states, mixed component styles, incorrect focus colours, and unclear
action hierarchy. Project design rules and existing capture notes were not
being supplied to the reviewer.

The earlier research reports were session scratch and are not available in
this repository. Their numerical claims about model behaviour, compaction,
and review accuracy are not requirements or validated benchmarks. This
change is based on the observed workflow problems above; its tests must
establish whether the revised instructions and capture process address them.

## Constraints

- Skills hard-code no consuming repository, provider, or model. Model names
  appear only in `skills/agent-routing/defaults.json` and agent
  definitions. Per-project values live under `.toolbelt/`.
- One skill names exactly one next skill. Handoff chains do not change.
- "Your human partner" stays.
- No new npm dependencies in the plugin. The capture script resolves
  `playwright` from `PLAYWRIGHT_MODULE` when set, else from the consuming
  project's root (`--project-root`, default the working directory), and
  fails with a one-line instruction and exit 2 when neither resolves. There
  is no global-install lookup.
- No paid products. Video is a local Playwright recording, off by default.
- Every `tests/toolbelt/*.sh` and `tests/hooks/*` assertion a change makes
  false is updated in the same commit. The Testing section lists the known
  ones.
- Frontmatter descriptions change only where this spec says so
  (brainstorming, ux-gate, verification-before-completion,
  receiving-code-review).
- Version bumps to 8.0.0 with `scripts/bump-version.sh 8.0.0`, verified by
  `scripts/bump-version.sh --check`.

## Component 1: Doctrine

Changed before any skill is rewritten, because the rewrite is done under it.

### `CLAUDE.md`

The bullet "Preserve forceful blocks verbatim" becomes:

> **Forceful blocks are gates, not decoration.** `<HARD-GATE>` and
> `<ENTRY-GATE>` mark a step whose failure is expensive or irreversible.
> Keep them to two or three sentences: the condition, who owns the
> exception, and why. Rationalization tables exist only where a brief
> instruction measurably failed under pressure; today that is
> test-driven-development alone. Re-test them when the model changes.

The bullet "Keep them short" gains one sentence: "Keep the instructions needed for the current task easy to find after compaction."

### `skills/writing-for-agents/SKILL.md`

Rewritten to at most 750 words as rules with one example each. Keeps, in
this order: context pointers (description wording decides triggering;
front-load the trigger; one trigger per branch); the two loads; the
information hierarchy and progressive disclosure (inline what every branch
needs, disclose what only some reach); completion criteria (checkable and
exhaustive); split by sequence or by invocation; leading words and
positive-over-prohibition; pruning (single source of truth, the
environment as a source of truth, relevance, the no-op test settled by
running the document).

The final bullet becomes:

> A gate earns forceful phrasing only where the failure is expensive or
> irreversible and a brief instruction measurably failed. Keep such blocks
> short, and re-test them when the model changes.

The coined-term glossary (context pointer, legwork, sediment, cache, sprawl
as named concepts) is dropped; each idea is stated once in plain words.
`SKILL-MECHANICS.md` is unchanged.

### `skills/writing-skills/SKILL.md`

At most 1,000 words. Changes:

- The Iron Law block, its "No exceptions" list, "Untested skills have
  issues. Always.", "Overconfidence guarantees issues", and "IMPORTANT:
  Create a todo for EACH item" are removed. The scope rule (new
  behaviour-shaping guidance needs a baseline; editing existing guidance
  does not) stays as one paragraph.
- "Match the Form to the Failure" stays whole, including the table and the
  wording-test evidence.
- "Bulletproofing Against Rationalization" opens with: "Use this only after
  a baseline shows the agent skipping a known rule under pressure and a
  brief instruction has failed to stop it. Frontier models overtrigger on
  aggressive phrasing; the default form is one sentence stating the rule
  and its reason." The four techniques stay, each one sentence. The
  "letter of the rules" block is removed.
- "The Description Field" keeps the rule and its one-line reason ("a
  description that summarised the workflow caused one review instead of
  two") and drops the five-example block to two examples, one wrong and one
  right.
- RED-GREEN-REFACTOR, Micro-Testing Wording, Testing by Skill Type, the
  rationalization table for skipping testing, and the Checklist move into
  `testing-skills-with-subagents.md` under matching headings; SKILL.md
  keeps a two-sentence pointer.

## Component 2: The unslop pass

Applies to every file in the table. Rules for the rewrite:

- Plain imperatives. State the goal, the constraint, and the reason once.
- Keep every gate condition, exact command, exact path, exact file
  contract, ledger line format, handoff line, quoted user-facing message,
  and table, unless a component of this spec changes it.
- Remove: `<EXTREMELY-IMPORTANT>`; "Violating the letter of the rules is
  violating the spirit"; threat language ("lying", "you'll be replaced");
  Red Flags lists and rationalization tables except where the table below
  keeps one; "Common Mistakes", "Never/Always", and "Quick Reference"
  sections that restate steps; example transcripts; ALL-CAPS pseudo-code;
  "IMPORTANT:", "MUST", and "ALWAYS" as emphasis.
- `<HARD-GATE>` and `<ENTRY-GATE>` tags stay, shrunk to two or three
  sentences each.
- Descriptions do not shout. brainstorming's becomes: "Use before creating
  features, building components, adding functionality, or changing
  behaviour. Explores intent, requirements, and design before
  implementation."
- Before rewriting a file, list the lines `tests/toolbelt/*.sh` and
  `tests/hooks/*` assert on for that file; keep them verbatim or change the
  test in the same commit.

Word ceilings, enforced by `tests/toolbelt/test-word-counts.sh`:

| File | Today | Ceiling |
|---|---|---|
| `skills/using-toolbelt/SKILL.md` | 535 | 300 |
| `skills/verification-before-completion/SKILL.md` | 811 | 300 |
| `skills/receiving-code-review/SKILL.md` | 801 | 300 |
| `skills/writing-skills/SKILL.md` | 2211 | 1000 |
| `skills/writing-for-agents/SKILL.md` | 1618 | 750 |
| `skills/systematic-debugging/SKILL.md` | 1122 | 600 |
| `skills/test-driven-development/SKILL.md` | 1127 | 600 |
| `skills/brainstorming/SKILL.md` | 1019 | 650 |
| `skills/finishing-a-development-branch/SKILL.md` | 1389 | 850 |
| `skills/using-git-worktrees/SKILL.md` | 1259 | 750 |
| `skills/dispatching-parallel-agents/SKILL.md` | 503 | 320 |
| `skills/requesting-code-review/SKILL.md` | 584 | 350 |
| `skills/requesting-code-review/code-reviewer.md` | 622 | 500 |
| `skills/interactive-design/SKILL.md` | 1705 | 1200 |
| `skills/subagent-driven-development/SKILL.md` | 2138 | 1900 |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | 851 | 650 |
| `skills/subagent-driven-development/implementer-prompt.md` | 397 | 550 |
| `skills/subagent-driven-development/re-review-prompt.md` | 418 | 420 |
| `skills/subagent-driven-development/gate-reviewer-prompt.md` | new | 700 |
| `skills/writing-plans/SKILL.md` | 2289 | 1900 |
| `skills/ux-gate/SKILL.md` | 742 | 950 |
| `skills/ux-gate/matrix.md` | new | 750 |
| `skills/writing-specs/SKILL.md` | 648 | 550 |
| `skills/delivery/SKILL.md` | 936 | 900 |
| `skills/pr-monitor/SKILL.md` | 856 | 850 |
| `skills/agent-routing/SKILL.md` | 834 | 800 |
| `skills/quick-task/SKILL.md` | 194 | 200 |
| `docs/WORKFLOW.md` | 290 | 320 |
| `skills/writing-plans/execution-tracks.md` | new | 360 |
| `skills/subagent-driven-development/parallel-tracks.md` | new | 420 |
| `skills/interactive-design/iteration-mode.md` | new | 500 |
| `skills/writing-skills/testing-skills-with-subagents.md` | 2447 | 1800 |

Ceilings above today's count are files that gain rules from Components 3
and 4. The pass is a rewrite for those files, not an exemption. The four
disclosed side files carry ceilings so disclosure cannot become an escape
hatch from the table; a later disclosure adds a row in the same commit.

### Per-file keep lists

Each file keeps the items named here; everything else is subject to the
rules above.

- **using-toolbelt.** `<SUBAGENT-STOP>`; invoke a relevant skill before any
  response, including clarifying questions, with the reason (the skill sets
  the approach); brainstorming before plan mode; process skills before
  implementation skills; agent-routing before the first dispatch, fail
  closed; the Codex pointer to `references/codex-tools.md`; user
  instructions outrank skills. The 12-row Red Flags table is replaced by
  one sentence: "A question, a file check, or a small task is still a task;
  check for a skill first."
- **verification-before-completion.** Description becomes: "Use before
  claiming work is complete, fixed, or passing, and before committing or
  opening a PR." Body: "Before reporting status, audit each claim against a
  tool result from this session. A claim with no run behind it is not made.
  Scope the claim to the evidence: if you ran one package, say that package
  passed. A regression test counts once it has been seen red and then
  green. An agent's success report is a claim; read the diff." Plus the
  table of claims and their evidence, trimmed to tests, build, bug fixed,
  agent completed.
- **receiving-code-review.** Description becomes: "Use when acting on code
  review feedback from a person or an external reviewer, before
  implementing it." Keeps: verify each item against the codebase before
  implementing; an unclear item blocks the batch, ask about all unclear
  items at once; feedback from your human partner is trusted after
  understanding, external feedback is checked for correctness, breakage,
  the reason for the current code, and platform fit; a conflict with your
  human partner's earlier decision goes to them; grep for callers before
  accepting "unused"; the `gh api` reply mechanic. The Forbidden Responses
  section, the gratitude ban, and the ALL-CAPS response pattern are
  removed.
- **writing-skills, writing-for-agents.** Component 1.
- **systematic-debugging.** Root cause before any fix, with the reason;
  the four phases as one list; instrument each boundary in multi-component
  systems; one hypothesis, one change; a failing test before the fix; three
  failed fixes means question the architecture; pointers to the three
  technique files. The Iron Law block, Red Flags, rationalization table,
  and "Signals From Your Human Partner" are removed.
- **test-driven-development.** The Iron Law one-liner; "delete means
  delete" with its loophole list as one sentence; verify RED for the right
  reason; ask before taking an exception; a five-row rationalization table
  keeping the rows on tests-after, sunk cost, keep-as-reference,
  too-simple-to-test, and I'll-test-manually; the pointer to
  `writing-good-tests.md`. The Red Flags list, the four Good/Bad code
  blocks, and the completion checklist are removed.
- **brainstorming.** The HARD-GATE (shrunk); the checklist; the visual
  companion rule and file path; the frontend-first offer text and the
  own-message rule; the Claude Design variant; the After the Design
  handoff. The terminal state is stated once. Component 4 changes the
  approval rule.
- **finishing-a-development-branch.** Steps 1 to 6 with the exact-head
  evidence reuse and docs-only cases, GIT_DIR and GIT_COMMON detection, the
  exact 4- and 3-option menus, typed "discard", the squash-merge guard,
  provenance cleanup, the completion contract, and the PR handoff lines.
  Quick Reference, Common Mistakes, Never, and Always are removed.
- **using-git-worktrees.** Detection including the submodule guard; native
  tool first with the reason; the ignore check; the policy-file contract;
  the source ref; the report format; the focused baseline. The
  rationalization table is removed; the polyglot setup script becomes one
  sentence ("install dependencies the way the project's manifest says").
- **dispatching-parallel-agents.** When to parallelise, what a focused
  brief carries, how to integrate results. The ❌/✅ mistakes list is removed.
- **requesting-code-review, code-reviewer.md.** Merge-base-not-HEAD~1 with
  its reason; the review-package and DIFF_FILE contract; REVIEW-GUIDANCE is
  reviewer-only; the output format. The example transcript, the
  Mandatory/Optional lists, and "accurate praise helps the implementer
  trust" are removed. Component 4 adds the failing-input rule.
- **interactive-design.** The ENTRY-GATE rewritten as one block naming all
  three entries in two sentences; the fixture HARD-GATE; the ledger format
  and statuses; exit reconciliation; what the spec must carry. §8 moves to
  `iteration-mode.md` behind a pointer that fires on the third entry.
  Component 3 changes the exit step about screenshots.
- **subagent-driven-development.** Every contract. Parallel Tracks moves to
  `parallel-tracks.md` behind a pointer that fires when the plan declares
  `## Execution Tracks`. The "Never" list stays under the heading
  "Ownership rules". Component 4 adds gate mode.
- **writing-plans.** Every contract. The Execution Tracks declaration rules
  and example table move to `execution-tracks.md` behind a pointer in the
  section that requires them. `plan-document-reviewer-prompt.md` is
  deleted; the Plan Review Gate bullets are the reviewer's brief.
- **ux-gate.** Rewritten under Component 3.
- **delivery, pr-monitor, agent-routing, writing-specs, quick-task,
  implementer-prompt, re-review-prompt, task-reviewer-prompt.** Light pass;
  Components 3 and 4 change specific rules.
- **The docs-only carry-forward rule** (Markdown under `docs/**` or at the
  repository root, or `.toolbelt/**` scratch; never a file the application
  builds, renders, or serves) is stated once, in
  finishing-a-development-branch Step 1, and referenced by pr-monitor and
  ux-gate with the words "the docs-only rule in
  toolbelt:finishing-a-development-branch Step 1".

### `hooks/session-start`

The wrapper tag `<EXTREMELY_IMPORTANT>` becomes `<TOOLBELT>`; the text
inside it is unchanged.

## Component 3: Visual verification

### Scope and ownership

UX review applies to new user flows and material changes to interaction,
layout, or responsive behaviour, or when explicitly requested. A routine
button-colour, copy, or isolated CSS adjustment does not trigger a model
review by itself. Judge the rendered effect, not the number of changed
lines: a one-line global layout change can still need review. Delivery
uses this same entry condition instead of treating every rendering diff
as a request for UX review.

The ux-gate description states that trigger. Its entry bundle contains the
changed routes, base..head range, approved acceptance criteria, and a
running isolated environment with queryable data. Its exit is `Pass` bound
to the reviewed head SHA, or `Changes Required`. The gate does not fix code.

| Work | Owner |
|---|---|
| Task smoke: mechanical checks and stills of the touched pathway | Implementer, before reporting DONE |
| Task smoke matrix and command | Orchestrator, before dispatching the implementer |
| Boundary capture and evidence selection | Gate operator, role `errand` |
| UX judgment | Vision-capable reviewer, specialty `ux` |

A rendering task still gets a cheap scripted smoke pass; that does not
invoke a model reviewer. Non-rendering tasks report `UI smoke: not applicable`.
The orchestrator never captures UX evidence; the implementer captures only
its own task's smoke pass.

### Capture input and execution

Bundle `skills/ux-gate/scripts/ux-capture` (executable Node launcher), its
explicit ESM implementation `ux-capture.mjs`, and a
skill-relative `matrix.md` reference. The reference documents the JSON
schema, defaults, actions, auth, theme setup, output, and failure results.
Link it where the operator and orchestrator write their matrices.

The matrix contains `baseUrl`, nonempty `pathways`, optional `storageState`,
`themes`, `viewports`, theme configuration, required web-font families,
allowed overflow/overlap/light-surface selectors, and reference routes.
Each named pathway has a path and nonempty named steps. A step may have an
action, selector, state label, wait selector, focus assertion, full-page
capture, crops, and a motion flag. State labels describe fixtures; they do
not create an error or loading state by themselves.

Actions: `click`, `hover`, `focus`, `scroll`, `press`, and `fill`. `press`
uses page keyboard input when no selector is provided; `key` names the key.
`fill` uses a selector and string `value`. `expectFocus` asserts which
selector holds focus. `capture: false` performs the step and its checks
without emitting images; use it for keyboard setup and assertions.

Default viewports: 375×812 at DPR 2, 768×1024 at DPR 1, and 1440×900 at
DPR 1. Default themes: light and dark. Theme modes are media, class,
attribute (`data-theme`), and localStorage. Relative auth paths resolve
from `--project-root`; all output paths resolve from the working directory.

Commands accept the matrix path, required `--out`, `--project-root`
(default cwd), repeatable `--pathway`, `--baseline`, `--smoke`, and `--video`.
Smoke uses the first viewport and all matrix themes, skipping axe,
filmstrips, reference screens, and baseline comparison. Completed capture runs write
`mechanical.json` with `projectRoot` and capture entries. Each entry records
its tag, pathway, step, state, width, theme, DPR, files, diff, checks, CLS,
console errors, failed requests, fonts, and axe result. Stills use
`<pathway>-<step>-<state>-<width>-<theme>.png`.

### Mechanical checks and failure handling

Keep page overflow, clipped content/text, overlap, covered controls, small
tap targets, layout shift, console errors, failed requests, broken images,
required web-font availability, dark-theme leakage, and optional axe checks.
The plan's Data Model defines their thresholds and severities.

Check overlapping content within a positioned container; exclude intentional
relationships between different overlay layers, not whole subtrees.
Required web fonts must have a loaded declaration as well as pass the font
loading check. Collect uncaught page exceptions alongside console errors.

Exit 0 means the requested checks completed without findings at `should`
or above; exit 1 means findings; exit 2 means the run cannot proceed.
Reject empty dimensions or step lists, invalid actions, and missing
configured auth before capture. A failed action, focus assertion, or wait
is a `step-failed` blocker; record subsequent skipped steps. An installed
axe scanner that fails is an `axe-error` blocker. Missing optional axe is
`unavailable`, not a passing scan. Failed requested diffs, crops, or motion
captures are blockers, with their errors in the report. A missing baseline
image is `new`; an unreadable baseline image is an error.

### Evidence selection and cost

There is no fixed image-count limit. Choose coverage from the feature's
size, acceptance criteria, changed dependencies, and rendering risks.
Capture relevant breakpoints and supported themes for changed surfaces;
exercise criteria-named states with isolated fixtures or seeded data.
Choose additional dimensions only where they can reveal a different defect.

Test keyboard navigation once per changed interaction unless responsive
behaviour changes it. Assert Tab reachability, activation, and dismissal
where relevant; direct programmatic focus does not establish keyboard
reachability. Capture focus appearance when it changed. Use filmstrips
only to review changed motion, rather than every open/close action.

Compare stills in the browser with per-channel tolerance 8 and the neighbour
noise filter. Record the changed bounding box and pixel ratio. Any surviving
change is `changed`, even below 0.1%; whole-image ratios do not determine
whether a label or icon matters. Crop the changed region with 24px padding.
Send relevant changed/new images, their useful crops or filmstrips, and
reference screens. Include unchanged images when they are needed to assess
an acceptance criterion; omit redundant images. Images precede text and are
labelled `Image N: <tag>`.

### Review and fixes

Before model review, route every mechanical finding at `should` or above
to the fix loop. Run any project token/palette check and attach its result.
The reviewer reads the project design reference and `docs/REVIEW-GUIDANCE.md`
when present and does not drive the browser or execute checks.

Pass 1: mark each acceptance criterion met, not met, or not evidenced,
with the relevant evidence. Pass 2: identify visible inconsistencies or
usability problems in spacing, alignment, typography, contrast, action
hierarchy, and states, using the project's design rules and reference
screens. Explain the consequence and the relevant criterion or convention.
Distinguish legitimate disabled states from unfinished controls. Do not
infer component imports from screenshots; code review checks those.

Findings name severity (`blocker`, `should`, `nit`), evidence, expected and
actual behaviour, and the component/file when known. Missing evidence itself
can block a criterion. The operator maps findings to owning files.

Blockers and shoulds go to the owning implementer; nits go in the PR
summary. Rerun affected pathways on the new head, including the nearest
previously passing state for each affected component. A shared style/token
change invalidates every consuming capture. Record carried and recaptured
evidence and its source head. Diff against each pathway's last capture.
After two unsuccessful rounds, send your human partner the remaining
findings and evidence. The final verdict reports pathways covered separately
from screenshot count and binds to the reviewed head. Use the docs-only
carry-forward rule from finishing-a-development-branch Step 1.

### Project policy and prototype baseline

Read optional `.toolbelt/ux-policy.md`: Launch, Auth, Theme, Data, viewports
and themes, allowed exceptions, design reference, reference screens, harness
notes. Infer missing launch/auth/theme conventions and record them.

The orchestrator writes `.toolbelt/ux/smoke/task-<N>/matrix.json` and supplies
the absolute smoke command before dispatching a rendering task. The
implementer fixes `should`/blocker findings within its task, reports paths
under **UI smoke**, or returns `DONE_WITH_CONCERNS` for an out-of-scope fix.
Reviewers treat missing required smoke evidence as an Important finding.

Interactive-design writes `.toolbelt/ux/matrix.json` and captures the
approved prototype to `.toolbelt/ux/baseline/`, recording the matrix path in
the ledger's acceptance criteria. Otherwise the gate captures the base
branch with the same matrix. Both paths use the bundled script.

Add `ux` and `gate` specialties to agent-routing's bundled defaults, using
the existing configured cross-harness reviewer routes. Concrete routes
remain in `defaults.json`; project routing can override them.

## Component 4: Review cadence

### `skills/writing-plans/SKILL.md`

Task Structure gains a field after `**Interfaces:**`:

```markdown
**Review:** immediate | gate
```

Rule, added to Task Right-Sizing:

> **Review class.** A task is `immediate` when any of these hold: it is in a
> `serial-N` track before a fork, or its `Produces:` is consumed by two or
> more later tasks or by a task in another track; it touches auth,
> authorization, tenancy scoping, a migration or shared schema, secrets or
> crypto, payments, a destructive data operation, or CI, build, or release
> configuration; it deletes or weakens a test, threshold, or lint rule. Every
> other task is `gate`. The plan reviewer checks each stamp against these
> conditions.

The Plan Review Gate gains the bullet: "**Review class** — every task
stamped, each `gate` stamp consistent with the review-class rule."

Delivery's skill text for the handoff is unchanged; writing-plans'
Execution Handoff closing sentence becomes "fresh subagent per task,
immediate review or a batched gate by review class, broad whole-branch
review at the end."

### `skills/subagent-driven-development/SKILL.md`

The Process step 2 becomes: "Per task: record BASE, dispatch the
implementer with its brief, answer its questions. On DONE, an `immediate`
task goes to task review as before. A `gate` task goes through the
self-check close and waits for its gate."

**Self-check close** (new section). Read the report's self-check table:

| Check | Evidence |
|---|---|
| Requirements | one row per requirement in the brief → file:line or test name |
| Files | `git diff --stat BASE..HEAD` pasted; every path is in the brief's Files block |
| Seen red | per guard: command and failing line |
| Covering suite | command and last passing line |
| Produces | the implemented signatures beside the brief's `Produces:` block, or `none` |
| UI smoke | run path and stills, or `not applicable` |
| Deviations | named, or `None` |

Every row must be present with pasted output, and every path in the Files
row must appear in the brief's Files block. If a row is missing or is a
claim without output, resume the implementer once for that row. If it is
still incomplete, or a path is outside the brief, the task flips to
`immediate` and goes to task review. Ledger line:
`Task <N>: self-checked (commits <base7>..<head7>, gate pending)`.

A task that returned `DONE_WITH_CONCERNS`, needed a re-dispatch, or whose
diff stat exceeds 8 files or 400 changed lines flips to `immediate`
regardless of its stamp.

**Gates** (new section). A gate runs when the first of these occurs: the
last task of a named track completes; four `gate` tasks have accumulated
since the last gate; `git diff --shortstat GATE_BASE..HEAD` exceeds 1,500
changed lines; or the boundary's tasks are all complete (the final gate).
GATE_BASE is the head the previous gate reviewed, or the boundary's start.

A boundary with four or fewer tasks and no `immediate` task runs only the
final gate. The final gate is the boundary's broad final review; it uses
MERGE_BASE as GATE_BASE and reads the ledger's minor findings.

Dispatch one reviewer resolved with role `reviewer`, specialty `gate`, and
the implementer's harness as `--author-harness`, using
`gate-reviewer-prompt.md`. Inputs, as files: the plan's Global Constraints
and Known Gotchas; per task in the batch its brief, report, and
`scripts/review-package --plan PLAN_FILE BASE HEAD` package; the batch
package `scripts/review-package --plan PLAN_FILE GATE_BASE HEAD`; the smell
baseline; the track's drift-log entries; the ledger's minor findings at the
final gate. The existing line "`scripts/review-package --plan PLAN_FILE
MERGE_BASE HEAD` for the final review" stays.

After the verdict: exactly one fix wave — one fixer with the complete list
of Critical and Important findings and spec gaps — then exactly one scoped
re-review of the fix wave with `re-review-prompt.md`, then adjudication as
at the task loop. Plan-mandated findings collected across the batch are
presented to your human partner once, at the gate. Ledger line:
`Gate <G>: tasks <a>–<b>, base <sha7>, head <sha7>, <X> findings, fix wave
<a7>..<b7>, verdict <clean|open>`. When a gate closes clean, every task in its batch
gets its `Task <N>: complete (commits <base7>..<head7>, gate <G>, route
<harness>/<model>/<effort>, report <path>)` line.

When the boundary is UX-gated, dispatch ux-gate's capture at the final
gate's head in parallel with the gate reviewer; the two finding sets merge
into the one fix wave; the re-review and the UX recapture run on the fixed
head. The existing "Optional pre-final gate" paragraph is replaced by this.

The task fix loop is unchanged for `immediate` tasks.

Verification Scope is unchanged.

### `gate-reviewer-prompt.md` (new)

A template in the SDD directory. Its body, in order: the plan's constraints;
the per-task list with brief, report, and diff paths; the batch diff path;
the reviewer-only guidance line and the smell baseline; the evidence limits
from the task-reviewer prompt (read each input once, one targeted read per
suspected finding, at most one focused test run, working tree untouched,
no subagents); then the required output:

1. **Per task**: spec verdict ✅ / ❌ / ⚠️ with file:line, reading that
   task's diff against its brief; a self-check audit (each row present and
   true against the diff); a seen-red audit (every guard has red evidence or
   the task gets an Important).
2. **Across the batch**: contract drift between tasks, duplicated logic
   across tasks, a seam no test crosses, drift-log entries that contradict
   a sibling, tests that assert mocks rather than behaviour.
3. **Findings** under Critical, Important, Minor, each with file:line,
   what is wrong, and why it matters. "How to fix" is optional.

The severity rule, also added to `task-reviewer-prompt.md` and
`code-reviewer.md` in place of their Calibration text:

> A Critical or Important finding names the input, state, or command under
> which the code misbehaves. A finding that cannot name one is Minor. Report
> everything you see and let the orchestrator filter.

### `implementer-prompt.md`

Report Format gains the self-check table above, required for every task
("the orchestrator reads it mechanically"). The After Review Findings
table is unchanged.

### `skills/delivery/SKILL.md`

Step 4 becomes: "When the boundary meets ux-gate’s entry condition or UX review is explicitly requested, tell SDD the boundary is UX-gated; SDD runs ux-gate at the final
gate." The role table gains the Component 3 rows. "That broad final review
is the slice gate; do not add another whole-slice review." stays.

### `skills/brainstorming/SKILL.md`

Presenting the Design, the bullet "Ask after each section whether it looks
right" becomes: "When the whole design fits three sections, present them
together and ask for one approval; otherwise ask after each section."
Checklist item 5 reads "Present the design — one approval when it fits
three sections, otherwise approval after each."

### `skills/writing-specs/SKILL.md`

Checklist items 4 and 5 swap: alternate-harness review runs after
self-review, and the user review gate runs on the reviewed spec. The user
gate message becomes:

> "Spec written, reviewed through <reviewer harness> (<X> of <Y> findings
> applied), and committed to `<path>`. Please review it and let me know if
> you want to make any changes before we start writing out the
> implementation plan."

The ENTRY-GATE is unchanged in meaning; the prose rules of Component 2
apply.

### `docs/WORKFLOW.md`

The delivery paragraph adds: "Tasks are reviewed by class: `immediate`
tasks get a task review on completion; `gate` tasks self-check with
evidence and are reviewed together at a gate — track end, four tasks, 1,500
lines, or the boundary's final review, whichever comes first — by one
top-tier cross-harness reviewer with one fix wave. The UX gate runs beside
the final gate." The sentence "A materially user-visible slice runs the UX
gate after task reviews and before SDD's broad final review" is replaced by
that.

## Component 5: Docs and release

- `README.md`: the ux-gate line becomes "Mechanical checks, pixel diff, and
  two-pass vision review for user-visible changes"; the
  verification-before-completion and receiving-code-review lines match
  their new descriptions.
- `docs/ADOPTING-IN-A-PROJECT.md` gains `.toolbelt/ux-policy.md` in the
  per-project files list with its section names.
- `docs/AGENTS-SNIPPET.md` gains one line naming the review classes.
- Version 8.0.0.

## Error handling

- Capture script cannot resolve `playwright`: exit 2 with the one-line
  install instruction; the gate records "cannot run" and no downstream step
  may claim UX was verified (the existing preflight rule).
- A step's `waitFor` times out: `step-failed` blocker recorded, still taken,
  run continues.
- `--baseline` given but a capture has no baseline file: `diff.status:
  "new"`, included in the reviewer set.
- `@axe-core/playwright` absent: `"axe":"unavailable"`, no failure.
- Self-check row incomplete after one resume: task flips to `immediate`.
- Gate reviewer route fails to resolve: stop and tell your human partner
  (agent-routing's existing fail-closed rule).
- Smoke pass reports findings the implementer cannot fix within the task's
  Files block: `DONE_WITH_CONCERNS`, which flips the task to `immediate`.
- Word-count ceiling exceeded: the test fails; the file is cut, never the
  ceiling raised, except by a later spec.

## Testing

The plugin has no machine-specific dependency paths. Provision capture-test
dependencies in a temporary directory when they are not already available:

```bash
capture_deps=$(mktemp -d)
npm install --prefix "$capture_deps" --no-package-lock --no-save playwright
export PLAYWRIGHT_MODULE="$capture_deps/node_modules/playwright"
node "$PLAYWRIGHT_MODULE/cli.js" install chromium
bash tests/toolbelt/test-ux-capture.sh
bash tests/toolbelt/test-ux-capture-regressions.sh
```

Use the project's installed Playwright for normal UX runs; `--project-root`
controls resolution. The test font is a bundled synthetic fixture, so its
availability does not depend on installed operating-system fonts.

Existing assertions that become false, each replaced in the same commit:

- `tests/toolbelt/test-ux-gate.sh`: "throwaway Playwright script",
  "`<pathway>-<step>-<state>-<width>[-<theme>].png`", "only when
  theme-specific styles or tokens changed or the acceptance criteria require
  them", "against the approved criteria — never personal taste", "component
  file + visual state + viewport + specific deviation + screenshot
  reference", "a shared style or token change invalidates every consuming
  capture" (kept if the sentence survives the rewrite, else replaced).
- `tests/toolbelt/test-final-review-gate.sh`: "If the caller supplies a
  pre-final gate, run it after all task reviews and before the broad final
  review." → the gate-mode sentence.
- `tests/toolbelt/test-fix-loop.sh`: needles stay; add the self-check and
  gate ledger lines.
- `tests/toolbelt/test-delivery.sh`: "ux-gate" and "broad final review is
  the slice gate" stay; check the role-table needles.
- `tests/toolbelt/test-interactive-design.sh`: "Acceptance criteria" stays;
  brainstorming's "The offer MUST be its own message" → "The offer is its
  own message"; "[PENDING]" and "a placeholder without" stay in `SKILL.md`
  (the test requires "[PENDING]" inside the HARD-GATE block); "before §4's
  reconciliation may run" and "toolbelt:quick-task" point at
  `iteration-mode.md`; "the single route confirmed in §8" → "the route
  confirmed in iteration-mode.md", which is also §4 step 4's new wording.
  The test's frontmatter `sed` expression is replaced with a portable `awk`
  so it runs on BSD sed.
- `tests/toolbelt/test-writing-plans.sh`: needles stay; the Execution
  Tracks needles in `test-execution-tracks.sh` point at
  `execution-tracks.md`.
- `tests/toolbelt/test-worktree-baseline.sh`: "Satisfy Step 3 now"
  (rationalization table) → removed.
- `tests/toolbelt/test-word-counts.sh`: the Component 2 table replaces the
  current one.
- `tests/hooks/test-session-start.sh`: any needle on `EXTREMELY_IMPORTANT`
  → `TOOLBELT`.
- `tests/toolbelt/test-agent-routing.sh`: the bundled-defaults expectations
  gain the two specialties and the new reviewer fallback.

New assertions:

- `tests/toolbelt/test-ux-capture.sh`: with a fixture HTML page served from
  a temp directory by a Node static server, a matrix naming one pathway with
  an element overflowing its card, a covered button, a dark theme with a
  hard-coded white block, and a `motion` step: the script exits 1 in
  `--smoke`, `mechanical.json` contains `element-overflow`, `unclickable`,
  and `theme-leak` entries with the expected selectors, a filmstrip file
  exists, and a second run with `--baseline` over an unchanged page marks
  every capture `unchanged`. Skipped with a clear message when `playwright`
  does not resolve on the machine.
- `tests/toolbelt/test-review-classes.sh`: writing-plans carries
  `**Review:** immediate | gate` and the review-class rule; SDD carries the
  self-check table headers, the four gate triggers, the `Gate <G>:` ledger
  line, and the parallel UX rule; `gate-reviewer-prompt.md` exists and
  carries the severity rule; the same severity rule is in
  `task-reviewer-prompt.md` and `code-reviewer.md`.
- `tests/toolbelt/test-doctrine.sh`: no skill file contains
  `EXTREMELY-IMPORTANT`, "Violating the letter", "you'll be replaced", or
  "Iron Law" outside `test-driven-development`; every `<HARD-GATE>` and
  `<ENTRY-GATE>` block is at most 80 words; only
  `test-driven-development/SKILL.md` and
  `writing-skills/testing-skills-with-subagents.md` (the testing reference
  Component 1 moves the skipping-tests table into) contain a table whose
  header is `| Excuse | Reality |` or `| Thought | Reality |`.
- `tests/toolbelt/test-word-counts.sh` covers every file in the Component 2
  table.

Acceptance, run after reinstalling both plugin caches:

- Clean session, "Let's make a react todo list": brainstorming triggers
  before any code, in both harnesses.
- Clean session in a disposable consuming project with a running fixture
  route: "run the UX smoke on /settings" produces a `mechanical.json` and stills without the agent
  writing a Playwright script.

## Out of scope

- Consuming-project configuration: the UX paragraph of `docs/REVIEW-GUIDANCE.md`,
  creating `.toolbelt/ux-policy.md` from the existing harness notes, and
  the overlap between its AGENTS.md self-UAT line and the smoke pass. A
  follow-up quick task in that repository.
- Micro-testing the stripped rationalization tables under pressure. The
  acceptance test above is the gate; if test-first behaviour regresses in
  practice, restore rows verbatim from git history.
- Pressure-scenario suites under `tests/claude-code/`.
