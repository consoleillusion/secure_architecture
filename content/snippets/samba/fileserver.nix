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
