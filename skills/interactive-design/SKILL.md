---
name: interactive-design
description: "Use when your human partner accepts the frontend-first offer or asks to prototype the frontend before backend work — after brainstorming approves the intent-level design — or asks to iterate directly on an existing feature's UI, changing what information it shows. Direct UI iteration needs no prior design or spec."
---

# Interactive Design

**Announce:** "I'm using interactive-design to prototype the frontend against fixture-backed contracts."

Building the frontend is the design work. You and your human partner iterate on the real UI in one sitting while every backend-owned datum arrives through a real API route returning fixture data. The output is working frontend code plus a reconciled contract ledger — the API the backend must now implement, settled by use rather than by argument.

<ENTRY-GATE>
Two ways in: your human partner accepted brainstorming's frontend-first offer, or asked
for this path directly. Never select this path yourself. Entry requires an approved
intent-level design from brainstorming — what the feature does, who uses it, the data it
needs, and a first sketch of the contracts — with UI detail deferred to this session.
The feature's frontend and the API it consumes must live in this repository (or its
workspace); if they don't, stop and tell your human partner this path does not apply.
Third way in, for existing features: your human partner asks to iterate directly on an
existing surface's UI. No intent-level design is required — the existing feature is the
design context and the request itself is the entry. The repository requirement above
still applies.
</ENTRY-GATE>

## 1. Setup

1. Ensure an isolated workspace. If you are already in an isolated worktree, use it; otherwise invoke `toolbelt:using-git-worktrees`. The prototype branch is the branch the backend plan later executes on.
2. Read `.toolbelt/prototyping.md` when the project provides it — it states where fixture-backed routes live, how to run the frontend dev server, and seed-data conventions. When it is absent, infer all three and record each inference in the ledger header.
3. Scaffold the ledger (§7) and start the dev server.

## 2. The fixture gate

<HARD-GATE>
Every datum the frontend would obtain from the backend in production comes from a real
API route in this repo. No inline mock data, no hardcoded domain data in components, no
frontend-side stub layers. A route that doesn't exist yet gets created as a real route
handler returning fixture data, tagged with a greppable marker line naming its endpoint
(`TOOLBELT-FIXTURE <endpoint id>`), and recorded in the contract ledger in the same
edit — a fixture without a ledger entry is a gate violation.
In iteration mode (§8) only, a datum may instead render placeholder data while a
`[PENDING]` ledger entry naming it is recorded in the same edit — a placeholder without
a `[PENDING]` entry is a gate violation.
</HARD-GATE>

The gate governs backend-owned data only. UI copy, labels, icons, layout constants, and client-derived display values are exempt. The marker's `<endpoint id>` is the ledger entry's identifier — for example `GET /api/projects/:id/insights`.

## 3. The loop

Edit directly in this session: no subagent dispatch, no per-iteration review. Commit checkpoints frequently. On every shape change, update the fixture and its ledger entry in the same pass. Before the design may be declared nailed, exercise the empty and error variants of each fixture-backed surface through its fixture responses.

## 4. Exit

1. Reconcile. Every marker has a ledger entry matching its endpoint id, and every `[FIXTURE]` / `[EXISTING — EXTENDED]` entry has a marker (`[EXISTING]` and `[IMPLEMENTED]` entries carry none). Recorded shapes match what the fixtures actually return. Delete dead routes.
2. Write the **Acceptance criteria** section into the ledger — visual and interaction criteria from the approved prototype, including the exercised empty and error states. ux-gate consumes these criteria later and captures its own screenshots; keep no prototype screenshots.
3. Present the final contract inventory to your human partner.
4. On approval, invoke the mode's terminal skill — new-feature mode: `toolbelt:writing-specs`; iteration mode: the single route confirmed in §8. Do NOT invoke any other skill.

## 5. What the spec must carry

- API section lifted from the ledger.
- One fixture-replacement requirement per `[FIXTURE]` / `[EXISTING — EXTENDED]` entry: implement the exact recorded shape, remove the marker, flip the entry to `[IMPLEMENTED]`.
- Hardening requirements: frontend tests per project conventions, plus loading and slow-response handling — the empty and error appearances were already approved in the loop.
- The fixture-zero check, stated below.
- ux-gate criteria are the ledger's Acceptance criteria.
- Ledger synchronization: contract changes accepted in spec or plan review are written back to ledger and fixture in the same round.
- Prototype-commit accounting: prototype commits predate the plan and are covered by the hardening tasks and the final whole-branch review, inside the single PR.
- Single-PR mandate, with its standing justification: fixtures must never reach the base branch.

The fixture-zero check:

```
git grep TOOLBELT-FIXTURE -- ':!docs/toolbelt' ':!.toolbelt'
```

exits 1 (no matches) at the final whole-branch review. Projects that deliberately keep fixtures (tests, storybook) record the exception in the ledger and add those paths to the exclusion list.

## 6. When a contract turns out infeasible

During SDD this is the existing BLOCKED escalation. The human-approved resolution amends the spec, updates ledger and fixture to match, and revises the affected plan tasks — including a frontend adaptation task — before execution resumes. The spec's API section and the ledger move together, always.

