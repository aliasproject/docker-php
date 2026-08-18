FROM alpine:edge

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --no-cache \
    curl \
    php85 \
    php85-bcmath \
    php85-common \
    php85-ctype \
    php85-curl \
    php85-dom \
    php85-exif \
    php85-fileinfo \
    php85-gd \
    php85-iconv \
    php85-mbstring \
    php85-mysqli \
    php85-openssl \
    php85-pcntl \
    php85-pdo_mysql \
    php85-pecl-imagick \
    php85-pecl-redis \
    php85-phar \
    php85-posix \
    php85-session \
    php85-simplexml \
    php85-sodium \
    php85-tokenizer \
    php85-xml \
    php85-xmlreader \
    php85-xmlwriter \
    php85-zip

WORKDIR /app

CMD ["php", "-a"]
