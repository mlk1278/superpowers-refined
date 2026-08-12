# Interactive Design: Direct-Entry UI-Iteration Mode — Design Spec

A second mode of the existing `interactive-design` skill: your human partner enters
directly — "let's iterate on the settings page UI" — with no brainstorming, no offer, and
no intent-level design gate, because the existing feature is the design context. The loop
runs at full speed by deferring fixture creation: data needs are recorded as `[PENDING]`
ledger entries in the same edit, materialized against the real API surface at the end of
the session, and the exit routes by delta size to quick-task or writing-specs. New-feature
mode is unchanged.

## Global Constraints

- All changes land in `skills/interactive-design/SKILL.md` and
  `tests/toolbelt/test-interactive-design.sh` plus version files. No other skill changes —
  brainstorming, writing-specs, and quick-task are consumed as they are.
- Pending status string: exactly `[PENDING]`.
- Existing forceful blocks are add-text-only: the ENTRY-GATE and HARD-GATE gain sentences;
  no existing sentence inside either block is reworded.
- Existing section numbering (§1–§7) and every existing test needle stay valid: the new
  material is one appended section (§8) plus additive edits, never a renumbering.
- Frontmatter stays exactly two fields, ≤ 1024 characters total, description trigger-only,
  third person. Phrasing: "your human partner", never "the user".
- New-feature mode behavior is byte-identical except where §8 explicitly scopes a rule to
  iteration mode: `[PENDING]` is forbidden outside iteration mode.
- Version: bump to `7.7.0` in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `.codex-plugin/plugin.json`, and `package.json` (all currently `7.6.0`).

## Components

### 1. Description — second trigger, exact text

> Use when your human partner accepts the frontend-first offer or asks to prototype the
> frontend before backend work — after brainstorming approves the intent-level design —
> or asks to iterate directly on an existing feature's UI, changing what information it
> shows. Direct UI iteration needs no prior design or spec.

(319 bytes by `printf %s '<value>' | wc -c`; well under the frontmatter limit.)

### 2. ENTRY-GATE — third way in, appended sentences

Appended inside the existing `<ENTRY-GATE>` block, after its current text:

> Third way in, for existing features: your human partner asks to iterate directly on an
> existing surface's UI. No intent-level design is required — the existing feature is the
> design context and the request itself is the entry. The repository requirement above
> still applies.

### 2b. HARD-GATE — scoped deferral sentence, appended inside the block

The deferral must live inside the forceful block itself, not in later prose — otherwise
the gate's absolute prohibition and the exception compete. Appended after the block's
current last sentence:

> In iteration mode (§8) only, a datum may instead render placeholder data while a
> `[PENDING]` ledger entry naming it is recorded in the same edit — a placeholder without
> a `[PENDING]` entry is a gate violation.

### 3. Ledger — `[PENDING]` status (§7 addition)

One status added to §7's status list:

- `[PENDING]` — iteration mode only: a datum rendered with placeholder data while its
  backing is deferred. Entries live in a separate **Pending** ledger subsection with
  stable ids (`P1`, `P2`, …), one per datum — not per endpoint, since the endpoint is not
  yet known. Fields: the surface/component showing it, what data is needed, and the
  expected shape. No fixture, no marker yet. Invariant additions: a `[PENDING]` entry
  exists only during an iteration-mode session, and the session cannot exit §8's
  materialization step until the Pending subsection is empty.
- §7's closing durability sentence is scoped by route: content lives on in the spec on
  the writing-specs route, or in the quick-task request and PR description on the
  quick-task route.

### 4. New section `## 8. Iteration mode (existing features)`

Appended after §7 so no existing section number or cross-reference moves. Contents:

**Announce variant:** "I'm using interactive-design to iterate on this UI with
ledger-tracked data changes."

**Announce scoping:** §8's announcement replaces the top-level announcement in iteration
mode.

**The gate delta.** The `[PENDING]` deferral is authorized by the HARD-GATE's own new
sentence (component 2b); §8 restates it with the mechanics: entry recorded in the
Pending subsection with a stable id, same edit as the placeholder. Everything else about
the gate (backend-owned data only, the exemption list, marker format for actual
fixtures) applies unchanged. Creating a real fixture immediately instead of a
`[PENDING]` entry is always allowed.

**Materialization — runs when the design is declared nailed, before §4's reconciliation.**
For each pending id, inspect the real API surface and map it to an endpoint entry —
several pending ids may coalesce into one endpoint entry — resolving each endpoint to:

- `[EXISTING]` — an endpoint already serves the data: wire the frontend to it, delete the
  placeholder.
