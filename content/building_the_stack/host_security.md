# Host and Endpoint Security

**Goal:** build verifiable, reproducible, attestable hosts.

## Why the host is a trust boundary

The network chapters argued that network location cannot carry trust; the identity chapter argued that every service must authenticate its callers. Both arguments terminate on a host. If the host running a service cannot be trusted to be what the architecture says it is, then its identity, its cryptographic keys and its authorisation decisions are all available to whoever changed it. Host security is therefore not an endpoint product category. It is the discipline of making a machine's state a known, reviewable quantity.

The course uses **verifiable** in a specific sense: the running host can be compared against a description, and divergence is observable. Reproducibility makes the description useful; attestation makes the comparison available to a remote party. Neither is achieved by an agent that reports "healthy" according to its own unattested logic.

## Declarative systems

A NixOS host is described by a configuration that names its packages, services, users and configuration files. A rebuild makes the managed part of the system match that description; packages and services not in the description are not in the resulting system closure. This is the strongest form of least functionality available on a general-purpose host. It is not total: `/var`, user data, runtime state and anything written outside the managed closure persist and must be treated as separate state with its own controls.

Guix makes a similar set of commitments with a different package model, and is worth knowing as evidence that declarative hosts are not a single product. Terraform and OpenTofu describe infrastructure around hosts; Ansible remains useful for imperative gap-filling where a device cannot be described declaratively, but every imperative step is a place where the running state and the description can silently diverge. The rule is not "never use imperative tools" but "every imperative step is recorded, justified and bounded."

## Hardening the running host

Hardening reduces what a compromised process can reach. At the kernel level this means applying conservative `sysctl` settings and following the Kernel Self Protection Project's guidance where the workload permits. At the service level it means systemd sandboxing directives — `ProtectSystem`, `PrivateTmp`, `NoNewPrivileges`, `RestrictAddressFamilies` and their companions — so that a service escape does not become a host compromise. Mandatory access control, through AppArmor or SELinux, adds a policy that a compromised process cannot override with its own credentials.

Audit rules should be narrow and intentional: a small set of high-value paths and operations, rather than a firehose that nobody reads. The observability chapter owns the pipeline that carries these events; the host chapter owns the decision about what is worth emitting.

## Boot integrity and attestation

Secure Boot establishes that the firmware and bootloader chain are signed by keys the organisation trusts. Measured boot records what actually ran into TPM platform configuration registers (PCRs), and a unified kernel image reduces the number of independent pieces that can be measured and changed. Binding disk encryption keys to TPM PCRs means a modified boot chain cannot unseal the key, which turns boot integrity into a practical control rather than a measurement nobody consumes.

Remote attestation extends the comparison to a verifier: the host presents signed measurements, the verifier checks them against a policy, and only then is the host admitted to the network or given a credential. The hard part is not the measurement but the policy and the recovery path when a legitimate update changes a PCR. An attestation system that cannot distinguish a planned rebuild from an intrusion will be switched off at the first outage.

## Software provenance on the host

Every package on a host is a trust decision. An SBOM in SPDX or CycloneDX format records what is present; VEX statements say whether a disclosed vulnerability actually affects it as deployed; PURL and CPE identifiers make the correlation unambiguous; and an automated pipeline matches the inventory against CVE feeds. The introduction described this pipeline as an architectural requirement. The host chapter is where it is consumed: the question is not whether a scanner produced a report, but whether a new advisory can be traced to a specific host and a specific decision within a defined time.

Supply-chain attestation itself — sigstore, in-toto, SLSA levels and build provenance — is designed and produced in the application chapter. Here it is an input: the host verifies provenance before accepting a package, and records the verification. Two chapters owning different halves of one artifact is deliberate, but it requires both to name the same identifiers and the same trust anchor.

## Containers

Containers are processes with boundaries provided by the kernel, not virtual machines with a separate kernel. Rootless operation and user namespaces remove the most dangerous default — root inside the container being root on the host. `seccomp` profiles restrict available syscalls, AppArmor or SELinux confine filesystem access, and gVisor or Kata provide stronger isolation where the workload justifies the cost. Container images are software artifacts and must be verified by signature, for example with `cosign`, before they are admitted. An unverified image is an unsigned binary from an unknown builder, whatever registry it came from.

## Detection surface

Fleet visibility is emitted, not discovered after an incident. `osquery` turns host state into queryable tables, Wazuh agents provide host intrusion detection, and Falco observes syscalls at runtime. These are sensors; they become a detection surface only when their output reaches the shared pipeline with enough schema consistency and retention to be correlated with identity and network events. Alert fatigue is designed in or prevented at this stage, not fixed later by tuning a dashboard.

## What an architect decides at the host layer

| **Decision** | **The course's answer** |
| --- | --- |
| Host description | Declarative configuration in version control; imperative steps recorded and bounded |
| Managed scope | State inside the configuration versus state outside it named explicitly |
| Least functionality | Only declared packages and services; no ad-hoc installs on managed hosts |
| Service confinement | systemd sandboxing plus AppArmor or SELinux for anything handling untrusted input |
| Boot chain | Secure Boot, measured boot, unified kernel images where supported, TPM-bound storage keys |
| Attestation | Signed measurements checked against a policy, with a tested recovery path for legitimate rebuilds |
| Provenance | SBOM plus VEX plus identifier hygiene; signatures verified before install or admission |
| Containers | Rootless by default, syscall and filesystem confinement, verified images |
| Detection | A named set of host events emitted to the shared observability pipeline |

**Architectural question a graduate answers:** **given a host in this architecture, how would you prove that it is the machine the configuration describes, what authority does a compromised process on it acquire, and what evidence of that compromise does the architecture preserve?**
