FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /usr/src

RUN apt-get update && apt-get install -y \
  wget curl gnupg2 ca-certificates lsb-release net-tools \
  cron ntpdate iputils-ping nano sudo git unzip sox \
  build-essential subversion libncurses5-dev uuid-dev \
  libxml2-dev libsqlite3-dev libjansson-dev libssl-dev \
  libedit-dev pkg-config python3 php php-cli php-mysql \
  php-curl php-mbstring php-gd php-xml php-bcmath php-zip \
  apache2 php-pear php-dev nodejs npm mariadb-client && \
  apt-get clean

# Install Asterisk 21
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

# Install FreePBX
RUN cd /usr/src && \
  git clone https://github.com/FreePBX/framework.git freepbx && \
  cd freepbx && \
  ./start_asterisk start && \
  ./install -n

EXPOSE 80 443 5060/udp 5160/udp 18000-18100/udp

CMD ["sh", "-c", "service mysql start && apache2ctl -D FOREGROUND"]
