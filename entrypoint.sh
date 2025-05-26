#!/bin/bash
set -e

DB_HOST=${DB_HOST:-mariadb}
DB_USER=${DB_USER:-asterisk}
DB_PASS=${DB_PASS:-asteriskpassword}
DB_NAME=${DB_NAME:-asterisk}

echo "Waiting for database at $DB_HOST..."

# Wait for DB to be ready
until mysql -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" -e "status" &> /dev/null; do
  echo "Waiting for database connection..."
  sleep 3
done

echo "Database is available."

# Check if FreePBX is installed (by presence of asterisk.conf)
if [ ! -f "/etc/asterisk/asterisk.conf" ]; then
  echo "FreePBX not detected, running initial setup..."

  # Run FreePBX install (it will connect to external DB)
  /usr/src/freepbx/start_asterisk start
  /usr/src/freepbx/install -n

  echo "FreePBX initial setup complete."
else
  echo "FreePBX installation detected."
fi

# Start supervisord to manage Apache and Asterisk
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
