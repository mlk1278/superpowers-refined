#!/usr/bin/env bash
# Literal shell snippets are contract text, not expressions to expand.
# shellcheck disable=SC2016
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
skill="$repo_root/skills/writing-plans/SKILL.md"

assert_contains() {
  local text=$1 description=$2
  if ! grep -Fq -- "$text" "$skill"; then
    echo "not ok - $description" >&2
    echo "missing: $text" >&2
    exit 1
  fi
  echo "ok - $description"
}

assert_not_contains() {
  local text=$1 description=$2
  if grep -Fq -- "$text" "$skill"; then
    echo "not ok - $description" >&2
    echo "unexpected: $text" >&2
    exit 1
  fi
  echo "ok - $description"
}

# Exploration precedes drafting, and its breadth is per-surface.
assert_contains 'fan out explorers — one per surface the plan will touch' \
  "exploration fans out per surface"
assert_contains "agent-routing's \`explorer\` role" \
  "explorers are routed, not hand-picked"

# Exploration must land before File Structure, which depends on it.
explore_line=$(grep -n '^## Exploration Before Drafting' "$skill" | cut -d: -f1)
structure_line=$(grep -n '^## File Structure' "$skill" | cut -d: -f1)
if [ "$explore_line" -ge "$structure_line" ]; then
  echo "not ok - exploration section precedes File Structure" >&2
  exit 1
fi
echo "ok - exploration section precedes File Structure"

assert_contains 'get wrong here?' "explorer briefs end with the forcing question"

# The gotcha hunt and its resolution rule.
assert_contains 'An absence check must exclude its own evidence' \
  "gotcha taxonomy covers unpassable absence guards"
assert_contains 'A gotcha that is neither is a plan defect' \
  "every gotcha is resolved or named"

# Gotchas reach implementers through the plan document.
assert_contains '## Known Gotchas' "plan header carries cross-cutting gotchas"
assert_contains '**Gotchas:**' "task structure carries task-local gotchas"
assert_contains 'A named gotcha carrying neither a decision nor an instruction to escalate' \
  "a bare gotcha is a placeholder failure"

# Gotcha classes added after the Phase 7 run.
assert_contains 'Coverage that leaves with the code' \
  "deletion slices must inventory coverage they strip from kept surfaces"
assert_contains 'a precondition read from output the gated command itself produces' \
  "a gate cannot observe the command it gates"

# The plan review gate, and its new powers.
assert_contains 'It may fan out its own explorers' "plan reviewer may explore too"
assert_contains '**Unflagged gotchas**' "plan reviewer judges unflagged gotchas"

# WOR-753 §6: self-review must not argue against the gate that follows it.
assert_not_contains 'No need to re-review' \
  "stale no-re-review clause no longer contradicts the plan gate"

echo "PASS"
