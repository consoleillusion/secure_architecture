---
cnl: ste
cnl-version: 1
cnl-scope: narrative
lexicon: core-v1
lint: light
---
## Layer 4 - The Transport Layer

### 1. Position in the Stack

Layer 4 is the layer at which two endpoints first speak to each other in terms that have nothing to do with the wire, the cable, the radio, or the route. Below it, every PDU is in transit between adjacent nodes; above it, every PDU is **application content**. Transport is the layer that converts a network — a thing capable of moving individual packets between hosts — into a **channel**, a thing capable of carrying a conversation.

Two protocols dominate Layer 4 in practice: **TCP** and **UDP**. They are equivalent in their structural role: both are constructed on top of a network-layer service (IP) and both expose an interface that the application layer programs against. That is what makes them Layer 4. They are **not** equivalent in what that interface offers. TCP exposes a reliable, ordered byte stream between two endpoints; UDP exposes addressable, length-delimited datagrams with no delivery guarantees. The choice between them is a choice about which guarantees the application is willing to provide for itself versus which it wants the kernel to provide.

This chapter treats both as instances of a more general pattern, applies the PDU transformation framework, surveys the other Layer 4 protocols you should know exist, and then turns to the security and design decisions a business of up to roughly 100 people actually has to make.

### 2. The PDU Transformation Framework Applied to Layer 4

Recall the three categories of protocol behaviour:

- **Single-layer protocols** are endofunctions: `A → A`. They operate on a PDU and return a PDU of the same type. Most of what happens **inside** a Layer 4 implementation falls here — retransmission, reordering, acknowledgement, congestion adjustment.
- **PDU transformations** are morphisms: `A → B`. They take a PDU of one type and produce a PDU of another. The headline morphism of Layer 4 is the conversion between an application-layer object (a stream of bytes, or a message) and a transport-layer object (a segment, or a datagram).
- **Inter-layer composites** are compositions of morphisms: `A → B → C`. The full descent of a payload — application data into a transport PDU into a network PDU into a link-layer frame — is one such composition.

Layer 4 therefore lives at the boundary between two morphisms. Below it, it composes with the network layer (`Segment → Packet`). Above it, it is the **target** of the morphism from the application layer's chosen content type.

#### 2.1 The Layer 4 morphisms in detail

For TCP:

```
Stream<Byte>  →  Sequence<Segment>
```

The application offers a stream of bytes with no inherent boundaries. TCP's job is to chop that stream into segments small enough to descend into the network layer, and to reconstitute it on the other side as the same stream of bytes. The stream abstraction is **preserved across the round trip**: what the sending application writes is what the receiving application reads, in order, with no holes. Internally, TCP runs many `Segment → Segment` endofunctions (retransmit, reorder, coalesce, ACK) to maintain this contract.

For UDP:

```
Message  →  Datagram
```

The morphism is much thinner. UDP takes a single application message of bounded size, prepends a small header, and hands it to the network layer. There is no stream to maintain, no ordering to enforce, no retransmission. The morphism is essentially an injective wrapping. Almost no internal endofunctions run — a UDP implementation that does nothing but checksum and forward is conformant.

This difference is the structural source of every other distinction between the two: state, latency, complexity, security surface, and application fit.

For QUIC (treated more fully below):

```
Stream<Byte>  →  Sequence<QUIC-Frame>  →  Sequence<UDP-Datagram>
```

QUIC reproduces the TCP-style morphism at its own layer, then composes with UDP's morphism beneath. This is one of the cleanest examples of why morphism composition matters: QUIC is **semantically** a Layer 4 protocol but **structurally** runs above another Layer 4 protocol.

### 3. The Concept of a Port

Before discussing the protocols themselves, we need the addressing scheme they share.

The network layer delivers a packet to a host. The transport layer must deliver it to a **process** on that host. The port is the demultiplexing key: a 16-bit unsigned integer that identifies which socket on the receiving host should be handed the payload.

A complete Layer 4 endpoint is therefore the tuple:

