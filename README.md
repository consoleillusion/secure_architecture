# Secure Architecture

> **Work in progress.** This is a developing course manuscript, not a finished
> book. Some chapters are near-final prose, others are still outlines or
> fragments, and the generated artifacts in this directory may lag behind the
> sources. Expect rough edges.

Secure Architecture is an architecture-first security course written for the IT
teams that design and operate infrastructure at small-to-medium businesses
(roughly 5–100 people) — organizations large enough that ad-hoc configuration
is no longer defensible, but too small to have a dedicated security department
or SOC. The people who build the systems are the people responsible for their
security, so the architecture itself has to carry the weight.

The central argument: security is a property of how a system is built, not a
product bolted on afterwards. A segmented network does not need a product to
stop lateral movement; a host built from a declarative configuration cannot
silently drift; short-lived, scoped credentials remove the long-lived secrets
an attacker would steal. Zero trust is presented here not as a product category
but as the consistent application of long-standing principles — fail-safe
defaults, complete mediation, least privilege, explicit trust boundaries, and
minimizing the trusted computing base — to every component.

## Status

- Prose is substantially developed in the introduction, foundations,
  networking, identity/PKI, data security, adversary awareness, and human-layer
  chapters.
- The host, application security, observability, resilience, and governance
  chapters currently exist primarily as structured outlines with `Goal:` lines
  and bullet-point topics.
- The `automation/` chapter is written but commented out in `main.typ`; the
  intention is to distribute its material across the relevant chapters rather
  than keep it standalone.
- `osi/` contains a multi-file treatment of networking with per-layer files,
  diagrams, and a ports reference. Layers 5, 6, and 8 are currently commented
  out of `osi/main.typ`; files ending in `.typOLD` are older drafts, not part
  of the build.
- `secure_architecture.pdf` is a generated snapshot. Regenerate it after
  editing sources; do not edit it directly.

## Source layout

```
public/
├── main.typ                 # root document; include order = chapter order
├── introduction/            # one main.typ per chapter
├── foundations/
├── osi/                     # networking chapter, split by layer/topic
├── host/
├── iam/
├── data_security/
├── application/
├── observability/
├── adverserial/             # chapter on adversary awareness
├── incentives/              # human behaviour, incentives, economics
├── resilience/
├── grc/
├── automation/              # currently excluded from the build
└── secure_architecture.pdf  # generated snapshot
../compile.sh                # build script (run from this directory)
```

The document source lives in this `public/` directory. Everything above it is
scratch material: references, notes, drafts, and older exports.

## Building

Requirements:

- [Typst](https://typst.app/) CLI (tested with 0.15.x). HTML export currently
  requires a build with the `html` feature enabled.
- [Pandoc](https://pandoc.org/) for the optional Markdown export; `compile.sh`
  invokes it through `nix run nixpkgs#pandoc`, so Nix is needed for that step.
- Network access on first build if the `@preview` packages (`tablem`,
  `fletcher`) are not already in the Typst package cache.

From this directory:

```sh
../compile.sh
```

That script produces `secure_architecture.pdf`, an experimental HTML export,
and a Markdown conversion of the HTML in the current directory. To build just
the PDF, or to skip Pandoc:

```sh
typst compile main.typ secure_architecture.pdf
typst compile --features html --format html main.typ secure_architecture.html
```

HTML export is unstable and emits warnings for page rules, page breaks, and
diagrams; the PDF is the canonical output for now.

## Contributing

- Write Typst. Chapter files use `== Chapter title` as their first line and
  conventionally end with `#pagebreak()`.
- To add a chapter, create `<chapter>/main.typ` and add an `#include` line to
  `main.typ` in the position where it belongs.
- Cite sources inline where they inform architectural claims (NIST SP 800-33,
  Saltzer and Schroeder, NIST 800-63B, and so on).
- Keep outlines when a section is unfinished — the bullet lists are intentional
  scaffolding for planned prose.
- Regenerate `secure_architecture.pdf` when the text changes meaningfully.
