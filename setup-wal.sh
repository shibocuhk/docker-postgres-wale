#!/bin/bash

# Assumption: the group is trusted to read secret information
umask u=rwx,g=rx,o=

if [ "$POSTGRES_AUTHORITY" = "slave" ]
then
  echo "Authority: Slave - Fetching latest backups";

  pg_ctl -D "$PGDATA" -w stop
  # $PGDATA cannot be removed so use temporary dir
  # If you don't stop the server first, you'll waste 5hrs debugging why your WALs aren't pulled
  /wal-g backup-fetch /tmp/pg-data LATEST
  cp -rf /tmp/pg-data/* $PGDATA
  rm -rf /tmp/pg-data

  # Create recovery.conf
  echo "standby_mode     = 'yes'" >> $PGDATA/recovery.conf
  echo "restore_command  = '/wal-g wal-fetch "%f" "%p"'" >> $PGDATA/recovery.conf
  echo "trigger_file     = '$PGDATA/trigger'" >> $PGDATA/recovery.conf

  chown -R postgres "$PGDATA"

  # Starting server again to satisfy init script
  pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
else
  echo "Authority: Master - Scheduling WAL backups";

  echo "wal_level = archive" >> /var/lib/postgresql/data/postgresql.conf
  echo "archive_mode = on" >> /var/lib/postgresql/data/postgresql.conf
  echo "archive_command = '/wal-g wal-push %p'" >> /var/lib/postgresql/data/postgresql.conf
  echo "archive_timeout = 60" >> /var/lib/postgresql/data/postgresql.conf

  crontab -l | { cat; echo "0 3 * * * /wal-g backup-push /var/lib/postgresql/data"; } | crontab -
  crontab -l | { cat; echo "0 4 * * * /wal-g delete --confirm retain 7"; } | crontab -
fi
