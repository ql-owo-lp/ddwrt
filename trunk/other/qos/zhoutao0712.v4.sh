#copyright by zhoutao0712
UIP="192.168.1."
NET="192.168.1.0/24"
IPS="2"
IPE="20"
UP=35
DOWN=175
UPLOADR=1
UPLOADC=15
DOWNLOADR=10
DOWNLOADC=$((DOWN*9/10))
UPLOADR2=1
UPLOADC2=5
DOWNLOADR2=2
DOWNLOADC2=$((DOWN*6/10))

modprobe imq
modprobe ipt_IMQ
modprobe ipt_length
modprobe ipt_hashlimit
ifconfig imq1 up
ifconfig imq0 up
iptables -t mangle -N QOSDOWN
iptables -t mangle -N QOSUP
iptables -t mangle -A PREROUTING -p ! icmp -s $NET -d ! $NET -j QOSUP
iptables -t mangle -I POSTROUTING -p ! icmp -d $NET -s ! $NET -j QOSDOWN
iptables -t mangle -A OUTPUT -o br0 -j ACCEPT
iptables -t mangle -A INPUT -i br0 -j ACCEPT
iptables -t mangle -A OUTPUT -j QOSUP
iptables -t mangle -A INPUT -j QOSDOWN

iptables -t mangle -A QOSDOWN -p udp -m mport --sports 53,67,68 -j RETURN
iptables -t mangle -A QOSUP -p udp -m mport --dports 53,67,68 -j RETURN
iptables -t mangle -N PUNISH0
iptables -t mangle -A QOSUP -p udp -j PUNISH0
iptables -t mangle -A PUNISH0 -m hashlimit --hashlimit 100/sec --hashlimit-mode srcip --hashlimit-name udplmt -j RETURN
iptables -t mangle -A PUNISH0 -m recent --rcheck --seconds 20 -j DROP
iptables -t mangle -A PUNISH0 -m recent --set
iptables -t mangle -N NEWCONN
iptables -t mangle -A QOSUP -m state --state NEW -j NEWCONN
iptables -t mangle -A NEWCONN -p ! tcp -m connlimit --connlimit-above 100 -j DROP
iptables -t mangle -A NEWCONN -p tcp -m connlimit --connlimit-above 200 -j DROP

iptables -t mangle -A QOSDOWN -p tcp ! --syn -m length --length :128 -j RETURN
iptables -t mangle -A QOSUP -p tcp ! --syn -m length --length :80 -j RETURN

iptables -t mangle -A QOSDOWN -j IMQ --todev 0
iptables -t mangle -A QOSUP -j IMQ --todev 1

iptables -t mangle -A QOSDOWN -p tcp -m length --length :768 -j MARK --set-mark-return 255
iptables -t mangle -A QOSUP -p tcp -m length --length :512 -j MARK --set-mark-return 255
iptables -t mangle -A QOSDOWN -p tcp -m mport --sports 80,443,25,110 -j BCOUNT
iptables -t mangle -A QOSDOWN -p tcp -m mport --sports 80,443,25,110 -m bcount --range :153600 -j MARK --set-mark-return 254
iptables -t mangle -A QOSUP -p tcp -m mport --dports 80,443,25,110 -j BCOUNT
iptables -t mangle -A QOSUP -p tcp -m mport --dports 80,443,25,110 -m bcount --range :51200 -j MARK --set-mark-return 254
iptables -t mangle -A QOSDOWN -m recent --rdest --rcheck  --seconds 120 -j MARK --set-mark-return 253
iptables -t mangle -A QOSUP -p udp -m recent --rcheck --seconds 120 -j MARK --set-mark-return 253
iptables -t mangle -A QOSDOWN -j MARK --set-mark 252
iptables -t mangle -A QOSUP -j MARK --set-mark 252

