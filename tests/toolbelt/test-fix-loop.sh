#!/usr/bin/env bash
# Literal shell snippets are contract text, not expressions to expand.
# shellcheck disable=SC2016
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
sdd="$repo_root/skills/subagent-driven-development/SKILL.md"

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

assert_contains "$sdd" 'when the task'"'"'s `Interfaces: Produces:` block is non-empty' \
  "re-review is required when a later task builds on this one"
assert_contains "$sdd" 'or when any open finding was Critical' \
  "a Critical finding forces the re-review route"
assert_contains "$sdd" '**Orchestrator close**' \
  "the other exit from the fix round is named"
assert_contains "$sdd" 'Task <N>: fix round closed by orchestrator' \
  "orchestrator close has its own ledger line"
assert_contains "$sdd" 'escalate to your human partner as a BLOCKED task' \
  "an incomplete findings table escalates"
assert_contains "$sdd" 'Task N: in-progress (agent <id>, route <harness>/<model>/<effort>)' \
  "in-progress ledger line records the resolved route"
assert_contains "$sdd" 'route <harness>/<model>/<effort>, report <path>' \
  "complete ledger line records the resolved route"
assert_contains "$sdd" 'Produces: none' \
  "the plan template's empty-produces marker is named"

echo "PASS"
