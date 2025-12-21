FROM alpine:latest

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

# Install dependencies
RUN apk add --update --no-cache \
    curl \
    php85 \
    php85-fpm \
    php85-common \
    php85-curl \
    php85-gd \
    php85-exif \
    php85-pecl-imagick \
    php85-mbstring \
    php85-pdo_mysql \
    php85-mysqli \
    php85-session \
    php85-opcache \
    php85-xml \
    php85-xmlreader \
    php85-openssl \
    php85-bcmath \
    php85-ctype \
    php85-simplexml \
    php85-iconv \
    php85-dom \
    php85-json \
    php85-phar \
    php85-xmlwriter \
    php85-fileinfo \
    php85-tokenizer \
    php85-zip \
    php85-pcntl \
    php85-posix \
    php85-pecl-redis \
    php85-sodium

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
