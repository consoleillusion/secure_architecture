# Secure Architecture

> **Work in progress.** This is a developing course manuscript, not a finished
> book. The chapters are written as continuous prose, but the text continues to
> be revised and the PDF snapshot may lag behind the sources.

Secure Architecture is an architecture-first security course written for the IT
teams that design and operate infrastructure at small-to-medium businesses
(roughly 5–100 people) — organisations large enough that ad-hoc configuration
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
minimising the trusted computing base — to every component.

## Status

- All planned chapters are written as prose: principles, networking layers,
  host and application security, identity/PKI, data security, observability,
  adversary awareness, resilience, the human layer and governance.
- The ports reference is rendered in Part II. The glossary, the Samba AD DC
  practical and the book-wide bibliography are rendered as appendices.
- The Samba practical's configuration and shell code live as real `.nix` and
  `.sh` files under `content/snippets/samba/` and are included at render time.
- Old Typst drafts and the original automation outline are kept in `archive/`.
  They are historical sources and are not part of the build.
- `secure_architecture.pdf` is a generated snapshot. Regenerate it after
  editing sources; do not edit it directly.

## Source layout

```
./
├── compile.sh                  # deterministic PDF build; writes the PDF at the root
├── content/
│   ├── index.typ               # root document; render order = chapter order
│   ├── bibliography.md         # book-wide bibliography
│   ├── glossary.md
│   ├── principles_and_premises/
│   │   ├── introduction.md
│   │   └── foundations.md
│   ├── building_the_stack/
│   │   ├── secure_networking.md
│   │   ├── secure_networking_protocol_categories.md
│   │   ├── secure_networking_layer0.md … secure_networking_layer7.md
│   │   ├── secure_networking_ports.md
│   │   ├── host_security.md
│   │   ├── identity_pki_zero_trust.md
│   │   ├── data_security.md
│   │   └── application_supply_chain.md
│   ├── operating_and_defending/
│   │   ├── observability.md
│   │   ├── adversary_awareness.md
│   │   └── resilience.md
│   ├── people_incentives_and_obligation/
│   │   ├── human_layer.md
│   │   └── governance_compulsion_privacy.md
│   ├── practicals/
│   │   └── samba_ad_nixos.md
│   └── snippets/samba/         # included .nix and .sh code
├── archive/                    # excluded drafts and outlines
└── secure_architecture.pdf     # generated snapshot
```

`content/index.typ` is the only Typst source. It renders the Markdown files
with cmarker; the order of its `render-md` calls is the chapter order. Each part
directory is flat: one `chapter_name.md` per chapter. No source file outside
`content/` is rendered.

## Building

Requirements:

- [Typst](https://typst.app/) CLI (tested with 0.15.x).
- The `@preview` packages `cmarker` 0.1.10 and `fletcher` 0.5.8. Network access
  is needed on the first build if they are not already in the Typst package
  cache.

From the project root:

```sh
./compile.sh                       # writes ./secure_architecture.pdf
./compile.sh /tmp/book.pdf         # optional custom output path
```

Or compile directly:

```sh
typst compile content/index.typ secure_architecture.pdf
```

`compile.sh` sets the PDF creation timestamp from the latest git commit so the
same commit produces the same metadata. The Markdown chapters are rendered into
the PDF at build time; there is no separate site output. The PDF remains the
canonical artifact.

## Contributing

- Write Markdown. Chapter files use `# Chapter title` as their first line.
  `content/index.typ` renders with `h1-level: 2`, so `#`, `##`, `###` become the
  book's chapter, section and subsection levels.
- Page breaks are controlled in `content/index.typ`, not in chapter files. To
  add a chapter, create `content/<part>/<chapter>.md`, add a `render-md` call at
  the right position, and name the chapter in that part's opener.
- Cite sources with Markdown footnotes (`[^label]` and `[^label]: short
  citation`). Put the full publication details in `content/bibliography.md`.
- Include real code from `content/snippets/` with
  `<!-- include: snippets/path/to/file.nix -->`; the language is taken from the
  file extension. Keep runnable configuration in snippet files rather than in
  fenced Markdown blocks.
- Use cmarker's reference syntax for cross-references: `[@label]` or
  `[Chapter][@label]`. Explicit IDs can be set with `<h2 id="label">`.
- The physical-layer diagram is retained as a documented `<!--raw-typst ... -->`
  block in `secure_networking_layer1.md`; `content/index.typ` provides the
  fletcher scope. Keep such blocks rare.
- Prefer completed prose to outline stubs. If a section must remain skeletal,
  say so explicitly rather than leaving a list of topics as a placeholder.
- Regenerate `secure_architecture.pdf` when the text changes meaningfully.
