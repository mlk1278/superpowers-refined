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
- **Single PR:** a frontend-first feature ships as one pull request. This is forced, not
  preferred: fixtures never reach the base branch, so no earlier slice can merge before
  every fixture is replaced. The plan's PR Boundaries section declares one PR with this
  standing justification. Because the whole feature lives in one worktree until merge,
  the ledger (ignored scratch) survives the entire execution; delivery's normal
  post-merge cleanup removes it.
- **Applicability:** the path applies only when the frontend and the API it consumes
  live in this repository (or its workspace). "Endpoint" means the unit of the project's
  API convention — REST method + path, GraphQL operation, RPC procedure. Projects that
  don't fit (frontend-only repos, third-party-API consumers) never get the offer.
- **Version:** bump to `7.6.0` in `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, and `package.json`
  (new-skill minor bump, per existing release practice; `7.5.0` is taken by the
  execution-tracks release merged into this branch).
- **Claude Design integration is out of scope** (deferred to a future iteration).

## Components

### 1. New skill: `skills/interactive-design/SKILL.md`

**Purpose:** run the one-session frontend prototype loop and deliver a reconciled contract
ledger to writing-specs.

**Description (frontmatter), exact text:**

> Use when your human partner accepts the frontend-first offer or asks to prototype the
> frontend before backend work — after brainstorming approves the intent-level design,
> before any spec exists.

Trigger-only by design; it names the two entry conditions and nothing about the workflow.

**Entry gate (`<ENTRY-GATE>`):** two ways in — brainstorming's offer accepted, or an
explicit request from your human partner. The agent never selects this path on its own.
Entry requires an **approved intent-level design** from brainstorming: what the feature
does, who uses it, the data it needs, and a first sketch of the contracts — presented and
approved like any brainstorming design, with UI-detail sections explicitly deferred to
the prototype session. This is the single entry threshold; components 1 and 2 use the
same term. A full UI design is NOT required — the prototype session is where it emerges.

**Setup:**
1. Ensure an isolated workspace: if the session is already in an isolated worktree, use
   it; otherwise invoke `toolbelt:using-git-worktrees`. The prototype branch is the same
   branch the backend plan later executes on.
2. Read `.toolbelt/prototyping.md` if present (see component 4). If absent, infer fixture
   location, frontend run command, and seed-data conventions from the codebase and record
   each inference in the ledger header.
3. Scaffold the contract ledger (component 5) and start the dev server.

**Fixture hard gate (`<HARD-GATE>`, verbatim in the skill):**

> Every datum the frontend would obtain from the backend in production comes from a real
> API route in this repo. No inline mock data, no hardcoded domain data in components, no
> frontend-side stub layers. A route that doesn't exist yet gets created as a real route
> handler returning fixture data, tagged with a greppable marker line naming its endpoint
> (`TOOLBELT-FIXTURE <endpoint id>`), and recorded in the contract ledger in the same
> edit — a fixture without a ledger entry is a gate violation.

The gate governs backend-owned data only: UI copy, labels, icons, layout constants, and
client-derived display values are not backend data and are exempt. The marker's
`<endpoint id>` is the ledger entry's identifier (e.g. `GET /api/projects/:id/insights`),
making marker↔ledger reconciliation deterministic even when one file holds several
handlers.

**The loop:** the session agent edits code directly — no subagent dispatch, no
per-iteration review; latency is the enemy in an interactive session. Frequent checkpoint
commits on the prototype branch; nobody reads this history. Whenever an iteration changes
what data the UI needs, the fixture and its ledger entry are updated in the same pass —
shape changes are never deferred. Before the design can be declared nailed, the loop
exercises the empty and error variants of each fixture-backed surface (fixture responses
make these cheap to serve) so those user-visible states are designed and approved here,
not invented later by an autonomous hardening task.

**Exit — reconciliation pass, then handoff.** When your human partner says the design is
nailed:
1. Verify every `TOOLBELT-FIXTURE` marker has a ledger entry matching its endpoint id and
   every `[FIXTURE]` / `[EXISTING — EXTENDED]` entry has a marker; verify each ledger
   shape matches what the fixture actually returns; delete dead routes left by abandoned
   iterations.
2. Write the visual and interaction acceptance criteria from the approved prototype —
   including the exercised empty and error states — into the ledger file; they graduate
   into the spec and are what ux-gate later consumes. (ux-gate captures its own
   screenshots against criteria; no prototype screenshots are kept.)
3. Present the final contract inventory to your human partner: "this is what the backend
   has to build."
4. On approval, invoke `toolbelt:writing-specs`. Do NOT invoke any other skill.

**Handoff requirements the skill instructs the agent to carry into the spec** (this is how
downstream stays unchanged — the requirements ride in the spec document):
- The spec's API section is lifted from the reconciled ledger.
- One fixture-replacement requirement per `[FIXTURE]` and `[EXISTING — EXTENDED]` entry:
  implement the real logic behind the exact recorded shape, remove the marker, flip the
  ledger status to `[IMPLEMENTED]`.
- Prototype-hardening requirements: tests for the frontend behavior worth locking in, per
  the consuming project's testing conventions, plus real handling for the timing states
  fixtures never exercised — loading and slow responses (fixtures always succeed
  instantly; the spec names this blind spot). Empty and error *appearances* were already
  designed and approved in the loop; hardening wires them to real conditions.
- Fixture-zero requirement, exact check: at the final whole-branch review,
  `git grep TOOLBELT-FIXTURE -- ':!docs/toolbelt' ':!.toolbelt'` exits 1 (no matches).
  The exclusions exist because the committed spec and plan legitimately name the marker —
  an absence check must exclude its own evidence. If the consuming project deliberately
  keeps fixtures (tests, storybook), the ledger records the exception and the requirement
  adds those paths to the exclusion list.
- UX-gate criteria: the visual and interaction acceptance criteria written at prototype
  exit, carried in the spec.
- Ledger synchronization: any contract change accepted during spec review or plan review
  is written back to the ledger and its fixture in the same round, before execution
  starts. The ledger and the spec's API section never diverge.
- Prototype-commit accounting: the prototype commits predate the plan and receive no
  task-level review; the plan states this, covers that code through the hardening tasks
  that modify and test it, and relies on the final whole-branch review — whose diff spans
  the merge-base and therefore includes every prototype commit — inside the single PR.

**Error path:** if backend implementation later finds a recorded contract infeasible, that
is SDD's existing BLOCKED escalation — the human adjudicates; no new machinery decides
anything. What this skill adds is the resolution protocol: the agreed change is applied to
the spec (amended and recommitted), the ledger and fixture updated to match, and the
affected plan tasks — including a frontend adaptation task — revised under that same
human approval before execution resumes. The spec's API section and the ledger move
together; neither is edited alone.

**Cleanup:** `.toolbelt/prototype/<feature-slug>/` is ignored scratch; delivery step 6's
existing cleanup removes it after merge. The ledger's content lives on in the spec.

### 2. Edit: `skills/brainstorming/SKILL.md` — the offer and the gate carve-out

Three precise text changes, no others:

1. **The offer.** Modeled on the existing visual-companion offer pattern. When the feature
   has a significant user-facing surface, its API lives in this repository (the
   applicability constraint), and the intent-level design sections are approved, the
   agent offers the frontend-first path **in its own message** — only the offer, nothing
   else — and waits. Exact offer text:

> "This feature has a real user-facing surface — we could go frontend-first: I build the
> actual frontend against fixture-backed API routes in one sitdown session, we iterate
> until the design is right, and the backend gets implemented afterward from the contracts
> we settle. Want to? Otherwise I'll write the spec as usual."

- Accepted → the remaining UI-detail design work and the writing-specs handoff are
  replaced by invoking `toolbelt:interactive-design`.
- Declined → continue exactly as today; do not offer again unless your human partner
  raises it. Terminal state stays writing-specs.
- Backend-only features and out-of-applicability projects never get the offer.

2. **HARD-GATE carve-out.** The existing HARD-GATE forbids all implementation before an
   approved design; "design activity" does not satisfy its literal text. Add one
   conditional sentence to the HARD-GATE block, keyed to an observable predicate:

   > Exception: when your human partner has approved the intent-level design and accepted
   > the frontend-first offer, invoke toolbelt:interactive-design — prototype
   > implementation inside that skill is authorized.

3. **"After the Design" fork.** The paragraph naming writing-specs as the sole next skill
   gains the accepted-offer branch: accepted offer → interactive-design; otherwise →
   writing-specs, unchanged. Each branch still names exactly one next skill.

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
for endpoints — so entries transfer into the spec verbatim. For REST that is method,
path, request/response shape, status codes; for other conventions, the project's API unit
(GraphQL operation, RPC procedure) with its request/response shapes and error modes. The
entry's identifier is what the fixture's marker line carries. Entry statuses:

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

After the exit reconciliation the ledger also carries an **Acceptance criteria** section:
the visual and interaction criteria written from the approved prototype (including the
exercised empty and error states), which graduate into the spec for ux-gate.

Invariant at all times after any edit: grep for the marker and the ledger agree on what is
still fake, and each marker's endpoint id resolves to exactly one ledger entry.

### 6. Codex interface metadata: `skills/interactive-design/agents/openai.yaml`

Mirrors `skills/quick-task/agents/openai.yaml`: `display_name`, `short_description`,
`default_prompt` for the Codex harness. Entry-point skills (quick-task, delivery) carry
this file; interactive-design is an entry-point skill.

## Data Flow

brainstorming (intent-level design approved, offer accepted) → interactive-design
(worktree ensured, ledger scaffolded, prototype loop with empty/error variants exercised,
reconciliation, acceptance criteria written, human approval of contract inventory)
→ writing-specs (API section and acceptance criteria from ledger; fixture-replacement,
hardening, fixture-zero, ledger-sync, and prototype-commit-accounting requirements added;
normal spec gates run — the alternate-harness reviewer now also catches
backend-infeasible contracts before planning; contract changes flow back to ledger and
fixtures) → writing-plans (single-PR boundary with standing justification) → delivery/SDD
on the same branch (backend tasks implement to the recorded shapes, flip ledger statuses,
remove markers; hardening tasks add frontend tests and loading/slow-state handling) →
final whole-branch review includes the scoped fixture-zero grep → ux-gate judges against
the spec's acceptance criteria with its own captures → finishing/pr-monitor unchanged.

## Error Handling

- **Ledger/marker mismatch at reconciliation:** fixed before handoff; the skill treats
  reconciliation as its own verification gate — writing-specs is not invoked until the
  ledger and code agree.
- **Infeasible contract during SDD:** existing BLOCKED escalation; the human-approved
  resolution amends the spec, updates ledger and fixture to match, and revises the
  affected plan tasks before execution resumes (component 1, error path).
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
- The test also asserts the fixture-zero check appears with its exclusions
  (`':!docs/toolbelt'` and `':!.toolbelt'`) — the self-matching-grep gotcha must not be
  reintroduced by a later edit.
- **Acceptance test** (manual, per CLAUDE.md): refresh both plugin caches
  (uninstall-first for Claude Code), fresh session in each harness:
  - UI-heavy prompt ("Let's build a dashboard for X") → brainstorming fires, and once the
    intent-level design is approved the frontend-first offer appears as its own message.
  - Backend-only prompt ("Let's add a cron cleanup job") → no offer; normal handoff to
    writing-specs.
  - **Accepted-path drill** (at least one harness): accept the offer in a scratch project
    and verify the orchestration, not the prose — interactive-design is invoked, a
    fixture route and its ledger entry appear in the same edit, the exit reconciliation
    runs, and the skill hands off to writing-specs. Decline in a second run and verify
    the offer is not repeated.
- The existing `tests/toolbelt/` suite stays green; if an existing test asserts
  brainstorming or writing-specs phrasing that these edits change, update the assertion
  with the phrase (per the project's stated test policy).
