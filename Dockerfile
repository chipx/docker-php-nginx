ARG ALPINE_VERSION=3.17
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Tim de Pater <code@trafex.nl>"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 8.1 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-fpm \
  php81-gd \
  php81-intl \
  php81-mbstring \
  php81-mysqli \
  php81-opcache \
  php81-openssl \
  php81-phar \
  php81-session \
  php81-xml \
  php81-xmlreader \
  supervisor

# Configure nginx - http
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/nginx/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/php/fpm-pool.conf /etc/php81/php-fpm.d/www.conf
COPY config/php/php.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisor/supervisord.conf /etc/supervisord.conf
COPY config/supervisor/conf.d /etc/supervisor.d/

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:88/fpm-ping
