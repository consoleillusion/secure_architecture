== Identity, PKI and Zero Trust

*Goal:* identity as the new perimeter, implemented.

=== Identity architecture
- Authentication vs. authorization vs. accounting
- Directory (LDAP) foundations, when it is still appropriate
- Federated vs. centralized models

=== Modern identity protocols
- OIDC (built on OAuth 2.0): flows, tokens, PKCE
- SAML 2.0: assertions, bindings, when it is still unavoidable
- SCIM for provisioning

=== Authenticators
- Password guidance (NIST 800-63B current)
- Passphrase design (structured entropy, memorability)
- WebAuthn / FIDO2: attestation, resident keys, platform vs. roaming
- TOTP, HOTP, push, and their respective weaknesses

=== Secrets and signing
- Secret-management substrate (Vault, Infisical)
- Signing workflows (sigstore, cosign)
- Rotation discipline

=== Zero Trust architecture
- Explicit verify, least privilege, assume breach, as practices not slogans
- Identity-aware proxies (Pomerium, oauth2-proxy, Authelia)
- Device identity and posture
- Microsegmentation at the application layer
- ZTA reference architectures (NIST 800-207) critiqued

=== Open-source stack
- Keycloak (OIDC + SAML IdP)
- Authentik as a lighter alternative
- HashiCorp Vault
- step-ca for device and workload identity
- Pomerium, oauth2-proxy


== Identity Management

*Goal:* centralised identity as the substrate every other layer
authenticates against, operated as code, recoverable, and cross-platform
by construction rather than by adapter.

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

=== Why identity is the new perimeter

The phrase *identity is the new perimeter* is repeated often enough to
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

This is what the introduction has been pointing toward. The principle
of *complete mediation*, that every access to every object is checked
every time, has no meaningful implementation if the check happens at a
network boundary the request never crosses. It has to happen at the
service, against a credential, on each call. The principle of *least
privilege* has no meaningful implementation if "privilege" is a
property of which network the request came from rather than which
principal is making it. *Fail-safe defaults*, which require that the
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

=== Authentication, authorisation, and accounting

The familiar acronym AAA conceals a discipline that organisations
routinely fail. The three are different, and the failures of each take
different shapes.

*Authentication* is the question of who the principal is. It produces
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

*Authorisation* is the question of what the authenticated principal
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

*Accounting* is the question of what the authenticated principal
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

=== The protocol landscape

The protocols that carry identity across an organisation are a smaller
set than the application catalogue might suggest. Five matter. Two
others are sometimes encountered.

*LDAP*, the Lightweight Directory Access Protocol (RFC 4511), is the
oldest of the protocols still in mainstream use. It defines a
hierarchical directory, a query language for it, and a set of
operations: bind, search, add, modify, delete. The directory's
structure, distinguished names, attributes, object classes, comes from
the X.500 lineage and is older than the web. Despite its age, LDAP is
the protocol most identity stores still speak natively, and most
applications that need to consume identity from a central source still
have an LDAP client. SASL, treated in the network chapter, provides
the authentication framework LDAP rides on; *LDAP over TLS* (LDAPS,
or LDAP with StartTLS) provides the encryption. The architectural
fact about LDAP is that it is a directory protocol, not an
authentication protocol. The identity store answers queries about
principals. The principals authenticate using something else, often
SASL with an underlying mechanism, to bind to the directory and
demonstrate that they are who their entry says they are.

*Kerberos* (RFC 4120) is an authentication protocol, distinct from
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
where *single sign-on* comes from in the Kerberos sense: not a
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

*OpenID Connect* (OIDC) is the modern authentication layer for
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

*SAML 2.0* is the older federation protocol, predating OIDC by about
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

