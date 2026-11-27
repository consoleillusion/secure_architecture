## A Rigorous Classification of Network Protocols

### Introduction

Most introductions to the OSI model treat it as a memory exercise — seven layers to recite, acronyms to memorise, exam questions to pass. When pressed for precision, teachers often retreat to "real protocols don't fit the model cleanly, it's just a guide." This is unsatisfying and misses the point entirely.

The OSI model is not a taxonomy. It is an argument: that every useful thing a computer network does is only possible because something more fundamental exists beneath it. Each layer is not merely related to the one below; it is **required** by it. Remove any layer and everything above it collapses. Understanding this dependency chain is what separates someone who knows networking from someone who can reason about it.

This document treats the OSI model not as a loose description of how networks operate, but as a precise mechanical account of the data types that exist on a network, the mandatory transformations required to produce them, and the strict dependency chain by which lower layers make higher layers possible. Every layer depends on the one below it — not loosely, not approximately, but necessarily.

The fuzziness in teaching comes not from the model itself, but from a lack of rigorous vocabulary for what protocols actually **do**. Most classifications tell you **where** a protocol lives. They do not tell you **what kind of operation** it performs on the data. This document proposes a classification that fixes that, and shows why the distinction matters both for understanding networks and for reasoning about how they can be attacked.

### How Each Layer Earns Its Existence

Before introducing the classification, it helps to walk the layers from the bottom and see how each one solves a problem the layer below cannot.

#### Layer 0 — The medium

Before anything else, there must be something for a signal to travel through. Copper carries electrical charge. Glass carries light. Air carries electromagnetic waves. None of these materials "know" anything about data — they simply have physical properties that allow energy to propagate. Layer 0 is usually not part of formal models, but it can be said to represent raw signal, waves, or current on a medium without the concept of "information." It is just noise. No medium means no signal, and without a signal, the entire stack above is imaginary.

#### Layer 1 — Bits

A medium alone produces nothing useful. Layer 1 is where deliberate structure is imposed on the medium: voltages are driven onto copper, lasers pulse into fibre, radio waves are modulated in air. These structured variations — ones and zeros — are the first emergence of **information** from pure physics. The critical insight is that a bit does not exist at Layer 0. It is a Layer 1 invention, made possible only because the medium beneath it can carry a distinguishable signal.

#### Layer 2 — Frames

A stream of bits on a wire is still not enough to communicate. You cannot address a destination, detect corruption, or know where one message ends and another begins. Layer 2 solves this by grouping bits into **frames**: structured bundles with source and destination MAC addresses, and error detection. The concept of a frame has no meaning at Layer 1, which knows only raw bits. Crucially, there is no concept of a "network" at Layer 2, only of two directly connected devices exchanging frames. The network is a later invention.

#### Layer 3 — Packets

Layer 2 can move data between adjacent devices, but only between adjacent devices. What if the destination is not directly connected? Layer 3 introduces the **packet** and the logical address — the IP address — which identifies not a physical device but a location on an internetwork. Routers operate here, using packets to carry data across multiple hops. The entire internet, the routing of data across continents, exists because Layer 3 added addressability to what Layer 2 could only deliver locally.

#### Layer 4 — Segments

Packets arrive independently, out of order, and sometimes not at all. Layer 4 transforms this unreliable stream into something a higher layer can depend on. TCP reassembles packets into the correct sequence, acknowledges receipt, and retransmits losses. UDP offers the same addressing without the guarantees, trading reliability for speed. Either way, Layer 4 is where **reliable communication** is born — a concept that does not exist at the packet level below.

#### Layers 5–7 — Sessions, presentation, application

Reliable data transfer between two ports is not the same as a **conversation**. Layer 5 manages the lifecycle of communication sessions — establishing them, maintaining them across interruptions, and terminating them cleanly. A video call that can pause and resume, a login session that persists across requests: these require continuity over time, which Layer 4 alone cannot provide.

Two machines may both receive a session's data and still not understand each other, because they represent data differently. Layer 6 handles translation, compression, and encryption. It is responsible for ensuring that what one application sends, another can interpret. JPEG images, TLS encryption, JSON encoding: these are all presentation-layer concerns. This layer makes **interoperability** possible, converting raw bytes into shared meaning.

At the top of the stack, a human being opens a browser, sends an email, or streams a video. None of this is possible without every layer below doing its job invisibly. HTTP, DNS, SMTP — these protocols assume all lower layers are functioning correctly and build the final abstraction: a network that a person can actually **use**. This is the only layer most users ever see, and it exists entirely because of the six layers beneath it.

