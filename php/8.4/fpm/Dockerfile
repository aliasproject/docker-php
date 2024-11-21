FROM ghcr.io/aliasproject/docker-baseimage-s6-overlay-alpine:latest

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
    php84 \
    php84-fpm \
    php84-common \
    php84-curl \
    php84-gd \
    php84-exif \
    php84-pecl-imagick \
    php84-mbstring \
    php84-pdo_mysql \
    php84-mysqli \
    php84-session \
    php84-opcache \
    php84-xml \
    php84-xmlreader \
    php84-openssl \
    php84-bcmath \
    php84-ctype \
    php84-simplexml \
    php84-iconv \
    php84-dom \
    php84-json \
    php84-phar \
    php84-xmlwriter \
    php84-fileinfo \
    php84-tokenizer \
    php84-zip && \
    sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php84/php-fpm.d/www.conf && \
    mkdir /app && \
    addgroup -S alias && \
    adduser -S alias -G alias && \
    chown -R alias.alias /app

# Copy over S6 configurations
COPY etc/s6-rc.d/ /etc/s6-overlay/s6-rc.d

# Configure PHP
COPY etc/php/php-fpm.d/y-override-php-defaults.conf /etc/php84/php-fpm.d/y-override-php-defaults.conf

# Set the default work directory to our web user
WORKDIR /app

# Run S6
ENTRYPOINT ["/init"]