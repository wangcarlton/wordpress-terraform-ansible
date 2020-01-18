#! /bin/bash
sudo echo "127.0.0.1 `hostname`" >> /etc/hosts
sudo apt-get update -y
sudo apt-get install -y apache2 apache2-utils
sudo service apache2 restart
sudo systemctl enable apache2
sudo apt-get install -y php7.2
sudo apt-get install -y php7.2-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
sudo service apache2 restart
sudo wget -c https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sleep 20
sudo mkdir -p /var/www/html/
sudo rsync -av wordpress/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i -e "s/database_name_here/${db_name}/g" \
    -e "s/username_here/${db_username}/g" \
    -e "s/password_here/${db_password}/g" \
    -e "s/localhost/${db_host}/g" \
    /var/www/html/wp-config.php
sudo echo "define('FS_METHOD', 'direct');" >> /var/www/html/wp-config.php
sudo rm -rf /var/www/html/index.html

sudo service apache2 restart
sleep 20