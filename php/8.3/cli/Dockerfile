FROM alpine:3.21

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --no-cache \
    curl \
    php83 \
    php83-bcmath \
    php83-common \
    php83-ctype \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-gd \
    php83-iconv \
    php83-mbstring \
    php83-mysqli \
    php83-opcache \
    php83-openssl \
    php83-pcntl \
    php83-pdo_mysql \
    php83-pecl-imagick \
    php83-pecl-redis \
    php83-phar \
    php83-posix \
    php83-session \
    php83-simplexml \
    php83-sodium \
    php83-tokenizer \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-zip && \
    ln -s /usr/bin/php83 /usr/bin/php

WORKDIR /app

CMD ["php", "-a"]
