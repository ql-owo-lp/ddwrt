#!/bin/sh

# Hosts Fetcher

TMP_BASE=/tmp/autoloader/hosts-fetcher
#target hosts
TARGET_DIRECTORY=/root/hosts

mkdir -p $TMP_BASE/tmp
mkdir -p $TMP_BASE/hosts

rm -rf $TARGET_DIRECTORY
mkdir -p $TARGET_DIRECTORY


# filter comments
_filter_hosts() {
  cat $1 | sed -e 's/#.*$//g' -e 's/127.0.0.1/0.0.0.0/g' | egrep '^.+$' | grep -v localhost > $2
}

# log
_log() {
  echo $1
  date "+%Y-%m-%d %H:%M:%S $1" >> $TMP_BASE/runtime.log
} 

# from zip / $1=url, $2=alias
_get_hosts_zip() {
  mkdir -p $TMP_BASE/tmp/$2
  _log "Fetching hosts from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2/hosts.zip
  _log "Hosts from [$2] fetched!  Now uncompressing"
  unzip -uCLo $TMP_BASE/tmp/$2/hosts.zip hosts -d $TMP_BASE/tmp/$2
  _log "Uncompressing [$2] finished.. Now filtering"
  _filter_hosts $TMP_BASE/tmp/$2/hosts $TARGET_DIRECTORY/$2
  _log "Hosts from [$2] filtered!"
  rm -rf $TMP_BASE/tmp/$2
}

_get_hosts_plain() {
  _log "Fetching hosts from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2
  _log "Now filtering [$1]"
  _filter_hosts $TMP_BASE/tmp/$2 $TARGET_DIRECTORY/$2
  _log "Hosts from [$2] filtered!"
  rm -f $TMP_BASE/tmp/$2
}

_get_hosts_gzip() {
  _log "Fetching hosts from [$1].."
  wget -O - $1 > $TMP_BASE/tmp/$2.gz
  _log "Hosts from [$2] fetched!  Now uncompressing"
  gunzip -f  $TMP_BASE/tmp/$2.gz
  _log "Uncompressing [$2] finished.. Now filtering"
  _filter_hosts $TMP_BASE/tmp/$2 $TARGET_DIRECTORY/$2
  _log "Hosts from [$2] filtered!"
  rm -f $TMP_BASE/tmp/$2
}

_get_hosts_zip http://www.mvps.org/winhelp2002/hosts.zip mpvs.org &
_get_hosts_gzip http://ddwrt.googlecode.com/svn/trunk/other/hosts/adblock/hosts.gz autoloader-adblock &
_get_hosts_gzip http://ddwrt.googlecode.com/svn/trunk/other/hosts/activation-block/hosts.gz autoloader-activation &
_get_hosts_plain http://ddwrt.googlecode.com/svn/trunk/other/hosts/gfw/hosts autoloader-gfw &
_get_hosts_plain https://raw.github.com/davidsun/HostsFile/master/hosts pooled-hosts &
# Google IPv6
#_get_hosts_plain https://docs.google.com/View?docid=dfkdmxnt_61d9ck9ffq &

#rm -rf $TMP_BASE
