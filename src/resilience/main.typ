== Resilience

*Goal:* the architecture answers correctly to "how fast, from what, to what state."

=== Recovery as architectural input
- RPO and RTO derivation, where they come from, how they drive design
- Why recovery objectives precede backup technology, not the other way around
- Dependency mapping, what must come back first and in what order

=== Backup topology
- 3-2-1 as a minimum
- Immutable backups: append-only stores, object-lock, offline copies
- Encryption in backup, key management is the hard part, not the encryption
- Backup integrity: verification, not just existence

=== Restore as a first-class activity
- Restore testing cadence
- Tabletop exercises against recovery scenarios
- Why untested backups are not backups

=== DR architecture
- Hot, warm, cold, what each costs and what each buys
- Pilot light and multi-region patterns without cloud mythology
- RTO-driven selection among them

*Architectural question a graduate answers:* *what is the RPO/RTO for each system, what backup topology achieves it, when was it last restored successfully, and in what order does recovery proceed?*

#pagebreak()
