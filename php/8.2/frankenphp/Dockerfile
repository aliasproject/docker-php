FROM dunglas/frankenphp:1.7-php8.2-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

ENV MSMTP_RELAY_SERVER_HOST= \
    MSMTP_RELAY_SERVER_PORT= \
    MSMTP_RELAY_SERVER_AUTH= \
    MSMTP_RELAY_SERVER_USER= \
    MSMTP_RELAY_SERVER_PASSWORD= \
    MSMTP_RELAY_SERVER_FROM=

COPY /etc/msmtprc /etc/msmtprc
COPY docker-configure /usr/local/bin/docker-configure

# Copy php.ini and Install Extensions
RUN chmod +x /usr/local/bin/docker-configure && \
    apk add --update --no-cache msmtp && \
    cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    install-php-extensions \
    pdo_mysql \
    pdo \
    fileinfo \
    tokenizer \
    dom \
    session \
    gd \
    zip \
    xml \
    simplexml \
    intl \
    bcmath \
    opcache

ENTRYPOINT ["docker-configure"]
CMD [ "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
