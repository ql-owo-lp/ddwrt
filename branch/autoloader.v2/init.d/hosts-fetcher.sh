#Short global var

# first command variable -> path
PAT=$1
# default value
if [ -z "$PAT" ] ; then
  PAT=/tmp/autoloader
fi
BIN=$PAT/bin
CFG=$PAT/cfg

LCK=$BIN/lock
ULCK=$BIN/unlock

#return 1-locked,0-unlocked
mkdir -p $PAT/.lock
cat > $LCK << EOF
#!/bin/sh
if [ -f "$PAT/.lock/\$1" ] ; then
  exit 1
else
  echo \> $PAT/.lock/\$1
fi
exit 0
EOF

#lock this progress first
$LCK starter
if [ $? -eq 1 ] ; then
  exit
fi

#unlock a progress
cat > $ULCK <<EOF
#!/bin/sh
  rm -f $PAT/.lock/\$1
EOF

#Default Configuration
if [ -z "$1" ] ; then
  __K_HOSTS_MODE=1
fi
if [ -z "$2" ] ; then
  __K_SERVER=http://ddwrt.googlecode.com/svn/trunk
fi
#custom optware url
if [ -z "$3" ] ; then
  __K_SERVER_OPTWARE=http://ipkg.nslu2-linux.org/feeds/optware/ddwrt/cross/stable
  __K_SERVER_OPTWARE_CUST=0
else
  __K_SERVER_OPTWARE_CUST=1
fi
#生成脚本目录
mkdir -p $PAT/script
mkdir -p $PAT/tmp
mkdir -p $PAT/dnsmasq.cfg
mkdir -p $PAT/cron.d
mkdir -p $PAT/hosts

#create a symbol link
ln -s /tmp/dnsmasq.conf $PAT/dnsmasq.cfg/default

#Configure here
mkdir -p $CFG
cat > $CFG/global << EOF
export __K_SERVER=$__K_SERVER
export __K_BASE=$PAT
export __K_BIN=$BIN
export __K_HOSTS_MODE=$__K_HOSTS_MODE
export __K_SERVER_OPTWARE=$__K_SERVER_OPTWARE
export __K_SERVER_OPTWARE_CUST=$__K_SERVER_OPTWARE_CUST
EOF
#Configuration ends

#开始生成文件(Generating sub-scripts)

#argu : $1-local target,$2-remote source
cat > $BIN/fetch-and-exec << EOF
#!/bin/sh
$BIN/fetch \$1 \$2
chmod +x \$1
echo Executing \$1..
$BIN/exec \$1
echo \$1 execution finished.
EOF
chmod +x $BIN/fetch-and-exec

#argu : $1-local target,$2-remote source
cat > $BIN/fetch << EOF
#!/bin/sh
echo Fetching \$2 -\>\> \$1..
wget \$1 \$2
echo \$1 has been fetched.
EOF
chmod +x $BIN/fetch

#NOTICE to extension!!
cat > $PAT/fetch-and-exec-gz << EOF
#!/bin/sh
$BIN/gunzip \$1.gz \$2.gz
chmod +x \$1
$BIN/exec \$1
EOF
chmod +x $PAT/fetch-and-exec-gz

#execute scripts with path environment variable
cat > $BIN/exec << EOF
#!/bin/sh
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/jffs/sbin:/jffs/bin:/jffs/usr/sbin:/jffs/usr/bin:/mmc/sbin:/mmc/bin:/mmc/usr/sbin:/mmc/usr/bin:/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin
while read cfg
do
  \$cfg
done < $CFG
if [ -x "\$1" ]; then
  /bin/sh \$1
fi
EOF
chmod +x $BIN/exec

#argu : $1-script name,$2-fetch url,$3-repeat or not, 1 stands yes
cat > $BIN/wanup << EOF
#!/bin/sh
SCRIPT=$PAT/script/\$1.wanup
if [ ! -f "\$SCRIPT" ] ; then
  $PAT/fetch-and-exec-gz \$SCRIPT \$2
  ln -s \$SCRIPT /tmp/etc/config/\$1.wanup
  #Repeat this script or not
  if [ \$3 -eq 1 ] ; then
    echo "30 */24 * * * root $BIN/exec \$SCRIPT" > $PAT/cron.d/\$1
    $BIN/cron-rebuilder
  fi
