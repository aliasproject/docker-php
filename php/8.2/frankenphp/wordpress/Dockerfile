FROM dunglas/frankenphp:sha-7454826-php8.2-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Copy php.ini and Install Extensions
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    install-php-extensions \
    json \
    mysqli \
    curl \
    dom \
    exif \
    fileinfo \
    hash \
    igbinary \
    imagick \
    intl \
    mbstring \
    openssl \
    pcre \
    xml \
    zip