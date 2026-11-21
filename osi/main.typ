== Secure Networking

#quote(attribution: "Edsger W. Dijkstra, The Humble Programmer")[
In this connection it might be worth-while to point out that the purpose of abstracting is not to be vague, but to create a new semantic level in which one can be absolutely precise.
]

#table(
  columns: (auto, auto),
  inset: 8pt,
  stroke: 0.5pt,

  [*OSI Layer*], [*PDU (Protocol Data Unit)*],

  [7. Application], [Data],
  [6. Presentation], [Data],
  [5. Session], [Data],
  [4. Transport], [Segment (TCP) / Datagram (UDP)],
  [3. Network], [Packet],
  [2. Data Link], [Frame],
  [1. Physical], [Bit],
  [0. Physics], [Wave],
)

#include "./osi_protocol_categories.typ"
#include "./layer0.typ"
#include "./layer1.typ"
#include "./layer2.typ"
#include "./layer3.typ"
#include "./layer4.typ"
//#include "./layer5.typ"
//#include "./layer6.typ"
#include "./layer7.typ"
//#include "./layer8.typ"

#pagebreak()
