FROM alpine:latest

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	curl \
	php82 \
	php82-fpm \
	php82-common \
	php82-curl \
	php82-gd \
	php82-exif \
	php82-pecl-imagick \
	php82-mbstring \
	php82-pdo_mysql \
	php82-mysqli \
	php82-session \
	php82-opcache \
	php82-xml \
	php82-xmlreader \
	php82-openssl \
	php82-bcmath \
	php82-ctype \
	php82-simplexml \
	php82-iconv \
	php82-dom \
	php82-json \
	php82-phar \
	php82-xmlwriter \
	php82-fileinfo \
	php82-tokenizer \
	php82-zip

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
