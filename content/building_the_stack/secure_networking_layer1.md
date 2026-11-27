## Layer 1 - Physical Layer

Layer 0 gave us a medium: something through which energy can travel. Layer 1 is the standard that says how to use that medium to carry bits. The word _bit_ is doing work here. Before Layer 1 there are no bits. There are voltages on a wire, there is light intensity inside a fibre, there is an electromagnetic wave with some amplitude and phase. Layer 1 is the agreement between two endpoints about how to interpret one of those continuous physical signals as a discrete sequence of ones and zeros. Above Layer 1, the rest of the stack is entitled to assume that bits arrive faithfully. Below Layer 1, nothing in the stack has any reason to believe anything.

If your role us to design and implement small scale business architecture, you don't need to understand most of the complexity at this level. The complexity largely belongs to people involved in areas like network card design, Ethernet, and WiFi standards. If you want to optimise and make enterprise decisions about adopting new routers that support the latest WiFi or Ethernet standards you may also need to learn more. This course focuses on implementing modern defaults, not differentiating between every existing standard.

This layer is where the electro-magnetic waves in the air and on a wire physics become information. The lower level is waves, the upper level is bits. This layer provides that transition. Protocols said to operate at this level do so at the bit level abstraction, but only a few protocols are actually involved in that transformation from waves to bits, specifically these are implemented in a network card.  When the medium is noisy, when the cable is cut, when the radio is jammed, Layer 1 fails, and no amount of cryptography above it compensates for the failure. The physics has to keep its promise, and Layer 1 is the specification of what that promise is.

### Layer 1 is a family of standards, not a single thing

The OSI model is usually drawn as a single stack of seven neat layers, which implies each layer is one thing. This is not true of Layer 1. Layer 1 is a category. A Layer 1 standard is any specification that completes the physics-to-bits transformation for some particular medium, and the specifications for different media have essentially nothing in common at the lowest level. The document that describes how bits travel over a copper twisted pair and the document that describes how bits travel as radio waves through open air are both Layer 1 standards. They are **different implementations of the same interface**, not variations of the same implementation.

The two standards that almost every SMB infrastructure will use are:

- **IEEE 802.3** ,  commonly called _Ethernet_ --- the standard for bits over wired media: copper twisted pair, coaxial cable, and optical fibre. It transforms a controlled voltage on a wire, or a controlled pulse of light in glass, into a bitstream.
- **IEEE 802.11** ,  commonly called _Wi-Fi_ --- the standard for bits over radio in open air. It transforms a modulated electromagnetic wave propagating through a room into a bitstream.

Both occupy Layer 1. Both produce a bitstream that Layer 2 can frame. Neither has anything to say about the other. Below the Layer 2 handoff they are different worlds.

### The three sublayers

What 802.3 and 802.11 do share is the _shape_ of the problem they solve. Converting continuous physical energy into discrete bits turns out to decompose into three concerns that are independent enough that the IEEE specifications name them separately and permit them to evolve separately.

**PMD ,  Physical Medium Dependent.** Everything specific to the medium itself. Driving voltages onto copper. Modulating a laser into fibre. Radiating an electromagnetic wave from an antenna. The PMD is what changes when the medium changes.

**PMA ,  Physical Medium Attachment.** The interface between the medium-specific world and the medium-independent world. Serialises parallel data into a single bit stream for transmission, reverses it on receive, and recovers the sender's clock from the incoming signal so the receiver knows where each bit begins and ends.

**PCS ,  Physical Coding Sublayer.** Converts between the abstract bitstream Layer 2 produces and the physically-robust symbol stream the PMA will actually transmit. Line coding lives here --- the schemes that ensure the signal has enough transitions to be recoverable and enough redundancy to survive the medium's characteristic errors.

