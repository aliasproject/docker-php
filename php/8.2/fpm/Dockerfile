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
    php82 \
    php82-fpm \
    php82-common \
    php82-curl \
    php82-gd \
    php82-exif \
    php82-pecl-imagick \
    php82-mbstring \
    php82-pdo_mysql \
    php82-mysqli \
    php82-session \
    php82-opcache \
    php82-xml \
    php82-xmlreader \
    php82-openssl \
    php82-bcmath \
    php82-ctype \
    php82-simplexml \
    php82-iconv \
    php82-dom \
    php82-json \
    php82-phar \
    php82-xmlwriter \
    php82-fileinfo \
    php82-tokenizer \
    php82-zip && \
    sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php82/php-fpm.d/www.conf && \
    mkdir /app && \
    addgroup -S alias && \
    adduser -S alias -G alias && \
    chown -R alias.alias /app

# Copy over S6 configurations
COPY etc/s6-rc.d/ /etc/s6-overlay/s6-rc.d

# Configure PHP
COPY etc/php/php-fpm.d/y-override-php-defaults.conf /etc/php82/php-fpm.d/y-override-php-defaults.conf

# Set the default work directory to our web user
WORKDIR /app

# Run S6
ENTRYPOINT ["/init"]