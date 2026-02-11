#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\n\033[1;34m==>\033[0m $*"; }
die()  { echo -e "\033[1;31m[x]\033[0m $*" >&2; exit 1; }

version() {
  local v
  v="$(git describe --tags --always --dirty 2>/dev/null || echo "dev")"
  echo "${v//\//-}"
}
