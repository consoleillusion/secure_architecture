# Identity, PKI and Zero Trust

**Goal:** To make identity the substrate every other layer authenticates against — centralised, operated as code, recoverable and cross-platform by construction.

The earlier chapters have, between them, established that the network
cannot be the trust boundary, that the host cannot be the trust
boundary, and that the application cannot answer "is this caller
allowed to do this thing" without a credible answer to "who is this
caller in the first place." Identity is what supplies that answer. It
is the substrate the rest of the architecture sits on. Every
authorisation decision the application chapter described, every mTLS
connection the network chapter described, every encrypted volume the
host chapter described, and every key the cryptography chapter will
describe, ultimately resolves back to a question about identity: who is
the principal making the request, and how confident is the system in
that identification.

For a small-to-medium business, the temptation is to leave identity
distributed. Every application has its own user database. Every server
has its own local accounts. Every SaaS subscription is a fresh signup.
This is the path of least immediate resistance and the path of greatest
eventual cost. The cost shows up in three ways. It shows up
operationally, when an employee leaves and a person has to remember
every system that needs an account disabled, and forgets one, and
months later the forgotten account is the path the attacker uses. It
shows up architecturally, when the organisation cannot answer "who has
access to what" without a multi-day inventory project. And it shows up
during an incident, when the response team needs to revoke a credential
in twenty places at once and the systems do not share enough structure
to let them.

The architecture-first answer is the same as it has been at every other
layer. The capability that is going to be exercised across the entire
estate is built once, centrally, on infrastructure the organisation
controls, and every system that needs identity federates to it rather
than carrying its own copy. The cost of building that substrate well is
real. The cost of not building it is greater, and is paid quietly, in
parts of the system that will not signal their own decay.

## Why identity is the new perimeter

The phrase **identity is the new perimeter** is repeated often enough to
be suspicious of, but it is repeated because it describes something
that has actually happened. The older model of network security, in
which a firewall at the edge of the corporate network divided the
trusted interior from the untrusted exterior, was already in decline by
the late 2000s and is now structurally finished. Three forces
dismantled it. Cloud and SaaS moved the applications outside the
network the firewall could enclose. Mobile devices and remote work
moved the users outside it. And lateral movement inside flat internal
networks made the interior less trustworthy than the model had assumed.
What replaced the perimeter, in any architecture that is actually
defensible, is identity. Each request is authenticated, each
authentication is contextualised, and the network's role contracts to
delivering bytes between authenticated endpoints rather than deciding
which endpoints are allowed to talk.

This is what the introduction has been pointing towards. The principle
of **complete mediation**, that every access to every object is checked
every time, has no meaningful implementation if the check happens at a
network boundary the request never crosses. It has to happen at the
service, against a credential, on each call. The principle of **least
privilege** has no meaningful implementation if "privilege" is a
property of which network the request came from rather than which
principal is making it. **Fail-safe defaults**, which require that the
absence of an explicit grant means the access is denied, has no
meaningful implementation if the grant is encoded in firewall rules
that happened to leave a port open. The principles all need a place
where the answer to "who is this, and what are they allowed to do" can
be evaluated, and that place is the identity layer.

What an identity layer that takes its job seriously provides is small,
but it is not optional. It provides a way to authenticate a principal,
human or service, with a credential strong enough that the failure
modes are understood. It provides a way to express, in one place,
which principals are allowed to do which things. It provides a way to
revoke a credential or a permission and have that revocation propagate
to every system that consumes the identity. And it provides an audit
record sufficient to answer, after the fact, what a principal actually
did. The four properties together are what the rest of the architecture
is implicitly assuming when it says "the application enforces
authorisation" or "mTLS authenticates the caller." If the identity
substrate does not exist, those statements are aspirational. If it
does, they are operational.

## Authentication, authorisation, and accounting

The familiar acronym AAA conceals a discipline that organisations
routinely fail. The three are different, and the failures of each take
different shapes.

