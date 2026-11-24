==  Foundations

=== Goals

https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-33.pdf
#quote(attribution: "NIST")[
Security Goal
The goal of information technology security is to:

Enable an organisation to meet all of its mission/business objectives by implementing systems with due care consideration of IT-related risks to the organisation, its partners and customers.
]
#quote(attribution: "Rick Howard, Cybersecurity First Principles")[
Reduce the probability of material impact due to a cyber event over the next three years.
]

The First Principle: Prosperity, Flourishing, Quality of Life, Success. These are attempts to describe how security contributes to that business goal:
- CIA
- Parkerian Hexad
- X.800
- Five Pillars(DoD)
- Synthesis

https://www.dpmc.govt.nz/sites/default/files/2026-02/nz-cyber-security-strategy-2026-30.pdf
Our vision
"New Zealanders embrace cyber security to enable innovation, drive a prosperous economy and protect our digital way of life."

#table(
  columns: 2,
  [*Property*], [*Source*],

  [Confidentiality], [CIA / Parkerian Hexad / DoD / X.800],
  [Integrity], [CIA / Parkerian Hexad / DoD, X.800],
  [Availability], [CIA / Parkerian Hexad / DoD],
  [Control (Possession)], [Parkerian Hexad],
  [Authenticity], [Parkerian Hexad / DoD],
  [Utility], [Parkerian Hexad],
  [Authentication], [X.800],
  [Access Control], [X.800],
  [Non-repudiation], [DoD, X.800],
)

=== Strategies
- *Architecture-first* Security is a property of the system, not a bolt-on. Security as an architectural property
    - Kerckhoffs's principle and its modern corollaries
    - Why secrecy-of-mechanism fails at scale
    - Compliance vs. security as categorically distinct concerns
- Holistic, not patchwork
- *Open source throughout.* No vendor lock-in, no unauditable binaries in the trust path.
- *Applied, not theoretical.* Every domain ends in deployable artifacts. The capstone is a working SMB stack.
- *Compliance is a byproduct.* Frameworks appear in GRC as instruments, not as the goal.
- Automated, infrastructure as code
- Secure from start to finish

- *The OSI Secure Layers classification is the spine.* Every networking unit is anchored in the five protocol types (Single Layer, PDU Transformation, PDU Address Translation, Composite Intra-Layer, Composite Inter-Layer) and their bidirectional-opacity implications for threat modelling.

=== Guiding Principles

- *Fail-safe defaults.* Absence of explicit permission is denial; the default state of any undefined access is "no."
- *Complete mediation.* Every access to every object is checked for authority every time; no cached approval bypasses the check on subsequent attempts.
- *Economy of mechanism.* The protection system is small and simple enough to be audited by a single person; complexity is the attacker's ally.
- *Open design.* Security rests on the secrecy of keys, not the secrecy of the mechanism; any design that would collapse if published is already broken.
- *Separation of privilege.* Sensitive operations require multiple independent conditions (two keys, two roles, two channels); no single failure grants full authority.
- *Minimise the trusted computing base.* Reduce the set of components that, if compromised, would compromise everything; most of the system should be in a position to be wrong without being fatal.
- *Assume breach.* Design as though the adversary is already inside; prevention is a tax, not a plan.
- *Separate policy from mechanism.* What is allowed is described independently of how it is enforced, so policy can change without rebuilding the enforcement layer and vice versa.
- *Explicit trust boundaries.* Every component names the adversary it hardens against; trust that is unstated is trust that will be violated.
- *Blast-radius containment.* Authority is scoped, time-bound, and isolated so that compromise of one component does not cascade; corollary: destructive operations must be reversible or require explicit additional authority.
- *Zero Trust*

https://thecyberwire.com/stories/4c2978fc087f48df955f19f71c7c18de/prior-research-on-cybersecurity-first-principles

=== Elements of Cybersecurity

In order to make decisions in an organisation, and to achieve an organisations goal, it needs to be clear first about what those goals are. Rick Howard discusses what a "first principle" is, and how that helps to make clearer decisions. He argues that compliance, CIA Triad, Patching etc are not a fundamental goal or a first principle. He argues instead for the idea that Cybersecurity's first principle is:

"Reduce the probability of material impact due to a cyber event over the next three years."

