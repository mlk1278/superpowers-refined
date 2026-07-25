---
name: ux-gate
description: Scripted-capture UX verification of changed user-visible surfaces against approved visual and interaction acceptance criteria. Internal gate run before the final gate verdict; returns Pass or Changes Required.
---

# UX Gate

**Announce:** "I'm running the UX gate for <surface>."

**Entry:** a context bundle — changed surface routes, the base..head range, the approved acceptance criteria (visual, interaction, responsive, accessibility, copy), and how to reach a running isolated environment.
**Exit:** `Pass` bound to the reviewed head SHA, or `Changes Required` with component-level findings. The gate does not fix anything.

Never review by navigating the browser interactively — manual navigation burns tokens and leaves no rerunnable evidence. Capture is scripted; judgment happens over the resulting images.

Ownership follows delivery's role-ownership table: this gate runs in a dedicated gate-operator subagent dispatched by the orchestrator, and that operator owns scripted capture; a routed vision-capable reviewer owns judgment. Neither the orchestrator nor the implementer captures UX evidence, and task briefs must not reassign this.

## 0. Runtime preflight

The environment must actually serve the changed routes with queryable data before capture starts. No preflight evidence means the gate cannot run, and nothing downstream may claim UX was verified.

## 1. Pathways from the actual diff

Derive the smallest set of navigation pathways covering what this diff changed — the flows, entry points, and states the criteria name, not a generic tour of the application.

## 2. Scripted capture

Enumerate the capture matrix — pathways × states × dimensions — before capturing anything. Widths: capture the supported breakpoints (small ~375px, medium ~768px, large ~1440px) for steps whose markup, copy, layout, or responsive styling the diff touches — including shared styling or layout the step consumes; one representative width suffices where a step's presentation is unchanged. Themes: supported themes only, and only when theme-specific styles or tokens changed or the acceptance criteria require them. Record why any excluded dimension cannot vary. Plans and briefs may bind required coverage through acceptance criteria, but a fixed screenshot count or an unexplained full Cartesian product is a conflict to surface, not obey. Write a throwaway Playwright script under ignored `.toolbelt/ux/` that walks the matrix, naming files `<pathway>-<step>-<state>-<width>[-<theme>].png`. Exercise the states the criteria name (empty, loading, error, dense data, overlays, overflow) using isolated fixtures or seeded test data. Run the script once per review round. A step the script cannot complete (auth, data, a dead route) is a finding, not a skip. The script is scratch: rerunnable after every fix, deleted at gate close, never committed.

## 3. Review the captures

Resolve one `reviewer` with specialty `ux` via agent-routing; the route must resolve to a vision-capable model. The reviewer reads `docs/REVIEW-GUIDANCE.md` when the project provides it, then judges the screenshot set against the approved criteria — never personal taste — without driving the browser. Each finding names component file + visual state + viewport + specific deviation + screenshot reference; findings missing a screenshot or component file are unroutable and do not count.

## 4. Fix loop

Route the finding set to the owning implementer thread, rerun the capture script on the new head for the affected pathways plus one nearest previously passing unchanged state for each affected component within them (record these as the comparison), and send the fresh set to the same reviewer thread. Unaffected captures carry forward only while their rendered dependencies and fixtures are unchanged — a shared style or token change invalidates every consuming capture; record carried vs recaptured. The verdict reports pathways covered separately from raw screenshot count. Every round and the final `Pass` bind to the head SHA that was reviewed; a new push invalidates prior evidence. Exception: commits that touch only Markdown files under `docs/**` or at the repository root, or `.toolbelt/**` scratch, carry the evidence forward — record it explicitly ("Pass at `<sha>`; head advanced by docs-only `<sha>..<sha>`"). A file the application builds, renders, or serves, or that supplies copy or content shown by the surfaces under review, never qualifies regardless of path. Any other change — code, tests, config, migrations, CI — invalidates as before. Run this gate before the final gate verdict so its fixes land in the gated head.

## Rules

- One primary UX reviewer by default; an additional reviewer needs an explicit written reason such as a broad redesign or an accessibility specialty.
- Do not manufacture states by editing app source. Isolated fixtures and seeded test data are fine; production or shared-user data is not.
