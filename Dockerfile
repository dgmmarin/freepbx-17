FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies + supervisor + mysql client
RUN apt-get update && apt-get install -y \
    wget curl gnupg2 lsb-release apt-utils \
    apache2 \
    php php-cli php-common php-mysql php-curl php-intl php-mbstring php-xml php-zip \
    sox libncurses5 libjansson4 libssl3 libsqlite3-0 libcurl4 libiksemel3 libiksemel-utils \
    libxml2 libncurses-dev uuid-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev \
    build-essential git autoconf automake libtool pkg-config libncurses5-dev libxml2-dev \
    libsqlite3-dev libjansson-dev uuid-dev libssl-dev libcurl4-openssl-dev \
    supervisor default-mysql-client vim net-tools iproute2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create supervisor config directory
RUN mkdir -p /etc/supervisor/conf.d

# Download and build Asterisk 19
RUN cd /usr/src && \
    wget http://downloads.asterisk.org/pub/telephony/asterisk/19/asterisk-19.14.0.tar.gz && \
    tar xvfz asterisk-19.14.0.tar.gz && \
    rm asterisk-19.14.0.tar.gz && \
    cd asterisk-19.14.0 && \
    contrib/scripts/install_prereq install && \
    ./configure && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable format_mp3 menuselect.makeopts && \
    make && make install && make samples && make config && ldconfig


# Download FreePBX 17 source
RUN cd /usr/src && \
    wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz && \
    tar xfz freepbx-17.0-latest.tgz && \
    rm freepbx-17.0-latest.tgz

# Enable apache modules and SSL site
RUN a2enmod rewrite ssl headers && a2ensite default-ssl

# Copy supervisord config
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /usr/src/freepbx

# Expose HTTP, HTTPS, SIP, and RTP ports
EXPOSE 80 443 5060 5061 10000-20000/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
