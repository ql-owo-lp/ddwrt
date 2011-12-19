#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/sbin
unset LD_PRELOAD
unset LD_LIBRARY_PATH

_install_package() {
    PACKAGE=$1
	$AUTOLOADER_LOG "Prepare to install $PACKAGE.."
    $AUTOLOADER_FETCH /tmp/${PACKAGE} ${AUTOLOADER_URL_OPTWARE}/${PACKAGE}
    cd  /tmp 
    tar xzf /tmp/${PACKAGE} 
    tar xzf /tmp/control.tar.gz
    cd /
    if [ -f /tmp/preinst ] ; then
	sh /tmp/preinst
	rm -f /tmp/preints
    fi
    tar xzf /tmp/data.tar.gz
    if [ -f /tmp/postinst ] ; then
	sh /tmp/postinst
	rm -f /tmp/postinst
    fi
    rm -f /tmp/data.tar.gz
    rm -f /tmp/control.tar.gz
    rm -f /tmp/control
    rm -f /tmp/${PACKAGE}
	$AUTOLOADER_LOG "[$2-installed]$PACKAGE install finished.."
}

$AUTOLOADER_LOG "ipkg-opt installing..."
# if ipkg-opt is already installed..
if [ ! -f '/opt/bin/ipkg' ]; then
	_install_package uclibc-opt_0.9.28-13_mipsel.ipk uclibc-opt &
	_install_package ipkg-opt_0.99.163-10_mipsel.ipk ipkg-opt &
	while [[ `cat $AUTOLOADER_PATH/.log | grep '\[ipkg-opt-installed\]' | wc -l` -lt 1 || `cat $AUTOLOADER_PATH/.log | grep '\[uclibc-opt-installed\]' | wc -l` -lt 1 ]]; do
	  sleep 10;
	done
fi

# little update
/opt/sbin/ldconfig
ipkg-opt update

$AUTOLOADER_LOG "[ipkg-opt-ALL-installed]ipkg-opt install finished"

sleep 5; rm -f $0 &