Does this really represent a good first principle? Here's why I don't think so:
- What if a company wanted to release a brand new technology which could make them billions of dollars, but would increase the risk of a cyber event? The principle above, if taken literally, would forbid such a move. 
- Strictly speaking, the definition of a first principle is that it is not derivable from other principles. Howard's principle however, and its apparent soundness comes from the fact that it's clearly derivable from a more general human desire for something like happiness, safety, and prosperity.

Why is this important? Because reducing the possibility of a breach does not necessarily reflect a desire for increasing prosperity. You could easily reduce the material impact on a business by doing nothing and taking no risks and making no profit. The fundamental principle here should be something like:

"The first principle of cybersecurity is to promote human happiness and prosperity, by helping to build and secure, private and profitable businesses, lives and data."

This is necessarily vague because the how to achieve these basic human goals is going to depend on the people, culture, technology of the time, and it is roughly the principle by which Howard's definition must have come about. Is it possible to derive the "first principle" I have given from something else? If I could find something, would it not be possible to ask the same question of that newer, more fundamental principle? This is the "turtles all the way down"/infinite regress principle, I propose that the point of human desire, or recognition of some psychological benefit is a helpful point to stop, at which further regress becomes too philosophical, religious or theological to be helpful to our purposes. Like Descartes, I have brought the principle back to something fundamentally psychological "I think therefore I am". I would love to hear improvements, I do not know how it would be possible to get to a more fundamental first principle without making very debatable and disagreeable religious or philosophical statements.

How do we increase these things for a business? How do we help the business, make it safer, more profitable, more valuable to consumers? Everything you have heard about cybersecurity probably contributes something, but it needs to be understood within its proper place in order to be helpful.

This new first principle is not the same as Business Alignment. The first principle is the goal of or foundation of the goals of the business. Business Alignment is how closely the various departments are working with business goals.

=== Foundations of Cybersecurity

In order to make decisions within an organisation and achieve its goals, it is essential first to clarify what those goals are. Rick Howard discusses the concept of a "first principle" and how it helps guide clearer decision-making. He argues that compliance, the CIA Triad, patching, and similar practices are *not* fundamental goals or first principles. Instead, he proposes the following as the first principle of cybersecurity:

*"Reduce the probability of material impact due to a cyber event over the next three years."*

Does this truly represent a fundamental first principle? I argue that it does not:

- If a company wanted to release a groundbreaking technology that could generate significant revenue but increase the risk of a cyber event, Howard’s principle would, if interpreted literally, discourage such innovation.
- By definition, a first principle should *not* be derivable from other principles. Howard’s principle, however, derives its apparent soundness from a more general human desire for *happiness, safety, and prosperity*.

The problem is that simply reducing the possibility of a breach does not necessarily advance prosperity. A business could minimise cyber risk entirely by avoiding risk-taking, doing nothing, and making no profit. The *more fundamental principle* should therefore be:

*"The first principle of cybersecurity is to promote human happiness and prosperity by helping build and secure private, profitable businesses, lives, and data."*

The relative importance of and relationship between prosperity, security, privacy and happiness will differ between times and cultures but the important thing is that we tie the business to this vision, whatever you decide it to be. Any attempt to derive a first principle from something more fundamental than this will most likely lead to unhelpful speculation into the philosophical or theological. By grounding the principle in *human psychological benefit*, we stop at a level that is both meaningful and practical—similar to Descartes’ *“I think, therefore I am.”*

How do we operationalise this principle for a business? How do we enhance safety, profitability, and value for customers? All standard cybersecurity practices contribute, but only when understood in the context of this broader first principle.

It is important to note that this principle is *not equivalent to business alignment*. Business alignment measures how closely departments pursue corporate goals; the first principle is *the underlying goal itself*—the foundation upon which alignment and cybersecurity strategies rest.

=== Classical Cybersecurity Strategies

With the first principle established, we can now consider a set of *strategies*. Howard's next level in his hierarchy is strategies. Actually, these are just evolutions of ancient ideas applied in military strategy, this is helpful to point out to encourage cross germination of ideas, and to make us aware that there is a long history of protecting information, infrastructure, and people.

Examples include:

- *Redundancy* – maintaining multiple systems or pathways to ensure availability.
- *Defence in Depth* – layering defences so that breaching one layer does not compromise the system.
- *Cyber Hygiene* – routine practices to maintain secure and healthy systems.

