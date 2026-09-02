#!/usr/bin/env bash
#
# Word-count ceilings for the planning skills.
#
# Prints every count and fails on the first file over its ceiling.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

ceilings=(
  "skills/brainstorming/SKILL.md:1050"
  "skills/writing-specs/SKILL.md:670"
  "skills/writing-plans/SKILL.md:2300"
  "skills/subagent-driven-development/SKILL.md:2140"
  "skills/subagent-driven-development/task-reviewer-prompt.md:850"
  "skills/subagent-driven-development/re-review-prompt.md:420"
  "skills/dispatching-parallel-agents/SKILL.md:510"
  "skills/using-git-worktrees/SKILL.md:1260"
  "skills/subagent-driven-development/implementer-prompt.md:400"
  "skills/delivery/SKILL.md:940"
  "skills/pr-monitor/SKILL.md:860"
  "skills/quick-task/SKILL.md:200"
  "docs/WORKFLOW.md:290"
)

for entry in "${ceilings[@]}"; do
  path=${entry%:*}
  ceiling=${entry##*:}
  file="$repo_root/$path"

  count=$(wc -w <"$file")
  echo "$count/$ceiling $path"

  if [[ "$count" -gt "$ceiling" ]]; then
    echo "not ok - $path exceeds ceiling" >&2
    exit 1
  fi
done
