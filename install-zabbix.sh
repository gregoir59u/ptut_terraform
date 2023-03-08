#!/bin/bash

bleu="\e[1;34m"

#Identifiant
pass="passzabbix"

#Ip
bdd="192.168.1.213"
zab="192.168.1.210"

        echo -e "${bleu}************************************** \\ Installation des paquets Zabbix // ********************************************************"
sudo apt-get update
sudo apt-get -y install apache2 php php-mysql php-mysqlnd php-ldap php-bcmath php-mbstring php-gd php-pdo php-xml libapache2-mod-php wget

        echo -e "${bleu}************************************** \\ Installation et configuration de Zabbix // *************************************************"
wget https://repo.zabbix.com/zabbix/6.2/debian/pool/main/z/zabbix-release/zabbix-release_6.2-4%2Bdebian11_all.deb -O zabbix-release6-2.deb
sudo dpkg -i zabbix-release6-2.deb

        echo -e "${bleu}************************************** \\ Installation Zabbix server, frontend, agent  // ****************************************"
sudo apt update
sudo apt-get -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

        echo -e "${bleu}************************************** \\ Installation de la langue  // ****************************************"
sudo apt-get -y install locales-all
sudo locale-gen en_US.UTF-8
sudo service apache2 restart

sudo apt-get update

sudo sed -i "s/# DBHost=localhost/DBHost=$bdd/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBPassword=/DBPassword=$pass/" /etc/zabbix/zabbix_server.conf

sudo sed -i '963i\date.timezone = "Europe/Paris"' /etc/php/7.4/cli/php.ini
sudo sed -i '963i\date.timezone = "Europe/Paris"' /etc/php/7.4/apache2/php.ini

        echo -e "${bleu}**************************** \\ Ajouter une base de données Zabbix à l'utilisateur zabbix (Mariadb) // **********************************"
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | sudo mysql -h $bdd -u zabbix -p$pass zabbix

        echo -e "${bleu}*************************************************** \\ Configuration Gui-Zabbix // *****************************************************"
sudo touch /etc/zabbix/web/zabbix.conf.php
sudo chmod 777 /etc/zabbix/web/zabbix.conf.php
sudo cat <<"EOF" > /etc/zabbix/web/zabbix.conf.php
<?php
$ZBX_LANG = 'fr_FR';
// Zabbix GUI configuration file.
$DB['TYPE']                     = 'MYSQL';
$DB['SERVER']                   = 'ip_database';    
$DB['PORT']                     = '0';
$DB['DATABASE']                 = 'zabbix';
$DB['USER']                     = 'zabbix';
$DB['PASSWORD']                 = 'pass_database';
// Schema name. Used for PostgreSQL.
$DB['SCHEMA']                   = '';
// Used TLS connection.
$DB['ENCRYPTION']               = false;
$DB['KEY_FILE']                 = '';
$DB['CERT_FILE']                = '';
$DB['CA_FILE']                  = '';
$DB['VERIFY_HOST']              = false;
$DB['CIPHER_LIST']              = '';
// Use IEEE754 compatible value range 64-bit Numeric
$DB['VAULT']                    = '';
$DB['VAULT_URL']                = '';
$DB['VAULT_DB_PATH']            = '';
$DB['VAULT_TOKEN']              = '';
$DB['VAULT_CERT_FILE']          = '';
$DB['VAULT_KEY_FILE']           = '';
$DB['DOUBLE_IEEE754']           = true;
// PHP Time zone
$PHP_TZ = 'Europe/Paris';
// nom de la base Zabbix hostname/IP
$ZBX_SERVER_NAME                = 'supervision_zabbix';
// Identifiant par defaut de Zabbix
$ZBX_USER = 'Admin';
$ZBX_PASSWORD = 'zabbix';
$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;
EOF

sudo sed -i "s/ip_database/$bdd/" /etc/zabbix/web/zabbix.conf.php
sudo sed -i "s/pass_database/$pass/" /etc/zabbix/web/zabbix.conf.php

    echo -e "${bleu}*************************************** \\ Suppression de la page par defaut index.html // ******************"
sudo rm -rf /var/www/html/index.html
sudo sed -i 's#DocumentRoot /var/www/html#DocumentRoot /usr/share/zabbix#g' /etc/apache2/sites-available/000-default.conf

sudo chmod 600 /etc/zabbix/web/zabbix.conf.php
sudo chown www-data:www-data /etc/zabbix/web/zabbix.conf.php

        echo -e "${bleu}*********************************************** \\ Redémarrage des services // ******************************************************"
sudo service apache2 restart
sudo service zabbix-server restart
sudo service zabbix-agent restart

sudo systemctl enable zabbix-server zabbix-agent apache2