These strategies serve as high-level rules for designing and evaluating more specific operational plans, mechanisms, and models. By framing them as *strategies*, we recognise their tactical heritage while linking them to our human-centred first principle.

If you want a *minimal spanning set of cybersecurity doctrines*, think in terms of *high-level, foundational strategies* that are *broad, independent, and composable*. From these, most other doctrines or tactics can be derived or specialised. Here’s a rational minimal set of 6–7:

=== *Minimal Core Cybersecurity Doctrines*

1. *Defence in Depth*

   * Layered defences so that the compromise of one layer does not compromise the whole.
   * Basis for firewalls, IDS/IPS, segmentation, and redundancy.

2. *Least Privilege*

   * Users and processes get only the access they need.
   * Basis for RBAC, ABAC, DAC, capability systems, and microsegmentation.

3. *Segmentation / Isolation*

   * Systems, networks, and workloads are partitioned to contain failures or breaches.
   * Basis for network zoning, virtual networks, sandboxing, and containerisation.

4. *Redundancy / Resilience*

   * Backup systems, failover, replication, and incident response planning.
   * Basis for high availability, disaster recovery, and business continuity.

5. *Continuous Monitoring / Intelligence*

   * Active observation and analysis to detect threats, misconfigurations, or anomalies.
   * Basis for SIEM, logging, anomaly detection, and vulnerability scanning.

6. *Secure Defaults / Hardening*

   * Systems should be secure by default; reduce unnecessary exposure.
   * Basis for secure configuration, patching, and minimal attack surface.

7. *Operational Security / Privacy by Design* *(optional but increasingly crucial)*

   * Protect sensitive information from disclosure or misuse; integrate security into design from the start.
   * Basis for data minimisation, OPSEC, encryption, and privacy compliance.

*Why this is minimal and spanning:*

- Each doctrine is *independent*: no other in the set is fully derivable from another.
- Each doctrine is *broad* enough that specific strategies or mechanisms (like Zero Trust, Kill Chain Prevention, intrusion detection) are *specialisations or combinations* of these foundations.
- Any additional doctrine can usually be expressed as a *pattern or operationalisation of one or more of these seven*.

- Fabian Strategy
- Defence in Depth / Elastic Defence
- Fortification
- Choke Point
- Win Without Fighting

=== Given this principle

=== Zero Trust Principles

#table(
  columns: (auto, auto, auto),
  align: center + horizon,
  stroke: none,
  table.header(
    [*Zero Trust / Security Principle*], [*Historical Analogue*], [*Historical Source*]
  ),
  [Assume Breach], [Spartan secret police], [*Medieval Castles*, David Macaulay],
  [Defence in Depth], [Walls of Constantinople with triple fortifications and moats], [*The Byzantine Wars*, John F. Haldon],

  [Continuous Verification], [Qin Dynasty Censorate inspections reporting on officials], [*The First Emperor of China*, Jonathan Clements],
  [Segmentation / Least Privilege], [Byzantine thematic military districts], [*The Byzantine Wars*, John F. Haldon],
  [Adaptive Response], [Hannibal’s feigned retreat at Cannae], [*Hannibal*, Serge Lancel],
  [Micro-Segmentation / Isolation], [Concentric castle baileys and keeps], [*Castles and Fortified Cities of Medieval Europe*, Charles Stephenson],
  [Logging and Monitoring], [Roman frontier watchtowers and census records], [*The Frontier of the Roman Empire*, David J. Breeze & Brian Dobson],
  [Dynamic Access Control], [Ottoman timar system limiting governor authority], [*Osman's Dream*, Caroline Finkel],
  [Verification of Identity], [Roman signet rings and tesserae], [*Roman Dress and the Fabrics of Roman Culture*, Alison E. Cooley],
  [Threat Intelligence], [Sun Tzu’s evaluation of terrain and enemy dispositions], [*The Art of War*, Sun Tzu, trans. Lionel Giles],
  [Redundancy / High Availability], [Dual consuls in Roman Republic to prevent single-point failure], [*SPQR: A History of Ancient Rome*, Mary Beard],
  [Patch / Vulnerability Management], [Medieval city wall repairs after sieges], [*Medieval Fortifications*, J. E. Kaufmann & H. W. Kaufmann],
  [Compartmentalisation], [Mauryan provincial administration with divided authority], [*India Before Europe*, Catherine B. Asher & Cynthia Talbot],
  [Incident Response / Rapid Remediation], [Ashoka’s immediate punitive measures for rebellion], [*Ashoka: The Search for India’s Lost Emperor*, Charles Allen],
  [Audit Trails / Record Keeping], [Roman census and tax records], [*The Roman Census*, W.V. Harris],
  [Fail-Safe Mechanisms], [Qin Dynasty legal punishments to deter failure], [*Legalism in Chinese History*, Hing Ming Hung],
  [Access Logging], [Ottoman kadı court registers], [*Ottoman Judges and Their Records*, A. Yaşar Ocak],
  [Separation of Duties], [Byzantine bureaucracy offices with overlapping responsibilities], [*Byzantine Bureaucracy and Aristocracy*, John B. Bury],
  [Containment / Quarantine], [Plague quarantines in Ragusa (Dubrovnik)], [*The Black Death*, Philip Ziegler],
  [Immutable Records], [Egyptian hieroglyphic monumental inscriptions], [*The Oxford History of Ancient Egypt*, Ian Shaw],
  [Change Management], [Tokugawa Japan sankin kōtai system (alternate attendance)], [*Japan’s Medieval Population*, William Wayne Farris],
  [Event Correlation / Pattern Detection], [Byzantine theme logs and reports], [*Byzantium: The Surprising Life of a Medieval Empire*, Judith Herrin],
  [Adaptive Intelligence Sharing], [Caravan and border informants along Silk Roads], [*The Silk Roads*, Peter Frankopan],
)