```
(IP address, transport protocol, port number)
```

A complete Layer 4 **connection** (for stateful protocols) is the four-tuple:

```
(source IP, source port, destination IP, destination port)
```

— qualified by the protocol. Two TCP connections that share all four fields are the same connection; if any field differs, they are distinct. This four-tuple is the index into the kernel's connection table and into every stateful firewall and NAT device on the path.

Port numbers are partitioned by IANA convention into three ranges:

- **0–1023: Well-known ports.** Assigned to standard services (22 for SSH, 53 for DNS, 80 for HTTP, 443 for HTTPS, etc.). On Unix systems, binding these requires elevated privilege.
- **1024–49151: Registered ports.** Assigned on request to specific applications.
- **49152–65535: Dynamic / ephemeral ports.** Used by clients to identify their end of an outbound connection.

The convention is not enforced by the protocol; it is enforced by the operating system and by everyone agreeing to follow it. A service can bind any free port. The well-known assignments are a discoverability convention, not a security boundary.

### 4. TCP — Transmission Control Protocol

#### 4.1 Design contract

TCP gives the application a reliable, ordered, full-duplex byte stream. Concretely:

- **Reliable:** every byte the sender writes will eventually be delivered or the connection will fail visibly.
- **Ordered:** bytes arrive in the same sequence they were sent.
- **Byte stream:** there are no message boundaries. The receiver may read in chunks of arbitrary size, regardless of how the sender wrote.
- **Full-duplex:** both endpoints can send and receive simultaneously.
- **Flow controlled:** the sender will not overrun the receiver's buffers.
- **Congestion controlled:** the sender will not overrun the network.

The price of these guarantees is state — kept in both endpoints — and at least one round trip of latency to establish a connection before any payload can flow.

#### 4.2 The header

The TCP header is a minimum of 20 bytes, extensible by options. The fields that matter for understanding the protocol's behaviour:

| Field | Width | Purpose |
|---|---|---|
| Source port | 16 bits | Demultiplexing on the sender side |
| Destination port | 16 bits | Demultiplexing on the receiver side |
| Sequence number | 32 bits | Position of the first byte of this segment in the byte stream |
| Acknowledgement number | 32 bits | Next byte the sender expects to receive |
| Data offset | 4 bits | Length of the header in 32-bit words |
| Control flags | 9 bits | SYN, ACK, FIN, RST, PSH, URG, ECE, CWR, NS |
| Window | 16 bits | How much the sender is willing to receive |
| Checksum | 16 bits | Verifies header and payload |
| Urgent pointer | 16 bits | Largely vestigial |
| Options | variable | MSS, window scale, SACK, timestamps, etc. |

Sequence numbers are the central mechanism. Every byte in the stream has a sequence number; segments carry the sequence number of their first byte. The receiver acknowledges by stating the next sequence number it expects. Loss is inferred from gaps; retransmission is keyed by the missing range.

#### 4.3 The three-way handshake

TCP connection establishment:

```
Client                                Server
  |                                     |
  |  SYN, seq=X                         |
  |------------------------------------>|
  |                                     |
  |          SYN-ACK, seq=Y, ack=X+1    |
  |<------------------------------------|
  |                                     |
  |  ACK, seq=X+1, ack=Y+1              |
  |------------------------------------>|
  |                                     |
  |        --- connection established --|
```

Three messages in one and a half round trips: the client can send payload with the final ACK after one round trip, and the server considers the connection established when that ACK arrives half a round trip later. The handshake serves three purposes: it confirms both endpoints exist and are willing, it exchanges initial sequence numbers, and it exchanges options (maximum segment size, window scale, SACK permission, timestamps).

The initial sequence numbers must not be predictable by an off-path attacker — this is the lesson of the early sequence-number-prediction attacks of the late 1980s and 1990s. Modern stacks generate them from a hashed combination of the four-tuple and a per-boot secret.

#### 4.4 The state machine

TCP is, formally, a finite state machine. Every connection sits in one of eleven states. The ones to know:

