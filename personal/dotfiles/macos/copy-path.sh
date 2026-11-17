#!/bin/zsh
set -euo pipefail

if (( $# == 0 )); then
  exit 0
fi

printf '%s\n' "$@" | /usr/bin/pbcopy
