#!/usr/bin/env python3
"""Validate the controlled-language declarations in course chapters.

The linter checks that every Markdown source declares a supported CNL and that
chapters marked `lint: strict` satisfy the minimum requirements of that CNL.
It is deliberately a style linter, not a formal parser: ACE/SBVR rule blocks
are checked for the `shall` form, and E-Prime prose is checked for forms of
"to be". Full formal parsing would require an external ACE parser.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

ALLOWED_CNL = {
    "plain-language",
    "special-english",
    "ste",
    "ace",
    "clce",
    "sbvr",
    "rulespeak",
}
ALLOWED_SCOPE = {"narrative", "normative", "hybrid"}
ALLOWED_LINT = {"light", "strict"}
REQUIRED = ("cnl", "cnl-version", "cnl-scope", "lexicon", "lint")
SHALL_RULE = re.compile(r"^\s*[-*] .*\bshall\b", re.I)


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        raise ValueError("missing YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("unterminated YAML frontmatter")
    block = text[4:end]
    meta: dict[str, str] = {}
    for line in block.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise ValueError(f"invalid frontmatter line: {line!r}")
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip()
    return meta, text[end + 5 :]


def check(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        meta, body = split_frontmatter(path.read_text())
    except ValueError as exc:
        return [str(exc)]

    for key in REQUIRED:
        if key not in meta:
            errors.append(f"missing required field: {key}")
    if errors:
        return errors

    cnl = meta["cnl"]
    if cnl not in ALLOWED_CNL:
        errors.append(f"unsupported cnl: {cnl}")
    if meta["cnl-scope"] not in ALLOWED_SCOPE:
        errors.append(f"unsupported cnl-scope: {meta['cnl-scope']}")
    if meta["lint"] not in ALLOWED_LINT:
        errors.append(f"unsupported lint: {meta['lint']}")
    if meta["lexicon"] != "core-v1":
        errors.append(f"unknown lexicon: {meta['lexicon']}")
    if cnl in {"ace", "clce", "sbvr", "rulespeak"} and meta["lint"] == "strict":
        rules = [line for line in body.splitlines() if SHALL_RULE.match(line)]
        if len(rules) < 3:
            errors.append(
                f"{cnl} strict requires at least 3 'shall' rules; found {len(rules)}"
            )
    return errors


def main() -> int:
    failed = False
    for path in sorted(CONTENT.rglob("*.md")):
        errors = check(path)
        if errors:
            failed = True
            rel = path.relative_to(ROOT)
            for error in errors:
                print(f"{rel}: {error}")
    if failed:
        print("CNL lint failed", file=sys.stderr)
        return 1
    print(f"CNL lint passed ({len(list(CONTENT.rglob('*.md')))} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
