#!/bin/sh
# wait until ipkg-opt is ready
while [ `cat $AUTOLOADER_PATH/.log | grep '\[ipkg-opt-ALL-installed\]' | wc -l` -lt 1 ] ; do
  $AUTOLOADER_LOG 'Squid install progress : Wait for ipkg-opt... sleep 15sec'
  sleep 15
done

$AUTOLOADER_GUNZIP $AUTOLOADER_TMP/squid.conf $AUTOLOADER_URL/auto-installer/optware/script/squid.conf.gz squid.conf &

$AUTOLOADER_LOG 'creating Squid nobody account ...'
grep -q ^nobody /etc/group  || echo "nobody:x:99:" >> /etc/group &
grep -q ^nobody /etc/passwd || echo "nobody:*:99:99:nobody:/var:/bin/false" >> /etc/passwd &

$AUTOLOADER_LOG 'making Squid folders ...'
mkdir -p /opt/var/squid/cache/ ; mkdir -p /opt/var/squid/logs/ &

chmod 777 /opt/var/squid &
chmod 777 /opt/var/squid/logs &
chmod 777 /opt/var/squid/cache &

LIST="$(ipkg-opt list_installed)"
$AUTOLOADER_LOG 'Squid installing ...'
if [ `echo $LIST | grep libuclibc++ | wc -l` -lt 1 ]; then
	if [ $AUTOLOADER_URL_OPTWARE_CUST -eq 1 ]; then
	  ipkg-opt install $AUTOLOADER_URL_OPTWARE/libuclibc++_0.2.2-9_mipsel.ipk
	else
	  ipkg-opt install libuclibc++
	fi
fi; $AUTOLOADER_LOG '[libuclibc++-installed]' &
if [ `echo $LIST | grep squid3 | wc -l` -lt 1 ] ; then
	if [ $AUTOLOADER_URL_OPTWARE_CUST -eq 1 ] ; then
	  ipkg-opt install $AUTOLOADER_URL_OPTWARE/squid3_3.1.8-1_mipsel.ipk
	else
	  ipkg-opt install squid3
	fi
fi; $AUTOLOADER_LOG '[squid3-installed]' &

while [[ `cat $AUTOLOADER_PATH/.log | grep '\[libuclibc++-installed\]' | wc -l` -lt 1 || `cat $AUTOLOADER_PATH/.log | grep '\[squid3-installed\]' | wc -l` -lt 1 ]]; do
  sleep 10;
done
/opt/sbin/ldconfig
$AUTOLOADER_LOG 'Squid install finished'

while [  `cat $AUTOLOADER_PATH/.log | grep 'fetched\[squid.conf\]' | wc -l` -lt 1 ] ; do
  $AUTOLOADER_LOG 'Squid.conf not ready yet?? wait 20sec'
  sleep 20
done

$AUTOLOADER_LOG 'compressing Squid files..'
cat $AUTOLOADER_TMP/squid.conf | sed -e 's/#.*$//g' | egrep '^.+$'> /opt/etc/squid/squid.conf
cat /opt/etc/squid/cachemgr.conf | sed -e 's/#.*$//g' | egrep '^.+$' > /opt/etc/squid/cachemgr.conf
cat /opt/etc/squid/mime.conf | sed -e 's/#.*$//g' | egrep '^.+$' > /opt/etc/squid/mime.conf
cat /opt/etc/squid/squid.delay-start.sh | sed -e 's/#.*$//g' | egrep '^.+$' > /opt/etc/squid/squid.delay-start.sh
cat /opt/etc/squid/errorpage.css | sed -e 's/\/\*.*\*\/$//g' | egrep '^.+$' > /opt/etc/squid/errorpage.css

squid -z ; /opt/etc/init.d/S80squid start &

$AUTOLOADER_FETCH_EXEC_GZ $AUTOLOADER_DIR/squid.up $AUTOLOADER_URL/auto-installer/optware/script/squid.up.sh &

#clean job, delete some useless file to save memory
rm -f $AUTOLOADER_TMP/squid.conf &
rm -f /opt/etc/squid/cachemgr.conf.default &
rm -f /opt/etc/squid/errorpage.css.default &
rm -f /opt/etc/squid/mime.conf.default &
rm -f /opt/etc/squid/squid.conf.default &
rm -f /opt/etc/squid/squid.conf.documented &

sleep 5; rm -f $0 &