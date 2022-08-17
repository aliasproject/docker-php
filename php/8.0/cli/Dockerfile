FROM alpine:3.15.0

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	curl \
	php8 \
	php8-fpm \
	php8-common \
	php8-curl \
	php8-gd \
	php8-exif \
	php8-pecl-imagick \
	php8-mbstring \
	php8-pdo_mysql \
	php8-mysqli \
	php8-session \
	php8-opcache \
	php8-xml \
	php8-xmlreader \
	php8-openssl \
	php8-bcmath \
	php8-ctype \
	php8-simplexml \
	php8-iconv \
	php8-dom \
	php8-json \
	php8-phar \
	php8-xmlwriter \
	php8-fileinfo \
	php8-tokenizer \
	php8-zip && \
	ln -s /usr/bin/php8 /usr/bin/php

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
