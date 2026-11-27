---
cnl: ste
cnl-version: 1
cnl-scope: narrative
lexicon: core-v1
lint: light
---
## Appendix: Ports and Protocol Numbers

Port numbers are useful shorthand, not security controls. A default-deny policy still has to decide which service on which host is allowed to speak to which peer. This appendix collects the numbers used in the course so that firewall rules and captures can be read without guessing.

| **Port** | **Transport** | **Service** | **Security note** |
| --- | --- | --- | --- |
| 20, 21 | TCP | FTP data and control | Plaintext credentials; avoid in favour of SFTP or HTTPS-based transfer |
| 22 | TCP | SSH, including SFTP as a subsystem | Key-based authentication and mTLS-style host verification where possible |
| 23 | TCP | Telnet | Plaintext; should never be enabled on managed infrastructure |
| 25 | TCP | SMTP between mail servers | Use TLS, SPF, DKIM and DMARC; submission uses 587 or 465 |
| 53 | UDP/TCP | DNS | Queries may be encrypted with DoT/DoH; validate DNSSEC at the resolver |
| 67, 68 | UDP | DHCP server and client | Bind to the intended interface; DHCP snooping at Layer 2 |
| 69 | UDP | TFTP | Unauthenticated; restrict tightly if unavoidable |
| 80 | TCP | HTTP | Redirect to HTTPS; do not carry credentials or session tokens |
| 110 | TCP | POP3 | Prefer IMAP over TLS |
| 123 | UDP | NTP | Authenticate time sources; time is a dependency of certificate validation |
| 143 | TCP | IMAP | Use TLS |
| 179 | TCP | BGP | Authenticate sessions; filter routes at the boundary |
| 389, 636 | TCP | LDAP, LDAPS | Use TLS and a service account with scoped rights |
| 443 | TCP/UDP | HTTPS (TCP) and HTTP/3 (QUIC, UDP) | Application encryption terminates at the endpoint; no midpoint inspection |
| 465 | TCP | SMTPS submission | Implicit TLS submission |
| 500, 4500 | UDP | IKE and NAT-T for IPsec | ESP itself is IP protocol 50, not a TCP/UDP port |
| 587 | TCP | SMTP submission | STARTTLS submission; authenticated |
| 853 | TCP | DNS over TLS | Alternative to DoH for encrypted host-to-resolver DNS |
| 995 | TCP | POP3 over TLS | Prefer IMAP |
| 161, 162 | UDP | SNMP and SNMP traps | Use SNMPv3 authentication and privacy |
| 1812, 1813 | UDP | RADIUS authentication and accounting | 802.1X backend; restrict to network devices |
| 49152–65535 | TCP/UDP | Ephemeral and dynamic RPC ranges | Pin service RPC ranges explicitly where firewalls must allow them |
