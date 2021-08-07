FROM ghcr.io/aliasproject/docker-baseimage-s6-overlay-alpine:3.14.0

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
    php7 \
    php7-fpm \
    php7-common \
    php7-curl \
    php7-gd \
    php7-mbstring \
    php7-pdo_mysql \
    php7-mysqli \ 
    php7-opcache \
    php7-session \
    php7-simplexml \
    php7-iconv \
    php7-dom \
    php7-xmlwriter \
    php7-fileinfo \
    php7-xml \
    php7-json \
    php7-tokenizer \
    php7-zip && \
    sed -i -e 's/\[www\]/\[$\{PHP_POOL_NAME\}]/g' /etc/php7/php-fpm.d/www.conf && \
    mkdir /app && \
    chown -R nobody.nobody /app

# Copy over S6 configurations
COPY etc/services.d/ /etc/services.d/
COPY etc/cont-init.d/ /etc/cont-init.d/

# Configure PHP
COPY etc/php/php-fpm.d/y-override-php-defaults.conf /etc/php7/php-fpm.d/y-override-php-defaults.conf

# Set the default work directory to our web user
WORKDIR /app

# Run S6
ENTRYPOINT ["/init"]
