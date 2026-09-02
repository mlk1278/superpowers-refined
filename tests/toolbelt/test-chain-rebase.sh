#!/usr/bin/env bash
set -euo pipefail

# Verifies the rebase recipe skills/pr-monitor/SKILL.md quotes for a PR chain:
# after the bottom layer is squash-merged, the layer above rebases onto the base
# with --onto so the squashed commits are not replayed.

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

old=$(g rev-parse pr-1)

g checkout -q main
g merge --squash pr-1 >/dev/null
# A realistic squash-merge carries a review fix, so the squash is NOT patch-identical
# to the pr-1 commit. Without this, git rebase's own patch-id dedup drops the
# already-applied commit and a plain `git rebase main pr-2` passes too, which would
# leave the assertions below unable to tell the --onto recipe from the naive one.
echo "review fix" >>"$tmp/one.txt"
g add one.txt
commit -m "squashed pr-1"

g rebase --onto main "$old" pr-2 >/dev/null 2>&1

count=$(g rev-list --count main..pr-2)
if [ "$count" != "1" ]; then
  echo "not ok - pr-2 should hold exactly one commit above main, got $count" >&2
  exit 1
fi

tree=$(g ls-tree --name-only pr-2)
for f in base.txt one.txt two.txt; do
  if ! printf '%s\n' "$tree" | grep -Fqx -- "$f"; then
    echo "not ok - pr-2 tree missing $f" >&2
    echo "tree: $tree" >&2
    exit 1
  fi
done

echo "ok - chain rebase recipe"
echo "PASS"
