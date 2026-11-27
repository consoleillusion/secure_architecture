# Practical: Samba AD DC on NixOS for cross-platform directory and file services

The remainder of the chapter develops one architectural pattern in
detail. The pattern is **a Samba Active Directory Domain Controller
running on NixOS, with separate file servers joined to the domain,
serving Linux, Windows, and macOS clients from a single identity
substrate.** The pattern is not the only valid identity architecture
for a small business, but it is a good one for the case where
cross-platform compatibility is a load-bearing requirement, and it
exercises the principles the rest of the chapter has developed
against a concrete deployment.

### The problem statement

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
deliberately, because the Samba project itself recommends it: **the
domain controller does not also serve files.** The Samba wiki is
explicit on this point and the Ubuntu Server documentation echoes it,
the AD/DC role and the file-server role have conflicting
configuration requirements and operating one machine in both roles
produces fragility neither role would have on its own. The pattern
this section develops is therefore two systems: a domain controller
that authenticates, and one or more member servers that join the
domain and serve files using credentials it issues. For an
organisation of forty people, both can be modest virtual machines.

### Why Samba AD DC and not the alternatives

A small business that wants cross-platform identity has, realistically,
four self-hosted options. The choice among them is worth being
explicit about.

**FreeIPA** is the strongest stack for Linux-heavy estates. It
bundles 389 Directory Server, MIT Kerberos, Dogtag CA, and BIND into
a coherent whole, and SSSD on Linux clients is built to talk to it.
For an estate that is mostly Linux, FreeIPA is the better choice.
For one with significant Windows presence, FreeIPA's Windows
integration is a bolt-on, the cross-realm trust to a Windows domain
is configurable but not native, and Windows clients do not join
FreeIPA the way they join AD.

**OpenLDAP plus a separate Kerberos KDC**, with the two integrated by
hand, is the configuration the older Samba documentation describes.
It is more flexible than the bundled options and considerably more
work to maintain. For an organisation of forty people it is the
wrong trade.

**Keycloak fronting an LDAP backend** is the answer when the
identity needs are predominantly browser-based. It does not, on its
own, give Windows clients something to join, and it does not produce
the Kerberos infrastructure that SMB file authentication wants.
Keycloak is the right complement to either FreeIPA or Samba AD DC
when browser federation is needed, but it is not a substitute for
either.

**Samba AD DC** is the answer when the centre of gravity is
cross-platform, and especially when Windows endpoints joining a
domain and SMB file shares respecting domain groups are part of how
the organisation actually works. The implementation is mature, the
client compatibility across Windows, Linux, and macOS is the best
the open-source landscape offers for this case, and the protocols it
exposes, AD-flavoured LDAP, Kerberos, and DNS, are well-supported on
the consuming side.

The remainder of this section assumes Samba AD DC has been chosen.

### Topology

The deployment described here uses three roles. **One domain
controller** runs Samba AD DC, the LDAP and Kerberos endpoints, and
the AD-integrated DNS. **One or more file servers** run Samba in
member-server mode, joined to the domain, serving SMB shares whose
ACLs reference domain groups. **The clients**, Windows laptops,
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

### The NixOS module: domain controller

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
        # Audit: ship every authentication and authorisation
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

### The provisioning ceremony

The configuration above describes what the DC looks like once it is
running. It does not, on its own, create the directory. Samba's AD
database has to be **provisioned** with a one-time command that
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

### Post-provisioning verification

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

### Joining a Linux file server

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

### Joining a Linux workstation

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

### Joining a Windows workstation

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

### Joining a macOS workstation

macOS has had AD binding support for two decades. The mechanism on
modern macOS is **Profile Manager** or, more often in small
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

### File-share authorisation

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

The discipline that makes this scale is **groups everywhere, users
never**. Permissions on shares are granted to groups, not to named
users, and a user's access is determined by which groups they are
in. Adding a new engineer is one command, adding them to the
`Engineering` group, and they immediately have access to everything
the group has access to. Removing them when they leave is the
inverse, one command, and access drops everywhere at once. The
revocation property the introduction promised is now operational.

### Operations: backup, observability, recovery

The DC is the single most important system in the architecture, and
its operations have to reflect that. Three concerns dominate.

**Backup.** The directory is in `/var/lib/samba/`, divided into
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

**Observability.** The audit log level set in the configuration above,
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

**Recovery.** The procedure for restoring the DC from backup, if the
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

### Honest assessment of what this architecture does and does not give

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

**OIDC and SAML federation are not in this configuration.** Browser
applications that want OIDC or SAML need a layer in front. The
standard pattern is **Keycloak**, configured to federate against
the Samba LDAP backend, presenting OIDC and SAML to the
applications and consuming the LDAP directory as its user database.
This adds a second component to the identity stack, but it is the
right component, and it does not duplicate the user database, the
LDAP in Samba remains the source of truth and Keycloak is the
federation front end. Adding Keycloak to a NixOS host is its own
section's worth of configuration, which a future chapter develops.

**WebAuthn is not yet first-class in Samba AD.** Samba AD's password
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

**The DC is a single point of failure as deployed above.** A
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
