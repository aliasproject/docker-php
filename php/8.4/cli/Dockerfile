FROM alpine:3.21

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --no-cache \
    curl \
    php84 \
    php84-bcmath \
    php84-common \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-exif \
    php84-fileinfo \
    php84-gd \
    php84-iconv \
    php84-mbstring \
    php84-mysqli \
    php84-opcache \
    php84-openssl \
    php84-pcntl \
    php84-pdo_mysql \
    php84-pecl-imagick \
    php84-pecl-redis \
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
    ln -s /usr/bin/php84 /usr/bin/php

WORKDIR /app

CMD ["php", "-a"]
