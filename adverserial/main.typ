==  Adversary Awareness

*Goal:* enough understanding of offensive methodology, malware behaviour, and defensive consumption to make architectural decisions that deny adversaries and expose the right detection surfaces. Not to operate the function.

=== Offensive methodology (awareness)
- What a pentest is, what a pentest report looks like
- Authorisation, scoping, rules of engagement
- MITRE ATT&CK as a shared vocabulary for adversary behaviour
- Asset discovery as defender visibility

=== What adversaries do, mapped to architectural answers
- Reconnaissance → reduce attack surface
- Exploitation → minimise TCB, default deny
- C2 and lateral movement → egress control, segmentation
- Persistence → host attestation, immutability
- Exfiltration → data classification and egress boundaries

=== Malware behaviour (awareness)
- What malware needs: persistence, privilege, C2, exfiltration
- Packers, crypters, obfuscation, that they exist and why
- Sandboxes exist (CAPE, Cuckoo), categorical knowledge only
- ML detection: approach, not pipeline, briefly cover dataset, features, evaluation
- Android case study at architectural level: APK structure, permission model, feature engineering

=== Detection surfaces consumed from the observability pipeline
- SIEM categories: Elastic, Wazuh, Security Onion, consumers of the D7 pipeline
- Network detection: Suricata, Zeek, require tap or span placement (a D2 design input)
- Host detection: Wazuh, osquery, Falco, require agent deployment (a D4 design input)
- Honeynets as zero-trust telemetry, intentional-exposure design pattern

=== Incident response architecture
- SANS PICERL as the lifecycle the architecture must accommodate
- Evidence preservation as an architectural property, what's captured, where, immutably
- Runbooks consume the same telemetry operations consumes

=== Tooling anchors (source obligations)
- Huntsman: what it does and what its existence tells an architect
- nmap, masscan: what they find and what that tells an architect

*Architectural question a graduate answers:* *what would a pentester find, what does malware need to succeed, what detection surfaces has the architecture exposed, and what architectural decisions make all three harder?*


== Adversary Awareness

*Goal:* enough understanding of offensive methodology, malware
behaviour, and defender consumption to make architectural decisions
that deny adversaries the conditions they need and expose the
detection surfaces that catch them when denial fails. Not to operate
the offensive function, not to author intelligence, not to run a SOC.
The architect's task is to know the shape of the adversary well enough
to design a system whose default behaviour resists, instruments, and
contains intrusion.

The defining insight of this chapter is that adversaries do not act
randomly. An intrusion is a sequence of dependent steps, each of which
must succeed for the next to be possible, and the architecture's job
is to make as many of those steps as possible either impossible to
complete, expensive to attempt, or impossible to complete silently.
That sequence has a name borrowed from military doctrine, and the
borrowing is not metaphor. The structural logic of a targeting cycle
in armed conflict and the structural logic of a network intrusion are
the same logic, and recognising that fact is the orientation the
architect needs before any of the technical material below makes
sense.

=== The military origin of the kill chain

Long before anyone applied the term to networks, "kill chain" was a
phrase from the precision-targeting doctrine of late-twentieth-century
air forces. The United States Air Force formalised the modern version
as *F2T2EA*: Find, Fix, Track, Target, Engage, Assess. The doctrine
was developed to address a specific operational problem of the 1990s,
the move from prepared deliberate strikes against fixed installations
to dynamic targeting of mobile, time-sensitive objectives such as
mobile missile launchers, vehicle convoys, or individuals on the move.
A target of that kind cannot be hit by simply executing a pre-built
mission plan. It must be *found* in a wide search area, *fixed* to
a specific location, *tracked* so that its location is current at
the moment of engagement, *targeted* with a weapon system whose
effects match the target type, *engaged*, and then *assessed* to
determine whether the engagement achieved its objective and whether
re-attack is required. Each step depends on the one before. Failure or
delay at any step propagates forward, and beyond a certain delay
budget the target is lost: the mobile launcher has moved, the convoy
has dispersed, the individual is no longer at the location.

