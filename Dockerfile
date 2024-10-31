# Use the base image
FROM gaibz/ubuntu20-php7.4-nginx:latest

# Set label
LABEL maintainer="mrizkihidayat66"

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN \
    echo "**** install build packages ****" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        build-essential && \
    \
    echo "**** install runtime packages ****" && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        pkg-config \
        libmagickwand-dev \
        mariadb-client \
        php-dev \
        php7.4 \
        php7.4-common \
        php7.4-curl \
        php7.4-gd \
        php7.4-json \
        php7.4-mbstring \
        php7.4-opcache \
        php7.4-mysql \
        php7.4-xml \
        php7.4-zip && \
    \
    echo "**** install imagick ****" && \
    curl -o /tmp/imagick-3.4.4.tgz -L http://pecl.php.net/get/imagick-3.4.4.tgz && \
    tar xvzf /tmp/imagick-3.4.4.tgz -C /tmp && \
    cd /tmp/imagick-3.4.4 && \
    phpize && \
    ./configure && \
    make install && \
    echo "extension=imagick.so" >> /etc/php/7.4/cli/php.ini && \
    echo "" >> /etc/php/7.4/fpm/php.ini && \
    echo "extension=imagick.so" >> /etc/php/7.4/fpm/php.ini && \
    cd / && \
    \
    echo "**** install ioncube ****" && \
    curl -o /tmp/ioncube_loaders_lin_x86-64.tar.gz -L http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xvfz /tmp/ioncube_loaders_lin_x86-64.tar.gz -C /tmp && \
    cp "/tmp/ioncube/ioncube_loader_lin_7.4.so" /usr/lib/php/20190902/ && \
    echo "zend_extension=ioncube_loader_lin_7.4.so" >> /etc/php/7.4/fpm/conf.d/00_ioncube_loader_lin_7.4.ini && \
    \
    echo "**** install filerun ****" && \
    mkdir -p /var/www/html && \
    curl -o /tmp/filerun.zip -L http://tiny.cc/sn7qzz && \
    unzip /tmp/filerun.zip -d /var/www/html && \
    \
    echo "**** cleanup ****" && \
    apt-get purge -y --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /root/.cache /tmp/*

# Ports and volumes
VOLUME /html
VOLUME /config
VOLUME /user-files

# Copy local files
COPY default /etc/nginx/sites-available/
COPY filerun-optimization.ini /etc/php/7.4/fpm/conf.d/

RUN \
    mkdir -p /html \
        /config \
        /user-files \
        /config/keys && \
    rm -f /etc/nginx/sites-enabled/default.conf && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default.conf && \
    ln -s /config/config.php /var/www/html/system/data/autoconfig.php && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /config/keys/cert.key -out /config/keys/cert.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com/emailAddress=email@example.com" && \
    chown -R www-data:www-data \
        /var/www/html \
        /html \
        /config \
        /user-files \
        /config/keys/cert.crt \
        /config/keys/cert.key && \
    chmod 644 /config/keys/cert.crt \
        /config/keys/cert.key
