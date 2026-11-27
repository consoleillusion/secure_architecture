## A Rigorous Classification of Network Protocols

### Introduction

The OSI model is a teaching aid, but it is also a statement about dependencies. Each layer earns its place by solving a problem the layer below cannot solve, and hides that problem from the layers above. Conflating a MAC address with an IP address, or reasoning about routing without addressing, is a category error: the layers are not interchangeable labels.

This section classifies protocols by what they do to a **Protocol Data Unit** (PDU). The classification is not an end in itself. Its purpose is to make dependency and attack surface visible before an architect draws a trust boundary.

### The dependency chain

On transmit, application data is turned into a transport PDU, then a packet, then a frame, then bits, then a physical signal. On receive the sequence is reversed. The transformations are not conventions; they are how each PDU comes to exist.

```
Transmit:
Application data (Layers 5–7)
    ↓  [transport encapsulation]
Segment / datagram (Layer 4)
    ↓  [IP encapsulation]
Packet (Layer 3)
    ↓  [framing]
Frame (Layer 2)
    ↓  [line coding]
Bits (Layer 1)
    ↓  [modulation]
Physical medium (Layer 0)

Receive: the same chain in reverse.
```

A layer can be replaced by an alternative implementation — Wi-Fi for Ethernet, IPv6 for IPv4 — provided it presents the same PDU type to the layer above, or replaces the layers above with equivalent functionality. What cannot happen is removing a layer without something taking its place in the chain.

### The five protocol types

A protocol is classified by the PDU it **directly manipulates**. When a named protocol bundles work at several layers, that is recorded as a cross-layer note rather than as a second, contradictory classification.

#### Type 1: Single Layer

Operates entirely within one layer, taking and producing the same PDU type. Examples: ICMP and OSPF on packets, STP and VLAN tagging on frames, HTTP on application data.

#### Type 2: PDU Transformation

Defines the creation of a layer's PDU from the PDU above it on transmit, and reverses it on receive. Examples: TCP creates segments from application data; IP creates packets from segments; Ethernet and Wi-Fi create frames from packets; the PHY creates bits from frames.

#### Type 3: PDU Address Translation

Translates an address from one layer's scheme into the scheme needed by the next transformation, without changing the PDU type. ARP resolves IPv4 addresses to MAC addresses; NDP does the equivalent for IPv6. DNS is deliberately **not** in this type: name resolution is an application convenience, and a host can be reached by raw IP without it. ARP failure, by contrast, stops the frame from being built.

#### Type 4: Composite, Intra-Layer

A single named protocol bundling sub-protocols that all operate on the same PDU type. AH, ESP and IKE are often grouped as IPsec, but IKE runs over UDP, so on the strict test IPsec is an inter-layer composite. The AH/ESP pair is the intra-layer part.

#### Type 5: Composite, Inter-Layer

A named protocol whose sub-protocols span layers or depend on a transformation. TLS bundles handshake, record and alert protocols over TCP; HTTPS composes HTTP with TLS; QUIC bundles transport, encryption and congestion control over UDP; WireGuard bundles a UDP transport, a handshake, a cryptographic protocol and an IP tunnel. These are cross-layer systems and should not be assigned a single OSI layer.

### Classification table

| Protocol | Primary layer | Type | PDU manipulated | Note |
| --- | --- | --- | --- | --- |
| HTTP, SMTP, DNS, SNMP | 7 | Single Layer | Application data | DNS is application-layer, not address translation in the PDU sense |
| HTTPS | 7 + 4–6 | Composite, Inter-Layer | Application data + TLS | HTTP composed with TLS |
| SSH | 7 + 4 | Composite, Inter-Layer | Application data + TCP | Transport, authentication and connection protocols |
| BGP, RIP | 7 | Single Layer | Application data | Routing protocols that run as applications over TCP/UDP |
| TCP | 4 | PDU Transformation | Segment | Creates segments; reliable ordered delivery |
| UDP | 4 | PDU Transformation | Datagram | Creates datagrams; no reliability guarantees |
| QUIC | 4–6 | Composite, Inter-Layer | Datagram | Transport and cryptography in one protocol |
| ICMP, ICMPv6 | 3 | Single Layer | Packet | Diagnostics and error reporting |
| OSPF, EIGRP | 3 | Single Layer | Packet | Routing tables; transport is part of their implementation |
| IP, IPv6 | 3 | PDU Transformation | Packet | Creates packets from transport PDUs |
| IPsec (AH, ESP) | 3 | Composite, Intra-Layer | Packet | IKE itself runs over UDP and is treated separately |
| NAT / PAT | 3 | Single Layer | Packet | Rewrites address fields; relies on transport state for PAT |
| ARP, NDP | 2–3 boundary | PDU Address Translation | Frame / packet | Supplies the next-hop MAC address |
| Ethernet, Wi-Fi | 2 | PDU Transformation | Frame | Creates frames from packets |
| VLAN (802.1Q), STP, MACsec, LACP | 2 | Single Layer | Frame | Operate within the frame layer |
| GRE, MPLS | 2–3 | Composite, Inter-Layer | Frame / packet | Encapsulation between layers |
| Ethernet PHY, Wi-Fi PHY | 1 | PDU Transformation | Bits | Encodes frames as bits and modulates them onto the medium |
| Line encoding, RS-232/485 | 1 | Single Layer | Bits | Signalling within the bit layer |
| WireGuard | 3 + 4 | Composite, Inter-Layer | Packet + UDP datagram | Encrypted overlay, not a single-layer protocol |

### Why this classification is useful

**It makes dependencies visible.** Layer 3 “sits above” Layer 2 because a transformation at the boundary creates the frame that carries the packet. The dependency is mechanical, not a matter of drawing conventions.

**It resolves “where does this protocol live?”** TLS is not simply “at the Presentation Layer”; it is an inter-layer composite. Forcing it into one layer produces the familiar contradiction in which it is both above TCP and dependent on TCP.

**It maps attack surface to precise points in the chain.** Address translation, transformation and composition fail differently. ARP poisoning attacks the address-translation step; TCP hijacking attacks transport state; a TLS implementation flaw attacks a composite; a jamming attack attacks the medium. The layer chapter for each step describes its architectural answer.

### Conclusion

The value of the taxonomy is not that every protocol has a tidy one-word home. It is that the architect can state which PDU a protocol manipulates, which dependencies it requires, and which trust boundary it crosses. Where a protocol spans layers, that fact is itself the important result.
