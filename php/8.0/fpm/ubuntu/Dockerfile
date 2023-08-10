FROM ghcr.io/aliasproject/docker-baseimage-s6-overlay-ubuntu:20.04

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Set default PHP environment variables
ENV PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=On \
    PHP_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    PHP_POOL_NAME="www" \
    PHP_PM_CONTROL="dynamic" \
    PHP_PM_MAX_CHILDREN="20" \
    PHP_PM_START_SERVERS="2" \
    PHP_PM_MIN_SPARE_SERVERS="1" \
    PHP_PM_MAX_SPARE_SERVERS="3"

# Install packages
RUN export DEBIAN_FRONTEND=noninteractive && apt-get -y install software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get -y install \
    curl \
    php8.0 \
    php8.0-fpm \
    php8.0-common \
    php8.0-curl \
    php8.0-gd \
    php8.0-exif \
    php8.0-mbstring \
    php8.0-mysql \
    php8.0-mysqli \
    php8.0-opcache \
    php8.0-xml \
    php8.0-xmlreader \
    php8.0-bcmath \
    php8.0-ctype \
    php8.0-simplexml \
    php8.0-iconv \
    php8.0-dom \
    php8.0-phar \
    php8.0-xmlwriter \
    php8.0-fileinfo \
    php8.0-tokenizer \
    php8.0-zip && \
    sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php/8.0/fpm/pool.d/www.conf && \
    mkdir /app && \
    groupadd alias && \
    useradd alias -g alias && \
    chown -R alias.alias /app

# Copy over S6 configurations
COPY etc/s6-rc.d/ /etc/s6-overlay/s6-rc.d

# Configure PHP
COPY etc/php/php-fpm.d/y-override-php-defaults.conf /etc/php/8.0/fpm/pool.d/y-override-php-defaults.conf

# Set the default work directory to our web user
WORKDIR /app

# Run S6
ENTRYPOINT ["/init"]