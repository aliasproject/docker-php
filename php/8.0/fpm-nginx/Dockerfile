FROM aliasproject/php:8.0-fpm

LABEL maintainer="Michael Aguiar <mike@aliasproject.com>"

ENV HTTP2=true
ENV PORT=80

RUN apk add --update --no-cache nginx

# Copy over S6 configurations
COPY etc/services.d/ /etc/services.d/
COPY etc/cont-init.d/ /etc/cont-init.d/

# Configure NGINX
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/php_fastcgi.conf /etc/nginx/php_fastcgi.conf
COPY etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY etc/nginx/server-opts.d /etc/nginx/server-opts.d

# Configure PHP

# Set the default work directory to our web user
WORKDIR /app

# Configure S6 to drop priveleges
ENTRYPOINT ["/init"]
