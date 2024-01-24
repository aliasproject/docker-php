FROM dunglas/frankenphp:sha-d4c313f-php8.3.1-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Copy php.ini and Install Extensions
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && install-php-extensions \
    pdo_mysql \
    gd \
    zip \
    xml \
    bcmath \
    opcache