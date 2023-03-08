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

#Mot de passe :
passwp="passwp"
passdl="passdl"
passmdb="passmdb"
passzabbix="passzabbix"

#Ip
ipdb="192.168.1.213"
ipzab="192.168.1.210"
ipwp="192.168.1.211"
ipdl="192.168.1.212"

set -ex
sudo apt-get update

    echo "${bleu}******************** 1.  Installation des paquets MariaDB  ********************"

sudo apt-get -y install mariadb-server mariadb-client curl wget

    echo "${bleu}******************** 2.  Création des données  ********************"
    echo "${bleu}***** Wordpress *****"

sudo mysql -uroot -e "CREATE DATABASE wpdata CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -uroot -e "CREATE USER wpuser@'${ipwp}' IDENTIFIED BY '${passwp}';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON wpdata.* TO 'wpuser'@'${ipwp}';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"

   echo "${bleu}***** Drupal *****"

sudo mysql -uroot -e "CREATE DATABASE dldata CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -uroot -e "CREATE USER dluser@'${ipdl}' IDENTIFIED BY '${passdl}';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON dldata.* TO 'dluser'@'${ipdl}';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"

    echo "${bleu}***** Zabbix *****"

sudo mysql -uroot -e "CREATE DATABASE zabbix DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -uroot -e "CREATE USER 'zabbix'@'${ipzab}' IDENTIFIED BY '${passzabbix}';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'${ipzab}';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"
sudo mysql -uroot -e "SET GLOBAL log_bin_trust_function_creators = 1;"

    echo "${bleu}***** Modification de l'accès à distance du serveur MariaDB *****"

sed -i 's/^bind-address.*/bind-address = */' /etc/mysql/mariadb.conf.d/50-server.cnf

    echo "${bleu}******************** 3. Sécurisation de la base de données MariaDB  ********************"

mysql_secure_installation <<EOF
y
#Switch to unix_socket authentication
n
#Change the root password
y
$passmdb
$passmdb
#Remove anonymous users?
y
#Disallow root login remotely?
y
#Remove test database and access to it?
y
# Reload privilege tables now?
y
EOF

echo -e "${bleu}******************** 4.  Installation zabbix Agent  ********************"

sudo apt-get -y install zabbix-agent

    echo -e "${bleu}************************* 5. Configuration zabbix agent ********************"

sudo sed -i "s/# DBHost=localhost/DBHost=$ipdb/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/Server=127.0.0.1/Server=192.168.1.210/" /etc/zabbix/zabbix_agentd.conf

    echo "${bleu}******************** 6. Redemarrage des services ********************"

sudo service mariadb restart
sudo service zabbix-agent restart

trap : 0

echo -e >&2 "${green}
**********************************************************
************* INSTALLATION DONE SUCCESSFULLY *************
**********************************************************
"

