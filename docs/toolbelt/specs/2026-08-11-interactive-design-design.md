# Interactive Design (Frontend-First Prototyping) — Design Spec

An optional, human-opted phase between brainstorming and writing-specs: build the real
frontend against fixture-backed API routes in one sitdown session, iterate with your human
partner until the design is nailed, and hand the settled API contracts to the existing
spec → plan → SDD pipeline, which then implements the backend autonomously. Serial — no
parallel backend lane. The prototype phase is design work; its output is working frontend
code plus a reconciled contract ledger that becomes the spec's API section.

## Global Constraints

- **Project-agnostic:** no file under `skills/` may hard-code anything about one repo.
  Per-project behavior comes only from the optional `.toolbelt/prototyping.md` in the
  consuming project.
- **Fixture marker string:** exactly `TOOLBELT-FIXTURE`.
- **Ledger path (in the consuming project):** `.toolbelt/prototype/<feature-slug>/contracts.md`.
- **Skill name:** `interactive-design`. Frontmatter carries exactly `name` and
  `description`, total ≤ 1024 characters; description states triggers only, never
  workflow summary; written in third person.
- **Phrasing:** "your human partner", never "the user".
- **Handoff chain:** `interactive-design` names exactly one next skill — `writing-specs` —
  and says "Do NOT invoke any other skill." Brainstorming's default terminal state remains
  writing-specs; the fork is decided by the human, never by agent discretion.
- **Downstream untouched:** no changes to writing-plans, delivery, SDD,
  finishing-a-development-branch, pr-monitor, or ux-gate. Fixture-replacement and
  hardening requirements travel inside the spec document the pipeline already consumes.
- **Version:** bump to `7.5.0` in both `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` (new-skill minor bump, per existing release practice).
- **Claude Design integration is out of scope** (deferred to a future iteration).

## Components

### 1. New skill: `skills/interactive-design/SKILL.md`

**Purpose:** run the one-session frontend prototype loop and deliver a reconciled contract
ledger to writing-specs.

**Description (frontmatter), exact text:**

> Use when your human partner accepts the frontend-first offer or asks to prototype the
> frontend before backend work — after brainstorming settles feature intent, before any
> spec exists.

Trigger-only by design; it names the two entry conditions and nothing about the workflow.

**Entry gate (`<ENTRY-GATE>`):** two ways in — brainstorming's offer accepted, or an
explicit request from your human partner. The agent never selects this path on its own.
Entry requires settled feature intent from brainstorming: what the feature does, who uses
it, and a first sketch of the data it needs. A full UI design is explicitly NOT required —
the prototype session is where that design emerges.

**Setup:**
1. Ensure an isolated workspace: if the session is already in an isolated worktree, use
   it; otherwise invoke `toolbelt:using-git-worktrees`. The prototype branch is the same
   branch the backend plan later executes on.
2. Read `.toolbelt/prototyping.md` if present (see component 4). If absent, infer fixture
   location, frontend run command, and seed-data conventions from the codebase and record
   each inference in the ledger header.
3. Scaffold the contract ledger (component 5) and start the dev server.

**Fixture hard gate (`<HARD-GATE>`, verbatim in the skill):**

> Every datum rendered by the frontend comes from a real API route in this repo. No inline
> mock data, no hardcoded arrays in components, no frontend-side stub layers. A route that
> doesn't exist yet gets created as a real route handler returning fixture data, tagged
> with a greppable marker (`TOOLBELT-FIXTURE`), and recorded in the contract ledger in the
> same edit — a fixture without a ledger entry is a gate violation.

**The loop:** the session agent edits code directly — no subagent dispatch, no
per-iteration review; latency is the enemy in an interactive session. Frequent checkpoint
commits on the prototype branch; nobody reads this history. Whenever an iteration changes
what data the UI needs, the fixture and its ledger entry are updated in the same pass —
shape changes are never deferred.