**Authentication** is the question of who the principal is. It produces
a verified identity from a credential. The credential might be a
password, a hardware token, a TLS client certificate, a Kerberos ticket
derived from a prior authentication, an OIDC ID token issued by an
identity provider, or any of several other shapes. What unites them is
that the credential is something the principal possesses and the
verifier can check, with a process that produces high confidence the
principal is who they claim to be and low probability that an attacker
can forge the result. The properties that matter are the ones the
authenticator section will treat in detail: resistance to phishing,
resistance to credential reuse, resistance to credential theft from a
compromised endpoint, and the binding of the credential to a specific
device or person rather than a string that anyone can replay.

**Authorisation** is the question of what the authenticated principal
is allowed to do. It is a separate question, and the application
chapter has already insisted that it has to be answered in the
application, with the application's own knowledge of what its objects
are and what its operations on them are. The identity layer's role in
authorisation is supplying the inputs the application needs: the
identity itself, the groups or roles the identity belongs to, and any
attributes the application's authorisation logic depends on. The
identity layer is not the authorisation engine. It is the source of
truth that the authorisation engines, plural, in each application
consult.

**Accounting** is the question of what the authenticated principal
actually did. It produces an audit trail. It is the property that
makes the other two falsifiable: an authentication that was claimed but
did not actually happen will leave the wrong shape in the audit record;
an authorisation that was granted but should not have been will be
evident in the access log if the log is being read. The accounting
function is what feeds the observability pipeline the next chapters
will develop, and it is the function organisations are most likely to
under-invest in, because it produces no immediate operational benefit
until the day someone has to reconstruct an incident from the records.

The discipline of separating these three is what the rest of the
chapter is built on. An identity provider that conflates them, that
treats authorisation as a property of the credential rather than a
decision the consuming application makes, ends up with a model in
which giving someone any access requires giving them potentially too
much, and revoking access requires editing the credential rather than
the access policy. The right structure has the credential prove who
the principal is, has the application decide what the principal can do,
and has both authentication and authorisation events appear in the
audit log with enough detail to reconstruct what happened.

## The protocol landscape

The protocols that carry identity across an organisation are a smaller
set than the application catalogue might suggest. Five matter. Two
others are sometimes encountered.

**LDAP**, the Lightweight Directory Access Protocol (RFC 4511), is the
oldest of the protocols still in mainstream use. It defines a
hierarchical directory, a query language for it, and a set of
operations: bind, search, add, modify, delete. The directory's
structure, distinguished names, attributes, object classes, comes from
the X.500 lineage and is older than the web. Despite its age, LDAP is
the protocol most identity stores still speak natively, and most
applications that need to consume identity from a central source still
have an LDAP client. SASL, treated in the network chapter, provides
the authentication framework LDAP rides on; **LDAP over TLS** (LDAPS,
or LDAP with StartTLS) provides the encryption. The architectural
fact about LDAP is that it is a directory protocol, not an
authentication protocol. The identity store answers queries about
principals. The principals authenticate using something else, often
SASL with an underlying mechanism, to bind to the directory and
demonstrate that they are who their entry says they are.

**Kerberos** (RFC 4120) is an authentication protocol, distinct from
LDAP and considerably more interesting. It uses tickets issued by a
central authority, the Key Distribution Center, to let a principal
prove its identity to a service without sending its password to the
service. The principal authenticates once to the KDC, receives a
ticket-granting ticket, and uses that to obtain service tickets for
each resource it wants to access. The properties this gives are
significant. The principal's password never traverses the network to
the service. The service can verify the ticket without contacting the
KDC on every request. The ticket has a lifetime, after which it has to
be renewed. The authentication is mutual, the service proves to the
client that it is the right service, not just the other way around.
And the ticket can be presented to any service in the realm, which is
where **single sign-on** comes from in the Kerberos sense: not a
slogan, but a protocol property, the ticket-granting ticket is the
credential the user holds, and every subsequent service request is a
ticket exchange the user does not see.