F2T2EA itself sits inside a longer tradition. John Boyd's *OODA
loop*, Observe, Orient, Decide, Act, articulated in the 1970s and
1980s for fighter combat and then generalised, makes the same
structural argument at a higher level: combat is a contest between two
loops of perception and action, and the side that completes its loop
faster while disrupting the opponent's loop wins. F3EAD, Find, Fix,
Finish, Exploit, Analyse, Disseminate, used in special-operations
targeting from the early 2000s, made the same point with different
emphasis: the engagement is not the end of the cycle, the
*exploitation* of what is recovered from the engagement, and the
*dissemination* of intelligence derived from that exploitation,
feeds the next cycle's Find. All of these doctrines share two
properties. First, they are sequences in which each step depends on
the previous one, so that breaking any step breaks the sequence.
Second, they are sequences executed under adversarial conditions, in
which the opposing side is also acting and is also a target of
disruption.

The phrase "kill chain" captures both properties at once. *Chain*
because the steps are linked and ordered, and a chain is no stronger
than its weakest link. *Kill* because the chain's purpose is the
delivery of effects against an adversary who is trying to avoid them.
The defender's strategic problem in this framework is not to perfect
any single capability but to break the opponent's chain at any
available link. A radar system that prevents Find never gives the
opposing kill chain anywhere to begin. A jammer that prevents Fix
makes Track impossible. A camouflage scheme that breaks Track wastes
the targeting effort that has already been invested. A hardened
shelter that defeats Engage forces the entire chain to be re-run for
no return. Any of these, applied to any link, breaks the cycle.

This is the orientation Eric Hutchins, Michael Cloppert, and Rohan
Amin imported into network defence in their 2010 paper for Lockheed
Martin, *Intelligence-Driven Computer Network Defense Informed by
Analysis of Adversary Campaigns and Intrusion Kill Chains*.[^11]
Their argument, briefly, is that an intrusion is not an event but a
campaign, and that a campaign has the same chain structure as a
targeting cycle. If the intrusion is a chain, the defender does not
need to detect every individual indicator; the defender needs to
detect, deny, disrupt, degrade, or deceive at any one link to break
the entire intrusion. The shift in framing matters because it changes
what counts as a defensive success. Under the older event-based view,
a defence that catches an intrusion at the actions-on-objectives stage
is a success and a defence that misses earlier indicators is a
failure. Under the kill-chain view, a defence that detects unusual
reconnaissance and prevents the campaign from ever reaching delivery
is the more valuable success, because it required less to achieve and
because the same indicator pattern, recognised once, can be used to
preempt every future campaign that begins with it. *Intelligence-driven*
defence, in their phrase, means defence whose investments are guided
by the structure of the campaigns being defended against, not by the
shape of whatever vendor product happens to be in the market.

=== The intrusion kill chain

The Lockheed model decomposes an intrusion into seven phases. They are
not arbitrary; each is a stage at which the adversary must succeed
before the next stage becomes meaningful. They are presented here in
order, with the architectural question each phase raises and the
detection surface each phase exposes.

==== Reconnaissance

The first phase is the adversary's collection of information about the
target. At a minimum this includes identification of public-facing
systems and personnel, which is performed without ever sending a
packet to the target by querying public DNS, certificate transparency
logs, search engines, social networks, code-hosting platforms,
breach-data corpora, and the open business filings of the
organisation. Active reconnaissance, when the adversary chooses to do
it, includes port scanning of the public address space, banner
grabbing of services that respond, and probing of public web
applications for fingerprintable behaviour. Reconnaissance also
includes the human dimension: building a list of employees from
LinkedIn, identifying executives whose impersonation would be
plausible, and mapping reporting relationships from public
announcements.

