#!/bin/sh

echo "start to install nginx"

# import public key
KEY='ABF5BD827BD9BF62'
gpg --keyserver subkeys.pgp.net --recv $KEY
gpg --export --armor $KEY  |  apt-key add -

cat >> /etc/apt/sources.list <<EOF
deb http://nginx.org/packages/debian/ squeeze nginx
deb-src http://nginx.org/packages/debian/ squeeze nginx
EOF
apt-get update
apt-get -y --force-yes install nginx

wget -O - http://ddwrt.googlecode.com/svn/trunk/other/elegantclean.zip > /tmp/elegantclean.zip
unzip -uoC /tmp/elegantclean.zip -d /tmp

mkdir -p /usr/hosts/tossing.co.in/html
mv -f /tmp/elegantclean /usr/hosts/tossing.co.in/html