Kerberos's reputation as difficult is somewhat earned. It is sensitive
to time skew, because tickets are timestamped and the validation
window is small. It depends on DNS, because services are identified
by their service principal names, which are derived from hostnames.
And it has historically been hostile to NAT, because tickets were once
bound to client IP addresses, though modern Kerberos is more flexible
about this. None of these are reasons to avoid it. They are reasons to
deploy it on infrastructure the organisation actually controls,
including its DNS, its time source, and its hostnames. When that
control is real, Kerberos is the authentication protocol with the
strongest properties in widespread deployment, and the one that
underlies most of what an organisation actually means when it says it
has single sign-on for its internal systems.

**OpenID Connect** (OIDC) is the modern authentication layer for
HTTP-based applications. It is built on top of OAuth 2.0 (RFC 6749),
which is itself an authorisation framework rather than an
authentication protocol, and it resolves the various ways OAuth had
been misused for authentication into a standard. An OIDC flow
typically looks like this: the user visits an application, the
application redirects them to the identity provider, the user
authenticates to the identity provider using whatever method the
identity provider supports, the identity provider redirects them back
to the application carrying an ID token, and the application validates
the ID token and considers the user authenticated. The ID token is a
JWT, signed by the identity provider, containing the user's identity
and a small set of claims about them.

OIDC's strength is that it is the protocol the modern web speaks. New
applications nearly always support it. Federation across organisations
is straightforward. The protocol itself, when implemented correctly
with PKCE for public clients and short-lived tokens, is solid. The
weakness is that the implementation correctness has historically been
where vulnerabilities live: open redirector flaws, token validation
shortcuts, confused-deputy patterns when the authorisation token gets
treated as authentication, missing audience checks. The protocol is
fine; the implementations vary. The architectural answer is to use a
small number of well-maintained client libraries and to federate
through a single identity provider so that the protocol's edges are
exercised in one place rather than reinvented in each application.

**SAML 2.0** is the older federation protocol, predating OIDC by about
a decade and built on XML. It is still everywhere in the enterprise
SaaS world, because the SaaS vendors implemented it first and have
not, in many cases, moved on. An organisation that is going to use
SaaS is going to encounter SAML, and the identity provider has to be
able to issue SAML assertions whether the architect prefers OIDC or
not. The protocol is more complicated than it should be, the XML
canonicalisation that the signatures depend on has been a source of
implementation flaws, and the spec leaves too many things underspecified
for two implementations to be confident they will interoperate without
testing. None of this changes the practical position: SAML is the
protocol the IdP has to speak when federating to many existing
applications, and the architectural decision is which IdP to run, not
whether the IdP supports SAML.

**SCIM**, the System for Cross-domain Identity Management (RFCs 7643
and 7644), is the protocol for provisioning and deprovisioning users
and groups across systems. It is the answer to the question of how
the identity provider's record of who is in the organisation propagates
to the applications that need to know. Its support is uneven, modern
SaaS tends to support it, older applications often do not, and the
applications that do support it often support different subsets of the
spec, but where it is available it is the right answer. It is the
mechanism that makes the deprovisioning case actually work: when an
employee leaves and the identity provider records them as terminated,
SCIM is what propagates that to every application before someone has
to remember to log into each one and disable the account.

The two others worth mentioning are **GSSAPI** and **PAM**. GSSAPI,
already discussed in the network chapter, is the API surface through
which application protocols hook into Kerberos. SSH, NFS, SMB, LDAP,
and several others all support GSSAPI authentication, and where the
organisation has Kerberos infrastructure, GSSAPI is how the
applications use it. **PAM**, Pluggable Authentication Modules, is
the framework Linux systems use to plug authentication into the
operating system itself: login, sudo, ssh, and most other things that
ask for credentials on a Linux host go through PAM. PAM is where the
identity layer terminates on the host, and where the host's local
account model meets the central directory. A small business that has
done identity correctly will have PAM configured to consult the
central directory for authentication and the central directory's
group memberships for authorisation, with local accounts reserved for
the cases where central authentication is structurally unavailable,
recovery accounts, the bootstrap before the directory exists, and a
small number of system accounts that should not be in the directory.

