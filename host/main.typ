== Host and Endpoint Security

*Goal:* build verifiable, reproducible, attestable hosts.

=== Linux hardening
- Kernel surface (sysctl hardening, KSPP recommendations)
- systemd unit confinement (sandbox directives)
- AppArmor vs. SELinux, policy authoring, auditing
- auditd rule design

=== Declarative systems
- NixOS configuration, modules, flakes
- Guix as comparison
- Ansible
- Why imperative systems cannot be kept in a known state

=== Boot integrity
- UEFI Secure Boot basics
- Measured boot, TPM 2.0 PCRs
- Remote attestation architectures
- Unified kernel images, disk encryption with TPM-bound keys

=== Software supply chain on the host
- Reproducible builds, current maturity
- SBOM formats (SPDX, CycloneDX) and generation
- SLSA levels, in-toto attestations, VEX
- PURL and CPE identifier hygiene
- Live CVE correlation workflows

=== Containers
- Rootless containers, user namespaces
- seccomp profiles, AppArmor for containers
- gVisor, Kata for stronger isolation
- Image provenance (cosign verify)

=== Endpoint detection
- osquery for fleet visibility
- Wazuh agents for HIDS
- Falco for syscall-level runtime detection

#pagebreak()
