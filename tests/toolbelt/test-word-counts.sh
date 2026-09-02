#!/usr/bin/env bash
#
# Word-count ceilings for the planning skills.
#
# Report-only by default: prints every count and exits 0. Set ENFORCE=1 to fail
# on the first file over its ceiling.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

ceilings=(
  "skills/brainstorming/SKILL.md:740"
  "skills/writing-specs/SKILL.md:420"
  "skills/writing-plans/SKILL.md:1880"
  "skills/subagent-driven-development/SKILL.md:1760"
  "skills/subagent-driven-development/task-reviewer-prompt.md:590"
  "skills/subagent-driven-development/re-review-prompt.md:340"
  "skills/dispatching-parallel-agents/SKILL.md:350"
  "skills/using-git-worktrees/SKILL.md:910"
  "skills/subagent-driven-development/implementer-prompt.md:400"
  "skills/delivery/SKILL.md:940"
  "skills/pr-monitor/SKILL.md:640"
  "skills/quick-task/SKILL.md:200"
  "docs/WORKFLOW.md:290"
)

for entry in "${ceilings[@]}"; do
  path=${entry%:*}
  ceiling=${entry##*:}
  file="$repo_root/$path"

  count=$(wc -w <"$file")
  echo "$count/$ceiling $path"

  if [[ "${ENFORCE:-}" == "1" && "$count" -gt "$ceiling" ]]; then
    echo "not ok - $path exceeds ceiling" >&2
    exit 1
  fi
done
