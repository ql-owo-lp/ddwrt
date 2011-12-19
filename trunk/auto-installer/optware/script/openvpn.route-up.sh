#!/bin/sh

# take the prefix
VPN_NAME=`basename $0 | cut -d '.' -f1`
VPN_DEV='tun1'

# default set to openvpn style
if [[ $VPN_NAME == 'pptp' ]]; then
  VPN_SUB=$(nvram get pptpd_client_srvsub)
  VPN_DEV=$(route -n | grep ^${VPN_SUB%.[0-9]*} | awk '{print $NF}' | head -n 1)
fi

if [ -f "$AUTOLOADER_PATH/.lock.$VPN_NAME.up" ]; then exit ; fi
echo > $AUTOLOADER_PATH/.lock.$VPN_NAME.up

VPNGW=$(ifconfig "$VPN_DEV" | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
$AUTOLOADER_LOG "$VPN_NAME is up, tunnel gateway($VPNGW). Now fetch GFW route policies.."

# Analysis gfwlist, but don't know where to use it yet
# if squid rewriter works, this may help
_install_gfwlist() {
  $AUTOLOADER_FETCH $AUTOLOADER_TMP/gfw.list.tmp http://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt
  echo -e '\n====' >> $AUTOLOADER_TMP/gfw.list.tmp
  echo 'begin-base64 644 -' | cat - $AUTOLOADER_TMP/gfw.list.tmp > $AUTOLOADER_TMP/gfw.list
  rm -f $AUTOLOADER_TMP/gfw.list.tmp &
  uudecode $AUTOLOADER_TMP/gfw.list | tail +2 | egrep -e '^[^!]+$' > $AUTOLOADER_TMP/gfw.list
  rm -f $AUTOLOADER_TMP/gfw.list &
}

_install_gfw() {
  $AUTOLOADER_FETCH $AUTOLOADER_TMP/gfw.autovpn http://autoddvpn.googlecode.com/svn/trunk/grace.d/vpnup.sh
cat > $AUTOLOADER_PATH/script/firewall/gfw.autovpn << EOF
if [ -f '$AUTOLOADER_PATH/.lock.gfw.autovpn' ]; then exit; fi
echo > $AUTOLOADER_PATH/.lock.gfw.autovpn
if [ ! -z "$VPN_SUB" ]; then
  VPN_DEV=\$(route -n | grep ^${VPN_SUB%.[0-9]*} | awk '{print \$NF}' | head -n 1)
else
  VPN_DEV=$VPN_DEV
fi
while [ -z \$(ifconfig \$VPN_DEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2) ] ; do sleep 20; done
VPNGW=\$(ifconfig \$VPN_DEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
EOF
  cat $AUTOLOADER_TMP/gfw.autovpn | egrep '^route add' >> $AUTOLOADER_PATH/script/firewall/gfw.autovpn
  echo "rm -f $AUTOLOADER_PATH/.lock.gfw.autovpn" >> $AUTOLOADER_PATH/script/firewall/gfw.autovpn
  sh $AUTOLOADER_PATH/script/firewall/gfw.autovpn &
  rm -f $AUTOLOADER_TMP/gfw.autovpn &
}

# when adding route for domain, async execution is not recommended, massive DNS resolve will kill the router
_install_gfw_domain() {
  $AUTOLOADER_FETCH $AUTOLOADER_PATH/dnsmasq/gfw.domain http://autoddvpn.googlecode.com/svn/trunk/grace.d/gfwdomains
  cat $AUTOLOADER_PATH/dnsmasq/gfw.domain | egrep -e '^server=\/.+\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > $AUTOLOADER_PATH/dnsmasq/gfw.domain
  $AUTOLOADER_PATH/merge $AUTOLOADER_PATH/dnsmasq /tmp/dnsmasq.conf
  $AUTOLOADER_PATH/dnsmasq.restart &
}

_install_gfw_custom() {
  # create route records into gfw.custom
  $AUTOLOADER_FETCH $AUTOLOADER_TMP/gfw.custom $AUTOLOADER_URL/other/g-list/list.txt
  cat $AUTOLOADER_TMP/gfw.custom | egrep -e '^[0-9a-zA-Z\.\/]+$' > $AUTOLOADER_TMP/gfw.custom
cat > $AUTOLOADER_PATH/script/firewall/gfw.custom << EOF
if [ -f '$AUTOLOADER_PATH/.lock.gfw.custom' ]; then exit; fi
echo > $AUTOLOADER_PATH/.lock.gfw.custom
if [ ! -z "$VPN_SUB" ]; then
  VPN_DEV=\$(route -n | grep ^${VPN_SUB%.[0-9]*} | awk '{print \$NF}' | head -n 1)
else
  VPN_DEV=$VPN_DEV
fi
while [ -z \$(ifconfig \$VPN_DEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2) ] ; do sleep 20; done
VPNGW=\$(ifconfig \$VPN_DEV | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
EOF
  # grep hosts
  cat $AUTOLOADER_TMP/gfw.custom | egrep -e '^[0-9a-zA-Z\.]+\.[a-zA-Z]+$|^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | while read host; do
    echo route add -host "$host" gw '$VPNGW' >> $AUTOLOADER_PATH/script/firewall/gfw.custom
  done
  # grep net
  cat $AUTOLOADER_TMP/gfw.custom | egrep -e '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$'  | while read host; do
    echo route add -net "$host" gw '$VPNGW' >> $AUTOLOADER_PATH/script/firewall/gfw.custom
  done
  echo "rm -f $AUTOLOADER_PATH/.lock.gfw.custom" >> $AUTOLOADER_PATH/script/firewall/gfw.custom
  rm -f $AUTOLOADER_TMP/gfw.custom ; sh $AUTOLOADER_PATH/script/firewall/gfw.custom &
}

#_install_gfwlist &
_install_gfw &
# something wrong with the dnsmasq
#_install_gfw_domain &
_install_gfw_custom &

$AUTOLOADER_LOG 'GFW route fetch finished.' &
rm -f $AUTOLOADER_PATH/.lock.$VPN_NAME.up
