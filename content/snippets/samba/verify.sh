# Kerberos: obtain a TGT for the administrator. This exercises the
# KDC end to end.
kinit administrator@CORP.EXAMPLE.COM
klist  # should show a ticket cache with krbtgt/CORP.EXAMPLE.COM

# DNS: the AD DC should be answering queries for the realm.
dig @10.42.0.10 _ldap._tcp.corp.example.com SRV
# Should return an SRV record pointing at dc01.corp.example.com

# LDAP: bind to the directory using GSSAPI (Kerberos), confirming
# the LDAP server accepts the ticket the KDC issued.
ldapsearch -H ldap://dc01.corp.example.com -Y GSSAPI \
    -b "dc=corp,dc=example,dc=com" "(sAMAccountName=administrator)"

# samba-tool: a smoke test against the domain itself.
samba-tool domain info 127.0.0.1
samba-tool user list
