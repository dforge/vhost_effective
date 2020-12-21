#!/bin/bash

#;
#; todo: modify inputs name format (like fqdn);
#; todo: provide user frendly input (php-version);
#; todo: input validation;
#;

#;
#; check block;
#;


### greeting;
echo -e "\e[35m hello vhost!;";
echo -e "\e[39m";

### check fpm template file;
echo -e "\e[36m check fpm template file;";
echo -e "\e[39m";

if [ ! -f $PWD/fpm.conf.j2 ]; then
    echo -e "\e[31mfpm.conf.j2 file not found; exiting...";
    echo -e "\e[39m";
    exit 1;
fi

### cheking vhost template file;
echo -e "\e[36m Check fpm template file;";
echo -e "\e[39m";

if [ ! -f $PWD/vhost.conf.j2 ]; then
    echo -e "\e[31m vhost.conf.j2 file not found; exiting...";
    echo -e "\e[39m";
    exit 1;
fi

### 3. check root status;
echo -e "\e[36m Check root status;";
echo -e "\e[39m";

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31m This script must be run as root; exiting...";
   echo -e "\e[39m"; 
   exit 1;
fi

#;
#; input block; 
#;


### capturing host name;
read -p " Write hostname (example: google/other.google/www.google) " HOST;
if [ -z "$HOST" ]; then
   echo -e "\e[31mhost is required; exiting...";
   echo -e "\e[39m"; 
   exit 1
fi

### capturing domain name;
read -p " Write the first level domain (example: ru) " DOMAIN;
if [ -z "$DOMAIN" ]; then
   echo -e "\e[31m1st level domain is required; exiting...";
   echo -e "\e[39m"; 
   exit 1
fi

### capturing php-fpm version;
echo -e "\e[36m installed php versions is:"
echo -e "\e[39m";
ls /etc/php --color=auto
read -p " Write the PHP version. Enter for default (7.4) " VERSION;
if [ -z "${VERSION}" ]; then
    echo -e "\e[33mversion not selected, default is 7.4";
    echo -e "\e[39m"; 
fi;

### backup request;
read -p "Enable cron backups(database/files) (y/n)? Enter for No:" BACKUP;
case "$BACKUP" in 
  y|Y ) BACKUP=true;;
  n|N ) BACKUP=false;;
  * ) BACKUP=false;;
esac

#;
#; variable setup;
#;


# fpm and vhost j2 configuration;
J2_FPM=$PWD/fpm.conf.j2;
J2_VHOST=$PWD/vhost.conf.j2;
VERSION=${VERSION:-"7.4"};
BACKUP=${BACKUP:-false};

SEC_PASS="< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8";
DB_PASS="< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8";

SEC_STRING=$(eval "$SEC_PASS");
SQL_STRING=$(eval "$DB_PASS");