## 7. The ledger

- Path: `.toolbelt/prototype/<feature-slug>/contracts.md`. Header: feature, branch, marker string, and inferred conventions when `.toolbelt/prototyping.md` was absent.
- One entry per endpoint at plan altitude (REST: method, path, request/response shapes, status codes; other conventions: the project's API unit — GraphQL operation, RPC procedure — with shapes and error modes). The entry's identifier is what the marker line carries.
- Statuses: `[FIXTURE]` (new route, canned; fields: fixture `path:line`, shapes, error statuses, `Notes` line for UI-derived semantics), `[EXISTING — EXTENDED]` (delta + fixture location only), `[EXISTING]` (consumed as-is, no marker), `[IMPLEMENTED]` (set during SDD when the fixture is replaced and the marker removed), `[PENDING]` (iteration mode only, §8: a datum rendered with placeholder data while its backing is deferred; lives in a separate **Pending** ledger subsection with a stable id — `P1`, `P2`, … — one per datum, since the endpoint is not yet known; fields: the surface/component showing it, what data is needed, the expected shape; no fixture, no marker yet).
- After exit reconciliation the ledger adds an **Acceptance criteria** section: visual and interaction criteria from the approved prototype, including the exercised empty and error states.
- Invariant: marker grep and ledger agree on what is still fake; each marker's endpoint id resolves to exactly one entry. The Pending subsection exists only during an iteration-mode session and never survives §8's materialization.

```markdown
### GET /api/projects/:id/insights — [FIXTURE]
Fixture: app/api/projects/[id]/insights/route.ts:12
Response 200: { insights: [{ id: string, title: string, score: number, updatedAt: ISO8601 }] }
Errors: 404 unknown project, 500 generic
Notes: `score` is 0–100; the UI renders < 40 as "needs attention".

### PATCH /api/projects/:id — [EXISTING — EXTENDED]
Delta: request accepts `archivedAt: ISO8601 | null`; response echoes it.
Fixture: app/api/projects/[id]/route.ts:48
```

The ledger directory is ignored scratch, removed by delivery's post-merge cleanup. Its content lives on in the spec on the writing-specs route, or in the quick-task request and PR description on the quick-task route.

## 8. Iteration mode (existing features)

For direct entry on an existing surface (the ENTRY-GATE's third way in).

**Announce:** "I'm using interactive-design to iterate on this UI with ledger-tracked data changes." In this mode, this announcement replaces the top-level one.

**The gate delta.** The `[PENDING]` deferral is authorized by §2's HARD-GATE itself: a datum may render placeholder data only while a `[PENDING]` entry naming it — surface, data needed, expected shape — is recorded in the ledger's Pending subsection, with a stable id, in the same edit. Everything else about the gate — backend-owned data only, the exemption list, the marker format for actual fixtures — applies unchanged. Creating a real fixture immediately instead of a `[PENDING]` entry is always allowed.

**Materialization.** Runs when the design is declared nailed, before §4's reconciliation. For each pending id, inspect the real API surface and map it to an endpoint entry — several pending ids may coalesce into one endpoint entry — resolving each endpoint to:

- `[EXISTING]` — an endpoint already serves the data: wire the frontend to it, delete the placeholder.
- `[EXISTING — EXTENDED]` — an endpoint needs a delta: create the fixture for the delta with its marker, record the delta.
- `[FIXTURE]` — no endpoint fits: create the fixture route with its marker.

Then delete the emptied Pending subsection. Materialization may change what renders: re-exercise each affected surface — including the empty and error variants of anything newly fixture-backed — and return visible changes to the loop for your human partner's approval. The Pending subsection is empty before §4's reconciliation may run. A pending id that cannot be resolved — the data has no plausible source — goes to your human partner as a design question, never a silent deletion. From reconciliation on, the exit is §4's: same marker/ledger checks, same acceptance criteria, same contract-inventory presentation.

**Exit routing.** This section decides the "route confirmed in §8" that §4 step 4 invokes for this mode. With the inventory presented, recommend a route and let your human partner confirm:

- **Small and decision-complete** — the delta fits quick-task's own entry bar (one coherent outcome, one PR, no product shaping): invoke `toolbelt:quick-task`. The request carries every applicable §5 delivery obligation as its requirements: implement each `[FIXTURE]` / `[EXISTING — EXTENDED]` shape exactly, remove markers, flip entries to `[IMPLEMENTED]`, meet the acceptance criteria, add frontend tests per project conventions, handle loading and slow responses, and satisfy §5's fixture-zero check before the PR merges.
- **Substantial** — anything above that bar: invoke `toolbelt:writing-specs`, exactly as new-feature mode does; §5 applies as written.

If quick-task later discovers the change needs product shaping after all, its own escalation applies — it routes to brainstorming and writing-plans, per its own text.

**Single PR, unchanged:** fixtures never reach the base branch, so the session's UI changes and their backend delta ship together in one PR whichever route is taken.
