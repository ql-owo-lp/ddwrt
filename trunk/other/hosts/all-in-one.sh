#!/bin/sh
$AUTOLOADER_GUNZIP $AUTOLOADER_PATH/hosts/all.in.one.gz $AUTOLOADER_URL/other/hosts/hosts-all-in-one.gz
$AUTOLOADER_FILTER_HOSTS $AUTOLOADER_PATH/hosts/all.in.one
$AUTOLOADER_PATH/merge $AUTOLOADER_PATH/hosts /tmp/hosts
for file in `find $AUTOLOADER_PATH/hosts -type f | grep -v default`; do
  rm -f $file
done
$AUTOLOADER_PATH/dnsmasq.restart &