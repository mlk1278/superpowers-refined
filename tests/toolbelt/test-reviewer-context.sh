#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
sdd="$repo_root/skills/subagent-driven-development/SKILL.md"
task_prompt="$repo_root/skills/subagent-driven-development/task-reviewer-prompt.md"
requesting="$repo_root/skills/requesting-code-review/SKILL.md"
final_prompt="$repo_root/skills/requesting-code-review/code-reviewer.md"
implementer_prompt="$repo_root/skills/subagent-driven-development/implementer-prompt.md"

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

for prompt in "$task_prompt" "$final_prompt"; do
  assert_contains "$prompt" 'docs/REVIEW-GUIDANCE.md' \
    "review prompt discovers canonical project guidance"
  assert_contains "$prompt" 'This file is reviewer-only.' \
    "review prompt limits project guidance to reviewers"
  assert_contains "$prompt" '[REVIEW_NUANCE]' \
    "review prompt accepts orchestrator-supplied nuance"
  assert_contains "$prompt" 'does not override requirements, suppress findings, or set severity' \
    "review nuance cannot pre-judge findings"
done

assert_contains "$task_prompt" 'This guidance read is an explicit exception to the later limits on' \
  "task reviewer may read guidance despite diff-only limits"
assert_contains "$sdd" 'Do not read it' \
  "SDD orchestrator does not consume reviewer guidance"
assert_contains "$sdd" 'while orchestrating or pass it to implementers, fixers, explorers, planners,' \
  "SDD excludes reviewer guidance from non-review roles"
assert_contains "$sdd" 'Use `None` when there is no useful nuance.' \
  "SDD omits invented review nuance"
assert_contains "$requesting" 'Do not read `docs/REVIEW-GUIDANCE.md` yourself' \
  "ad hoc review caller leaves guidance to reviewer"
assert_not_contains "$implementer_prompt" 'docs/REVIEW-GUIDANCE.md' \
  "implementer prompt does not receive reviewer guidance"

echo "PASS"
