# Authenticate as a domain administrator and join the server to
# the domain. This creates a computer account in the directory and
# stores the machine credentials in /var/lib/samba/private. PASSWD_FILE
# keeps the password off the command line.
PASSWD_FILE=/run/secrets/ad-admin-password net ads join -U administrator

# Verify the join succeeded.
net ads testjoin
# Should report: Join is OK

# Verify SSSD can resolve domain users.
getent passwd 'CORP\jdoe'
# Should return a passwd entry with the user's UID, GID, and home

# Restart the dependent services so the new keytab takes effect.
systemctl restart smbd winbindd sssd
