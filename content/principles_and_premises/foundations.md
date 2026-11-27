# Foundations

## Goals

The goal of security is to enable the organisation to meet its mission and business objectives while exercising due care over the risks to itself, its partners and its customers.[^nist800-33] A more operational formulation is Howard's: reduce the probability of material impact from a cyber event over a three-year horizon.[^howard2023] Neither formulation is a first principle. Both are goals derived from a more general human interest in prosperity, safety and the ability to pursue one's purposes.

| **Property** | **Source** |
| --- | --- |
| Confidentiality | CIA / Parkerian Hexad / DoD / X.800 |
| Integrity | CIA / Parkerian Hexad / DoD / X.800 |
| Availability | CIA / Parkerian Hexad / DoD |
| Control or possession | Parkerian Hexad |
| Authenticity | Parkerian Hexad / DoD |
| Utility | Parkerian Hexad |
| Authentication | X.800 |
| Access control | X.800 |
| Non-repudiation | DoD / X.800 |

New Zealand's cyber security strategy expresses the same end in national terms: “New Zealanders embrace cyber security to enable innovation, drive a prosperous economy and protect our digital way of life.”[^nzstrategy]

## The first principle

If a first principle is a proposition not derived from another, “reduce material impact” is not it. A business could eliminate cyber risk by doing nothing and making no profit. Security is instrumental: it serves the broader human goals of happiness, prosperity and the ability to build and operate useful institutions. The operational question for an architect is therefore not “how do we avoid all risk?” but “how do we build systems that let the organisation flourish while making serious harm unlikely and contained?”

This is not the same as business alignment. Business alignment measures how closely departments pursue existing corporate goals. The first principle is the goal itself, from which both business objectives and security requirements derive.

## Guiding principles

The course does not invent a new framework. It treats the following as primitives and applies them consistently rather than selectively.

- **Fail-safe defaults.** The absence of explicit permission is denial.
- **Complete mediation.** Every access is checked against authority every time; no cached approval bypasses the check.
- **Economy of mechanism.** Protection systems are small enough to be audited; complexity is the attacker's ally.
- **Open design.** Security rests on secret keys, not secret mechanisms. A design that collapses when published is already broken.
- **Separation of privilege.** Sensitive operations require more than one independent condition.
- **Least privilege.** A component receives only the authority it needs, for no longer than it needs it.
- **Least common mechanism.** Components do not share more state or authority than necessary.
- **Minimise the trusted computing base.** Most of the system should be able to be wrong without being fatal.
- **Assume breach.** Any layer may already be compromised; prevention alone is not a plan.
- **Separate policy from mechanism.** What is allowed is described independently of how it is enforced.
- **Explicit trust boundaries.** Every component names what it trusts and why. Unstated trust will be violated.
- **Blast-radius containment.** Authority is scoped, time-bound and isolated; destructive operations are reversible or require additional authority.
- **Least functionality.** A system contains only the programs, services and capabilities its function requires.

Zero trust is the consistent application of these principles to every component. It is not a product category or a separate framework. Where conventional architectures apply the principles at the perimeter and to selected users or services, zero trust applies them everywhere, which is why soft interior boundaries are not acceptable.[^saltzer] [^kindervag]

## Classical strategies and doctrines

Howard places strategies between first principles and concrete mechanisms. The classical examples are old: redundancy, defence in depth, cyber hygiene, fortification, choke points and the Fabian strategy of delaying stronger opponents rather than meeting them directly.[^howard2023] They remain useful as high-level rules, but they are not themselves first principles.

The following table is the minimal spanning set used in this course. Each row is broad enough that specific tactics can be derived from it, and independent enough that it cannot be reduced to another row.

| **Doctrine** | **What it means** | **Typical mechanisms** |
| --- | --- | --- |
| Defence in depth | Layer defences so one failure is not fatal, while ensuring each layer justifies its own attack surface. | Segmentation, isolation, least privilege, host controls |
| Least privilege | Grant only the authority required for the task. | RBAC, ABAC, MAC, capability systems, scoped credentials |
| Segmentation and isolation | Partition systems, networks and workloads to contain failure or breach. | Network zones, VXLAN, containers, sandboxing |
| Redundancy and resilience | Design for failure and recovery as normal operating conditions. | Backups, replication, failover, restore testing |
| Continuous monitoring | Observe state and change so that deviation is detected and attributable. | Logging, metrics, audit trails, detection engineering |
| Secure defaults and hardening | Make the safe state the state that requires no special discipline to maintain. | Least functionality, declarative configuration, patch pipelines |
| Privacy and operational security by design | Minimise what is collected, retained and exposed. | Data minimisation, encryption, access review, OPSEC |

The course treats defence in depth as a *consequence* of independent boundaries, not as a reason to accumulate products. A layer that adds more trust relationships and attack surface than it removes has failed the principle. That is why this book prefers simple primitives composed carefully over tool-heavy “security stacks”.