The architectural question reconnaissance raises is *what does the
organisation expose, intentionally or otherwise, to the public, and
what does that exposure tell an adversary?* The architecture-first
answer is to reduce attack surface by default. Services that do not
require public reachability should not be on public addresses; they
should be reached over an authenticated overlay (the mesh VPN of the
networking chapters, or an identity-aware proxy of the identity
chapter). The DNS namespace should publish only what the organisation
is willing to be reconnoitred about. The mail infrastructure should
publish SPF, DKIM, and DMARC such that an attacker's
spoofing-from-domain options are constrained, not because the
attacker cannot send spoofed mail anyway but because the organisation
has reduced what reconnaissance returns. Asset discovery, which is the
defender's mirror of reconnaissance, must be at least as good as the
adversary's. The organisation that does not know what it exposes is
strictly worse off than the adversary who has spent a weekend with
nmap and Shodan.

The detection surface at this phase is largely external and largely
weak. Public reconnaissance is invisible by definition; passive
collection from third-party sources leaves no trace on the target's
network. Active scanning of the public address space is detectable in
edge logs but is so common as background internet noise that
distinguishing targeted reconnaissance from baseline scanning requires
patience and infrastructure. The architecture's contribution at this
phase is therefore not detection but reduction.

==== Weaponisation

The second phase happens entirely on the adversary's infrastructure.
The adversary takes what reconnaissance has produced and constructs
the artefact that will be delivered to the target: a malicious
document that bundles an exploit with a decoy payload, a phishing
landing page that mimics the target's identity provider, a backdoored
package, a tampered firmware update. The defender does not see this
phase happen. The artefact is, however, the durable trace the
adversary leaves of their tooling, and intelligence about that
artefact, hash, structure, embedded URLs, code-signing identities,
shared infrastructure, becomes the indicator material that lets later
phases be detected.

The architectural question at this phase is *what artefact patterns
must the architecture be prepared to recognise, and what
infrastructure does it consume to do so?* The answer is that
weaponisation creates the indicators of compromise (IOCs) that
detection engineering will later match against. The architecture's
relationship to weaponisation is therefore mediated through the
intelligence pipeline: feeds of hashes, URLs, IP addresses, TLS
certificate fingerprints, and YARA rules that the architecture's
detection layer must be able to ingest and act on. An architecture
that has no place for these inputs is an architecture that cannot use
intelligence about adversary tooling, and is reduced to detecting only
the behaviours that tooling produces in later phases.

==== Delivery

The third phase is the moment the adversary touches the target.
Delivery is the act of placing the weaponised artefact in front of a
target user or system: an email with a malicious attachment or link, a
watering-hole page on a website the target visits, a USB drive in a
parking lot, a compromised dependency added to a package the target
will install, a network exploit fired at a public-facing service.
Delivery is the first phase that produces telemetry on the defender's
network and is therefore the first phase at which detection becomes
realistic.

The architectural question at this phase is *what delivery channels
exist and what controls each of them?* Email is the dominant delivery
channel for almost every intrusion that does not begin with a network
exploit, and the architectural answer at the email layer is to deny
default delivery: SPF, DKIM, and DMARC enforcement on inbound mail;
attachment policy that strips or detonates dangerous types; URL
rewriting and time-of-click validation; restriction of macro-bearing
documents to a content type that produces a friction prompt the user
must overcome. The web channel is constrained at the egress proxy and
DNS layer, where unfamiliar destinations and known-bad infrastructure
are blocked before the user's browser ever connects. The supply-chain
channel is constrained by attestation: the only artefacts the
organisation installs are those whose provenance has been verified,
and the build pipeline that produces internal artefacts has its own
attestation chain. The physical channel, USB and similar, is
constrained by host policy: removable media require explicit
authorisation to mount, and the workstation refuses to autorun
anything from them.

The detection surface at delivery is the email gateway, the egress
proxy, the DNS resolver, and the endpoint at the moment a removable
device is attached. All four are pipeline stages the architecture must
have decided exist before delivery happens. They cannot be bolted on
after the intrusion is under way.

==== Exploitation

The fourth phase is the conversion of delivery into execution. The
weaponised artefact, once delivered, runs against a vulnerability in
the target system: a memory-corruption flaw in a document parser, a
cross-site scripting flaw in an internal web application, a
deserialisation flaw in a service that accepts user-supplied data, a
human flaw in which the user is induced to enter a credential into a
phishing page or to authorise a malicious OAuth grant. The boundary
between delivery and exploitation is sometimes thin, in a
single-click drive-by-download the two phases happen in a single
network exchange, but the conceptual distinction is real. Delivery
puts the artefact in the right place; exploitation makes it run.