if [ $(cat /tmp/qos_state) -eq 1 ]
then
exit
else
echo 1 >/tmp/qos_state
fi
tc qdisc del dev imq0 root;tc qdisc del dev imq1 root
tc qdisc add dev imq0 root handle 1: htb default 999
tc qdisc add dev imq1 root handle 1: htb default 999
tc class add dev imq1 parent 1: classid 1:1 htb rate $((UP))kbps
tc class add dev imq0 parent 1: classid 1:1 htb rate $((DOWN))kbps
tc class add dev imq0 parent 1:1 classid 1:5000 htb rate $((DOWN/5))kbps quantum 15000 prio 1
tc filter add dev imq0 parent 1:0 protocol ip prio 5 handle 255 fw flowid 1:5000
tc class add dev imq1 parent 1:1 classid 1:5000 htb rate $((UP))kbps quantum 15000 prio 1
tc filter add dev imq1 parent 1:0 protocol ip prio 5 handle 255 fw flowid 1:5000
tc class add dev imq0 parent 1:1 classid 1:4000 htb rate $((DOWN/10))kbps ceil $((DOWN*6/10))kbps quantum 8000 prio 3
tc filter add dev imq0 parent 1:0 protocol ip prio 10 handle 254 fw flowid 1:4000
tc class add dev imq1 parent 1:1 classid 1:4000 htb rate $((UP/10))kbps ceil $((UP/2))kbps quantum 1500 prio 3
tc filter add dev imq1 parent 1:0 protocol ip prio 10 handle 254 fw flowid 1:4000
tc class add dev imq1 parent 1:1 classid 1:3000 htb rate $((UP/3))kbps ceil $((UP))kbps
tc class add dev imq0 parent 1:1 classid 1:3000 htb rate $((DOWN/3))kbps ceil $((DOWN))kbps
tc filter add dev imq1 parent 1:0 protocol ip prio 20 handle 253 fw flowid 1:3000
tc filter add dev imq0 parent 1:0 protocol ip prio 20 handle 253 fw flowid 1:3000
tc class add dev imq1 parent 1:1 classid 1:2000 htb rate $((UP*2/3))kbps ceil $((UP))kbps
tc class add dev imq0 parent 1:1 classid 1:2000 htb rate $((DOWN*2/3))kbps ceil $((DOWN))kbps
tc filter add dev imq1 parent 1:0 protocol ip prio 15 handle 252 fw flowid 1:2000
tc filter add dev imq0 parent 1:0 protocol ip prio 15 handle 252 fw flowid 1:2000
tc filter add dev imq0 parent 1:3000 prio 200 handle f0: protocol ip u32 divisor 256
tc filter add dev imq0 protocol ip parent 1:3000 prio 200 u32 ht 800:: match ip dst $NET hashkey mask 0x000000ff at 16 link f0:
tc filter add dev imq1 parent 1:3000 prio 200 handle f0: protocol ip u32 divisor 256
tc filter add dev imq1 protocol ip parent 1:3000 prio 200 u32 ht 800:: match ip src $NET hashkey mask 0x000000ff at 12 link f0:
tc filter add dev imq0 parent 1:2000 prio 100 handle f1: protocol ip u32 divisor 256
tc filter add dev imq0 protocol ip parent 1:2000 prio 100 u32 ht 801:: match ip dst $NET hashkey mask 0x000000ff at 16 link f1:
tc filter add dev imq1 parent 1:2000 prio 100 handle f1: protocol ip u32 divisor 256
tc filter add dev imq1 protocol ip parent 1:2000 prio 100 u32 ht 801:: match ip src $NET hashkey mask 0x000000ff at 12 link f1:
n=$IPS;
while [ $n -le $IPE ]
do
m=$(printf "%x\n" $n)
tc class add dev imq1 parent 1:3000 classid 1:${n}f htb rate $((UPLOADR2))kbps ceil $((UPLOADC2))kbps quantum 1500 prio 7
tc class add dev imq0 parent 1:3000 classid 1:${n}f htb rate $((DOWNLOADR2))kbps ceil $((DOWNLOADC2))kbps quantum 1500 prio 7
tc qdisc add dev imq1 parent 1:${n}f handle ${n}f bfifo limit 8kb
tc qdisc add dev imq0 parent 1:${n}f handle ${n}f sfq perturb 15
tc filter add dev imq1 parent 1:3000 protocol ip prio 200 u32 ht f0:${m}: match ip src 0/0 flowid 1:${n}f
tc filter add dev imq0 parent 1:3000 protocol ip prio 200 u32 ht f0:${m}: match ip dst 0/0 flowid 1:${n}f
tc class add dev imq1 parent 1:2000 classid 1:${n}a htb rate $((UPLOADR))kbps ceil $((UPLOADC))kbps quantum 1500 prio 5
tc class add dev imq0 parent 1:2000 classid 1:${n}a htb rate $((DOWNLOADR))kbps ceil $((DOWNLOADC))kbps quantum 2000 prio 5
tc qdisc add dev imq1 parent 1:${n}a handle ${n}a bfifo limit 8kb
tc qdisc add dev imq0 parent 1:${n}a handle ${n}a sfq perturb 15
tc filter add dev imq1 parent 1:2000 protocol ip prio 100 u32 ht f1:${m}: match ip src 0/0 flowid 1:${n}a
tc filter add dev imq0 parent 1:2000 protocol ip prio 100 u32 ht f1:${m}: match ip dst 0/0 flowid 1:${n}a
n=$((n+1))
done
tc class add dev imq1 parent 1:1 classid 1:999 htb rate 1kbps ceil $((UP/5))kbps quantum 1500 prio 7
tc class add dev imq0 parent 1:1 classid 1:999 htb rate 2kbps ceil $((DOWN))kbps quantum 1500 prio 7
echo 0 >/tmp/qos_state

iptables -t mangle -I PUNISH0 -m iprange --src-range 192.168.1.80-192.168.1.90 -j RETURN
iptables -t mangle -I PUNISH0 -s 192.168.1.8 -j RETURN

cat >/tmp/qos_scheduler <<"EOF"
echo 1 >/tmp/state_scheduler
if [ $(cat /proc/net/arp|fgrep -c 0x2) -eq 1 ]
then
ifconfig imq0 down
ifconfig imq1 down
exit
fi
if [ $(ifconfig |grep -c imq0) -eq 0 ]
then
ifconfig imq0 up
ifconfig imq1 up
fi
ip neigh flush dev $(nvram get lan_ifname)
EOF
chmod +x /tmp/qos_scheduler
cru d qos_scheduler
echo -e '*/1 * * * *  sh /tmp/qos_scheduler #qos_scheduler#' >>/tmp/var/spool/cron/crontabs/root