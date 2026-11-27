// Secure Architecture Course
// Book-wide typography and layout. Compile with ./compile.sh from the project root.

#import "@preview/cmarker:0.1.10" as cmarker
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let ink = rgb("#0f172a")
#let accent = rgb("#0f766e")
#let muted = rgb("#64748b")
#let hairline = rgb("#cbd5e1")
#let paper-tint = rgb("#f8fafc")
#let paper = rgb("#fafafa")
#let body-font = "Liberation Sans"

// cmarker scope for the few Markdown files that retain Typst diagrams.
#let md-scope = (
  diagram: diagram,
  node: node,
  edge: edge,
  fletcher: fletcher,
)

// Markdown has no native include directive. A marker of the form
//   <!-- include: snippets/path/to/file.nix -->
// is replaced at render time with a fenced block whose language is taken from
// the file extension. Snippet paths are relative to this file (content/).
#let include-code(match) = {
  let path = match.captures.at(0)
  let extension = path.split(".").last()
  let language = if extension == "conf" { "text" } else { extension }
  "```" + language + "\n" + read(path).trim() + "\n```"
}

#let include-pattern = regex("<!-- include: ([^ ]+) -->")

// Each chapter declares its controlled language in YAML frontmatter. cmarker
// parses the block into a dictionary and removes it from the rendered body.
// The metadata is intentionally not printed: it is consumed by the CNL linter.
#let render-md(path, prefix) = {
  let (_meta, body) = cmarker.render-with-metadata(
    read(path).replace(include-pattern, include-code),
    h1-level: 2,
    label-prefix: prefix,
    scope: md-scope,
    metadata-block: "frontmatter-yaml",
  )
  body
}

// A part opener: roman numeral, title, blurb, and the chapters it contains.
#let part-open(num, title, blurb, chapters) = {
  align(center)[
    #block(above: 3.4cm)[
      #set text(font: body-font, size: 11pt, weight: "semibold", fill: ink)
      PART #num
    ]
  ]
  heading(level: 1, numbering: none)[Part #num — #title]
  align(center)[
    #block(above: 1.1em, width: 78%)[
      #set text(size: 11.5pt, fill: muted)
      #blurb
    ]
    #block(above: 2em)[
      #set text(font: body-font, size: 10.5pt, fill: ink)
      #chapters
    ]
  ]
  pagebreak()
}

#set document(
  title: "Secure Architecture Course",
  author: "Secure Architecture Course",
  description: "An architecture-first security course for small and medium businesses.",
  keywords: ("security", "architecture", "zero trust", "infrastructure"),
)

// ---- Title page (no running header or page number) ----

#page(
  paper: "a4",
  margin: (x: 2.2cm, top: 2.4cm, bottom: 0.6cm),
  fill: rgb("#111111"),
  header: none,
  numbering: none,
)[
  #place(bottom + left)[
    #set text(font: body-font, size: 40pt, weight: "bold", fill: paper)
    Secure Architecture
  ]
]

// ---- Global book style ----

#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  fill: paper,
  numbering: "1",
  number-align: center,
  header: [
    #set text(font: body-font, size: 8pt, fill: muted)
    #grid(columns: (1fr, auto), align: left)[Secure Architecture][Course manuscript]
    #line(length: 100%, stroke: 0.5pt + hairline)
  ],
)

#set text(font: body-font, size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.72em, spacing: 0.85em)
#set table(stroke: 0.4pt + hairline, inset: (x: 0.5em, y: 0.35em))

#show heading: it => {
  if it.level == 1 {
    // Parts: large, centred titles on their own pages.
    align(center)[
      #block(above: 0.2em, below: 0.6em)[
        #set text(font: body-font, size: 26pt, weight: "bold", fill: ink)
        #it.body
      ]
    ]
  } else if it.level == 2 {
    // Chapters: large, with a neutral rule.
    block(
      above: 1.5em,
      below: 0.9em,
      width: 100%,
      inset: (bottom: 0.35em),
      stroke: (bottom: 1.4pt + ink),
    )[
      #set text(font: body-font, size: 20pt, weight: "bold", fill: ink)
      #it.body
    ]
  } else if it.level == 3 {
    // Sections: smaller, neutral.
    block(above: 1.1em, below: 0.45em)[
      #set text(font: body-font, size: 13pt, weight: "semibold", fill: ink)
      #it.body
    ]
  } else {
    // Subsections and anything deeper.
    block(above: 0.8em, below: 0.3em)[
      #set text(font: body-font, size: 11pt, weight: "semibold", fill: ink)
      #it.body
    ]
  }
}

