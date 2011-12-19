#!/bin/sh

IP_LIST=`ifconfig |grep 'inet addr:.*Bcast'|awk '{print $2}'|sed 's/addr://g'|grep -v '^169.254'`

# here define which ports are allowed to be proxied by squid
for PORT in 80 21; do    
  # by-pass the squid
  iptables -t mangle -A PREROUTING -p tcp --dport $PORT -s 172.16.224.7 -j ACCEPT
  iptables -t mangle -A PREROUTING -p tcp --dport $PORT -d 172.16.224.7 -j ACCEPT
  # Merely match packets with no mark, while WTF the DD-WRT support nothing of mark match!!
  iptables -t mangle -A PREROUTING -p tcp --dport $PORT -j CONNMARK --restore-mark
  iptables -t mangle -A PREROUTING -p tcp --dport $PORT -m mark --mark 0 -j MARK --set-mark 191
  # iptables -t mangle -A PREROUTING -p tcp --dport $PORT -j MARK --set-mark 191
  # Redirect to 3128
  IP=172.16.224.7
  iptables -t nat -A PREROUTING ! -d $IP ! -s $IP -p tcp --dport $PORT -j REDIRECT --to-port 3128
done
iptables -t mangle -A PREROUTING -m mark --mark 191 -j CONNMARK --save-mark

if [ `ip rule | grep 'lookup 191' | wc -l` -lt 1 ]; then
  ip rule add fwmark 191 table 191
fi
# dierectly send via 10.24.0.251
if [ `ip route list table 191 | wc -l` -lt 1 ]; then
  ip route add 0/0 via 10.24.0.251 table 191   
fi