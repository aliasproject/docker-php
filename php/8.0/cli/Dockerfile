FROM alpine:3.14.0

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	curl \
	unzip \
	php8-cli \
	php8-common \
	php8-curl \
	php8-gd \
	php8-mbstring \
	php8-pdo_mysql \
	php8-mysqli \
	php8-tokenizer \
	php8-xml \
	php8-zip && \
	ln -s /usr/bin/php8 /usr/bin/php

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
