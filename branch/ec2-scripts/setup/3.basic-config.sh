#!/bin/sh

# Debian
resize2fs /dev/xvda1
yes | mkfs -t ext3 /dev/xvda2
mkdir /mnt/data
mount /dev/xvda2 /mnt/data

cat > /etc/ppp/chap-secrets <<EOF
xjw * xjw *
wp * wp *
xl * xl *
wby * wby *
EOF

# provide ipv6 support
sed -i "s/#ListenAddress /ListenAddress /g" /etc/ssh/sshd_config
/etc/init.d/ssh restart
