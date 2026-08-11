# Interactive Design (Frontend-First Prototyping) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use toolbelt:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `interactive-design` skill — an optional, human-opted frontend-first prototyping phase between brainstorming and writing-specs — plus its brainstorming/writing-specs integration edits, tests, and release bump.

**Architecture:** One new skill directory with Codex interface metadata; three precise text changes to `skills/brainstorming/SKILL.md`; one sentence added to `skills/writing-specs/SKILL.md`; one new content-assertion test following the existing `tests/toolbelt` pattern. No downstream skill (writing-plans, delivery, SDD, finishing, pr-monitor, ux-gate) changes.

**Tech Stack:** Markdown skills, YAML interface metadata, bash content tests.

**Spec:** `docs/toolbelt/specs/2026-08-11-interactive-design-design.md` — implementers follow this plan; the spec is the source the verbatim blocks below were copied from.

## Global Constraints

- No file under `skills/` may hard-code anything about one consuming repo; per-project behavior comes only from optional `.toolbelt/prototyping.md`.
- Fixture marker string: exactly `TOOLBELT-FIXTURE`.
- Ledger path (in consuming projects): `.toolbelt/prototype/<feature-slug>/contracts.md`.
- Skill name: `interactive-design`. Frontmatter exactly two fields (`name`, `description`), ≤ 1024 chars total, description in third person, triggers only — never workflow summary.
- Phrasing: "your human partner", never "the user".
- `interactive-design` names exactly one next skill — `writing-specs` — with the sentence "Do NOT invoke any other skill." Brainstorming's default terminal state remains writing-specs; the fork is decided by the human.
- Version becomes `7.6.0` in all four of: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `package.json` (all currently `7.5.0`).
- Preserve existing forceful blocks verbatim when editing brainstorming/writing-specs; add text, do not rephrase surrounding gates.
- Downstream untouched: no changes to writing-plans, delivery, SDD, finishing-a-development-branch, pr-monitor, or ux-gate — fixture-replacement and hardening requirements travel inside the spec document consuming projects produce.
- Single PR is forced for frontend-first features (fixtures never reach the base branch); the skill text carries that standing justification for consuming projects' plans.
- Applicability: the path applies only when the frontend and the API it consumes live in the same repository (or its workspace); "endpoint" means the unit of the project's API convention — REST method + path, GraphQL operation, RPC procedure.
- Claude Design integration is out of scope.

## Known Gotchas

- **`git grep` exit inversion:** in the fixture-zero check, exit 0 = marker found = FAIL; exit 1 = clean = PASS. The skill text must state "exits 1 (no matches)" exactly as the Data Model block does.
- **Self-matching absence check:** the fixture-zero grep must carry the `':!docs/toolbelt' ':!.toolbelt'` exclusions — committed specs/plans in consuming projects legitimately name the marker. Never write the bare grep.
- **Tests run via `bash`, not the executable bit:** invoke as `bash tests/toolbelt/test-interactive-design.sh`; the mode bit is irrelevant (siblings vary — `test-execution-tracks.sh` is 0644).
- **Do not touch phrases other tests assert:** `tests/toolbelt/test-workflow-summary.sh`, `test-quick-task.sh`, and `test-delivery.sh` assert text in other files; the brainstorming/writing-specs edits here add text without rewording existing sentences, so no existing assertion changes. If an edit collides with an existing test assertion anyway, stop and escalate — do not silently reword either side.
- **Plugin cache is stale by design:** editing this checkout changes nothing in live sessions. Implementer tasks verify with `tests/toolbelt` scripts only; the manual acceptance drill (cache refresh + fresh session) is the human's post-merge step, not a task step.
- **`docs/AGENTS-SNIPPET.md` is frozen:** it declares exactly two public entry points and says to redesign the capability rather than extend it. interactive-design is reached through brainstorming and does NOT get added there.

## Data Model

Verbatim text blocks. Tasks reference them by name; copy exactly — wording is behavior in this repo.

**[D1] Skill frontmatter description** (for `skills/interactive-design/SKILL.md`):

```yaml
description: "Use when your human partner accepts the frontend-first offer or asks to prototype the frontend before backend work — after brainstorming approves the intent-level design, before any spec exists."
```

**[D2] Skill entry gate:**