fi
EOF
chmod +x $BIN/wanup

cat > $BIN/cron-rebuilder << EOF
#!/bin/sh
stopservice cron && startservice cron && stopservice crond && startservice crond
ln -s $PAT/cron.d/* /tmp/cron.d/
cp -f /tmp/crontab.backup /tmp/crontab
for I in \`find $PAT/cron.d -type f\`; do
  cat \$I >> /tmp/crontab
done
EOF
chmod +x $BIN/cron-rebuilder

#argu : if $2 has a value..
cat > $BIN/gunzip << EOF
#!/bin/sh
if [ ! -z "\$2" ] ; then
  $BIN/fetch \$1 \$2
fi
gunzip -f \$1
echo Gunzip \$1 successfully.
EOF
chmod +x $BIN/gunzip

#argu : 
cat > $BIN/hosts/unzip << EOF
#!/bin/sh
if [ ! -f "/opt/bin/unzip" ] ; then
  echo unzip not installed!!
  exit
fi
$BIN/fetch $PAT/tmp/hosts.zip \$1
unzip -uCLo $PAT/tmp/hosts.zip hosts -d $PAT/tmp
echo Appending new hosts..
$BIN/hosts/filter /tmp/hosts $PAT/tmp/hosts
rm -f $PAT/tmp/hosts.zip
rm -f $PAT/tmp/hosts
EOF
chmod +x $BIN/hosts/unzip

#argu : filter $2 to $1
cat > $BIN/hosts/filter << EOF
#!/bin/sh
cat \$2 | egrep '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' | sed -e '2,\$s/127.0.0.1/0.0.0.0/g' -e 's/[[:space:]]*#.*\$//' -e 's/[[:space:]][[:space:]]/ /g'  >> \$1
EOF
chmod +x $BIN/hosts/filter

_install_unzip_module() {
  ##$PAT/fetch-and-exec-gz $PAT/script/ipkg.setup $__K_SERVER/auto-installer/optware/script/ipkg.sh
  $PAT/fetch-and-exec-gz $PAT/script/ipkg-opt.setup $__K_SERVER/auto-installer/optware/script/ipkg-opt.sh
  $PAT/fetch-and-exec-gz $PAT/script/unzip.setup $__K_SERVER/auto-installer/optware/script/unzip.sh
}

_installhosts() {
case $__K_HOSTS_MODE in
0);;
1) #gzipped all-in-one package
  $BIN/wanup hosts $__K_SERVER/other/hosts/autoloader-gzip-all-in-one.sh 1
  ;;
2) #zipped all-in-one(NOT developped)
  _install_unzip_module
  $BIN/wanup hosts $__K_SERVER/other/hosts/autoloader-zip-mixed.sh 1
  ;;
3) #gzipped mixed(NOT developped)
  $BIN/wanup hosts $__K_SERVER/other/hosts/autoloader-gzip-all-in-one.sh 1
  ;;
4) #zipped mixed
  _install_unzip_module
  $BIN/wanup hosts $__K_SERVER/other/hosts/autoloader-zip-mixed.sh 1
  ;;
*) #plain-text
  $BIN/wanup hosts $__K_SERVER/other/hosts/autoloader-plain.sh 1
  ;;
esac
}
#Function ends

#Prepare for installing Opt-Ware
mkdir /tmp/opt
mount -o bind /tmp/opt /opt
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

if [ $__K_HOSTS_MODE -ne 0 ] ; then
  rm -f /tmp/hosts
  _installhosts
  rm -f $PAT/tmp/hosts
  ln -s /tmp/hosts /etc/hosts
  killall dnsmasq
  dnsmasq --conf-dir=$PAT/dnsmasq.cfg
fi

echo Auto-loader progress completed, wait 10 secs to suicide..
sleep 10
#delete the initial scripts
rm -f /tmp/etc/config/autoloader-starter.wanup
rm -f /tmp/autoloader.start.sh
#unlock
$ULCK starter
