#!/usr/bin/env bash
# Compile the Secure Architecture book from the project root.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-$root/secure_architecture.pdf}"

# Keep PDF creation metadata stable for a given set of sources. Using the last
# commit that touched content/ means regenerating the tracked PDF does not
# change the timestamp on the next build.
epoch="$(git -C "$root" log -1 --format=%ct -- content 2>/dev/null || printf '0')"

typst compile "$root/content/index.typ" "$out" --creation-timestamp "$epoch"
printf 'Built %s\n' "$out"

# The repository README is the introduction chapter. Strip the CNL frontmatter
# so the generated file reads as ordinary Markdown outside the book build.
intro="$root/content/principles_and_premises/introduction.md"
tmp="$(mktemp)"
awk '
  NR == 1 && $0 == "---" { skip = 1; next }
  skip && $0 == "---" { skip = 0; next }
  !skip { print }
' "$intro" > "$tmp"
mv "$tmp" "$root/README.md"
printf 'Wrote %s\n' "$root/README.md"