**Exit — reconciliation pass, then handoff.** When your human partner says the design is
nailed:
1. Verify every `TOOLBELT-FIXTURE` marker has a ledger entry and every `[FIXTURE]` /
   `[EXISTING — EXTENDED]` entry has a marker; verify each ledger shape matches what the
   fixture actually returns; delete dead routes left by abandoned iterations.
2. Present the final contract inventory to your human partner: "this is what the backend
   has to build."
3. On approval, invoke `toolbelt:writing-specs`. Do NOT invoke any other skill.

**Handoff requirements the skill instructs the agent to carry into the spec** (this is how
downstream stays unchanged — the requirements ride in the spec document):
- The spec's API section is lifted from the reconciled ledger.
- One fixture-replacement requirement per `[FIXTURE]` and `[EXISTING — EXTENDED]` entry:
  implement the real logic behind the exact recorded shape, remove the marker, flip the
  ledger status to `[IMPLEMENTED]`.
- Prototype-hardening requirements: tests for the frontend behavior worth locking in, per
  the consuming project's testing conventions, plus real error, empty, and slow/loading
  states — the states fixtures never exercised (fixtures always succeed instantly; the
  spec names this blind spot).
- Fixture-zero requirement: at the final whole-branch review, `git grep TOOLBELT-FIXTURE`
  over the repo returns nothing. If the consuming project deliberately keeps fixtures
  (tests, storybook), the ledger records the exception and the requirement names the
  allowed locations.
- UX-gate criteria: "matches the approved prototype", with reference screenshots captured
  at the end of the prototype session.

**Error path:** if backend implementation later finds a recorded contract infeasible, that
is SDD's existing BLOCKED path — no new machinery. The one rule this skill adds: a
contract change agreed at that point is written back to the ledger, and the frontend gets
a task to adapt. The ledger stays the single source of truth for the API surface until
merge.

**Cleanup:** `.toolbelt/prototype/<feature-slug>/` is ignored scratch; delivery step 6's
existing cleanup removes it after merge. The ledger's content lives on in the spec.

### 2. Edit: `skills/brainstorming/SKILL.md` — the offer

Modeled on the existing visual-companion offer pattern. When the settled feature has a
significant user-facing surface, and after the design sections that do not depend on UI
detail are approved, the agent offers the frontend-first path **in its own message** —
only the offer, nothing else — and waits. Exact offer text:

> "This feature has a real user-facing surface — we could go frontend-first: I build the
> actual frontend against fixture-backed API routes in one sitdown session, we iterate
> until the design is right, and the backend gets implemented afterward from the contracts
> we settle. Want to? Otherwise I'll write the spec as usual."

- Accepted → the remaining UI-detail design work and the writing-specs handoff are
  replaced by invoking `toolbelt:interactive-design`. Acceptance satisfies the
  brainstorming HARD-GATE for this path: the approved intent-level design plus the accepted
  offer authorize prototype implementation as design activity.
- Declined → continue exactly as today; do not offer again unless your human partner
  raises it. Terminal state stays writing-specs.
- Backend-only features never get the offer.

### 3. Edit: `skills/writing-specs/SKILL.md` — entry gate

One sentence added to the `<ENTRY-GATE>`: arriving from `interactive-design` with a
reconciled contract ledger is a normal entry, equivalent to arriving from brainstorming
with an approved design. No other change to the skill.

### 4. Convention: `.toolbelt/prototyping.md` (optional, per consuming project)

Documented only inside the `interactive-design` skill, consistent with the other
`.toolbelt/*` policy files. When present it states: where fixture-backed routes live in
this repo, how to run the frontend dev server, and seed-data conventions. When absent the
agent infers all three and records its inferences in the ledger header. No schema beyond
those three topics; it is prose read by the agent, not parsed.

### 5. Contract ledger format

Path: `.toolbelt/prototype/<feature-slug>/contracts.md` in the consuming project's
worktree.

