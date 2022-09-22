FROM alpine:3.16.0

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	curl \
	php81 \
	php81-fpm \
	php81-common \
	php81-curl \
	php81-gd \
	php81-exif \
	php81-pecl-imagick \
	php81-mbstring \
	php81-pdo_mysql \
	php81-mysqli \
	php81-session \
	php81-opcache \
	php81-xml \
	php81-xmlreader \
	php81-openssl \
	php81-bcmath \
	php81-ctype \
	php81-simplexml \
	php81-iconv \
	php81-dom \
	php81-json \
	php81-phar \
	php81-xmlwriter \
	php81-fileinfo \
	php81-tokenizer \
	php81-zip && \
	ln -s /usr/bin/php81 /usr/bin/php

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
