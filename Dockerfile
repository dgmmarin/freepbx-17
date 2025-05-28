FROM debian:12

# Environment setup
ENV ASTERISK_VERSION=20
ENV FREEPBX_VERSION=17.0-latest-EDGE
ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies
RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y \
  build-essential git curl wget subversion \
  apache2 openssh-server cron mariadb-client bison flex \
  php8.2 php8.2-curl php8.2-cli php8.2-common php8.2-mysql \
  php8.2-gd php8.2-mbstring php8.2-intl php8.2-xml php-soap php-pear \
  libnewt-dev libssl-dev libncurses5-dev libsqlite3-dev libjansson-dev \
  libxml2-dev uuid-dev default-libmysqlclient-dev unixodbc-dev \
  libasound2-dev libogg-dev libvorbis-dev libicu-dev \
  libcurl4-openssl-dev odbc-mariadb libical-dev libneon27-dev \
  libsrtp2-dev libspandsp-dev software-properties-common \
  nodejs npm ipset iptables fail2ban vim sox lame ffmpeg mpg123 \
  expect sudo htop sngrep pkg-config automake autoconf libtool libtool-bin && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Build and install Asterisk
RUN wget -O /usr/src/asterisk.tar.gz http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}-current.tar.gz && \
  tar xzf /usr/src/asterisk.tar.gz -C /usr/src/ && \
  cd /usr/src/asterisk-* && \
  contrib/scripts/get_mp3_source.sh && \
  contrib/scripts/install_prereq install && \
  ./configure --libdir=/usr/lib64 --with-pjproject-bundled --with-jansson-bundled && \
  make menuselect.makeopts && \
  menuselect/menuselect --enable app_macro menuselect.makeopts && \
  make && make install && make samples && make config && \
  ldconfig && \
  rm /usr/src/asterisk.tar.gz

# Create Asterisk user and set permissions
RUN groupadd asterisk && \
  useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
  usermod -aG audio,dialout asterisk && \
  mkdir -p /var/lib/asterisk/etc && \
  chown -R asterisk:asterisk /etc/asterisk /var/{lib,log,spool}/asterisk /usr/lib64/asterisk && \
  echo "AST_USER=asterisk" >> /etc/default/asterisk && \
  echo "AST_GROUP=asterisk" >> /etc/default/asterisk && \
  echo -e "[options]\nrunuser = asterisk\nrungroup = asterisk" >> /etc/asterisk/asterisk.conf && \
  echo "/usr/lib64" >> /etc/ld.so.conf.d/x86_64-linux-gnu.conf && ldconfig

# Configure Apache and PHP
RUN sed -i 's/upload_max_filesize = .*/upload_max_filesize = 20M/' /etc/php/8.2/apache2/php.ini && \
  sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php/8.2/apache2/php.ini && \
  sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf && \
  sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf && \
  a2enmod rewrite ssl && \
  rm -f /var/www/html/index.html

# Add ODBC and SSL configuration
COPY odbc.ini /etc/odbc.ini
COPY odbcinst.ini /etc/odbcinst.ini
COPY ./default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
RUN a2ensite default-ssl

# Install FreePBX
RUN wget -O /usr/local/src/freepbx-${FREEPBX_VERSION}.tgz http://mirror.freepbx.org/modules/packages/freepbx/freepbx-${FREEPBX_VERSION}.tgz && \
  tar zxvf /usr/local/src/freepbx-${FREEPBX_VERSION}.tgz -C /usr/local/src && \
  rm /usr/local/src/freepbx-${FREEPBX_VERSION}.tgz

# Add entrypoint script
ADD run-httpd.sh /run-httpd.sh
RUN chmod +x /run-httpd.sh

# Declare volumes for persistent data
VOLUME [ "/var/lib/asterisk", "/etc/asterisk", "/usr/lib64/asterisk", "/var/www/html", "/var/log/asterisk" ]

# Expose SIP, HTTPS, RTP, etc.
EXPOSE 443 4569 4445 5060 5060/udp 5160/udp 18000-18100/udp

# Optional: add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD curl -f http://localhost || exit 1

# Run the entrypoint
CMD ["/run-httpd.sh"]
