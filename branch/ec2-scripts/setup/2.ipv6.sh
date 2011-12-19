cat > /usr/ipv6-setup <<EOF
#!/bin/sh
ifconfig sit0 up
ifconfig sit0 inet6 tunnel ::74.82.46.6
ifconfig sit1 up
ifconfig sit1 inet6 add 2001:470:23:541::2/64
route -A inet6 add ::/0 dev sit1
EOF

chmod +x /usr/ipv6-setup

sed -i 's/^exit 0/\/usr\/ipv6-setup\n\nexit 0/' /etc/rc.local

echo "*/4 * * * * root ping6 -c 2 ipv6.google.com" >> /etc/crontab

service cron reload
