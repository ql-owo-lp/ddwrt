#!/bin/sh

apt-get update
apt-get upgrade

install_yuch() {
apt-get -y install unzip
wget -O - https://yuchberry.googlecode.com/files/latest_version > /tmp/yuch.latestversion
VERSION=`cat /tmp/yuch.latestversion`
wget -O - http://yuchberry.googlecode.com/files/yuchsbox_server_$VERSION.zip > /tmp/yuch.zip
unzip -uoC /tmp/yuch.zip -d /tmp
mv /tmp/yuchberry_server_$VERSION /usr/yuch
rm -f /usr/yuch.zip /usr/yuch/commonMailSvr.ini frame.jar /usr/yuch/*.bat /usr/yuch/*.html /usr/yuch/timeupMail.txt /usr/yuch/*.url

keytool -genkey -alias serverkey -keystore /usr/yuch/YuchBerrySvr.key -validity 3650 -storepass qscesz -dname "CN=ec2.tossing.co.in, OU=EC2, O=Yuch, L=BlackBerry, ST=WTF, C=CN"

cat > /usr/yuch/start <<EOF
#!/bin/sh
cd /usr/yuch
nohup /opt/ibm/java-i386-60/jre/bin/java -jar svr.jar &
EOF

chmod +x /usr/yuch/start

sed -i 's/^exit 0/\/usr\/yuch\/start\n\nexit 0/' /etc/rc.local

/usr/yuch/start
}

install_jre() {
cd /usr
wget -O - http://dl.dropbox.com/u/182853/ibm-java-i386-jre-6.0-9.0.i386.rpm > ibm-java-i386-jre-6.0-9.0.i386.rpm
apt-get -y install alien
alien -d ibm-java-i386-jre-6.0-9.0.i386.rpm
dpkg -i ibm-java-i386-jre_6.0-10_i386.deb
rm -f ibm-java-i386-jre_6.0-10_i386.*
}

chinese_language() {

localedef -v -c -i zh_CN -f UTF-8 zh_CN.UTF-8

cat > /tmp/lang.ch <<EOF

export LC_ALL="zh_CN.utf8"
export LC_CTYPE="zh_CN.utf8"
export LANG="zh_CN.utf8"

if [ `echo $PATH | grep '/jre/bin' | wc -l` -lt 1 ] ; then
	export PATH=/opt/ibm/java-i386-60/jre/bin:$PATH
fi

EOF

cat /tmp/lang.ch >> /etc/profile
cat /tmp/lang.ch >> /etc/bash.bashrc

}
