FROM php:8.3-fpm-alpine

# 安装常用扩展和 unzip 工具
RUN apk add --no-cache unzip && \
    docker-php-ext-install pdo pdo_mysql mysqli

# 允许 PHP 处理 .do 后缀
RUN echo "security.limit_extensions = .php .do" >> /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

# 复制 www.zip 到临时目录
COPY src/ax-go-admin/dist/www.zip /tmp/www.zip

# 1. 解压 www.zip
# 2. 将 ax-go-admin 子目录下的所有文件移动到 /var/www/html/
# 3. 强制删除（可能非空的）ax-go-admin 目录
RUN mkdir -p /var/www/html && \
    unzip /tmp/www.zip -d /var/www/html && \
    if [ -d "/var/www/html/ax-go-admin" ]; then \
        mv /var/www/html/ax-go-admin/* /var/www/html/ && \
        rm -rf /var/www/html/ax-go-admin; \
    fi && \
    rm /tmp/www.zip

# 复制后端源码
COPY src /var/www/src
