FROM alpine:latest

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Install dependencies
RUN apk add --update --no-cache \
    curl \
    php84 \
    php84-fpm \
    php84-common \
    php84-curl \
    php84-gd \
    php84-exif \
    php84-pecl-imagick \
    php84-mbstring \
    php84-pdo_mysql \
    php84-mysqli \
    php84-session \
    php84-opcache \
    php84-xml \
    php84-xmlreader \
    php84-openssl \
    php84-bcmath \
    php84-ctype \
    php84-simplexml \
    php84-iconv \
    php84-dom \
    php84-json \
    php84-phar \
    php84-xmlwriter \
    php84-fileinfo \
    php84-tokenizer \
    php84-zip \
    php84-pcntl \
    php84-posix

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