## What an identity system has to be, structurally

The protocols are the means; the properties below are the commitment. They are stated once, as decisions, at the end of this chapter. In short: the directory is a single source of truth; users, groups and policy are described in version control; every authentication and administrative action is logged; the directory and its keys are backed up and restoration is tested; the provider speaks the protocols the organisation's clients actually require; and the whole stack is reachable from the encrypted mesh while only federation endpoints face the internet. The sections that follow explain how each is achieved.

## Choosing a stack at the small-business scale

The open-source landscape for identity is mature enough that an
organisation does not have to compromise on these properties. It does,
however, have to make a deliberate choice among stacks that are good at
different things. The choice depends on what kinds of clients the
organisation actually has and what kinds of applications it actually
runs.

**Keycloak** is the most general of the options. It is an OIDC and
SAML identity provider, federation-capable, with strong support for
the protocols modern web applications speak. It can sit in front of
an LDAP backend, including one of the dedicated LDAP servers below,
or use its own user database. It is the right default for an
organisation whose applications are mostly HTTP-based, whose user
authentication is mostly browser-based, and whose Windows or Linux
host integration is light enough that LDAP-via-Keycloak suffices for
the few cases where it matters. The cost is that Keycloak is heavier
than its lightest competitors and the configuration model is large.

**Authentik** is the lighter alternative in the same niche. It speaks
OIDC and SAML. It has a smaller surface than Keycloak and a more
focused configuration model. For organisations whose use cases are
within its capability set, which covers most browser-based federation,
it is easier to operate. The trade is a smaller community and fewer
edge cases handled out of the box.

**FreeIPA** is the answer for organisations whose primary problem is
authenticating Linux hosts. It bundles a 389 Directory Server LDAP
backend, an MIT Kerberos KDC, a Dogtag certificate authority, BIND for
DNS, and SSSD on the client side, into a stack that is genuinely
integrated rather than a directory plus a Kerberos plus a CA running
side by side. For Linux-heavy estates it is the strongest option in
the open-source landscape. Its weakness is Windows integration: it can
do cross-realm trust to a Windows domain, but the configuration is
non-trivial, and an organisation whose users primarily authenticate to
Windows endpoints will spend more effort here than it would in the
next option.

**Samba Active Directory Domain Controller**, the subject of the
practical section below, is the answer for organisations whose primary
problem is the inverse: Windows clients that need to join a domain,
SMB file shares that need to authenticate domain users, and a need
for the Active Directory protocol behaviour that a wide range of
existing applications, particularly older or Windows-targeted ones,
expect to find. Samba AD DC implements the AD protocols, including
LDAP, Kerberos, DNS, and the Microsoft-specific RPC interfaces, well
enough that Windows clients join it as they would a Microsoft domain
controller, and Linux clients join it through SSSD using the same
mechanism they would use for a real AD domain. The result is a single
identity system that authenticates Windows, Linux, and macOS clients
without an integration layer between them. Where the organisation also
needs OIDC and SAML for browser applications, a Keycloak or Authentik
in front of the Samba LDAP provides the federation layer.

**Vendor-hosted identity** is the path most small businesses take
without thinking about it. Microsoft Entra ID, Google Workspace,
Okta, JumpCloud. These are not bad products. They are well-engineered
and they reduce the operational burden meaningfully. The trade is the
one the introduction's Parkerian Control discussion described: the
organisation is handing the most sensitive single function in its
architecture to a vendor whose internal behaviour is opaque to it,
whose availability decisions are not under its control, and whose
relationship with state-level demands for access is governed by a
jurisdiction the organisation may not have chosen. For some
organisations the trade is reasonable. For others it is not. The
architecture-first answer is to make the trade explicitly, with the
control loss accounted for, rather than to default into it because
signing up for the vendor was easier than running the open-source
stack.

