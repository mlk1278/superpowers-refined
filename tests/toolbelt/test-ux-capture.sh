#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
script="$repo_root/skills/ux-gate/scripts/ux-capture"
fixtures="$repo_root/tests/toolbelt/fixtures/ux-capture"

tmp=$(mktemp -d)
server_pid=""
cleanup() {
  if [ -n "$server_pid" ]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT

fail() {
  echo "not ok - $1" >&2
  shift
  [ "$#" -gt 0 ] && printf '%s\n' "$@" >&2
  exit 1
}

[ -f "$script" ] || fail "capture script missing: $script"
[ -x "$script" ] || fail "capture script is not executable: $script"

# --- help_runs -------------------------------------------------------------
help_out=$(node "$script" --help 2>&1) || fail "--help exited non-zero" "$help_out"
case "$help_out" in
  *--smoke*) : ;;
  *) fail "--help output does not mention --smoke" "$help_out" ;;
esac
echo "ok - help_runs"

# --- skip_without_playwright ----------------------------------------------
mkdir -p "$tmp/empty"
echo '{}' > "$tmp/empty/package.json"
set +e
skip_err=$(env -u PLAYWRIGHT_MODULE node "$script" "$fixtures/matrix.json" \
  --out "$tmp/unresolved" --project-root "$tmp/empty" 2>&1 >/dev/null)
skip_code=$?
set -e
[ "$skip_code" -eq 2 ] || fail "expected exit 2 without playwright, got $skip_code" "$skip_err"
case "$skip_err" in
  *"cannot resolve 'playwright'"*) : ;;
  *) fail "exit-2 stderr lacks the resolution message" "$skip_err" ;;
esac
echo "ok - skip_without_playwright"

# Decide the module for the real run.
module="${PLAYWRIGHT_MODULE:-}"
if [ -z "$module" ]; then
  module=$(cd "$repo_root" && node -e "console.log(require.resolve('playwright'))" 2>/dev/null || true)
fi
if [ -z "$module" ]; then
  echo "SKIP - playwright unavailable"
  exit 0
fi

# --- static fixture server on an ephemeral port ----------------------------
node -e '
const http = require("http"), fs = require("fs"), path = require("path");
const root = process.argv[1];
http.createServer((req, res) => {
  const rel = decodeURIComponent(req.url.split("?")[0]);
  const file = path.join(root, rel);
  if (!file.startsWith(root)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404, {"Content-Type": "text/plain"}); res.end("not found"); return; }
    res.writeHead(200, {"Content-Type": file.endsWith(".html") ? "text/html; charset=utf-8" : "text/plain"});
    res.end(data);
  });
}).listen(0, "127.0.0.1", function () { console.log(this.address().port); });
' "$fixtures" > "$tmp/port.txt" &
server_pid=$!

port=""
for _ in $(seq 1 50); do
  port=$(head -n 1 "$tmp/port.txt" 2>/dev/null || true)
  [ -n "$port" ] && break
  perl -e 'select(undef,undef,undef,0.1)'
done
[ -n "$port" ] || fail "fixture server did not report a port"
base="http://127.0.0.1:$port"

rewrite_matrix() {
  node -e '
    const fs = require("fs");
    const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    m.baseUrl = process.argv[2];
    fs.writeFileSync(process.argv[3], JSON.stringify(m, null, 2));
  ' "$1" "$base" "$2"
}
rewrite_matrix "$fixtures/matrix.json" "$tmp/matrix.json"
rewrite_matrix "$fixtures/matrix-clean.json" "$tmp/matrix-clean.json"

# --- smoke_finds_fixture_defects ------------------------------------------
set +e
run_out=$(PLAYWRIGHT_MODULE="$module" node "$script" "$tmp/matrix.json" \
  --smoke --out "$tmp/out" --project-root "$tmp/empty" 2>&1)
run_code=$?
set -e
[ "$run_code" -eq 1 ] || fail "expected exit 1 on the defective fixture, got $run_code" "$run_out"

