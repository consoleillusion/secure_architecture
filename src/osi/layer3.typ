=== Layer 3 - The Network Layer

==== What Layer 3 is for

Layer 2 can move a frame between two interfaces that share a broadcast domain. That is all it can do. The moment a destination is on the other side of a router, Layer 2's addressing ceases to refer to anything useful: MAC addresses have no topology, no hierarchy, and no meaning outside the segment they were first observed on. A network that consists of more than one broadcast domain cannot be built out of Layer 2 alone, because Layer 2 has no mechanism for choosing between several possible paths when the destination is not a neighbour.

Layer 3 introduces that mechanism. It does so by creating a new data unit, the *packet*, and a new kind of address, the *IP address*, whose purpose is not to identify a piece of hardware but to identify a logical location within a larger topology. Packets are forwarded, hop by hop, by devices called *routers*, each of which makes an independent decision about which of its interfaces should carry the packet onward. The internet — every continent, every data centre, every home — exists because Layer 3 solved the problem of reaching a destination that is not directly connected.

For a business of five to a hundred people, the whole of Layer 3 exists to answer three questions. What IP addresses do we use, and how are they allocated? How does a packet get from any one of our hosts to any other of our hosts or to the internet? And when a packet arrives somewhere, how do we know it is allowed to be there? The remainder of this chapter addresses each in turn, and then the harder question of what the architecture should do about the fact that the default answers to most of them are not safe.

==== What the layer actually creates

===== The packet

Every Layer 3 technology — IPv4 and IPv6 being the only two that matter outside specialised environments — defines a packet format. A header containing source and destination IP addresses, a handful of control fields, and a payload carrying the upper-layer PDU. The packet is the *PDU Transformation* that Layer 3 contributes to the dependency chain. IP takes a Layer 4 segment and wraps it into a packet so that it can be routed across an internetwork. Without this transformation there is no packet; without a packet, the Layer 2 frame has nothing to encapsulate, and the entire chain above collapses.

This is worth stating plainly because it governs every decision downstream. Any protocol that takes a segment and produces a packet, or a packet and produces a different packet, is on the critical path. Any protocol that assists this transformation without being it — translating addresses, exchanging routes, diagnosing failures — is not on the critical path in the same way, and the distinction matters when reasoning about what an attack on a given protocol can actually accomplish.

===== The IP address

An IP address is a logical identifier. In IPv4 it is 32 bits, written as four dotted decimal octets; in IPv6 it is 128 bits, written in colon-separated hexadecimal. Unlike the MAC address, it is not tied to any specific piece of hardware; a host can change its address trivially, and a single host can hold many. Unlike the MAC address, the IP address is *hierarchical*: the left-hand portion identifies a network, and the right-hand portion identifies a host within that network. The split between the two portions is determined by a *subnet mask*, written in CIDR notation as a suffix after a slash — `/24` meaning the first 24 bits are the network and the remaining 8 are the host. This hierarchy is what makes routing tractable at internet scale: routers do not need to know about every individual host, only about the prefix that contains the host, and prefixes can be aggregated upward into larger summaries.

Hierarchy is also what makes subnetting an architectural tool rather than a bookkeeping exercise. An address plan that assigns a contiguous range to each department, site, or trust zone produces routing tables that are short and firewall rules that are legible. An address plan that assigns addresses ad hoc as each device appears produces routing tables that are long and firewall rules nobody can audit. The plan is a decision made once, early, and its consequences are felt every time something changes. 

===== The routing domain

A router does not terminate a packet; it forwards it. The unit of Layer 3 scope, inherited from the routers' collective reach, is the *routing domain*: the set of networks between which packets can be forwarded without leaving a common administrative boundary. Within a routing domain, every host can in principle reach every other host; at the boundary, the domain exchanges reachability with other domains through some explicit mechanism, most commonly a default route towards an upstream provider. 

Where Layer 2's blast radius is the broadcast domain, Layer 3's blast radius is the routing domain plus everything the routing domain chooses to reach. That choice is made by the routing table and by the firewall policy sitting in front of it. The architecture of Layer 3 is, more than anything else, the architecture of those two things.

==== IP addressing and the subnet plan

===== IPv4, and the exhaustion that shapes it

IPv4 gives 32 bits of address space, approximately 4.3 billion addresses in theory and considerably fewer in practice once reserved ranges, broadcast addresses, and historical waste are accounted for. That space has been exhausted at the registry level for more than a decade. The practical consequence is that public IPv4 addresses are a scarce resource; an organisation of a hundred people is unlikely to obtain more than one or two of them, and the internal network has to be built out of private address space.

Private IPv4 space is defined by *RFC 1918*: `10.0.0.0/8`, `172.16.0.0/12`, and `192.168.0.0/16`. These ranges are not routable on the public internet; any router on the path to the internet will drop packets addressed to or from them. They are also not unique: every private network in the world uses the same three ranges, and this non-uniqueness becomes relevant the moment two networks have to be connected — through a VPN, through a merger, through any kind of peering. Overlapping private ranges collide. The standard mitigation is to pick a less-common sub-range of the 10.0.0.0/8 space — for instance `10.47.0.0/16` — on the assumption that collisions with the same random choice elsewhere will be rare. This is pragmatic and it works, but it is worth acknowledging as the workaround it is.

