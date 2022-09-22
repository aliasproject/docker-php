FROM ghcr.io/aliasproject/docker-baseimage-s6-overlay-alpine:3.16

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
RUN apk add --update --no-cache \
    curl \
    php81 \
    php81-fpm \
    php81-common \
    php81-curl \
    php81-gd \
    php81-exif \
    php81-pecl-imagick \
    php81-mbstring \
    php81-pdo_mysql \
    php81-mysqli \
    php81-session \
    php81-opcache \
    php81-xml \
    php81-xmlreader \
    php81-openssl \
    php81-bcmath \
    php81-ctype \
    php81-simplexml \
    php81-iconv \
    php81-dom \
    php81-json \
    php81-phar \
    php81-xmlwriter \
    php81-fileinfo \
    php81-tokenizer \
    php81-zip && \
    ln -s /usr/bin/php81 /usr/bin/php && \
    sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php81/php-fpm.d/www.conf && \
    mkdir /app && \
    addgroup -S alias && \
    adduser -S alias -G alias && \
    chown -R alias.alias /app

# Copy over S6 configurations
COPY etc/s6-rc.d/ /etc/s6-overlay/s6-rc.d

# Configure PHP
COPY etc/php/php-fpm.d/y-override-php-defaults.conf /etc/php81/php-fpm.d/y-override-php-defaults.conf

# Set the default work directory to our web user
WORKDIR /app

# Run S6
ENTRYPOINT ["/init"]