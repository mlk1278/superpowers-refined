# Toolbelt

A personal agent-skills framework. Started as a fork of [Superpowers](https://github.com/obra/superpowers) and has diverged enough to stand on its own. There is no upstream remote and no plan to merge back.

Installed globally for Claude Code and Codex, and used across every project. That constraint shapes most of what follows.

## How it works

`skills/` holds behavior-shaping markdown. The frontmatter `description` is the highest-leverage line in any skill — it decides whether the skill fires at all.

`hooks/session-start` injects `using-toolbelt` at session start and after compaction. That bootstrap is what makes skills auto-trigger; without it the skills sit on disk and never load.

Two harnesses: Claude Code and Codex. The rest were removed. `docs/porting-to-a-new-harness.md` still describes the hook contract if one gets added back — parts of it reference harnesses that no longer ship here.

## Working on skills

Skills are code, not prose. They shape agent behavior, so edit them like code.

- **Keep them short.** Most of this content was written for models that needed the process restated three times. They don't anymore. Cut restatement; keep gates.
- **Preserve forceful blocks verbatim.** `<HARD-GATE>`, `<ENTRY-GATE>`, Red Flags tables, and rationalization lists are written the way they are because that phrasing survives compaction. Don't smooth them out.
- **One skill names exactly one next skill** and says "Do NOT invoke any other skill." Handoff chains leak otherwise.
- **"Your human partner" is deliberate.** Don't normalize it to "the user."
- **Split by trigger, not by size.** A distinct entry condition earns its own skill and its own `description`, however short the body is. One description straddling two entry conditions degrades both.

## Nothing may assume a specific project

This installs globally, so no file under `skills/` may hard-code anything about one repo. Per-project behavior comes from files in the consuming project, all optional:

- `.toolbelt/agents.json` — agent routes, models, effort, custom instructions
- `.toolbelt/pr-policy.md` — review providers to await, complexity lanes, timeouts
- `docs/REVIEW-GUIDANCE.md` — review conventions, read when present
- `AGENTS.md` — entry-point summary, copied from `docs/AGENTS-SNIPPET.md`

Scripts are referenced relative to their own skill directory, never relative to a repo root. `scripts/review-package` is correct; `skills/subagent-driven-development/scripts/review-package` only works inside this checkout.

`.toolbelt/` is also where scratch lands in consuming projects — `sdd/`, `quick/`, `brainstorm/`.

## Verifying a change

Clean session, send exactly:

> Let's make a react todo list

`brainstorming` must auto-trigger before any code is written. If it doesn't, the bootstrap isn't loading and nothing else about the change matters. Run it in both harnesses after touching `hooks/`, the plugin manifests, or `using-toolbelt`.

`tests/` holds plugin-infrastructure tests — packaging, hooks, the brainstorm server, and assertions about skill content. They are **not** a gate on skill wording; if a test asserts a phrase that should change, change the phrase and fix the test.

Currently failing, all pre-existing: `tests/codex-plugin-sync` (23 assertions), `tests/toolbelt/test-agent-routing` (Windows path formatting), `tests/toolbelt/test-final-review-gate`, `tests/toolbelt/test-reviewer-context`.
