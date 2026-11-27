# Stop the AD DC service if it is running. It will fail to start
# without a provisioned database; this is expected.
systemctl stop samba-ad-dc

# Run the provisioner with the deployment's chosen values. The password is
# briefly visible in the process list while Samba starts; see the note in the
# chapter about restricting process inspection on this host.
samba-tool domain provision \
    --server-role=dc \
    --use-rfc2307 \
    --dns-backend=SAMBA_INTERNAL \
    --realm=CORP.EXAMPLE.COM \
    --domain=CORP \
    --adminpass="$(cat /run/secrets/ad-admin-password)" \
    --host-ip=10.42.0.10 \
    --host-name=dc01

# The provisioner writes /var/lib/samba/private/krb5.conf. The
# NixOS module declares /etc/krb5.conf from that path; no manual symlink.

# Start the AD DC.
systemctl start samba-ad-dc
