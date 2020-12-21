#!/bin/bash

#;
#; todo: modify inputs name format (like fqdn);
#; todo: provide user frendly input (php-version);
#;

###
###
###
echo -e "\e[31m WARNING! THIS SCRIPT WILL DELETE ALL VHOST DATA (files/databases/backups/confs/logs);";
echo -e "\e[39m";

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31m This script must be run as root; exiting...";
   echo -e "\e[39m"; 
   exit 1;
fi

echo -e "\e[33m HINT! Exited PHP SOCKETS;";
echo -e "\e[39m";
ls -lah /run/php/*.sock --color=auto;

### capturing host name;
read -p " Write hostname (example: google/other.google/www.google) " HOST;
if [ -z "$HOST" ]; then
   echo -e "\e[31m host is required; exiting...";
   echo -e "\e[39m"; 
   exit 1
fi

### capturing domain name;
read -p " Write the first level domain (example: ru) " DOMAIN;
if [ -z "$DOMAIN" ]; then
   echo -e "\e[31m 1st level domain is required; exiting...";
   echo -e "\e[39m"; 
   exit 1
fi

### capturing php-fpm version;
read -p " Write the PHP version. Enter for default (7.4) " VERSION;
if [ -z "$VERSION" ]; then
   echo -e "\e[31m the php version is required to determine conf; exiting...";
   echo -e "\e[39m"; 
   exit 1
fi

echo -e "\e[33m Defining variables;";
echo -e "\e[39m";
FQDN=$HOST.$DOMAIN;
USERNAME=${FQDN//./_};
FPM_EFFECTIVE=/etc/php/$VERSION/fpm/pool.d/$VERSION.$USERNAME.conf;
VHOST_EFFECTIVE=/etc/nginx/conf.d/$USERNAME.conf;
_CRONTAB=/var/spool/cron/crontabs;
_CRONTAB=$_CRONTAB/$USERNAME;
QUERY="DROP DATABASE IF EXISTS $USERNAME;";
QUERY="${QUERY} DROP USER IF EXISTS ${USERNAME}@localhost;";
QUERY="${QUERY} FLUSH PRIVILEGES;";
echo -e "\e[32m Done!";
echo -e "\e[39m";

echo -e "\e[33m Finding application configuration files;";
echo -e "\e[39m";
if [ ! -f $FPM_EFFECTIVE ] || [ ! -f $VHOST_EFFECTIVE ]; then
    echo -e "\e[31m $FPM_EFFECTIVE or $VHOST_EFFECTIVE file not found; exiting...";
    echo -e "\e[39m"; 
    exit 1
fi
echo -e "\e[32m Founded!";
echo -e "\e[39m";

if [ -f $_CRONTAB ]; then
    echo -e "\e[33m Crontab found, deliting...;";
    echo -e "\e[39m";
    rm -rf $_CRONTAB;
    if [ ! $? -eq 0 ]; then
        echo -e "\e[31m Cannot delete;";
        echo -e "\e[39m Bye!";
    else
        echo -e "\e[32m Deleted!";
        echo -e "\e[39m";
    fi
fi

if [ -f /var/spool/cron/crontabs/root ]; then
    echo -e "\e[33m Found root crontab, removig assigned job;";
    echo -e "\e[39m";

    sed "/$USERNAME/d"  -i /var/spool/cron/crontabs/root;
    if [ ! $? -eq 0 ]; then
        echo -e "\e[31m Cannot remove cron job;";
    else
        echo -e "\e[32m Removed cron!";
        echo -e "\e[39m";
    fi

    echo -e "\e[33m Killing user process;";
    echo -e "\e[39m";

    pkill -f "$USERNAME";
    if [ ! $? -eq 0 ]; then
        echo -e "\e[31m Cannot kill;";
    else
        echo -e "\e[32m Killed!";
        echo -e "\e[39m";
    fi
fi

echo -e "\e[33m Remove database and access;";
echo -e "\e[39m";
mysql -uroot -e "${QUERY}";
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot delete mysql user;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Deleted!";
    echo -e "\e[39m";
fi

echo -e "\e[33m Remove FPM_EFFECTIVE files;";
echo -e "\e[39m";
rm -rf $FPM_EFFECTIVE
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot remove $FPM_EFFECTIVE;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Removed!";
    echo -e "\e[39m";
fi

echo -e "\e[33m Remove VHOST_EFFECTIVE files;";
echo -e "\e[39m";
rm -rf $VHOST_EFFECTIVE
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot remove $VHOST_EFFECTIVE;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Removed!";
    echo -e "\e[39m";
fi

echo -e "\e[33m Testing nginx;";
echo -e "\e[39m";
nginx -t
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Test failed;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Passed!";
    echo -e "\e[39m";
fi

echo -e "\e[33m Restart FPM service;";
echo -e "\e[39m";
systemctl restart php$VERSION-fpm.service
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m FPM restart failed;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Done!";
    echo -e "\e[39m";
fi

echo -e "\e[33m Restart FPM service;";
echo -e "\e[39m";
systemctl restart nginx.service
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m NGINX restart failed;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Done!";
    echo -e "\e[39m";
fi

echo -e "\e[33m Removing user;";
echo -e "\e[39m";
userdel -r -f $USERNAME;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot delete user;";
    echo -e "\e[39m Bye!";
else
    echo -e "\e[32m Deleted!";
    echo -e "\e[39m";
fi

echo -e "\e[36m It's should be done! Please verify; Your faithful employer;";
echo -e "\e[39m";