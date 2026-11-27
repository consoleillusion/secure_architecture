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
      ];
      # Samba AD allocates dynamic RPC endpoints in 49152-65535. Pin
      # individual services to fixed ports first, then narrow this range.
      allowedTCPPortRanges = [
        { from = 49152; to = 65535; }
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

  # The generated krb5.conf is exposed from the DC state directory
  # rather than created by a hand-run symlink.
  environment.etc."krb5.conf".source = "/var/lib/samba/private/krb5.conf";

  # Backups: the directory itself is in /var/lib/samba, which is
  # snapshotted by the host's backup substrate. The keys are in
  # /var/lib/samba/private and are backed up separately, encrypted,
  # to the offline-keys location the cryptography chapter develops.
  # The backup configuration itself lives in the host module.
}
