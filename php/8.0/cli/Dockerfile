FROM alpine:3.15.0

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --no-cache \
    curl \
    php8 \
    php8-bcmath \
    php8-common \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-exif \
    php8-fileinfo \
    php8-gd \
    php8-iconv \
    php8-mbstring \
    php8-mysqli \
    php8-opcache \
    php8-openssl \
    php8-pdo_mysql \
    php8-pecl-imagick \
    php8-phar \
    php8-session \
    php8-simplexml \
    php8-tokenizer \
    php8-xml \
    php8-xmlreader \
    php8-xmlwriter \
    php8-zip && \
    ln -s /usr/bin/php8 /usr/bin/php

WORKDIR /app

CMD ["php", "-a"]