The architectural question at this phase is *what is the trusted
computing base of the targeted system, and how small is it?* A
Saltzer-Schroeder principle reasserts itself here: the components
whose compromise compromises everything must be as few and as audited
as possible. An exploitable flaw in a complex office suite is
catastrophic if the office suite runs with the user's full authority,
and an inconvenience if the suite runs in a sandbox that confines its
filesystem and network access. The architectural responses to
exploitation are therefore the host-hardening and least-privilege
disciplines of the host and endpoint chapter: kernel surface
reduction, mandatory access control with deny-by-default policy,
unprivileged-by-default execution, application sandboxes for the
small set of programs that handle untrusted input, declarative system
definition such that drift from a known-good state is structurally
impossible. The architecture cannot prevent a vulnerability from
existing. It can prevent the vulnerability's exploitation from
yielding more authority than the application itself was granted.

Detection at this phase is host-side. Endpoint detection systems
(osquery, Wazuh, Falco at runtime, auditd at the kernel boundary)
observe the syscall and process behaviour of running software, and a
process exhibiting the behaviour of a freshly exploited target,
spawning a shell, writing to a directory it has no business writing
to, attempting outbound connections it has never made, presents a
detection surface that did not exist before exploitation.

==== Installation

Successful exploitation produces a brief moment of code execution.
That moment is, by itself, of limited value to the adversary. A
process that disappears when the user closes the document or reboots
the machine is a process that has not yet established itself. The
fifth phase is *installation*, the establishment of persistent
presence: a service that restarts on boot, a scheduled task, a
modified login script, a backdoored binary on disk, a malicious
browser extension, a credential harvested from memory and stored for
later use, a sideloaded daemon registered with the system's
service manager. Installation is the phase that converts a
transient compromise into a durable one.

The architectural question at this phase is *what does the host
admit as a legitimate change to its persistent state, and what does
it admit only with explicit and audited authority?* A host whose
filesystem is mostly read-only, whose service definitions are derived
from a declarative configuration repository, whose binaries are
verified at boot via measured boot and unified kernel images, and
whose persistent state is confined to a small, enumerated, and audited
set of locations is a host that makes installation difficult and loud.
The relevant disciplines, again, live in the host and endpoint
chapter: NixOS or equivalent declarative systems, signed and reproducible
binaries, TPM-bound disk encryption with attestation of boot state,
file-integrity monitoring on the small set of paths that should never
change. The opposite, an imperatively configured host that has accumulated
years of ad-hoc changes, is a host on which installation is essentially
indistinguishable from administration.

The detection surface at installation is again host-side, and is the
single richest detection surface in the chain. Persistence mechanisms
on every operating system are well enumerated, and the population of
legitimate changes on a properly architected host is small enough that
the unauthorised additions stand out. Auditd rules covering the
canonical persistence locations, file-integrity monitoring on system
binaries, periodic enumeration of services and scheduled tasks via
osquery, and host-side rules in Wazuh covering the platform-specific
persistence techniques produce a detection surface that catches
installation reliably, *provided* the architecture has put the
agents in place. An architecture that did not include host telemetry
in its design has no detection surface at installation.

==== Command and control

The sixth phase is the establishment of a channel between the
installed implant and the adversary's infrastructure. Without command
and control (C2), the implant has no means of receiving instructions,
no way to deliver the data it collects, and no way for the operator to
react to changes on the target network. Almost every modern intrusion
beyond opportunistic ransomware involves a C2 channel of some kind.
The channel is rarely overt; the adversary's defaults run over HTTPS
to a benign-looking domain, over DNS to a recursive resolver, or over
a legitimate cloud service that the target has no reason to block.