The OSI model's deepest lesson is not about networking — it is about how complexity is made manageable. Each layer earns its existence by solving a problem the layer below cannot solve, and in doing so, hides that problem from every layer above. This is why violations of layer boundaries cause such persistent confusion: when someone conflates a MAC address with an IP address, or tries to reason about routing without understanding addressing, they are making a category error. Respecting the layers is not pedantry. It is the only reliable way to think clearly about how networked systems work, fail, and can be secured.

### The Dependency Chain

Every layer of the OSI model operates on a specific data unit — a **Protocol Data Unit**, or PDU. Bits at Layer 1. Frames at Layer 2. Packets at Layer 3. Segments at Layer 4. Application data at Layers 5–7. These are not interchangeable. A Layer 3 protocol operates on packets. It cannot operate on frames. It does not know what frames are. The packet must exist before Layer 3 can do anything with it.

This means that for each PDU to come into existence, something must **create** it from the PDU below. That act of creation — wrapping one PDU inside another, adding a header, producing a new data type — is a Transformation. It is not optional. It is not a convention. It is the mechanism by which each layer becomes possible.

The dependency chain, in full, looks like this:

```
Physical medium (Layer 0)
    ↓  [signal encoding]
Bits (Layer 1)
    ↓  [framing]
Frame (Layer 2)
    ↓  [encapsulation]
Packet (Layer 3)
    ↓  [segmentation]
Segment (Layer 4)
    ↓
Application data (Layers 5–7)
```

Every arrow in this diagram is a mandatory Transformation step. Skip any one and the chain breaks. This is observable in any packet capture: the headers appear in exactly this order because the transformations happen in exactly this sequence.

A layer can be **replaced** by an alternative implementation — Wi-Fi can substitute for Ethernet at Layer 2, IPv6 for IPv4 at Layer 3 — provided the substitute either presents the same PDU type to the layer above, or replaces those higher layers entirely with equivalent functionality. What cannot happen is the elimination of a layer without something taking its place in the dependency chain.

### The Five Protocol Types

With the dependency chain as the foundation, every protocol can be classified into one of five types based on what it does to the PDU.

#### Type 1: Single Layer

A Single Layer protocol operates entirely within one OSI layer. It takes the PDU of its layer as input, processes it, and outputs the same PDU type. It never changes the data unit type. It never touches a PDU from another layer.

**Test:** Does this protocol ever produce or consume a PDU with a different name? If no, it is a Single Layer protocol.

**Dependency implication:** A Single Layer protocol can only operate after the PDU of its layer has been created by the Transformation below it. It depends on the stack beneath it but does not contribute to building it.

**Examples:** TCP, UDP (Layer 4); ICMP, OSPF, EIGRP (Layer 3); HTTP, SMTP, DNS, BGP (Layer 7).

#### Type 2: PDU Transformation

A PDU Transformation protocol takes the PDU of layer N and produces the PDU of layer N+1 (on the transmit side), or takes the PDU of layer N+1 and produces the PDU of layer N (on the receive side). It is the mechanism of encapsulation and decapsulation. It is the only type of protocol that actually changes the name of the data unit.

**Test:** Does this protocol change the PDU type — segment to packet, packet to frame, frame to bits? If yes, it is a PDU Transformation protocol.

**Dependency implication:** PDU Transformation protocols are the load-bearing elements of the stack. Every upper layer is entirely dependent on the Transformation immediately below it. There is no substitute and no workaround.

**Examples:** IP (segment → packet), Ethernet (packet → frame), Wi-Fi (packet → frame), the Ethernet PHY (frame → bits).

#### Type 3: PDU Address Translation

A PDU Address Translation protocol operates at a layer boundary. It does not change the PDU type — it is still working within a single layer's frames or packets. What it does is translate an address from one layer's addressing scheme into the addressing scheme required by the next Transformation protocol.

This type is distinct from a Single Layer protocol because its purpose is specifically to enable a Transformation that could not otherwise complete. Without the translated address, the Transformation protocol cannot correctly build its PDU header.

**Test:** Does this protocol translate an address from one layer's scheme (e.g. IP) into another layer's scheme (e.g. MAC), without encapsulating any payload from a different layer? If yes, it is a PDU Address Translation protocol.

**Dependency implication:** PDU Address Translation is a prerequisite enabler. It is required before the next Transformation can execute, but it is not the Transformation itself. Remove it and the Transformation stalls — Ethernet cannot fill in the destination MAC field, so no frame can be built, so no packet can be delivered.

