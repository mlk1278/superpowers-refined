#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
skill="$repo_root/skills/delivery/SKILL.md"
metadata="$repo_root/skills/delivery/agents/openai.yaml"
workflow="$repo_root/docs/WORKFLOW.md"
routing="$repo_root/skills/agent-routing/SKILL.md"

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

assert_before() {
  local file=$1 first=$2 second=$3 description=$4
  local first_line second_line
  first_line=$(grep -Fn -- "$first" "$file" | head -1 | cut -d: -f1)
  second_line=$(grep -Fn -- "$second" "$file" | head -1 | cut -d: -f1)
  if [[ -z "$first_line" || -z "$second_line" || "$first_line" -ge "$second_line" ]]; then
    echo "not ok - $description" >&2
    exit 1
  fi
  echo "ok - $description"
}

assert_no_model_names() {
  local file=$1
  if grep -Eq 'gpt-[0-9]|opus-|sonnet|haiku|-sol|Sol (high|medium|low)' "$file"; then
    echo "not ok - concrete model identifiers in $file" >&2
    exit 1
  fi
  echo "ok - no concrete model identifiers in $file"
}

[[ -f "$skill" ]] || { echo "not ok - delivery skill missing: $skill" >&2; exit 1; }
[[ -f "$workflow" ]] || { echo "not ok - workflow document missing: $workflow" >&2; exit 1; }

assert_contains "$skill" "name: delivery" "frontmatter name"
assert_contains "$skill" "Use when an approved implementation plan is ready to be implemented and shipped" "approved-plan trigger"
assert_contains "$skill" "I'm using delivery to deliver this approved plan." "announce line"
assert_contains "$skill" "one coherent delivery slice" "single-slice scope"
assert_contains "$skill" '## Agent Routing' "optional plan routing section"
assert_contains "$skill" "plan route, then project route, then bundled default" "route precedence"
assert_contains "$skill" "session agent remains the orchestrator" "plan cannot route orchestrator"
assert_contains "$skill" "toolbelt:using-git-worktrees" "isolated worktree handoff"
assert_contains "$skill" "toolbelt:subagent-driven-development" "SDD handoff"
assert_contains "$skill" "ux-gate" "conditional UX gate"
assert_contains "$skill" "broad final review is the slice gate" "SDD final review is the slice gate"
assert_contains "$skill" "toolbelt:finishing-a-development-branch" "branch completion handoff"
assert_contains "$skill" "pr-monitor" "PR monitor handoff"
assert_contains "$skill" "run it in the background" "background monitoring is allowed"
assert_contains "$skill" "The next work is independent" "pipelining requires independence"
assert_contains "$skill" "At most one PR is in background monitoring" "one monitored PR cap"
assert_contains "$skill" "Never report the slice complete or end the session while the monitor runs" "monitor is never orphaned"
assert_contains "$skill" "always before that lane's broad final review" "rebase precedes the lane's final review"
assert_contains "$skill" "Reconcile Linear only when the plan is linked to Linear" "optional Linear reconciliation"
assert_contains "$skill" "remove the worktree, branch, and ignored scratch" "post-merge cleanup"
assert_before "$skill" "ux-gate" "broad final review is the slice gate" "UX runs before broad final review"
assert_before "$skill" "broad final review is the slice gate" "toolbelt:finishing-a-development-branch" "review precedes PR completion"
assert_not_contains "$skill" "workstack-slice-gate" "no replacement slice-gate skill"
assert_not_contains "$skill" "progress ledger" "no delivery ledger state machine"
assert_no_model_names "$skill"

[[ -f "$metadata" ]] || { echo "not ok - committed OpenAI metadata missing" >&2; exit 1; }
assert_contains "$metadata" "display_name" "committed OpenAI metadata present"

assert_contains "$routing" "Plan-supplied routes are explicit run overrides" "routing maps plan routes to explicit overrides"
assert_contains "$routing" "plan, project, bundled" "routing documents public precedence"

assert_contains "$workflow" 'upstream `brainstorming` and `writing-plans`' "upstream planning policy"
assert_contains "$workflow" "one coherent delivery slice" "slice policy"
assert_contains "$workflow" '## Agent Routing' "optional plan-routing policy"
assert_contains "$workflow" "implementation report and review-package path" "controller context discipline"
assert_contains "$workflow" "without independently rereading the implementation or verification output" "controller avoids duplicate review context"
assert_contains "$workflow" "No separate resume state machine" "recovery avoids resume machinery"
assert_contains "$workflow" "one monitored PR at a time" "workflow documents the monitoring cap"
assert_not_contains "$workflow" "workstack-resume" "workflow does not revive resume skill"

echo "PASS"
