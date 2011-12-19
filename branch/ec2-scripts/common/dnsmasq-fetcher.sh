#!/bin/sh

# Common Fetcher

TMP_BASE=/tmp/autoloader/dnsmasq-fetcher
#target dnsmasq
TARGET_DIRECTORY=/root/dnsmasq.d

mkdir -p $TMP_BASE/tmp
mkdir -p $TMP_BASE/dnsmasq.d

rm -rf $TARGET_DIRECTORY
mkdir -p $TARGET_DIRECTORY


# filter comments
_filter_file() {
  cat $1 | sed -e 's/#.*$//g' -e 's/127.0.0.1/0.0.0.0/g' | egrep '^.+$' > $2
}

# log
_log() {
  echo $1
  date "+%Y-%m-%d %H:%M:%S $1" >> $TMP_BASE/runtime.log
} 

# from zip / $1=url, $2=alias
_get_file_zip() {
  mkdir -p $TMP_BASE/tmp/$2
  _log "Fetching file from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2/file.zip
  _log "file from [$2] fetched!  Now uncompressing"
  unzip -uCLo $TMP_BASE/tmp/$2/file.zip hosts -d $TMP_BASE/tmp/$2
  _log "Uncompressing [$2] finished.. Now filtering"
  _filter_file $TMP_BASE/tmp/$2/file $TARGET_DIRECTORY/$2
  _log "file from [$2] filtered!"
  rm -rf $TMP_BASE/tmp/$2
}

_get_file_plain() {
  _log "Fetching file from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2
  _log "Now filtering [$1]"
  _filter_file $TMP_BASE/tmp/$2 $TARGET_DIRECTORY/$2
  _log "file from [$2] filtered!"
  rm -f $TMP_BASE/tmp/$2
}

_get_file_gzip() {
  _log "Fetching file from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2.gz
  _log "file from [$2] fetched!  Now uncompressing"
  gunzip -f  $TMP_BASE/tmp/$2.gz
  _log "Uncompressing [$2] finished.. Now filtering"
  _filter_file $TMP_BASE/tmp/$2 $TARGET_DIRECTORY/$2
  _log "file from [$2] filtered!"
  rm -f $TMP_BASE/tmp/$2
}

_get_file_zip http://www.mvps.org/winhelp2002/hosts.zip mpvs.org &
_get_file_gzip http://ddwrt.googlecode.com/svn/trunk/other/hosts/adblock/hosts.gz ddwrt-adblock &
_get_file_gzip http://ddwrt.googlecode.com/svn/trunk/other/hosts/activation-block/hosts.gz ddwrt-activation &
_get_file_plain http://ddwrt.googlecode.com/svn/trunk/other/hosts/gfw/hosts ddwrt-gfw &
_get_file_plain https://raw.github.com/davidsun/HostsFile/master/hosts pooled-hosts &

# rm -rf $TMP_BASE
