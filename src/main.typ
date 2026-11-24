// Secure Architecture Course
// Book-wide typography and layout. Compile with ./compile.sh from the project root.

#let ink = rgb("#0f172a")
#let accent = rgb("#0f766e")
#let muted = rgb("#64748b")
#let hairline = rgb("#cbd5e1")
#let paper-tint = rgb("#f8fafc")

// A part opener: roman numeral, title, blurb, and the chapters it contains.
#let part-open(num, title, blurb, chapters) = {
  align(center)[
    #block(above: 3.4cm)[
      #set text(font: "TeX Gyre Heros", size: 11pt, weight: "semibold", fill: accent)
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
      #set text(font: "TeX Gyre Heros", size: 10.5pt, fill: ink)
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
  margin: (x: 2.2cm, y: 2.4cm),
  header: none,
  numbering: none,
)[
  #align(center)[
    #block(above: 5.2cm)[
      #set text(font: "TeX Gyre Heros", size: 33pt, weight: "bold", fill: ink)
      Secure Architecture
    ]
    #block(above: 0.7em)[
      #set text(font: "TeX Gyre Heros", size: 15pt, fill: accent)
      An architecture-first security course
    ]
    #block(above: 3.2em, width: 82%)[
      #set text(size: 11pt, fill: muted)
      For the people who design and operate infrastructure at small-to-medium
      businesses — where the team that builds the system is the team responsible
      for keeping it secure.
    ]
    #block(above: 6.5em)[
      #set text(font: "TeX Gyre Heros", size: 9pt, fill: muted)
      Work in progress · #datetime.today().display("[year]")
    ]
  ]
]

// ---- Global book style ----

#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  numbering: "1",
  number-align: center,
  header: [
    #set text(font: "TeX Gyre Heros", size: 8pt, fill: muted)
    #grid(columns: (1fr, auto), align: left)[Secure Architecture][Course manuscript]
    #line(length: 100%, stroke: 0.5pt + hairline)
  ],
)

#set text(font: "New Computer Modern", size: 10.5pt, lang: "en")
#set par(justify: true, leading: 0.72em, spacing: 0.85em)
#set table(stroke: 0.4pt + hairline, inset: (x: 0.5em, y: 0.35em))

#show heading: it => {
  if it.level == 1 {
    // Parts: large, centred titles on their own pages.
    align(center)[
      #block(above: 0.2em, below: 0.6em)[
        #set text(font: "TeX Gyre Heros", size: 26pt, weight: "bold", fill: ink)
        #it.body
      ]
    ]
  } else if it.level == 2 {
    // Chapters: large, underlined with the accent colour.
    block(
      above: 1.5em,
      below: 0.9em,
      width: 100%,
      inset: (bottom: 0.35em),
      stroke: (bottom: 1.4pt + accent),
    )[
      #set text(font: "TeX Gyre Heros", size: 20pt, weight: "bold", fill: ink)
      #it.body
    ]
  } else if it.level == 3 {
    // Sections: smaller, accent-coloured.
    block(above: 1.1em, below: 0.45em)[
      #set text(font: "TeX Gyre Heros", size: 13pt, weight: "semibold", fill: accent)
      #it.body
    ]
  } else {
    // Subsections and anything deeper.
    block(above: 0.8em, below: 0.3em)[
      #set text(font: "TeX Gyre Heros", size: 11pt, weight: "semibold", fill: ink)
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
  #set text(font: "TeX Gyre Heros", size: 22pt, weight: "bold", fill: ink)
  Contents
]
#outline(depth: 2, title: none)
#pagebreak()

// ---- Parts and chapters ----
// Each include is scoped so that any chapter-local set rules (notably the page
// override in osi/layer1.typ) cannot leak into later chapters.

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
  include "./introduction/main.typ"
}
#{
  include "./foundations/main.typ"
}

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
  include "./osi/main.typ"
}
#{
  include "./host/main.typ"
}
#{
  include "./iam/main.typ"
}
#{
  include "./data_security/main.typ"
}
#{
  include "./application/main.typ"
}

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
  include "./observability/main.typ"
}
#{
  include "./adverserial/main.typ"
}
#{
  include "./resilience/main.typ"
}

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
  include "./incentives/main.typ"
}
#{
  include "./grc/main.typ"
}

/*
Automation is intentionally excluded for now; its material will be folded into
the relevant chapters above.
#{
  include "./automation/main.typ"
}
*/
