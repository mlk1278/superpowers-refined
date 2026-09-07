---
name: writing-for-agents
description: Use when editing the prose of any agent-consumed document — a skill body or description, AGENTS.md or CLAUDE.md, a dispatch prompt template — to decide what to cut, where material sits, and how a trigger is worded
---

# Writing for Agents

Rules for any document an agent reads — a skill, an `AGENTS.md` or `CLAUDE.md`, a dispatch prompt, a linked doc. Keep instructions clear enough for agents to follow and your human partner to audit.

When the document is a skill, read [SKILL-MECHANICS.md](SKILL-MECHANICS.md) for frontmatter, invocation choice, and router skills.

## Pointers to other material

A skill's description, or a line in `AGENTS.md` naming a doc, is a pointer: it says what the material is and when to read it. The description must make the reading condition clear. If needed material sits behind a weak pointer, sharpen the wording first; inline the material only if that fails.

- Front-load the trigger: the condition for reading goes before the contents.
- One trigger per branch. Two synonyms for one case are that case written twice; collapse them.
- Avoid repeating the document title or contents in its trigger.

Example: `Use when a test is flaky, order-dependent, or times out` beats `Notes on our async test helpers`.

## The two loads

Always-loaded instructions and descriptions use context on every task. Documents loaded only when needed save context, but your human partner should not have to remember when to request them.

A link keeps the full document out of context until it is needed. Give it a clear reading condition so the agent can find the right reference without prompting.

## Where material sits

Three tiers, by how immediately the agent needs the material: steps in the file, reference in the file, reference in a separate file behind a pointer.

Inline what every branch of the document needs. Put behind a pointer what only some branches reach. Push too little down and the file bloats; push too much and the agent misses what it needs.

Keep one concept's definition, rules, and caveats under one heading rather than scattered, so reading one part brings its neighbours.

Example: a review skill's four rules belong inline; the API reference they cite belongs in its own file.

## Completion criteria

Every step ends on a condition telling the agent it is done. Make it checkable and exhaustive: "every modified model accounted for" beats "produce a change list", which beats "understanding reached".

If an agent stops too early, clarify the completion condition. Split the sequence only when a clearer condition has not helped and the split creates a useful pause or separate dispatch.

## When to split

Split a run of steps when later steps tempt the agent to rush the one in front of it. Splitting by invocation is skill-specific: see [SKILL-MECHANICS.md](SKILL-MECHANICS.md).

## Word choice

Use familiar terms; define new terms when needed. Remove repetition without deleting requirements: "fast, deterministic, low-overhead" cannot become "tight" if those properties matter. Name the action, owner, and required result directly.

State the target behavior directly. "Explain why the code needs the workaround" is more useful than "don't write vague comments". Use a prohibition only as a guardrail you cannot phrase positively, and pair it with the positive target.

## Pruning

- Keep each rule in one place, so changing behavior is a one-place edit. The same rule in two places costs tokens and drifts.
- The environment is a source of truth: `package.json` scripts, config files, `--help` output. Document conventions and rationale that those sources do not explain. Repeat exact values only when the task needs them inline.
- Delete lines that no longer bear on what the document does.
- Delete instructions the model already follows by default. Whether a line is a no-op is settled by running the document with and without it, not by argument. Delete the whole sentence rather than trimming its words.

A gate earns forceful phrasing only where the failure is expensive or irreversible and a brief instruction measurably failed. Keep such blocks short, and re-test them when the model changes.
