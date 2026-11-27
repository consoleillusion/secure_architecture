---
cnl: ace
cnl-version: 1
cnl-scope: hybrid
lexicon: core-v1
lint: strict
secondary-cnl: ste
---
# Cryptography & Data Security

**Goal:** To make confidentiality a property of key ownership rather than of network location or storage state, and to make every point where plaintext exists an explicit, justified decision.

## Two kinds of data protection

Data protection uses two mechanisms. **Software security** relies on an authorisation protocol: an operating system, database or application decides whether a party may read, and the difficulty of forging that decision is the control. **Cryptographic security** relies on a hard problem: data is encrypted so that possession of the ciphertext is not possession of the information, whatever the storage system believes.

Every system implements the first mechanism to some degree. Even a system with open access is applying a rule that says access is open, and a robust implementation can add multi-factor authentication to make the decision harder to forge. But authorisation only governs data while it remains inside the system that holds it. A database dump, a stolen drive, a backup tape or a log file is readable by whoever obtains it, regardless of how good the authentication was at the front door.

Cryptography extends the guarantee beyond the authorisation protocol: a party who obtains the bytes without the key learns nothing. Neither mechanism, however, protects data from the endpoints that legitimately hold the key. If the producer is compromised, the attacker encrypts on behalf of the producer; if the consumer is compromised, the attacker decrypts on behalf of the consumer. A key logger on a laptop, malware running under the user's account, a malicious browser extension, or a backdoored client build bypasses the cryptography without breaking it by stepping inside the boundary it defines. That boundary — the set of parties that can legitimately decrypt — is the trusted computing base for the data, and it is the subject of this chapter.

## States, boundaries and controllers

Compliance discussions usually organise data protection around three states: **data at rest**, **data in transit** and **data in use**. Each gets its own controls — disk encryption for rest, TLS for transit, memory protection or confidential computing for use — and an architecture that ticks all three boxes is declared to have covered its obligations.

The three states are a useful taxonomy of where data lives. They are a poor organising principle for data security because they leave two things unstated: the transitions between states, where most real exposure occurs, and the identity of the controller who holds the key in each state, which determines the threat model that actually applies.

### Where plaintext appears

Data in a modern system does not sit quietly in one state. A request arrives over TLS, is terminated at a load balancer, is handed in plaintext to a WAF for inspection, is re-encrypted onward to an application, is written in plaintext to a log shipper, is buffered in a queue, is cached by a CDN, is serialised for a message bus, is written to disk in a format a DLP agent can scan, is paged out to swap, and is captured in a core dump when a process crashes. Every one of these is a boundary at which plaintext becomes available to a new component, with its own credentials, attack surface and operational team.

The attack surface at a handoff is frequently larger than at either endpoint. A TLS-terminating appliance holds plaintext, the private key and the onward credentials simultaneously. A logging pipeline often sees more plaintext than the application that generated it, stores it longer, controls it more weakly and replicates it more widely. A DLP agent that scans for sensitive data necessarily sees that data unencrypted: the control designed to prevent leakage becomes a new place leakage can occur. Each is a deliberate choice to decrypt somewhere in the middle, and each is invisible to a checklist that only asks about the states at the ends.

### Who holds the key

The three-state model also obscures who can decrypt. Each state has, in practice, a different controller with a different threat model. "Encryption in transit" via TLS usually means the server holds the key, so the excluded adversary is a network observer. "Encryption at rest" via full-disk encryption usually means the running operating system holds the key, so the excluded adversary is someone with a stolen drive; once the volume is mounted, FDE offers no defence against a compromised process, a malicious insider with shell access or a backup agent. "Encryption in use," where it means anything at all, means an OS and a ring of trusted services hold the key, and that ring is usually larger than the architect realises.

Data can therefore be "encrypted at rest, in transit and in use" and still be readable by every component along the path. The useful framing is **scope** — the set of parties who hold the key — and **crossings**, the points at which the scope changes and a new controller takes over. The question is not "is this data encrypted in each state?" but "who holds the key at each point from producer to consumer, and is each controller within the trust boundary I intended?" That question finds the load balancer, the CDN, the log, the DLP appliance, the kernel and the swap file, because each is a controller that can decrypt and each must be justified or eliminated.

End-to-end encryption is categorically different, not merely better. The key exists outside every intermediate system on the path. The load balancer, log shipper, CDN and application server cannot decrypt; there is one controller at the producer and one at the consumer, and the intermediary is untrusted by assumption at every point. The scope does not change across states, so the threat model does not have to either.

## The reach and limits of cryptography

Where a key is held outside every intermediate system, those systems are structurally excluded from the set of parties that can read the data. Compromise of a load balancer, log shipper, CDN, message bus, operating system or hypervisor no longer implies compromise of the data they carry. This is a strong and achievable guarantee: it shrinks the set of components that must be trusted from "every system the data passes through" to "the two endpoints that legitimately hold the key."

It is not a total guarantee. Cryptography does not eliminate the need for host integrity, attestation, least functionality and supply-chain discipline; it confines them to the endpoints where they actually have to work. Those endpoints are smaller, more auditable and more tractable than the whole path. An architecture that claims more than this has confused the guarantee with the system that implements it.

## Why end-to-end encryption is rare

If the guarantee is this strong, the obvious question is why it is not the default. The answer is that it has costs, and most architectures have reasons to avoid paying them.

**Implementation difficulty.** TLS and full-disk encryption are effectively free to the application developer because operating systems, browsers and filesystems provide them. End-to-end encryption has to happen at the client, before data leaves the user's control, so the application must generate keys, manage them, encrypt and decrypt without help from the transport layer or the kernel. There is no standard system call for "encrypt this to my contact's key." Most applications decline to build that machinery.

