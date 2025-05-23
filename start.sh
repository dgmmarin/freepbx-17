#!/bin/bash
set -e

# Wait for MariaDB to be available
echo "Waiting for MariaDB at $MYSQL_HOST..."
until mysqladmin ping -h "$MYSQL_HOST" --silent; do
  sleep 2
done
echo "MariaDB is up."

# Start Asterisk in the background
echo "Starting Asterisk..."
runuser -u asterisk -- /usr/sbin/asterisk &

# Wait for Asterisk to respond
echo "Waiting for Asterisk to become responsive..."
until runuser -u asterisk -- asterisk -rx "core show uptime" > /dev/null 2>&1; do
  sleep 5
done
echo "Asterisk is running."

# Run FreePBX install only if not installed yet
if [ ! -f /etc/freepbx.conf ]; then
  cd /usr/src/freepbx || exit
  ./install -n \
    --dbhost=${MYSQL_HOST:-mariadb} \
    --dbname=${MYSQL_DATABASE:-asterisk} \
    --dbuser=${MYSQL_USER:-root} \
    --dbpass=${MYSQL_PASSWORD:-your_root_password}
fi


# Start Apache in foreground
echo "Starting Apache..."
apache2ctl -D FOREGROUND