FQDN=$HOST.$DOMAIN;
USERNAME=${FQDN//./_};

APP_PATH=/var/www/vhosts/$USERNAME;
APP_PUBLIC=$APP_PATH/pub;
APP_LOGS=$APP_PATH/logs;
APP_SSL=$APP_PATH/ssl;
APP_CONF=$APP_PATH/conf;
APP_SSH=$APP_PATH/.ssh;
APP_CRON=$APP_PATH/cron;
APP_BACKUPS=$APP_PATH/backups;

FPM_SOCK=/run/php/$VERSION.$USERNAME.sock
FPM_CONF_APP=$APP_CONF/$USERNAME.fpm.conf
FPM_EFFECTIVE=/etc/php/$VERSION/fpm/pool.d/$VERSION.$USERNAME.conf;

VHOST_CONF_APP=$APP_CONF/$USERNAME.http.conf
VHOST_EFFECTIVE=/etc/nginx/conf.d/$USERNAME.conf;

# service things conf;
CURRENT_DATE=$( date '+%Y.%m.%d__%H-%M-%S' );
SCRIPT_ROOT=/var/www/vhosts;

#;
#; Creating directories;
#;

### create directories; not validating;
echo -e "\e[36m create directories;";
echo -e "\e[39m";

mkdir -p $APP_PATH;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_PATH; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_PUBLIC;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_PUBLIC; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_LOGS;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_LOGS; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_SSL;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_SSL; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_CONF;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_CONF; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_SSH;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_SSH; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_CRON;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_CRON; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

mkdir -p $APP_BACKUPS;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create directory: $APP_BACKUPS; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

#;
#; Creating user;
#;


### creating user;
echo -e "\e[36m creating user;";
echo -e "\e[39m";

groupadd $USERNAME;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create user (groupadd error) exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

useradd -g $USERNAME -d $APP_PATH $USERNAME;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create user (useradd error) exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

echo -e "$SEC_PASS\n$SEC_PASS\n" | passwd $USERNAME;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create user (passwd error) exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

usermod -s /bin/bash $USERNAME;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create user (usermod error) exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### notify about bad passwd work;
echo -e "\e[33m#########################################################;
Sometime the passwd works not as expected, you may use reset password manually, in this case login and password entries in file credentials.txt will not work;
#########################################################";
echo -e "\e[39m";
sleep 1;

#;
#; Modify permissions;
#;


### running chown -R;
echo -e "\e[36m running chown -R;";
echo -e "\e[39m";

chown -R $USERNAME:$USERNAME $APP_PATH;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot setup permissions(chown); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### running chmod -R;
echo -e "\e[36m running chmod -R;";
echo -e "\e[39m";

chmod -R 0775 $APP_PATH;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot setup permissions(chmod); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

#;
#; Creating vhost and php-fpm;
#;

### creating fpm_effective;
echo -e "\e[36m creating fpm_effective;";
echo -e "\e[39m";
touch $FPM_EFFECTIVE
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot setup configuration($FPM_EFFECTIVE); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### write fpm effective;
echo -e "\e[36m write fpm effective;";
echo -e "\e[39m";
echo "include=$FPM_CONF_APP;" > $FPM_EFFECTIVE;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot setup configuration($FPM_EFFECTIVE); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### copy fpm configuration file;
echo -e "\e[36m copy fpm configuration files;";
echo -e "\e[39m";
cp $J2_FPM $FPM_CONF_APP;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot copy configuration file($FPM_CONF_APP); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### creating vhost_effective;
echo -e "\e[36m creating vhost_effective;";
echo -e "\e[39m";
touch $VHOST_EFFECTIVE
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot setup configurations($VHOST_EFFECTIVE); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### write vhost_effective;
echo -e "\e[36m write vhost_effective;";
echo -e "\e[39m";
echo "include $VHOST_CONF_APP;" > $VHOST_EFFECTIVE;

### copy vhost_effective configuration file;
echo -e "\e[36m copy vhost_effective configuration file;";
echo -e "\e[39m";
cp $J2_VHOST $VHOST_CONF_APP;
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot copy configuration file($VHOST_CONF_APP); exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

### seeding;
echo -e "\e[36m seeding configuration files; no validating";
echo -e "\e[39m";
sed -i "s|cdfqdn|$FQDN|g" $FPM_CONF_APP;
sed -i "s|cdfqdn|$FQDN|g" $VHOST_CONF_APP;
sed -i "s|cdsock|$FPM_SOCK|g" $FPM_CONF_APP;
sed -i "s|cdsock|$FPM_SOCK|g" $VHOST_CONF_APP;
sed -i "s|cdnuser|$USERNAME|g" $FPM_CONF_APP;
sed -i "s|cdnuser|$USERNAME|g" $VHOST_CONF_APP;

### setup mysql
echo -e "\e[36m Creating database and database user;";
echo -e "\e[39m";
echo -e "\e[33m By default using root accaount and my.cnf with no password;";
echo -e "\e[39m";

QUERY="CREATE DATABASE IF NOT EXISTS ${USERNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;";
QUERY="${QUERY} CREATE USER ${USERNAME}@localhost IDENTIFIED BY '${SQL_STRING}';";
QUERY="${QUERY} GRANT ALL PRIVILEGES ON ${USERNAME}.* TO '${USERNAME}'@'localhost';";
QUERY="${QUERY} FLUSH PRIVILEGES;";

mysql -uroot -e "${QUERY}";

if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create mysql database; exiting...";
    echo -e "\e[39m No skip, do it manualy!";
fi

### generate self-signed certs
echo -e "\e[36m Generating self-signed certificates;";
echo -e "\e[33m Please provide valid ssl certificate later;";
echo -e "\e[39m";
openssl req -x509 -nodes -days 365 -new -subj "/C=RU/CN=$FQDN" -addext "subjectAltName = DNS:$FQDN" -newkey rsa:2048 -keyout $APP_SSL/ssl.key -out $APP_SSL/ssl.crt
if [ ! $? -eq 0 ]; then
    echo -e "\e[31m Cannot create ssl certificates; exiting...";
    echo -e "\e[39m Bye!";
    exit 1;
fi

RESULT="#########################################################
$CURRENT_DATE
https://$FQDN
#########################################################

Shell:
---
username      : $FQDN
password      : $SEC_STRING

Database:
---
name          : $USERNAME
user          : $USERNAME
password      : $SQL_STRING

Backups:
---
is enabled    : $BACKUP
path          : $APP_BACKUPS

Paths:
---
public(httpd) : $APP_PUBLIC
logs          : $APP_LOGS
confs         : $APP_CONF
ssl           : $APP_SSL

#########################################################";

echo -e "\e[32m $RESULT";
echo -e "\e[39m";

if [ -f $PWD/authorized_keys ]; then
    echo -e "\e[36m Found authorized_keys file; copying;";
    echo -e "\e[39m";
    cp -f $PWD/authorized_keys $APP_SSH/authorized_keys;
fi

echo -e "\e[36m creating index.php for testing;";
echo -e "\e[39m";
touch $APP_PUBLIC/index.php;
echo "<?php phpinfo(); ?>" > $APP_PUBLIC/index.php;

echo -e "#. testing nginx...just for information;";
nginx -t;

if [ -f $PWD/index.php ]; then
    echo -e "\e[36m Found greeting info; copying;";
    echo -e "\e[39m";
    cp -f $PWD/index.php $APP_PUBLIC/index.php;
    cp -f $PWD/picme.png $APP_PUBLIC/picme.png;
    cp -f $PWD/hello_linux.jpg $APP_PUBLIC/hello_linux.jpg;

    #
    echo -e "\e[36m Seeing greeting information;";
    echo -e "\e[39m";
    sed -i "s|cddbuser|$USERNAME|g" $APP_PUBLIC/index.php;
    sed -i "s|cddbpass|$SQL_STRING|g" $APP_PUBLIC/index.php;
    sed -i "s|cddbname|$USERNAME|g" $APP_PUBLIC/index.php;
fi

if [ "$BACKUP" = true ]; then
    cp -f $PWD/backup.sh $APP_CRON/$USERNAME.sh;
    echo "* 23 * * * /usr/bin/bash $APP_CRON/$USERNAME.sh $USERNAME" >> /var/spool/cron/crontabs/root;
    if [ ! $? -eq 0 ]; then
        echo -e "\e[31m Unable to add cron backup job;";
    fi
fi

echo -e "\e[36m Fixing permissions again; no validating;";
echo -e "\e[39m";
chown -R $USERNAME:$USERNAME $APP_PATH
chmod -R 0775 $APP_PATH
umask 0775 $APP_PATH/;

echo -e "\e[36m Restarting nginx and fpm service;";
echo -e "\e[39m";
systemctl restart php$VERSION-fpm.service;
systemctl restart nginx.service;

echo -e "\e[36m It's should be done! Please verify; Your faithful employer;";
echo -e "\e[39m";

exit 0;