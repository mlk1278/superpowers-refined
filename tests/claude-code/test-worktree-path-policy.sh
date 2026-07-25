#!/usr/bin/env bash
# Regression check: Toolbelt should not route new worktrees through the old
# global worktree directory. The `~/.config/superpowers/worktrees` literal below
# is deliberately legacy - it is the pre-rename path this project must never
# reintroduce.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

USING_SKILL="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
FINISHING_SKILL="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"

failures=0

assert_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    fi
}

assert_not_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [FAIL] $label"
        echo "    Did not expect to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    else
        echo "  [PASS] $label"
    fi
}

echo "=== Worktree Path Policy Test ==="
echo ""

assert_not_contains "$USING_SKILL" "~/.config/superpowers/worktrees" "using-git-worktrees does not mention old global path"
assert_not_contains "$USING_SKILL" "global legacy" "using-git-worktrees does not use unclear global legacy shorthand"
assert_not_contains "$USING_SKILL" "Global path" "using-git-worktrees has no global path quick-reference row"
assert_contains "$USING_SKILL" 'default to `.worktrees/` at the project root' "using-git-worktrees defaults new manual worktrees to .worktrees/"

assert_not_contains "$FINISHING_SKILL" "~/.config/superpowers/worktrees" "finishing-a-development-branch does not treat old global path as owned"
assert_contains "$FINISHING_SKILL" '`.worktrees/` or `worktrees/`' "finishing-a-development-branch keeps project-local cleanup ownership"

# The worktree-rototill spec and plan that used to be asserted here were removed
# from docs/ along with the rest of the pre-Toolbelt design notes, so there is
# nothing left to check.

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
