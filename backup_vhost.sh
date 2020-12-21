#!/bin/bash

#;
#; be more specific;
#; todo: extended logs;
#; todo: more backup options;
#; todo: notification systems;
#; 

if [ -z "$1" ]
  then
    echo "No vhost argument;";
    exit 1;
fi

USERNAME=$1;
APP_PATH=/var/www/vhosts/$USERNAME;
APP_SOURCE=$APP_PATH/pub;
APP_BACKUPS=$APP_PATH/backups;
BACKUP="$( date '+%Y.%m.%d__%H-%M-%S' )";

APP_DB_FILE=$APP_BACKUPS/$USERNAME.$BACKUP.sql.gz
BACKUP_FILE=$APP_BACKUPS/$USERNAME.$BACKUP.zip;

if [ ! -e /tmp/vhost_backup.log ]; then
   touch /tmp/vhost_backup.log;
fi

echo "Running files backup for $1" >> /tmp/vhost_backup.log;
echo "Backup file is $BACKUP_FILE" >> /tmp/vhost_backup.log;
echo "=====================" >> /tmp/vhost_backup.log;
zip -r $BACKUP_FILE $APP_SOURCE #-x *folder/to/exclude*;

echo "Running mysql backup for $1" >> /tmp/vhost_backup.log;
echo "Backup file is $APP_DB_FILE" >> /tmp/vhost_backup.log;
echo "=====================" >> /tmp/vhost_backup.log;
mysqldump -uroot $USERNAME  | gzip > $APP_DB_FILE;
exit 0;