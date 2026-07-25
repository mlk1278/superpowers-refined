#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
resolver="$repo_root/skills/agent-routing/scripts/resolve-agent"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

passes=0

assert_route() {
  local name=$1 expected=$2
  shift 2
  local actual

  if ! actual=$("$resolver" "$@" 2>"$tmp/stderr"); then
    echo "not ok - $name" >&2
    cat "$tmp/stderr" >&2
    exit 1
  fi

  python3 - "$name" "$expected" "$actual" <<'PY'
import json
import sys

name, expected_text, actual_text = sys.argv[1:]
expected = json.loads(expected_text)
actual = json.loads(actual_text)
if actual != expected:
    raise SystemExit(
        f"not ok - {name}\nexpected: {json.dumps(expected, sort_keys=True)}"
        f"\nactual:   {json.dumps(actual, sort_keys=True)}"
    )
PY
  echo "ok - $name"
  passes=$((passes + 1))
}

assert_failure() {
  local name=$1 diagnostic=$2
  shift 2

  if "$resolver" "$@" >"$tmp/stdout" 2>"$tmp/stderr"; then
    echo "not ok - $name (command unexpectedly succeeded)" >&2
    exit 1
  fi
  if ! grep -F -- "$diagnostic" "$tmp/stderr" >/dev/null; then
    echo "not ok - $name" >&2
    echo "expected diagnostic containing: $diagnostic" >&2
    cat "$tmp/stderr" >&2
    exit 1
  fi
  echo "ok - $name"
  passes=$((passes + 1))
}

mkdir -p "$tmp/empty" "$tmp/project/.toolbelt" "$tmp/reviewer/.toolbelt" \
  "$tmp/dependent/.toolbelt" "$tmp/filtered/.toolbelt" "$tmp/invalid/.toolbelt"

cat >"$tmp/project/.toolbelt/agents.json" <<'JSON'
{
  "version": 1,
  "roles": {
    "implementer": {
      "harness": "project-harness",
      "model": "project-role",
      "effort": "low",
      "fallbacks": [
        {"harness": "fallback-a", "model": "fallback-one", "effort": "medium"},
        {"harness": "fallback-b", "model": "fallback-two", "effort": "high"}
      ]
    }
  },
  "harnesses": {
    "selected-harness": {
      "implementer": {"harness": "selected-harness", "model": "harness-route", "effort": "medium"}
    }
  },
  "workflows": {
    "delivery": {
      "implementer": {"harness": "workflow-harness", "model": "workflow-route", "effort": "high"}
    }
  },
  "reviewer_specialties": {
    "security": {
      "harness": "specialty-harness",
      "model": "specialty-route",
      "effort": "high",
      "fallbacks": [
        {"harness": "specialty-fallback", "model": "specialty-fallback-route", "effort": "high"}
      ]
    }
  }
}
JSON

cat >"$tmp/reviewer/.toolbelt/agents.json" <<'JSON'
{
  "version": 1,
  "roles": {
    "reviewer": {
      "harness": "author-harness",
      "model": "author-model",
      "effort": "high",
      "fallbacks": [
        {"harness": "reviewer-harness", "model": "independent-model", "effort": "high"},
        {"harness": "final-harness", "model": "final-model", "effort": "medium"}
      ]
    }
  }
}
JSON

cat >"$tmp/dependent/.toolbelt/agents.json" <<'JSON'
{
  "version": 1,
  "roles": {
    "reviewer": {
      "harness": "first-harness",
      "model": "same-model",
      "effort": "high",
      "fallbacks": [
        {"harness": "second-harness", "model": "same-model", "effort": "medium"}
      ]
    }
  }
}
JSON

cat >"$tmp/filtered/.toolbelt/agents.json" <<'JSON'
{
  "version": 1,
  "roles": {
    "reviewer": {
      "harness": "reviewer-harness",
      "model": "independent-model",
      "effort": "high",
      "fallbacks": [
        {"harness": "author-harness", "model": "author-model", "effort": "high"},
        {"harness": "final-harness", "model": "final-model", "effort": "medium"}
      ]
    }
  }
}
JSON

printf '{invalid json\n' >"$tmp/invalid/.toolbelt/agents.json"

while IFS='|' read -r role model effort; do
  assert_route "bundled $role" \
    "{\"role\":\"$role\",\"harness\":\"codex\",\"model\":\"$model\",\"effort\":\"$effort\",\"fallbacks\":[],\"source\":\"bundled:role\",\"fallback_reason\":null}" \
    --project-root "$tmp/empty" --role "$role"
