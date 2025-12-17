FROM alpine:latest

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Install dependencies
RUN apk add --update --no-cache \
    curl \
    php83 \
    php83-fpm \
    php83-common \
    php83-curl \
    php83-gd \
    php83-exif \
    php83-pecl-imagick \
    php83-mbstring \
    php83-pdo_mysql \
    php83-mysqli \
    php83-session \
    php83-opcache \
    php83-xml \
    php83-xmlreader \
    php83-openssl \
    php83-bcmath \
    php83-ctype \
    php83-simplexml \
    php83-iconv \
    php83-dom \
    php83-json \
    php83-phar \
    php83-xmlwriter \
    php83-fileinfo \
    php83-tokenizer \
    php83-zip \
    php83-pcntl \
    php83-posix

# Create symlink for generic php command
RUN ln -s /usr/bin/php83 /usr/bin/php

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