Header: feature name, branch, the marker string, and (only when `.toolbelt/prototyping.md`
was absent) the conventions the agent inferred.

One entry per endpoint the feature touches, at the same altitude writing-plans requires
for endpoints — method, path, request/response shape, status codes — so entries transfer
into the spec verbatim. Entry statuses:

- `[FIXTURE]` — new route, entirely canned. Fields: fixture location (`path:line`),
  request/response shapes, error statuses, and a `Notes` line carrying UI-derived
  semantics a backend implementer cannot see from the shape alone (sort contracts,
  pagination expectations, display-only fields).
- `[EXISTING — EXTENDED]` — real route with a fixture-backed addition; records only the
  delta plus the fixture location of the added part.
- `[EXISTING]` — consumed as-is; listed so the spec knows the feature's full API surface;
  no marker, no fixture field.
- `[IMPLEMENTED]` — set during SDD when a backend task replaces the fixture and removes
  the marker.

Invariant at all times after any edit: grep for the marker and the ledger agree on what is
still fake.

### 6. Codex interface metadata: `skills/interactive-design/agents/openai.yaml`

Mirrors `skills/quick-task/agents/openai.yaml`: `display_name`, `short_description`,
`default_prompt` for the Codex harness. Entry-point skills (quick-task, delivery) carry
this file; interactive-design is an entry-point skill.

## Data Flow

brainstorming (intent settled, offer accepted) → interactive-design (worktree ensured,
ledger scaffolded, prototype loop, reconciliation, human approval of contract inventory)
→ writing-specs (API section from ledger; fixture-replacement, hardening, fixture-zero,
and ux-gate requirements added; normal spec gates run — the alternate-harness reviewer now
also catches backend-infeasible contracts before planning) → writing-plans → delivery/SDD
on the same branch (backend tasks implement to the recorded shapes, flip ledger statuses,
remove markers; hardening tasks add frontend tests and non-happy-path states) → final
whole-branch review includes the fixture-zero grep → ux-gate compares against prototype
reference screenshots → finishing/pr-monitor unchanged.

## Error Handling

- **Ledger/marker mismatch at reconciliation:** fixed before handoff; the skill treats
  reconciliation as its own verification gate — writing-specs is not invoked until the
  ledger and code agree.
- **Infeasible contract during SDD:** existing BLOCKED path; agreed changes written back
  to the ledger plus a frontend adaptation task (component 1, error path).
- **`.toolbelt/prototyping.md` absent:** not an error; infer and record (component 4).
- **Routing/gates:** all existing review and routing failure modes are unchanged because
  no downstream skill changes.

## Testing

- **`tests/toolbelt/test-interactive-design.sh`**, following the `assert_contains` pattern
  of `tests/toolbelt/test-ux-gate.sh`:
  - `skills/interactive-design/SKILL.md` contains: `name: interactive-design`, the
    `TOOLBELT-FIXTURE` marker string, the ledger path
    `.toolbelt/prototype/`, the HARD-GATE sentence "a fixture without a ledger entry is a
    gate violation", the reconciliation requirement, and "Do NOT invoke any other skill."
  - `skills/brainstorming/SKILL.md` contains the frontend-first offer and its
    own-message requirement.
  - `skills/writing-specs/SKILL.md` ENTRY-GATE mentions `interactive-design`.
  - `skills/interactive-design/agents/openai.yaml` exists with a `display_name`.
- **Acceptance test** (manual, per CLAUDE.md): refresh both plugin caches
  (uninstall-first for Claude Code), fresh session in each harness:
  - UI-heavy prompt ("Let's build a dashboard for X") → brainstorming fires, and once
    intent settles the frontend-first offer appears as its own message.
  - Backend-only prompt ("Let's add a cron cleanup job") → no offer; normal handoff to
    writing-specs.
- The existing `tests/toolbelt/` suite stays green; if an existing test asserts
  brainstorming or writing-specs phrasing that these edits change, update the assertion
  with the phrase (per the project's stated test policy).
