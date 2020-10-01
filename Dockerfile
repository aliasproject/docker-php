FROM php:7.4-fpm-alpine

ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10"

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libzip-dev \
&& docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
&& docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd  \
&& docker-php-ext-install pdo_mysql zip exif opcache \
&& apk del libzip-dev libpng-dev freetype-dev libjpeg-turbo-dev

# Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Opcache
COPY conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

CMD ["php-fpm"]
