#!/bin/bash

red='\033[31m'
green='\033[32m'
bleu='\e[1;34m'

abort()
{
    echo -e >&2 "${red}
**********************************************************
****************** INSTALLATION ABORTED ******************
**********************************************************
"
    echo "An error occurred. Exiting..." >&2
    exit 1
}

trap 'abort' 0

#Identifiant
user="wpuser"
pass="passwp"

#Ip
ip_bdd="192.168.1.213"

set -ex

    # A exécuter sur wordpress
    echo -e "${bleu}******************************* 1. Installation du service Apache2 *******************************"
sudo apt-get update
sudo apt-get -y install apache2 locales-all wget
sudo systemctl start apache2

    echo -e "${bleu}******************************* 2. Activation du service Apache2 *******************************"
sudo systemctl enable apache2
sudo systemctl restart apache2

    echo -e "${bleu}******************************* 3. Activation du mode rewrite *******************************"
sudo a2enmod rewrite

    echo -e "${bleu}******************************* 4. Activation du mode SSL 'Https' *******************************"
sudo a2enmod ssl

    echo -e "${bleu}******************************* 5. Activation du mode deflate *******************************"
sudo a2enmod deflate

    echo -e "${bleu}******************************* 6. Activation du mode headers 'En-tête HTTP' *******************************"
sudo a2enmod headers

    echo -e "${bleu}******************************* 7. Masqué la version du serveur Apache2' *******************************"
echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf

    echo -e "${bleu}******************************* 8. Configuration d'Apache2 *******************************"
sudo cat <<"EOF" > /etc/apache2/sites-available/000-default.conf
NameVirtualHost *:80
<VirtualHost *:80>
    UseCanonicalName Off
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    Options All
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    echo -e "${bleu}******************************* 9.  Installation de Zabbix Agent  *******************************"
sudo apt-get -y install zabbix-agent

    echo -e "${bleu}******************************* 10. Configuration de Zabbix Agent *******************************"
sudo sed -i "s/# DBHost=localhost/DBHost=$ip_bdd/" /etc/zabbix/zabbix_agentd.conf 
sudo sed -i "s/Server=127.0.0.1/Server=192.168.1.210/" /etc/zabbix/zabbix_agentd.conf

    echo -e "${bleu}********************* 11. Installation de PHP et des modules nécessaires  *******************************"
sudo apt-get -y install php libapache2-mod-php php-fpm php-curl php-cli php-zip php-mysql php-xml php-mbstring php-gd php-xmlrpc php-imagick php-intl php-soap 

    echo -e "${bleu}********************************* 12. Téléchargement de CMS Wordpress *******************************"
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

    echo -e "${bleu}********************** 13. Déplacer de tout les fichiers Wordpress *******************************"
sudo mv wordpress/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/

        echo -e "${bleu}********************** 14. Augmentation de la taille des fichiers téléversés sur WordPress *******************************"
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 3G/g' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/post_max_size = 8M/post_max_size = 3G/g' /etc/php/7.4/fpm/php.ini
sudo service php7.4-fpm restart
sudo service apache2 restart

    echo -e "${bleu}**************************** 15. Configuration du fichier wp-confing.php *******************************"
sudo touch  /var/www/html/wp-config.php
sudo cat <<"EOF" > /var/www/html/wp-config.php
<?php
# Created by setup-mysql
define('DB_NAME', 'wpdata');
define('DB_USER', 'user_to_replace');
define('DB_PASSWORD', 'password_to_replace');
define('DB_HOST', 'host_to_replace');
$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF

sudo sed -i "s/user_to_replace/$user/" /var/www/html/wp-config.php
sudo sed -i "s/password_to_replace/$pass/" /var/www/html/wp-config.php
sudo sed -i "s/host_to_replace/$ip_bdd/" /var/www/html/wp-config.php

    echo  -e "${bleu}*********************** 16. Modification des droits sur wp-confing.php *******************************"
sudo chmod 400 /var/www/html/wp-config.php
sudo chown -R www-data:www-data /var/www/html/wp-config.php

    echo -e "${bleu}************************************ 17. Suppression des fichiers par défaut *******************************"   
sudo rm -rf /var/www/html/index.html
sudo rm -rf /var/www/html/wp-config-sample.php
sudo rm -rf /var/www/html/wp-content/themes/twentytwentythree/
sudo rm -rf /var/www/html/wp-content/themes/twentytwentytwo/

    echo -e "${bleu}************************************* 18. Redémarrage des services *******************************"
sudo service php7.4-fpm restart
sudo service apache2 restart
sudo service zabbix-agent restart

sudo a2enmod rewrite
sudo a2enmod vhost_alias

trap : 0

echo -e >&2 "${green}
**********************************************************
************* INSTALLATION DONE SUCCESSFULLY *************
**********************************************************
"

