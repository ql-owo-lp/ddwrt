#!/bin/sh
#在这里定义一些脚本全局变量
#Auto-loader主目录 (Main floder)
export AUTOLOADER_PATH=/tmp/autoloader
#获取远程脚本并执行(fetch a remote script and execute it immediately)
export AUTOLOADER_FETCH_EXEC=$AUTOLOADER_PATH/fetch-and-exec
#Fetch only
export AUTOLOADER_FETCH=$AUTOLOADER_PATH/fetch
#执行脚本(execute a script, before which environment variables are imported) 
export AUTOLOADER_EXEC=$AUTOLOADER_PATH/exec
#WAN UP脚本(execute when wan's up)
export AUTOLOADER_WANUP=$AUTOLOADER_PATH/wanup
#临时目录(directory to store temporary files, use to extract zip/gzip file)
export AUTOLOADER_TMP=$AUTOLOADER_PATH/tmp
#脚本目录(AUTOLOADERs are stored here)
export AUTOLOADER_DIR=$AUTOLOADER_PATH/script
#CROND
export AUTOLOADER_CRON=$AUTOLOADER_PATH/cron.d
export AUTOLOADER_FETCH_EXEC_GZ=$AUTOLOADER_PATH/fetch-and-exec-gz
export AUTOLOADER_CRON_BUILDER=$AUTOLOADER_PATH/cron-builder
export AUTOLOADER_GUNZIP=$AUTOLOADER_PATH/gunzip
export AUTOLOADER_UNZIP_HOSTS=$AUTOLOADER_PATH/unzip-hosts
export AUTOLOADER_FILTER_HOSTS=$AUTOLOADER_PATH/filter-hosts
export AUTOLOADER_LOG=$AUTOLOADER_PATH/log
#Configuration ends

#Default Configuration
AUTOLOADER_HOSTS_MODE=$1
AUTOLOADER_URL=$2
AUTOLOADER_URL_OPTWARE=$3
if [ -z "$AUTOLOADER_HOSTS_MODE" ] ; then
  # Never fetch a host by default. as modules like squid is installed, hosts is no longer needed for its less efficiency
  AUTOLOADER_HOSTS_MODE=0
fi
if [ -z "$AUTOLOADER_URL" ] ; then
  AUTOLOADER_URL=http://ddwrt.googlecode.com/svn/trunk
fi
#custom optware url
AUTOLOADER_URL_OPTWARE_CUST=1
if [ -z "$AUTOLOADER_URL_OPTWARE" ] ; then
  AUTOLOADER_URL_OPTWARE=http://ipkg.nslu2-linux.org/feeds/optware/ddwrt/cross/stable
  AUTOLOADER_URL_OPTWARE_CUST=0
fi
#生成脚本目录
mkdir -p $AUTOLOADER_DIR
mkdir -p $AUTOLOADER_TMP
mkdir -p $AUTOLOADER_CRON
mkdir -p $AUTOLOADER_PATH/.backup
mkdir -p $AUTOLOADER_PATH/dnsmasq
mkdir -p $AUTOLOADER_PATH/hosts
mkdir -p $AUTOLOADER_PATH/script/firewall

# dnsmasq
cp -f /tmp/dnsmasq.conf $AUTOLOADER_PATH/dnsmasq/default
#$AUTOLOADER_PATH/backup /tmp/dnsmasq.conf &
cp -f /tmp/hosts $AUTOLOADER_PATH/hosts/default
#$AUTOLOADER_PATH/backup /tmp/crontab &
cp -f /tmp/crontab $AUTOLOADER_CRON/default
#$AUTOLOADER_PATH/backup /tmp/hosts &
ln -s /tmp/hosts /etc/hosts

# lock file
BOOTLOCK=$AUTOLOADER_PATH/.boot.lock
#Lock
if [ -f "$BOOTLOCK" ] ; then
  echo 'AUTOLOADER LOCKED!' ; exit 0
else
  echo > $BOOTLOCK
fi

