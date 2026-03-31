在 Zeabur 中部署这个项目，当前采用的是单镜像方案：MySQL 和 EMQX 独立部署，前端静态资源、Nginx 和 PHP 后端合并到项目根目录的 `Dockerfile` 中一次部署完成。

以下是详细的部署步骤：

### 第一步：推送代码到 GitHub
确保你已经执行了推送命令，将代码同步到仓库：

```bash
git add .
git commit -m "准备 Zeabur 部署配置文件"
git push
```

### 第二步：在 Zeabur 中部署服务
在一个 Zeabur 项目内，手动添加以下 3 个服务：

#### 1. 部署 MySQL (数据库)
1. 点击 **"Deploy New Service"** -> **"Marketplace"**。
2. 搜索并选择 **"MySQL"**。
3. 在 MySQL 服务的 **"Variables"** 选项卡中，记录下生成的 `MYSQL_ROOT_PASSWORD` 等信息（或者手动设置它们）。

#### 2. 部署 EMQX (MQTT)
1. 点击 **"Deploy New Service"** -> **"Marketplace"**。
2. 搜索并选择 **"EMQX"**。

#### 3. 部署 Web 应用 (前端 + Nginx + PHP)
1. 点击 **"Deploy New Service"** -> **"GitHub"** -> 选择你的 `axgoserver` 仓库。
2. 进入该服务的 **"Settings"** -> **"Build"**：
   - **Root Directory** 保持为 `/`
   - **Dockerfile Path** 使用项目根目录的 `Dockerfile`
3. 在 **"Variables"** 中不要手动覆盖数据库自动注入变量，直接使用 Zeabur 关联 MySQL 后生成的：
   - `MYSQL_HOST`
   - `MYSQL_PORT`
   - `MYSQL_USERNAME`
   - `MYSQL_PASSWORD`
   - `MYSQL_DATABASE`
4. 如果需要 MQTT 连接，请确认：
   - `EMQX` 服务的内网主机名为 `emqx.zeabur.internal`
   - Dashboard 登录后已创建代码中使用的 MQTT 用户
5. 进入 **"Networking"**：
   - 点击 **"Generate Domain"** 或绑定你自己的域名

### 第三步：配置持久化存储 (Volume)
为了保证数据库和 EMQX 的数据在重启后不丢失，需要挂载卷：

1. 点击 **mysql** 服务 -> **"Storage"** -> **"Mount Volume"**：
   - 挂载路径填入：`/var/lib/mysql`
2. 点击 **emqx** 服务 -> **"Storage"** -> **"Mount Volume"**：
   - 挂载路径填入：`/opt/emqx/data`

### 第四步：访问项目
1. 访问 Web 服务生成的域名（例如 `https://axgo.zeabur.app`）。
2. 访问首页确认前端资源已正常解压。
3. 访问 `/api/login` 或 `/api/login.do` 确认 `.do` 重写与 PHP 解析正常。

---

### 未来更新代码的过程
Zeabur 与 GitHub 是 **实时联动** 的（CI/CD）。

**前端更新**：
如果你修改了前端代码，请务必先在本地运行构建命令，生成最新的 `dist/www.zip`，然后再推送：
```bash
cd src/ax-go-admin
npm run build:zip  # 假设你有这个脚本，或者手动打包 dist 目录为 www.zip
# 确保新的 www.zip 覆盖了 src/ax-go-admin/dist/www.zip
```

**提交推送**：
```bash
git add .
git commit -m "更新前端资源和后端逻辑"
git push
```

**自动部署**：
Zeabur 会自动拉取代码，并在根目录 `Dockerfile` 构建过程中完成以下工作：
- 解压 `src/ax-go-admin/dist/www.zip` 到 `/var/www/html`
- 启动同容器内的 PHP-FPM
- 启动 Nginx
- 处理 `/api/*` 到 `.do` 的重写以及 PHP 转发
