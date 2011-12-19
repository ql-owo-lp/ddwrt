#!/bin/sh

# load adblock script
$AUTOLOADER_WANUP squid.adblock $AUTOLOADER_URL/auto-installer/optware/script/squid.adblock.sh &

insmod ipt_mark &
insmod ipt_CONNMARK &

$AUTOLOADER_LOG 'squid up, updating iptables..'

# Notice table 191 and mark 191 are not used by other progresses.
cat > $AUTOLOADER_PATH/script/firewall/squid.up << EOF
IP_LIST=\`ifconfig |grep 'inet addr:.*Bcast'|awk '{print \$2}'|sed 's/addr://g'|grep -v '^169.254'\`

# here define which ports are allowed to be proxied by squid
# transparent proxy works not well with https(443)
for PORT in 80 21; do
  # by-pass the squid
  iptables -t mangle -A PREROUTING -p tcp --dport \$PORT -s `nvram get lan_ipaddr` -j ACCEPT
  iptables -t mangle -A PREROUTING -p tcp --dport \$PORT -d `nvram get lan_ipaddr` -j ACCEPT
  # Merely match packets with no mark, while WTF the DD-WRT support nothing of mark match!!
  iptables -t mangle -A PREROUTING -p tcp --dport \$PORT -j CONNMARK --restore-mark
  iptables -t mangle -A PREROUTING -p tcp --dport \$PORT -m mark --mark 0 -j MARK --set-mark 191
  # iptables -t mangle -A PREROUTING -p tcp --dport \$PORT -j MARK --set-mark 191
  # Redirect to 3128
  for IP in \$IP_LIST; do
    iptables -t nat -A PREROUTING ! -d \$IP ! -s \$IP -p tcp --dport \$PORT -j REDIRECT --to-port 3128
  done
done
iptables -t mangle -A PREROUTING -m mark --mark 191 -j CONNMARK --save-mark

if [ \`ip rule | grep 'lookup 191' | wc -l\` -lt 1 ]; then
  ip rule add fwmark 191 table 191
fi
if [ \`ip route list table 191 | wc -l\` -lt 1 ]; then
  ip route add 0/0 via `nvram get lan_ipaddr` table 191
fi
EOF

# wait modules to be installed
sleep 10
sh $AUTOLOADER_PATH/script/firewall/squid.up &
sleep 5; rm -f $0 &