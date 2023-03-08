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

set -e

ip_bdd="192.168.1.213"

    echo -e "${bleu}******************************* 1. Installation du service Apache2 ********************************************"
   
sudo apt-get update
sudo apt-get -y install apache2 locales-all wget
sudo systemctl start apache2

    echo -e "${bleu}************************ 2. Activé le service Apache2 au redémarrage du système *******************************"

sudo systemctl enable apache2
sudo systemctl restart apache2

    echo -e "${bleu}************************ 3. Activé le mode rewrite 'url plus structurée' **************************************"

sudo a2enmod rewrite

    echo "${bleu}****************************** 4.   Activé le mode ssl 'Https' **************************************************"

sudo a2enmod ssl

    echo -e "${bleu}******************** 5. Activé le mode deflate 'compression du site/plus rapide' ******************************"

sudo a2enmod deflate

    echo -e "${bleu}****************************** 6. Activé le mode headers 'en-tete http' **************************************"
    
sudo a2enmod headers

    echo -e "${bleu}***************************** 7. masqué la version du serveur apache2' ***************************************"

echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf


    echo -e "${bleu}********************* 8. Installation du PHP et de ses modules nécessaire  ************************************"
    
sudo apt-get install -y libnss-mdns php libapache2-mod-php php-fpm php-curl php-cli php-zip php-mysql php-xml php-mbstring php-gd php-xmlrpc php-imagick php-intl php-soap zabbix-agent

 echo -e "${bleu}********************************* 9. Telechargement du CMS Drupal ************************************************"
 
wget https://ftp.drupal.org/files/projects/drupal-9.5.3.tar.gz
tar -zxvf drupal-9.5.3.tar.gz

echo -e "${bleu}**************************** 10. modifier le nom du répértoire drupal ***********************************************"
sudo mv drupal-9.5.3 drupal

echo -e "${bleu}************************** 11. Deplacer tout les fichiers Drupal dans la racine drupal ******************************"
sudo mv drupal /var/www/html



    echo -e "${bleu}********************************** 12. Créer fich drupal *******************************************************"
    
sudo touch  /etc/apache2/sites-available/drupal.conf

     echo -e "${bleu}********************************* 13 attributs de propriété aux fichiers drupal *******************************************"
sudo chown -R www-data:www-data /var/www/html/drupal

    echo -e "${bleu}********************************** 14 Configuration apache2 **************************************************"
sudo cat <<"EOF" > /etc/apache2/sites-available/drupal.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/drupal
   #ServerName drupal.local
    Options All
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    echo -e "${bleu}********************************** 15 activer le site drupal **************************************************"
#sudo a2ensite /etc/apache2/sites-available/drupal.conf
sudo a2enmod rewrite
sudo service apache2 restart

    echo -e "${bleu}********************************** 16 modifier le site  par defaut ********************************************"
sudo cat <<"EOF" > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/drupal
        DirectoryIndex index.php
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
      
      <Directory /var/www/html/drupal>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>
EOF





echo -e "${bleu}******************************* 17. Supprimer les fichiers par defauts *****************************************************"
sudo rm -rf /var/www/html/index.html

echo -e "${bleu}****************************** 18.  Installation zabbix Agent  ********************************"

sudo apt-get -y install zabbix-agent

    echo -e "${bleu}************************* 19. Configuration zabbix agent *******************************************"

sudo sed -i "s/# DBHost=localhost/DBHost=$ip_bdd/" /etc/zabbix/zabbix_agentd.conf 
sudo sed -i "s/Server=127.0.0.1/Server=192.168.1.210/" /etc/zabbix/zabbix_agentd.conf

    
    echo -e "${bleu}***************************** 20. Recharger les fichiers de conf ~services~**********************************************"
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