```markdown
<ENTRY-GATE>
Two ways in: your human partner accepted brainstorming's frontend-first offer, or asked
for this path directly. Never select this path yourself. Entry requires an approved
intent-level design from brainstorming — what the feature does, who uses it, the data it
needs, and a first sketch of the contracts — with UI detail deferred to this session.
The feature's frontend and the API it consumes must live in this repository (or its
workspace); if they don't, stop and tell your human partner this path does not apply.
</ENTRY-GATE>
```

**[D3] Fixture hard gate:**

```markdown
<HARD-GATE>
Every datum the frontend would obtain from the backend in production comes from a real
API route in this repo. No inline mock data, no hardcoded domain data in components, no
frontend-side stub layers. A route that doesn't exist yet gets created as a real route
handler returning fixture data, tagged with a greppable marker line naming its endpoint
(`TOOLBELT-FIXTURE <endpoint id>`), and recorded in the contract ledger in the same
edit — a fixture without a ledger entry is a gate violation.
</HARD-GATE>
```

**[D4] Fixture-zero check** (appears in the skill's handoff-requirements section):

```
git grep TOOLBELT-FIXTURE -- ':!docs/toolbelt' ':!.toolbelt'
```

exits 1 (no matches) at the final whole-branch review. Projects that deliberately keep fixtures (tests, storybook) record the exception in the ledger and add those paths to the exclusion list.

**[D5] Brainstorming HARD-GATE exception sentence** (appended inside brainstorming's existing `<HARD-GATE>` block, after its current sentence):

```markdown
Exception: when your human partner has approved the intent-level design and accepted the
frontend-first offer, invoke toolbelt:interactive-design — prototype implementation
inside that skill is authorized.
```

**[D6] Frontend-first offer text** (in brainstorming's new offer section):

```markdown
> "This feature has a real user-facing surface — we could go frontend-first: I build the
> actual frontend against fixture-backed API routes in one sitdown session, we iterate
> until the design is right, and the backend gets implemented afterward from the
> contracts we settle. Want to? Otherwise I'll write the spec as usual."
```

**[D7] writing-specs ENTRY-GATE sentence** (appended inside the existing `<ENTRY-GATE>` block, after "Direct entry is allowed only when your human partner asks for a spec or supplies written requirements."):

```markdown
Arriving from interactive-design with a reconciled contract ledger is likewise a normal
entry, equivalent to a brainstorming-approved design.
```

**[D10] "After the Design" fork sentence** (inserted at the start of brainstorming's "After the Design" paragraph; deliberately distinct wording from D5 so the test needle cannot false-pass):

```markdown
When your human partner accepted the frontend-first offer, the next skill is
toolbelt:interactive-design — invoke it and no other. Otherwise:
```

The existing "invoke the writing-specs skill … Do NOT invoke any other skill. writing-specs is the next step." text stays verbatim as the otherwise-branch.

**[D11] Checklist and terminal-state conditional wording** (replaces brainstorming checklist item 6 and the terminal-state line — the spec's fourth change; these are the only two existing lines this plan rewords):

```markdown
6. **Hand off** — to writing-specs once your human partner has approved the whole design, or to interactive-design when they accepted the frontend-first offer
```

```markdown
**The terminal state is invoking writing-specs — or interactive-design when the frontend-first offer was accepted.**
```

**[D8] Codex interface metadata** (`skills/interactive-design/agents/openai.yaml`, complete file):

```yaml
interface:
  display_name: "Interactive Design"
  short_description: "Prototype the frontend against fixture-backed contracts before backend work"
  default_prompt: "Use $interactive-design to prototype this feature frontend-first."
```

**[D9] Ledger contract** (documented in the skill; the skill shows this shape):

- Path: `.toolbelt/prototype/<feature-slug>/contracts.md`. Header: feature, branch, marker string, and inferred conventions when `.toolbelt/prototyping.md` was absent.
- One entry per endpoint at plan altitude (REST: method, path, request/response shapes, status codes; other conventions: the project's API unit — GraphQL operation, RPC procedure — with shapes and error modes). The entry's identifier is what the marker line carries.
- Statuses: `[FIXTURE]` (new route, canned; fields: fixture `path:line`, shapes, error statuses, `Notes` line for UI-derived semantics), `[EXISTING — EXTENDED]` (delta + fixture location only), `[EXISTING]` (consumed as-is, no marker), `[IMPLEMENTED]` (set during SDD when the fixture is replaced and the marker removed).
- After exit reconciliation the ledger adds an **Acceptance criteria** section: visual and interaction criteria from the approved prototype, including the exercised empty and error states.
- Invariant: marker grep and ledger agree on what is still fake; each marker's endpoint id resolves to exactly one entry.

---

## PR Boundaries

| PR | Outcome | Tasks | Depends on | Independent verification |
|---|---|---|---|---|
| 1 | interactive-design skill live: new skill + integration edits + tests + 7.6.0 bump | 1, 2, 3 | none | `bash tests/toolbelt/test-interactive-design.sh` passes; full `tests/toolbelt` suite green |

One PR: this delivers one atomic capability — the skill, both integration gates that make it part of the pipeline, the tests that pin their wording, and the release metadata. A skill shipped without its brainstorming fork ships a half-wired path (reachable only by explicit request, with a dangling gate contradiction), and the fork without the skill dangles outright; no smaller outcome is independently verifiable as the feature the spec defines.

---

### Task 1: The interactive-design skill and its metadata

**Files:**
- Create: `skills/interactive-design/SKILL.md`
- Create: `skills/interactive-design/agents/openai.yaml`
- Test: `tests/toolbelt/test-interactive-design.sh` (created here; extended in Task 2)

**Interfaces:**
- Produces: `skills/interactive-design/SKILL.md` containing blocks D1–D4 and the section set below — Task 2's brainstorming edits point at this skill by name `toolbelt:interactive-design`.

**Gotchas:**
- The grep inversion and exclusion rules (Known Gotchas) must appear in the skill text exactly as D4 states them.
- Frontmatter is exactly `name` + D1's `description`; adding any other field breaks the skill spec.

- [ ] **Step 1: Write the failing test**

Create `tests/toolbelt/test-interactive-design.sh` copying the structure of `tests/toolbelt/test-ux-gate.sh` (same `assert_contains` helper, same `repo_root` resolution). One `assert_contains` per line — file — needle — description:

- `SKILL.md` — `name: interactive-design` — frontmatter name
- `SKILL.md` — `accepts the frontend-first offer` — description trigger
- `SKILL.md` — `TOOLBELT-FIXTURE <endpoint id>` — marker format with endpoint id
- `SKILL.md` — `.toolbelt/prototype/` — ledger path
- `SKILL.md` — `a fixture without a ledger entry is a gate violation` — hard gate teeth
- `SKILL.md` — `':!docs/toolbelt' ':!.toolbelt'` — fixture-zero exclusions
- `SKILL.md` — `exits 1 (no matches)` — grep inversion stated
- `SKILL.md` — `.toolbelt/prototyping.md` — per-project convention documented
- `SKILL.md` — `Do NOT invoke any other skill` — single next skill
- `SKILL.md` — `matching its endpoint id` — reconciliation requirement
- `SKILL.md` — `Acceptance criteria` — criteria written at exit
- `agents/openai.yaml` — `display_name: "Interactive Design"` — Codex metadata

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/toolbelt/test-interactive-design.sh`
Expected: FAIL — skill file missing.

- [ ] **Step 3: Write the skill and metadata**

`skills/interactive-design/agents/openai.yaml` is D8, complete.

`skills/interactive-design/SKILL.md`: frontmatter (`name: interactive-design`, D1), then these sections in order. The verbatim blocks are fixed; surrounding prose is the implementer's, written short per the repo's skill conventions (cut restatement, keep gates):

1. **Title + one-paragraph overview:** frontend-first prototyping as design work; output is working frontend code plus a reconciled contract ledger. Announce line: "I'm using interactive-design to prototype the frontend against fixture-backed contracts."
2. **D2 entry gate.**
3. **Setup (numbered):** (a) ensure an isolated workspace — if already in an isolated worktree use it, otherwise invoke `toolbelt:using-git-worktrees`; the prototype branch is the branch the backend plan later executes on; (b) read `.toolbelt/prototyping.md` when present (it states where fixture-backed routes live, how to run the frontend dev server, seed-data conventions); when absent, infer all three and record each inference in the ledger header; (c) scaffold the ledger per D9 and start the dev server.
4. **D3 fixture hard gate**, followed by its scope note: the gate governs backend-owned data only — UI copy, labels, icons, layout constants, and client-derived display values are exempt. The marker's `<endpoint id>` is the ledger entry's identifier (example: `GET /api/projects/:id/insights`).
5. **The loop:** edit directly in-session — no subagent dispatch, no per-iteration review; frequent checkpoint commits; fixture and ledger entry updated in the same pass on every shape change; before the design may be declared nailed, exercise the empty and error variants of each fixture-backed surface via fixture responses.
6. **Exit:** the four reconciliation/handoff steps — (1) verify every marker has a ledger entry matching its endpoint id and every `[FIXTURE]` / `[EXISTING — EXTENDED]` entry has a marker (`[EXISTING]` and `[IMPLEMENTED]` entries carry none), shapes match what fixtures return, dead routes deleted; (2) write the Acceptance criteria section (visual + interaction, including the exercised empty and error states) into the ledger — ux-gate later consumes these criteria and captures its own screenshots, no prototype screenshots are kept; (3) present the final contract inventory to your human partner; (4) on approval invoke `toolbelt:writing-specs`. Do NOT invoke any other skill.
7. **What the spec must carry** (bulleted, one line each): API section lifted from the ledger; one fixture-replacement requirement per `[FIXTURE]`/`[EXISTING — EXTENDED]` entry (implement the exact recorded shape, remove the marker, flip to `[IMPLEMENTED]`); hardening requirements (frontend tests per project conventions plus loading/slow-response handling — empty and error appearances were approved in the loop); the D4 fixture-zero check; ux-gate criteria = the ledger's Acceptance criteria; ledger synchronization (contract changes accepted in spec or plan review are written back to ledger and fixture in the same round); prototype-commit accounting (prototype commits predate the plan, are covered by hardening tasks and the final whole-branch review, inside the single PR); single-PR mandate with its standing justification (fixtures never reach the base branch).
8. **Error path:** infeasible contract during SDD is the existing BLOCKED escalation; the human-approved resolution amends the spec, updates ledger and fixture to match, and revises affected plan tasks — including a frontend adaptation task — before execution resumes. Spec API section and ledger move together.
9. **D9 ledger contract**, shown as a short annotated example (one `[FIXTURE]` entry, one `[EXISTING — EXTENDED]` entry), plus the cleanup note: the ledger directory is ignored scratch removed by delivery's post-merge cleanup; its content lives on in the spec.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/toolbelt/test-interactive-design.sh`
Expected: PASS, one `ok` line per assertion.

- [ ] **Step 5: Commit**

```bash
git add skills/interactive-design tests/toolbelt/test-interactive-design.sh
git commit -m "feat: interactive-design frontend-first prototyping skill"
```

### Task 2: Brainstorming fork and writing-specs entry

**Files:**
- Modify: `skills/brainstorming/SKILL.md` (HARD-GATE block at lines 10–13; checklist item 6 at line 25; terminal-state line at line 29; "After the Design" section at lines 50–52; new section inserted between "After the Design" and "Visual Companion")
- Modify: `skills/writing-specs/SKILL.md` (ENTRY-GATE block at lines 12–14)
- Test: `tests/toolbelt/test-interactive-design.sh` (extend)

**Interfaces:**
- Consumes: skill name `toolbelt:interactive-design` from Task 1.

**Gotchas:**
- Add text only; do not reword any existing sentence in either gate block — forceful blocks are preserved verbatim by project convention.
- The offer section must require the offer to be its own message, mirroring the Visual Companion pattern already in the file.

- [ ] **Step 1: Extend the test with failing assertions**

Append to `tests/toolbelt/test-interactive-design.sh`:

- `skills/brainstorming/SKILL.md` — `inside that skill is authorized` — HARD-GATE exception present (D5's distinct final line)
- `skills/brainstorming/SKILL.md` — `we could go frontend-first` — offer text present
- `skills/brainstorming/SKILL.md` — `The offer MUST be its own message` — own-message rule (distinct needle; the bare phrase "its own message" already appears in the visual-companion section and would false-pass)
- `skills/brainstorming/SKILL.md` — `invoke it and no other` — After-the-Design fork (D10's distinct second line; a bare `toolbelt:interactive-design` needle would false-pass on D5)
- `skills/brainstorming/SKILL.md` — `or to interactive-design when they accepted` — checklist item 6 conditional (D11)
- `skills/writing-specs/SKILL.md` — `Arriving from interactive-design with a reconciled contract ledger` — entry gate acknowledges the path (D7's complete first line, not a bare name)

`assert_contains` uses `grep -F`, which is line-based: every needle above lies within a single line of its D-block exactly as the block is line-wrapped in this plan. Copy the D-blocks' line breaks verbatim and the needles match; re-wrap them and the test false-fails.

- [ ] **Step 2: Run the test to verify the new assertions fail**

Run: `bash tests/toolbelt/test-interactive-design.sh`
Expected: FAIL on the first brainstorming assertion; Task 1 assertions still pass.

- [ ] **Step 3: Make the four brainstorming changes and one writing-specs change**

1. Inside brainstorming's `<HARD-GATE>` block, after its existing sentence, append D5.
2. Insert a new `## Frontend-First Offer` section between "After the Design" and "Visual Companion" containing, in order: the firing condition (the feature has a significant user-facing surface, its frontend and API live in this repository, and the intent-level design sections — purpose, users, data, contract sketch — are approved); the sentence "The offer MUST be its own message — only the offer, nothing else — and you wait for the response."; D6; the three outcomes — accepted → invoke `toolbelt:interactive-design` (remaining UI-detail design work moves into that session), declined → continue exactly as before and do not offer again unless your human partner raises it, backend-only features and out-of-applicability projects never get the offer.
3. Prepend D10 to the "After the Design" paragraph; the existing "invoke the writing-specs skill … Do NOT invoke any other skill. writing-specs is the next step." text stays verbatim as the otherwise-branch. Each branch names exactly one next skill.
4. Replace checklist item 6 and the terminal-state line with D11's two lines — the only two existing lines this task rewords.
5. Inside writing-specs' `<ENTRY-GATE>` block, after the direct-entry sentence, append D7.

- [ ] **Step 4: Run the full test to verify it passes**

Run: `bash tests/toolbelt/test-interactive-design.sh`
Expected: PASS on all assertions.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/writing-specs/SKILL.md tests/toolbelt/test-interactive-design.sh
git commit -m "feat: brainstorming offers the frontend-first path; writing-specs accepts it"
```

### Task 3: Docs and release bump

**Files:**
- Modify: `README.md` (skills list around lines 89–103)
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `package.json` (version fields)

**Interfaces:**
- Consumes: nothing from earlier tasks beyond the skill's existence.

**Gotchas:**
- `docs/AGENTS-SNIPPET.md` stays untouched (Known Gotchas). `marketplace.json`'s version sits inside a plugin entry, not at top level — bump the `7.5.0` occurrence, currently line 12.

- [ ] **Step 1: Edit docs and versions**

1. In `README.md`'s skills list, after the `writing-specs` bullet, add: `- **interactive-design** - Frontend-first prototyping against fixture-backed API contracts`.
2. Change `7.5.0` to `7.6.0` in all four version files.

- [ ] **Step 2: Verify**

Run: `git grep -c '"version": "7.6.0"' -- .claude-plugin .codex-plugin package.json | wc -l` → expected `4` (one match in each of the four files); `git grep -n '"version": "7.5.0"' -- .claude-plugin .codex-plugin package.json` → expected: no output, exit 1.
Run: `for t in tests/toolbelt/test-*.sh; do bash "$t" || exit 1; done`
Expected: every script exits 0.

- [ ] **Step 3: Commit**

```bash
git add README.md .claude-plugin .codex-plugin/plugin.json package.json
git commit -m "chore: bump to 7.6.0; document interactive-design"
```

---

## Pre-merge acceptance gate (after the final review, before the PR merges)

Owner: the human partner runs the drills; the orchestrator prepares. Not an implementer task — it happens once Tasks 1–3 are complete and reviewed:

1. Orchestrator: refresh both plugin caches from this branch (uninstall-first for Claude Code — install is a no-op at an unchanged version), then verify with `grep -r "interactive-design" ~/.claude/plugins/cache/toolbelt-dev/toolbelt/7.6.0/skills/ | head -1` (and the Codex cache equivalent) that the new skill is actually installed before any drill is trusted.
2. Human partner, fresh session per harness: UI-heavy prompt → offer appears as its own message after intent-level approval; backend-only prompt → no offer.
3. Human partner, one accepted-path drill in at least one harness (scratch project): skill invoked, fixture route + ledger entry in the same edit, exit reconciliation runs, handoff to writing-specs; one declined run confirms the offer is not repeated.

Failures here are fix findings against the branch before merge, not post-release patches.
