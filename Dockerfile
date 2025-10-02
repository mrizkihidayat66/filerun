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
    rm -rf /var/lib/apt/lists/*

# Install Imagick extension
RUN \
    echo "**** install imagick ****" && \
    curl -o /tmp/imagick.tgz -L http://pecl.php.net/get/imagick-3.4.4.tgz && \
    tar xvzf /tmp/imagick.tgz -C /tmp && \
    cd /tmp/imagick-3.4.4 && \
    phpize && ./configure && make install && \
    echo "extension=imagick.so" >> /etc/php/7.4/cli/php.ini && \
    echo "" >> /etc/php/7.4/fpm/php.ini && \
    echo "extension=imagick.so" >> /etc/php/7.4/fpm/php.ini && \
    rm -rf /tmp/*

# Install IonCube
RUN \
    echo "**** install ioncube ****" && \
    curl -o /tmp/ioncube.tar.gz -L http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
    tar xvfz /tmp/ioncube.tar.gz -C /tmp && \
    cp "/tmp/ioncube/ioncube_loader_lin_7.4.so" /usr/lib/php/20190902/ && \
    echo "zend_extension=ioncube_loader_lin_7.4.so" >> /etc/php/7.4/fpm/conf.d/00_ioncube_loader_lin_7.4.ini && \
    rm -rf /tmp/*

# Copy FileRun (local zip instead of download)
COPY FileRun_20220519_PHP73-74.zip /tmp/filerun.zip
RUN \
    echo "**** install filerun ****" && \
    mkdir -p /var/www/html && \
    unzip /tmp/filerun.zip -d /var/www/html && \
    rm /tmp/filerun.zip

# Copy configs
COPY default /etc/nginx/sites-available/
COPY filerun-optimization.ini /etc/php/7.4/fpm/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Prepare volumes
RUN mkdir -p /config /user-files /config/keys && \
    rm -f /etc/nginx/sites-enabled/default.conf && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default.conf && \
    ln -sf /config/config.php /var/www/html/system/data/autoconfig.php && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /config/keys/cert.key -out /config/keys/cert.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com/emailAddress=email@example.com" && \
    chown -R www-data:www-data /var/www/html /config /user-files /config/keys && \
    chmod 644 /config/keys/cert.*

VOLUME ["/config", "/user-files"]

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