Rick Howard's Strategies
- Zero trust
- Intrusion Kill Chain Prevention
- Resilience
- Risk Forecasting
- Automation

Security Mechanisms
- Access Control Lists (ACLs)
- Capability systems
- Role-Based Access Control (RBAC)
- Attribute-Based Access Control (ABAC)
- Mandatory Access Control (MAC)
- Discretionary Access Control (DAC)

Security Models
- Bell–LaPadula. Confidentiality in multilevel systems (“no read up, no write down”).
- Biba integrity. Integrity model (“no read down, no write up”).
- Clark–Wilson. Commercial integrity model based on well-formed transactions and separation of duties.
- Brewer–Nash. “Chinese Wall” model preventing conflicts of interest.
- Graham–Denning. Formal model for secure creation/deletion of subjects and objects.
- Harrison–Ruzzo–Ullman. Formal analysis of rights propagation and safety in access control systems.
- Take–Grant. Graph model describing how access rights can be transferred.
- Lattice-based access control. General framework underlying many multilevel security models.
- Information Flow. Tracks permitted flows of information between system components.
- Noninterference. Ensures high-security actions cannot affect low-security observations.

Historical Distributions:

Throughout history, communities and boundaries move, shift, grow and shrink according to what the dominant technology facilitates. Political boundaries are only one such form of boundary, financial, religious, ideological communities frequently occur across these boundaries.
The change in technology over time.


- Manual Encryption(-1960) - Sparse, distributed
- Mainframe (1960 - 1981) - Centralised
- Personal computer (1981 - 1995) - Decentralised, Isolated
- Internet (1995 - 2006) - Decentralised, Interlinked
- Cloud (2006 - 2020) Centralised, Interlinked
- AI (2020-Present) ? 

Principles

- Cyber Hygiene - Vint Cerf, 2000
- Defence in Depth
A possible early example of this came at the Battle of Cannae in 216 BC, when Hannibal employed this manoeuvre in order to encircle and destroy eight Roman legions, but that is disputed by some historians. Edward Luttwak used the term to describe his theory of the defensive strategy employed by the Late Roman army in the 3rd and 4th centuries AD.
Later examples of defence in depth might be European hill forts and the development of concentric castles. These castles utilised many layers, including ditches, outer walls, towers, inner walls, and a keep, with some layers like the outer ditch intended to only slow attackers and reduce their coordination. In those examples, the inner layers of defence can support the outer layers with projectile fire and an attacker must breach each line of defence in turn with the prospect of significant losses, and the defenders have the option of falling back to fight again. On a strategic level, defence in depth was employed by the Byzantine military. Fred Cohen 1992 'Defense-in-depth against computer viruses'
- Least Privilege/Least Functionality 
- Assume Breach, Probably the only thing that is new about Zero Trust Architecture. ZTA stated baldly, says that the perimeter no longer exists. However, it would be extremely naive to let anyone into the inner realms of your data centre just because you have some inner defence. You should not assume perimeters don't exist, you should assume that any one layer can or already has been breached, or has malware, spyware, etc, and for that exact reason build multiple perimeters, some of them being host based or "microsegmentation".