mech="$tmp/out/mechanical.json"
[ -f "$mech" ] || fail "mechanical.json not written" "$run_out"

query() { node -e "$1" "$mech"; }

parses=$(query 'const e=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); if(!Array.isArray(e)||!e.length) throw new Error("not a non-empty array"); console.log("ok")')
[ "$parses" = "ok" ] || fail "mechanical.json does not parse as a non-empty array"
echo "ok - mechanical.json parses"

assert_check() {
  local check=$1 selector=$2 theme=$3 desc=$4 found
  found=$(node -e '
    const fs = require("fs");
    const entries = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const [check, selector, theme] = process.argv.slice(2);
    const hit = entries.some((e) => (theme === "any" || e.theme === theme) &&
      (e.checks || []).some((c) => c.check === check && c.selector === selector));
    console.log(hit ? "yes" : "no");
  ' "$mech" "$check" "$selector" "$theme")
  [ "$found" = "yes" ] || fail "$desc" "no $check on $selector (theme $theme) in mechanical.json"
  echo "ok - $desc"
}

assert_check element-overflow "SPAN.overflow-child" any "element-overflow on the clipped span"
assert_check unclickable "BUTTON#covered" any "unclickable on the covered button"
assert_check theme-leak "DIV.hardcoded-white" dark "theme-leak on the hardcoded white block in dark"

for name in home-open-default-375-light home-open-default-375-dark \
            home-panel-default-375-light home-panel-default-375-dark; do
  [ -f "$tmp/out/$name.png" ] || fail "still missing: $name.png" "$(ls "$tmp/out")"
done
echo "ok - stills named per the Data Model"

recorded=$(node -e '
  const fs = require("fs");
  const entries = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  console.log(entries.map((e) => e.files.still).sort().join(","));
' "$mech")
expected="home-open-default-375-dark.png,home-open-default-375-light.png,home-panel-default-375-dark.png,home-panel-default-375-light.png"
[ "$recorded" = "$expected" ] || fail "recorded stills differ from expectation" "got: $recorded"
echo "ok - smoke_finds_fixture_defects"

# --- smoke_uses_first_viewport_only ---------------------------------------
widths=$(node -e '
  const fs = require("fs");
  const entries = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  console.log([...new Set(entries.map((e) => e.width))].join(","));
' "$mech")
[ "$widths" = "375" ] || fail "smoke captured widths other than 375" "widths: $widths"
echo "ok - smoke_uses_first_viewport_only"

# --- deferred Task 13 fields ----------------------------------------------
deferred=$(node -e '
  const fs = require("fs");
  const entries = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const bad = entries.filter((e) => e.diff !== null || e.files.filmstrip !== null ||
    e.files.diffCrop !== null || e.axe !== "skipped");
  console.log(bad.length ? JSON.stringify(bad[0]) : "ok");
' "$mech")
[ "$deferred" = "ok" ] || fail "smoke entry does not defer Task 13 fields" "$deferred"
echo "ok - smoke defers diff, filmstrip, diffCrop and axe"

# --- clean_page_has_no_findings -------------------------------------------
set +e
clean_out=$(PLAYWRIGHT_MODULE="$module" node "$script" "$tmp/matrix-clean.json" \
  --smoke --out "$tmp/clean" --project-root "$tmp/empty" 2>&1)
clean_code=$?
set -e
findings=$(node -e '
  const fs = require("fs");
  const entries = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const bad = entries.flatMap((e) => (e.checks || [])
    .filter((c) => c.severity === "blocker" || c.severity === "should")
    .map((c) => e.tag + " " + c.check + " " + c.selector));
  console.log(bad.length ? bad.join("; ") : "none");
' "$tmp/clean/mechanical.json")
[ "$findings" = "none" ] || fail "clean fixture produced should-or-above findings" "$findings"
[ "$clean_code" -eq 0 ] || fail "expected exit 0 on the clean fixture, got $clean_code" "$clean_out"
echo "ok - clean_page_has_no_findings"

echo "PASS"
