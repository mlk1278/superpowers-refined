---
name: ux-gate
description: Use to verify changed user-visible surfaces before a boundary's final review: scripted capture, mechanical checks, pixel diff against a baseline, and a two-pass vision review. Returns Pass or Changes Required.
---

# UX Gate

**Announce:** "I'm running the UX gate for <surface>."

**Entry:** a context bundle — changed surface routes, the base..head range, the approved acceptance criteria, and how to reach a running isolated environment.
**Exit:** `Pass` bound to the reviewed head SHA, or `Changes Required` with component-level findings. The gate does not fix anything.

## Ownership

The gate operator owns capture; a reviewer routed with specialty `ux` owns judgment. The orchestrator never captures UX evidence; the implementer captures only its own task's smoke pass.

## 0. Runtime preflight

The environment must serve the changed routes with queryable data before capture starts. No preflight evidence means the gate cannot run, and nothing downstream may claim UX was verified.

## 1. Pathways from the diff

Derive the smallest set of navigation pathways covering what this diff changed — the flows, entry points, and states the criteria name, not a tour of the application.

## 2. Capture

Read `.toolbelt/ux-policy.md` when the project has one: Launch, Auth, Theme, Data, viewports and themes, allowed exceptions, design reference, reference screens, harness notes. When it is absent, infer Launch, Auth, and Theme, record each inference, and use the default viewports and both themes.

Enumerate the capture matrix — pathways × states × dimensions — before capturing anything. Widths: the supported breakpoints for steps whose markup, copy, layout, or responsive styling the diff touches — including shared styling or layout the step consumes; one representative width suffices where a step's presentation is unchanged. Capture every supported theme for every changed surface. States: the ones the criteria name (empty, loading, error, dense data, overlays, overflow), from isolated fixtures or seeded test data. Also exercise hover, focus, and keyboard reach on each changed control, one scroll position past the fold, and every step that opens, closes, or transitions, marked `motion`. Record why any excluded dimension cannot vary. A fixed screenshot count or an unexplained full Cartesian product is a conflict to surface, not obey.

Write the matrix to `.toolbelt/ux/matrix.json`, then run `scripts/ux-capture` from this skill's directory, `--out` into that ignored directory, `--baseline` at `.toolbelt/ux/baseline/` when interactive-design's prototype captures are there, otherwise at a capture of the base branch from the same matrix. Stills are named `<pathway>-<step>-<state>-<width>-<theme>.png`. A step the script cannot complete — auth, data, a dead route — is a finding, not a skip.

## 3. Mechanical findings first

Every mechanical finding at `should` or above is a finding before any image reaches the reviewer. Route those to the fix loop with the capture; the reviewer sees the remaining set.

## 4. Review

Resolve one `reviewer` with specialty `ux` via agent-routing; the route must resolve to a vision-capable model. Send only changed and new captures, their diff crops, filmstrips, and reference screens. Images go first, each labelled `Image N: <tag>`, then the acceptance criteria, the mechanical report, and the design reference doc's path from the policy. The reviewer reads `docs/REVIEW-GUIDANCE.md` when the project provides it and judges without driving the browser, under this instruction:

> Pass 1, criteria: for each acceptance criterion, met, not met, or not evidenced, with the image that shows it.
>
> Pass 2, design: judge the changed surfaces against the project's design reference and the two reference screens using these checks: spacing on the project's scale (default 8pt); alignment to shared edges; type scale and hierarchy; contrast; internal padding no larger than external margin; one primary action per context; components composed from the project's primitives rather than ad hoc equivalents; empty, loading, and error states that match the loaded layout; no placeholder or disabled controls shipped as final. Then answer once: where would a designer wince, and why?
>
> Every finding carries a severity (blocker, should, nit), the image reference, the component or file when you can name it, expected, and actual. A finding without an image reference is not a finding.

A finding the reviewer could not attach to a file is mapped by the operator from the diff, not discarded. A finding without a screenshot reference does not count.

## 5. Fix loop

Blockers and shoulds go to the owning implementer thread; nits go in the PR description. Then rerun the capture script on the new head: mechanical checks over the whole matrix, stills for the affected pathways plus one nearest previously passing unchanged state for each affected component within them. Diff against the previous round; send only changed images to the same reviewer thread. Unaffected captures carry forward only while their rendered dependencies and fixtures are unchanged — a shared style or token change invalidates every consuming capture; record carried vs recaptured. Two rounds, then the owner gets the receipts.

The verdict reports pathways covered separately from raw screenshot count.

## Budget

Per round: at most 25 images, desktop at DPR 1, crops at DPR 2, filmstrips only where motion exists, video never.

## Rules

- One primary UX reviewer by default; a second needs an explicit written reason.
- Do not manufacture states by editing app source. Isolated fixtures and seeded test data are fine; production or shared-user data is not.
- Every round and the final `Pass` bind to the head SHA that was reviewed; a new push invalidates prior evidence. The docs-only rule in toolbelt:finishing-a-development-branch Step 1 carries the evidence forward — record it explicitly ("Pass at `<sha>`; head advanced by docs-only `<sha>..<sha>`").
- Run this gate before the final gate verdict so its fixes land in the gated head.
