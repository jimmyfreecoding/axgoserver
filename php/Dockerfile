FROM php:8.3-fpm-alpine

# 安装常用扩展和 unzip 工具
RUN apk add --no-cache unzip && \
    docker-php-ext-install pdo pdo_mysql mysqli

# 允许 PHP 处理 .do 后缀
RUN echo "security.limit_extensions = .php .do" >> /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

# 复制 www.zip 到临时目录
COPY src/ax-go-admin/dist/www.zip /tmp/www.zip

# 解压 www.zip 到 /var/www/html 并清理
RUN unzip /tmp/www.zip -d /var/www/html && \
    rm /tmp/www.zip

# 复制后端源码
COPY src /var/www/src
