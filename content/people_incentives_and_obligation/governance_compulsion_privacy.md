---
cnl: sbvr
cnl-version: 1
cnl-scope: normative
lexicon: core-v1
lint: strict
---
# Governance, Compulsion, Privacy

**Goal:** the architecture answers correctly to law, audit and privacy regimes without installing compliance theatre.

## Architectural versus procedural controls

A procedural control asks a person to behave correctly: a policy document, a review meeting, a signature on a change form. An architectural control makes the incorrect behaviour unavailable: a credential that cannot be issued outside a scope, a segment that cannot route to the internet, a build that cannot promote an unverified artifact. Procedural controls decay because people get busy, forget, or work around them; architectural controls scale because they are enforced by the system on every transaction, including the ones nobody is watching.

This is not an argument for abolishing procedures. Policies record intent, allocate authority and define exceptions; a system with no policy has no way to distinguish a deliberate exception from an accident. The point is about which controls carry the load. When a control is load-bearing for a security property, it must be architectural. Auditability should then be a byproduct of correctness: the configuration in version control, the identity decision in the log and the signed build record are evidence the system produced while doing its job, not a report assembled for an auditor.

Compliance theatre is the inverse: artefacts produced to satisfy a reviewer that do not correspond to any property of the running system. Recognising it is a practical skill. Ask what system state would change if the artefact were removed. If the answer is none, the artefact is theatre.

## The legal compulsion landscape

Organisations that provide communications services can be compelled by law to assist lawful access. Examples include the United States' CALEA, the United Kingdom's Investigatory Powers Act 2016 and Australia's Assistance and Access Act 2018.[^calea] [^ipa] [^aaa] They differ in scope, process and what they permit, but they share a design implication: a provider can be required to build or retain a capability it would not otherwise have chosen to build. An architecture that renders itself incapable of producing plaintext, because it never holds the keys or stores the content, is a genuine limit on what can be compelled; an architecture that merely promises not to look is not.

The honest framing matters. Some jurisdictions also restrict encryption or require assistance that effectively weakens it, which means "we cannot comply" is not always an available position. The architect's task is to establish the applicable regime with qualified advice, decide which capabilities the organisation will and will not build, and record the decision. Refusing to build a capability is itself a control, but it is a legal and business decision with consequences; it must be made explicitly rather than discovered during an incident.

Jurisdictional data residency is the other compulsion-driven design input. Where data is stored determines which law reaches it, so residency is a segmentation boundary as much as a contractual term. The architecture should be able to name, for each data class, the jurisdiction whose law applies and the technical path that keeps the data inside it.

## Privacy essentials

Data classification drives segmentation. A class that is personal, confidential or regulated gets a boundary, an allowed set of consumers and a retention rule; a class with no such designation cannot be protected by a boundary that was never drawn. This is why the data-security chapter treats classification as an architectural input rather than a documentation exercise.

The EU GDPR and sector-specific regimes such as healthcare and financial-services rules impose obligations that vary by jurisdiction and data class.[^gdpr] Privacy-by-design means the technical controls — minimisation, purpose limitation, access control, retention limits, pseudonymisation — are properties of the system, not promises in a notice. An architecture that collects everything "in case it is useful later" has made an unstated privacy decision, and the cost of that decision grows with every copy made.

The observability pipeline is a common source of accidental collection: logs contain credentials, identifiers and content. A retention rule that applies to logs as data, with access control and minimisation at emission, is part of the privacy architecture, not an afterthought in the logging chapter.

## Frameworks, risk and policy as code

Frameworks are vocabularies for the same underlying controls. ISO 27001 and 27002, NIST CSF 2.0, CIS Controls v8 and the ACSC Essential Eight describe overlapping sets of practices in different structures.[^iso27001] [^csf] [^cis] [^e8] An architecture-first course uses them as a check on coverage, not as a design method. The design method is the set of principles in the Foundations chapter; the framework is the translation layer used when an organisation must report against a recognised standard.

Risk management follows the same pattern. FAIR offers a quantitative way to express loss events and their frequency; architecture-first treats risk as a filter on design choices rather than a driver that can be delegated to a register.[^fair] A risk register that says "data breach: high" has not told the architect which boundary to move. A register that says "unauthenticated access to this service exposes this data class to this population" has, and the architecture can answer it.

Policies become architectural when they are executable. Policy-as-code tools — Open Policy Agent with Rego, Kyverno for Kubernetes admission, Conftest for linting infrastructure-as-code — turn a rule into something evaluated on every change rather than read once a year.[^opa] [^kyverno] [^conftest] The governance chapter owns the meaning of the rule; the pipeline enforced it. SCAP and OpenSCAP provide a standard format for expressing and checking configuration policy, which matters when an auditor needs machine-readable evidence rather than a screenshot.[^scap] The connection to the application chapter is direct: pipeline gates are the enforcement point, governance defines what they enforce.

Third-party risk is handled with the same preference for evidence over assurance. SBOMs say what is in a supplied artifact, contractual controls say what the supplier must do, and the verification of both belongs in the pipeline. A vendor questionnaire is a procedural control; a verified signature and an SBOM are architectural ones.

## What an architect decides at the governance layer

| **Decision** | **The course's answer** |
| --- | --- |
| Control type | Architectural where the control is load-bearing; procedural only for intent and exception handling |
| Compulsion | Capabilities the organisation will not build named explicitly; legal advice obtained for each jurisdiction |
| Residency | A segmentation boundary with a named applicable law per data class |
| Privacy | Minimisation and purpose limitation enforced in the system, including in logs |
| Frameworks | Used to check coverage and report, not as the design method |
| Risk | Used as a filter on architecture; FAIR where quantification is justified |
| Policy | Expressed as code and enforced by the pipeline; SCAP/OpenSCAP where standard evidence is required |
| Third parties | SBOMs and verified signatures over questionnaires and assurances |

## Architectural rules

- Every load-bearing control shall be architectural.
- Every policy shall be expressible as executable code.
- Every regulated data class shall have a named jurisdiction.
- Every audit artefact shall derive from system state.

**Architectural question a graduate answers:** **what does the business have to answer for in law, what architectural choices reduce that surface, and what controls can you produce under audit without operational theatre?**

[^calea]: Communications Assistance for Law Enforcement Act, 1994.
[^ipa]: Investigatory Powers Act 2016 (UK).
[^aaa]: Assistance and Access Act 2018 (Australia).
[^gdpr]: Regulation (EU) 2016/679 (GDPR).
[^iso27001]: ISO/IEC 27001 and 27002.
[^csf]: NIST Cybersecurity Framework 2.0, 2024.
[^cis]: CIS Controls, Version 8, 2021.
[^e8]: Australian Cyber Security Centre, Essential Eight.
[^fair]: The Open Group, FAIR™ Standard.
[^opa]: Open Policy Agent and Rego.
[^kyverno]: Kyverno project documentation.
[^conftest]: Conftest project documentation.
[^scap]: NIST Security Content Automation Protocol; OpenSCAP project.
