FROM alpine:3.15.0

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	curl \
	unzip \
	php7 \
	php7-common \
	php7-curl \
	php7-gd \
	php7-json \
	php7-mysqli \
	php7-mbstring \
	php7-opcache \
	php7-xml \
	php7-tokenizer \
	php7-zip

# Set default work directory
WORKDIR /app

# Run PHP
CMD ["php", "-a"]