Mechanisms and formal models sit below strategies. The mechanisms include access control lists, capability systems, role-based, attribute-based, mandatory and discretionary access control. The models include Bell–LaPadula for confidentiality, Biba and Clark–Wilson for integrity, Brewer–Nash for conflict-of-interest separation, Graham–Denning and Take–Grant for rights propagation, lattice-based access control, information-flow analysis and noninterference. They are analytical tools; none of them is a substitute for architecture.

## Historical perspective

The history of security thought is a history of discovering that information systems create new boundaries. Willis Ware's 1970 report for the US Defense Science Board was among the first systematic accounts of the problems created when computers began to share resources.[^ware] James Anderson's 1972 study argued that security had to be designed into systems rather than added afterwards, and that monitoring was necessary because design alone could not be trusted in practice.[^anderson]

Bell and LaPadula attempted a mathematical proof that a system could be secure; they also recognised the implementation problem: even a provable design must be implemented correctly, and that cannot be assumed.[^bell] Saltzer and Schroeder's 1975 paper named many of the properties this course still uses, including fail-safe defaults, complete mediation and economy of mechanism, and described the confidentiality, integrity and availability failures that later became grouped as the CIA triad.[^saltzer]

Donn Parker argued in 1998 that confidentiality, integrity and availability were insufficient and added possession or control, authenticity and utility.[^parker] The resulting Parkerian Hexad is useful here mainly for **control**: the capacity to decide what happens to a system or its data. Control is a spectrum, and every vendor dependency trades some of it away.

From the 1990s onward, defence in depth meant a firewall plus intrusion detection and antivirus, later generalised to a “security stack” around each data island. Kindervag's 2010 zero-trust work rejected the assumption that an interior network could be trusted, and Hutchins and colleagues formalised the intrusion kill chain as a sequence of adversary phases.[^kindervag] [^hutchins] The Diamond Model and MITRE ATT&CK followed as ways of describing adversary behaviour rather than only defences.[^diamond] [^attack]

Later work on cybersecurity first principles asked what could be treated as elemental: Arbutina and Banerjee, Hale and colleagues, Sands and colleagues, Xu, and Seeley all proposed sets of foundational propositions, often derived from NSA checklists.[^seeley] Seeley's observation is the most relevant here: trust is only meaningful where risk exists, and risk arises from uncertainty. Since complete knowledge of a system is unobtainable, an architecture must make trust explicit and limit its consequences rather than pretend it can be eliminated.

## Historical distributions

Communities and boundaries move with the dominant technology. The shape of security changes with it.

| **Era** | **Dominant shape** | **Security consequence** |
| --- | --- | --- |
| Manual encryption, before 1960 | Sparse, distributed | Secrecy rests on people and procedures |
| Mainframe, 1960–1981 | Centralised | Physical and administrative control dominates |
| Personal computer, 1981–1995 | Decentralised, isolated | Endpoint compromise becomes local and immediate |
| Internet, 1995–2006 | Decentralised, interlinked | Perimeters appear; remote attack scales |
| Cloud, 2006–2020 | Centralised, interlinked | Control is outsourced; identity becomes the boundary |
| AI systems, 2020 onward | Centralised capability, distributed use | Model, data and supply-chain trust become inseparable |

Historical analogies are useful for explanation but not for evidence. Castles, frontier watchtowers and concentric fortifications illustrate separation of privilege, monitoring and layered containment; they do not establish that a modern control works. Where an analogy is used in this course, it is a teaching device, not a source of authority.

[^nist800-33]: NIST Special Publication 800-33, *Models for Information Technology Security*, 1998.
[^howard2023]: Rick Howard, *Cybersecurity First Principles: A Reboot of Strategy and Tactics*, 2023.
[^nzstrategy]: Department of Prime Minister and Cabinet, *New Zealand Cyber Security Strategy 2026–2030*.
[^saltzer]: Jerome Saltzer and Michael Schroeder, “The Protection of Information in Computer Systems,” *Proceedings of the IEEE* 63, no. 9 (1975): 1278–1308.
[^kindervag]: John Kindervag, *No More Chewy Centers: Introducing the Zero Trust Model of Information Security*, Forrester, 2010.
[^ware]: Willis H. Ware, *Security Controls for Computer Systems*, Rand Corporation, 1970.
[^anderson]: James P. Anderson, *Computer Security Technology Planning Study*, US Air Force, 1972.
[^bell]: David Bell and Leonard LaPadula, *Secure Computer Systems: Mathematical Foundations*, MITRE, 1973.
[^parker]: Donn B. Parker, *Fighting Computer Crime: A New Framework for Protecting Information*, Wiley, 1998.
[^hutchins]: Erick Hutchins et al., *Intelligence-Driven Computer Network Defense Informed by Analysis of Adversary Campaigns and Intrusion Kill Chains*, Lockheed Martin, 2010.
[^diamond]: Steven Caltagirone, Andrew Pendergast and Christopher Betz, *The Diamond Model of Intrusion Analysis*, 2013.
[^attack]: Blake Strom et al., *MITRE ATT&CK: Design and Philosophy*, MITRE, 2020.
[^seeley]: Nicholas Seeley, *Finding the Beginning to Discover the End: Power System Protection as a Means to Find the First Principles of Cybersecurity*, master's thesis, University of Idaho, 2021.