The choice of which open-source stack, where the organisation has
decided to self-host, comes down to where the centre of gravity of the
authenticator population is. An estate that is mostly Windows, with
SMB file shares and domain-joined endpoints as load-bearing parts of
how people work, is best served by Samba AD DC, with browser
federation layered on top through Keycloak when it becomes necessary.
An estate that is mostly Linux, with engineers SSHing into hosts,
authenticating to git servers, and consuming Kerberos-aware services
internally, is best served by FreeIPA. An estate whose centre of
gravity is browser applications and SaaS, where the host operating
system is incidental and the question of "is this user logged in" is
mostly a question of whether they have a valid session at the IdP, is
best served by Keycloak or Authentik directly. The remainder of this
chapter develops the Samba AD DC case in detail, because it is the
choice that handles the cross-platform problem most directly and
because it is the option most likely to be underestimated by an
architect who has only thought about identity in browser terms.

## Authenticators

The protocols are the means of carrying authentication. The
authenticators are what the user actually presents to authenticate.
The choice of authenticator is the security-architectural decision
that has the largest practical impact on the organisation's resistance
to credential-theft attacks, and it deserves treatment separate from
the protocol catalogue.

**Passwords**, the default authenticator, have a worse reputation than
they deserve and a better one than they deserve, depending on how they
are used. NIST SP 800-63B in its current revision has, helpfully,
discarded most of the password rules that produced no security and
considerable user frustration. Forced rotation on an arbitrary
schedule is gone. Forced character-class composition rules are gone.
Knowledge-based recovery questions are gone. What remains is
straightforward: passwords should be long, at least eight characters
and ideally considerably longer; they should not be on the lists of
passwords known to be compromised; they should not be the same as the
user's other passwords on services the verifier can plausibly check;
and their entropy should come from length and unpredictability rather
than from rules that produce predictable patterns. A passphrase of
four or five unrelated words is stronger than the eight-character
password with a special character that the older rules used to
require, and a user is more likely to remember it correctly.

The architectural problem with passwords is not the rules. It is that
the password, as a credential, has to be presented to the verifier,
and any verifier that receives the password is in a position to log it
or leak it. The password is also reusable, which means that if it is
intercepted once, it can be replayed indefinitely until the user
changes it. And the password is phishable, which means that an
attacker who can convince the user to type the password into a fake
verifier obtains it as readily as the real verifier does. None of
these properties can be fixed at the password layer. They are
properties of "the credential is a string the user knows."

**TOTP**, time-based one-time passwords (RFC 6238), help with replay,
since the value changes every thirty seconds, but do not help with
phishing, since a fake verifier can collect the current TOTP value at
the same time as the real one. They also do not help with verifier
compromise, since the seed value the TOTP is computed from is shared
between the user's authenticator app and the verifier, and a verifier
compromise yields the seed. TOTP is a step up from passwords alone,
but it is not the strong authentication that an architecture aiming
at something defensible should treat as sufficient.

**Push-based MFA**, the kind that sends a notification to the user's
phone asking them to approve a login, is worse than TOTP for the case
that matters. Push fatigue, the phenomenon of users approving prompts
they did not initiate because they receive too many of them, has been
the proximate cause of several high-profile breaches. The user receives a
prompt, the user approves it because that is what users do with
prompts, and the attacker is now logged in. The mechanism's safety
relies on the user's vigilance at exactly the moment the user is least
attentive.