<!--raw-typst
#align(center)[
  #diagram(
    edge-stroke: 0.8pt,
    node-corner-radius: 4pt,
    mark-scale: 70%,
    spacing: (1.6em, 0.9em),

    // Column headers
    node((-1, 0), [*Ethernet* \ IEEE 802.3], stroke: none, fill: none),
    node((0,  0), [], stroke: none, fill: none),
    node((+1, 0), [*Wi-Fi* \ IEEE 802.11], stroke: none, fill: none),

    // PCS row
    node((-1, 1), [NRZ, PAM-4, \ 64b/66b framing], fill: teal.lighten(50%), shape: fletcher.shapes.rect),
    node((0,  1), [*PCS*], stroke: 0.8pt, fill: white, shape: fletcher.shapes.rect),
    node((+1, 1), [OFDM, \ QAM-256 / 1024], fill: teal.lighten(50%), shape: fletcher.shapes.rect),

    // PMA row
    node((-1, 2), [Serialiser / \ deserialiser, clock], fill: green.lighten(50%), shape: fletcher.shapes.rect),
    node((0,  2), [*PMA*], stroke: 0.8pt, fill: white, shape: fletcher.shapes.rect),
    node((+1, 2), [Antenna, \ RF front-end], fill: green.lighten(50%), shape: fletcher.shapes.rect),

    // PMD row
    node((-1, 3), [Line driver, \ laser / LED], fill: olive.lighten(50%), shape: fletcher.shapes.rect),
    node((0,  3), [*PMD*], stroke: 0.8pt, fill: white, shape: fletcher.shapes.rect),
    node((+1, 3), [Radio transmitter \ 2.4 / 5 / 6 GHz], fill: olive.lighten(50%), shape: fletcher.shapes.rect),

    // Medium row
    node((-1, 4), [Copper twisted \ pair, or fibre], fill: gray.lighten(50%), shape: fletcher.shapes.rect),
    node((0,  4), [*Medium*], stroke: 0.8pt, fill: white, shape: fletcher.shapes.rect),
    node((+1, 4), [Open air], fill: gray.lighten(50%), shape: fletcher.shapes.rect),

    // Flow arrows within each column
    edge((-1, 1), (-1, 2), "<->"),
    edge((-1, 2), (-1, 3), "<->"),
    edge((-1, 3), (-1, 4), "<->"),

    edge((+1, 1), (+1, 2), "<->"),
    edge((+1, 2), (+1, 3), "<->"),
    edge((+1, 3), (+1, 4), "<->"),
  )
]
-->

The separation is not arbitrary. It is the same principle the introduction named as **separation of policy from mechanism**, applied to standards authoring instead of access control. The PCS does not need to know what medium its symbols will ride on; the PMD does not need to know what the bits it transmits mean. Each sublayer can be redesigned independently. When a new fibre type becomes deployable, only the PMD changes. When a new modulation scheme enables higher bitrates over the same cable, only the PCS changes. The modularity is the reason Ethernet has survived from 10 Mbps to 400 Gbps without being thrown out and rewritten, and it is the reason the same Wi-Fi driver on a laptop can talk to an access point radio it has never seen before, at a bitrate that did not exist when the laptop was manufactured.

### Ethernet: voltage on wire becomes bits

Ethernet's Layer 1 is a wired standard. Its PMD drives electricity into copper or light into glass. For most SMB infrastructure the medium is twisted-pair copper ,  Category 5e, Category 6, or Category 6A --- with optical fibre reserved for distances or electromagnetic environments that copper cannot survive. The naming convention is compact and worth recognising on sight: _10BASE-T_ means 10 Mbps, baseband signalling (the entire cable bandwidth is used for a single signal rather than divided into channels), over twisted pair. _1000BASE-LX_ means 1 Gbps, baseband, long-wavelength laser over single-mode fibre. The speed and medium are encoded directly in the name.

The PMD's tools are crude: it can raise or lower the voltage on a pair of wires, or it can flash a laser on and off. The PCS is where these crude primitives become a signal the receiver can actually decode. Early Ethernet encoded each bit as a voltage level ,  non-return-to-zero, NRZ --- which is simple but fragile: a long run of zeros produces no transitions and the receiver's clock drifts. Manchester coding fixed that at 10 Mbps by guaranteeing a transition in every bit period, at the cost of doubling the required bandwidth. Modern high-speed Ethernet at 25 Gbps and above uses PAM-4, which carries two bits per symbol by using four voltage levels instead of two, packing more data into the same copper at the cost of a smaller noise margin and more aggressive error correction. Each encoding was chosen to preserve bit recoverability as the signalling rate pushed against what the medium could carry. The arithmetic below the line keeps changing; the interface at the top stays the same.

The architectural property that matters about Ethernet's Layer 1 is that the signal _mostly_ stays in the cable. Copper emanates a weak electromagnetic field that can in principle be detected at short range ,  the TEMPEST problem discussed at Layer 0 --- but the field falls off rapidly and the signal is not a broadcast in any practical sense. Fibre emanates almost nothing. Cable selection and cable placement are therefore security decisions, not merely performance decisions that happen to have security consequences. A fibre run through a controlled plenum is defensible against interception in a way that an unshielded copper run along a wall shared with a neighbouring tenant is not, and that difference is a property of Layer 1.

### Wi-Fi: waves in air become bits

