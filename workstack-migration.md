# Toolbelt Migration

Temporary. Steps to run on the dev machine after pulling the rename. Delete this file once done.

## Claude Code

- Remove the old install: `/plugin uninstall superpowers@<marketplace>` — check `/plugin` for the marketplace name you actually used (official `claude-plugins-official`, or the local dev one)
- If you added a marketplace pointing at this repo, remove it too: `/plugin marketplace remove superpowers-dev`
- Re-add this repo: `/plugin marketplace add <path-to-this-repo>`
- Install: `/plugin install toolbelt@toolbelt-dev`
- Start a fresh session — the session-start hook re-registers on load, it does not pick up mid-session

## Codex

- Remove the old plugin entry from `~/.codex/config.toml`
- Reinstall from this repo (`/plugins` → install, or re-run the sync script)
- Confirm `[features] multi_agent = true` is still set — subagent dispatch depends on it

## In the workstack CRM repo

- `git mv .workstack .toolbelt` if the directory exists (holds `agents.json`)
- Re-copy the entry-point snippet into `AGENTS.md` from `workstack/AGENTS-SNIPPET.md`
- Search and replace skill references:
  - `superpowers:` → `toolbelt:`
  - `workstack-delivery` → `delivery`
  - `workstack-quick-task` → `quick-task`
  - `workstack-agent-routing` → `agent-routing`
  - `workstack-pr-monitor` → `pr-monitor`
  - `workstack-ux-gate` → `ux-gate`
- Check `CLAUDE.md` / `AGENTS.md` for any other `superpowers`/`workstack-` skill names

## Any other project you want this in

- Nothing to install — the plugin is global
- Optional per-project config: `.toolbelt/agents.json` (routes, models, effort, custom instructions)
- Optional per-project review conventions: `docs/REVIEW-GUIDANCE.md`
- Optional entry-point snippet in `AGENTS.md`

## Verify

- New session in the CRM repo: the routing brief should resolve at session start; if the script fails it should escalate to you, not fall back silently
- Send `Let's make a react todo list` in a clean session — `brainstorming` must auto-trigger. If it doesn't, the bootstrap isn't loading and the install is wrong
- Dispatch anything that needs a reviewer and confirm the route is independent of the author model

## Cleanup

- Delete this file
