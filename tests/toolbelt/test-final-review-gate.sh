#!/usr/bin/env bash
# Literal shell snippets are contract text, not expressions to expand.
# shellcheck disable=SC2016
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
skill="$repo_root/skills/subagent-driven-development/SKILL.md"

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

assert_contains 'Caller-provided routes take precedence: plan route, then project route, then the bundled model-selection defaults below.' \
  "caller routing precedence is explicit"
assert_contains 'If the caller supplies a pre-final gate, run it after all task reviews and before the broad final review.' \
  "optional pre-final gate runs at the retained seam"
assert_contains 'The final whole-branch review gets a package too: run' \
  "broad final review still receives a review package"
assert_contains 'If the final whole-branch review returns findings, dispatch ONE fix' \
  "final findings are fixed together"
assert_contains 'subagent with the complete findings list — not one fixer per finding.' \
  "one fixer receives the complete finding set"
assert_contains 'contains the covering tests, the command run, and the output' \
  "fix verification carries evidence"
assert_contains 'recorded, commit-bound evidence to read rather than' \
  "evidence reuse is commit-bound and actor-scoped"
assert_contains 'implementers and fixers always produce their own fresh evidence' \
  "implementers never reuse evidence for their own claims"
assert_contains 'The workspace-wide suite runs once, at the final gate' \
  "workspace suite is final-gate only"
assert_contains 'Resume the same final reviewer thread with a `review-package` for the fix delta, and repeat until approved.' \
  "same reviewer receives delta packages until approval"

assert_not_contains '### Final whole-branch gate' "exact-head gate section removed"
assert_not_contains 'REVIEW_HEAD=$(git rev-parse HEAD)' "exact-head state removed"
assert_not_contains 'approved SHA' "approved-SHA bookkeeping removed"
assert_not_contains 'After any compaction or resume' "resume state machinery removed"

echo "PASS"
