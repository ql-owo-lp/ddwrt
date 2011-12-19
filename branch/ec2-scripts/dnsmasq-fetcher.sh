#!/bin/sh

# DNSMasq Fetcher

TMP_BASE=/tmp/autoloader/dnsmasq-fetcher
#target dnsmasq
TARGET_DIRECTORY=/root/dnsmasq.d

mkdir -p $TMP_BASE/tmp
mkdir -p $TMP_BASE/dnsmasq.d

rm -rf $TARGET_DIRECTORY
mkdir -p $TARGET_DIRECTORY


# filter comments
_filter_file() {
  cat $1 | sed -e 's/#.*$//g' | egrep '^.+$' > $2
}

# log
_log() {
  echo $1
  date "+%Y-%m-%d %H:%M:%S $1" >> $TMP_BASE/runtime.log
} 

_get_file_plain() {
  _log "Fetching file from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2
  _log "Now filtering [$1]"
  _filter_file $TMP_BASE/tmp/$2 $TARGET_DIRECTORY/$2
  _log "File from [$2] filtered!"
  rm -f $TMP_BASE/tmp/$2
}

_get_file_gzip() {
  _log "Fetching file from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2.gz
  _log "File from [$2] fetched!  Now uncompressing"
  gunzip -f  $TMP_BASE/tmp/$2.gz
  _log "Uncompressing [$2] finished.. Now filtering"
  _filter_file $TMP_BASE/tmp/$2 $TARGET_DIRECTORY/$2
  _log "file from [$2] filtered!"
  rm -f $TMP_BASE/tmp/$2
}

_get_file_plain http://ddwrt.googlecode.com/svn/trunk/other/dnsmasq/gfw.conf autoloader-gfw.conf &
_get_file_plain http://ddwrt.googlecode.com/svn/trunk/other/dnsmasq/adblock.conf autoloader-adblock.conf &

# rm -rf $TMP_BASE
