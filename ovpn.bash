#!/bin/bash

# First, Install Apache2
# Debian/Ubuntu
apt-get install apache2 -y

# CentOS 7
yum install apache2 -y

# If you encountered some installation error using the commands above, try googling for your solution, above are the common procedure for installing apache2 on your machine

# Second, create your directory where your openvpn configs can be downloadable
rm -rf /var/www/openvpn
mkdir -p /var/www/openvpn
# manage permission with that directory
chown -R www-data:www-data /var/www/openvpn
chmod -R g+rw /var/www/openvpn

# Third, create apache config to allow /var/www/openvpn to be use as an openvpn config download directory

cat <<'EOF'> /etc/apache2/conf-available/openvpn-configs.conf
<Directory "/var/www/openvpn">
Options Indexes FollowSymLinks
AllowOverride all
Require all granted
</Directory>
EOF

# Fourth, allow that config using a2enconf
a2enconf openvpn-configs
# then restart apache2 service
systemctl restart apache2 

# Fifth, now create site config for apache2
# I'm using port 88 as a service listener for apache2, so i'm a bit secure for my directory
# this will be accessible as http://my-ip-address:88/sample.ovpn
mkdir /etc/apache2/sites-available/
touch /etc/apache2/sites-available/openvpn-configs.conf
cat <<'EOF'> /etc/apache2/sites-available/openvpn-configs.conf
<VirtualHost *:88>
ServerAdmin myemail@gmail.com
ServerName localhost
DirectoryIndex index.html index.txt
DocumentRoot /var/www/openvpn
</VirtualHost>
EOF

sed -i '/Listen 80/aListen 88' /etc/apache2/ports.conf

# Sixth, allow that site config using a2ensite
a2ensite openvpn-configs
# then reload your apache2 service
systemctl reload apache2

# Seventh, to make sure we are making a .ovpn config download site, we'll adding http header to automatically imports a .ovpn config to our openvpn client application
echo 'AddType application/x-openvpn-profile .ovpn' > /var/www/openvpn/.htaccess

# Now, our webserver is ready so we'll take our .ovpn configs on /root directory and place it on /var/www/openvpn
# here, i'm also adding a empty index.html so we're secure for file indexing
echo '' > /var/www/openvpn/index.html
cp -R ~/*.ovpn /var/www/openvpn

# Now we can download and import our .ovpn configs without any SFTP/SCP or any cli-type filehosting site support
# e.g http://my-ip-address:88/client.ovpn
