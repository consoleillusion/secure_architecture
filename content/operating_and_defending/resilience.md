---
cnl: ace
cnl-version: 1
cnl-scope: hybrid
lexicon: core-v1
lint: strict
secondary-cnl: ste
---
# Resilience

**Goal:** the architecture answers correctly to "how fast, from what, to what state."

## Recovery as architectural input

Recovery point objective (RPO) and recovery time objective (RTO) are not properties of a backup product. They are business statements: how much data the organisation can afford to lose, and how long it can afford to be without a service. Deriving them requires asking what the service does, what happens while it is down, who depends on it and in what order. A finance system that must be back before payroll runs has a different answer from a wiki that can wait a day, and neither answer comes from the backup vendor.

The objectives precede the technology. Choosing a backup product and then declaring the resulting RPO and RTO to be what the organisation needs is a common failure: it makes the constraint follow the implementation. Dependency mapping is the other prerequisite. A service's restore time is the restore time of everything it needs — identity, DNS, network, storage — so the recovery order is an architectural artifact and must be documented and tested. An environment that restores its application servers before its directory is a demo, not a recovery.

## Backup topology

The 3-2-1 rule — three copies, two different media, one off-site — is a minimum, not a design. A modern implementation adds immutability: append-only object stores, object lock with a retention period, and at least one copy that is offline or held under a separate credential from the production estate. The threat the immutable copy answers is specific and important: ransomware that obtains administrative credentials must not be able to delete the backups. A backup reachable with the same credentials as the production system is not a backup against the incident that matters.

Encryption protects backups in transit and at rest, but key management is the hard part. A key stored next to the encrypted backup buys nothing against an attacker who controls that host; a key held separately, under a different identity and with a documented recovery procedure, does. The recovery procedure must work when the directory is itself part of the incident, which is why the offline copy and its key path need to be independent of the systems they protect.

Integrity is distinct from existence. A job that reports success while writing empty files is worse than a job that fails loudly, because it removes the evidence that would have prompted action. Backup verification should check restoreability, not just file counts, and the results belong in the shared observability pipeline with enough retention to show a trend.

## Restore as a first-class activity

Untested backups are not backups. Restore testing has a cadence derived from the change rate of the system, not from a convenient calendar date: a frequently changing service needs frequent restore tests, because a backup that worked last quarter may not cover today's configuration. Each test restores to an isolated environment, verifies the data and the application, and records the elapsed time against the RTO.

Tabletop exercises extend this from technology to decisions. Who declares an incident, who authorises a restore, who communicates with customers, and what happens when the person who normally does all three is unavailable? These are architectural questions about authority and dependency, not exercises in reading a runbook aloud. The output should be changes to the architecture or to the named responsibilities, not a report that is filed and forgotten.

## Disaster recovery architecture

Hot, warm and cold patterns are points on a cost curve, not ranks in a maturity model. Hot keeps a live copy ready to take traffic with minimal delay and the highest recurring cost. Warm keeps infrastructure provisioned and data replicated but does not run the full service until needed. Cold keeps data and configuration, with the compute built on demand; it is cheapest and slowest. Pilot light is a warm variant in which a minimal core — identity, DNS, the control plane — is always running. Multi-region designs add failure-domain independence but also add consistency, identity and operational complexity that must be justified by the RTO rather than adopted for its own sake.

A useful selection rule is to work backwards from the objective: if the RTO is minutes, only a hot pattern with tested automated failover can meet it; if the RTO is hours, warm or pilot light may be sufficient; if it is a day or more, cold is often the honest answer. Cloud mythology tends to invert this by promising effortless resilience from region count. A second region with untested identity, untested restore and untested runbooks is two places for the same failure to occur.

## The detection surface

Recovery is a consumer of observability, not a parallel stack. The alert that starts an incident, the identity decisions that show which credentials were used, the flow records that show what left the estate, and the integrity results from the backup system all need to arrive in one place with a common time base. The resilience chapter defines what must be answerable after the fact: what changed, when, under whose identity, and whether the restore reached the state the architecture promised.

## What an architect decides at the resilience layer

| **Decision** | **The course's answer** |
| --- | --- |
| RPO and RTO | Derived from business function before any technology is chosen |
| Dependency order | Documented and tested; identity and network restored before dependent services |
| Copies | 3-2-1 as a minimum, with an immutable copy under a separate credential |
| Keys | Stored separately from the data they protect, with a recovery path that survives loss of the directory |
| Verification | Restore tests on a change-driven cadence, timed against the RTO |
| Exercises | Tabletops that change responsibilities or architecture, not just documentation |
| DR pattern | Selected from the RTO: hot for minutes, warm or pilot light for hours, cold for a day or more |
| Evidence | Backup results and recovery events emitted to the shared observability pipeline |

**Architectural question a graduate answers:** **what is the RPO/RTO for each system, what backup topology achieves it, when was it last restored successfully, and in what order does recovery proceed?**
