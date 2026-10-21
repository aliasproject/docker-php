# Official image: it tracks php.net patch releases, where Alpine's stable
# branches can sit on one PHP patch release for months, and it is the same
# PHP build the frankenphp images use (php:*-zts-alpine under
# dunglas/frankenphp), so CLI and web containers run the same PHP.
FROM php:8.4-cli-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

ARG APP_UID=1000

# Same installer the frankenphp images ship, so derived images
# (Dockerfile.wordpress) install extensions with the same names and builds.
COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/

# Tier 1 only: the PHP runtime itself, plus pdo_mysql as the generic modern
# driver (mysqlnd is compiled in, so the shim is effectively free).
#
# Deliberately NOT here -- each picks a backend or wraps an external library,
# and belongs in a derived image: mysqli, redis, igbinary, gd, exif, imagick,
# soap, pgsql.
RUN apk add --no-cache tzdata && \
    install-php-extensions \
        bcmath \
        intl \
        pcntl \
        pdo_mysql \
        zip && \
    \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    # CLI tasks (search-replace, imports, exports) blow past the 128M default.
    # max_execution_time 0 = unlimited, which is the CLI SAPI norm.
    printf 'memory_limit = 512M\nmax_execution_time = 0\ndate.timezone = UTC\n' \
        > "$PHP_INI_DIR/conf.d/99-cli.ini" && \
    \
    # The Alpine-package images this replaced had PHP at /usr/bin/php and
    # /usr/bin/php84; keep both working for scripts that call them.
    ln -s /usr/local/bin/php /usr/bin/php && \
    ln -s /usr/local/bin/php /usr/bin/php84 && \
    \
    # The CGI and debugger SAPIs are ~20MB each and unused in a CLI image.
    rm /usr/local/bin/php-cgi /usr/local/bin/phpdbg && \
    \
    # Match the frankenphp images: unprivileged UID in group 0
    adduser -u ${APP_UID} -G root -s /sbin/nologin -D appuser && \
    mkdir -p /app && \
    chgrp -R 0 /app && \
    chmod -R g=u /app

WORKDIR /app

# Running unprivileged keeps file ownership consistent with the web containers.
USER ${APP_UID}:0

CMD ["php", "-a"]