cat > $AUTOLOADER_PATH/backup << EOF
#!/bin/sh
cp -f \$1 $AUTOLOADER_PATH/.backup/\`echo \$1 | sed 's/\//#/g'\`
EOF
chmod +x $AUTOLOADER_PATH/backup

cat > $AUTOLOADER_PATH/recover << EOF
#!/bin/sh
cp -f $AUTOLOADER_PATH/.backup/\`echo \$1 | sed 's/\//#/g'\` \$1
EOF
chmod +x $AUTOLOADER_PATH/recover

cat > $AUTOLOADER_PATH/firewall.script << EOF
#!/bin/sh
for SCRIPT in  \`find $AUTOLOADER_PATH/script/firewall -type f\`; do
  $AUTOLOADER_EXEC \$SCRIPT &
done
EOF
chmod +x $AUTOLOADER_PATH/firewall.script

#开始生成文件(Generating sub-scripts)
cat > $AUTOLOADER_FETCH_EXEC << EOF
#!/bin/sh
$AUTOLOADER_FETCH \$1 \$2 \$3
chmod +x \$1
$AUTOLOADER_LOG "Executing \$1.."
$AUTOLOADER_EXEC \$1
$AUTOLOADER_LOG "\$1 execution finished."
EOF
chmod +x $AUTOLOADER_FETCH_EXEC

# restart dnsmasq
# WTF: the --conf-dir & --addn-hosts never work!!
cat > $AUTOLOADER_PATH/dnsmasq.restart << EOF
#!/bin/sh
$AUTOLOADER_LOG "Restarting DNSMasq..."
killall dnsmasq
dnsmasq --conf-file=/tmp/dnsmasq.conf --clear-on-reload
EOF
chmod +x $AUTOLOADER_PATH/dnsmasq.restart

# monitor a progress($2) every $1 sec, and try to recover it with command($3)
cat > $AUTOLOADER_PATH/monitor << EOF
#!/bin/sh
$AUTOLOADER_LOG "Start monitoring \$2..."
while true ; do
  sleep \$1
  if [ \`ps | awk '{print \$5}' | grep '\$2' | wc -l\` -lt 1 ] ; then
    $AUTOLOADER_LOG "\$2 crashed.  Recovering..."
    \$3 &
  fi
done &
EOF
chmod +x $AUTOLOADER_PATH/monitor

# merge files in a folder into a file, NOTICE it will clean the target first
cat > $AUTOLOADER_PATH/merge << EOF
#!/bin/sh
if [ ! -d "\$1" ] ; then exit; fi
echo>\$2
$AUTOLOADER_LOG "Merge folder \$1 into \$2..."
for file in \`find \$1 -type f\`; do
  $AUTOLOADER_LOG "Merge file \$file into \$2..."
  echo -e '\n' | cat - \$file >> \$2
done
$AUTOLOADER_LOG "Merge folder \$1 into \$2...FINISHED!!"
EOF
chmod +x $AUTOLOADER_PATH/merge

cat > $AUTOLOADER_LOG << EOF
#!/bin/sh
echo \$1
date "+%Y-%m-%d %H:%M:%S \$1" >> $AUTOLOADER_PATH/.log
EOF
chmod +x $AUTOLOADER_LOG

# file size should be no less than 5, or it will be considered incorrect
cat > $AUTOLOADER_FETCH << EOF
#!/bin/sh
# see if it is a local file
if [ -z \`echo \$2 | egrep -Eo '^https?:\/\/.+'\` ] ; then
  cp \$2 \$1
  exit 0
fi
SITE=`echo $AUTOLOADER_URL | awk -F / '{print $3}'`
COUNT=0
while true ; do
  ping -c 3 \$SITE > /dev/null
  if [[ \$? != 0 ]]; then
    $AUTOLOADER_LOG "Ping gateway failed, wait for 120 sec"
	# sometimes VPN may block the route, just guess, the gateway may be wrong
	if [ \$COUNT -gt 3 ] ; then
	  route del -host \$SITE
	  route add -host \$SITE gw \`nvram get wan_gateway\`
	fi
    sleep 120
  else
    break
  fi
done
$AUTOLOADER_LOG "Fetching \$2 ->> \$1.."
COUNT=0 ; rm -f \$1
# to ensure the file always be fetched correctly, use 'while true loop';
# the for loop will die after trying certain times, then causes program fault
# yet the while loop will stuck progress when the internet connection is down
#for i in 1 2 3 4 6 9 14 17 25 30 ; do
# set i=1, thus sleep 5 sec after wget attempt fails
i=1
while true ; do
    _SIZE=0
    if [ -f "\$1" ] ; then
        _SIZE=\`ls -l \$1 | awk '{print \$5}'\`
    fi
    if [ \$_SIZE -lt 5 ] ; then
        wget -O - \$2 > \$1
        if [ \$COUNT -gt 0 ] ; then
            let WAIT=\$i*5
            $AUTOLOADER_LOG "\$1 fetching retry(\$COUNT), wait (\$WAIT) seconds"
            sleep \$WAIT
        fi
        let COUNT++
    else
	    ID=''
	    if [ ! -z "\$3" ] ; then ID="fetched[\$3]"; fi
        $AUTOLOADER_LOG "\$ID\$2 has been fetched. size(\$_SIZE)"
        break
    fi
done
EOF
chmod +x $AUTOLOADER_FETCH

cat > $AUTOLOADER_FETCH_EXEC_GZ << EOF
#!/bin/sh
$AUTOLOADER_GUNZIP \$1.gz \$2.gz \$3
chmod +x \$1
$AUTOLOADER_EXEC \$1
EOF
chmod +x $AUTOLOADER_FETCH_EXEC_GZ

cat > $AUTOLOADER_EXEC << EOF
#!/bin/sh
export AUTOLOADER_PATH=$AUTOLOADER_PATH
export AUTOLOADER_FETCH=$AUTOLOADER_FETCH
export AUTOLOADER_FETCH_EXEC=$AUTOLOADER_FETCH_EXEC
export AUTOLOADER_EXEC=$AUTOLOADER_EXEC
export AUTOLOADER_WANUP=$AUTOLOADER_WANUP
export AUTOLOADER_TMP=$AUTOLOADER_TMP
export AUTOLOADER_CRON=$AUTOLOADER_CRON
export AUTOLOADER_DIR=$AUTOLOADER_DIR
export AUTOLOADER_CRON_BUILDER=$AUTOLOADER_CRON_BUILDER
export AUTOLOADER_FETCH_EXEC_GZ=$AUTOLOADER_FETCH_EXEC_GZ
export AUTOLOADER_GUNZIP=$AUTOLOADER_GUNZIP
export AUTOLOADER_UNZIP_HOSTS=$AUTOLOADER_UNZIP_HOSTS
export AUTOLOADER_FILTER_HOSTS=$AUTOLOADER_FILTER_HOSTS
export AUTOLOADER_URL=$AUTOLOADER_URL
export AUTOLOADER_HOSTS_MODE=$AUTOLOADER_HOSTS_MODE
export AUTOLOADER_URL_OPTWARE=$AUTOLOADER_URL_OPTWARE
export AUTOLOADER_URL_OPTWARE_CUST=$AUTOLOADER_URL_OPTWARE_CUST
export AUTOLOADER_LOG=$AUTOLOADER_LOG
#Fix PATH for crontab
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/jffs/sbin:/jffs/bin:/jffs/usr/sbin:/jffs/usr/bin:/mmc/sbin:/mmc/bin:/mmc/usr/sbin:/mmc/usr/bin:/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin
/bin/sh \$1
EOF
chmod +x $AUTOLOADER_EXEC

cat > $AUTOLOADER_WANUP << EOF
#!/bin/sh
SCRIPT_NAME=\$1.wanup
SCRIPT=$AUTOLOADER_DIR/\$SCRIPT_NAME
if [ ! -f "\$SCRIPT" ] ; then
  $AUTOLOADER_FETCH_EXEC_GZ \$SCRIPT \$2
  # use EXEC command
  echo "$AUTOLOADER_EXEC \$SCRIPT &" > /tmp/etc/config/\$SCRIPT_NAME
  #Repeat this script or not
  echo "30 */24 * * * root /tmp/etc/config/\$SCRIPT_NAME" > $AUTOLOADER_CRON/\$SCRIPT_NAME
  $AUTOLOADER_CRON_BUILDER &
fi
EOF
chmod +x $AUTOLOADER_WANUP

cat > $AUTOLOADER_CRON_BUILDER << EOF
#!/bin/sh
stopservice cron && startservice cron && stopservice crond && startservice crond
#cp -a $AUTOLOADER_CRON/* /tmp/cron.d
#$AUTOLOADER_PATH/recover /tmp/crontab
$AUTOLOADER_PATH/merge $AUTOLOADER_CRON /tmp/crontab
EOF
chmod +x $AUTOLOADER_CRON_BUILDER

cat > $AUTOLOADER_GUNZIP << EOF
#!/bin/sh
GZ=\$1
if [ -z \`echo \$GZ | egrep -Eo '\.gz\$'\` ] ; then GZ="\$GZ".gz; fi
$AUTOLOADER_FETCH \$GZ \$2 \$3
gunzip -f \$GZ
if [ -f \$GZ ] ; then
  $AUTOLOADER_LOG "Gunzip \$GZ successfully."
else
  $AUTOLOADER_LOG "Gunzip \$GZ failed.  File does not exist?"
fi
EOF
chmod +x $AUTOLOADER_GUNZIP

cat > $AUTOLOADER_FILTER_HOSTS << EOF
#!/bin/sh
$AUTOLOADER_LOG "filtering hosts(\$1).."
TMP=$AUTOLOADER_TMP/`echo \$1 | sed 's/\//#/g'`
cat \$1 | egrep -e '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' | grep -v localhost | sed -e 's/127.0.0.1/0.0.0.0/g' -e 's/[[:space:]]*#.*\$//' -e 's/[[:space:]][[:space:]]/ /g'  > \$TMP
cp -f \$TMP \$1
rm -f \$TMP
EOF
chmod +x $AUTOLOADER_FILTER_HOSTS

_install_hosts() {
case $AUTOLOADER_HOSTS_MODE in
0);;
1) #gzipped all-in-one package
  $AUTOLOADER_WANUP hosts $AUTOLOADER_URL/other/hosts/all-in-one.sh
  ;;
2) #zipped mixed
  $AUTOLOADER_WANUP hosts $AUTOLOADER_URL/other/hosts/zip.sh
  ;;
*) #plain-text
  $AUTOLOADER_WANUP hosts $AUTOLOADER_URL/other/hosts/plain.sh
  ;;
esac
}
#Function ends

#Prepare for installing Opt-Ware
mkdir /tmp/opt
mount -o bind /tmp/opt /opt
# these two value must be 1, even the router doesn't support jffs at all
nvram set enable_jffs2=1
nvram set sys_enable_jffs2=1

#CRON fix
CRON_ENABLE=`nvram get cron_enable`
if [ $CRON_ENABLE -ne 1 ] ; then
  nvram set cron_enable=1
  nvram set cron_jobs=
fi

#NTP fix for CRON
NTP_ENABLE=`nvram get ntp_enable`
if [ $NTP_ENABLE -ne 1 ] ; then
  nvram set ntp_enable=1
  nvram set ntp_server=0.asia.pool.ntp.org
  nvram set ntp_mode=auto
fi 

# install optware
_install_ipkg_opt() {
  $AUTOLOADER_FETCH_EXEC_GZ $AUTOLOADER_DIR/ipkg-opt.setup $AUTOLOADER_URL/auto-installer/optware/script/ipkg-opt.sh &
  ##$AUTOLOADER_FETCH_EXEC $AUTOLOADER_DIR/ipkg.setup $AUTOLOADER_URL/auto-installer/optware/script/ipkg.sh &
}

if [ $AUTOLOADER_HOSTS_MODE -ne 0 ] ; then
  _install_hosts &
  if [ $AUTOLOADER_HOSTS_MODE -ne 10 ] ; then
    _install_ipkg_opt &
  fi
fi

$AUTOLOADER_LOG "Auto-loader progress completed, wait 5sec then suicide.."
sleep 5
#delete the initial scripts
rm -f /tmp/etc/config/autoloader-starter.wanup &
#unlock
rm -f $BOOTLOCK ; rm -f $0 &