**WebAuthn and FIDO2** are what the architecture should actually be
deploying. The credential is a key pair, generated on a hardware token
or in a hardware-backed enclave on the user's device, with the private
key never leaving the hardware. The authentication is a challenge
signed by the private key, where the signed client data includes the origin of
the verifier the user is actually authenticating to, alongside the random challenge. This is the property that makes WebAuthn phishing-resistant: a fake verifier on a
different origin cannot make the user's authenticator produce an assertion
the real verifier will accept, because the origin recorded in the signed
client data will be wrong. The credential is also unique per service,
which means that a verifier compromise does not yield a credential
reusable elsewhere, and it is bound to the hardware, which means that
stealing the credential requires stealing the hardware. The WebAuthn
deployment story has matured in the last several years to the point
that the option is genuinely available: most browsers support it, most
identity providers support it, and hardware tokens are inexpensive
enough that an organisation can issue one to every employee.

The architectural commitment is straightforward. **WebAuthn for
human authentication, with hardware tokens as the primary
authenticator and a platform authenticator (TPM-backed on Windows,
Secure Enclave on macOS, hardware-backed keystore on Android) as the
fallback for routine use.** Passwords as the bootstrap during
enrolment and as the recovery path that goes through a controlled
out-of-band process. TOTP grudgingly accepted for the dwindling
population of services that do not yet support WebAuthn, with an
explicit migration plan. Push notifications avoided. SMS-based
authentication avoided entirely, because SMS is a protocol the
organisation does not control and SIM-swap attacks are within the
threat model of any business worth attacking.

For machine authentication, the equivalent commitment is **mTLS or
SPIFFE-style workload identities**, developed in the PKI section below: long-lived static
credentials are not used for service-to-service authentication. The
service holds a short-lived certificate or token that is renewed
automatically by the identity infrastructure, and the renewal failure
is a detectable event rather than a silent expiry.

## Secrets, signing, and the identity layer's wider scope

The identity system authenticates principals. It is not the system
that holds the secrets the principals consume. The two functions are
related but separate, and the secrets-management substrate is what
holds API keys, database credentials, certificate private keys, and
the other material that applications need but should not have hard-
coded.

**Infisical** is the open-source option for the secrets-management
role. **HashiCorp Vault** is also covered here because it is widely deployed,
but since version 1.15 it has shipped under the Business Source License
rather than an open-source licence: an organisation committed to
verifiable, open-source primitives must account for that explicitly.
Both products store secrets encrypted at rest,
issue them to authenticated callers under policies that decide who can
read what, audit every access, and support the rotation of secrets
either through their own machinery or through integration with the
systems the secrets authenticate to. The integration with the
identity provider is the load-bearing piece: an application
authenticates to Vault using its workload identity, which Vault
verifies against the identity provider, and Vault returns the
secrets the application is authorised to read. The application never
has a static credential of its own. The credential it presents to
Vault is the workload identity issued by the identity layer, which is
short-lived and renewed automatically. The credentials Vault returns
are themselves typically short-lived, brokered through Vault's
dynamic-secrets machinery for backends that support it.

**Signing**, the cryptographic side of identity, is what binds
artifacts to the principals that produced them. Sigstore and cosign
provide the open-source pipeline for this in the software-supply-chain
context: a build produces an artifact, the artifact is signed with a
key tied to the build's identity at the identity provider, and the
deployment system verifies the signature before accepting the artifact
into the running estate. The host chapter has already touched on this;
the identity-layer fact is that the identity the build authenticates
under is the same identity model the rest of the architecture uses,
and the trust path from "the build produced this" to "the deployment
will accept it" is the identity layer's credential.

**Rotation discipline** is the operational property that ties the
secrets and signing material to the identity it represents. A
credential that does not rotate accumulates risk over time: more
copies, more places it has been logged, more chances it has been
captured. The architectural commitment is that every credential has a
defined lifetime and a defined rotation procedure, both of which are
implemented in the infrastructure the credential lives in rather than
documented in a runbook nobody reads. Where this is operationally
infeasible, the credential's existence is a known weakness, treated
the way the architecture treats other known weaknesses: with explicit
acknowledgement, monitoring sufficient to detect compromise, and a
plan to eliminate the credential rather than continue to manage it.