*SCIM*, the System for Cross-domain Identity Management (RFCs 7643
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

The two others worth mentioning are *GSSAPI* and *PAM*. GSSAPI,
already discussed in the network chapter, is the API surface through
which application protocols hook into Kerberos. SSH, NFS, SMB, LDAP,
and several others all support GSSAPI authentication, and where the
organisation has Kerberos infrastructure, GSSAPI is how the
applications use it. *PAM*, Pluggable Authentication Modules, is
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

=== What an identity system has to be, structurally

Out of those protocols, an identity system for a small-to-medium
business has to assemble a small number of properties. The properties
are the architectural commitment; the protocols are the means.

*A single source of truth.* Exactly one place where the canonical
record of "who works here" lives. Every other system either consumes
that source through one of the protocols, or, where it cannot, has its
local account list synchronised from it. If two systems disagree about
whether a person is still an employee, the architecture has failed at
this layer. The cost of getting this right early is small. The cost
of unifying two divergent identity sources later is large.

*Operated as code.* The list of users, groups, and the policies that
attach to them, are described in version control where the structure
of the configuration is auditable, reviewable, and reproducible. The
parts that cannot be in version control, passwords, secrets, recovery
material, are stored in the secrets management substrate the secrets
section will treat, with the version-controlled configuration
referencing them rather than embedding them. An identity system in
which adding a user is "log into the admin console and click the
button" is not yet operated as code, regardless of how nicely the
admin console is designed.

*Auditable.* Every authentication event, every authorisation
decision, every directory modification, every administrative action,
appears in a log that is preserved long enough to reconstruct what
happened during an incident, and is shipped to the observability
pipeline that the rest of the architecture uses. The audit trail is
not an extra feature. It is what makes the difference between an
identity system that is trustworthy and one that merely claims to be.

*Recoverable.* The directory itself is backed up. The keys that
protect it are backed up, separately, with the separation discipline
the cryptography chapter develops. The procedure for restoring the
identity system from backups has been tested, because an organisation
that has lost its identity system has lost access to all of its other
systems, and the recovery procedure is the only thing that gets it
back. This is the most under-invested property in most identity
deployments. It is also the one whose absence converts a routine
incident into an existential one.

*Cross-platform.* A small business does not get to choose to have
only Linux clients, or only Windows clients, or only browsers. It has
all of them, because the people in the business have all of them, and
the identity system has to authenticate users on whatever device they
happen to be using. This is what makes the protocol catalogue above
load-bearing rather than academic: each of the protocols was designed
to solve a particular kind of authentication problem on a particular
kind of system, and the identity provider has to speak whichever ones
the consuming systems require. An identity provider that only speaks
OIDC is fine for browser-based applications and useless for joining a
Windows laptop. One that only speaks LDAP is fine for old applications
and bad for browser-based ones. The provider has to cover the matrix.

*Reachable but not exposed.* The identity system is the most
sensitive single system in the architecture, because compromising it
compromises everything else. It has to be reachable from the systems
that authenticate against it, which is most systems, and it has to be
unreachable from anywhere else. The encrypted mesh VPN the network
chapter described is the natural place for this: the identity provider
is on the internal mesh, every host that consumes identity is on the
mesh, and the public internet has no path to the identity provider's
authentication endpoints at all. Where federation to external
applications is required, OIDC and SAML are the egress paths, with
the identity provider's HTTP front end exposed publicly through a
reverse proxy and nothing else of the identity stack reachable from
outside.

=== Choosing a stack at the small-business scale

The open-source landscape for identity is mature enough that an
organisation does not have to compromise on these properties. It does,
however, have to make a deliberate choice among stacks that are good at
different things. The choice depends on what kinds of clients the
organisation actually has and what kinds of applications it actually
runs.

*Keycloak* is the most general of the options. It is an OIDC and
SAML identity provider, federation-capable, with strong support for
the protocols modern web applications speak. It can sit in front of
an LDAP backend, including one of the dedicated LDAP servers below,
or use its own user database. It is the right default for an
organisation whose applications are mostly HTTP-based, whose user
authentication is mostly browser-based, and whose Windows or Linux
host integration is light enough that LDAP-via-Keycloak suffices for
the few cases where it matters. The cost is that Keycloak is heavier
than its lightest competitors and the configuration model is large.

*Authentik* is the lighter alternative in the same niche. It speaks
OIDC and SAML. It has a smaller surface than Keycloak and a more
focused configuration model. For organisations whose use cases are
within its capability set, which covers most browser-based federation,
it is easier to operate. The trade is a smaller community and fewer
edge cases handled out of the box.

*FreeIPA* is the answer for organisations whose primary problem is
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

*Samba Active Directory Domain Controller*, the subject of the
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

*Vendor-hosted identity* is the path most small businesses take
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

=== Authenticators

The protocols are the means of carrying authentication. The
authenticators are what the user actually presents to authenticate.
The choice of authenticator is the security-architectural decision
that has the largest practical impact on the organisation's resistance
to credential-theft attacks, and it deserves treatment separate from
the protocol catalogue.

*Passwords*, the default authenticator, have a worse reputation than
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

*TOTP*, time-based one-time passwords (RFC 6238), help with replay,
since the value changes every thirty seconds, but do not help with
phishing, since a fake verifier can collect the current TOTP value at
the same time as the real one. They also do not help with verifier
compromise, since the seed value the TOTP is computed from is shared
between the user's authenticator app and the verifier, and a verifier
compromise yields the seed. TOTP is a step up from passwords alone,
but it is not the strong authentication that an architecture aiming
at something defensible should treat as sufficient.

*Push-based MFA*, the kind that sends a notification to the user's
phone asking them to approve a login, is worse than TOTP for the case
that matters. Push fatigue, the phenomenon of users approving prompts
they did not initiate because they receive too many of them, has been
the proximate cause of several high-profile breaches. The Uber
compromise of 2022 is the canonical example. The user receives a
prompt, the user approves it because that is what users do with
prompts, and the attacker is now logged in. The mechanism's safety
relies on the user's vigilance at exactly the moment the user is least
attentive.

*WebAuthn and FIDO2* are what the architecture should actually be
deploying. The credential is a key pair, generated on a hardware token
or in a hardware-backed enclave on the user's device, with the private
key never leaving the hardware. The authentication is a challenge
signed by the private key, where the challenge includes the origin of
the verifier the user is actually authenticating to. This is the
property that makes WebAuthn phishing-resistant: a fake verifier on a
different origin cannot make the user's authenticator sign a challenge
the real verifier will accept, because the origin in the signed
challenge will be wrong. The credential is also unique per service,
which means that a verifier compromise does not yield a credential
reusable elsewhere, and it is bound to the hardware, which means that
stealing the credential requires stealing the hardware. The WebAuthn
deployment story has matured in the last several years to the point
that the option is genuinely available: most browsers support it, most
identity providers support it, and hardware tokens are inexpensive
enough that an organisation can issue one to every employee.

The architectural commitment is straightforward. *WebAuthn for
human authentication, with hardware tokens as the primary
authenticator and a platform authenticator (TPM-backed on Windows,
Secure Enclave on macOS, hardware-backed keystore on Android) as the
fallback for routine use.* Passwords as the bootstrap during
enrollment and as the recovery path that goes through a controlled
out-of-band process. TOTP grudgingly accepted for the dwindling
population of services that do not yet support WebAuthn, with an
explicit migration plan. Push notifications avoided. SMS-based
authentication avoided entirely, because SMS is a protocol the
organisation does not control and SIM-swap attacks are within the
threat model of any business worth attacking.

For machine authentication, the equivalent commitment is *mTLS or
SPIFFE-style workload identities*, which the secrets and signing
section will develop, with the principle that long-lived static
credentials are not used for service-to-service authentication. The
service holds a short-lived certificate or token that is renewed
automatically by the identity infrastructure, and the renewal failure
is a detectable event rather than a silent expiry.

=== Secrets, signing, and the identity layer's wider scope

The identity system authenticates principals. It is not the system
that holds the secrets the principals consume. The two functions are
related but separate, and the secrets-management substrate is what
holds API keys, database credentials, certificate private keys, and
the other material that applications need but should not have hard-
coded.

*HashiCorp Vault* and *Infisical* are the open-source options for
the secrets-management role. Both store secrets encrypted at rest,
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

*Signing*, the cryptographic side of identity, is what binds
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

*Rotation discipline* is the operational property that ties the
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

=== Zero Trust as a property of the identity layer

The phrase *Zero Trust* has been used in several places already.
The identity chapter is where it has to be made concrete, because
without an identity layer that supports it, Zero Trust is a marketing
term. The substantive content is three commitments.

*Verify explicitly.* Every request, every time, is authenticated and
authorised, with no exemption for "internal" traffic, "trusted"
networks, or any other category that grants a request privilege based
on where it came from. The principle of complete mediation made
operational. The identity layer's role is supplying the verification:
every service the architecture runs is configured to require
authentication on every call, the authentication is to the identity
layer, and the identity layer's response is the only basis on which
the service decides whether the call is from a legitimate principal.

*Use least privilege.* Every principal has the minimum set of
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

*Assume breach.* The architecture is designed under the assumption
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

The phrase *identity-aware proxy* describes a deployment pattern that
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

=== What the architect decides

The decisions that the identity layer demands of the architect are a
short list, and most of the rest of the chapter has been building up
to them.

*Which identity provider stack runs the organisation's identity.*
The choice among Keycloak, Authentik, FreeIPA, Samba AD DC, and
vendor-hosted options is made on the basis of what the organisation's
actual client population requires, not on what is fashionable. The
choice is documented, with the reasoning for it, in the same place
the rest of the architecture's design decisions live.

*Which authenticators principals use.* WebAuthn with hardware tokens
for human users, mTLS or SPIFFE-style workload identities for
services. The exceptions are explicit, with their security properties
acknowledged.

*How the identity layer is operated.* Declarative configuration in
version control. Backups tested. Disaster recovery rehearsed.
Audit logs shipped to the observability pipeline. The administrative
interface is itself behind the identity layer, with administrative
access requiring the same authentication that user access does and
preferably stronger.

*Where the identity layer lives in the network topology.* On the
internal mesh, with the public-facing federation endpoints, OIDC and
SAML, exposed through a reverse proxy and the rest of the stack
unreachable from outside. The directory and the KDC, in particular,
are not on the public internet under any circumstances.

*How federation works.* The identity provider is the single trust
anchor. Applications that support OIDC federate through it. SaaS
that requires SAML federates through it. LDAP-aware applications bind
through it, over TLS, with SASL. The default for any new application
is federation; local accounts are the documented exception.

*How provisioning and deprovisioning work.* SCIM where the consuming
applications support it. The identity provider's group and role
membership as the source of truth for application authorisation. A
defined and tested procedure for what happens when an employee leaves,
that disables their access in every system within a defined time
window and produces an audit record that the disabling occurred.

*How the identity layer itself is recovered.* A backup strategy
that includes the directory, the keys, and the configuration. A
restore procedure that has been tested at least once. A recovery path
that does not depend on the identity layer being available, because
during the recovery the identity layer by definition is not available.

The architecture that emerges from these decisions is the substrate
the rest of the course assumes. It is not glamorous. It does not
demonstrate well to a board. It is, however, the difference between
an organisation that can answer "who has access to what, and why,
and is that still the right answer" and one that cannot. The
investment in getting it right is paid back every time a compromise
attempt is blocked at the credential layer, every time an employee
leaves and access is revoked everywhere it matters, and every time an
auditor or an incident responder asks a question and the answer is in
the logs.

=== Practical: Samba AD DC on NixOS for cross-platform directory and file services

The remainder of the chapter develops one architectural pattern in
detail. The pattern is *a Samba Active Directory Domain Controller
running on NixOS, with separate file servers joined to the domain,
serving Linux, Windows, and macOS clients from a single identity
substrate.* The pattern is not the only valid identity architecture
for a small business, but it is a good one for the case where
cross-platform compatibility is a load-bearing requirement, and it
exercises the principles the rest of the chapter has developed
against a concrete deployment.

==== The problem statement

Consider a small business of forty people. They have Windows laptops
in the front office, Linux workstations in engineering, and macOS
laptops on the design team. They have a fileserver where shared
documents live and where engineering keeps build artifacts that are
too large for the version-control system. They want a single sign-on
that works for all three operating systems, file shares that respect
group membership, the ability to revoke an employee's access in one
place when they leave, and an audit trail that records who accessed
what.

The combination is the canonical case where Samba AD DC is the right
answer. Active Directory's protocol behaviour is what Windows expects
to find when it joins a domain, Linux can join it through SSSD using
the same code path it uses for a Microsoft AD, and macOS has had AD
binding support since the early 2000s. Samba's open-source
implementation of AD is mature, well-deployed, and well-documented;
it is not a clone with caveats but a working AD-compatible domain
controller. Running it on NixOS makes the configuration declarative
and reproducible, which is what the rest of this course's
infrastructure looks like.

There is one architectural choice this section makes early and
deliberately, because the Samba project itself recommends it: *the
domain controller does not also serve files.* The Samba wiki is
explicit on this point and the Ubuntu Server documentation echoes it,
the AD/DC role and the file-server role have conflicting
configuration requirements and operating one machine in both roles
produces fragility neither role would have on its own. The pattern
this section develops is therefore two systems: a domain controller
that authenticates, and one or more member servers that join the
domain and serve files using credentials it issues. For an
organisation of forty people, both can be modest virtual machines.

==== Why Samba AD DC and not the alternatives

A small business that wants cross-platform identity has, realistically,
four self-hosted options. The choice among them is worth being
explicit about.

*FreeIPA* is the strongest stack for Linux-heavy estates. It
bundles 389 Directory Server, MIT Kerberos, Dogtag CA, and BIND into
a coherent whole, and SSSD on Linux clients is built to talk to it.
For an estate that is mostly Linux, FreeIPA is the better choice.
For one with significant Windows presence, FreeIPA's Windows
integration is a bolt-on, the cross-realm trust to a Windows domain
is configurable but not native, and Windows clients do not join
FreeIPA the way they join AD.

*OpenLDAP plus a separate Kerberos KDC*, with the two integrated by
hand, is the configuration the older Samba documentation describes.
It is more flexible than the bundled options and considerably more
work to maintain. For an organisation of forty people it is the
wrong trade.

*Keycloak fronting an LDAP backend* is the answer when the
identity needs are predominantly browser-based. It does not, on its
own, give Windows clients something to join, and it does not produce
the Kerberos infrastructure that SMB file authentication wants.
Keycloak is the right complement to either FreeIPA or Samba AD DC
when browser federation is needed, but it is not a substitute for
either.

*Samba AD DC* is the answer when the centre of gravity is
cross-platform, and especially when Windows endpoints joining a
domain and SMB file shares respecting domain groups are part of how
the organisation actually works. The implementation is mature, the
client compatibility across Windows, Linux, and macOS is the best
the open-source landscape offers for this case, and the protocols it
exposes, AD-flavoured LDAP, Kerberos, and DNS, are well-supported on
the consuming side.

The remainder of this section assumes Samba AD DC has been chosen.

==== Topology

The deployment described here uses three roles. *One domain
controller* runs Samba AD DC, the LDAP and Kerberos endpoints, and
the AD-integrated DNS. *One or more file servers* run Samba in
member-server mode, joined to the domain, serving SMB shares whose
ACLs reference domain groups. *The clients*, Windows laptops,
Linux workstations, and macOS machines, join the domain through
their respective mechanisms and authenticate to the file servers
using Kerberos tickets obtained from the DC.

Naming conventions matter. The realm, in DNS-and-Kerberos terms, is
chosen and committed to: this section uses `corp.example.com` as the
realm, `CORP` as the NetBIOS workgroup, and `dc01.corp.example.com`
as the domain controller's hostname. The realm should be a domain
the organisation actually controls in DNS, and ideally not the same
as the organisation's primary public-facing domain, because mixing
the AD-integrated DNS for `corp.example.com` with a public web
presence on `example.com` produces avoidable confusion. A common
pattern is to use a subdomain of the organisation's main domain for
the AD realm.

The DC is on the internal mesh VPN, with no exposure to the public
internet at all. The file servers are also on the internal mesh.
Clients reach both through the mesh when remote and through the
local network when on-site, with no architectural difference between
the two cases. The `services.samba` configuration on the DC binds
to the mesh interface, the firewall on the DC closes everything else,
and the AD-integrated DNS is the resolver of last resort for the
realm zone.

==== The NixOS module: domain controller

The NixOS configuration for the DC is the centrepiece of the
declarative half of the deployment. The configuration below targets
NixOS 25.05 or unstable, which use the structured `services.samba.settings`
attribute set; older releases used `configText` or `extraConfig`, and
the configuration would have to be adjusted accordingly.

```nix
{ config, lib, pkgs, ... }:

let
  realm = "CORP.EXAMPLE.COM";
  domain = "CORP";
  netbios = "DC01";
  dcIp = "10.42.0.10";
  dnsForwarder = "10.42.0.1";  # internal validating resolver
in {
  # The DC is the authoritative DNS for the realm. Disable any
  # other resolver configuration that would compete with Samba's
  # internal DNS backend.
  systemd.services.resolvconf.enable = false;
  services.resolved.enable = false;

  # The DC's own resolver points at itself for the realm zone,
  # with the internal validating resolver as the upstream for
  # everything else.
  environment.etc."resolv.conf".text = ''
    search corp.example.com
    nameserver ${dcIp}
  '';

  # Samba AD DC requires a Samba build with AD, LDAP, and mDNS
  # support. The samba4Full package includes them; the lighter
  # default samba package does not.
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    # Disable the standalone services that conflict with the AD DC
    # role. The samba-ad-dc systemd unit replaces them.
    nmbd.enable = false;
    winbindd.enable = false;
    smbd.enable = false;
    openFirewall = false;  # we control the firewall explicitly below
    settings = {
      global = {
        "server role"          = "active directory domain controller";
        "realm"                = realm;
        "workgroup"            = domain;
        "netbios name"         = netbios;
        "dns forwarder"        = dnsForwarder;
        "idmap_ldb:use rfc2307" = "yes";
        # Bind only to the mesh interface; never expose the DC
        # to interfaces the architecture does not control.
        "interfaces"           = "lo wg0";
        "bind interfaces only" = "yes";
        # SMB encryption is required on the wire even though the
        # mesh already encrypts; defence in depth.
        "server smb encrypt"   = "required";
        "server min protocol"  = "SMB3_00";
        # TLS settings for the LDAP listener; the DC's own
        # certificate is provisioned in /var/lib/samba/private/tls.
        "tls enabled"          = "yes";
        "tls keyfile"          = "tls/key.pem";
        "tls certfile"         = "tls/cert.pem";
        "tls cafile"           = "tls/ca.pem";
        # Audit: ship every authentication and authorization
        # decision into the journal at a level the observability
        # pipeline picks up.
        "log level"            = "1 auth_audit:3 auth_json_audit:3";
        "log file"             = "/var/log/samba/log.%m";
      };
      sysvol = {
        "path"      = "/var/lib/samba/sysvol";
        "read only" = "No";
      };
      netlogon = {
        "path"      = "/var/lib/samba/sysvol/corp.example.com/scripts";
        "read only" = "No";
      };
    };
  };

  # The AD DC needs the samba-ad-dc unit, not smbd/nmbd. The unit
  # is shipped by the Samba package; we just have to make sure it
  # is the one that runs.
  systemd.services.samba-ad-dc = {
    description = "Samba Active Directory Domain Controller";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.samba4Full}/sbin/samba --foreground --no-process-group";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      LimitNOFILE = 16384;
      Restart = "on-failure";
    };
    unitConfig.RequiresMountsFor = "/var/lib/samba";
  };

  # The firewall: open the AD DC ports on the mesh interface only.
  networking.firewall = {
    enable = true;
    interfaces.wg0 = {
      allowedTCPPorts = [
        53      # DNS
        88      # Kerberos
        135     # RPC endpoint mapper
        139     # NetBIOS session service (legacy SMB)
        389     # LDAP
        445     # SMB
        464     # Kerberos password change
        636     # LDAPS
        3268    # Global Catalog
        3269    # Global Catalog SSL
        49152 49153 49154 49155 49156  # RPC dynamic range, narrowed
      ];
      allowedUDPPorts = [
        53      # DNS
        88      # Kerberos
        123     # NTP
        137 138 # NetBIOS name and datagram
        389     # CLDAP
        464     # Kerberos password change
      ];
    };
    # Everything else is closed.
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  # NTP is non-negotiable for Kerberos. The DC syncs to a chosen
  # internal time source; clients sync to the DC.
  services.chrony = {
    enable = true;
    servers = [ "10.42.0.1" ];  # internal authoritative time source
    extraConfig = ''
      allow 10.42.0.0/16
      bindaddress ${dcIp}
    '';
  };

  # Backups: the directory itself is in /var/lib/samba, which is
  # snapshotted by the host's backup substrate. The keys are in
  # /var/lib/samba/private and are backed up separately, encrypted,
  # to the offline-keys location the cryptography chapter develops.
  # The backup configuration itself lives in the host module.
}
```

The configuration is long but uniform. Every value is in version
control. Every rebuild reconstructs the exact same configuration.
The Samba package is the `samba4Full` build that includes AD, LDAP,
and mDNS support. The standalone services that would conflict with
the AD DC role are disabled. The firewall opens precisely the AD
ports the protocol requires, on the mesh interface only. NTP is
configured because Kerberos cannot tolerate clock skew.

==== The provisioning ceremony

The configuration above describes what the DC looks like once it is
running. It does not, on its own, create the directory. Samba's AD
database has to be *provisioned* with a one-time command that
generates the initial schema, the krbtgt key, the administrator
account, and the various other artifacts an AD domain requires.
This step is imperative, and it is the single piece of the
deployment that is not declarative.

The reason this matters, and the reason it is being called out
explicitly rather than glossed over, is that the entire NixOS
philosophy is that the configuration in version control reconstructs
the system. Provisioning is the case where the system has state that
the configuration does not describe, the keys, the SIDs, the
randomly-generated material the directory depends on, and that
state has to come from somewhere. The honest position is to admit
this and to handle it with the same discipline the rest of the
architecture uses. The provisioning command is run once. The output
state, `/var/lib/samba/private/` and `/var/lib/samba/sysvol/`, is
then itself part of the system's persistent state, backed up
separately from the configuration, with restore procedures tested
the same way other state-bearing systems are tested.

The provisioning command:

```bash
= Stop the AD DC service if it is running. It will fail to start
= without a provisioned database; this is expected.
systemctl stop samba-ad-dc

= Move any existing smb.conf out of the way; the provisioner will
= write a new one.
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak 2>/dev/null || true

= Run the provisioner with the deployment's chosen values.
samba-tool domain provision \
    --server-role=dc \
    --use-rfc2307 \
    --dns-backend=SAMBA_INTERNAL \
    --realm=CORP.EXAMPLE.COM \
    --domain=CORP \
    --adminpass="$(cat /run/secrets/ad-admin-password)" \
    --host-ip=10.42.0.10 \
    --host-name=dc01

= The provisioner writes /var/lib/samba/private/krb5.conf with the
= realm configuration. Symlink it into /etc so the system uses it.
ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf

= Start the AD DC.
systemctl start samba-ad-dc
```

The administrator password is read from a file the secrets-management
substrate has placed at `/run/secrets/ad-admin-password`. NixOS's
`agenix` and `sops-nix` modules both implement this pattern; the
secret never appears in the world-readable `/nix/store`. The
administrator account exists, and it is the first account
provisioned, but it is not the account that day-to-day administrators
use. As soon as provisioning is complete and the DC is reachable, a
named administrative account is created for each human administrator,
those accounts are added to `Domain Admins`, and the original
`Administrator` account is locked away for break-glass use only,
with its password rotated and held in the offline secrets store.

The `--use-rfc2307` flag is significant. It tells Samba to populate
the directory with the POSIX attributes, `uidNumber`, `gidNumber`,
`unixHomeDirectory`, `loginShell`, that Linux clients need to map
domain principals to local UNIX accounts. Without this, Linux
clients can authenticate to the domain but cannot resolve a domain
user to a UID, which makes file ACLs and home directories awkward.
Setting it at provisioning time avoids the considerable pain of
adding it later.

==== Post-provisioning verification

The first thing to do after provisioning is verify that the basic
machinery works. The four checks below are standard.

```bash
= Kerberos: obtain a TGT for the administrator. This exercises the
= KDC end to end.
kinit administrator@CORP.EXAMPLE.COM
klist  # should show a ticket cache with krbtgt/CORP.EXAMPLE.COM

= DNS: the AD DC should be answering queries for the realm.
dig @10.42.0.10 _ldap._tcp.corp.example.com SRV
= Should return an SRV record pointing at dc01.corp.example.com

= LDAP: bind to the directory using GSSAPI (Kerberos), confirming
= the LDAP server accepts the ticket the KDC issued.
ldapsearch -H ldap://dc01.corp.example.com -Y GSSAPI \
    -b "dc=corp,dc=example,dc=com" "(sAMAccountName=administrator)"

= samba-tool: a smoke test against the domain itself.
samba-tool domain info 127.0.0.1
samba-tool user list
```

Each of these exercising a different subsystem. `kinit` exercises the
KDC. `dig` exercises the DNS. `ldapsearch` exercises the LDAP server
and the GSSAPI binding through it. `samba-tool` exercises the
domain-management interface. If any of them fails, the failure
points at the subsystem to investigate first, rather than at "Samba
isn't working."

==== Joining a Linux file server

The file server is the second NixOS host in the deployment. It is
not a domain controller, it is a member server, joined to the
domain, with its own NixOS configuration that runs Samba in the
member-server role and serves SMB shares whose ACLs are domain
groups.

```nix
{ config, lib, pkgs, ... }:

let
  realm = "CORP.EXAMPLE.COM";
  domain = "CORP";
  fsHostname = "fs01";
in {
  networking.hostName = fsHostname;
  networking.domain = "corp.example.com";

  # The file server uses the domain's DNS so that domain SRV
  # records resolve correctly. Without this, Kerberos discovery
  # fails.
  networking.nameservers = [ "10.42.0.10" ];

  # Time sync against the DC; Kerberos requires it.
  services.chrony = {
    enable = true;
    servers = [ "10.42.0.10" ];
  };

  # SSSD is the system's bridge between the local OS and the
  # domain. It implements PAM and NSS modules that consult the
  # domain for authentication and identity, with a local cache
  # for offline operation.
  services.sssd = {
    enable = true;
    config = ''
      [sssd]
      domains = ${realm}
      services = nss, pam
      config_file_version = 2

      [domain/${realm}]
      id_provider = ad
      access_provider = ad
      ad_domain = ${realm}
      krb5_realm = ${realm}
      realmd_tags = manages-system joined-with-samba
      cache_credentials = True
      ldap_id_mapping = False  # use RFC2307 attributes from AD
      use_fully_qualified_names = False
      fallback_homedir = /home/%u
      default_shell = /bin/bash
    '';
  };

  # PAM: have login services consult SSSD. The NixOS sssd module
  # adds the right PAM stanzas automatically when enabled, but
  # the home directory pam_mkhomedir line has to be requested
  # explicitly so that domain users get a home directory the
  # first time they log in.
  security.pam.services = {
    sshd.makeHomeDir = true;
    login.makeHomeDir = true;
  };

  # Samba in member-server mode. Note the absence of "server role
  # = active directory domain controller"; this server is not a DC.
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    openFirewall = false;
    settings = {
      global = {
        "workgroup"            = domain;
        "realm"                = realm;
        "security"             = "ADS";
        "kerberos method"      = "secrets and keytab";
        "winbind use default domain" = "yes";
        "winbind enum users"   = "yes";
        "winbind enum groups"  = "yes";
        "winbind refresh tickets" = "yes";
        "template shell"       = "/bin/bash";
        "template homedir"     = "/home/%U";
        "idmap config * : backend"  = "tdb";
        "idmap config * : range"    = "100000-199999";
        "idmap config ${domain} : backend" = "ad";
        "idmap config ${domain} : schema_mode" = "rfc2307";
        "idmap config ${domain} : range"   = "10000-99999";
        "server smb encrypt"   = "required";
        "server min protocol"  = "SMB3_00";
        "log level"            = "1 auth_audit:3";
      };
      shared = {
        "path"                 = "/srv/shared";
        "browseable"           = "yes";
        "read only"            = "no";
        "valid users"          = "@\"${domain}\\Domain Users\"";
        "create mask"          = "0660";
        "directory mask"       = "0770";
        "vfs objects"          = "acl_xattr";
        "map acl inherit"      = "yes";
        "store dos attributes" = "yes";
      };
      engineering = {
        "path"                 = "/srv/engineering";
        "browseable"           = "yes";
        "read only"            = "no";
        "valid users"          = "@\"${domain}\\Engineering\"";
        "create mask"          = "0660";
        "directory mask"       = "0770";
        "vfs objects"          = "acl_xattr";
      };
    };
  };

  # winbindd is required on a member server; it is the daemon that
  # talks to the domain controller and resolves domain users and
  # groups for the local system.
  services.samba.winbindd.enable = true;

  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 445 139 ];
  networking.firewall.interfaces.wg0.allowedUDPPorts = [ 137 138 ];
}
```

The member server's join to the domain is, like the DC's
provisioning, an imperative one-time operation. After the NixOS
configuration above is applied, the server is configured to behave
as a domain member but does not yet have credentials in the domain.
The join command issues those credentials:

```bash
= Authenticate as a domain administrator and join the server to
= the domain. This creates a computer account in the directory and
= stores the keytab in /var/lib/samba/private.
net ads join -U administrator
= (prompts for the domain administrator's password)

= Verify the join succeeded.
net ads testjoin
= Should report: Join is OK

= Verify SSSD can resolve domain users.
getent passwd 'CORP\jdoe'
= Should return a passwd entry with the user's UID, GID, and home

= Restart the dependent services so the new keytab takes effect.
systemctl restart samba-smbd winbind sssd
```

The principle that has been operating throughout, the imperative
one-time steps are documented, scripted, and re-runnable, applies
here. The join command goes into a runbook that is checked in next
to the NixOS configuration, the administrator password it consumes
comes from the secrets store rather than being typed at the prompt
in production, and the verification commands are run automatically
after the join to confirm success.

==== Joining a Linux workstation

A Linux workstation joins the domain the same way the file server
does, with the same SSSD configuration but without the Samba
member-server module. Users log in to the workstation with their
domain credentials, their home directory is created on first login
by `pam_mkhomedir`, and group memberships from the domain are
honoured by NSS so that file permissions on networked filesystems
work as expected. The same Kerberos ticket the user obtains by
logging in is good for SSH to other domain-joined hosts (with
GSSAPI authentication enabled in the SSH server config) and for
mounting SMB shares from the file server (with the `cifs-utils`
package and `sec=krb5` mount option).

```nix
= Excerpt of a Linux workstation's NixOS configuration. The SSSD
= block is identical to the file server's; only the Samba module
= is omitted.

services.sssd.enable = true;
= ... same config as fileserver ...

= Allow Kerberos-authenticated SSH between domain hosts.
services.openssh.settings.GSSAPIAuthentication = true;

= CIFS mount support, for accessing SMB shares with the user's
= Kerberos ticket.
environment.systemPackages = with pkgs; [ cifs-utils ];

= Optional: an automounter for SMB shares, so users can `cd`
= into //fs01/shared and have it mounted on demand.
services.autofs = {
  enable = true;
  autoMaster = ''
    /mnt/smb /etc/autofs/auto.smb --timeout=300
  '';
};
environment.etc."autofs/auto.smb".text = ''
  shared -fstype=cifs,sec=krb5,cruid=${"$"}{UID} \
      ://fs01.corp.example.com/shared
  engineering -fstype=cifs,sec=krb5,cruid=${"$"}{UID} \
      ://fs01.corp.example.com/engineering
'';
```

==== Joining a Windows workstation

Windows is the OS the protocol was designed for. Joining a domain
on Windows 10 or 11 Pro is a settings dialog: System → About →
Join a domain, enter `corp.example.com`, supply a domain
administrator credential, reboot. The workstation's computer
account is created in the directory automatically, the keytab is
stored in the Windows-native equivalent (LSA secrets), and from
the next login onward the user can log in with `CORP\username` and
their domain password. SMB access to `\\fs01\shared` and
`\\fs01\engineering` works without further configuration; the user's
Kerberos ticket is presented automatically.

The architectural commitments do not stop being commitments because
the OS is Windows. Group Policy is the AD-native mechanism for
distributing configuration to Windows endpoints, and Samba AD DC
supports it. The standard practice is to keep Group Policy
narrow, password policy, screen-lock timeout, audit settings,
software-restriction policies, the kind of thing that has to be
enforced and verified by the directory rather than left to each
workstation. Application configuration that varies per workstation,
or that should be treated as code, belongs in the workstation
management substrate (whatever the organisation has chosen for that)
rather than in Group Policy.

==== Joining a macOS workstation

macOS has had AD binding support for two decades. The mechanism on
modern macOS is *Profile Manager* or, more often in small
businesses, the System Settings → Users & Groups → Network Account
Server pane, which writes the directory configuration to
`/Library/Preferences/OpenDirectory/`. The user enters the domain
name, supplies an administrator credential, and the machine is
bound. Kerberos works thereafter, SMB shares are accessible with
the user's domain credentials, and the directory's group
memberships are visible to the local NSS-equivalent.

The macOS join is the most fragile of the three. Apple has, over
several macOS versions, deprioritised the AD-binding code path in
favour of mobile-device-management profiles distributed by an MDM,
and the AD-binding implementation has become more sensitive to
edge cases. For an organisation with significant macOS presence,
the architectural realistic answer is often to use AD for
authentication and an MDM (Jamf, or the open-source MicroMDM) for
configuration, rather than to expect AD's GP-equivalent to manage
macOS the way it manages Windows.

==== File-share authorisation

The directory's groups are the load-bearing structure for
authorisation on the file server. Creating a share that is readable
and writable by the engineering team, but not by the rest of the
company, is a matter of two domain-side actions and one
file-server-side action:

```bash
= On the DC: create the group, if it does not exist, and add users.
samba-tool group add Engineering --description="Engineering team"
samba-tool group addmembers Engineering "jdoe,asmith,bnguyen"

= On the file server: create the directory and set its ACL so that
= only the Engineering group has write access. setfacl with NFSv4
= ACLs (which Samba's acl_xattr maps to NTFS-style ACLs) is the
= right tool here.
mkdir -p /srv/engineering
chown root:"CORP\\Engineering" /srv/engineering
chmod 2770 /srv/engineering
setfacl -m "g:CORP\\Engineering:rwx" /srv/engineering
setfacl -d -m "g:CORP\\Engineering:rwx" /srv/engineering
```

The share definition in the file server's `services.samba.settings`
references the same group, the `valid users = @"CORP\Engineering"`
line is what tells Samba to honour the group at the protocol level.
The pattern composes: an additional share, with a different group,
is two lines in the NixOS configuration and a couple of `setfacl`
commands.

The discipline that makes this scale is *groups everywhere, users
never*. Permissions on shares are granted to groups, not to named
users, and a user's access is determined by which groups they are
in. Adding a new engineer is one command, adding them to the
`Engineering` group, and they immediately have access to everything
the group has access to. Removing them when they leave is the
inverse, one command, and access drops everywhere at once. The
revocation property the introduction promised is now operational.

==== Operations: backup, observability, recovery

The DC is the single most important system in the architecture, and
its operations have to reflect that. Three concerns dominate.

*Backup.* The directory is in `/var/lib/samba/`, divided into
`private/` (the schema, the keys, the krbtgt) and `sysvol/` (the
group-policy files and login scripts, replicated between DCs in a
multi-DC setup). Both have to be backed up. The `samba-tool domain
backup` command produces a consistent snapshot:

```bash
samba-tool domain backup online \
    --server=dc01.corp.example.com \
    --targetdir=/var/backups/samba \
    -UAdministrator
```

The output is a tarball containing the directory and the keys at a
moment-consistent point. The backup is encrypted, with the same
substrate the rest of the organisation's backups use, and the
encryption key is held separately from the DC, so that a compromise
of the DC does not yield the backups.

*Observability.* The audit log level set in the configuration above,
`auth_audit:3 auth_json_audit:3`, produces a JSON-formatted
authentication audit on every Kerberos and NTLM authentication
attempt. The log lines are picked up by the host's journal, shipped
to the central log store the observability chapter develops, and
indexed there. Successful authentications, failed authentications,
ticket requests, and password changes are all visible. The
operational dashboard for the identity layer is built from these
streams. A spike in failed authentications against a particular
account is a brute-force attempt; a successful authentication from
an unexpected source is a credential-compromise indicator; a
password change at an unusual time is something to investigate.

*Recovery.* The procedure for restoring the DC from backup, if the
DC is destroyed, is the procedure that has to actually have been
tested. The steps are: bring up a new NixOS host with the same
hostname and IP as the original DC; install the NixOS configuration
from version control, which reconstructs the system to the point of
the unprovisioned state; restore the `/var/lib/samba/` tree from
the most recent backup; restart `samba-ad-dc`; verify that
authentication, DNS, and LDAP all work. The rehearsal of this
procedure, on a schedule, is the difference between a recoverable
identity layer and one that is theoretically backed up. The
recommended cadence is once a quarter at the minimum, with a
rotating responsibility so that more than one person on the team
has done it.

==== Honest assessment of what this architecture does and does not give

The pattern above gives an organisation a single identity substrate
that authenticates Windows, Linux, and macOS clients, with file
shares whose authorisation is centrally managed, with audit logs
that record authentication events, with a configuration that is
mostly declarative and entirely in version control, and with a
recovery procedure that has been tested. It is a substantially
stronger identity foundation than the distributed-accounts default
that small businesses tend to drift into, and it does the work
without a vendor in the trust path.

It does not, on its own, give the organisation everything the
identity chapter has been describing. Three gaps are worth being
explicit about.

*OIDC and SAML federation are not in this configuration.* Browser
applications that want OIDC or SAML need a layer in front. The
standard pattern is *Keycloak*, configured to federate against
the Samba LDAP backend, presenting OIDC and SAML to the
applications and consuming the LDAP directory as its user database.
This adds a second component to the identity stack, but it is the
right component, and it does not duplicate the user database, the
LDAP in Samba remains the source of truth and Keycloak is the
federation front end. Adding Keycloak to a NixOS host is its own
section's worth of configuration, which a future chapter develops.

*WebAuthn is not yet first-class in Samba AD.* Samba AD's password
policy supports the modern NIST guidance, length-based requirements,
no forced rotation on a fixed schedule, no character-class rules,
but the directory itself does not natively store WebAuthn
credentials. The pattern that works today is to have Keycloak
handle WebAuthn for browser authentication and to use smart cards
for Windows logon, with the Samba AD-issued certificate-mapping
features doing the binding. Hardware-token-only authentication for
Windows logon is achievable, but it requires more configuration
than the simpler password-plus-MFA setup, and the WebAuthn-direct
path is not yet there for Samba AD.

*The DC is a single point of failure as deployed above.* A
production deployment would have at least two domain controllers,
configured to replicate against each other, so that the loss of
one does not bring the domain down. Adding a second DC is a
straightforward extension of the configuration above, the second
DC's NixOS configuration is the same as the first's, with a
different hostname and IP, and the join command is `samba-tool
domain join` against the existing DC. For an organisation of forty
people, the operational case for the second DC is less about the
loss of a host, which the recovery procedure handles, and more
about the loss of availability during the recovery, which the
second DC eliminates. The trade is one more host to maintain
against several hours of downtime in the worst case.

These gaps are real and should be planned against. The architecture
the rest of the course assumes is the substrate developed here plus
the federation front end plus the second DC plus the WebAuthn
deployment, and a small business that has all four has a substantially
stronger identity layer than its peers. The pattern is also extensible:
the same DC, with the same group structure, is the source of truth that
mail servers, the wiki, the chat platform, the version-control system,
and every other application the organisation runs federate against.
The investment in getting it right pays back the more applications the
organisation adds, because each one consumes the substrate rather than
reproducing it.

The final architectural fact is the one this chapter began with. The
identity layer is the substrate. Every commitment the rest of the
course has made, the network's authenticated mesh, the host's verified
boot, the application's enforced authorisation, the cryptography
chapter's keys-bound-to-principals, terminates in the identity layer's
answer to "who is this?" An organisation that has built a credible
identity layer has the foundation under all of those commitments. An
organisation that has not has the commitments without the foundation,
and the commitments cannot hold up what they were not designed to hold.

#pagebreak()
