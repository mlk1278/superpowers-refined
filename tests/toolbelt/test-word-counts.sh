#!/usr/bin/env bash
#
# Word-count ceilings, repo-wide.
#
# Prints every count and fails on the first file over its ceiling.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

ceilings=(
  "skills/using-toolbelt/SKILL.md:300"
  "skills/verification-before-completion/SKILL.md:300"
  "skills/receiving-code-review/SKILL.md:300"
  "skills/writing-skills/SKILL.md:1000"
  "skills/writing-for-agents/SKILL.md:750"
  "skills/systematic-debugging/SKILL.md:600"
  "skills/test-driven-development/SKILL.md:600"
  "skills/brainstorming/SKILL.md:650"
  "skills/finishing-a-development-branch/SKILL.md:850"
  "skills/using-git-worktrees/SKILL.md:750"
  "skills/dispatching-parallel-agents/SKILL.md:320"
  "skills/requesting-code-review/SKILL.md:350"
  "skills/requesting-code-review/code-reviewer.md:500"
  "skills/interactive-design/SKILL.md:1200"
  "skills/subagent-driven-development/SKILL.md:1900"
  "skills/subagent-driven-development/task-reviewer-prompt.md:650"
  "skills/subagent-driven-development/implementer-prompt.md:550"
  "skills/subagent-driven-development/re-review-prompt.md:420"
  "skills/subagent-driven-development/gate-reviewer-prompt.md:700"
  "skills/writing-plans/SKILL.md:1900"
  "skills/ux-gate/SKILL.md:950"
  "skills/writing-specs/SKILL.md:550"
  "skills/delivery/SKILL.md:900"
  "skills/pr-monitor/SKILL.md:850"
  "skills/agent-routing/SKILL.md:800"
  "skills/quick-task/SKILL.md:200"
  "docs/WORKFLOW.md:320"
)

for entry in "${ceilings[@]}"; do
  path=${entry%:*}
  ceiling=${entry##*:}
  file="$repo_root/$path"

  [ -f "$file" ] || continue

  count=$(wc -w <"$file")
  echo "$count/$ceiling $path"

  if [[ "$count" -gt "$ceiling" ]]; then
    echo "not ok - $path exceeds ceiling" >&2
    exit 1
  fi
done
