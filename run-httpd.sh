#!/bin/bash
set -e

WORKDIR="/usr/local/src/freepbx"
PBX_MARKER="/var/www/html/.pbx"

cd "$WORKDIR"
./start_asterisk start

if [ ! -f "$PBX_MARKER" ]; then
  echo "First-time FreePBX installation detected."
  sleep 5
  ./install \
    --dbengine="${DBENGINE}" --dbname="${DBNAME}" --dbhost="${DBHOST}" --dbport="${DBPORT}" \
    --cdrdbname="${CDRDBNAME}" --dbuser="${DBUSER}" --dbpass="${DBPASS}" \
    --user="${USER}" --group="${GROUP}" --webroot="${WEBROOT}" \
    --astetcdir="${ASTETCDIR}" --astmoddir="${ASTMODDIR}" --astvarlibdir="${ASTVARLIBDIR}" \
    --astagidir="${ASTAGIDIR}" --astspooldir="${ASTSPOOLDIR}" --astrundir="${ASTRUNDIR}" \
    --astlogdir="${ASTLOGDIR}" --ampbin="${AMPBIN}" --ampsbin="${AMPSBIN}" \
    --ampcgibin="${AMPCGIBIN}" --ampplayback="${AMPPLAYBACK}" -n

  fwconsole ma installall
  fwconsole reload
  fwconsole restart

  touch "$PBX_MARKER"
  mkdir -p /var/lib/asterisk/etc
  cp /etc/freepbx.conf /var/lib/asterisk/etc/
  chown -R asterisk:asterisk /var/lib/asterisk/etc
else
  echo "FreePBX already installed, skipping installation."

  [ ! -L /etc/freepbx.conf ] && ln -s /var/lib/asterisk/etc/freepbx.conf /etc/freepbx.conf
  [ ! -L /usr/sbin/fwconsole ] && ln -s /var/lib/asterisk/bin/fwconsole /usr/sbin/fwconsole

  fwconsole reload
  fwconsole restart
fi

exec /usr/sbin/apachectl -DFOREGROUND
