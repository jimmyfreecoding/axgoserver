FROM php:8.3-fpm-alpine

# 安装常用扩展
RUN docker-php-ext-install pdo pdo_mysql mysqli

# 允许 PHP 处理 .do 后缀
RUN echo "security.limit_extensions = .php .do" >> /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html
