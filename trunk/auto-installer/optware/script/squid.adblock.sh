#!/bin/sh
# NOTICE : the URL within symbol '$', '^' and '#' is dumped anyway
$AUTOLOADER_LOG 'Squid adblock update progess processing...'

_adblock_fetch() {
$AUTOLOADER_FETCH $AUTOLOADER_TMP/$1.adblock.origin.tmp $2

TMP_RULE="$AUTOLOADER_TMP/$1.adblock.rules"
TMP_EXCEPT_RULE="$AUTOLOADER_TMP/$1.adblock.exception.rules"

before_filter $AUTOLOADER_TMP/$1.adblock.origin.tmp $TMP_RULE $TMP_EXCEPT_RULE

advanced_filter $TMP_RULE
advanced_filter $TMP_EXCEPT_RULE

# following filter must be place after advanced filter
after_filter $TMP_RULE
after_filter $TMP_EXCEPT_RULE

# append regexp
append_regxp $AUTOLOADER_TMP/$1.adblock.origin.tmp $TMP_RULE $TMP_EXCEPT_RULE

cat $TMP_RULE >> /opt/etc/squid/adblock.rules
cat $TMP_EXCEPT_RULE >> /opt/etc/squid/adblock.exception.rules

LINECOUNT=`cat $TMP_RULE | wc -l`
LINECOUNT_T=`cat /opt/etc/squid/adblock.rules | wc -l`
LINECOUNT_E=`cat $TMP_EXCEPT_RULE | wc -l`
LINECOUNT_E_T=`cat /opt/etc/squid/adblock.exception.rules | wc -l`
$AUTOLOADER_LOG "$1 has been converted.  $LINECOUNT/$LINECOUNT_E records are added.  Now total $LINECOUNT_T/$LINECOUNT_E_T. (BLOCK/EXCEPTION)"

rm -f $AUTOLOADER_TMP/$1.adblock.origin.tmp
rm -f $TMP_RULE
rm -f $TMP_EXCEPT_RULE
}

# filter string before the progress
# $1 orgin file, $2 rules, $3 exception rules
before_filter() {
  cat $1 | tail +2 | egrep '^[^/].+[^/]$' | egrep '^[^!#]+$' | sed -e 's/\./\\./g'  -e 's/\*/.*/g' -e 's/\?/\\?/g' -e 's/\^/[^a-zA-Z0-9_\\-\\.%]+/g' > $1.adblock.tmp 
  # rules
  cat $1.adblock.tmp  | egrep '^[^@]' > $2
  # exception rules
  cat $1.adblock.tmp  | egrep '^@' | sed -e 's/^@@//g' > $3
  rm -f $1.adblock.tmp 
}

# filter string at the end
after_filter() {
  cat $1 | sed -e 's/|$/$/g' -e 's/^||/^https?:\/\//g' -e 's/^|/^/g' > $1.adblock
  mv -f $1.adblock $1
}

# append regxp rules 
append_regxp() {
  cat $1 | tail +2 | egrep '^/.+/$' >> $2
  cat $1 | tail +2 | egrep '^@@/.+/$' | sed -e 's/^@@//g' >> $3
}

advanced_filter() {
  # filter options start --> includine situation of xxx.js?${random number}
  # convert \$ to (\$ then , to \$, then \$ to (..)|, then )|$ to ))
  cat $1 | sed -e 's/\$/(\$/g' -e 's/,/\$/g'> $1.adblock
  mv -f $1.adblock $1
  # filter image
  cat $1 | sed -e 's/\$image/(.+\\.(jpg|jpeg|svg|png|bmp|gif)(\\?.+)?)|/g' > $1.adblock
  mv -f $1.adblock $1
  # filter object
  cat $1 | sed -e 's/\$object_subrequest/\$what_the_fuck/g' -e 's/\$object-subrequest/\$what_the_fuck/g' -e 's/\$object/(.+\\.(swf|jar)(\\?.+)?)|/g' > $1.adblock
  mv -f $1.adblock $1
  # filter script
  cat $1 | sed -e 's/\$script/(.+\\.(js|vbs)(\\?.+)?)|/g' > $1.adblock
  mv -f $1.adblock $1
  # filter stylesheet
  cat $1 | sed -e 's/\$stylesheet/(.+\\.css(\\?.+)?)|/g'  > $1.adblock
  mv -f $1.adblock $1
  # filter dtd
  cat $1 | sed -e 's/\$dtd/(.+\\.dtd(\\?.+)?)|/g' > $1.adblock
  mv -f $1.adblock $1
  # filter options unknown or unable to process
  cat $1 | sed -e 's/)|$/))/g' | egrep '^[^$,]+\$?$' > $1.adblock
  mv -f $1.adblock $1
}

rm -f /opt/etc/squid/adblock.rules
rm -f /opt/etc/squid/adblock.exception.rules

_adblock_fetch adblock-lazy http://adblock-chinalist.googlecode.com/svn/trunk/adblock-lazy.txt
_adblock_fetch adblock-costom $AUTOLOADER_URL/other/squid-rules/adblock.txt

# restart squid, command 'restart' works not well
while [ `ps | awk '{print $5}' | grep '(squid)' | wc -l` -gt 0 ] ; do
  $AUTOLOADER_LOG 'Squid process running. Kill'
  /opt/etc/init.d/S80squid stop
  sleep 1
done

/opt/etc/init.d/S80squid start &
#$AUTOLOADER_PATH/monitor 10 "(squid)" "/opt/etc/init.d/S80squid start"

sleep 5; rm -f $0 &