- `LISTEN` — passive open, waiting for incoming SYN
- `SYN-SENT` — active open, SYN sent, waiting for SYN-ACK
- `SYN-RECEIVED` — SYN received, SYN-ACK sent, waiting for ACK
- `ESTABLISHED` — handshake complete, data flowing
- `FIN-WAIT-1`, `FIN-WAIT-2`, `CLOSE-WAIT`, `CLOSING`, `LAST-ACK`, `TIME-WAIT` — variants of the closing dance
- `CLOSED` — terminal

The closing sequence is symmetric and four-way (each side independently signals it has no more to send), which is why the close has more states than the open.

`TIME-WAIT` is the state that surprises people. After both sides have closed, the active closer holds the four-tuple in `TIME-WAIT` for two maximum segment lifetimes (typically 60–120 seconds on Linux) to absorb any straggling segments. Under high connection churn this can exhaust ephemeral ports on the active closer.

#### 4.5 Reliability, flow control, congestion control

These are TCP's three internal endofunctions, all running on the segment stream:

- **Reliability** is handled by acknowledgements and retransmission timers. When a sent segment is not acknowledged within the retransmission timeout (RTO), it is resent. Modern TCP also uses fast retransmit (three duplicate ACKs trigger immediate resend without waiting for the timer) and selective acknowledgement (SACK) to retransmit only the missing ranges.
- **Flow control** is the receive window: the receiver advertises how many bytes of buffer space it has, and the sender will not exceed that. This is endpoint-to-endpoint backpressure.
- **Congestion control** is the congestion window: the sender maintains its own estimate of how much the **network** can carry, and sends the minimum of the receive window and the congestion window. The estimate is grown on success and shrunk on loss. The specific algorithm — Reno, CUBIC, BBR, etc. — is a kernel choice and is invisible to the application.

These mechanisms are why TCP is good for bulk transfer over arbitrary networks. They are also why TCP is bad for low-latency interactive workloads where a single dropped packet can stall the entire stream waiting for retransmission (head-of-line blocking).

---

### 5. UDP — User Datagram Protocol

#### 5.1 Design contract

UDP gives the application addressable, length-delimited, best-effort datagram delivery. Concretely:

- **Best-effort:** datagrams may be lost, duplicated, or reordered. The protocol will not detect or recover from any of this.
- **Message-oriented:** each `send` produces exactly one datagram; each `recv` returns exactly one datagram. Boundaries are preserved.
- **Connectionless:** no handshake, no state. The first packet contains payload.
- **Bounded size:** practical maximum is the path MTU minus headers; theoretical maximum is 65,507 bytes of payload.

UDP is the minimum protocol that is still distinguishable from raw IP. Its job is to add ports (so the OS can route a datagram to a process) and a checksum (so corruption is detected). Everything else is the application's problem.

#### 5.2 The header

UDP's header is 8 bytes. The complete list of fields:

| Field | Width | Purpose |
|---|---|---|
| Source port | 16 bits | Demultiplexing on the sender side |
| Destination port | 16 bits | Demultiplexing on the receiver side |
| Length | 16 bits | Header + payload length |
| Checksum | 16 bits | Verifies header and payload |

That's it. There is no sequence number, no flags, no window, no options. The brevity is the point: UDP imposes almost no overhead in bytes, in latency, or in implementation complexity.

#### 5.3 What UDP is good for

UDP is the right choice when one or more of the following hold:

- The application can recover from loss faster than TCP can retransmit (real-time audio and video, where a stale packet is worse than a missing one).
- The application provides its own reliability and ordering on top (QUIC, custom protocols).
- The interaction is request/response of a single packet each (DNS over UDP, NTP, many discovery protocols).
- Multicast or broadcast is required (TCP cannot do either).
- The interaction is fire-and-forget (syslog, statsd metrics).

UDP is the wrong choice when the application needs reliability and would otherwise reimplement TCP poorly. There are a great many badly-built UDP protocols whose authors should have used TCP and whose users discover loss only under unusual network conditions.

