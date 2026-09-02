#!/usr/bin/env bash
set -euo pipefail

# Verifies the two rebase recipes skills/pr-monitor/SKILL.md quotes for a PR chain,
# on a three-layer chain main -> pr-1 -> pr-2 -> pr-3.
#
# After the bottom layer is squash-merged, each layer above is rebased ONE AT A TIME,
# working upward, each onto its immediate parent's new head using that parent's own
# old head as the cut point. Rebasing every layer onto the merged base instead would
# regenerate pr-2's commits independently inside pr-3, so pr-2 would stop being an
# ancestor of pr-3 and the upper PR would expose duplicate changes.

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

g() {
  git -C "$tmp" "$@"
}
commit() {
  git -C "$tmp" -c user.name=t -c user.email=t@t commit -q "$@"
}

g init -q -b main

echo base >"$tmp/base.txt"
g add base.txt
commit -m base

g checkout -q -b pr-1
echo one >"$tmp/one.txt"
g add one.txt
commit -m one

g checkout -q -b pr-2
echo two >"$tmp/two.txt"
g add two.txt
commit -m two

g checkout -q -b pr-3
echo three >"$tmp/three.txt"
g add three.txt
commit -m three

# Record each layer's old head BEFORE any rebase moves it.
old_1=$(g rev-parse pr-1)
old_2=$(g rev-parse pr-2)

g checkout -q main
g merge --squash pr-1 >/dev/null
# A realistic squash-merge carries a review fix, so the squash is NOT patch-identical
# to the pr-1 commit. Without this, git rebase's own patch-id dedup drops the
# already-applied commit and a plain `git rebase main pr-2` passes too, which would
# leave the assertions below unable to tell the --onto recipe from the naive one.
echo "review fix" >>"$tmp/one.txt"
g add one.txt
commit -m "squashed pr-1"

# A real monitor rebases one layer, pushes, and waits for that layer's CI before
# touching the next, so the layers move minutes apart. Pin distinct committer dates to
# model that separation; without it both rebases land in the same second and an
# independently replayed commit comes out hash-identical by luck, hiding the very
# divergence these assertions exist to catch.
rebase_at() {
  local when=$1
  shift
  env GIT_COMMITTER_DATE="$when" git -C "$tmp" rebase "$@" >/dev/null 2>&1
}

# Upward, one layer at a time. pr-2's parent is the merged base; pr-3's parent is pr-2,
# cut at pr-2's own recorded old head and landing on pr-2's NEW head.
rebase_at "2026-01-01T00:00:00Z" --onto main "$old_1" pr-2
new_2=$(g rev-parse pr-2)
rebase_at "2026-01-01T00:05:00Z" --onto "$new_2" "$old_2" pr-3

count_2=$(g rev-list --count main..pr-2)
if [ "$count_2" != "1" ]; then
  echo "not ok - pr-2 should hold exactly one commit above main, got $count_2" >&2
  exit 1
fi

count_3=$(g rev-list --count pr-2..pr-3)
if [ "$count_3" != "1" ]; then
  echo "not ok - pr-3 should hold exactly one commit above pr-2, got $count_3" >&2
  exit 1
fi

if ! g merge-base --is-ancestor pr-2 pr-3; then
  echo "not ok - rebased pr-2 is no longer an ancestor of pr-3" >&2
  exit 1
fi

tree=$(g ls-tree --name-only pr-3)
for f in base.txt one.txt two.txt three.txt; do
  if ! printf '%s\n' "$tree" | grep -Fqx -- "$f"; then
    echo "not ok - pr-3 tree missing $f" >&2
    echo "tree: $tree" >&2
    exit 1
  fi
done

echo "ok - chain rebase recipe"
echo "PASS"