**Loss of operator control.** An operator who cannot read customer data cannot scan it for abuse, search it to improve the product, show it to support staff, or hand it to advertisers, data brokers and analytics partners. Business models that depend on access to customer data are incompatible with architectures in which the customer holds the only key. The encryption is declined for commercial reasons, not technical ones.

**Obligations and legal constraints.** In some jurisdictions providers can be compelled to produce customer data under lawful process, and an architecture that renders the provider incapable of producing plaintext conflicts with that obligation. The regimes differ by country, sector and data class, and some impose restrictions on encryption itself. The architect in a regulated environment must establish which regime applies and take local advice rather than assuming a universal rule.## Architectural rules

- Every data class shall have a named boundary.
- Every key shall have a custody owner and a rotation path.
- Every stored secret shall remain outside the application image.
- Every cryptographic failure shall terminate the operation.

[^lawful-access]

**Availability.** If the only party holding the key loses it, the data is unrecoverable. Forgotten passphrases, lost devices and failed backups become permanent loss rather than support tickets. In an architecture where the key lives outside the processing system, that system cannot help, because helping would require holding the key the architecture exists to keep out of its reach.

None of these costs is insurmountable. Recovery does not have to mean that the user is on their own; the requirement is that recovery material lives in a separate process from the system that processes the data. It can be held by the user, escrowed in a hardware security module under a different team's control, split across a key-management service on isolated infrastructure, sharded among trusted custodians, or placed with an external escrow provider. What matters is separation: different process, different host, different credentials, different operational team, and often different jurisdiction. If the recovery key sits on the same host, under the same credentials and operated by the same team, the controller the architecture removed has been quietly reintroduced.

The cost that remains is key management, which is not an implementation detail but the hard part. Where does the master key come from? How is it derived, backed up and rotated? What happens when a device is lost, stolen or sold, or when a user dies? How are new devices enrolled and old ones revoked? How is a corrupted backup distinguished from a tampered one? Who authorises a recovery event, and how is that authorisation audited? Every answer has trade-offs, and the architecture must choose deliberately rather than by default. A design that gets the cryptography right and the key management wrong is not a secure design; it fails in a more embarrassing way.

The three states remain useful as descriptive categories. The argument is against them as an *organising principle*. Organised around states, the architect asks whether each state is protected and gets a compliance report. Organised around boundaries and controllers, the architect asks where plaintext exists, who holds the key, what threat model each controller assumes, and whether that trust is justified. Only the second question produces a consistent trust model across the whole data path.

## The stack at this scale

The course uses a small set of primitives rather than a product category. Each one has a narrow, stated purpose:

| **Concern** | **Primitive** | **What it does and does not provide** |
| --- | --- | --- |
| Host storage | LUKS2 with TPM2 unlock or a key file, expressed in the host's declarative configuration | Protects media removed from the host; offers nothing once the volume is mounted and the OS is running |
| Backups and archives | `age` for new deployments; GPG where interoperability requires it | Encrypts before data leaves the host; keys must not live on the backup target |
| Transport | TLS 1.3 everywhere, mTLS where the client identity matters | Protects the hop; the terminating endpoint still holds plaintext unless the application adds end-to-end encryption |
| Host-to-host | The WireGuard mesh already described in the network chapters | Carries encrypted IP between hosts so the underlay is only a carrier |
| Application data | `age`/GPG for files, and established protocols for messaging | End-to-end only if the key never enters the processing system |
| Key custody | Offline root, online issuing CA, HSM or isolated secret store, narrow authenticated interface | Separates recovery from processing; see the Identity, PKI and Zero Trust chapter for certificate issuance and revocation |

Two rules follow. First, the organisation does not invent cryptography: it composes reviewed primitives with conservative parameters and lets specialists break the mechanisms. Second, encryption is only as strong as the key's location. A key in the same cluster, under the same credentials, as the data it protects is not a separate control.

Classification — deciding which data needs which scope — is a governance decision, not a cryptographic one, and is treated in the governance chapter. At this scale a small taxonomy is enough: **public**, **internal**, **confidential** and **restricted**, each with a stated rule about who may hold the key and where plaintext may appear. Without that input, the architect cannot size the control, and every dataset gets the same expensive treatment or the same dangerous default.

## What an architect decides at the data layer

| **Decision** | **The course's answer** |
| --- | --- |
| Key ownership | Name the parties that can decrypt at each point; intermediate infrastructure is not among them by default |
| Plaintext locations | Enumerate every handoff where plaintext appears and justify or remove each one |
| End-to-end versus provider-held keys | End-to-end where the operator does not need content; document the commercial or legal reason where it is declined |
| Recovery separation | Recovery material in a different process, host, credential domain and team from the processing system |
| Host storage | LUKS2 on managed hosts, unlocked by TPM2 or a secret store, with the limitation explicitly accepted |
| Backups | Encrypted before transfer, with keys held outside the backup target and restore tested regularly |
| Primitives | Reviewed, standard primitives only: TLS 1.3, WireGuard, `age`/GPG, AES-GCM, Ed25519; no bespoke designs |
| Rotation and revocation | Short certificate lifetimes, scheduled key rotation, a tested device-offboarding path, and audited recovery events |
| Classification | Four simple classes with explicit rules about key scope and plaintext locations |

The resulting architecture treats encryption as a way to shrink trust, not as a box to tick. It can state, for any dataset, who holds the key, where the plaintext is, and what must be compromised to read it. If it cannot answer those questions, the data is not protected by the architecture — it is protected by the hope that nothing goes wrong.

[^lawful-access]: Legal obligations and restrictions vary by jurisdiction and sector; this is a design constraint to be established with qualified local advice, not a technical default.