- Watch Everything
- Monitor Everything












These represent major changes the ways that information was shared and protected.

=== Mainframe

In the modern world, the computer era started in earnest in Phase 1, when the mainframe computer became useful to governments, universities, and the commercial world. It took about a decade before the mainframe community realised that they might have a computer security problem, and it started with the U.S. military. Willis Ware’s paper “Security Controls For Computer Systems,” published in 1970 when Ware was working for the Rand Corporation, started the process.1 His paper is not so much a definition of cybersecurity or a statement about cybersecurity first principles as it is a listing and description of all the ways computers were going to be a problem in the future when they started sharing resources across networks. I would put this in the category of, “the first step in solving any problem is recognising that you have a problem.” The paper hints at the idea that the security community needs to determine how to build secure systems. That means designing a computer architecture that is mathematically proven to be impenetrable. That idea would be the focus of researchers through the 1990s. In the Cybersecurity Canon Hall of Fame book, "A Vulnerable System: The History of Information Security in the Computer Age," published in 2021, the author, Andrew Stewart, laments the fact that since the beginning of the digital age, nobody has been able to build a secure system.2 That’s true. Today, that idea has largely been abandoned.

=== The 70s and 80s.

The paper, “Computer Security Technology Planning Study,” published by James Anderson for the U.S. Air Force in 1972 feels like a continuation of thought from the Willis Ware paper.3 It’s an early expression, maybe the first expression, of the idea that security shouldn’t be added on after the system is built; something that security professionals still talk about today when you hear them discuss the idea of shifting left or security-by-design. It mirrors the idea that building a secure system is the ultimate goal but proposes that any secure systems will require a way to monitor that system for defects and intrusions.

The next year, David Bell and Len LaPadula, then working for MITRE, published their paper called "Secure Computer Systems: Mathematical Foundations.”4 In it, they provide the arithmetic proof that would guarantee that a computer system is secure. Unfortunately, they admit up front that even if you could build a system that adhered to the proof, how would system builders guarantee that they implemented everything correctly? Theoretically, you could do it, but practically, how would you vouch for its security? And this is the problem that plagued this kind of research for 20 years.

In 1975, Jerome Saltzer and Michael Schroeder published their paper, "The Protection of Information in Computer Systems," in the Proceedings of the IEEE.5 According to Jen Reed, a former CISO but now working as an AWS Principle, and is a regular guest here at the Cyberwire Hash Table, told me in a Linked-In conversation last year (2022) that Saltzer and Schroeder’s paper may be the first paper to describe the CIA triad. They didn’t call it that but they refer to three types of invasion: unauthorised information release (confidentiality), unauthorised information modification (integrity), and unauthorised denial of use (availability).

What’s interesting is that Saltzer and Schroeder, as well as other researchers during this period, talk about the elements of the CIA Triad but they never group them together as a coalesced concept. These early papers refer to those elements as things you might do and should do in a checklist, or things that can go wrong if you don’t do them. But they never lump all three characteristics into one cybersecurity first principle as in, if you just get these three things done, then you will have solved cybersecurity.

Saltzer and Schroeder also likely make the first case that userid/password combinations are a weak form of authentication and two-factor authentication will be required. Further, they might be the first to champion the reduction of complexity in all things related to security design and, for whatever the design becomes, to not hide it in secrecy. In other words, this may be the first public record of researchers making the argument against security through obscurity. Finally, they promote an idea called “Fail-safe defaults;” deny everything first and allow by exception. This idea is possibly the first inklings of perimeter defence; building an outer barrier to the network that could control access. This was about a decade before we had the technology to do it–we call that technology “firewalls”.

 U.S. Department of Defense published “TRUSTED COMPUTER SYSTEM EVALUATION CRITERIA,” more commonly known as The Orange Book. This was an effort to establish standards for how secure a computer system should be depending on the classification level of the data that will reside on the system. The standards have changed over time but the idea is still in practice today not just by the U.S. government but many governments worldwide when they think about security requirements for various levels of security classification like Top Secret, Secret, Confidential, and Sensitive But Unclassified (SBU).
