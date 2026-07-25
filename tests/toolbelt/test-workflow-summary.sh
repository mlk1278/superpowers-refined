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

summary="$repo_root/docs/AGENTS-SNIPPET.md"
[ -f "$summary" ] || { echo "not ok - workflow summary draft missing" >&2; exit 1; }
assert_contains "$summary" "quick-task" "summary names quick task"
assert_contains "$summary" "delivery" "summary names delivery"
assert_contains "$summary" '`brainstorming` and `writing-plans`' "summary points ambiguous work at planning"
assert_contains "$summary" "redesign the capability, not this summary" "summary is the simplicity forcing function"
if grep -Eq 'workstack-(start|resume|spec-review|slice-gate)|phase plan|shepherd|implementation phase|living plan|active contract' "$summary"; then
  echo "not ok - superseded workflow vocabulary in workflow summary" >&2
  exit 1
fi
echo "ok - no superseded workflow vocabulary"

entry_points=$(grep -Ec '^- `[a-z-]+`:' "$summary")
if [[ "$entry_points" -ne 2 ]]; then
  echo "not ok - expected exactly two public entry points, found $entry_points" >&2
  exit 1
fi
echo "ok - exactly two public entry points"
echo "PASS"
