ARG FRANKENPHP_VERSION=1.12.4
ARG PHP_VERSION=8.4
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

ENV PHP_MEMORY_LIMIT=256M \
    PHP_MAX_EXECUTION_TIME=60 \
    MSMTP_RELAY_SERVER_HOST=mailhog \
    MSMTP_RELAY_SERVER_PORT=1025 \
    MSMTP_RELAY_SERVER_TLS=off \
    MSMTP_RELAY_SERVER_FROM=no-reply@localhost

RUN apk add --no-cache libcap msmtp && \
    cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    # Wire up msmtp as the PHP mailer (path is fixed at build time)
    sed -i -r 's|;sendmail_path =.*|sendmail_path = "/usr/bin/msmtp -t"|g' $PHP_INI_DIR/php.ini && \
    install-php-extensions \
        pdo_mysql \
        mysqli \
        redis \
        gd \
        zip \
        intl \
        bcmath \
        pcntl \
        posix \
        exif && \
    \
    # Create unprivileged user and group
    addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -s /sbin/nologin -D appuser && \
    \
    # Grant frankenphp the capability to bind to ports 80/443 without root
    setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp && \
    \
    # Provision runtime directories and hand ownership to the app user
    mkdir -p /config/caddy /data/caddy /var/www/html && \
    touch /etc/msmtprc && \
    chown -R appuser:appgroup \
        /config/caddy \
        /data/caddy \
        /var/www/html \
        $PHP_INI_DIR \
        /etc/msmtprc

# COPY after RUN so script edits don't bust the extension-install layer
COPY --chmod=755 docker-configure /usr/local/bin/docker-configure

EXPOSE 80 443 443/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -qO /dev/null http://localhost:2019/config/ || exit 1

WORKDIR /var/www/html

USER appuser:appgroup

ENTRYPOINT ["docker-configure"]
CMD ["--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