Defence in depth.

Dr. Fred Cohen published the first papers in the early 1990s that used defence-in-depth to describe a common cybersecurity model in the network defender community.6 7 Back in 2016, I discovered his papers but couldn’t tell if he originated the idea of defence-in-depth. He referred to the concept but didn’t take credit for it. So, I called him on the phone and asked him. I said “Fred, are you the guy that invented defence in depth?” He said that, no, he didn’t invent the idea but he was probably the first one to document it in a research paper.8 So, there you go. Let’s give it to Fred. Since scientific tradition typically gives credit to the person who publishes first, Fred is our man.

Defence-in-depth is the idea that network architects would erect an electronic barrier that sits between the internet and an organisation's digital assets. In order to get on the inside of the barrier from the internet, you had to go through a control point (usually a firewall but sometimes, in the early days, with a router). From the 1990s until today, the common practice has been to add additional control tools behind the firewall to provide more granular functions. In the early days, we added intrusion-detection systems and anti-virus systems. All of those tools together formed something called the security stack, and the idea was that if one of the tools in the stack failed to block an adversary, then the next tool in line would. If that one failed, then the next would take over. That’s defence-in-depth. If you asked cybersecurity practitioners today to describe their security model, many would say they follow the defence-in-depth model.

But you will notice that I don’t have defence-in-depth as one of my first principle strategies. When you say that you are strategically trying to reduce the probability of material impact to your organisation due to a cyber event, and you say that you are deploying a defence-in-depth strategy, how does that work exactly? In the old days (say the late 1990s), we were just trying to block bad technical things from happening. Call it cyber hygiene. We would block all network traffic and only allow by exception with our firewall. We would disallow even more network traffic based on known bad guy IP addresses with our intrusion detection systems. And we would block malicious code with our anti-virus systems; three systems, defence in depth. As time went on, we added more and more tools to the stack.

Back then, cyber hygiene was our first and best guess about how to stop malicious behaviour coming onto our networks. I used it back in the day like everybody else because we didn’t have an alternative. But today, defence-in-depth doesn't have anything to say about the more modern notions of probability and materiality. Defence-in-depth is an idea whose time has come to an end.
The CIA triad.

In 1998, Donn Parker published his book “Fighting Computer Crime: A New Framework for Protecting Information” where he strongly condemns the elements in the CIA Triad as being inadequate.9 He also never mentions the phrase “CIA Triad,” however. He proposed adding three other elements (Possession or control, Authenticity, and Utility) that eventually became known as the Parkerian Hexad, but the idea never really caught on for reasons probably only a marketing expert could explain.

It’s unclear when or even who is responsible, but sometime after the Parker book, the infosec community started referring to the three elements—confidentiality, integrity, availability—as a single concept, an inextricably linked triad. During this period, most security practitioners spent time improving the security stack in one form or the other.

As cloud environments emerged around 2006, however, the number of digital environments we had to protect exploded. Organisations started storing and processing data in multiple locations that I like to call data islands (traditional data centres, mobile devices, cloud environments, and SaaS applications). The security stack idea became more abstract. It wasn’t one set of tools physically deployed behind the firewall any longer. It was now a series of security stacks deployed for each data island. The security stack became the set of all tools deployed that improved the organisation’s defensive posture regardless of where they were located; Defence-in-Depth applied abstractly to all of the environments.

