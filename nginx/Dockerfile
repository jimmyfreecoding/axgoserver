FROM nginx:stable-alpine

# 安装 unzip 工具
RUN apk add --no-cache unzip

# 注意：构建上下文应该是项目根目录
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# 复制 www.zip 到临时目录
COPY src/ax-go-admin/dist/www.zip /tmp/www.zip

# 解压 www.zip 到 /var/www/html 并清理
RUN unzip /tmp/www.zip -d /var/www/html && \
    rm /tmp/www.zip

# 复制后端源码
COPY src /var/www/src
