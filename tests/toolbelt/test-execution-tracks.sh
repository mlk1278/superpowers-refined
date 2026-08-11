#!/usr/bin/env bash
# Literal shell snippets are contract text, not expressions to expand.
# shellcheck disable=SC2016
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
plans="$repo_root/skills/writing-plans/SKILL.md"

assert_contains() {
  local file=$1 text=$2 description=$3
  if ! grep -Fq -- "$text" "$file"; then
    echo "not ok - $description" >&2
    echo "missing: $text" >&2
    exit 1
  fi
  echo "ok - $description"
}

assert_not_contains() {
  local file=$1 text=$2 description=$3
  if grep -Fq -- "$text" "$file"; then
    echo "not ok - $description" >&2
    echo "unexpected: $text" >&2
    exit 1
  fi
  echo "ok - $description"
}

# writing-plans: declaring tracks.
assert_contains "$plans" '## Execution Tracks' \
  "plans may declare execution tracks"
assert_contains "$plans" 'No file is created or modified by two concurrent tracks' \
  "concurrent tracks require disjoint file sets"
assert_contains "$plans" 'contract-freeze' \
  "shared contracts freeze on the mainline before the fork"
assert_contains "$plans" 'Every fork closes with a mainline integration task' \
  "every merge point gets an integration task"
assert_contains "$plans" 'bogus or missing track declarations' \
  "plan review gate rejects bad track declarations"

echo "PASS"
