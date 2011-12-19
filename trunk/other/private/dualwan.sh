#!/bin/sh

# 由于 10.24.2.19 与 10.24.3.251 在同一个出口，所以做包负载均衡时只能均衡一条路(需要根据出口和进口mark)
# 对于UDP可以直接进行包负载，反正握手都木有- -

cat > $AUTOLOADER_PATH/script/firewall/dualwan.script << EOF
i=0
ROUT='ip route replace default scope global equalize'
# 与WRT54G2做TCP包负载
for WAN in \`nvram get wan_gateway\` 10.24.3.251 ; do
	let i++
	let TBL=\$i*10+100
	ip route add default via \$WAN table \$TBL
	ip route | grep link | while read ROUTE ; do
		ip route add table \$TBL to \$ROUTE
	done
	if [ \`ip rule | grep "lookup \$TBL" | wc -l\` -lt 1 ]; then
		ip rule add fwmark \$TBL table \$TBL prio \$TBL
	fi
	ip route flush table \$TBL
	ROUT="\$ROUT nexthop via \$WAN"
done
\$ROUT

# 把三条链路都加到table160中去
ip route replace default scope global equalize table 160 nexthop via \`nvram get wan_gateway\` nexthop via 10.24.3.251 nexthop via 10.24.2.19

iptables -A PREROUTING -t mangle -i br1 -j IMQ --todev 0
iptables -A PREROUTING -t mangle -i br1 -j SVQOS_IN
iptables -A POSTROUTING -t mangle -o br1 -j SVQOS_OUT

# 根据进出口标记，就算是校内路由也可以标记，因为10.24.3.251可以路由
iptables -t mangle -A PREROUTING -i ppp0 -m conntrack --ctstate NEW -j CONNMARK --set-mark 110
iptables -t mangle -A PREROUTING -i br1 -m conntrack --ctstate NEW -j CONNMARK --set-mark 120
iptables -t mangle -A POSTROUTING -o ppp0 -m conntrack --ctstate NEW -j CONNMARK --set-mark 110
iptables -t mangle -A POSTROUTING -o br1 -m conntrack --ctstate NEW -j CONNMARK --set-mark 120

# 对53端口特别保护一下，避免dns劫持，也由于OpenVPN使用了53端口
iptables -t mangle -A PREROUTING -p udp ! --dport 53 -m mark --mark 0 -j MARK --set-mark 160
# Punish
iptables -t mangle -A PREROUTING -s 10.219.219.248/29 -j MARK --set-mark 120

# 原本是根据br0 mark，这里情况特殊
iptables -t mangle -A PREROUTING -s 10.24.6.254 -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
iptables -t mangle -A PREROUTING -s 10.219.219.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark

iptables -t mangle -D SVQOS_OUT -j CONNMARK --restore-mark 2> /dev/null
EOF

sh $AUTOLOADER_PATH/script/firewall/dualwan.script &
sleep 5; rm -f $0 &