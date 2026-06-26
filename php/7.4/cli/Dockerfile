FROM alpine:3.15.0

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --no-cache \
    curl \
    php7 \
    php7-bcmath \
    php7-common \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-exif \
    php7-fileinfo \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-mysqli \
    php7-opcache \
    php7-openssl \
    php7-pdo_mysql \
    php7-pecl-imagick \
    php7-phar \
    php7-session \
    php7-simplexml \
    php7-tokenizer \
    php7-xml \
    php7-xmlreader \
    php7-xmlwriter \
    php7-zip

WORKDIR /app

CMD ["php", "-a"]
