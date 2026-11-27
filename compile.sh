#!/usr/bin/env bash
# Compile the Secure Architecture book from the project root.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-$root/secure_architecture.pdf}"

# Keep PDF creation metadata stable for a given commit.
epoch="$(git -C "$root" log -1 --format=%ct 2>/dev/null || printf '0')"

typst compile "$root/content/index.typ" "$out" --creation-timestamp "$epoch"
printf 'Built %s\n' "$out"