**Why DNS does not belong here:** DNS translates human-readable names into IP addresses, but this translation is not required for the PDU dependency chain to function. A host can be reached by raw IP address without DNS. DNS failure produces an application-layer problem, not a stack collapse. ARP failure produces a stack collapse. The dependency is of a different kind entirely — DNS is a convenience; ARP is a necessity.

**Examples:** ARP (IPv4 → MAC), NDP (IPv6 → MAC, carried in ICMPv6), RARP (MAC → IPv4), InARP (DLCI → IPv4), Proxy ARP.

#### Type 4: Composite, Intra-Layer

A Composite protocol is a single named protocol that internally bundles multiple sub-protocols. An Intra-Layer Composite bundles sub-protocols that all operate at the same OSI layer. All sub-protocols work on the same PDU type. The composite hides the internal structure but does not itself perform any cross-layer transformation.

**Test:** Is this one named protocol that contains multiple named sub-protocols, all operating on the same PDU type? If yes, it is an Intra-Layer Composite.

**Examples:** IPSec (bundles AH, ESP, and IKE, all operating on Layer 3 packets).

#### Type 5: Composite, Inter-Layer

An Inter-Layer Composite bundles sub-protocols that span different OSI layers, or includes a sub-protocol that itself performs a PDU Transformation. The composite hides a cross-layer dependency behind a single name.

**Test:** Is this one named protocol that contains sub-protocols operating at different layers, or that depends on a Transformation as part of its operation? If yes, it is an Inter-Layer Composite.

**Examples:** TLS (bundles the Handshake, Record, and Alert sub-protocols, and runs over TCP at a different layer), HTTPS (HTTP at Layer 7 plus TLS spanning Layers 4–6), QUIC (bundles UDP transport with its own encryption and congestion control, spanning Layers 4–6).

### Why This Classification Is Useful

#### It makes dependencies visible

The standard OSI presentation tells you that Layer 3 "sits above" Layer 2. This classification tells you **why** that relationship is not optional: there is a PDU Transformation protocol at the boundary, and without it the Layer 3 PDU does not exist. The dependency is mechanical, not architectural.

#### It resolves "where does this protocol live"

Teachers say "TLS is at the Presentation Layer" and then add "but it also uses TCP from the Transport Layer." This feels contradictory because it is. TLS is not a Single Layer protocol and cannot be accurately described by assigning it one layer. It is an Inter-Layer Composite. The classification resolves the confusion by giving it the right type rather than forcing it into a single-layer assignment it does not fit.

#### It maps the attack surface to precise points in the dependency chain

This is the major payoff for security practitioners, and the next two sections develop it in full.

