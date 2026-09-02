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

# Exploration begins in context and dispatches only for questions that need it.
assert_contains 'nearest instructions' "exploration starts from local instructions"
assert_contains '2–3 targeted inline `rg` searches' \
  "exploration begins with bounded inline searches"
assert_contains "agent-routing's \`explorer\` role" \
  "explorers are routed, not hand-picked"
assert_contains 'completeness inventory' \
  "explorers are reserved for completeness inventories"
assert_contains 'invisible trap' "explorers are reserved for invisible traps"
assert_contains 'plan-shaping existence question' \
  "explorers are reserved for plan-shaping existence questions"
assert_contains 'Start with one explorer' "exploration starts with one agent"
assert_contains 'unfamiliar, independent subsystems' \
  "additional explorers require unfamiliar independent subsystems"
assert_contains 'checkable paths and pointers' \
  "explorer briefs request checkable evidence"
assert_not_contains 'fan out explorers — one per surface the plan will touch' \
  "unconditional per-surface fan-out is absent"

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

# PR boundaries partition tasks into independently verifiable outcomes.
assert_contains '## PR Boundaries' "plan declares PR boundaries"
boundary_line=$(grep -n '^## PR Boundaries' "$skill" | cut -d: -f1)
task_line=$(grep -n '^## Task Structure' "$skill" | cut -d: -f1)
if [ "$boundary_line" -ge "$task_line" ]; then
  echo "not ok - PR Boundaries precedes Task Structure" >&2
  exit 1
fi
echo "ok - PR Boundaries precedes Task Structure"
assert_contains '| PR | Outcome | Tasks | Depends on | Independent verification |' \
  "each PR row carries the required boundary fields"
assert_contains 'Every task number appears in exactly one boundary' \
  "boundaries cover tasks without overlap"
assert_contains 'why no smaller independently verifiable outcome exists' \
  "one-PR plans require a justification"
assert_contains 'core plus one representative consumer' \
  "shared substrate starts with one representative consumer"
assert_contains 'repeat the same reviewer judgment' \
  "later consumers share a PR only when review is repetitive"
assert_contains 'Novel lifecycle, export, or rollout work stays separate' \
  "novel consumer work gets its own boundary"

# Gotcha classes added after the Phase 7 run.
assert_contains 'Coverage that leaves with the code' \
  "deletion slices must inventory coverage they strip from kept surfaces"
assert_contains 'a precondition read from output the gated command itself produces' \
  "a gate cannot observe the command it gates"

# The plan review gate, and its new powers.
assert_contains 'It may fan out its own explorers' "plan reviewer may explore too"
assert_contains '**Unflagged gotchas**' "plan reviewer judges unflagged gotchas"
assert_contains '**PR boundaries**' "plan reviewer judges PR boundaries"
assert_contains 'missing, horizontal, overlapping, or unjustified' \
  "self-review rejects invalid PR partitions"
assert_contains 'Handing the plan to delivery' \
  "the whole plan is handed to delivery"

# Tracks are the default; task size is capped; RED names each test.
assert_contains 'states in one sentence why no tasks can run concurrently' \
  "an all-serial plan justifies itself in one sentence"
assert_contains "A task's **Files:** block is closed" \
  "a task lists every file it touches"
assert_contains 'at most 8 files' "a task is capped at eight files"
assert_contains 'Mechanical sweep:' \
  "the file cap has one exception, marked and verified"
assert_contains 'Expected, per test:' "the RED step names one failure per test"
assert_contains 'when the guard is absent' \
  "a guard's red is the failure seen without the guard"
assert_contains 'Produces: none' \
  "a task with no downstream dependents says so"

# WOR-753 §6: self-review must not argue against the gate that follows it.
assert_not_contains 'No need to re-review' \
  "stale no-re-review clause no longer contradicts the plan gate"

echo "PASS"