===== IPv6, and what it restores

IPv6 gives 128 bits. The abundance is not the important part; the important part is that IPv6 restores *global addressability*. Every host can have a routable public address, and a firewall, rather than a NAT gateway, becomes the mechanism that decides which connections are allowed to reach it. End-to-end reachability, the property the original internet architecture assumed and IPv4 exhaustion destroyed, is recovered. This has consequences throughout the stack, some good (every connection is directly identifiable; no NAT state to manage; protocols like IPsec that assume end-to-end addressing work again), some requiring care (there is no NAT accidentally hiding misconfigured services; the firewall is now the only thing between the host and the internet, and the firewall had better be correct).

IPv6 also has private space, called *unique local addresses* (ULA),
in the range `fc00::/7`. ULA is used similarly to RFC 1918 space but the
expectation and the usual practice is that organisations use *global
unicast* IPv6 addresses internally, allocated from the provider, and
rely on the firewall for isolation rather than on non-routability. The
architectural benefit is a flat, consistent addressing model in which
the internal network and the public internet use the same address
family, and every packet's source and destination mean what they claim
to mean.

Every modern operating system speaks IPv6 natively. Most modern
consumer-grade and business-grade internet connections provide it. The
sensible default for a new deployment at this scale is *dual stack*:
run both IPv4 and IPv6 simultaneously, with IPv6 as the preferred
transport between internal hosts and services that support it. IPv4 is
retained for the inevitable compatibility cases and for reaching the
parts of the internet that have not caught up.

===== Subnetting as an architectural decision

A subnet is not just a size class; it is a *segmentation primitive*.
Each subnet is a broadcast domain at Layer 2 and a routing domain
participant at Layer 3. Traffic between subnets crosses a router, and
every router is a place where a firewall can inspect that traffic. The
architect decides how many subnets the organisation needs, and the
answer is rarely "as few as possible."

A useful convention, at this scale, is one subnet per *trust zone*
rather than one subnet per collection of devices that happen to be
nearby. Workstations in one subnet, servers in another, printers in a
third, IoT and building-automation devices in a fourth, guest Wi-Fi in a
fifth, an infrastructure subnet for the routers and switches themselves
in a sixth. Each subnet is an access control boundary that the firewall
enforces. A plan with eight or ten subnets is not over-engineered at a
hundred people; a plan with two is usually under-engineered, because it
forces every piece of firewall policy to be host-based rather than
network-based.

For IPv4, a `/24` (256 addresses, 254 usable) is the operational sweet
spot for most subnets: large enough to hold the devices that belong
there without constant renumbering, small enough to remain human-legible
and to keep the broadcast domain reasonable. For point-to-point links
between routers, a `/30` (four addresses, two usable) or `/31` (RFC 3021,
two usable as a point-to-point) is appropriate. For IPv6, the convention
is simpler and well-established: every subnet gets a `/64`, regardless
of how many hosts actually live on it. The abundance makes this
affordable, and the uniformity makes SLAAC and other IPv6 mechanisms
work correctly.

The addressing plan is a document. Write it down. Put it in version
control. A plan held in the head of the person who designed it fails
silently the first time that person is on holiday.

==== What a router actually does

A router has interfaces. Each interface is attached to a Layer 2
segment. The router holds a *routing table*, which for each
destination prefix records the next-hop address and the outgoing
interface. When a packet arrives, the router performs a *longest
prefix match* against the destination IP in the packet's header: among
all the prefixes in its table that include the destination, it selects
the most specific one. That match determines the next hop; the router
uses ARP (for IPv4) or NDP (for IPv6) to find the next-hop MAC, wraps
the packet in a new Layer 2 frame for the outgoing interface, and
forwards.

A few properties of this process matter architecturally. First, there is
the *default route*, expressed as `0.0.0.0/0` in IPv4 and `::/0` in
IPv6, which matches everything. A packet with a destination that no
other prefix covers falls through to the default route. In almost every
small-business topology, the default route points at the internet-facing
router, which in turn has a default route pointing at the ISP. Second,
route selection has a tie-breaking hierarchy when multiple sources offer
the same prefix: *administrative distance* selects which protocol's
route wins (lower is more trusted — directly connected beats static
beats OSPF beats anything else), and within a single protocol the
*metric* selects among competing paths. Third, the routing table
(RIB, routing information base) and the forwarding table (FIB, what the
kernel actually consults per-packet) are conceptually distinct, though
the distinction rarely matters outside very high-performance scenarios.

A Layer 3 device, in other words, is simply a box with multiple
interfaces, a forwarding plane that consults a table, and a control
plane that populates that table. On Linux, that describes the kernel's
built-in functionality once `net.ipv4.ip_forward` and
`net.ipv6.conf.all.forwarding` are enabled. A Linux box with two or more
network interfaces is a router. The dedicated appliance category — the
vendor router — is a Linux box with a vendor skin, or a BSD box with a
vendor skin, or increasingly a Linux box with the vendor's own merchant
silicon attached for line-rate forwarding. The architectural primitives
are the same.

==== Static routing, the right default at this scale

