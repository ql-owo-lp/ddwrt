#!/bin/sh

_install_adblock() {
$AUTOLOADER_LOG 'installing hosts(adblock)...'
$AUTOLOADER_GUNZIP $AUTOLOADER_PATH/hosts/adblock $AUTOLOADER_URL/other/hosts/adblock/hosts.gz hosts.fetch.zip[adblock]
$AUTOLOADER_LOG "hosts.fetch.zip.finished[adblock]hosts(adblock) installed, finish..."
}

_install_activation() {
$AUTOLOADER_LOG 'installing hosts(activation)...'
$AUTOLOADER_GUNZIP $AUTOLOADER_PATH/hosts/activation $AUTOLOADER_URL/other/hosts/activation-block/hosts.gz hosts.fetch.zip[activation]
$AUTOLOADER_LOG "hosts.fetch.zip.finished[activation]hosts(activation) installed, finish..."
}

_install_gfw() {
$AUTOLOADER_LOG 'installing hosts(gfw)...'
$AUTOLOADER_FETCH $AUTOLOADER_PATH/hosts/gfw $AUTOLOADER_URL/other/hosts/gfw/hosts hosts.fetch.zip[gfw]
$AUTOLOADER_LOG "hosts.fetch.zip.finished[gfw]hosts(gfw) installed, finish..."
}

_install_hosts() {
$AUTOLOADER_LOG 'installing hosts(mvps.org)...'
$AUTOLOADER_FETCH $AUTOLOADER_TMP/hosts.zip http://www.mvps.org/winhelp2002/hosts.zip hosts.fetch.zip[mvps.org] &
$AUTOLOADER_FETCH_EXEC_GZ $AUTOLOADER_DIR/unzip.setup $AUTOLOADER_URL/auto-installer/optware/script/unzip.sh &
rm -f $AUTOLOADER_TMP/hosts
# check if hosts.zip is fetched
while [ `cat $AUTOLOADER_PATH/.log | grep 'hosts.fetch.zip\[mvps.org\]' | wc -l` -lt 1 ] ; do sleep 10; done
while [ `cat $AUTOLOADER_PATH/.log | grep '\[unzip-installed\]' | wc -l` -lt 1 ] ; do sleep 10; done
unzip -uoCL $AUTOLOADER_TMP/hosts.zip hosts -d $AUTOLOADER_TMP
rm -f $AUTOLOADER_TMP/hosts.zip &
cp -f $AUTOLOADER_TMP/hosts $AUTOLOADER_PATH/hosts/mvps.org
rm -f $AUTOLOADER_TMP/hosts &
$AUTOLOADER_LOG "hosts.fetch.zip.finished[mvps.org]hosts(mvps.org) installed..."
}

_install_adblock &
_install_activation &
_install_gfw &
_install_hosts &

# Notice the zip file need to be extracted
while [ `cat $AUTOLOADER_PATH/.log | grep 'hosts.fetch.zip.finished\[.*\]' | wc -l` -lt 4 ] ; do sleep 10; done
$AUTOLOADER_PATH/merge $AUTOLOADER_PATH/hosts /tmp/hosts
for file in `find $AUTOLOADER_PATH/hosts -type f | grep -v default`; do
  rm -f $file
done
$AUTOLOADER_FILTER_HOSTS /tmp/hosts
$AUTOLOADER_LOG "ALL hosts installed..."
$AUTOLOADER_PATH/dnsmasq.restart &
