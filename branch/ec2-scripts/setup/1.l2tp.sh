#!/bin/bash

vpsip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
vpsgw=`ip route | grep 'default' | awk '{print $3}'`

# IP Range
iprange="172.16.10"
# Pre-share key
mypsk="tossing.co.in"

clear
get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}

apt-get -y update
apt-get -y upgrade
apt-get -y install libgmp3-dev bison flex libpcap-dev ppp iptables make gcc lsof vim
mkdir /ztmp
mkdir /ztmp/l2tp
cd /ztmp/l2tp
wget http://www.openswan.org/download/openswan-2.6.24.tar.gz
tar zxvf openswan-2.6.24.tar.gz
cd openswan-2.6.24
make programs install
rm -rf /etc/ipsec.conf
touch /etc/ipsec.conf
cat >>/etc/ipsec.conf<<EOF
config setup
    nat_traversal=yes
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
    oe=off
    protostack=netkey

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=$vpsip
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any

conn passthrough-for-non-l2tp
    type=passthrough
    left=$vpsip
    leftnexthop=$vpsgw
    right=0.0.0.0
    rightsubnet=0.0.0.0/0
    auto=route
EOF
cat >>/etc/ipsec.secrets<<EOF
$vpsip %any: PSK "$mypsk"
EOF
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
sysctl -p
iptables --table nat --append POSTROUTING --jump MASQUERADE
for each in /proc/sys/net/ipv4/conf/*
do
echo 0 > $each/accept_redirects
echo 0 > $each/send_redirects
done
/etc/init.d/ipsec restart
ipsec verify
cd /ztmp/l2tp
wget http://mirror.zeddicus.com/sources/rp-l2tp-0.4.tar.gz
tar zxvf rp-l2tp-0.4.tar.gz
cd rp-l2tp-0.4
./configure
make
cp handlers/l2tp-control /usr/local/sbin/
mkdir /var/run/xl2tpd/
ln -s /usr/local/sbin/l2tp-control /var/run/xl2tpd/l2tp-control
cd /ztmp/l2tp
wget http://mirror.zeddicus.com/sources/xl2tpd-1.2.4.tar.gz
tar zxvf xl2tpd-1.2.4.tar.gz
cd xl2tpd-1.2.4
make install
mkdir /etc/xl2tpd
rm -rf /etc/xl2tpd/xl2tpd.conf
cat >/etc/xl2tpd/xl2tpd.conf<<EOF
[global]
ipsec saref = yes
[lns default]
ip range = $iprange.2-$iprange.254
local ip = $iprange.1
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF
rm -rf /etc/ppp/options.xl2tpd
cat >/etc/ppp/options.xl2tpd<<EOF
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
asyncmap 0
auth
crtscts
lock
hide-password
modem
debug
name l2tpd
proxyarp
lcp-echo-interval 30
lcp-echo-failure 4
EOF
touch /usr/bin/zl2tpset
echo "#/bin/bash" >>/usr/bin/zl2tpset
echo "for each in /proc/sys/net/ipv4/conf/*" >>/usr/bin/zl2tpset
echo "do" >>/usr/bin/zl2tpset
echo "echo 0 > \$each/accept_redirects" >>/usr/bin/zl2tpset
echo "echo 0 > \$each/send_redirects" >>/usr/bin/zl2tpset
echo "done" >>/usr/bin/zl2tpset
chmod +x /usr/bin/zl2tpset
iptables --table nat --append POSTROUTING --jump MASQUERADE
zl2tpset
xl2tpd

cat > /usr/l2tp-setup <<EOF
#!/bin/sh
/sbin/iptables -t nat -A POSTROUTING -s $iprange.0/24 -o eth0 -j MASQUERADE
/etc/init.d/ipsec restart
/usr/bin/zl2tpset
mkdir /var/run/xl2tpd/
ln -s /usr/local/sbin/l2tp-control /var/run/xl2tpd/l2tp-control
/usr/local/sbin/xl2tpd
EOF

chmod +x /usr/l2tp-setup

sed -i 's/^exit 0/\/usr\/l2tp-setup\n\nexit 0/' /etc/rc.local

clear

ipsec verify
printf "l2tp installed"

