#!/bin/bash
if [ ! -f /home/magento/readme.txt ]; then
    # mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    ROOT_PASSWORD="root" # `pwgen -c -n -1 12`
    MYSQL_ROOT_PASSWORD="root"
    MYSQL_MAGENTO_PASSWORD="magento"
    MAGENTO_PASSWORD="magento"
    echo "magento:$MAGENTO_PASSWORD" | chpasswd
    echo "root:$ROOT_PASSWORD" | chpasswd

    mysqladmin -u root password $MYSQL_ROOT_PASSWORD
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD < /usr/share/phpmyadmin/sql/create_tables.sql
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY 'pmapass';"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE magento; GRANT ALL PRIVILEGES ON magento.* TO 'magento'@'localhost' IDENTIFIED BY '$MYSQL_MAGENTO_PASSWORD'; FLUSH PRIVILEGES;"

    killall mysqld
    # mv /var/lib/mysql/ibdata1 /var/lib/mysql/ibdata1.bak
    # cp -a /var/lib/mysql/ibdata1.bak /var/lib/mysql/ibdata1
fi

# start all the services
/usr/local/bin/supervisord -c /etc/supervisord.conf

if [ ! -f /home/magento/readme.txt ]; then
    CONTAINER_IP=`networkctl status | awk '/Address/ {print $2}'`
    echo -e "SSH Address\t: http://$CONTAINER_IP:4200" >> /home/magento/readme.txt
    echo -e "Services Addr\t: http://$CONTAINER_IP:9011" >> /home/magento/readme.txt
    echo -e "Web Address\t: https://$CONTAINER_IP" >> /home/magento/readme.txt
    echo -e "Web Directory\t: /home/magento/files/html" >> /home/magento/readme.txt
    echo -e "SSH/SFTP\t: magento/magento" >> /home/magento/readme.txt
    echo -e "ROOT User\t: root/root" >> /home/magento/readme.txt
    echo -e "Database Name\t: magento" >> /home/magento/readme.txt
    echo -e "Database User\t: magento/magento" >> /home/magento/readme.txt
    echo -e "DB ROOT User\t: root/root" >> /home/magento/readme.txt
    echo -e "phpMyAdmin\t: http://$CONTAINER_IP/phpmyadmin" >> /home/magento/readme.txt
fi

cat /home/magento/readme.txt
/usr/sbin/sshd -De