A static route is a routing-table entry added by configuration. The
administrator writes, explicitly, "to reach `10.47.20.0/24`, forward to
`10.47.1.2` via `eth1`," and the router stores this and forwards
accordingly. Static routing has no protocol, no packets exchanged
between routers, no convergence, no timers. It is the simplest possible
mechanism for populating a routing table.

For an organisation of five to a hundred people, static routing is
almost always the correct default. The topology is usually a single
site, with a single edge router and perhaps a Layer 3 switch behind it.
Even multi-site deployments with two or three sites connected by VPN
have a topology simple enough that static routes, one per destination
subnet per router, are readable and auditable. Dynamic routing protocols
exist to handle convergence when topologies change automatically, and
topologies at this scale do not change automatically. They change when
the architect decides to change them, which is the right time to update
the routing configuration as well.

Static routing also has the security properties the course prefers. A
static route cannot be spoofed by a malicious participant on the
network, because there is no protocol for a participant to spoof. The
table reflects the architect's decisions and nothing else. Every entry
is a line in a configuration file that can be reviewed, diffed, and
version-controlled. This is infrastructure-as-code at the routing
layer, and it is what the course holds up as the right default.

==== Dynamic routing

===== When it is needed

Dynamic routing becomes justified when the topology contains redundant
paths that must converge automatically on the survivor when a link
fails, or when the number of subnets exceeds what can be reasonably
maintained by hand. For a pair of sites with a primary MPLS link and a
backup internet-based VPN, dynamic routing can move traffic between the
two automatically. For a single-site network with a flat internal
topology, it cannot do anything static routing does not already do.

At the scale this course addresses, dynamic routing is the exception,
not the rule. An organisation that finds itself deploying OSPF between
its routers should ask, honestly, what the failure mode is that the
protocol is guarding against and whether static routing plus a
monitored failover script would accomplish the same thing with less
machinery.

===== OSPF

The open-standard interior gateway protocol is *OSPF*, Open Shortest
Path First, defined in RFC 2328 for IPv4 and RFC 5340 for IPv6. OSPF is
a *Single Layer* protocol in the course's classification: it operates
on packets, carries its own messages directly over IP as protocol number
89, and never transforms the PDU into anything else. It is a link-state
protocol: each router floods information about its own links to every
other router in its area, each router independently computes the
shortest path to every destination from the resulting map, and the
routing table is built from those paths. When a link goes down, every
router sees the change, recomputes, and converges on a new table
typically within seconds.

The architectural property that matters is that OSPF adjacencies are,
by default, *unauthenticated*. Any device on a subnet where OSPF is
running can emit OSPF hello packets, become a neighbour, and inject
routes into the domain. An attacker who injects a more-specific route
for a prefix of interest causes traffic destined for that prefix to be
forwarded to them. This is the *route injection* attack, and it
requires only the ability to send OSPF packets on a participating
interface.

The defences are two, both mandatory if OSPF is deployed at all. First,
enable *cryptographic authentication* on every OSPF adjacency —
HMAC-SHA authentication for OSPFv2, IPsec AH for OSPFv3 — so that every
OSPF packet carries a keyed hash that a legitimate neighbour can produce
and an attacker without the key cannot. Second, configure every
interface explicitly as either an OSPF interface or a *passive*
interface; the passive designation prevents OSPF packets from being sent
or accepted on interfaces that face hosts rather than other routers.
Both of these are per-interface configuration that has to be applied
consistently. It is again the pattern the course warns against —
procedural discipline compensating for an insecure default — and it is
the best that can be done within the protocol.

==== ICMP

*ICMP*, the Internet Control Message Protocol, is the diagnostic and
control companion to IP. Classified as *Single Layer* at Layer 3, it
operates on packets — its own messages are carried in IP packets with
protocol number 1 for IPv4 or 58 for IPv6 — and it never changes the
PDU type. ICMP is the layer that emits `destination unreachable` when a
router has no route, `time exceeded` when a TTL expires, `echo request`
and `echo reply` for `ping`, and (in IPv6) carries the Neighbour
Discovery messages that replace ARP.

