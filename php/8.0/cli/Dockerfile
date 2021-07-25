FROM ghcr.io/aliasproject/docker-baseimage-s6-overlay-alpine:3.14.0
LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

RUN apk add --update --no-cache \
	ca-certificates \
	curl \
	unzip \
	php8-cli \
	php8-common \
	php8-curl \
	php8-gd \
	php8-mbstring \
	php8-xml \
	php8-zip && \
	ln -s /usr/bin/php8 /usr/bin/php
	
	
# Copy over S6 configurations
COPY etc/cont-init.d/ /etc/cont-init.d/

# Set the default work directory to our web user
WORKDIR /var/www/html

# Configure S6 to drop priveleges
ENTRYPOINT ["/init"]

# Run PHP
CMD ["php", "-a"]
