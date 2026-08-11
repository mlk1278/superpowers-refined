#!/usr/bin/env bash
set -euo pipefail

if ! command -v boxcar >/dev/null 2>&1; then
  echo "boxcar is not installed or not on PATH." >&2
  echo "Install it with: <boxcar-repo>/bin/boxcar install" >&2
  exit 1
fi

cd "$(dirname "$0")"
exec boxcar "$@"