The architectural question at this phase is *what is the egress
posture, and is it default-deny by destination, by protocol, or by
neither?* This is the single highest-leverage architectural decision
in the entire chain. An organisation whose egress is default-permit,
in which any host can initiate any connection to any internet
destination on any port, has provided the adversary with a free C2
channel; the only constraint on the channel is the adversary's choice.
An organisation whose egress is default-deny, in which only an
enumerated list of destinations and protocols is permitted from each
network zone, has constrained the adversary to operate within
channels the organisation has explicitly approved, and has produced
detection surface every time the implant attempts a destination
outside that list. The architecture-first answer at the C2 phase is
egress control, and egress control is realised at multiple layers:
firewall policy on outbound flows, identity-aware proxy enforcement
for HTTP and HTTPS, DNS filtering against known-bad and newly
registered domains, inspection of TLS metadata such as JA3
fingerprints and certificate properties without breaking
cryptographic guarantees of layer above.

Network detection enters at this phase and is consumed from the
observability pipeline of the previous chapter. Suricata for
signature matching, Zeek for protocol-aware metadata extraction,
NetFlow or IPFIX for connection summaries; all require *tap or span
placement* at points the architecture chose at design time. Network
detection that is bolted on after the fact catches some traffic some
of the time. Network detection that was a design input from the
beginning catches the traffic the architecture intended it to catch.

Beaconing patterns, periodic short connections to a low-volume
destination, are a behaviour that distinguishes C2 from human-driven
traffic and that an instrumented network can recognise. Domain
generation algorithms (DGAs) produce DNS queries with statistical
properties unlike legitimate queries and are a detection surface at
the resolver. The architecture that captured DNS queries in the
observability pipeline can run those analyses; the architecture that
did not, cannot.

==== Actions on objectives

The seventh phase is what the adversary actually came to do.
Depending on the campaign, this is data exfiltration, data
destruction, encryption for ransom, lateral movement to a downstream
target, manipulation of a business process, or persistent staging for
a future operation. The phase is named in the singular but is in
practice the part of the intrusion that contains the most variety,
because objectives differ across adversaries.

The architectural question at this phase is *what constrains the
authority an adversary in the network can wield, and what
boundary does data have to cross to leave?* The answer is layered.
Lateral movement is constrained by segmentation, the discipline of
the networking chapters: a host on the user network cannot directly
reach a database on the production network, even from a compromised
foothold, because there is no path through the architecture for that
flow. Privilege escalation is constrained by the identity discipline:
short-lived, scoped credentials issued by the identity provider make
"steal a credential and use it for six months" a category of attack
the architecture does not admit. Data exfiltration is constrained by
the data classification and egress boundary discipline: data that has
been classified as sensitive lives in stores whose egress goes
through inspection points, and the architecture knows which stores
those are because classification was a design input. Destruction and
ransomware are constrained by the resilience discipline: immutable,
tested, off-line backups make the destruction reversible, which
removes most of the leverage the adversary has.

The detection surface at this phase is wide, because the adversary at
this point is generating volume, large data transfers, unusual
authentications, mass file modifications, and anomalous database
queries. The same observability pipeline that has been instrumenting
earlier phases produces the signal here. The constraint is that the
volume is now very high and the time pressure to act is acute, which
makes the architectural quality of alerting decisions, who is paged,
on what threshold, with what runbook in front of them, the binding
constraint on whether the detection translates into a response that
matters.

=== The defender's logic of the chain

The chain's value to the defender does not come from any one of its
phases in isolation. It comes from the combination of two facts. The
first is that the adversary must traverse all seven phases for the
intrusion to succeed, and a failure at any phase ends the campaign.
The second is that the cost to the adversary of progressing through
the chain is monotonically increasing: reconnaissance is cheap and
abundantly available, weaponisation requires more investment, delivery
exposes infrastructure, exploitation requires a working capability,
installation produces durable evidence, C2 reveals patterns, and
actions on objectives are the moment the adversary commits to a
particular outcome.

