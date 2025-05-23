FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /usr/src

# Install dependencies
RUN apt-get update && apt-get install -y \
  wget curl gnupg2 ca-certificates lsb-release net-tools \
  cron ntpdate iputils-ping nano sudo git unzip sox \
  build-essential subversion libncurses5-dev uuid-dev \
  libxml2-dev libsqlite3-dev libjansson-dev libssl-dev \
  libedit-dev pkg-config python3 php php-cli php-mysql \
  php-curl php-mbstring php-gd php-xml php-bcmath php-zip \
  apache2 php-pear php-dev nodejs npm mariadb-client && \
  apt-get clean

# Create asterisk user and directories
RUN groupadd -r asterisk && useradd -r -d /var/lib/asterisk -g asterisk asterisk && \
  mkdir -p /var/run/asterisk /var/lib/asterisk /etc/asterisk /var/log/asterisk /var/spool/asterisk && \
  chown -R asterisk:asterisk /var/run/asterisk /var/lib/asterisk /etc/asterisk /var/log/asterisk /var/spool/asterisk

# Download and install Asterisk
RUN cd /usr/src && \
  wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-21.9.1.tar.gz && \
  tar xvfz asterisk-21.9.1.tar.gz && \
  cd asterisk-21.9.1 && \
  contrib/scripts/get_mp3_source.sh && \
  ./configure && make menuselect.makeopts && \
  menuselect/menuselect --enable CORE-SOUNDS-EN-WAV \
  --enable MOH-OPSOUND-WAV \
  --enable EXTRA-SOUNDS-EN-WAV \
  menuselect.makeopts && \
  make -j$(nproc) && make install && make samples && make config && ldconfig

# Configure asterisk.conf to run as the correct user
RUN echo '[directories](!)' >> /etc/asterisk/asterisk.conf && \
  echo 'runuser = asterisk' >> /etc/asterisk/asterisk.conf && \
  echo 'rungroup = asterisk' >> /etc/asterisk/asterisk.conf

# Clone and install FreePBX
RUN git clone https://github.com/FreePBX/framework.git /usr/src/freepbx

# Start Asterisk and install FreePBX
USER asterisk
RUN /usr/sbin/asterisk -f & sleep 5
USER root
RUN cd /usr/src/freepbx && ./install -n

# Expose ports
EXPOSE 80 443 5060/udp 5160/udp 18000-18100/udp

# Startup script
CMD ["sh", "-c", "/usr/sbin/asterisk && apache2ctl -D FOREGROUND"]