## PKI: issuing and revoking identity

A directory answers "who is this principal?" A public-key infrastructure answers a different question: "what cryptographic proof do we have of that identity, and for how long?" Without an answer to the second question, mTLS, signed artifacts and workload identity all rest on manually copied keys, which is the same as no identity at all.

**CA hierarchy.** The root CA is generated offline, stored with the recovery material described in the cryptography chapter, and brought online only to sign or replace an issuing CA. The issuing CA is online, automated and short-lived; it is the only key a day-to-day issuance system needs. Compromise of an issuing CA is a serious incident with a bounded blast radius; compromise of an offline root is an existential one, which is why the root does not sit on a network-connected host.

**Issuance with `step-ca` and ACME.** `step-ca` is the small-business issuing CA. It supports ACME, the same protocol public certificate authorities use, so devices and services can enrol and renew without a human copying files. Enrolment is bound to an authenticated identity: a device presents its existing certificate or an enrolment token issued through the identity provider, and receives a certificate whose subject and SANs describe that principal. Where ACME is unsuitable, `step` provides the equivalent CLI flow. Certificate private keys are generated on the device and never leave it; a CA that issues keys on behalf of devices has already lost the property it exists to provide.

**Lifetimes and renewal.** Human-facing TLS certificates can be issued for weeks; workload and device certificates should be measured in hours or a small number of days, with automatic renewal well before expiry. Short lifetimes are a compensating control for imperfect revocation: a stolen certificate stops working on its own without anyone having to notice and revoke it. Renewal failure must be an alert, not a silent expiry — monitoring certificate `notAfter` values is part of observability, not a housekeeping task.

**Revocation.** CRLs and OCSP are the standard mechanisms, and both have operational weaknesses: a CRL is only as fresh as its publication interval, and an OCSP responder is another availability dependency. Short-lived certificates reduce reliance on either. The architect still decides what happens when a status check cannot be reached: fail closed for high-value administrative access, fail open only where availability genuinely outranks the risk, and record the choice. Revocation must be tested by actually revoking a test certificate and confirming the relying party refuses it; an untested revocation path is a documentation exercise.

**Workload identity with SPIFFE and SPIRE.** SPIFFE defines a standard identity format and short-lived verifiable identities (SVIDs); SPIRE implements it, attests workloads using their environment, and issues X.509 or JWT SVIDs through a CA such as `step-ca`. This is the concrete form of the "mTLS or SPIFFE-style workload identities" commitment above: a service's identity comes from what and where it is, not from a static secret in a configuration file. The trade-off is a new control plane to operate, so it is worth it where services are numerous or short-lived, and unnecessary where a handful of hosts can use ordinary mTLS with short-lived certificates.

**What this gives the rest of the course.** The TLS certificates used by internal services, the machine credentials that join hosts to the directory, the signing keys used in supply-chain attestation, and the workload identities used between services all come from the same hierarchy and the same enrolment discipline. There is one place to audit issuance, one place to revoke, and one answer to "how do we know this certificate is ours?" The network chapters' encrypted mesh is only as trustworthy as the identity that issued its keys.

## Zero Trust as a property of the identity layer

The phrase **Zero Trust** has been used in several places already.
The identity chapter is where it has to be made concrete, because
without an identity layer that supports it, Zero Trust is a marketing
term. The substantive content is three commitments.

**Verify explicitly.** Every request, every time, is authenticated and
authorised, with no exemption for "internal" traffic, "trusted"
networks, or any other category that grants a request privilege based
on where it came from. The principle of complete mediation made
operational. The identity layer's role is supplying the verification:
every service the architecture runs is configured to require
authentication on every call, the authentication is to the identity
layer, and the identity layer's response is the only basis on which
the service decides whether the call is from a legitimate principal.

