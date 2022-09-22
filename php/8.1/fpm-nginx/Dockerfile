FROM ghcr.io/aliasproject/php:8.1-fpm

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

ENV HTTP2=true \
	PORT=80 \
	MSMTP_RELAY_SERVER_HOST= \
	MSMTP_RELAY_SERVER_PORT= \
	MSMTP_RELAY_SERVER_AUTH= \
	MSMTP_RELAY_SERVER_USER= \
	MSMTP_RELAY_SERVER_PASSWORD= \
	MSMTP_RELAY_SERVER_FROM= \
	PHP_POOL_NAME="www" \
	PHP_PM_CONTROL="ondemand" \
	PHP_PM_MAX_CHILDREN="20" \
	PHP_PM_START_SERVERS="2" \
	PHP_PM_MIN_SPARE_SERVERS="1" \
	PHP_PM_MAX_SPARE_SERVERS="3"

# Copy over S6 configurations
COPY etc/s6-rc.d/ /etc/s6-overlay/s6-rc.d
COPY etc/scripts /etc/s6-overlay/scripts

RUN apk add --update --no-cache nginx msmtp && \
	mkdir /var/run/php && \
	chmod u+x -R /etc/s6-overlay/scripts && \
	chown -R alias.alias /var/lib/nginx && \
	chown -R alias.alias /var/log/nginx

# Configure NGINX
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/php_fastcgi.conf /etc/nginx/php_fastcgi.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY etc/nginx/server-opts.d /etc/nginx/server-opts.d

# Configure MSMTP
COPY etc/msmtprc /etc/msmtprc

# Configure PHP
COPY etc/php/php-fpm.d/z-fpm-with-overrides.conf /etc/php81/php-fpm.d/z-fpm-with-overrides.conf

# Run S6
ENTRYPOINT ["/init"]
