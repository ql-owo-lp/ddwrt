#!/bin/sh

_install_hosts() {
$AUTOLOADER_LOG 'installing hosts(mvps.org)...'
$AUTOLOADER_FETCH $AUTOLOADER_PATH/hosts/mvps.org http://www.mvps.org/winhelp2002/hosts.txt hosts.fetch.plain[mvps.org]
$AUTOLOADER_LOG "hosts.plain.finished[mvps.org] installed, finish..."
}

_install_adblock() {
$AUTOLOADER_LOG 'installing hosts(adblock)...'
$AUTOLOADER_GUNZIP $AUTOLOADER_PATH/hosts/adblock $AUTOLOADER_URL/other/hosts/adblock/hosts.gz hosts.fetch.plain[adblock]
$AUTOLOADER_LOG "hosts.plain.finished[adblock] installed, finish..."
}

_install_activation() {
$AUTOLOADER_LOG 'installing hosts(activation)...'
$AUTOLOADER_GUNZIP $AUTOLOADER_PATH/hosts/activation $AUTOLOADER_URL/other/hosts/activation-block/hosts.gz hosts.fetch.plain[activation]
$AUTOLOADER_LOG "hosts.plain.finished[activation] installed, finish..."
}

_install_gfw() {
$AUTOLOADER_LOG 'installing hosts(gfw)...'
$AUTOLOADER_FETCH $AUTOLOADER_PATH/hosts/gfw $AUTOLOADER_URL/other/hosts/gfw/hosts hosts.fetch.plain[gfw]
$AUTOLOADER_LOG "hosts.plain.finished[gfw] installed, finish..."
}

_install_adblock &
_install_hosts &
_install_activation &
_install_gfw &

while [ `cat $AUTOLOADER_PATH/.log | grep 'hosts.plain.finished\[.*\]' | wc -l` -lt 4 ] ; do sleep 10; done
$AUTOLOADER_PATH/merge $AUTOLOADER_PATH/hosts /tmp/hosts
for file in `find $AUTOLOADER_PATH/hosts -type f | grep -v default`; do
  rm -f $file
done
$AUTOLOADER_FILTER_HOSTS /tmp/hosts
$AUTOLOADER_LOG 'ALL hosts installed'
$AUTOLOADER_PATH/dnsmasq.restart &