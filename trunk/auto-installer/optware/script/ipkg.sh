#!/bin/sh
mkdir -p /jffs/test
if [ ! -d "/jffs/test" ] ; then
  mkdir /tmp/jffs
  mount -o bind /tmp/jffs /jffs
else
  rm -f /jffs/test
fi

#Fix necessary folders here
mkdir -p /tmp/smb/share/tmp/ipkg
mkdir -p /jffs/tmp/ipkg

if [ ! -d "/jffs/usr/lib/ipkg/lists" ] ; then
  mkdir -p /jffs/usr/lib/ipkg/lists
  $AUTOLOADER_LOG "ipkg fixed. Now update lists.."
  /bin/ipkg update
  $AUTOLOADER_LOG "ipkg list update sucessfully."
fi &

sleep 5 ; rm -f $0 &