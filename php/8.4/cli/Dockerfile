# Alpine 3.22 matches the OS of the frankenphp base image (3.22.2), keeping the
# CLI and web PHP builds on the same release line.
FROM alpine:3.22

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

ARG APP_UID=1000

# Tier 1 only: the PHP runtime itself, plus pdo_mysql as the generic modern
# driver (mysqlnd is compiled in, so the shim is effectively free).
#
# Deliberately NOT here -- each picks a backend or wraps an external library,
# and belongs in a derived image: mysqli, redis, igbinary, gd, exif, imagick,
# soap, pgsql.
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tzdata \
    php84 \
    php84-bcmath \
    php84-common \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-fileinfo \
    php84-iconv \
    php84-intl \
    php84-mbstring \
    php84-opcache \
    php84-openssl \
    php84-pcntl \
    php84-pdo_mysql \
    php84-phar \
    php84-posix \
    php84-session \
    php84-simplexml \
    php84-sodium \
    php84-tokenizer \
    php84-xml \
    php84-xmlreader \
    php84-xmlwriter \
    php84-zip && \
    ln -s /usr/bin/php84 /usr/bin/php && \
    \
    # CLI tasks (search-replace, imports, exports) blow past the 128M default.
    # max_execution_time 0 = unlimited, which is the CLI SAPI norm.
    printf 'memory_limit = 512M\nmax_execution_time = 0\n' \
        > /etc/php84/conf.d/99-cli.ini && \
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