---

### 6. Other Layer 4 Protocols Worth Knowing

These are not equivalents to TCP and UDP in deployment, but they exist and are occasionally relevant.

#### 6.1 SCTP — Stream Control Transmission Protocol

SCTP was designed to address two TCP shortcomings: head-of-line blocking and the lack of multi-homing. It provides multiple independent ordered streams within a single association (so loss in one stream does not stall the others) and it allows an association to span multiple IP addresses on each endpoint (so a path failure can be transparent).

SCTP is the transport for SS7 signalling (Diameter, etc.) in telecoms infrastructure and is heavily used inside mobile core networks. Outside of telecoms, deployment is rare. Most NAT and firewall middleboxes do not handle SCTP, which is the practical reason it has not displaced TCP for general use.

In the PDU framework: SCTP's morphism is `MultiStream<Message> → Sequence<Chunk>`, where chunks carry the multi-stream identifier — a richer source object than TCP's flat byte stream.

#### 6.2 DCCP — Datagram Congestion Control Protocol

DCCP is what UDP would look like if it had congestion control without reliability. The intent was to provide a transport for media applications that wanted to be a good network citizen without paying for retransmission. It saw very little adoption, largely because applications that cared about congestion control were already implementing it themselves and applications that didn't care were perfectly happy with raw UDP.

#### 6.3 QUIC

