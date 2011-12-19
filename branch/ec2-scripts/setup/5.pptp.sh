#!/bin/sh

apt-get -y install pptpd

IPRANGE="192.168.240"

cat >> /etc/pptpd.conf <<EOF
localip $IPRANGE.1
remoteip $IPRANGE.2-100
EOF

cat >> /etc/ppp/pptpd-options <<EOF
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF

/etc/init.d/pptpd restart

cat > /usr/pptpd-ipt <<EOF
#!/bin/sh
/sbin/iptables -t nat -A POSTROUTING -s $IPRANGE.0/24 -o eth0 -j MASQUERADE
/sbin/iptables -A FORWARD -p tcp --syn -s $IPRANGE.0/24 -j TCPMSS --set-mss 1356
EOF

chmod +x /usr/pptpd-ipt

sed -i 's/^exit 0/\/usr\/pptpd-ipt\n\nexit 0/' /etc/rc.local