A tempting architectural mistake is to block ICMP wholesale at the
firewall on the theory that diagnostic traffic is optional and potential
reconnaissance. It is not optional. *Path MTU Discovery* depends on
`destination unreachable, fragmentation needed` messages getting back to
the sender; when they are filtered, connections that exceed the path
MTU silently black-hole, producing the class of bug where small requests
succeed and large ones hang. IPv6 in particular cannot fragment packets
in transit, which makes PMTUD load-bearing rather than optional. The
correct approach is to permit the ICMP types that are operationally
necessary (`echo`, `destination unreachable`, `time exceeded`, `packet
too big` for IPv6, and the Neighbour Discovery types within IPv6
link-local scope), rate-limit them to prevent abuse, and deny the types
that are not useful (`redirect`, notably, which can be used to alter a
host's routing table on the local segment).

The attack surface of ICMP is small but real. `ICMP redirect` instructs
a host that a better next-hop exists for a given destination; an
attacker on the local segment can emit redirects to divert a host's
traffic through themselves. The defence is to disable acceptance of ICMP
redirects on every host — a single sysctl on Linux,
`net.ipv4.conf.all.accept_redirects=0` — and to have the firewall drop
them at the edge. `Smurf` attacks, which relied on directed broadcasts
to produce amplified floods, are largely historical; modern routers do
not forward directed broadcasts by default.

==== DHCP

*DHCP*, the Dynamic Host Configuration Protocol, is formally a Layer 7
protocol: it runs over UDP, exchanges application-layer messages, and
would be classified as *Single Layer* at Layer 7 in the course's
scheme. Its purpose, however, is to assign IP addresses, default
gateways, and DNS servers to hosts — it is an *operational* concern of
Layer 3 even though it lives architecturally above it.

The DHCP exchange follows a four-step pattern: a client broadcasts
`DISCOVER`, servers respond with `OFFER`, the client broadcasts
`REQUEST` for one of the offers, and the server confirms with `ACK`.
The entire exchange is unauthenticated. Any device on the broadcast
domain that answers faster than the legitimate DHCP server can offer
its own address as the gateway, its own address as the DNS server, or
any other value it wishes. This is the *rogue DHCP* attack, and it is
a textbook example of what Layer 2's unauthenticated trust model
enables at the boundary between Layer 2 and Layer 3.

The conventional defence is *DHCP snooping* at the switch, covered in
the Layer 2 chapter: the switch is told which ports are allowed to emit
`OFFER` and `ACK` messages, and drops them on every other port. This
works, at the cost of per-port configuration that has to be applied
consistently. The architectural observation, carrying forward from
Layer 2, is that DHCP's integrity depends on the trustworthiness of the
broadcast domain, and the broadcast domain is not trustworthy. The
mesh-VPN overlay addressed later in this chapter is the structural
answer: even if an attacker poisons the underlay addressing, the
overlay addressing is not affected, because WireGuard peers identify
each other cryptographically rather than by whatever address DHCP
happens to have handed them.

At the scale this course addresses, DHCP should run on a dedicated
service host, not on the edge router (to keep the router's
responsibilities narrow) and not scattered across multiple devices.
*Kea DHCP* is the modern open-source reference implementation,
successor to the now-EOL ISC DHCP. For very small sites — under fifty
hosts — *dnsmasq* combines a lightweight DHCP server with a local DNS
forwarder in a single daemon, which is operationally convenient and
configurable in a few lines. Whichever is chosen, infrastructure devices
(routers, switches, access points, printers, hypervisors) should have
*reservations* that bind a specific MAC to a specific IP, so that
their addresses are stable even though they are assigned dynamically.
Dynamic assignment for workstations, stable assignment for
infrastructure.

==== IPv6 at Layer 3

Several IPv6 mechanisms deserve specific attention because they differ
from IPv4 in ways that affect the architecture.

*ARP does not exist in IPv6*. It is replaced by *Neighbor Discovery
Protocol* (NDP), which is classified as *PDU Address Translation*
(IPv6 → MAC) and carried within ICMPv6. NDP performs the same job as
ARP, with the same unauthenticated default, and has the same category
of vulnerabilities; the Layer 2 chapter's analysis of ARP applies with
very little modification. The IPv6 analogue of DHCP snooping is *RA
Guard*, a switch feature that prevents rogue Router Advertisements
from being forwarded; it is the mechanism that prevents an attacker
from advertising themselves as the default gateway to every IPv6 host
on the segment.

*SLAAC*, Stateless Address Autoconfiguration, lets hosts configure
their own IPv6 addresses by combining the prefix advertised by the
router with an interface identifier derived from their MAC or generated
randomly. SLAAC eliminates the need for DHCP in many deployments, and
where more control is wanted, *DHCPv6* can coexist with or replace
SLAAC for address assignment. The architectural choice at this scale is
typically SLAAC for workstations (simple, no server required) and
DHCPv6 or static assignment for infrastructure (stable, known
addresses).

*The firewall becomes load-bearing in a way it was not under IPv4 with
NAT*. With public IPv4 addresses behind a NAT gateway, unsolicited
inbound connections from the internet simply had no way to reach a
workstation; the NAT's connection table had no matching entry. Under
IPv6 without NAT, every workstation has a globally routable address,
and the only thing preventing an inbound connection from reaching it is
the firewall's explicit decision to drop it. This is not a regression —
it is a correction, because the NAT-based protection was always
accidental — but it does mean that the firewall configuration that used
to be optional is now mandatory.

==== NAT and PAT

*NAT*, Network Address Translation, is classified as *Single Layer*
at Layer 3 with a footnote: it operates on Layer 3 packets and does not
change the PDU type, but it rewrites header fields — source and
destination IP addresses — in a way that no other Single Layer protocol
does. *PAT*, Port Address Translation, extends this by also rewriting
the Layer 4 port numbers, which is what allows a single public IPv4
address to serve many internal hosts simultaneously: each outgoing
connection is assigned a unique source port on the public side, and
inbound replies are demultiplexed back to the right internal host by
consulting the NAT state table. This is the mechanism by which every
home internet connection in the world has worked for twenty years. It
is the reason IPv4 has not collapsed under the weight of its own
exhaustion.

It is also an architectural wart that the course is eager to see
retired. NAT breaks the end-to-end property the original IP
architecture guaranteed: the source address in a packet arriving at a
server no longer identifies the host that sent it, and the address that
host sees in its own configuration is not the one the outside world
knows it by. Any protocol that embeds an IP address in its payload —
SIP, FTP's data channel, some IPsec modes, some peer-to-peer systems —
must either be rewritten by an *application-layer gateway* (ALG) in
the NAT device or it breaks. Logs must correlate public-side five-tuples
with internal-side five-tuples by consulting NAT translation records,
which have to be kept and correlated in time. Every connection adds an
entry to the NAT table; every idle connection eventually ages out; every
mismatched timeout between the NAT's idea of when a flow ended and the
endpoints' idea produces a class of bug that is tedious to diagnose.

There is a second category error worth naming directly. NAT is often
described as a *security feature*. It is not. The reason an
unsolicited inbound packet cannot reach an internal host through a NAT
gateway is not that NAT is enforcing a policy; it is that the NAT's
connection table has no entry mapping that packet to an internal
destination, so the gateway has no choice but to drop it. This
protection is a consequence of *stateful connection tracking*, not of
address translation. A stateful firewall placed in front of hosts with
public IPv6 addresses provides the same guarantee with no translation
involved. NAT and firewalling are two different functions that happen
to live in the same box on the way to the internet; confusing them
leads to IPv6 deployments in which administrators feel they must
reintroduce NAT to preserve security they never actually had from NAT
in the first place.

The course's position: run NAT at the IPv4 edge because IPv4
necessitates it, understand it as a workaround for address exhaustion,
and let it disappear as IPv6 deployment proceeds. The security
properties come from the firewall, which should be configured
identically whether it sits in front of NATted IPv4 hosts or directly
addressable IPv6 hosts.

==== IPsec

*IPsec* is classified as a *Composite, Intra-Layer* protocol: a
single named protocol that bundles multiple sub-protocols, all operating
on Layer 3 packets. The sub-protocols are *AH* (Authentication Header,
providing integrity and authenticity without encryption), *ESP*
(Encapsulating Security Payload, providing encryption and optional
authenticity), and *IKE* (Internet Key Exchange, the control-plane
protocol that negotiates parameters and establishes keys). IPsec can
operate in *transport mode* (the original IP header is preserved and
only the payload is protected, used for host-to-host) or *tunnel mode*
(the original packet is wrapped in a new outer IP header, used for
gateway-to-gateway VPNs between sites).

IPsec has been the standard way to do site-to-site encryption for a
quarter-century. Every vendor router supports it. Every operating
system has an implementation. It works. It is also famously complicated
to configure correctly: the combinatorics of IKE phases, crypto
proposals, DH groups, PFS settings, NAT traversal, and the mismatch
that occurs when two sides agree on the first six items and disagree
silently on the seventh, have produced a generation of network
engineers whose primary skill is getting IPsec tunnels to come up.

The course does not forbid IPsec, but it strongly prefers the
alternative discussed next. Where IPsec appears in a deployment at this
scale, it is usually for one specific reason: the other end is a vendor
device that only speaks IPsec, and the organisation is connecting to a
partner, a legacy site, or a cloud provider that requires it. In those
cases, document the configuration precisely, keep the key material
under the same management as every other secret, and accept the
complexity as the cost of interoperability.

==== WireGuard and the encrypted mesh VPN

*WireGuard* is what the introduction of this course calls the default
for internal traffic. It is not IPsec; in the vocabulary of the
classification, it is best understood as an *Inter-Layer Composite*:
it bundles a Layer 4 transport (UDP), a handshake protocol, a
cryptographic construction, and the tunnelling of IP packets through the
resulting session, under a single name. What arrives at a WireGuard
interface looks like an IP packet; what leaves on the wire is a UDP
datagram carrying an authenticated, encrypted ciphertext. The machinery
in between is the protocol.

WireGuard has four properties that matter architecturally.

First, *simplicity*. The implementation is under five thousand lines
of kernel code. There are no phases, no negotiations, no crypto
algorithm choices. The cryptographic primitives are fixed: Curve25519
for key exchange, ChaCha20-Poly1305 for authenticated encryption,
BLAKE2s for hashing, SipHash24 for the hash table. A configuration file
lists peers by public key, and that is substantially the entire
protocol interface. Economy of mechanism, the principle that a
protection system should be simple enough to be audited by a single
person, is satisfied here in a way it simply is not for IPsec.

Second, *peer-to-peer semantics*. WireGuard's natural topology is a
mesh: every host knows the public keys of the peers it should talk to
and can reach any of them directly through its local WireGuard
interface. There is no privileged gateway, no hub-and-spoke
concentration point, no terminator that inspects every packet. Each
host encrypts for its peer; the packet rides whatever underlay is
available to get there; the peer decrypts. This is the encrypted mesh
VPN the introduction describes.

Third, *cryptographic identity*. Each peer is identified by its
public key, not by its IP address, not by a certificate whose chain must
be validated, not by a password shared among a group. The public key is
the identity. A peer presenting a packet that does not verify against
the known public key is rejected, full stop. There is no hostname
spoofing, no certificate-authority trust chain that could be
subverted, no password phishing. Identity is a Curve25519 public key
and the fact that the corresponding private key can produce the right
handshake.

Fourth, *transparency to the underlay*. WireGuard does not care what
is underneath it. The underlying path can be the local Ethernet, the
office Wi-Fi, a hotel network, a mobile data connection, an internet
link through a hostile ISP. From the perspective of WireGuard, all of
these are a lossy UDP medium over which encrypted datagrams flow. The
consequence is that *Layer 3 at the underlay becomes narrow and
boring*. It exists to get UDP packets from here to there. It does not
carry any application trust; no application is aware of it; it cannot
be attacked in any way that compromises the data.

This is the split the introduction names. The *underlay* is the
physical and logical network that carries UDP, maintained by the
organisation's router and firewall configuration. The *overlay* is
the WireGuard mesh, maintained by peer configurations and keys. Hosts
address each other through the overlay. Routing at the underlay
concerns itself only with reachability between WireGuard endpoints,
which at this scale is usually a single fact: how does each host reach
the internet, because the mesh assumes the internet is the substrate.

The architectural consequence is substantial. An ARP spoofing attack
diverts underlay frames to the attacker; those frames carry encrypted
UDP datagrams that the attacker cannot decrypt. A rogue DHCP server
gives a victim a malicious default gateway; the victim's mesh-VPN
traffic still flows over that gateway, still as ciphertext, still
unreadable. An OSPF route injection diverts underlay packets through an
attacker's router; the attacker sees encrypted traffic. The
routing-layer attacks described in the next section do not go away;
they lose the ability to give the attacker anything the attacker can
read. Cryptography placed at the endpoints, rather than in the network,
decouples security from the correctness of the network below it. This
is the encrypted mesh VPN doing the work the introduction said it would
do.

==== Layer 3 firewalling

A firewall is a device or software component that inspects packets and
allows or denies them according to a policy. At Layer 3, the policy
most commonly matches on source and destination IP addresses, source
and destination ports (which are Layer 4 fields, but every modern
firewall reads across the layer boundary), protocol numbers, and
connection state.

*Stateless packet filtering* evaluates each packet independently. A
rule says "allow TCP from `10.47.10.0/24` to `10.47.20.5` port 443";
any packet matching that rule passes, and the firewall retains no
memory of the packet after it has been forwarded. Stateless filtering
is simple and fast but clumsy for any protocol where the direction of
the reply matters, because allowing the request requires a separate
rule allowing the reply, and that separate rule is by definition
broader than it needs to be.

*Stateful firewalls* track connections. The first packet of a
connection is evaluated against the rule set; if allowed, the
firewall records the five-tuple (source IP, source port, destination
IP, destination port, protocol) in a state table, and subsequent
packets belonging to the same connection — including the reply
direction — are allowed implicitly. Only the first packet of each
connection has to match an explicit rule. This is the standard model
for any modern firewall.

On Linux, the modern firewall is *nftables*. It replaces the older
iptables, ip6tables, arptables, and ebtables with a single consistent
framework, a single kernel implementation, and a consistent rule
syntax. Rules live in text files, which means they live in version
control, which means they are reviewable and reproducible. A nftables
configuration can be rendered from a NixOS module or applied via an
Ansible role; in either case, the firewall policy is code, and the
code is the source of truth.

Several properties of firewall architecture at this scale deserve
direct statement. *Default deny* is the rule at every trust boundary.
A firewall that defaults to allow and tries to enumerate the things to
deny is guaranteed to miss something; a firewall that defaults to deny
and requires each allowed flow to be named explicitly cannot miss
anything silently. *Egress filtering* is at least as important as
ingress filtering. A host that is not allowed to initiate arbitrary
outbound connections cannot establish command-and-control channels to
arbitrary internet destinations; a host that can is one compromise away
from exfiltration. Organisations routinely treat outbound as
trusted-by-default, and this is the single largest structural
concession to attacker convenience in most networks. *Firewalls are
not single-perimeter objects*. Every host runs a host firewall. Every
subnet boundary is a policy-enforcement point. The architecture does
not have a soft interior behind a hard perimeter; it has layered
boundaries, each enforcing policy appropriate to what crosses it. A
flat internal network with no policy between subnets is the
architecture's failure mode, not its default.

==== Routing-layer attacks and reconnaissance

A brief taxonomy of what attacks at Layer 3 actually accomplish, mapped
to the architectural responses.

*Route injection into an IGP* (OSPF being the usual target at this
scale) inserts attacker-controlled routes into the routing table,
causing traffic for the affected prefix to be forwarded to the
attacker. Defence: OSPF authentication on every adjacency, passive
interfaces on every host-facing port, strong preference for static
routing where topology permits. Residual risk: mitigated further by
the mesh VPN, which makes the diverted traffic unreadable.

*BGP hijacking* is the public-internet analogue: an autonomous system
announces prefixes it does not own, and other ASes accept the
announcement. This happens routinely on the public internet and is
mostly outside the small-business operator's direct control; the
mitigation is to monitor (RPKI validation, BGP monitoring services)
and to rely on end-to-end encryption for any data whose confidentiality
matters, since a hijack diverts the packets but does not decrypt them.

*IP spoofing* inserts packets with forged source addresses into the
network. The historical use was in reflection-amplification attacks
against third parties; the defence at the edge is *unicast reverse
path forwarding* (uRPF), which drops packets arriving on an interface
whose source address the router would not route back out of the same
interface. Enabling uRPF at the internet edge is a small configuration
change that prevents the organisation's network from being used as a
reflector in other people's attacks.

*ICMP redirect attacks* on the local segment alter a host's routing
table by sending forged redirect messages. Defence: disable redirect
acceptance on every host, drop redirects at the edge.

*Reconnaissance* through ICMP sweeps, traceroute, and OS
fingerprinting is the precursor to most targeted attacks. The
architectural response is not to block ICMP, which breaks PMTUD, but
to reduce attack surface: hosts and services that should not be
reachable from the internet should have no public IP listener at all,
reached instead through the mesh VPN overlay. A service that does not
answer from the internet cannot be fingerprinted from the internet.

*DDoS* at Layer 3 — volumetric floods of traffic targeting public
services — is largely outside the defender's direct control at this
scale; the organisation's pipe can be saturated by a determined
attacker regardless of how the internal network is configured. The
mitigation is architectural: services that require public availability
are placed behind a provider whose business is absorbing volumetric
attacks, not run from the organisation's own edge. An email server on
the organisation's own IP can be DDoSed; the organisation's inbound
email through a provider cannot be, or at least cannot be without
taking the provider down with it.

==== The architecture-first answer at Layer 3

The conventional Layer 3 toolkit — dynamic routing protocols with
authentication, careful NAT configuration, ICMP filtering, uRPF, and so
on — works when it is deployed correctly and maintained consistently.
It produces a network whose security depends on the routing being
right, the firewall rules being current, the protocols not being
exploited, and the administrator not making a mistake. Each of those is
a place where the architecture can fail silently.

The architecture-first answer assumes Layer 3 will be attacked and
arranges for those attacks not to succeed in ways that matter.

The underlay is narrow: a handful of subnets, a default route to the
internet, and whatever minimal routing is necessary to get UDP packets
from each host to the peers it needs to reach. There is no dynamic
routing where static routing will do; there is no BGP at the edge
unless there genuinely is; there is no OSPF unless topology forces it.
The surface for routing attacks is small because the routing footprint
is small.

The overlay is a WireGuard mesh. Every host has a WireGuard interface
with keys for its peers. Every internal service listens on the
WireGuard address, not on the underlay address. Every connection
between hosts flows through the mesh, authenticated cryptographically
by the peer's public key, encrypted with modern primitives. A packet
captured anywhere on the underlay — by a compromised router, by ARP
spoofing, by a rogue access point, by the ISP, by a government request
at the provider level — is ciphertext the captor cannot read.

Firewalling is layered. Every host has an nftables policy that denies
by default and allows only the specific flows the host is supposed to
participate in. Every subnet boundary has a firewall policy that denies
by default and allows only the flows permitted between those zones. The
edge router has a firewall policy that denies inbound by default,
permits the specific inbound services the organisation runs from its
own IP (if any), and permits outbound traffic on specific categories
consistent with the organisation's egress policy. Each of these
policies lives in version control. Each is reviewable. Each is
reproducible.

Publicly-facing services are rare and carefully considered. Anything
that does not need to be reachable from the internet is not reachable
from the internet — reached instead through the mesh VPN from
authenticated endpoints. A host that can only be reached through the
mesh is invisible to internet reconnaissance; it does not have a listener
on its public address for anything to find.

IPv6 is enabled wherever the provider supports it, dual-stacked with
IPv4 for compatibility. NAT is accepted at the IPv4 edge as a necessary
consequence of address exhaustion, and is understood to contribute
nothing to security that the firewall does not also provide.

The result, measured against the principles in the introduction, is an
architecture that does not rely on Layer 3 being uncompromised for the
organisation's data to be safe. The underlay can be attacked and the
organisation's traffic remains confidential. Individual hosts can be
compromised and the blast radius is bounded by the firewall policies
that sit between them and every other host. Mistakes in routing
configuration degrade availability but do not produce disclosure. The
principles — fail-safe defaults, economy of mechanism, explicit trust
boundaries, least privilege, assume breach — describe what this layer
does when you examine it, not what a policy document says it should do.

==== The open-source stack

The components that implement the architecture described above are all
open-source and all run on the Linux boxes that are already the
organisation's infrastructure substrate.

The *Linux kernel itself* is the router. IP forwarding, the routing
table, policy routing with multiple tables and fwmarks, neighbour cache,
and every primitive the forwarding plane requires are in the kernel. A
Linux host with two or more interfaces and `ip_forward=1` is a router,
and the configuration lives in `/etc/network/` or `/etc/systemd/network/`
or the declarative equivalent in NixOS. No additional software is
required for static routing.

*FRRouting* provides OSPF, BGP, IS-IS, RIP, and other dynamic routing protocols as userspace daemons that install routes into the kernel's table via Netlink. FRR is the open-source successor to Quagga, which was the open-source successor to Zebra. If dynamic routing is genuinely required at the deployment, FRR is the implementation. Its configuration resembles Cisco IOS syntactically, which is a historical artefact rather than an endorsement; the config is nonetheless text, version-controllable, and reviewable.

*nftables* is the firewall. Native IPv4 and IPv6 support in a single ruleset, native support for sets and maps that replace the iptables habit of hundreds of individual rules, and a rule syntax that expresses policy cleanly. The configuration is a text file loaded at boot. NixOS has a first-class nftables module; Ansible has well-maintained roles that manage it.

*WireGuard* is in the mainline Linux kernel since 5.6. The userspace configuration is a single `.conf` file per interface, or equivalent NetworkManager / systemd-networkd configuration, listing the local keys and the peer table. The `wg-quick` wrapper is adequate for most deployments; the lower-level `wg` command exposes every primitive if finer control is needed. On non-Linux clients, WireGuard has
first-party support on every major operating system.

*Kea DHCP* is the modern reference DHCP implementation, maintained by ISC as the successor to their own now-EOL ISC DHCP. It supports IPv4 DHCP, IPv6 DHCPv6, and a plugin architecture for leases, reservations, and dynamic DNS updates. For very small deployments, *dnsmasq* combines a basic DHCP server with a DNS forwarder in a single small daemon, which is operationally convenient when the full feature set of Kea is not needed.

*strongSwan* or *libreswan* provide IPsec, for the cases where
IPsec is genuinely required for interoperability. Both are
mature open-source implementations of the full IPsec suite.

*Wireshark, tcpdump, and tshark* read the same packet captures and
dissect every Layer 3 protocol mentioned in this chapter. Traffic
analysis at Layer 3 is not a separate toolchain from Layer 2 analysis;
it is the same toolchain looking at different headers.

Purpose-built router distributions — *OPNsense* (BSD-based),
*VyOS* (Debian-based), *pfSense* (BSD-based, with a partially-open
licensing model worth reading carefully) — are valid deployment
choices where the convenience of a packaged router with a web UI is
worth its weight. Under the hood, each of them is running the
underlying primitives named above, and a well-managed deployment of any
of them still treats the configuration as text, backs it up, and
reviews changes. What the architecture resists is not the distribution
but the pattern of single-device configurations that live only on the
device and exist nowhere else.

==== What an architect decides at Layer 3

The principles from the introduction reduce, at this layer, to a
concrete set of decisions, each of which should be made explicitly and
recorded.

*The addressing plan.* Which subnets exist, what each contains, what
the CIDR boundaries are, and how the plan accommodates growth without
renumbering. IPv4 with RFC 1918 space internally; IPv6 with
provider-assigned global unicast prefixes dual-stacked where available.
Point-to-point links as `/30` or `/31` in IPv4, `/64` everywhere in
IPv6 regardless of host count.

*The subnet-to-trust-zone mapping.* Each subnet corresponds to a
trust zone, and each trust zone has an enumerated firewall policy
governing traffic to and from every other zone. Workstations, servers,
printers, IoT, guest, infrastructure — each in their own subnet, each
with their own rules.

*The routing discipline.* Static by default. Dynamic (OSPF) only if
the topology genuinely requires automatic convergence on redundant
paths; when deployed, with cryptographic authentication on every
adjacency and passive interfaces on every host-facing port. BGP only
where the organisation peers directly with multiple upstreams, which
at this scale is rare.

*The NAT posture.* NAT at the IPv4 edge as a necessity, understood
not to contribute to security. The IPv6 path free of NAT, with the
firewall providing the containment that NAT used to provide by
accident.

*The firewall architecture.* nftables policy on every host,
default-deny, declared as code, version-controlled. Firewall policy at
every subnet boundary, default-deny, declared as code. Edge firewall
policy, default-deny inbound, default-deny outbound with explicit
allowed categories.

*The ICMP policy.* Permit the types that are operationally required
(echo, destination unreachable, time exceeded, packet too big, NDP
within link-local scope). Rate-limit. Deny redirects. Deny redirect
acceptance on every host.

*The encrypted overlay.* WireGuard mesh between all hosts, with peer configuration managed as code. Internal services listen on the overlay address, not the underlay. The underlay's job is to carry UDP between WireGuard peers; nothing else rides on its confidentiality or integrity.  *DHCP, DNS, and operational services.* Kea or dnsmasq providing address assignment, with reservations for infrastructure. DHCP snooping enabled at the switches as defence in depth. DNS configured to point at organisational resolvers that enforce the organisation's name-resolution policy. 

*Monitoring posture.* The metadata of Layer 3 traffic — source and destination prefixes, connection counts, volumes, timing — is captured and analysed. The contents are encrypted and not inspected, in keeping with the introduction's position on break-and-inspect. NetFlow or IPFIX from the edge router, firewall logs from every enforcement point, and flow records from WireGuard peers collectively provide the observable surface.

The architecture that emerges from these decisions is small. It has a flat, legible addressing plan, a narrow underlay, a cryptographicoverlay that carries the real trust, firewall policies that live as
code, and a handful of well-understood daemons implementing every required function. It treats Layer 3 as plumbing — necessary, competent, and not where the security lives. The security lives in the keys, in the firewall policies, and in the architect's decisions about what is allowed to talk to what. Layer 3 is the layer that makes the plumbing work. The introduction's principles, applied at this layer, produce exactly this: a network whose routing is correct because
it is simple, and whose data is safe because the routing is not what
keeps it safe.

#pagebreak()
