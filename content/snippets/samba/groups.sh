# On the DC: create the group, if it does not exist, and add users.
samba-tool group add Engineering --description="Engineering team"
samba-tool group addmembers Engineering "jdoe,asmith,bnguyen"

# On the file server: create the directory and set its ACL so that
# only the Engineering group has write access. setfacl with NFSv4
# ACLs (which Samba's acl_xattr maps to NTFS-style ACLs) is the
# right tool here.
mkdir -p /srv/engineering
chown root:"CORP\\Engineering" /srv/engineering
chmod 2770 /srv/engineering
setfacl -m "g:CORP\\Engineering:rwx" /srv/engineering
setfacl -d -m "g:CORP\\Engineering:rwx" /srv/engineering
