==  Application and Software Supply Chain Security

*Goal:* students ship software whose architecture answers where trust boundaries, secrets, and origin live.

=== Secure coding discipline
- Input validation and canonicalization at trust boundaries
- Output encoding per context
- Parameterized queries
- Safe deserialization

=== Secrets management in applications
- Delivery patterns (env, mounted, SDK-fetched)
- sops + age for repo-safe config
- Vault dynamic secrets

=== Supply chain attestation
- sigstore (cosign, rekor, fulcio)
- in-toto attestation layouts
- Build provenance as release artifact
- xz/liblzma case study

=== Backstops (awareness)
- WAFs: ModSecurity as a backstop when architectural controls fail
- Pipeline gates as categories: SAST, SCA, IaC scanning, container scanning, pick one of each
- When backstops are appropriate and when their necessity signals architectural failure

*Architectural question a graduate answers:* *given this application, what are the trust boundaries, where do secrets live, how is origin established, what pipeline gates exist, and where does a WAF fit if one is needed?*

=== Application & Cloud Security
Securing software and the modern environments it runs in. Secure SDLC, DevSecOps, application security testing (SAST, DAST, fuzzing, package monitoring), common application attacks (SQL injection, XSS, CSRF, injection broadly), WAF and NGFW, sandboxing. Then cloud: service models (IaaS/PaaS/SaaS) with the shared responsibility matrix, deployment models (public, private, hybrid, multi-cloud, community), cloud-specific threats (CSA top concerns, misconfiguration, insecure APIs, weak control plane, limited visibility), CASB, SASE and SD-WAN, infrastructure as code and CI/CD pipeline security, supply chain vulnerabilities (including the SolarWinds pattern). Resilience and disaster recovery live here as well, high availability (load balancers, active/active and active/passive), redundancy (RAID, geographic dispersal), backups (full/incremental/differential, snapshots, replication), DR/BC (hot/warm/cold sites), and the shared responsibility question of who owns resilience at each service tier.

#pagebreak()