| Protocol | OSI Layer(s) | Type | PDU | What It Does |
| --- | --- | --- | --- | --- |
| **HTTP / HTTPS** | 7 | Single Layer | Application data | Transfers hypertext; HTTPS is Inter-Layer Composite (see below) |
| **SMTP** | 7 | Single Layer | Application data | Email transfer between mail servers |
| **BGP** | 7 | Single Layer | Application data | Path-vector routing protocol; establishes TCP sessions, exchanges routing information, feeds routing tables, structurally identical to DNS but serves routers rather than applications |
| **RIP** | 7 | Single Layer | Application data | Distance-vector routing; older, limited to 15 hops |
| **FTP** | 7 | Single Layer | Application data | File transfer with separate control and data channels |
| **SSH** | 7 | Single Layer† | Application data | Encrypted remote shell; bundles auth, channel, and transport sub-protocols, may be treated as Intra-Layer Composite |
| **DNS** | 7 | Single Layer | Application data | Name-to-IP resolution; network stack does not require it |
| **SNMP** | 7 | Single Layer | Application data | Network device monitoring and management |
| **DHCP** | 7 | Single Layer | Application data | Dynamic IP address assignment |
| **RTP** | 7 | Single Layer | Application data | Real-time media transport (audio/video streams) |
| **TCP** | 4 | Single Layer | Segment | Reliable, ordered delivery; connection-oriented; error recovery |
| **UDP** | 4 | Single Layer | Datagram | Unreliable, connectionless delivery; no retransmission |
| **SCTP** | 4 | Single Layer | Chunk | Multi-stream reliable transport; combines features of TCP and UDP |
| **ICMP** | 3 | Single Layer | Packet | Error reporting and diagnostics (ping, traceroute); operates on packets |
| **ICMPv6** | 3 | Single Layer | Packet | IPv6 error reporting; also carries NDP messages |
| **OSPF** | 3 | Single Layer | Packet | Link-state routing; builds and maintains Layer 3 routing tables |
| **EIGRP** | 3 | Single Layer | Packet | Cisco hybrid routing protocol; combines distance-vector and link-state |
| **GRE** | 3 | Single Layer | Packet | Generic encapsulation tunnel; wraps packets inside packets for VPN transport |
| **NAT / PAT** | 3 | Single Layer† | Packet | Modifies IP addresses inside packets; operates at Layer 3 but rewrites header fields |
| **PPP** | 2 | Single Layer | Frame | Point-to-point framing; does not itself encapsulate packets (uses NCP sub-protocols for that) |
| **VLAN (802.1Q)** | 2 | Single Layer | Frame | Adds VLAN tag to existing frame; does not change PDU type |
| **STP / RSTP** | 2 | Single Layer | Frame | Loop prevention; manages port states to ensure loop-free Layer 2 topology |
| **LACP (802.3ad)** | 2 | Single Layer | Frame | Link aggregation control; negotiates bonded links between switches |
| **MACsec (802.1AE)** | 2 | Single Layer | Frame | Frame-level encryption and authentication; operates within Layer 2 |
| **Line encoding (NRZ, PAM4, Manchester)** | 1 | Single Layer | Bits | Encodes bit values as signal transitions; does not change the PDU type |
| **RS-232 / RS-485** | 1 | Single Layer | Bits | Physical signalling standards for serial communication |
| **USB (physical)** | 1 | Single Layer | Bits | Physical signalling layer; higher USB layers add framing and protocol |
| **HTTPS** | 5–7 | Composite, Inter-Layer | Application data + TLS | HTTP (Layer 7) composed with TLS (Inter-Layer Composite) |
| **SIP** | 5–7 | Composite, Inter-Layer | Application data | Bundles session description (SDP) and often composes with RTP for media |
| **TLS / SSL** | 5–6 (spans 4) | Composite, Inter-Layer | Application data + TCP segment | Bundles Handshake Protocol, Record Protocol, Alert Protocol; runs over TCP |
| **QUIC** | 4–6 | Composite, Inter-Layer | UDP datagram | Bundles UDP transport, encryption, and congestion control in one protocol |
| **SSH (transport layer)** | 4–7 | Composite, Inter-Layer | TCP segment | Three sub-protocols: transport, authentication, and connection, runs over TCP |
| **MPLS** | 2–3 | Composite, Inter-Layer | Frame / Packet | Inserts label between Layer 2 and Layer 3; often described as "Layer 2.5" |
| **IPSec** | 3 | Composite, Intra-Layer | Packet | Bundles AH (authentication), ESP (encryption), and IKE (key exchange), all at Layer 3 |
| **Wireguard** | 3 | Composite, Intra-Layer | Packet |  |
| **IP (IPv4)** | 3→4 | PDU Transformation | Segment → Packet | Encapsulates Layer 4 segment into Layer 3 packet; adds source/destination IP |
| **IPv6** | 3→4 | PDU Transformation | Segment → Packet | Same transformation as IPv4; 128-bit addressing; replaces IPv4 header format |
| **Ethernet** | 2→3 | PDU Transformation | Packet → Frame | Encapsulates Layer 3 packet into Layer 2 frame; adds source/destination MAC |
| **Wi-Fi (802.11)** | 2→3 | PDU Transformation | Packet → Frame | Same transformation as Ethernet over wireless medium |
| **PPPoE** | 2→3 | PDU Transformation | Packet → Frame | Encapsulates PPP frames carrying IP packets; used in DSL connections |
| **Ethernet PHY** | 1→2 | PDU Transformation | Frame → Bits | Encodes Layer 2 frame into Layer 1 bit stream for transmission |
| **Wi-Fi PHY (802.11 PHY)** | 1→2 | PDU Transformation | Frame → Bits | Same transformation over wireless medium |
| **DSL PHY** | 1→2 | PDU Transformation | Frame → Bits | Encodes frames onto telephone copper pairs |
| **NDP** | 3 | PDU Address Translation | Packet (ICMPv6) | Translates IPv6 address → MAC address; IPv6 equivalent of ARP |
| **ARP** | 2 | PDU Address Translation | Frame (EtherType 0x0806) | Translates IPv4 address → MAC address; prerequisite for Ethernet Transformation |
| **RARP** | 2 | PDU Address Translation | Frame | Translates MAC address → IPv4 address; obsolete, replaced by DHCP |
| **InARP** | 2 | PDU Address Translation | Frame Relay / ATM frame | Translates DLCI → IPv4 address; used in non-Ethernet Layer 2 technologies |
| **Proxy ARP** | 2 | PDU Address Translation | Frame | Responds to ARP requests on behalf of another host; same PDU, same translation role |

