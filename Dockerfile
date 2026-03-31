FROM php:8.3-fpm-alpine

RUN apk add --no-cache nginx unzip && \
    docker-php-ext-install pdo pdo_mysql mysqli pcntl

RUN mkdir -p /run/nginx /var/www/html /var/www/src /etc/nginx/conf.d && \
    { \
        echo 'clear_env = no'; \
        echo 'security.limit_extensions = .php .do'; \
        echo 'pm.max_children = 50'; \
        echo 'pm.start_servers = 5'; \
        echo 'pm.min_spare_servers = 5'; \
        echo 'pm.max_spare_servers = 35'; \
    } >> /usr/local/etc/php-fpm.d/www.conf

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY src/ax-go-admin/dist/www.zip /tmp/www.zip

RUN unzip /tmp/www.zip -d /var/www/html && \
    if [ -d "/var/www/html/ax-go-admin" ]; then \
        mv /var/www/html/ax-go-admin/* /var/www/html/ && \
        rm -rf /var/www/html/ax-go-admin; \
    fi && \
    chmod -R 755 /var/www/html && \
    rm /tmp/www.zip

COPY src /var/www/src
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
