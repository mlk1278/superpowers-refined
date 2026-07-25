#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

assert_contains() {
  local file=$1 text=$2 description=$3
  if ! grep -Fq "$text" "$file"; then
    echo "not ok - $description" >&2
    echo "missing: $text" >&2
    exit 1
  fi
  echo "ok - $description"
}

skill="$repo_root/skills/finishing-a-development-branch/SKILL.md"

assert_contains "$skill" "**Completion contract:**" "completion contract exists"
assert_contains "$skill" "If the invoking prompt declared exactly one completion route (optionally naming the target base branch) before this skill was invoked" "contract trigger condition"
assert_contains "$skill" "execute that route and its cleanup directly instead of presenting the options below" "declared route skips the menu"
assert_contains "$skill" "An undeclared or ambiguous route falls through to the normal options." "default menu preserved on no declaration"
assert_contains "$skill" "This changes only who chooses the option; every verification and cleanup rule still applies." "verification is not bypassed"
assert_contains "$skill" "present exactly these 4 options" "default 4-option menu still present"
assert_contains "$skill" "Type 'discard' to confirm." "destructive confirmation gate still present"
assert_contains "$skill" "If tests fail:" "test verification step still present"
assert_contains "$skill" "only with a clean worktree" "evidence reuse requires a clean worktree"
assert_contains "$skill" "**Docs-only cases**" "docs-only Step 1 cases exist"
assert_contains "$skill" "never a file the application builds, renders," "docs-only allowlist has a semantic guard"
assert_contains "$skill" "**If Step 1 is satisfied**" "Step 1 satisfaction covers all three paths"

echo "PASS"
