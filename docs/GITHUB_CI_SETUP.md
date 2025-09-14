# GitHub CI/CD 部署配置指南

## 🔐 SSH密钥配置

### 1. 在服务器上生成部署用户和SSH密钥

```bash
# 在服务器上创建部署用户
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# 切换到部署用户
sudo su - deploy

# 生成SSH密钥对
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy
# 或者使用RSA格式（兼容性更好）
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_deploy

# 将公钥添加到authorized_keys
cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# 显示私钥（复制到GitHub Secrets）
cat ~/.ssh/github_deploy
```

### 2. 配置部署目录权限

```bash
# 创建部署目录
sudo mkdir -p /opt/amazon-pilot
sudo chown deploy:deploy /opt/amazon-pilot

# 切换到部署用户
sudo su - deploy
cd /opt/amazon-pilot

# 克隆项目（第一次）
git clone https://github.com/your-username/amazon-pilot.git .

# 创建生产环境配置
cp deployments/compose/.env.prod deployments/compose/.env.production

# 编辑生产环境配置
vi deployments/compose/.env.production
# 修改：数据库密码、Redis密码、JWT密钥、API密钥等
```

### 3. 配置GitHub Repository Secrets

在GitHub仓库设置中添加以下Secrets：

```
Settings → Secrets and variables → Actions → New repository secret
```

**必需的Secrets：**

| Secret Name | Value | 说明 |
|-------------|-------|------|
| `SERVER_HOST` | `your-server-ip` | 服务器IP地址 |
| `SERVER_USER` | `deploy` | 部署用户名 |
| `SERVER_SSH_KEY` | `私钥内容` | 从服务器复制的私钥 |
| `SERVER_PORT` | `22` | SSH端口（可选，默认22） |
| `DATABASE_PASSWORD` | `your-db-password` | PostgreSQL数据库密码 |
| `REDIS_PASSWORD` | `your-redis-password` | Redis密码 |
| `JWT_SECRET` | `your-32-char-secret` | JWT签名密钥（至少32字符） |
| `APIFY_API_TOKEN` | `your-apify-token` | Apify API Token |
| `OPENAI_API_KEY` | `your-openai-key` | OpenAI API Key |
| `GRAFANA_PASSWORD` | `your-grafana-password` | Grafana管理员密码 |

**SSH私钥格式示例：**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn...
（完整的私钥内容）
-----END OPENSSH PRIVATE KEY-----
```

### 4. 配置环境（Environment）

```bash
# 在GitHub中创建production环境
Settings → Environments → New environment → "production"

# 可选：配置环境保护规则
- Required reviewers（需要审核才能部署）
- Wait timer（部署前等待时间）
- Deployment branches（只有特定分支可以部署）
```

## 🚀 使用方式

### 自动部署（推送到main分支）
```bash
git add .
git commit -m "update: 产品功能优化"
git push origin main
# 自动触发CI/CD部署
```

### 手动部署（GitHub界面）
```
1. 进入GitHub仓库
2. Actions → Amazon Pilot - Production Deploy
3. Run workflow → 选择分支和服务
4. 点击 Run workflow
```

### 标签部署（特定服务）
```bash
# 部署特定服务
git tag auth-v1.2.3
git push origin auth-v1.2.3

# 部署所有服务
git tag all-v1.2.3
git push origin all-v1.2.3
```

## 🔧 部署流程说明

### CI/CD Pipeline
```
1. 🏗️  Build阶段
   - 检出代码
   - 构建Docker镜像
   - 保存镜像为artifact

2. 📦 Deploy阶段
   - 下载镜像
   - 上传到服务器
   - 加载镜像
   - 滚动更新服务
   - 健康检查

3. 📧 Notify阶段
   - 发送部署结果通知
```

### 零停机部署特性
- ✅ **滚动更新** - 服务逐个更新
- ✅ **健康检查** - 确保服务正常后才继续
- ✅ **备份配置** - 自动备份现有配置
- ✅ **失败回滚** - 部署失败时停止

## 🛡️ 安全配置

### 1. SSH安全
```bash
# 服务器SSH配置优化 /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# 重启SSH服务
sudo systemctl restart sshd
```

### 2. 防火墙配置
```bash
# 只开放必要端口
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# 禁止直接访问Docker端口
sudo ufw deny 3000:8080/tcp
```

### 3. Docker安全
```bash
# 将deploy用户加入docker组
sudo usermod -aG docker deploy

# 配置Docker daemon
sudo vi /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
sudo systemctl restart docker
```

## 📋 部署检查清单

### 部署前检查
- [ ] SSH密钥已生成并添加到GitHub Secrets
- [ ] 服务器部署目录已创建（/opt/amazon-pilot）
- [ ] 生产环境变量已配置（.env.production）
- [ ] Caddy配置已添加到服务器
- [ ] 防火墙规则已配置
- [ ] Docker和docker-compose已安装

### 部署后检查
- [ ] 所有服务容器正常运行
- [ ] 健康检查端点响应正常
- [ ] 前端页面可以访问
- [ ] SSL证书自动申请成功
- [ ] 监控界面需要认证才能访问

## 🔍 故障排除

### 常见问题
```bash
# 1. SSH连接失败
ssh -i ~/.ssh/github_deploy deploy@your-server-ip
# 检查网络、密钥、用户权限

# 2. Docker权限问题
sudo usermod -aG docker deploy
# 重新登录或 newgrp docker

# 3. 部署目录权限
sudo chown -R deploy:deploy /opt/amazon-pilot
sudo chmod -R 755 /opt/amazon-pilot

# 4. 端口冲突
sudo lsof -i :80,443,3001,4000,5555,8001,8002,8003,8004,8080

# 5. 查看部署日志
cd /opt/amazon-pilot
docker-compose -f deployments/compose/docker-compose.yml logs
```

---

**配置完成后，每次push到main分支都会自动部署到生产环境！** 🚀