Wi-Fi's Layer 1 is a radio standard. Its PMD radiates an electromagnetic wave into open air at 2.4, 5, or 6 GHz, and listens on the same bands for waves radiated by other stations. The PMA is an antenna and a radio front-end. The PCS is dramatically more complex than Ethernet's: it uses _orthogonal frequency-division multiplexing_ (OFDM), which divides the channel into dozens of narrow parallel subcarriers and modulates each one independently using high-order quadrature amplitude modulation ,  QAM-256 in Wi-Fi 5, QAM-1024 in Wi-Fi 6, QAM-4096 in Wi-Fi 7. This complexity is the price of transmitting through a shared, noisy, unbounded medium. The standard must pack many bits per symbol, spread them across many frequencies, include aggressive forward error correction, and remain robust in the presence of interference it cannot control --- other Wi-Fi networks, microwave ovens, Bluetooth, baby monitors, a neighbour's poorly-shielded appliance, reflections of its own signal arriving late off the walls.

Wi-Fi's generations ,  802.11n, 802.11ac (Wi-Fi 5), 802.11ax (Wi-Fi 6 and 6E), 802.11be (Wi-Fi 7) --- each add capability at the PMD and PCS levels. MIMO (multiple antennas transmitting and receiving in parallel to exploit multi-path reflection rather than fight it) arrived in 802.11n. OFDMA (multiple clients served on different subcarriers within one transmission) arrived in Wi-Fi 6. The 6 GHz band and 320 MHz channels arrived in Wi-Fi 7. Each generation packs more bits into the same physical reality. The bitstream handed up to Layer 2 remains the same kind of object the whole time.

The architectural property that matters about Wi-Fi's Layer 1 is that the signal _does not stay anywhere_. Every transmission is a broadcast by construction. The electromagnetic wave that carries a bit from an access point to a laptop also carries it to every other receiver within range: across walls, through floors, out into parking lots and neighbouring tenancies. There is no physical defence against this capture. Range can be reduced with lower transmit power and directional antennas, but reduction is not elimination. Any security property that Wi-Fi appears to provide against passive eavesdroppers ,  WPA3, protected management frames, PMF --- exists because a layer _above_ Layer 1 is encrypting the bits. The radio itself is transparent to anyone with an antenna in range.

### What Layer 1 does and does not provide

Layer 1 delivers a bitstream. That is its entire contract. It does not identify the sender. It does not verify that the bits are what the sender _meant_ to transmit ,  the error detection in the PCS catches signal corruption, but bit-level integrity against a malicious actor is not on offer at Layer 1 and cannot be. It does not prevent anyone else from reading, recording, or injecting bits on the same medium. Every property a secure network eventually provides --- authentication, integrity, confidentiality --- comes from a layer above Layer 1, acting on bits Layer 1 has delivered.

But those upper-layer guarantees assume Layer 1 is doing its job. A TLS connection that cannot deliver bits does not exist. A VPN whose encrypted packets are dropped because the radio is jammed fails in a way no cryptographic strength can repair. Jamming, cable cuts, electromagnetic interference, and power loss are all Layer 1 failures, and they produce upper-layer outages that cannot be solved upward. The architectural answer is **diversity of media** ,  paths that fail independently, so that a single Layer 1 failure does not take the whole system down.

The security-architectural consequences of Layer 1 choice are therefore direct, and they follow from principles already stated in the introduction:

1. **Choose the medium whose emanation properties match the threat model.** Fibre for uncontrolled runs. Copper for short runs in physically controlled space. Wi-Fi only where the traffic riding on it is already protected by a layer above ,  which, in this course's architecture, with an encrypted mesh VPN as the default for internal traffic, it always is.
1. **Do not rely on Layer 1 for identity or confidentiality.** It cannot provide them. A cable plugged into a physically present port is no more trustworthy than a laptop that has just associated with an access point; both are at the start of a chain that must be authenticated and encrypted at higher layers. An architecture that trusts the physical port is an architecture with a soft interior boundary.
1. **Treat the physical path as part of the architecture.** Where cables run, where access points emit, which neighbours share the plenum or the airspace ,  these are architectural facts, not facilities concerns to be delegated. A correctly built network is correct about its physical path or it is not correct at all.

Layer 1 is short and unglamorous compared with the protocols above it. Its correctness is almost never what higher layers are thinking about. But everything that follows in this course ,  frame authentication at Layer 2, routing at Layer 3, reliable transport at Layer 4, application cryptography above that --- assumes Layer 1 is delivering bits correctly, and fails in characteristically confusing ways when it is not. The architect's work at Layer 1 is to make sure that assumption is warranted, by choosing the standard, the medium, and the physical path deliberately rather than by default.
