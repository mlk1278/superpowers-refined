---
name: writing-specs
description: "Use after brainstorming reaches an approved design, or when your human partner asks for a spec directly or hands you written requirements. Writes, reviews, and gates the spec document before planning starts."
---

# Writing Specs

**Announce at start:** "I'm using the writing-specs skill to write the spec."

<ENTRY-GATE>
You normally arrive here from brainstorming, with a design the user has already approved section by section. Direct entry is allowed only when your human partner asks for a spec or supplies written requirements.
Arriving from interactive-design with a reconciled contract ledger is likewise a normal
entry, equivalent to a brainstorming-approved design.
Deciding for yourself that a request is clear enough to skip brainstorming is the one thing this skill does not authorize — that call belongs to the human.
</ENTRY-GATE>

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Gather context** — explore the codebase and the requirements you were given
2. **Write the spec** — save to `docs/toolbelt/specs/YYYY-MM-DD-<topic>-design.md` and commit
3. **Self-review the spec** — placeholders, contradictions, ambiguity, scope
4. **User reviews the written spec**
5. **Alternate-harness review** — resolve a reviewer outside the author's harness
6. **Transition to planning** — invoke writing-plans

**The terminal state is invoking writing-plans.**

## Gathering Context

On direct entry, build context before writing. Dispatch background subagents to explore in parallel: existing patterns and prior art, the surfaces this change touches, the relevant docs, external references. Reserve questions for what only your human partner knows.

If the requirements leave open a decision that would change what gets built, ask — one question per message, multiple choice where you can. If they leave several open, use the brainstorming skill instead.

## Writing the Spec

Cover architecture, components, data flow, error handling, and testing, scaling each section to its complexity.

- **Global constraints go up top** — version floors, dependency limits, naming and copy rules, platform requirements. Copy exact values verbatim from the source; the plan and every task inherit them.
- **Break the system into units with one clear purpose and well-defined interfaces.** For each: what does it do, how is it used, what does it depend on? If a consumer has to read the internals, the boundary is wrong.
- **YAGNI** — cut anything the design doesn't need.
- **In existing codebases, follow existing patterns.** Include targeted improvements where existing problems affect this work. No unrelated refactoring.
- **No placeholders.** No "TBD", "add error handling", or "similar to the above"; a deferred decision only relocates into the plan.

Use the elements-of-style:writing-clearly-and-concisely skill if available. Save to `docs/toolbelt/specs/YYYY-MM-DD-<topic>-design.md` (user preferences for spec location override this default) and commit it to git.

## Review Gates

**Self-review** the spec: placeholders or vague requirements, sections that contradict each other, requirements open to two readings, scope too large for one implementation plan. Fix inline; no re-review.

**User review gate.** Ask your human partner to review the spec before proceeding:

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

Wait for their response. If they request changes, make them and self-review again. Proceed only once they approve.

**Alternate-harness review.** After that approval, invoke
toolbelt:agent-routing and resolve the reviewer with role `reviewer`, specialty
`spec`, and the harness that wrote the spec as `author-harness`. Follow that
skill's resolver-path contract; the resolver is not relative to the project.

`--author-harness` removes same-harness routes case-insensitively and fails closed if no different-harness route remains. Dispatch the resolved reviewer to check the spec for gaps, ambiguity, or poor design. Small technical gaps — fix the spec and proceed. A rework large enough to change the idea — bring it to your human partner. Unsure — ask.

**Then invoke the writing-plans skill.** Do NOT invoke any other skill. writing-plans is the next step.
