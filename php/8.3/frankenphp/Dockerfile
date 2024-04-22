FROM dunglas/frankenphp:1.1.1-php8.3-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Copy php.ini and Install Extensions
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    install-php-extensions \
    pdo_mysql \
    gd \
    zip \
    xml \
    bcmath \
    opcache

CMD [ "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]