**† These classifications involve a judgement call where the protocol's implementation crosses layer boundaries in practice. The note indicates where reasonable disagreement exists.**
### The Dependency Proof in Full

The following sequence shows every protocol type that must execute, in order, for an HTTP request to reach a server from a client on the same LAN. This is observable directly in a Wireshark packet capture.

```
1. Application data
       ↓
2. HTTP           [Single Layer, Layer 7]      formats the request
       ↓
3. TLS            [Composite, Inter-Layer]     encrypts if HTTPS
       ↓
4. TCP            [Single Layer, Layer 4]      produces a segment
       ↓
5. IP             [PDU Transformation]         segment → packet
       ↓
6. ARP            [PDU Address Translation]    resolves destination IP → MAC
       ↓
7. Ethernet       [PDU Transformation]         packet → frame
       ↓
8. Ethernet PHY   [PDU Transformation]         frame → bits
       ↓
9. Physical medium (copper / fibre / air)
```

Remove step 6 (ARP) and step 7 cannot complete — Ethernet has no destination MAC to put in the frame header. Remove step 7 and the bits placed on the wire have no frame structure; the receiving device cannot recover the packet. Remove step 5 and the segment has no destination IP; the packet cannot be routed. Every step is a hard dependency. The model is not a heuristic. It is a description of the actual sequence of operations that must occur for any byte to move from one machine to another.

### The Security Implication

The value of this classification for security practitioners is that it maps the attack surface of the network to precise points in the dependency chain.

**Attacks on PDU Transformation protocols** target encapsulation itself — manipulating how packets are wrapped into frames, or how segments are wrapped into packets. BGP hijacking is in this family: by corrupting routing tables, an attacker causes IP (a PDU Transformation) to route packets through malicious infrastructure.

**Attacks on PDU Address Translation protocols** poison the prerequisite step before a Transformation. ARP poisoning is the canonical example. By inserting false IP-to-MAC mappings into a network's ARP caches, an attacker causes Ethernet — a Transformation that depends on ARP's output — to deliver frames to the wrong destination. The attacker never touches a packet. They undermine the address resolution that the Transformation depends on. Understanding the protocol type tells you exactly where the attack intervenes in the dependency chain.

**Attacks on Single Layer protocols at Layer 7** — DNS hijacking, HTTP injection, SMTP header manipulation — operate above the entire encapsulation stack. The PDU chain is intact. The attack is in the application data itself. The right defensive response is at Layer 7: DNSSEC, TLS, SPF/DKIM. Deploying a Layer 2 or Layer 3 control will not help.

**Attacks on Composite, Inter-Layer protocols** like TLS must be analysed at the sub-protocol level. Heartbleed was an implementation flaw in the Handshake extension mechanism. BEAST and CRIME attacked the Record Protocol. FREAK and Logjam attacked the handshake negotiation. These are different attacks on different components of the same composite, requiring different defences. A practitioner who treats TLS as a single monolithic thing will not be able to reason clearly about which part of it is under attack or which part of the mitigation applies. The composite structure is the reason TLS security analysis is so involved — you are not analysing one protocol, you are analysing a system of protocols with internal dependencies.

The classification does not solve every security problem. But it ensures that the problem is being analysed at the right level of abstraction, which is the prerequisite for solving it at all.

### Conclusion

The OSI model is not a vague teaching aid. It is a precise description of the dependency chain that makes networked communication possible. Every PDU must be created before the layer above it can operate. Every Transformation is mandatory. Every Address Translation is a prerequisite for a Transformation that cannot otherwise complete.

The five-type classification — Single Layer, PDU Transformation, PDU Address Translation, Composite Intra-Layer, and Composite Inter-Layer — gives practitioners a vocabulary that matches this precision. It allows any protocol to be unambiguously placed into a category with a verifiable test. It makes dependencies visible, maps the attack surface clearly, and resolves the layer-assignment confusion that surrounds composite protocols like TLS.

Most importantly, it treats the OSI model the way it deserves to be treated: not as a mnemonic, but as the actual mechanical description of the data on the wire.
