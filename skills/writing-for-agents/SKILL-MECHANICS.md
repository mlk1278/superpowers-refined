# Skill mechanics

The skill-specific branch of [writing-for-agents](SKILL.md): what changes when the document is a skill — frontmatter, the invocation choice, and router skills. Everything else about writing it is the universal reference in `SKILL.md`.

In toolbelt, `hooks/session-start` injects `using-toolbelt` at session start; that bootstrap is what makes descriptions fire at all. The description is still the skill's top-level context pointer, and toolbelt's rule — split by trigger, not by size — is the invocation cut of splitting.

## Invocation

Two choices, trading the two loads:

- A **model-invoked** skill keeps a `description`, so the agent can fire it autonomously — and other skills can reach it. You can still type its name: model-invocation always *includes* human reach. The description is the skill's top-level context pointer, permanently loaded — context load in exchange for discoverability. A model-invoked skill whose content is all reference is also one home for shared reference: another skill can invoke it, so reference needed by several skills lives in one place. Mechanics: write a model-facing description carrying the trigger branches (the pointer-writing rules in `SKILL.md` apply in full).
- A **user-invoked** skill strips the description from the agent's reach: only your human partner typing its name can invoke it, and no other skill can. Zero context load, but it spends cognitive load — your human partner is the index that must remember it exists. Mechanics: `disable-model-invocation: true` frontmatter where the harness supports it (harness-dependent; verify per harness); the `description` becomes human-facing — a one-line summary, trigger lists stripped.

Pick model-invocation only when the agent must reach the skill on its own, or another skill must. If it only ever fires by hand, make it user-invoked and pay no context load.

## Splitting by invocation

Split off a model-invoked skill when you have a distinct leading word that should trigger it on its own — a trigger word you actually use in your prompts — or another skill must reach it. You pay context load for the new always-loaded description, so that independent reach has to be worth it.

## Router skills

When user-invoked skills multiply past what your human partner can remember, that piled-up cognitive load is cured by a **router skill**: one user-invoked skill that names the others and when to reach for each, so there is one skill to remember instead of many. It can only hint, never fire them: user-invoked skills have no description, so nothing but your human partner can reach them.
