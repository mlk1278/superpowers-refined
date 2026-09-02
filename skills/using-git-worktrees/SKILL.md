---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

Detect existing isolation first. Then use native worktree tools. Then fall back to git.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

`GIT_DIR != GIT_COMMON` is also true inside a submodule, so check:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**`GIT_DIR != GIT_COMMON` and not a submodule:** already in a linked worktree. Skip to Step 2. Report:

- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

When the caller asks for a new sibling worktree, this skill creates it rather than skipping creation.

**`GIT_DIR == GIT_COMMON` or in a submodule:** normal repo checkout. Honor a worktree preference declared in your instructions. Otherwise ask:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

If your human partner declines, work in place and skip to Step 2.

## Project Worktree Policy

Read `<repo-root>/.toolbelt/worktree-policy.md` when it exists and follow it for the rest of this skill: port ranges and how to pick a non-conflicting set, sidecar containers and their naming, per-worktree data directories, environment files to derive rather than copy, and what to tear down at finish. Report the set you claimed. With no policy file, use the defaults below; do not invent a scheme.

A policy may also declare **parallel-workspace rules** for worktrees that run concurrently:

- How to derive a per-workspace database name (or equivalent isolated resource) from the worktree/branch name.
- Which resources are per-workspace and which are safely shared.
- Setup commands to run per workspace (e.g., client codegen, migrations against the derived database).
- An optional concurrency limit lower than 3 when the machine cannot support three concurrent setups; subagent-driven-development honors the lower number.

subagent-driven-development applies these rules to every track worktree and reports the claimed resources per track. A track needing isolated stateful resources with no policy declaring how is a gap to report, not improvise around.

## Step 1: Create Isolated Workspace

A caller may name a **source ref** — the SHA or branch the new worktree starts from. With one named, use the native tool only if it accepts a source ref; otherwise use Step 1b. With none named, start from `HEAD`.

### 1a. Native Worktree Tools (preferred)

Use any worktree tool you already have — `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, a `--worktree` flag — then skip to Step 2. Native tools own placement, branch creation, and cleanup; `git worktree add` alongside one creates phantom state your harness can't see or manage.

### 1b. Git Worktree Fallback

Use only with no native tool, or when the native tool cannot take the caller's source ref.

Pick the directory in this order: a preference declared in your instructions; an existing project-local `.worktrees/` (preferred) or `worktrees/`, `.worktrees` winning if both exist; otherwise `.worktrees/` at the project root.

Verify a project-local directory is ignored before creating the worktree:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** add to .gitignore, commit, then proceed. An unignored directory commits the worktree contents into the repository.

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME" "${SOURCE_REF:-HEAD}"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 2: Project Setup

Apply the policy's setup rules first — allocated ports, sidecar containers, per-worktree data directories — then detect and run setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Run the smallest focused checks that prove a clean start for the planned
work — the tests the work will rely on, not a workspace or package-wide
baseline. When the base commit already has qualifying test evidence or
authoritative green CI, cite that instead of re-running; docs-only work
needs no baseline suite.

```bash
# Project-appropriate command, scoped to the planned work
npm test path/to/relevant / cargo test module / pytest tests/relevant
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Baseline: <focused tests passing (N tests, 0 failures) | cited base CI/evidence <ref> | docs-only, no suite required>
Resources: <ports/containers claimed per worktree policy, or "project defaults, no policy file">
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.toolbelt/worktree-policy.md` exists | Read it first, follow it throughout |
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored worktree directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "Default ports are fine, nothing else is running" | Another worktree probably is. Read the worktree policy and claim a non-conflicting set; a port clash reads as a code bug for hours. |
| "I'll pick my own port scheme, the policy is vague" | Report the gap instead. An invented scheme collides with the next worktree that invents one too. |
| "The workspace is fresh — baseline checks can wait" | A dirty baseline makes every later failure ambiguous. Satisfy Step 3 now — focused checks, cited base evidence, or the docs-only case; proceeding past failures is your human partner's call. |