#show quote: it => block(
  fill: paper-tint,
  stroke: (left: 2.5pt + accent),
  inset: (x: 0.9em, y: 0.65em),
  radius: 2pt,
  above: 0.9em,
  below: 1em,
)[
  #set text(size: 9.8pt, fill: ink)
  #it.body
  #if it.attribution != none [
    #align(right)[
      #set text(size: 8.5pt, fill: muted, style: "italic")
      — #it.attribution
    ]
  ]
]

#show raw.where(block: true): it => block(
  width: 100%,
  fill: rgb("#0b1220"),
  inset: 0.85em,
  radius: 4pt,
  above: 0.8em,
  below: 1em,
)[
  #set text(font: "TeX Gyre Cursor", size: 8.6pt, fill: rgb("#e2e8f0"))
  #it
]

// ---- Contents ----

#block(above: 0.4em, below: 1.1em)[
  #set text(font: body-font, size: 22pt, weight: "bold", fill: ink)
  Contents
]
#outline(depth: 3, title: none)
#pagebreak()

// ---- Parts and chapters ----
// Markdown sources are rendered per chapter. Page breaks match the chapter-ending
// `#pagebreak()` calls from the former Typst sources. Each render is scoped so
// that chapter-local rules cannot leak into later chapters.

#part-open(
  "I",
  "Principles and Premises",
  [Why security has to be a property of the architecture, and the principles that make that concrete.],
  [
    Introduction \
    Foundations
  ],
)
#{
  render-md("principles_and_premises/introduction.md", "intro")
}
#pagebreak()
#{
  render-md("principles_and_premises/foundations.md", "foundations")
}
#pagebreak()

#part-open(
  "II",
  "Building the Stack",
  [Constructing the system layer by layer, from the network up to the application.],
  [
    Secure Networking \
    Host and Endpoint Security \
    Identity, PKI and Zero Trust \
    Cryptography and Data Security \
    Application and Software Supply Chain Security
  ],
)
#{
  render-md("building_the_stack/secure_networking.md", "networking")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_protocol_categories.md", "protocol-categories")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_layer0.md", "layer0")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_layer1.md", "layer1")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_layer2.md", "layer2")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_layer3.md", "layer3")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_layer4.md", "layer4")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_layer7.md", "layer7")
}
#pagebreak()
#{
  render-md("building_the_stack/secure_networking_ports.md", "ports")
}
#pagebreak()
#{
  render-md("building_the_stack/host_security.md", "host")
}
#pagebreak()
#{
  render-md("building_the_stack/identity_pki_zero_trust.md", "identity")
}
#pagebreak()
#{
  render-md("building_the_stack/data_security.md", "data-security")
}
#pagebreak()
#{
  render-md("building_the_stack/application_supply_chain.md", "application")
}
#pagebreak()

#part-open(
  "III",
  "Operating and Defending",
  [Seeing what the system does, understanding who attacks it, and surviving failure.],
  [
    Observability \
    Adversary Awareness \
    Resilience
  ],
)
#{
  render-md("operating_and_defending/observability.md", "observability")
}
#pagebreak()
#{
  render-md("operating_and_defending/adversary_awareness.md", "adversary-awareness")
}
#pagebreak()
#{
  render-md("operating_and_defending/resilience.md", "resilience")
}
#pagebreak()

#part-open(
  "IV",
  "People, Incentives and Obligation",
  [The human, economic and legal forces that decide whether the architecture gets built and kept.],
  [
    The Human Layer: Behaviour, Incentives and the Architecture That Survives Both \
    Governance, Compulsion, Privacy
  ],
)
#{
  render-md("people_incentives_and_obligation/human_layer.md", "human-layer")
}
#pagebreak()
#{
  render-md("people_incentives_and_obligation/governance_compulsion_privacy.md", "grc")
}
#pagebreak()

#part-open(
  "A",
  "Appendices",
  [Reference material: the ports appendix appears in Part II; this section collects the glossary and deployment practicals.],
  [
    Glossary \
    Practical: Samba AD DC on NixOS \
    Bibliography
  ],
)
#{
  render-md("glossary.md", "glossary")
}
#pagebreak()
#{
  render-md("practicals/samba_ad_nixos.md", "samba-practical")
}
#pagebreak()
#{
  render-md("bibliography.md", "bibliography")
}

/*
The former automation outline was distributed into the host, application and
governance chapters and the original outline is kept in archive/. Empty layer 5
and layer 8 stubs were removed; layer 6 was folded into the Layers 5–7 section.
Obsolete Typst drafts live in archive/ and are not sources.
*/
