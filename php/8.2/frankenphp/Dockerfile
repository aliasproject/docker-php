ARG FRANKENPHP_VERSION=1.13.2
ARG PHP_VERSION=8.2
FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Runtime UID. Keep this DIFFERENT from the UID that owns the bind-mounted
# source on the host: if they match, PHP owns every file it serves and any
# code-execution bug becomes persistent code modification. Downstream images
# override with --build-arg APP_UID=... (see Dockerfile.wordpress).
ARG APP_UID=1000

ENV PHP_MEMORY_LIMIT=256M \
    PHP_MAX_EXECUTION_TIME=60 \
    PHP_UPLOAD_MAX_FILESIZE=32M \
    PHP_POST_MAX_SIZE=32M \
    PHP_MAX_INPUT_VARS=3000 \
    PHP_EXPOSE=Off \
    PHP_DISABLE_FUNCTIONS= \
    PHP_OPEN_BASEDIR= \
    PHP_REALPATH_CACHE_SIZE=4096K \
    PHP_REALPATH_CACHE_TTL=600 \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_MEMORY=128 \
    PHP_OPCACHE_INTERNED_STRINGS=16 \
    PHP_OPCACHE_MAX_FILES=10000 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_OPCACHE_REVALIDATE_FREQ=2 \
    PHP_OPCACHE_JIT=off \
    PHP_OPCACHE_JIT_BUFFER=0 \
    PHP_NO_EXEC_PATHS= \
    PHP_NO_EXEC_HIDE_EXTENSIONS="php phtml phar phps php3 php4 php5 php6 php7 php8 inc" \
    PHP_DENY_PATHS= \
    PHP_DENY_EXTENSIONS= \
    PHP_DENY_STORAGE_PHP=on \
    CADDY_ACCESS_LOG=on \
    CADDY_ACCESS_LOG_PATH=/data/caddy/access.log \
    MSMTP_RELAY_SERVER_HOST=mailhog \
    MSMTP_RELAY_SERVER_PORT=1025 \
    MSMTP_RELAY_SERVER_TLS=off \
    MSMTP_RELAY_SERVER_FROM=no-reply@localhost

# Fail the build if the PHP the server embeds doesn't match the image's
# PHP_VERSION. `frankenphp php-cli` runs the libphp.so the server embeds;
# `php` is its own binary.
RUN for bin in "frankenphp php-cli" php; do \
        v="$($bin -r 'echo PHP_VERSION;')"; \
        test "$v" = "$PHP_VERSION" || { echo "ERROR: $bin reports $v, expected $PHP_VERSION" >&2; exit 1; }; \
    done && \
    \
    sed -i 's/{$SERVER_NAME:localhost}/:{$PORT:80}/' /etc/caddy/Caddyfile && \
    sed -i '/CADDY_GLOBAL_OPTIONS/a http_port {$PORT:80}' /etc/caddy/Caddyfile && \
    sed -i '/http_port/a servers :{$PORT:80} {\nprotocols h1 h2 h2c h3\n}' /etc/caddy/Caddyfile && \
    \
    # Each sed above is a silent no-op if the upstream Caddyfile format ever
    # changes shape on a FRANKENPHP_VERSION bump -- the build would otherwise
    # succeed and ship an image that falls back to Caddy's automatic-HTTPS
    # behavior for "localhost" and never binds plain HTTP on $PORT. Fail
    # loudly instead of shipping that silently.
    grep -qxF ':{$PORT:80} {' /etc/caddy/Caddyfile || \
        (echo "ERROR: failed to rewrite Caddyfile site address to :{\$PORT:80}" >&2 && exit 1) && \
    grep -qxF 'http_port {$PORT:80}' /etc/caddy/Caddyfile || \
        (echo "ERROR: failed to insert http_port {\$PORT:80} into Caddyfile" >&2 && exit 1) && \
    grep -qxF 'servers :{$PORT:80} {' /etc/caddy/Caddyfile || \
        (echo "ERROR: failed to insert servers block into Caddyfile" >&2 && exit 1) && \
    \
    # Splice in the runtime-generated hardening snippet ahead of php_server.
    # docker-configure regenerates it on every boot from PHP_NO_EXEC_PATHS /
    # PHP_DENY_PATHS / CADDY_ACCESS_LOG, which keeps this image framework-
    # agnostic: the mechanism lives here, the policy lives downstream.
    sed -i '/^\tphp_server/i \\timport /config/caddy/site.d/*.caddyfile\n' /etc/caddy/Caddyfile && \
    \
    grep -q '^\timport /config/caddy/site.d/\*.caddyfile$' /etc/caddy/Caddyfile || \
        (echo "ERROR: failed to splice hardening import into Caddyfile" >&2 && exit 1) && \
    \
    apk add --no-cache ca-certificates libcap msmtp tzdata && \
    cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    # Wire up msmtp as the PHP mailer (path is fixed at build time)
    sed -i -r 's|;sendmail_path =.*|sendmail_path = "/usr/bin/msmtp -t"|g' $PHP_INI_DIR/php.ini && \
    # Tier 1: the PHP runtime itself, plus pdo_mysql as the generic modern
    # driver (mysqlnd is already compiled in, so the shim costs ~0 bytes).
    # Anything that picks a backend or wraps an external library -- mysqli,
    # redis, gd, exif, imagick, soap, igbinary -- belongs in a derived image.
    install-php-extensions \
        pdo_mysql \
        zip \
        intl \
        bcmath \
        pcntl \
        posix && \
    \
    # 1. Create unprivileged user assigned to Group 0 (root group)
    adduser -u ${APP_UID} -G root -s /sbin/nologin -D appuser && \
    \
    # Grant frankenphp the capability to bind to ports 80/443 without root
    setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp && \
    \
    # 2. Provision runtime directories and assign permissions to Group 0 (GID 0)
    mkdir -p /config/caddy/site.d /data/caddy /app $PHP_INI_DIR/conf.d && \
    touch /etc/msmtprc && \
    \
    # Assign group ownership to Group 0 (root group)
    chgrp -R 0 \
        /config/caddy \
        /data/caddy \
        /app \
        $PHP_INI_DIR/conf.d \
        /etc/msmtprc && \
    \
    # Mirror owner read/write/execute permissions directly to the group.
    # Scoped to conf.d rather than all of $PHP_INI_DIR so the runtime user
    # cannot rewrite php.ini itself.
    chmod -R g=u \
        /config/caddy \
        /data/caddy \
        /app \
        $PHP_INI_DIR/conf.d && \
    chmod 660 /etc/msmtprc

# COPY after RUN so script edits don't bust the extension-install layer
COPY --chmod=755 docker-configure /usr/local/bin/docker-configure

# Composer binary pulled directly from the official image — no network fetch
# at build time (same as Dockerfile.dev). Not a runtime extension: it never
# loads into a FrankenPHP worker or touches a request, so it adds no
# request-time attack surface — it's a build-time CLI tool nearly every
# composer-managed PHP app (Laravel, Symfony, etc.) needs available when
# source is deployed without its own Dockerfile.
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

EXPOSE 80 443 443/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -qO /dev/null http://127.0.0.1:2019/config/ || exit 1

WORKDIR /app

# 3. Run default execution as APP_UID and GID 0
USER ${APP_UID}:0

ENTRYPOINT ["docker-configure"]
CMD ["--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
