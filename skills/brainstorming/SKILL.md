---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.

Exception: when your human partner has approved the intent-level design and accepted the
frontend-first offer, invoke toolbelt:interactive-design — prototype implementation
inside that skill is authorized.
</HARD-GATE>

The design can be a few sentences, but you MUST present it and get approval.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — files, docs, recent commits
2. **Assess scope** — if the request spans multiple independent subsystems, decompose it into sub-projects before refining details: what are the independent pieces, how do they relate, what order should they be built? Backlog the rest and plan the first part.
3. **Ask clarifying questions** — one at a time, until you can state the design
4. **Propose approaches** — when several are genuinely viable, with trade-offs and your recommendation
5. **Present the design** — in sections, approval after each
6. **Hand off** — to writing-specs once your human partner has approved the whole design, or to interactive-design when they accepted the frontend-first offer (or to design-fidelity-prep when they chose the offer's Claude Design variant)

Offer the visual companion just-in-time, outside this sequence — see below.

**The terminal state is invoking writing-specs — or interactive-design (or design-fidelity-prep, for the offer's Claude Design variant) when the frontend-first offer was accepted.**

## Asking Good Questions

Ask a question only when its answer would change what you build.

- **Ask about the problem, not the solution.** When the request names a solution, find out what problem it solves.
- **Chase the assumption you are most likely to get wrong.** Who uses this, what happens when it fails, what "done" looks like, what is out of scope.
- **State inferences instead of asking about them.** "I'm assuming X — correct me."
- **Stop when questions stop changing the design.** Then present.

Check the project state yourself. Dispatch background subagents to read the codebase, prior art, and external references while the conversation continues. Reserve questions for what only your human partner knows.

## Presenting the Design

- Scale each section to its complexity: a few sentences up to 200-300 words
- Cover architecture, components, data flow, error handling, testing
- Ask after each section whether it looks right. Clarify when it doesn't land.
- Break the system into units with one clear purpose and well-defined interfaces. For each: what does it do, how is it used, what does it depend on? If a consumer has to read the internals, or you can't change the internals without breaking consumers, the boundary is wrong.
- In existing codebases, follow existing patterns. Include targeted improvements where existing problems affect this work. No unrelated refactoring.

## After the Design

When your human partner accepted the frontend-first offer, the next skill is
toolbelt:interactive-design — or design-fidelity-prep when they chose the
offer's Claude Design variant — invoke it and no other. Otherwise:

Once your human partner has approved every section, **invoke the writing-specs skill.** Do NOT invoke any other skill. writing-specs is the next step.

## Frontend-First Offer

Offer this path when the feature has a significant user-facing surface, its frontend and the API it consumes live in this repository, and the intent-level design sections — purpose, users, data, contract sketch — are approved.

**The offer MUST be its own message** — only the offer — and wait for the response.

> "This feature has a real user-facing surface — we could go frontend-first: I build the
> actual frontend against fixture-backed API routes in one sitdown session, we iterate
> until the design is right, and the backend gets implemented afterward from the
> contracts we settle. Want to? Otherwise I'll write the spec as usual."

- **Accepted** — invoke `toolbelt:interactive-design`; the remaining UI-detail design work moves into that session.
- **Declined** — continue as before, and do not offer again unless your human partner raises it.
- Backend-only features, and projects where the frontend and its API do not live together, never get the offer.

### Claude Design variant

When the `design-fidelity-prep` skill is available, the offer names both frontend-first paths instead:

> "This feature has a real user-facing surface — we could go frontend-first, two ways:
> I build the actual frontend in-repo against fixture-backed API routes and we iterate
> in one sitdown session, or I prep a Claude Design session and you design on the
> canvas first, with implementation from the handoff bundle afterward. Either way the
> backend gets implemented from the contracts we settle. Want one of these? Otherwise
> I'll write the spec as usual."

- **In-repo** — invoke `toolbelt:interactive-design` as above.
- **Claude Design** — invoke `design-fidelity-prep`; it readies the repo for the session, and implementation later re-enters through that plugin's design-fidelity-implement skill.

## Visual Companion

A browser tab for mockups, diagrams, and visual comparisons. Accepting it does NOT mean every question goes through the browser.

Do NOT offer it upfront. Wait until a question would be clearer shown than told — a mockup, layout, or diagram question, not a UI *topic*. Offer it the first time that happens:

> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."

**This offer MUST be its own message** — only the offer — and wait for the response. If they decline, continue text-only and do not offer again unless they raise it. If they accept, read `skills/brainstorming/visual-companion.md` and start the server with `--open`.

Decide per question whether to use the browser or the terminal; the guide covers that test.