**Use least privilege.** Every principal has the minimum set of
permissions required to do the work it actually does, and no more.
The identity layer's role is supplying the structure: groups and roles
that map to specific functions, with permissions attached at the role
level rather than the user level, so that the question "what can this
user do" can be answered by enumerating their roles, and the question
"who can do this thing" can be answered by enumerating the role's
members. Permissions that drift, are added during a one-off task and
never removed, are the dominant source of unintended access in any
real organisation, and the answer is a periodic review process,
implemented in the identity system rather than maintained in
spreadsheets.

**Assume breach.** The architecture is designed under the assumption
that some part of it will be compromised, and the design choices
contain the consequences. Short-lived credentials so that compromised
credentials expire quickly. Strong authenticators so that the
credentials are hard to compromise in the first place. Rich audit
logs so that the compromise leaves traces. Rotation procedures so
that the path from "we suspect compromise" to "the compromised
credential is gone from the estate" is short, automated, and tested.
Microsegmentation at the application layer, treated in the network
chapter, so that a compromised principal cannot move sideways into
systems it had no business reaching.

The phrase **identity-aware proxy** describes a deployment pattern that
makes these commitments concrete for HTTP services. Pomerium,
oauth2-proxy, and Authelia are the open-source options. The proxy sits
in front of the application, receives the inbound request, requires
the request to carry a valid OIDC token from the identity provider,
optionally checks the token against the authorisation policy that
decides whether this particular principal is allowed to reach this
particular endpoint, and only then forwards the request to the
application. The application sees an authenticated request with the
identity attached. The pattern is useful for two reasons. It lets the
organisation put authentication in front of legacy applications that
do not natively support OIDC, by having the proxy handle the protocol
and pass the identity in a header the application can consume. And it
gives the organisation a single point at which authentication policy
for HTTP services is enforced, which is easier to audit than policies
distributed across each application. The pattern is not a replacement
for the application's own authorisation, the application still has to
decide what the authenticated principal is allowed to do, but it is a
clean separation of "is this caller who they claim to be" from "is
this caller permitted to do this thing."

## What the architect decides

The decisions developed above are collected here as a checklist. Each is argued in its own section; the table records only the answers.

| **Decision** | **The course's answer** |
| --- | --- |
| Provider stack | Keycloak or Authentik for OIDC/SAML; FreeIPA or Samba AD DC where operating-system integration and cross-platform join are required; the choice documented with its reasoning |
| Human authenticators | WebAuthn hardware tokens primary, platform authenticators for routine use, passwords only for enrolment and recovery, TOTP for remaining legacy services, no SMS and no push-only approval |
| Workload identity | mTLS with short-lived certificates, or SPIFFE/SPIRE SVIDs where services are numerous; no static service credentials |
| PKI lifecycle | Offline root, online issuing CA, `step-ca` with ACME, automated enrolment and renewal, tested revocation, short workload lifetimes |
| Source of truth | One directory; local accounts only for recovery, bootstrap and system accounts that cannot be federated |
| Operation | Declarative configuration in version control, secrets in a separate store, audit logs shipped, administrative access behind the same identity layer |
| Topology | On the internal WireGuard mesh; only OIDC/SAML federation endpoints through a reverse proxy; directory and KDC never public |
| Federation | The provider is the sole trust anchor; OIDC, SAML and SCIM where supported; local accounts are documented exceptions |
| Provisioning | Group membership as the source of application authorisation; tested offboarding that disables access everywhere within a defined window and produces an audit record |
| Recovery | Backups of directory, keys and configuration; a tested restore path independent of the identity layer being available |

The architecture that emerges is the substrate the rest of the course assumes. It is not glamorous and does not demonstrate well to a board. It is the difference between an organisation that can answer "who has access to what, and why, and is that still the right answer" and one that cannot. The investment is repaid every time a compromise is blocked at the credential layer, every time a leaver's access is revoked everywhere it matters, and every time an auditor or incident responder asks a question and the answer is in the logs.

The appendix that follows develops one concrete pattern — a Samba AD DC on NixOS with joined file servers — against which these decisions can be examined in full.

