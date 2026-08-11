---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

Turn ideas into designs through collaborative dialogue: understand the project, ask questions until you know what you're building, then present the design and get approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.

Exception: when your human partner has approved the intent-level design and accepted the
frontend-first offer, invoke toolbelt:interactive-design — prototype implementation
inside that skill is authorized.
</HARD-GATE>

There is no exception for "this is too simple to need a design" — a todo list, a single-function utility, a config change all go through this. Simple projects are where unexamined assumptions cause the most wasted work. The design can be a few sentences, but you MUST present it and get approval.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — files, docs, recent commits
2. **Assess scope** — if the request spans multiple independent subsystems, decompose it into sub-projects before refining details: what are the independent pieces, how do they relate, what order should they be built? Backlog the rest and plan the first part.
3. **Ask clarifying questions** — one at a time, until you can state the design
4. **Propose approaches** — when several are genuinely viable, with trade-offs and your recommendation
5. **Present the design** — in sections, approval after each
6. **Hand off** — to writing-specs once your human partner has approved the whole design, or to interactive-design when they accepted the frontend-first offer

Offer the visual companion just-in-time, outside this sequence — see below.

**The terminal state is invoking writing-specs — or interactive-design when the frontend-first offer was accepted.**

## Asking Good Questions

The design is bounded by the quality of your questions. A question is worth asking when its answer would change what you build — if both answers lead to the same design, skip it.

- **Ask about the problem, not the solution.** When the request names a solution, find out what problem it solves — there is often a shorter path to it.
- **Chase the assumption you are most likely to get wrong.** Who uses this, what happens when it fails, what "done" looks like, what is explicitly out of scope.
- **State inferences instead of asking about them.** "I'm assuming X — correct me" moves faster than a question and still catches the error.
- **Stop when questions stop changing the design.** Then present.

Explore rather than asking what you could find out yourself — check the current project state first, and dispatch background subagents at any point to read the codebase, dig up prior art, or research external references while the conversation continues. Reserve questions for what only your human partner knows.

## Presenting the Design

- Scale each section to its complexity: a few sentences when straightforward, up to 200-300 words when nuanced
- Cover architecture, components, data flow, error handling, testing
- Ask after each section whether it looks right so far; go back and clarify when something doesn't land
- Break the system into units with one clear purpose and well-defined interfaces. For each: what does it do, how is it used, what does it depend on? If a consumer has to read the internals, or you can't change the internals without breaking consumers, the boundary is wrong.
- In existing codebases, explore the structure first and follow existing patterns. Include targeted improvements where existing problems affect this work — the way a good developer improves code they're working in. No unrelated refactoring.

## After the Design

When your human partner accepted the frontend-first offer, the next skill is
toolbelt:interactive-design — invoke it and no other. Otherwise:

Once the user has approved every section, **invoke the writing-specs skill.** It writes the design to `docs/toolbelt/specs/`, gates it with the user and an alternate-family reviewer, and hands off to planning. Do NOT invoke any other skill. writing-specs is the next step.

## Frontend-First Offer

Offer this path when the feature has a significant user-facing surface, its frontend and the API it consumes live in this repository, and the intent-level design sections — purpose, users, data, contract sketch — are approved.

**The offer MUST be its own message** — only the offer, nothing else — and you wait for the response.

> "This feature has a real user-facing surface — we could go frontend-first: I build the
> actual frontend against fixture-backed API routes in one sitdown session, we iterate
> until the design is right, and the backend gets implemented afterward from the
> contracts we settle. Want to? Otherwise I'll write the spec as usual."

- **Accepted** — invoke `toolbelt:interactive-design`; the remaining UI-detail design work moves into that session.
- **Declined** — continue exactly as before, and do not offer again unless your human partner raises it.
- Backend-only features, and projects where the frontend and its API do not live together, never get the offer.

## Visual Companion

A browser tab for showing mockups, diagrams, and visual comparisons. It's a tool, not a mode — accepting it does NOT mean every question goes through the browser.

Do NOT offer it upfront. Wait until a question would genuinely be clearer shown than told — a real mockup / layout / diagram question, not merely a UI *topic*. The first time that happens, offer it:

> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."

**This offer MUST be its own message** — only the offer, no clarifying question or other content — and you wait for the user's response. If they decline, continue text-only and don't offer again unless they raise it. If they accept, read `skills/brainstorming/visual-companion.md` before proceeding and start the server with `--open`.

Even after they accept, decide per question whether to use the browser or the terminal; the guide covers that test.
