cd
wget -O /etc/apt/sources.list "https://raw.githubusercontent.com/kruleshvpn/AutoscriptSHVPN/master/conf/sources.list.debian10"
cd
apt-get update
apt install php7.0 mysql-server mysql-client libapache2-mod-php7.0 phpmyadmin
cd
sudo ln -s /usr/share/phpmyadmin /home/vps/public_html
echo "" | sudo tee -a /etc/apache2/apache2.conf
echo "Include /etc/phpmyadmin/apache.conf" | sudo tee -a /etc/apache2/apache2.conf
echo "" | sudo tee -a /etc/apache2/apache2.conf
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin.conf
