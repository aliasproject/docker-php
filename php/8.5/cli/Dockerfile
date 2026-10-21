# Official image: it tracks php.net patch releases, where Alpine's stable
# branches can sit on one PHP patch release for months. The frankenphp images
# are built on the same images (the ZTS variant, php:*-zts-alpine), so CLI and
# web containers get PHP from the same source and build recipe.
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
    # The socket paths are the ones the Alpine-package image this replaced
    # used; without them mysqlnd falls back to /tmp/mysql.sock.
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    printf 'max_execution_time = 0\ndate.timezone = UTC\nmysqli.default_socket = /run/mysqld/mysqld.sock\npdo_mysql.default_socket = /run/mysqld/mysqld.sock\n' \
        > "$PHP_INI_DIR/conf.d/99-cli.ini" && \
    \
    # The Alpine-package image this replaced had PHP at /usr/bin/php and
    # /usr/bin/php85; keep both working for scripts that call them.
    ln -s /usr/local/bin/php /usr/bin/php && \
    ln -s /usr/local/bin/php /usr/bin/php85

WORKDIR /app

CMD ["php", "-a"]