- `[EXISTING — EXTENDED]` — an endpoint needs a delta: create the fixture for the delta
  with its marker, record the delta.
- `[FIXTURE]` — no endpoint fits: create the fixture route with its marker.

Then delete the emptied Pending subsection. Materialization may change what renders:
re-exercise each affected surface — including the empty and error variants of anything
newly fixture-backed — and return visible changes to the loop for your human partner's
approval before reconciliation. The Pending subsection is empty before §4's
reconciliation may run. From reconciliation on, the exit is §4's — same marker/ledger
checks, same acceptance criteria, same contract-inventory presentation.

**Exit routing — §4 step 4 is mode-scoped at its source.** §4 step 4 becomes: "On
approval, invoke the mode's terminal skill — new-feature mode: `toolbelt:writing-specs`;
iteration mode: the single route confirmed in §8. Do NOT invoke any other skill." §8
then decides that route: with the inventory presented, recommend one and let your human
partner confirm; invoke the confirmed skill and no other:

- **Small and decision-complete** — the delta fits quick-task's own entry bar (one
  coherent outcome, one PR, no product shaping): invoke `toolbelt:quick-task`. The
  quick-task request carries every applicable §5 delivery obligation as its
  requirements: implement each `[FIXTURE]` / `[EXISTING — EXTENDED]` shape exactly,
  remove markers, flip entries to `[IMPLEMENTED]`, meet the acceptance criteria, add
  frontend tests per project conventions, handle loading and slow responses, and satisfy
  §5's fixture-zero check before the PR merges.
- **Substantial** — anything above that bar: invoke `toolbelt:writing-specs`, exactly as
  new-feature mode does; §5 applies as written.

If quick-task later discovers the change needs product shaping after all, its own
escalation applies — it routes to brainstorming and writing-plans, per its own text.

**Single-PR rule.** Unchanged in this mode: fixtures never reach the base branch, so the
session's UI changes and their backend delta ship together in one PR whichever route is
taken.

### 5. Test additions (`tests/toolbelt/test-interactive-design.sh`)

New `assert_contains` lines, following the file's existing style — file, needle,
description:

- `SKILL.md` — `iterate directly on an existing feature's UI` — second trigger in the
  description
- `SKILL.md` — `the request itself is the entry` — ENTRY-GATE third way in
- `SKILL.md` — `[PENDING]` — pending status documented
- `SKILL.md` — `a placeholder without` — placeholder gate teeth
- `SKILL.md` — `before §4's reconciliation may run` — materialization is a gate
- `SKILL.md` — `toolbelt:quick-task` — small-delta route named
- `SKILL.md` — `the single route confirmed in §8` — §4 step 4 mode-scoped at source
- Structural assertion: extract the `<HARD-GATE>…</HARD-GATE>` block and assert it
  contains `[PENDING]` — the deferral must live inside the forceful block, not only in
  §8 prose.
- Each needle must sit within a single line of the skill file as written (the existing
  `grep -F` line-based constraint).

## Data Flow (iteration mode)

Direct request → announce variant, setup per §1 (worktree ensure, ledger scaffold, dev
server) → loop: UI edits with `[PENDING]` entries recorded same-edit; creating a real fixture
immediately instead of a `[PENDING]` entry is always allowed → design nailed → materialization resolves
every `[PENDING]` against the real API → §4 reconciliation + acceptance criteria +
inventory → human-confirmed routing: quick-task (small) or writing-specs (substantial) →
delivery as that skill defines it; fixture-zero grep before merge either way.

## Error Handling

- **`[PENDING]` remaining at exit:** materialization is a hard gate; the session cannot
  proceed to reconciliation until each entry is resolved. An entry that cannot be
  resolved (data has no plausible source) goes to your human partner as a design
  question, not a silent deletion.
- **Contract infeasible during delivery:** §6 unchanged, both routes.
- **Route outgrown mid-delivery:** quick-task's existing escalation; fallback is
  writing-specs.
- **New-feature mode regression risk:** none by construction — §8 is additive and
  self-scoped; the only shared-text edits are the description, the ENTRY-GATE appendix,
  and the §7 status row, all additive.

## Testing

- The assertions in component 5, appended to the existing test file; existing 21
  assertions must keep passing unmodified.
- **Acceptance drill** (manual, post-release, per the repo's cache-refresh procedure):
  fresh session, "let's iterate on the <existing surface> UI" → skill fires directly with
  the iteration announce line, no brainstorming, no offer; a placeholder datum appears
  only alongside its `[PENDING]` entry; at exit the routing recommendation is presented
  and the confirmed route is invoked. A new-feature-mode run (offer path) behaves exactly
  as before.
