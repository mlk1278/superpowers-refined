---
name: ux-gate
description: "Use before final review of new user flows or material changes to interaction, layout, or responsive behavior, or when UX review is explicitly requested. Routine color, copy, or isolated CSS adjustments do not trigger this review on their own."
---

# UX Gate

**Announce:** "I'm running the UX gate for <surface>."

**Entry:** changed routes, base..head range, approved acceptance criteria, and a running isolated environment. Judge the rendered effect, not line count: a one-line shared-layout change can need review; a button-color adjustment normally does not.
**Exit:** `Pass` bound to the reviewed head SHA, or `Changes Required` with component-level findings. The gate does not fix anything.

## Ownership

The gate operator captures evidence; a reviewer routed with specialty `ux` judges it. The orchestrator never captures UX evidence; the implementer captures only its own task's smoke pass. A task smoke pass runs scripted checks without invoking this reviewer.

## 0. Runtime preflight

The environment must serve the changed routes with queryable data before capture. Without preflight evidence the gate cannot run, and nothing downstream may claim UX was verified.

## 1. Choose coverage

Derive the smallest set of navigation pathways covering what this diff changed. Include the acceptance criteria's entry points and states.

Read `.toolbelt/ux-policy.md` when present for Launch, Auth, Theme, Data, viewports, exceptions, design reference, reference screens, and harness notes. Infer missing launch, auth, and theme conventions and record them.

Enumerate the capture matrix before running it:

- Use relevant breakpoints for changed markup, copy, or layout, including shared styling or layout the step consumes. Use one representative width when presentation cannot vary.
- Capture every supported theme for every changed surface.
- Exercise criteria-named states with isolated fixtures or seeded data: empty, loading, error, dense data, and overlays as applicable.
- Check hover or focus appearance when it changes, keyboard reach and activation for changed interactions, and scrolling when content extends past the fold. Use `press` and `expectFocus` for keyboard checks; direct `focus` does not prove Tab reachability. Use `capture: false` for steps that need assertions but no images.
- Mark changed motion with `motion: true`. Repeat interaction checks across dimensions only when behavior can differ.

Record the reason for omitted dimensions. Choose enough evidence for the feature's complexity; there is no fixed image-count limit.

## 2. Capture

Read [matrix.md](matrix.md) for the input schema and actions. Write `.toolbelt/ux/matrix.json`. Resolve this skill's absolute directory as `UX_SKILL_DIR` from its loaded path, then run from the project root:

```bash
"$UX_SKILL_DIR/scripts/ux-capture" .toolbelt/ux/matrix.json \
  --project-root "$PWD" --out .toolbelt/ux/head/ \
  --baseline .toolbelt/ux/baseline/
```

Use interactive-design's prototype baseline when present; otherwise capture the base branch with the same matrix into the baseline directory first. Stills are `<pathway>-<step>-<state>-<width>-<theme>.png`. A step the script cannot complete is a finding, not a skip. Exit 2 means capture could not run; resolve it before review.

## 3. Mechanical findings first

Every mechanical finding at `should` or above goes to the fix loop before image review. Run any token or palette check named in the policy and attach its output. An unavailable optional check is a reported limitation, not evidence that it passed.

## 4. Review

Resolve one `reviewer` with specialty `ux` via agent-routing; use a vision-capable model. Send relevant changed/new captures, useful crops or filmstrips, and reference screens. Include unchanged captures needed to judge an acceptance criterion. Omit redundant images; do not discard meaningful changes because their whole-image pixel ratio is small.

Put images first, labelled `Image N: <tag>`, then criteria, mechanical results, and the design-reference path. The reviewer reads `docs/REVIEW-GUIDANCE.md` when present and judges without driving the browser:

> Pass 1: mark each criterion met, not met, or not evidenced, citing the evidence.
>
> Pass 2: identify visible inconsistencies or usability problems in spacing, alignment, typography, contrast, action hierarchy, and states. Use the project's design rules and reference screens. Explain the consequence and relevant criterion or convention. Distinguish legitimate disabled states from unfinished controls. Code review checks component imports; screenshots cannot establish them.
>
> Each finding names a severity (blocker, should, nit), the evidence, expected and actual behavior, and component/file when known. Missing evidence can block a criterion.

The operator maps findings to owning files when the reviewer cannot.

## 5. Fix loop

Send blockers and shoulds to the owning implementer; list nits in the PR description. Then rerun the capture script on the new head for affected pathways, including one nearest previously passing unchanged state for each affected component. Use `--pathway` and `--out .toolbelt/ux/head-<n>/`, comparing each pathway to its last capture directory.

Carry unaffected evidence forward only while its rendered dependencies and fixtures are unchanged: a shared style or token change invalidates every consuming capture. Record carried versus recaptured evidence and its source head. Send relevant updates to the same reviewer thread. After two unsuccessful rounds, send your human partner the remaining findings and evidence.

Report pathways covered separately from raw screenshot count.

## Rules

- One primary UX reviewer by default; explain any need for another.
- Do not manufacture states by editing app source. Use isolated fixtures and seeded data.
- Every round binds to the reviewed head; a new push invalidates prior evidence except recorded carry-forward. Apply the docs-only rule in toolbelt:finishing-a-development-branch Step 1.
- Run this gate before the final gate verdict so its fixes land in the reviewed head.
