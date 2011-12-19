#!/bin/sh
$AUTOLOADER_LOG 'Squid gfwlist update progess processing...'

_install_gfwlist() {
  $AUTOLOADER_FETCH $AUTOLOADER_TMP/squid.gfw.list.tmp $1
  echo -e '\n====' >> $AUTOLOADER_TMP/squid.gfw.list.tmp
  echo 'begin-base64 644 -' | cat - $AUTOLOADER_TMP/squid.gfw.list.tmp > $AUTOLOADER_TMP/squid.gfw.list
  uudecode $AUTOLOADER_TMP/squid.gfw.list | tail +2 | egrep -e '^[^!]+$' >> $AUTOLOADER_TMP/squid.gfw.rules
  rm -f $AUTOLOADER_TMP/squid.gfw.list &
  rm -f $AUTOLOADER_TMP/squid.gfw.list.tmp &
}

_install_gfw_custom() {
  # create route records into gfw.custom
  $AUTOLOADER_FETCH $AUTOLOADER_TMP/squid.gfw.custom $AUTOLOADER_URL/other/g-list/list.txt
  cat $AUTOLOADER_TMP/squid.gfw.custom | egrep -e '^[0-9a-zA-Z\.\/]+$' > $AUTOLOADER_TMP/squid.gfw.custom
  cat $AUTOLOADER_TMP/squid.gfw.custom | sed -e 's/^[0-9\.\/]+$//g' >> $AUTOLOADER_TMP/squid.gfw.rules
  rm -f $AUTOLOADER_TMP/squid.gfw.custom
}


# filter string before the progress
# $1 orgin file, $2 rules, $3 exception rules
before_filter() {
  cat $1 | tail +2 | egrep '^[^/].+[^/]$' | egrep '^[^!#]+$' | sed -e 's/\./\\./g'  -e 's/\*/.*/g' -e 's/\?/\\?/g' -e 's/\^/[^a-zA-Z0-9_\\-\\.%]+/g' > $1.rules.tmp 
  # rules
  cat $1.rules.tmp  | egrep '^[^@]' > $2
  # exception rules
  cat $1.rules.tmp  | egrep '^@' | sed -e 's/^@@//g' > $3
  rm -f $1.rules.tmp 
}

# filter string at the end
after_filter() {
  cat $1 | sed -e 's/|$/$/g' -e 's/^||/^https?:\/\//g' -e 's/^|/^/g' > $1.rules
  mv -f $1.rules $1
}

# append regxp rules 
append_regxp() {
  cat $1 | tail +2 | egrep '^/.+/$' >> $2
  cat $1 | tail +2 | egrep '^@@/.+/$' | sed -e 's/^@@//g' >> $3
}

advanced_filter() {
  # filter options start --> includine situation of xxx.js?${random number}
  # convert \$ to (\$ then , to \$, then \$ to (..)|, then )|$ to ))
  cat $1 | sed -e 's/\$/(\$/g' -e 's/,/\$/g'> $1.rules
  mv -f $1.rules $1
  # filter image
  cat $1 | sed -e 's/\$image/(.+\\.(jpg|jpeg|svg|png|bmp|gif)(\\?.+)?)|/g' > $1.rules
  mv -f $1.rules $1
  # filter object
  cat $1 | sed -e 's/\$object_subrequest/\$what_the_fuck/g' -e 's/\$object-subrequest/\$what_the_fuck/g' -e 's/\$object/(.+\\.(swf|jar)(\\?.+)?)|/g' > $1.rules
  mv -f $1.rules $1
  # filter script
  cat $1 | sed -e 's/\$script/(.+\\.(js|vbs)(\\?.+)?)|/g' > $1.rules
  mv -f $1.rules $1
  # filter stylesheet
  cat $1 | sed -e 's/\$stylesheet/(.+\\.css(\\?.+)?)|/g'  > $1.rules
  mv -f $1.rules $1
  # filter dtd
  cat $1 | sed -e 's/\$dtd/(.+\\.dtd(\\?.+)?)|/g' > $1.rules
  mv -f $1.rules $1
  # filter options unknown or unable to process
  cat $1 | sed -e 's/)|$/))/g' | egrep '^[^$,]+\$?$' > $1.rules
  mv -f $1.rules $1
}

rm -f  $AUTOLOADER_TMP/squid.gfw.rules

#_install_gfwlist http://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt
_install_gfwlist /tmp/gfwlist.txt
_install_gfw_custom

TMP_RULE="/opt/etc/squid/gfw.rules"
TMP_EXCEPT_RULE="/opt/etc/squid/gfw.exception.rules"

before_filter $AUTOLOADER_TMP/squid.gfw.rules $TMP_RULE $TMP_EXCEPT_RULE

advanced_filter $TMP_RULE
advanced_filter $TMP_EXCEPT_RULE

# following filter must be place after advanced filter
after_filter $TMP_RULE
after_filter $TMP_EXCEPT_RULE

# append regexp
append_regxp $AUTOLOADER_TMP/squid.gfw.rules $TMP_RULE $TMP_EXCEPT_RULE
