FROM nginx:stable-alpine

# 安装 unzip 工具
RUN apk add --no-cache unzip

# 注意：构建上下文应该是项目根目录
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# 复制 www.zip 到临时目录
COPY src/ax-go-admin/dist/www.zip /tmp/www.zip

# 1. 解压 www.zip
# 2. 将 ax-go-admin 子目录下的所有文件移动到 /var/www/html/
# 3. 删除空的 ax-go-admin 目录
# 4. 设置权限
RUN mkdir -p /var/www/html && \
    unzip /tmp/www.zip -d /var/www/html && \
    if [ -d "/var/www/html/ax-go-admin" ]; then \
        mv /var/www/html/ax-go-admin/* /var/www/html/ && \
        rmdir /var/www/html/ax-go-admin; \
    fi && \
    chmod -R 755 /var/www/html && \
    rm /tmp/www.zip

# 复制后端源码
COPY src /var/www/src
