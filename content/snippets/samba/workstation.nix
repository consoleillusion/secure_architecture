{ config, lib, pkgs, ... }:

{
  # The SSSD configuration block is the same as in fileserver.nix; only the
  # Samba member-server module is omitted on a workstation.
  services.sssd.enable = true;

  # Allow Kerberos-authenticated SSH between domain hosts.
  services.openssh.settings.GSSAPIAuthentication = true;

  # CIFS mount support, for accessing SMB shares with the user's
  # Kerberos ticket.
  environment.systemPackages = with pkgs; [ cifs-utils ];

  # Optional: an automounter for SMB shares, so users can `cd`
  # into a mount of //fs01/shared and have it mounted on demand.
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
}
