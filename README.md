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
- The automation chapter is written as Markdown but excluded from the render
  list in `content/index.typ`; the intention is to distribute its material
  across the relevant chapters rather than keep it standalone.
- `content/building_the_stack/` contains the networking chapter plus its
  per-layer sections, a diagram, and a ports reference. Layers 5, 6, and 8 and
  the ports reference are currently excluded from the render list. Files
  ending in `.typOLD` under `content/osi/` are older Typst drafts, not part
  of the build.
- `secure_architecture.pdf` is a generated snapshot. Regenerate it after
  editing sources; do not edit it directly.

## Source layout

```
./
├── compile.sh                # build script; writes the PDF at the project root
├── content/
│   ├── index.typ             # root document; render order = chapter order
│   ├── principles_and_premises/
│   │   ├── introduction.md
│   │   └── foundations.md
│   ├── building_the_stack/
│   │   ├── secure_networking.md
│   │   ├── secure_networking_protocol_categories.md
│   │   ├── secure_networking_layer0.md … secure_networking_layer8.md
│   │   ├── secure_networking_ports.md  # excluded reference
│   │   ├── host_security.md
│   │   ├── identity_pki_zero_trust.md
│   │   ├── data_security.md
│   │   ├── application_supply_chain.md
│   │   └── automation.md     # excluded from the build
│   ├── operating_and_defending/
│   │   ├── observability.md
│   │   ├── adversary_awareness.md
│   │   └── resilience.md
│   └── people_incentives_and_obligation/
│       ├── human_layer.md
│       └── governance_compulsion_privacy.md
└── secure_architecture.pdf   # generated snapshot
```

`content/index.typ` is the only Typst source. It renders the Markdown files
with cmarker; the order of its `render-md` calls is the chapter order. Each
part directory is flat: one `chapter_name.md` per chapter. Older `.typOLD`
drafts remain under `content/osi/` only as historical references.

## Building

Requirements:

- [Typst](https://typst.app/) CLI (tested with 0.15.x).
- The `@preview` packages `cmarker` 0.1.10 and `fletcher` 0.5.8. Network access
  is needed on first build if they are not already in the Typst package cache.

From the project root:

```sh
./compile.sh                       # writes ./secure_architecture.pdf
./compile.sh /tmp/book.pdf         # optional custom output path
```

Or compile directly:

```sh
typst compile content/index.typ secure_architecture.pdf
```

The Markdown chapters are rendered into the PDF at build time; there is no
separate site output. The PDF remains the canonical artifact.

## Contributing

- Write Markdown. Chapter files use `# Chapter title` as their first line.
  `content/index.typ` renders with `h1-level: 2`, so `#`, `##`, `###` become the
  book's chapter, section and subsection levels.
- Page breaks are controlled in `content/index.typ`, not in chapter files. To
  add a chapter, create `content/<part>/<chapter>.md` and add a `render-md`
  call in `content/index.typ` at the position where it belongs.
- Use cmarker's reference syntax in Markdown: `[@label]` or
  `[Chapter][@label]`. Explicit IDs can be set with `<h2 id="label">`.
- The physical-layer diagram is retained as a documented `<!--raw-typst ... -->`
  block in `secure_networking_layer1.md`; `content/index.typ` provides the
  fletcher scope. Keep such blocks rare.
- Cite sources inline where they inform architectural claims (NIST SP 800-33,
  Saltzer and Schroeder, NIST 800-63B, and so on).
- Keep outlines when a section is unfinished — the bullet lists are intentional
  scaffolding for planned prose.
- Regenerate `secure_architecture.pdf` when the text changes meaningfully.