The defender's strategic decision is therefore where on the chain to
spend defensive effort. Hutchins and colleagues encoded this as a
*course-of-action matrix*: for each phase of the chain, the defender
chooses among a small set of action verbs, *detect, deny, disrupt,
degrade, deceive, destroy*. *Detect* is the production of an alert
that a phase has occurred. *Deny* is the prevention of a phase from
occurring at all. *Disrupt* is the partial interference with a phase
in progress. *Degrade* is the reduction of the adversary's
effectiveness within a phase. *Deceive* is the provision of false
information that the adversary acts on. *Destroy* is the elimination
of a capability the adversary requires (and is, in most legal
frameworks, an option only available to nation-state defenders).
Different organisations will populate the matrix differently. The
architect's responsibility is to ensure that, for the architecture
being designed, the matrix is *populated*: that for every phase
there is some answer, and that the architecture has placed the
mechanism that realises that answer.

The matrix has a second use. It exposes where the architecture is
weak. A column with no entries means a phase the organisation does
nothing about, and a phase the organisation does nothing about is a
phase the adversary will choose to operate within. Most organisations,
at the time the kill chain was published, had heavy investment in
detect-at-actions-on-objectives and deny-at-delivery, both relatively
late phases, and almost no investment at reconnaissance or
weaponisation, where the marginal cost of action is small and the
value is highest because every campaign that is broken before delivery
spares the rest of the chain entirely. The kill chain's contribution
to the field, beyond the model itself, is the discipline of asking
this question phase by phase rather than aggregating defensive
posture into a single number.

=== Limits of the model and what it does not cover

The kill chain was developed against a specific class of intrusion: an
external adversary delivering an artefact that exploits a target,
installs persistence, communicates back, and acts on objectives. It
captures that class well. It captures other classes badly or not at
all, and an architect who treats the chain as a complete model of
adversary behaviour will build defences that have predictable blind
spots.

The chain is *linear*. It assumes the seven phases occur in order
and once. Real campaigns iterate: an installation may fail and be
retried, a foothold in one host may be used to perform reconnaissance
of the internal network, leading to delivery into a second host
whose exploitation begins the chain again at a new starting point. The
chain models the macro-structure but flattens the micro-structure.

The chain assumes a *perimeter*, or at least an outside-to-inside
direction. A campaign that begins with an insider, a recently
departed employee, a contractor with legitimate access, a supplier
with a routine integration, has no reconnaissance phase the
defender can observe, no delivery phase the defender's email or
egress controls touch, and no clear exploitation phase. The
adversary already has authority. The chain model has very little to
say about this case. The architectural responses to the insider case
are derived from least-privilege and segmentation rather than
chain-breaking.

The chain treats *the artefact as a thing the adversary brings*.
Supply-chain intrusions of the SolarWinds variety, in which the
adversary inserts the artefact into a build the target legitimately
acquires from a trusted vendor, do not fit neatly: from the target's
perspective there is no delivery and no exploitation in the
classical sense, and yet the campaign succeeds. The adversary has
weaponised the supply chain itself. The architectural response is
attestation and provenance, treated in the application security and
host chapters, and the kill chain's framing is at best a
re-interpretation of those events into phases rather than a
prescription for them.

The chain is *adversary-centric* and offers little vocabulary for
adversary attribution or capability characterisation. It says
"reconnaissance happened" without saying who, with what tools,
sharing what infrastructure with what other campaigns. The *Diamond
Model of Intrusion Analysis*, published by Caltagirone, Pendergast,
and Betz a year after Hutchins, fills this gap with a different
abstraction: every intrusion event is a vertex of a diamond whose
corners are adversary, capability, infrastructure, and victim, and
analysis proceeds by pivoting from a known corner to discover others.
The Diamond Model and the kill chain are complementary, not competing:
the kill chain organises events along the campaign timeline, and the
diamond organises features within an event for clustering and
attribution.

The chain is *coarse-grained* in what it calls a "phase" and gives
no vocabulary for the techniques an adversary uses within a phase.
*MITRE ATT&CK*, formalised by Strom and colleagues, fills this gap
with a taxonomy of tactics, the why of an action, mapped to
techniques, the how, with concrete examples. Where the kill chain
has "exploitation" as a single phase, ATT&CK has the *Initial
Access* tactic with techniques such as Phishing, Drive-by
Compromise, Exploit Public-Facing Application, and so on, each with
sub-techniques and observed adversary use. ATT&CK is the *shared
vocabulary* the architect uses when talking about what specific
behaviours the architecture defends against; the kill chain is the
*campaign skeleton* the architect uses to ensure defensive
investment is balanced across phases. Both are useful; neither is a
substitute for the other.