QUIC is the most important Layer 4 protocol of the last fifteen years and the most architecturally interesting. It runs over UDP — every QUIC packet is a UDP datagram — but it provides TCP-like semantics: reliable, ordered, congestion-controlled streams. It also provides multiple independent streams in a single connection (avoiding head-of-line blocking), built-in TLS 1.3 encryption (the transport is encrypted, including most of the header, not just the payload), and connection migration (a connection survives the client's IP address changing).

The reason QUIC is built on UDP rather than directly on IP is pragmatic: middleboxes on the public internet only reliably pass TCP and UDP. A new transport protocol over IP would be silently dropped by a significant fraction of paths. UDP is the lowest-overhead transport that is universally routable.

In the PDU framework, QUIC is the cleanest case of a `Stream → Frame → Datagram → Packet` composition, with the frame layer doing TCP's job and UDP doing the job of being routable.

QUIC is the transport for HTTP/3 and is now responsible for a substantial fraction of public web traffic. From the perspective of a 100-person business, the practical implications are:

- Outbound HTTPS traffic is increasingly UDP/443, not TCP/443. Egress firewalls that allow only TCP/443 will fall back to TCP, which usually works but is not ideal.
- Network monitoring tools that only understand TCP will see less of the conversation.
- Encrypted transport headers mean less is visible to passive observers, including your own.

#### 6.4 Honourable mentions

- **ICMP** is sometimes described as Layer 4 and sometimes as Layer 3.5. It carries no application payload and is best understood as a control protocol for IP, not as a transport for applications.
- **GRE, ESP, AH** are encapsulation and tunnelling protocols. They occupy IP protocol numbers like TCP and UDP do, but they exist to wrap other protocols rather than to carry application payload directly. For our purposes they are below Layer 4.

---

### 7. Security at Layer 4

Layer 4 is where the network first becomes a **connection**, and therefore the first layer at which connection-oriented attacks are possible. It is also the layer at which the most useful coarse-grained security controls — stateful firewalls — operate.

#### 7.1 Attacks against TCP

**SYN flooding.** The attacker sends a high volume of SYN packets, often with spoofed source addresses, and never completes the handshake. The victim allocates state for each `SYN-RECEIVED` connection until its connection table is exhausted. Defence: SYN cookies, which encode the necessary state into the initial sequence number returned in the SYN-ACK so that no server-side state is allocated until the final ACK arrives.

**TCP reset injection.** An on-path or off-path attacker forges an RST segment with a plausible sequence number and four-tuple, causing one endpoint to tear down the connection. Off-path attacks require guessing the sequence number, which is feasible if the receive window is large. Mitigations include strict sequence number validation (RFC 5961) and, more decisively, transport encryption that authenticates the header (QUIC, IPsec).

**Sequence number prediction.** If the initial sequence number is predictable, an off-path attacker can inject bytes into the stream. Resolved in modern stacks by cryptographically random ISN generation.

**Connection hijacking.** An on-path attacker reads the four-tuple and sequence numbers and injects payload. Defence: encrypt the payload (TLS) or authenticate the transport (IPsec, QUIC).

**Slowloris and slow-read attacks.** The attacker opens connections and either sends or reads bytes at a glacial rate, holding server resources without triggering ordinary timeout heuristics. Defence: connection limits per source, idle timeouts, and request-rate limits at the application proxy.

#### 7.2 Attacks against UDP

**Amplification and reflection.** The attacker sends UDP requests with a spoofed source address (the victim) to a service that replies with a much larger response. The victim is hit with the amplified traffic. Classic vectors: open DNS resolvers, NTP `monlist`, memcached, SSDP. Defence on your own infrastructure: do not run open resolvers, disable amplification-prone features, rate limit UDP responses. Defence on your network: BCP38 ingress filtering, which drops outbound packets with source addresses that do not belong to your network.

**Flooding.** UDP is stateless, so any flood is, by default, a delivered flood. Defence: rate limiting, often pushed upstream to the carrier or DDoS provider for any volume worth defending against.

#### 7.3 Port scanning

Scanning is the reconnaissance that precedes most targeted attacks. The standard scan types:

- **TCP connect scan** — completes the handshake. Slow, noisy, easily logged.
- **TCP SYN scan** — sends SYN, observes SYN-ACK or RST, resets the half-open. Faster and historically less likely to be logged.
- **TCP FIN/NULL/Xmas scans** — send malformed flag combinations to elicit different responses from open vs closed ports. Largely defeated by modern stacks.
- **UDP scan** — slow and unreliable because closed UDP ports return ICMP unreachable (rate-limited) and open UDP ports usually return nothing.

The defensive posture is not to prevent scanning — you cannot — but to ensure that scans reveal only what you intend to expose. This is the function of a default-deny firewall.

#### 7.4 The role of stateful firewalls

A stateful firewall maintains its own connection table indexed by the four-tuple and uses TCP's state machine to decide which packets are part of an established conversation. The default rule is then: allow outbound new connections, allow inbound packets that belong to an existing connection, deny everything else. This is the simplest non-trivial security policy that is actually effective.

Stateful inspection is genuinely a Layer 4 capability — it requires understanding the TCP state machine — even though the device sits at the network boundary. UDP has no state machine, so stateful firewalls treat UDP "connections" as a heuristic: a flow is created on the first outbound packet of a four-tuple and expires after a configurable idle period. This is good enough for request/response protocols and not really good enough for anything else.

---

### 8. Layer 4 Design for a Business of up to 100 People

The technical material above describes the protocols. This section addresses what to do with them. The recommendations are deliberately conservative: at this scale, the cost of operational complexity exceeds the cost of suboptimal performance, and the right defaults are the ones a single person can hold in their head.

#### 8.1 Firewall posture

Run a stateful firewall at every trust boundary. The relevant boundaries for a 100-person business are typically: the internet edge, the boundary between user networks and server networks, and (if you have one) the boundary around any payment or regulated-data zone.

The baseline policy:

- **Default deny in both directions.** Inbound and outbound. Egress filtering is the control that catches a compromised internal host trying to call home; without it, perimeter security is one-sided.
- **Allow outbound by service, not by destination.** Permit TCP/443, TCP/80, UDP/443 (QUIC), UDP/53 to your DNS resolvers, NTP to your time sources, and whatever your specific applications need. Resist the temptation to allow "all outbound."
- **Allow inbound only to services you intend to expose.** Anything that does not need to be reachable from the internet should not be reachable from the internet. This usually means: nothing, with a small number of explicit exceptions for VPN endpoints and any hosted public services.
- **Log denied traffic.** The denials are the signal. Allowed traffic is too voluminous to be useful as a primary log source; denials are sparse and informative.

For a 100-person business, the firewall itself is probably an OPNsense or pfSense appliance, a Linux box running nftables, or a small commercial firewall. The choice matters less than the configuration discipline.

#### 8.2 NAT and what it does at Layer 4

NAT — specifically NAPT, network address port translation, which is what almost everyone means by "NAT" — operates by rewriting the four-tuple of outbound connections so that internal hosts share a single external IP address, and maintaining a translation table to reverse the mapping for return traffic.

This is a Layer 4 operation: the translation requires understanding ports, and the translation table is keyed by the four-tuple. A pure Layer 3 device cannot do NAT.

NAT is widely deployed for IPv4 address conservation and is widely (and incorrectly) treated as a security control. NAT happens to drop unsolicited inbound traffic because there is no translation entry to send it to, but this is a side effect of address translation, not a security policy. A real firewall does the same thing on purpose, with logging and explicit rules. If you have IPv6, you should not be doing NAT on it; you should be using a stateful firewall. The protection is identical and the address space does not need conserving.

#### 8.3 Load balancing — Layer 4 vs Layer 7

If you run any internal services with redundancy, you have a load balancer. The choice of layer matters.

**Layer 4 load balancing** distributes connections by four-tuple. The load balancer reads the TCP or UDP header, picks a backend, and forwards. It does not read the payload. It cannot route HTTP requests by hostname or path; it cannot terminate TLS. It is fast, simple, and protocol-agnostic — anything over TCP or UDP works.

**Layer 7 load balancing** terminates the connection at the load balancer, parses the application protocol (almost always HTTP), and makes routing decisions on the parsed content. It can route by hostname, path, header, or cookie. It can terminate TLS, inspect requests for attacks, rewrite headers, and do session affinity. It is slower per request and only works for protocols it understands.

The right answer for most 100-person businesses is Layer 7 for HTTP services (HAProxy, nginx, Caddy, Traefik, or a cloud equivalent) and Layer 4 for everything else, including the occasional internal database or message bus that needs failover. Putting a Layer 7 load balancer in front of a database is a category error.

A second consideration is TLS termination. Terminating TLS at the load balancer is convenient — one place to manage certificates, plaintext flows visible to the WAF and the logger — but it also means traffic between the load balancer and the backend is unencrypted unless you re-encrypt. The course does not accept a plaintext hop even on the internal overlay: re-encrypt from the load balancer to the backend, or terminate TLS at the backend itself. A decrypted segment is readable by anything that compromises the load balancer, the path or the backend host, and it defeats the endpoint authentication that TLS provides.

#### 8.4 VPNs and what layer they live at

VPNs that are relevant at this scale, ordered by operational simplicity:

- **WireGuard.** Runs over UDP. Minimal codebase, modern cryptography, simple configuration. Provides a Layer 3 tunnel; transports anything IP. The right default for site-to-site and remote-access VPN at this scale.
- **IPsec (with IKEv2).** The traditional standard. More complex configuration, more interoperable with vendor equipment, more entrenched in enterprise environments. Still appropriate when you must interoperate with hardware that only speaks IPsec.
- **OpenVPN.** Runs over UDP or TCP. Older codebase, more configuration surface, broader client support. Acceptable if you have a reason to prefer it; not the recommended default for a new deployment.
- **TLS-based VPNs (SSL VPNs).** Tunnel the network through HTTPS. The reason to use one is to traverse hostile firewalls that allow only TCP/443. The reason not to use one is everything else.

The Layer 4 implication for all of these: a VPN tunnel adds a layer of transport beneath the application's transport. The headers and reliability behaviour the application sees are unchanged, but the actual packets on the wire are UDP (for WireGuard, OpenVPN-UDP and IKE; ESP is IP protocol 50, carried in UDP only when NAT-T is in use) or TCP (for SSL VPNs and OpenVPN-TCP). This affects firewall rules, MTU calculations, and observability.

A note on TCP-over-TCP: tunnelling TCP through a TCP-based VPN is functional but produces pathological behaviour under loss, because the inner and outer TCP retransmit independently and interfere. WireGuard and OpenVPN-UDP avoid this by tunnelling at the IP layer and not retransmitting at the tunnel layer.

#### 8.5 Observability at Layer 4

Three things are worth monitoring at Layer 4:

- **Connection counts** by service, by source, and by state. A spike in `SYN-RECEIVED` is a SYN flood; a spike in `TIME-WAIT` on a busy server is ephemeral port pressure; a spike in `CLOSE-WAIT` is an application that is not closing sockets properly.
- **Connection rates.** New connections per second per service, denied connections per second per source. Anomalies in these are usually the first sign of either an attack or a misconfigured client.
- **Bytes by four-tuple.** Aggregate flow data (NetFlow, IPFIX, sFlow, or `conntrack` export) gives you a usable picture of who is talking to whom without requiring payload inspection. This is the right level of detail for capacity planning and for incident investigation, and it is much cheaper to store than full packet capture.

Full packet capture is occasionally useful for incident response. It is rarely useful as a routine practice at this scale, both for storage cost and because the increasing prevalence of TLS and QUIC means most of what you capture is opaque.

#### 8.6 Choosing TCP or UDP for your own services

If you are building or hosting a service, the default is TCP, and the default for "TCP carrying anything important" is TLS over TCP. Choose UDP only if:

- You are deploying QUIC or HTTP/3.
- You are deploying a real-time media protocol (SIP, RTP, WebRTC).
- You are deploying DNS, NTP, syslog, or another protocol that is conventionally UDP.
- You have a measured latency requirement that TCP cannot meet, and you have implemented or selected a protocol that handles loss correctly at the application layer.

The fourth case is the one where most mistakes happen. "I'll use UDP because it's faster" is rarely a true statement at the application level once the application has reimplemented enough of TCP to be correct.

#### 8.7 A minimal Layer 4 baseline

For a 100-person business, the following is a defensible Layer 4 baseline:

- Stateful firewall at the internet edge with default-deny in both directions and logged denials.
- WireGuard for remote access and site-to-site tunnels.
- HTTP services behind a Layer 7 reverse proxy with TLS terminated at the proxy (or passed through to backends in regulated environments).
- Internal services on private addresses not reachable from the internet.
- DNS to a trusted resolver, NTP to a trusted source, both via firewall rules that name the destination explicitly.
- Flow data exported from the firewall and the core switch to a single collector.
- Connection-state metrics on every server, exported to the same monitoring system as everything else.

This is not a complete security posture — it does not address authentication, application security, endpoint security, or data handling — but it is a complete **Layer 4** posture, and it is the part of the network design that, if wrong, makes the rest of the design irrelevant.

### 9. Summary

Layer 4 is the transformation from network packets into application channels. TCP and UDP are the two morphisms that matter in practice: TCP turns a byte stream into a sequence of acknowledged segments and back into a byte stream; UDP wraps a single message in a thin header and delivers it best-effort. Other transports — SCTP, DCCP, QUIC — exist; QUIC is the one that is becoming materially important.

The security-relevant facts about Layer 4 are that it introduces state (and therefore state-exhaustion attacks), that it introduces ports (and therefore reconnaissance), that it is the layer at which firewalls can do their most useful work, and that it is the layer at which encryption begins to matter for the headers themselves and not just the payload.

The design-relevant facts for a 100-person business are that defaults dominate at this scale, that a stateful default-deny firewall is non-negotiable, that NAT is not security, that load balancers should match the layer of the protocol they are balancing, that WireGuard is the right VPN until something forces you elsewhere, and that flow data is the observability that earns its keep.

The next chapter ascends from transport to the application layer, where the morphisms become protocol-specific and the security concerns shift from connections to content.
