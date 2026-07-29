#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

python3 - "$repo_root" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
expected = {
    "opus-5-low": ("Claude Opus 5 on low effort.", "claude-opus-5", "low"),
    "opus-5-medium": ("Claude Opus 5 on medium effort.", "claude-opus-5", "medium"),
    "opus-5-high": ("Claude Opus 5 on high effort.", "claude-opus-5", "high"),
    "fable-5-low": ("Claude Fable 5 on low effort.", "claude-fable-5", "low"),
    "fable-5-medium": ("Claude Fable 5 on medium effort.", "claude-fable-5", "medium"),
    "fable-5-high": ("Claude Fable 5 on high effort.", "claude-fable-5", "high"),
    "fable-5-xhigh": ("Claude Fable 5 on xhigh effort.", "claude-fable-5", "xhigh"),
}

agent_dir = root / "agents"
actual_files = {path.stem for path in agent_dir.glob("*.md")} if agent_dir.exists() else set()
if actual_files != set(expected):
    raise SystemExit(
        f"not ok - agent files\nexpected: {sorted(expected)}\nactual: {sorted(actual_files)}"
    )

for name, (description, model, effort) in expected.items():
    path = agent_dir / f"{name}.md"
    match = re.fullmatch(r"---\n(.*?)\n---\n?", path.read_text(), re.DOTALL)
    if not match:
        raise SystemExit(f"not ok - {name} has only YAML frontmatter")
    fields = {}
    for line in match.group(1).splitlines():
        key, separator, value = line.partition(": ")
        if not separator:
            raise SystemExit(f"not ok - {name} malformed frontmatter line: {line}")
        fields[key] = value
    wanted = {
        "name": name,
        "description": description,
        "model": model,
        "effort": effort,
    }
    if fields != wanted:
        raise SystemExit(f"not ok - {name}\nexpected: {wanted}\nactual: {fields}")
    print(f"ok - {name}")
PY

if rg -n -i 'opus[ -]?4[.-]?8|opus-4-8|sonnet' \
  "$repo_root/agents" \
  "$repo_root/skills" \
  "$repo_root/.claude-plugin" \
  "$repo_root/.codex-plugin" \
  --glob '!writing-skills/anthropic-best-practices.md' >/dev/null; then
  echo "not ok - obsolete operational models remain" >&2
  exit 1
fi
echo "ok - obsolete operational models are absent"

# The vendored authoring reference is guidance too, but historical release and
# issue text plus regex guard tests are intentionally outside this operational scan.
if rg -n -i 'opus[ -]?4[.-]?8|opus-4-8|sonnet' \
  "$repo_root/skills/writing-skills/anthropic-best-practices.md" >/dev/null; then
  echo "not ok - obsolete model guidance remains in the authoring reference" >&2
  exit 1
fi
echo "ok - obsolete model guidance is absent"

echo "PASS"
