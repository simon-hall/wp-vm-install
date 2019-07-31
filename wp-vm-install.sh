#!/bin/bash
set -e
 
WPDIR="/var/www/localhost/htdocs"
WPUSER="sparky"
WPUSERPW="sparkyspassword"
DBROOTPW="MariaDB Root password"
DBWPPW="MariaDB Wordpress password"
HOSTNAME=$(ip route get 1 | awk '{print $NF;exit}')
 
echo -e "\n-->Enable community repo"
sed -i '/edge/b; /community/s/^#//g' /etc/apk/repositories
 
echo -e "\n-->Update packages"
apk update
 
echo -e "\n-->Installing required packages"
apk add lighttpd php7-common php7-iconv php7-json php7-gd php7-curl php7-xml php7-mysqli php7-imap php7-cgi fcgi php7-pdo php7-pdo_mysql php7-soap php7-xmlrpc php7-posix php7-mcrypt php7-gettext php7-ldap php7-ctype php7-dom wget php-mysqli mysql mysql-client php-zlib php-cli php-phar
 
echo -e "\n-->Modifying /etc/lighttpd/lighttpd.conf"
# Uncomments line 'include "mod_fastcgi.conf"'
sed -i '/include "mod_fastcgi.conf"/s/^#//g' /etc/lighttpd/lighttpd.conf
 
echo -e "\n-->Modifying /etc/lighttpd/mod_fastcgi.conf"
sed '#/usr/bin/php-cgi7#b;s#/usr/bin/php-cgi#/usr/bin/php-cgi7#g' /etc/lighttpd/mod_fastcgi.conf
 
echo -e "\n-->Enabling lighttpd service"
rc-service lighttpd start && rc-update add lighttpd default
 
echo -e "\n-->Initializing MariaDB"
/etc/init.d/mariadb setup
 
echo -e "\n-->Enabling MariaDB service"
/etc/init.d/mariadb start && rc-update add mariadb default
 
echo -e "\n-->Setting MariaDB root password"
/usr/bin/mysqladmin -u root password "${DBROOTPW}"
 
echo -e "\n-->Creating Wordpress DB"
mysql -u root -p"${DBROOTPW}" -e "CREATE DATABASE wordpress;"
mysql -u root -p"${DBROOTPW}" -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY \"${DBWPPW}\";"
mysql -u root -p"${DBROOTPW}" -e "FLUSH PRIVILEGES;"
 
echo -e "\n-->Downloading WP-CLI"
wget -O ~/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
 
echo -e "\n-->Installing WP-CLI"
chmod +x ~/wp-cli.phar
mv ~/wp-cli.phar /usr/bin/wp
 
echo -e "\n-->Downloading Wordpress"
wget -O ~/wordpress.tgz http://wordpress.org/latest.tar.gz
 
echo -e "\n-->Extracting Wordpress"
tar xvzf ~/wordpress.tgz -C "$WPDIR" --strip-components=1
 
echo -e "\n-->Setting permissions on web directory"
chown -R lighttpd. $WPDIR
 
echo -e "\n-->Creating wp-config.php"
wp config create --path="${WPDIR}" --dbname='wordpress' --dbuser='wordpress' --dbpass="${DBWPPW}" --dbhost='localhost' --allow-root
 
echo -e "\n-->Running Wordpress install"
wp core install --path="${WPDIR}" --url="http://${HOSTNAME}" --title="My AlpineVM Wordpress site" --admin_user="${WPUSER}" --admin_password="${WPUSERPW}" --admin_email="changeme@example.com" --allow-root
 
echo -e "\n-->Done! Now browse to http://${HOSTNAME}/"
