#自定义服务器地址(此行在粘贴时可被删除/Annotation can be deleted when pasting)
AUTOLOADER_SERV=ddwrt.googlecode.com
AUTOLOADER_URL=http://$AUTOLOADER_SERV/svn/trunk
AUTOLOADER_URL_OPTWARE=$AUTOLOADER_URL/auto-installer/optware/package
#参数含义(此行在粘贴时可被删除):0-Off,1-Gzip,2-Zip-Mixed,3-PlainText
AUTOLOADER_HOSTS_MODE=4
#此变量请不要修改(Please DO NOT change this value)!
SC=/tmp/etc/config/autoloader-starter.wanup; LOAD=/tmp/autoloader.start.sh
mkdir -p /tmp/etc/config
cat > $SC << EOF
#!/bin/sh
_COUNT=0
while true ; do
_SIZE=0
if [ -f "$LOAD.gz" ] ; then _SIZE=\`ls -l $LOAD.gz | awk '{print \$5}'\` ; fi
while true ; do
  ping -c 3 $AUTOLOADER_SERV
  if [[ \$? != 0 ]]; then sleep 180 ; else break ; fi
done
if [ \$_SIZE -lt 5 ] ; then
  if [ \$_COUNT -gt 0 ] ; then sleep 90; fi
  wget -O - $AUTOLOADER_URL/autoloader.start.sh.gz > $LOAD.gz
  let _COUNT++
else
  gunzip -f $LOAD.gz ; cp /tmp/crontab /tmp/crontab.backup ; chmod +x $LOAD
  $LOAD $AUTOLOADER_HOSTS_MODE $AUTOLOADER_URL $AUTOLOADER_URL_OPTWARE
  break
fi
done
EOF
sleep 20 ; sh $SC &