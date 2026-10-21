# Official image: it tracks php.net patch releases, where Alpine's stable
# branches can sit on one PHP patch release for months, and it is the same
# PHP build the frankenphp images use (php:*-zts-alpine under
# dunglas/frankenphp), so CLI and web containers run the same PHP.
FROM php:8.5-cli-alpine

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Same installer the frankenphp images ship.
COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/

# Same extensions as the Alpine-package image this replaced. igbinary and
# msgpack are installed alongside redis so it's built with both serializers.
RUN apk add --no-cache tzdata && \
    install-php-extensions \
        bcmath \
        exif \
        gd \
        igbinary \
        imagick \
        msgpack \
        mysqli \
        pcntl \
        pdo_mysql \
        redis \
        sockets \
        zip && \
    \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    printf 'max_execution_time = 0\ndate.timezone = UTC\n' \
        > "$PHP_INI_DIR/conf.d/99-cli.ini" && \
    \
    # The Alpine-package image this replaced had PHP at /usr/bin/php and
    # /usr/bin/php85; keep both working for scripts that call them.
    ln -s /usr/local/bin/php /usr/bin/php && \
    ln -s /usr/local/bin/php /usr/bin/php85 && \
    \
    # The CGI and debugger SAPIs are ~20MB each and unused in a CLI image.
    rm /usr/local/bin/php-cgi /usr/local/bin/phpdbg

WORKDIR /app

CMD ["php", "-a"]