done <<'CASES'
explorer|gpt-5.6-sol|medium
planner|gpt-5.6-sol|high
implementer|gpt-5.6-sol|high
operator|gpt-5.6-sol|low
monitor|gpt-5.6-sol|medium
CASES

assert_route "bundled reviewer" \
  '{"role":"reviewer","harness":"claude","model":"opus-4-8","effort":"high","fallbacks":[{"harness":"codex","model":"gpt-5.5","effort":"high"}],"source":"bundled:role","fallback_reason":null}' \
  --project-root "$tmp/empty" --role reviewer --author-model different-model

assert_route "project role" \
  '{"role":"implementer","harness":"project-harness","model":"project-role","effort":"low","fallbacks":[{"harness":"fallback-a","model":"fallback-one","effort":"medium"},{"harness":"fallback-b","model":"fallback-two","effort":"high"}],"source":"project:role","fallback_reason":null}' \
  --project-root "$tmp/project" --role implementer

assert_route "harness override" \
  '{"role":"implementer","harness":"selected-harness","model":"harness-route","effort":"medium","fallbacks":[],"source":"project:harness","fallback_reason":null}' \
  --project-root "$tmp/project" --role implementer --harness selected-harness

assert_route "workflow override" \
  '{"role":"implementer","harness":"workflow-harness","model":"workflow-route","effort":"high","fallbacks":[],"source":"project:workflow","fallback_reason":null}' \
  --project-root "$tmp/project" --role implementer --workflow delivery

assert_route "workflow beats harness" \
  '{"role":"implementer","harness":"workflow-harness","model":"workflow-route","effort":"high","fallbacks":[],"source":"project:workflow","fallback_reason":null}' \
  --project-root "$tmp/project" --role implementer --workflow delivery --harness selected-harness

assert_route "reviewer specialty" \
  '{"role":"reviewer","harness":"specialty-harness","model":"specialty-route","effort":"high","fallbacks":[{"harness":"specialty-fallback","model":"specialty-fallback-route","effort":"high"}],"source":"project:reviewer-specialty","fallback_reason":null}' \
  --project-root "$tmp/project" --role reviewer --reviewer-specialty security --author-model author-model

assert_route "explicit override" \
  '{"role":"implementer","harness":"run-harness","model":"run-model","effort":"medium","fallbacks":[{"harness":"run-fallback","model":"run-fallback-model","effort":"low"}],"source":"explicit","fallback_reason":null}' \
  --project-root "$tmp/project" --role implementer --override-harness run-harness \
  --override-model run-model --override-effort medium \
  --override-fallback run-fallback,run-fallback-model,low

assert_route "reviewer selects independent fallback" \
  '{"role":"reviewer","harness":"reviewer-harness","model":"independent-model","effort":"high","fallbacks":[{"harness":"final-harness","model":"final-model","effort":"medium"}],"source":"project:role:fallback[0]","fallback_reason":"reviewer model matches author model identity"}' \
  --project-root "$tmp/reviewer" --role reviewer --author-model author-model

assert_route "reviewer filters author fallback" \
  '{"role":"reviewer","harness":"reviewer-harness","model":"independent-model","effort":"high","fallbacks":[{"harness":"final-harness","model":"final-model","effort":"medium"}],"source":"project:role","fallback_reason":null}' \
  --project-root "$tmp/filtered" --role reviewer --author-model author-model

assert_failure "reviewer requires author identity" "reviewer role requires --author-model" \
  --project-root "$tmp/reviewer" --role reviewer
assert_failure "reviewer requires independent route" "no independent reviewer route is available" \
  --project-root "$tmp/dependent" --role reviewer --author-model same-model
assert_failure "unknown role" "no route found for role 'unknown'" \
  --project-root "$tmp/empty" --role unknown
assert_failure "missing project root" "project root is not a directory: $tmp/missing" \
  --project-root "$tmp/missing" --role implementer
assert_failure "incomplete explicit override" \
  "explicit override requires --override-harness, --override-model, and --override-effort" \
  --project-root "$tmp/empty" --role implementer --override-model run-model
assert_failure "specialty requires reviewer" \
  "--reviewer-specialty is valid only for the reviewer role" \
  --project-root "$tmp/empty" --role implementer --reviewer-specialty security
assert_failure "invalid project JSON" "invalid JSON" \
  --project-root "$tmp/invalid" --role implementer

echo "$passes routing tests passed"
