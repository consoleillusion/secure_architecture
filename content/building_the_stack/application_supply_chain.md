---
cnl: sbvr
cnl-version: 1
cnl-scope: normative
lexicon: core-v1
lint: strict
---
# Application and Software Supply Chain Security

**Goal:** students ship software whose architecture answers where trust boundaries, secrets and origin live.

## Trust boundaries in the application

The network's encrypted mesh authenticates hosts and the identity layer authenticates principals. Neither can tell an application whether a particular input is safe to act on. That decision belongs at the application's trust boundaries, and it is where most application vulnerabilities live.

Four disciplines do most of the work. **Canonicalise input before validating it**, so that two different encodings cannot present one meaning to the validator and another to the consumer. **Encode output for the context in which it is used**, because the same string is safe in a URL and dangerous in HTML, SQL or a shell command. **Use parameterised queries** rather than assembling SQL from input. **Deserialise only trusted formats and only with type constraints**, since deserialisation is execution by another name. These are not checklists to run at release time; they are properties of the code's structure.

## Secrets in applications

A secret delivered as an environment variable is visible to anything that can inspect the process. A secret mounted as a file is visible to anything that can read that path. A secret fetched from a store by an SDK is visible to the identity of the caller, which is the better pattern because it makes the credential's lifetime and scope a property of the identity layer rather than of a deployment file.

For repository configuration, `sops` with `age` keeps values encrypted while allowing the file to be reviewed and version-controlled. For runtime secrets, the organisation's secret store issues them to a verified workload identity, as described in the identity chapter. The application should hold no long-lived static credential of its own. Where it must, that credential is a documented exception with rotation and monitoring, not an invisible default.

## Supply chain attestation

The xz/liblzma incident showed that a trusted upstream can be compromised long before a release reaches a consumer. Signature verification alone proves that a package came from a builder; it does not prove the builder was trustworthy. Provenance answers the second question.

Sigstore's `cosign` signs artifacts, Fulcio binds a signing key to an authenticated identity, and Rekor records the signature in a transparency log. In-toto attestations describe which steps produced an artifact and under what policy; SLSA levels describe how strong the resulting claims are. The build produces provenance as a release artifact, and the deployment system verifies it before accepting the artifact into the estate. The identity under which the build authenticates is the same identity model the rest of the course uses, so the trust path from "this build produced this artifact" to "this deployment will accept it" is an identity path, not a separate PKI.

This chapter owns producing attestation. The host chapter owns verifying it at install time. Both must reference the same artifact digest and the same trust anchor.

## Delivery, GitOps and pipeline security

The declarative host configuration described in the host chapter has to reach the hosts through a path whose integrity can be checked. GitOps is the pattern most suited to this: the desired state lives in version control, changes arrive as reviewed commits, and a controller makes the running state match. Signed commits and enforced tags make the author and the release boundary verifiable; branch protection and required reviewers make review a property of the repository rather than a request sent by email. Flux and Argo CD implement this for Kubernetes, where the important architectural distinction is pull versus push: a pull-based controller runs inside the target environment and fetches the desired state, so the environment does not need an inbound channel from the CI system, while a push-based deployment must carry credentials outward and therefore has a larger credential surface.

The pipeline itself is a production system and must be designed as one. Runners should be ephemeral and least-privilege, because a build that executes untrusted code on a long-lived runner with cached credentials is a foothold in the control plane. Workload identity federation through OIDC gives a job short-lived credentials for the cloud or secret store it needs, replacing long-lived secrets stored in CI variables. Artifact signing closes the loop: the identity that built the artifact signs it, the deployment verifies it, and the provenance is available to the host chapter's install-time checks. Hermetic builds — builds whose result depends only on declared inputs, without ambient network or toolchain state — are what make that claim reproducible rather than aspirational.

Immutable infrastructure patterns follow from the same commitment. A golden image is a base state that is built, verified and never edited in place; hosts are replaced rather than repaired. Blue/green deployment runs two complete versions and switches traffic, which makes rollback a traffic decision rather than a frantic rebuild. Canary deployment exposes a new version to a subset of traffic first, which turns rollout into a measured observation. Each pattern buys a different failure mode, and the choice should follow the service's RTO and the cost of a bad release rather than the fashion of the moment. The host chapter owns the declarative substrate; this chapter owns the path by which a change reaches it.

## Backstops, and what their use means

A WAF is a backstop: it filters requests at the edge when the application's own boundary handling is incomplete. ModSecurity is the open-source reference. Pipeline gates — SAST, SCA, IaC scanning and container scanning — are backstops of a different kind; pick one of each category rather than accumulating tools.

A backstop is appropriate when the cost of fixing every call site is genuinely higher than the residual risk it covers, or when protecting an application the organisation did not write. Its necessity is also a signal. If a WAF is the only thing preventing injection, the application's architecture is wrong and the WAF is compensating for a design failure. The architect records which backstops exist and what architectural defect each one is buying time on.

## Cloud and boundary relocation

Iaas, PaaS and SaaS shift responsibility but do not remove it. The shared-responsibility matrix names who patches the host, who configures the service and who owns the data; an organisation that assumes the provider owns all three has made an unstated trust decision. Deployment models — public, private, hybrid, multi-cloud and community — change where the boundary sits, not whether one exists. Cloud-specific failures are overwhelmingly misconfiguration, insecure APIs, weak control planes and limited visibility rather than exotic cryptography.

CASB, SASE and SD-WAN are often sold as ways to restore control over traffic that has left the network. They relocate the enforcement point; they do not restore the architectural property that an encrypted, authenticated endpoint can enforce for itself. Infrastructure as code and pipeline security are the controls that carry through every deployment model. Resilience and disaster recovery are owned by the resilience chapter, not by this one: putting them here is how they end up nobody's problem.

## What an architect decides at the application layer

| **Decision** | **The course's answer** |
| --- | --- |
| Trust boundaries | Named at every input and output, with canonicalisation and context-appropriate encoding |
| Data access | Parameterised queries; no assembled SQL or unsafe deserialisation |
| Secrets | Store-fetched with workload identity; repository secrets via `sops` and `age`; no static application credentials |
| Origin | Signed artifacts, in-toto provenance and a transparency log; verified at deploy and at install |
| Delivery | Reviewed commits in version control; pull-based GitOps where the platform supports it; signed releases |
| Pipeline | Ephemeral least-privilege runners, OIDC federation, hermetic builds and artifact signing |
| Release pattern | Golden images with replacement rather than in-place edits; blue/green or canary chosen from the RTO and rollback cost |
| Backstops | One gate per category; WAF only where it is an explicit, documented backstop |
| Cloud responsibility | Documented per service tier; identity and configuration remain the organisation's concern |
| Resilience | Owned by the resilience chapter; referenced here as a consumer of application state |

**Architectural question a graduate answers:** **given this application, what are its trust boundaries, where do its secrets live, how is its origin established, what pipeline gates exist, and where does a WAF fit if one is needed?**
