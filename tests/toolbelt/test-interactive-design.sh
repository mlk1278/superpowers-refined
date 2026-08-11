#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
skill="$repo_root/skills/interactive-design/SKILL.md"
metadata="$repo_root/skills/interactive-design/agents/openai.yaml"

assert_contains() {
  local file=$1 text=$2 description=$3
  if ! grep -Fq "$text" "$file"; then
    echo "not ok - $description" >&2
    echo "missing: $text" >&2
    exit 1
  fi
  echo "ok - $description"
}

[ -f "$skill" ] || { echo "not ok - skill file missing: $skill" >&2; exit 1; }

assert_contains "$skill" "name: interactive-design" "frontmatter name"
assert_contains "$skill" "accepts the frontend-first offer" "description trigger"
assert_contains "$skill" "TOOLBELT-FIXTURE <endpoint id>" "marker format with endpoint id"
assert_contains "$skill" ".toolbelt/prototype/" "ledger path"
assert_contains "$skill" "a fixture without a ledger entry is a gate violation" "hard gate teeth"
assert_contains "$skill" "':!docs/toolbelt' ':!.toolbelt'" "fixture-zero exclusions"
assert_contains "$skill" "exits 1 (no matches)" "grep inversion stated"
assert_contains "$skill" ".toolbelt/prototyping.md" "per-project convention documented"
assert_contains "$skill" "Do NOT invoke any other skill" "single next skill"
assert_contains "$skill" "matching its endpoint id" "reconciliation requirement"
assert_contains "$skill" "Acceptance criteria" "criteria written at exit"

[ -f "$metadata" ] || { echo "not ok - committed OpenAI metadata missing" >&2; exit 1; }
assert_contains "$metadata" 'display_name: "Interactive Design"' "Codex metadata"

brainstorming="$repo_root/skills/brainstorming/SKILL.md"
writing_specs="$repo_root/skills/writing-specs/SKILL.md"

assert_contains "$brainstorming" "inside that skill is authorized" "HARD-GATE exception present"
assert_contains "$brainstorming" "we could go frontend-first" "offer text present"
assert_contains "$brainstorming" "The offer MUST be its own message" "own-message rule"
assert_contains "$brainstorming" "invoke it and no other" "After-the-Design fork"
assert_contains "$brainstorming" "or to interactive-design when they accepted" "checklist item 6 conditional"

assert_contains "$writing_specs" "Arriving from interactive-design with a reconciled contract ledger" "entry gate acknowledges the path"

echo "PASS"