Most of the research in this period focused on improving CIA Triad capability by building better tools for the security stack (like application firewalls, identity and access management systems, XDR, etc) and better models for stopping adversary activity (Kindervag’s zero trust "No More Chewy Centers” paper - 201010, Lockheed Martin’s intrusion kill chain model - also 201011, the U.S. Department of Defense’s Diamond model - 201112, and the MITRE ATT&CK Framework - 201313).
Modern day.

About the same time, the academic community started some preliminary thinking about how to apply the first principle idea to cybersecurity. The State University of New York at Buffalo’s Charles Arbutina and Sarbani Banerjee tied what they called “foundational propositions” to the U.S. National Security Agency (NSA) checklist of what makes up a secure system.14 But their work assumes that building a secure system is the absolute cybersecurity first principle without any discussion. It’s the right idea, pursuing cybersecurity first principles, but it’s not atomic enough: it doesn’t get to what the actual first principle is. Some of their proposed tasks—like domain separation, process isolation, and information hiding—might be and should be used as a tactic, but the authors don’t illustrate exactly what it is they are trying to do. They don’t get to the essence of the problem.

In 2017, Dr. Matthew Hale, Dr. Robin Gandhi, and Dr. Briana Morrison covered similar ground using the NSA checklist in their “Introduction to Cybersecurity First Principles” designed for elementary students (K-12).15 And, in 2021, Dr. John Sands, Susan Sands, and Jaime Mahoney, from Brookdale Community College, cover the same material with more detail but again don’t offer any argument about why these are first principles, just that they are.16

Shouhuai Xu published his paper, "The Cybersecurity Dynamics Way of Thinking and Landscape" at the 7th ACM Workshop on Moving Target Defense in 2020.17 Xu proposes a three-dimensional axis with first principles modelling analysis (Assumption driven), data analytics (Experiment driven), and metrics (Application and semantics driven). But again, there is no discussion of why his first principles are elemental.

Nicholas Seeley published his master’s thesis at the University of Idaho in 2021: “Finding the Beginning to Discover the End: Power System Protection as a Means to Find the First Principles of Cybersecurity.”18 Out of all the papers reviewed here, this is the most complete in terms of first-principle thinking. In his thesis, Seeley also reviewed most of the papers I’ve listed in this essay before he drew any conclusions and makes the case that the main ideas that emerge from those papers revolve around the issue of trust. He then questions whether or not the idea of trust is fundamental enough to be a first principle. He quotes James Coleman and his book “The Foundations of Social Theory” 19 that says “situations that involve trust are a subset of situations that involve risk.” Or, as Seeley says, “without risk there is no need for trust.” Seeley says that risk is a function of probability; a measure of uncertainty. He believes that uncertainty is more fundamental than the CIA Triad or any of the other analytical checklists that the previous authors came up with. Interestingly, the father of Decision Analysis theory, Dr. Ron Howard, says the same thing in his book, “The Foundations of Decision Analysis Revisited.”20

Seeley takes an idea from the Luhmann/King/Morgner book, “Trust and Power,” that trust allows us to reduce complexity in our lives.21 He then proposes a set of assumptions (postulates or axioms in the styl of Euclid), that form his set of cybersecurity first principles.

1. Complete knowledge of a system is unobtainable; therefore, uncertainty will always exist in our understanding of that system.

2. The principal of a system must invest trust in one or more agents.

3. Known risks can be mitigated using controls, transference, and avoidance, else the risks must be accepted.

4. Unknown risks manifest through complexity.

But then he stops short of identifying the absolute cybersecurity first principle and uses his axioms to design a better proof than Bell and LaPadula to decide if one system design over another is more secure using eigenvalue analysis of the associated graphs. In other words, he went back to the traditional well of trying to design secure systems.
The beginning of cybersecurity first principles.

I started thinking and writing about cybersecurity first principles as early as 2016. My thoughts weren’t fully formed yet, but even then, I knew that the security practitioner community was going in the wrong direction. We had somehow chosen, in a groupthink kind-of way, that securing individual systems with the CIA Triad was the way to go. And yet, when most were following that best practice, the number of breaches reported, just in the public alone, continued to grow. As Parker suggested, I knew that the CIA Triad wasn’t elemental enough. The elements were good tactics but they didn’t represent the essence of what we were trying to do.

And I knew it was probably hopeless to design a secure computer system too even with Seeley’s eigenvalue analysis. Even the giants in the field couldn’t figure that out in the1970s and the 1980s. Besides, in hindsight, it was the wrong focus. We didn’t need to protect individual computer systems as a first principle. We might do that for special niche cases as a tactic where the security requirements are extreme (like government classified systems). But for the rest of the normal use cases, we needed to prevent material impact to our organisations.

For the past three years, this entire essay and podcast series has been a discussion of what cybersecurity first principles are and how we might achieve them. If you’re still reading this stuff after all this time, you at least don’t think I'm completely crazy. You possibly think that there might be some merit to it all. Thank you for that.

The one downside to this is that we publish this content in pieces scattered across the Cyberwire’s website. Well, if you’re one of those people who like to have all of this material in a tight little container, like, I don’t know, a book, well, your prayers have been answered. The folks at The CyberWire have spent the last six months compiling that very book. It’s called, “Cybersecurity First Principles: A Reboot of Strategy and Tactics”22 and we are rolling it out in time for the big RSA Conference shindig in April of this year. You can pre-order your copy now at Amazon. The link is below. Or just go to the Amazon web page and search for the title. You can’t miss it. And, if you’re travelling to the great state of California for the conference this year, I will be signing copies at the bookstore. I would love to see you there.
References.

1 Ware, W.H., 1970. Security Controls for Computer Systems (U): Report of Defense Science Board Task Force on Computer Security. The Rand Corporation.

2 Stewart, A.J., 2021. A Vulnerable System: The History of Information Security in the Computer Age. Cornell University Press.

3 Anderson, J.P., 1972. Computer Security Technology Planning Study (Volume I). Electronics System Division 1.

4 Bell, D., LaPadula, L., 1973. Secure Computer Systems: Mathematical Foundations. Mitre.

5 Saltzer, J., Schroeder, M., 1975. The Protection of Information in Computer Systems. Proceedings of the IEEE 63, 1278–1308.

6 Cohen, F., 1989. Models of practical defenses against computer viruses. Computers &amp; Security 8, 149–160. https://doi.org/10.1016/0167-4048(89)90070-9

7 Cohen, F., 1992. [PDF] Defense-in-depth against computer viruses. Computers and Security 11, 563–579.

8 Cohen, F., 2016. Defence in Depth phone conversation with Rick Howard.

9 Parker, D.B., 1998. Fighting Computer Crime: A New Framework for Protecting Information. Wiley.

10 Kindervag, J., 2010. No More Chewy Centers: Introducing The Zero Trust Model Of Information Security. Forrester.

11 Hutchins, E., 2010. Intelligence-Driven Computer Network Defense Informed by Analysis of Adversary Campaigns and Intrusion Kill Chains. Lockheed Martin.

12 Caltagirone, S., Pendergast, A., Betz, C., 2011. The Diamond Model of Intrusion Analysis. Center for Cyber Threat Intelligence and Threat Research.

13 Strom, B., Applebaum, A., Miller, D., Nickel, K., Pennington, A., Thomas, C., 2020. MITRE ATT&CK: Design and Philosophy. Mitre.

14 Sarbani, B., Arbutina, C., n.d. Cybersecurity First Principles.

15 Hale, M., 2017. Introduction to Cybersecurity First Principles · nebraska-gencyber-modules [WWW Document]. Nebraska-Gencyber-Modules. URL https://mlhale.github.io/nebraska-gencyber-modules/intro_to_first_principles/README/ (accessed 10.29.22).

16 Sands, J., Sands, S., Mahoney, J., n.d. Cybersecurity Principles [WWW Document]. NCyTE, WA. URL https://www.ncyte.net/faculty/cybersecurity-curriculum/college-curriculum/interactive-lessons/cybersecurity-principles

17 Xu, S., 2020. The Cybersecurity Dynamics Way of Thinking and Landscape, in: Proceedings of the 7th ACM Workshop on Moving Target Defense. ACM, New York, NY, USA.

18 Seeley, N., 2021. Finding the Beginning to Discover the End: Power System Protection as a Means to Find the First Principles of Cybersecurity (Degree of Master of Science). University of Idaho.

19  Coleman, J.S., 1994. Foundations of Social Theory [Book]. www.goodreads.com/book/show/236795.Foundations_of_Social_Theory?ref=nav_sb_ss_1_28. URL (accessed 2.7.23).

20 Howard, R.A., Abbas, A.E., 2015. Foundations of Decision Analysis [WWW Document]. www.goodreads.com/book/show/14794158-foundations-of-decision-analysis?ref=nav_sb_ss_1_32. URL (accessed 2.7.23).

21 Luhmann, N., 2018. Trust and Power. John Wiley & Sons.

22 Howard, R., April 2023. Cybersecurity First Principles: A Reboot of Strategy and Tactics [Book]. https://www.amazon.com/Cybersecurity-First-Principles-Strategy-Tactics/dp/1394173083. URL (accessed 2.7.23).

  Billings, R., 2018. Another favourite quote: “Standing on shoulders” - Newton [WWW Document]. Acellus Learning System. URL https://www.science.edu/acellus/2018/11/newton-seeing-further/ (accessed 2.8.23).

#pagebreak()
