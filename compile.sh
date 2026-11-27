#!/usr/bin/env bash
# Compile the Secure Architecture book from the project root.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-$root/secure_architecture.pdf}"

typst compile "$root/src/index.typ" "$out"
printf 'Built %s\n' "$out"