The chain has also been *commercially overused*. Vendor marketing
that maps every product to "kill-chain coverage" produces matrices
that are reassuring on slides and uninformative in practice; a tool
that claims coverage at six of seven phases may have negligible
detection capability at any of them, and a tool that has a single
phase of genuine, well-instrumented coverage is more valuable than
one whose coverage matrix is broad and shallow. The architect's
response is to read the matrix critically: at each claimed phase, ask
what the tool actually detects, what it does with that detection,
and what the architectural prerequisites of its operation are.

=== What the kill chain demands of an architecture

The chapter to this point has used the kill chain as the spine of the
adversary's behaviour. The architecture-first reading of the chain is
that each phase has an architectural answer that must be present
*before* the chain begins, because none of the answers can be
retrofitted under intrusion. The reading is summarised here in the
language of the rest of the course.

Reconnaissance is answered by *attack surface reduction*: the only
services on the public address space are the ones whose business
function requires public reachability, and the rest live behind the
mesh VPN or the identity-aware proxy. The DNS, mail, and web
properties publish what the organisation has chosen to publish, and
nothing more. Asset discovery, run by the defender, is at least as
good as the adversary's.

Weaponisation is answered by *the intelligence pipeline*: the
architecture has a place to ingest indicators from external feeds,
internal incident response, and partner sharing, and a path from those
indicators to the detection layer that consumes them. Without the
pipeline, intelligence about adversary tooling is information without
a destination.

Delivery is answered by *channel-by-channel default-deny*: email
attachment and link policy enforced at the gateway; egress proxy and
DNS filtering at the perimeter; supply-chain attestation in the
build and install paths; removable-media control at the host. Each
channel is named, each channel has an owner in the architecture, and
each channel has a default policy that is restrictive.

Exploitation is answered by *trusted computing base minimisation*:
host hardening, mandatory access control, application sandboxing,
declarative system definition, least privilege at process and user
level. The architecture cannot prevent a vulnerability from existing,
but it controls the authority a vulnerability's exploitation can
yield.

Installation is answered by *host immutability and attestation*:
declarative configuration, signed binaries, measured boot, TPM-bound
keys, file integrity monitoring on a small enumerated set of paths,
and host telemetry feeding the SIEM. The architecture decides what
counts as legitimate persistent state, and everything else is, by
design, observable as deviation.

Command and control is answered by *default-deny egress*: outbound
traffic is enumerated, not assumed; the egress proxy, DNS filter, and
firewall enforce destination policy at the appropriate layers; tap
or span placement gives the network detection layer something to
read; the SIEM correlates the resulting signal with host telemetry.

Actions on objectives are answered by *segmentation, identity, data
classification, and resilience*: lateral movement is bounded by
network and identity boundaries, exfiltration crosses egress points
that classify and inspect, destruction is reversible because backups
are immutable, off-line, and tested.

=== Architectural question a graduate answers

*Given an intrusion that proceeds through reconnaissance,
weaponisation, delivery, exploitation, installation, command and
control, and actions on objectives, at which phases does the
architecture present a deny mechanism, at which phases does it
present a detection surface, where in the design were those
mechanisms decided, and what evidence does the architecture preserve
when, despite all of that, an intrusion runs its full length and
must be reconstructed after the fact?*

The remaining sections of this chapter, malware behaviour, detection
surfaces consumed from the observability pipeline, incident response
architecture, and the offensive-tooling anchors, are extensions of the
above. The kill chain is the spine on which they hang.

[^11]: Hutchins, E.M., Cloppert, M.J., Amin, R.M., 2010.
    *Intelligence-Driven Computer Network Defense Informed by Analysis
    of Adversary Campaigns and Intrusion Kill Chains.* Lockheed
    Martin Corporation. (Reference 11 in the main bibliography.)

#pagebreak()

