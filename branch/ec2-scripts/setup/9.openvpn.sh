#!/bin/sh

apt-get -y install openvpn libssl-dev openssl
cd /etc/openvpn/
sudo mkdir easy-rsa
sudo cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0/* /etc/openvpn/easy-rsa/
sudo chown -R $USER /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa/
# here change the ca
vi vars

source vars
./clean-all
source vars
./build-ca
./build-dh
source vars
./pkitool --server server
cd keys
openvpn --genkey --secret ta.key
sudo cp server.crt server.key ca.crt dh2048.pem ta.key /etc/openvpn/
cd ..
source vars
./pkitool kevin
cd ..

cat > /usr/openvpn.ipt <<EOF
#!/bin/sh
/sbin/iptables -t nat -A POSTROUTING -s 10.8.80.0/24 -o eth0 -j MASQUERADE
EOF
chmod +x /usr/openvpn.ipt
sed -i 's/^exit 0/\/usr\/openvpn.ipt\n\nexit 0/' /etc/rc.local

