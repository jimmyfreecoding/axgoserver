在 Zeabur 中部署这个项目非常简单，虽然 Zeabur 不直接支持自动拆分 `docker-compose.yml`，但我们可以手动添加相关服务来构建完整的环境。

以下是详细的部署步骤：

### 第一步：推送代码到 GitHub
确保你已经执行了推送命令，将代码同步到仓库：

```bash
git add .
git commit -m "准备 Zeabur 部署配置文件"
git push
```

### 第二步：在 Zeabur 中部署服务
在一个 Zeabur 项目内，手动添加以下 4 个服务：

#### 1. 部署 MySQL (数据库)
1. 点击 **"Deploy New Service"** -> **"Marketplace"**。
2. 搜索并选择 **"MySQL"**。
3. 在 MySQL 服务的 **"Variables"** 选项卡中，记录下生成的 `MYSQL_ROOT_PASSWORD` 等信息（或者手动设置它们）。

#### 2. 部署 EMQX (MQTT)
1. 点击 **"Deploy New Service"** -> **"Marketplace"**。
2. 搜索并选择 **"EMQX"**。

#### 3. 部署 PHP (后端)
1. 点击 **"Deploy New Service"** -> **"GitHub"** -> 选择你的 `axgoserver` 仓库。
2. 进入该服务的 **"Settings"** -> **"Docker"**：
   - 将 **Dockerfile Path** 设置为 `php/Dockerfile`。
3. 进入 **"Networking"**：
   - 在 **Service Alias** 处填入 `php`（这非常重要，Nginx 会通过这个名字找到它）。
4. 在 **"Variables"** 中添加数据库环境变量（与 MySQL 服务保持一致）。

#### 4. 部署 Nginx (网关/前端)
1. 点击 **"Deploy New Service"** -> **"GitHub"** -> 再次选择你的 `axgoserver` 仓库。
2. 进入该服务的 **"Settings"** -> **"Docker"**：
   - 将 **Dockerfile Path** 设置为 `nginx/Dockerfile`。
3. 进入 **"Networking"**：
   - 点击 **"Generate Domain"** 生成一个公共访问域名。

### 第三步：配置持久化存储 (Volume)
为了保证数据库和 EMQX 的数据在重启后不丢失，需要挂载卷：

1. 点击 **mysql** 服务 -> **"Storage"** -> **"Mount Volume"**：
   - 挂载路径填入：`/var/lib/mysql`
2. 点击 **emqx** 服务 -> **"Storage"** -> **"Mount Volume"**：
   - 挂载路径填入：`/opt/emqx/data`

### 第四步：访问项目
1. 访问 Nginx 服务生成的域名（例如 `https://axgo.zeabur.app`）。
2. 你能看到 `index.html` 的内容，或者访问 `/api/test_db.do` 测试数据库连接。

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
Zeabur 会自动拉取代码，在 Docker 构建过程中自动解压 `www.zip` 到容器的 `/var/www/html` 目录，完成更新。
