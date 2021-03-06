
#!/bin/bash

# check prerequisite
if ! command -v ipset &> /dev/null; then echo "ipset could not be found" && exit 1; fi
if ! command -v ncat &> /dev/null; then echo "ncat could not be found" && exit 1; fi

# IPTables create chain "blocklists"
iptables -N blocklists
# make chain in 1st position :
# delete if needed : iptables -D INPUT -j blocklists
for _CHX in INPUT OUTPUT FORWARD; do
iptables -I "$_CHX" 1 -j blocklists
done
# create ipset list "honeypot"
ipset create honeypot ip:hash
# add ipset 'honeypot' list to the blocklists chain :
iptables -A blocklists -m set --match-set honeypot src -j DROP
iptables -A blocklists -m set --match-set honeypot dst -j DROP
# or add all ipset lists to newly created chain
for _BLX in $(ipset list -n); do
iptables -A blocklists -m set --match-set $_BLX src -j DROP
iptables -A blocklists -m set --match-set $_BLX dst -j DROP
done

# copy scripts to path
mkdir /root/blacklist
for _SCR in blacklist-check killhony ncat-honeypot honeypot-banscript ipset-report; do
cp "$_SCR" /usr/local/bin/
done
# copy sample Systemd service file and start. [Ctrl+C] if service "seems" to block
cp honeypot.service /etc/systemd/system/honeypot.service
systemctl daemon-reload
systemctl start honeypot.service
# check honeypot configured port 
ss -tlpn|grep -w 22

LISTEN 0      10           0.0.0.0:22         0.0.0.0:*    users:(("ncat",pid=1041,fd=4))
LISTEN 0      10              [::]:22            [::]:*    users:(("ncat",pid=1041,fd=3))

