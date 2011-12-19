#!/bin/sh
# wait until ipkg-opt is ready
while [ `cat $AUTOLOADER_PATH/.log | grep '\[ipkg-opt-ALL-installed\]' | wc -l` -lt 1 ] ; do
  $AUTOLOADER_LOG 'Unzip install progress : Wait for ipkg-opt... sleep 15sec'
  sleep 15
done

LIST="$(ipkg-opt list_installed)"
$AUTOLOADER_LOG 'Unzip installing..'
if [ `echo $LIST | grep bzip2 | wc -l` -lt 1 ]; then
  $AUTOLOADER_LOG 'ipkg-opt : installing bzip2...'
	if [ $AUTOLOADER_URL_OPTWARE_CUST -eq 1 ] ; then
	  ipkg-opt install $AUTOLOADER_URL_OPTWARE/bzip2_1.0.6-1_mipsel.ipk
	else
	  ipkg-opt install bzip2
	fi
fi
if [ `echo $LIST | grep unzip | wc -l` -lt 1 ]; then
if [ $AUTOLOADER_URL_OPTWARE_CUST -eq 1 ] ; then
  $AUTOLOADER_LOG 'ipkg-opt : installing unzip...'
  ipkg-opt install $AUTOLOADER_URL_OPTWARE/unzip_6.0-2_mipsel.ipk
else
  ipkg-opt install unzip
fi
fi

$AUTOLOADER_LOG '[unzip-installed]Unzip finished..'

sleep 5; rm -f $0 &