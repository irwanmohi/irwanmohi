# configure rc.local
cat <<EOF >/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
chmod +x /etc/rc.local
systemctl daemon-reload
systemctl start rc-local

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get -y install wget curl

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config# install essential package

# Update & Upgrade
apt update
apt upgrade -y
apt-get -y install nano iptables-persistent dnsutils screen whois ngrep unzip unrar

# Remove unused dependencies
apt autoremove -y

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo -e "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Configure UFW
apt install -y ufw
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw
sed -i "s/IPV6=yes/IPV6=no/g" /etc/default/ufw
ufw allow 22
ufw allow 85
ufw allow 465
ufw allow 8080
ufw allow 1720
ufw allow 80
ufw allow 443
ufw allow 51820
ufw allow 7300
ufw allow 8000
ufw allow 3128
ufw allow 450
ufw allow 451
ufw reload
echo -e "y" | ufw enable

# Install tools
apt install -y net-tools vnstat unzip curl screen

# Install OpenVPN
apt install -y openvpn easy-rsa openssl
wget -q "https://raw.githubusercontent.com/irwanmohi/irwanmohi/main/deb10/openvpn//EasyRSA-3.0.8.tgz"
tar xvf EasyRSA-3.0.8.tgz
rm EasyRSA-3.0.8.tgz
mv EasyRSA-3.0.8 /etc/openvpn/easy-rsa
cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_COUNTRY\t"US"/set_var EASYRSA_REQ_COUNTRY\t"MY"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_PROVINCE\t"California"/set_var EASYRSA_REQ_PROVINCE\t"Kedah"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_CITY\t"San Francisco"/set_var EASYRSA_REQ_CITY\t"Bandar Baharu"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_ORG\t"Copyleft Certificate Co"/set_var EASYRSA_REQ_ORG\t\t"Void VPN"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_EMAIL\t"me@example.net"/set_var EASYRSA_REQ_EMAIL\t"aiman.iriszz@gmail.com"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_OU\t\t"My Organizational Unit"/set_var EASYRSA_REQ_OU\t\t"Void VPN Premium"/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_CA_EXPIRE\t3650/set_var EASYRSA_CA_EXPIRE\t3650/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_CERT_EXPIRE\t825/set_var EASYRSA_CERT_EXPIRE\t3650/g' /etc/openvpn/easy-rsa/vars
sed -i 's/#set_var EASYRSA_REQ_CN\t\t"ChangeMe"/set_var EASYRSA_REQ_CN\t\t"Void VPN"/g' /etc/openvpn/easy-rsa/vars
cd /etc/openvpn/easy-rsa
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
cd
mkdir /etc/openvpn/key
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/key/
wget -qO /etc/openvpn/server-udp.conf "https://raw.githubusercontent.com/irwanmohi/irwanmohi/main/deb10/openvpn//server-udp.conf"
wget -qO /etc/openvpn/server-tcp.conf "https://raw.githubusercontent.com/irwanmohi/irwanmohi/main/deb10/openvpn//server-tcp.conf"
sed -i "s/#AUTOSTART="all"/AUTOSTART="all"/g" /etc/default/openvpn
echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
echo -e "\n# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-I POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
-I POSTROUTING -s 10.9.0.0/24 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES" >> /etc/ufw/before.rules
ufw reload
systemctl start openvpn@server-udp
systemctl start openvpn@server-tcp
systemctl enable openvpn@server-udp
systemctl enable openvpn@server-tcp

# Configure OpenVPN client configuration
mkdir -p /home/openvpn
wget -qO /home/openvpn/client-udp.ovpn "https://raw.githubusercontent.com/irwanmohi/irwanmohi/main/deb10/openvpn//client-udp.ovpn"
wget -qO /home/openvpn/client-tcp.ovpn "https://raw.githubusercontent.com/irwanmohi/irwanmohi/main/deb10/openvpn//client-tcp.ovpn"
sed -i "s/xx/$ip/g" /home/openvpn/client-udp.ovpn
sed -i "s/xx/$ip/g" /home/openvpn/client-tcp.ovpn
echo -e "\n<ca>" >> /home/openvpn/client-tcp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /iriszz/openvpn/client-tcp.ovpn
echo -e "</ca>" >> /home/openvpn/client-tcp.ovpn
echo -e "\n<ca>" >> /home/openvpn/client-udp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /home/openvpn/client-udp.ovpn
echo -e "</ca>" >> /home/openvpn/client-udp.ovpn

# Install OHP
wget -qO /usr/bin/ohpserver "https://raw.githubusercontent.com/irwanmohi/irwanmohi/main/deb10/openvpn//ohpserver"
chmod +x /usr/bin/ohpserver
screen -AmdS ohp-dropbear ohpserver -port 3128 -proxy 127.0.0.1:8080 -tunnel 127.0.0.1:85
screen -AmdS ohp-openvpn ohpserver -port 8000 -proxy 127.0.0.1:8080 -tunnel 127.0.0.1:1194

# Install menu
wget -qO /usr/bin/menu "https://raw.githubusercontent.com/iriszz-official/autoscript/main/FILES/menu/menu.sh"
wget -qO /usr/bin/ssh-vpn-script "https://raw.githubusercontent.com/iriszz-official/autoscript/main/FILES/menu/ssh-vpn-script.sh"

# Cleanup and reboot
rm -f /root/install.sh
cp /dev/null /root/.bash_history
clear
echo -e ""
echo -e "Script executed succesfully."
echo -e ""
read -n 1 -r -s -p $"Press enter to reboot..."
echo -e ""
reboot
