# binance.wecode7.com — Nginx 反向代理 + SSL

> **日期**: 2026-07-01
> **状态**: 已部署
> **prod**: 84.247.154.45

## 1. 概述

通过 nginx 反向代理 + Let's Encrypt SSL，将 prod 内网 binance API 暴露到外网，支持远程开发和调试。

- **域名**: `binance.wecode7.com`
- **DNS**: 已指向 `84.247.154.45`
- **SSL**: Let's Encrypt (certbot 自动续期，到期 2026-09-28)
- **上游**: binance-server `127.0.0.1:8081`

## 2. 端点清单

| 路径 | 认证 | 上游 | 用途 |
|---|---|---|---|
| `/api/v1/stats` | 公开 | 8081 | 实时统计 (accepted/rejected/ingested) |
| `/api/v1/market/spot/{symbol}/latest` | 公开 | 8081 | 最新行情 |
| `/api/v1/market/spot/{symbol}/range` | 公开 | 8081 | 范围查询 |
| `/health` | 公开 | 8081 | 健康检查 (代理到 stats) |
| `/admin/streams` | Basic Auth | 8081 | Stream 状态、dead letter、freshness |
| `/admin/*` | Basic Auth | 8081 | 其他 admin 端点 |
| `/metrics` | Basic Auth | 8081 | Prometheus 指标 |
| `/grafana/` | Basic Auth | 3000 | Grafana 仪表盘 |
| `/jaeger/` | Basic Auth | 16686 | Jaeger 链路追踪 |
| `/nats/` | Basic Auth | 8222 | NATS 监控 (stream/consumer 状态) |
| `/` | — | — | 404 JSON (列出可用端点) |

## 3. 认证凭据

```
用户名: dev
密码:   BncDebug2026!
```

- htpasswd 文件: `/etc/nginx/.htpasswd_binance`
- Admin/Debug 端点均使用 Basic Auth 保护
- API 端点 (`/api/`) 无需认证，可供程序直接调用

## 4. 快速调试示例

### 4.1 命令行

```bash
# 查看 stats (公开)
curl https://binance.wecode7.com/api/v1/stats

# 查看 stream 状态 (需认证)
curl -u dev:BncDebug2026! https://binance.wecode7.com/admin/streams

# 查看 NATS 积压
curl -u dev:BncDebug2026! "https://binance.wecode7.com/nats/jsz?streams=true&consumers=true"

# 查看 Prometheus 指标
curl -u dev:BncDebug2026! https://binance.wecode7.com/metrics | head -20

# 查询最新行情
curl https://binance.wecode7.com/api/v1/market/spot/BTCUSDT/latest
```

### 4.2 浏览器

| 服务 | URL |
|---|---|
| Grafana | `https://binance.wecode7.com/grafana/` |
| Jaeger | `https://binance.wecode7.com/jaeger/` |
| NATS 监控 | `https://binance.wecode7.com/nats/jsz?streams=true` |
| Admin Streams | `https://binance.wecode7.com/admin/streams` |

> 浏览器访问受保护端点时会弹出 Basic Auth 对话框，输入 `dev` / `BncDebug2026!`。

## 5. Nginx 配置

### 5.1 文件位置

| 文件 | 说明 |
|---|---|
| `/etc/nginx/sites-available/binance.wecode7.com` | 主配置 |
| `/etc/nginx/sites-enabled/binance.wecode7.com` | 启用符号链接 |
| `/etc/nginx/.htpasswd_binance` | Basic Auth 凭据 |
| `/etc/letsencrypt/live/binance.wecode7.com/` | SSL 证书 |
| `/var/log/nginx/binance.wecode7.com.access.log` | 访问日志 |
| `/var/log/nginx/binance.wecode7.com.error.log` | 错误日志 |

### 5.2 配置结构

```nginx
# Upstream 定义
upstream binance_server  { server 127.0.0.1:8081; keepalive 32; }
upstream grafana_backend { server 127.0.0.1:3000; keepalive 16; }
upstream jaeger_backend  { server 127.0.0.1:16686; keepalive 16; }
upstream nats_monitor    { server 127.0.0.1:8222; keepalive 16; }

# HTTP → HTTPS 重定向 (port 80)
server {
    listen 80;
    server_name binance.wecode7.com;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 301 https://$host$request_uri; }
}

# HTTPS (port 443)
server {
    listen 443 ssl;
    server_name binance.wecode7.com;
    # SSL 证书 (certbot 管理)
    # CORS 头 (允许浏览器跨域调试)

    location /api/     { proxy_pass http://binance_server; }           # 公开
    location /health   { proxy_pass http://binance_server/api/v1/stats; } # 公开
    location /admin/   { auth_basic; proxy_pass http://binance_server; }  # 认证
    location /metrics  { auth_basic; proxy_pass http://binance_server; }  # 认证
    location /grafana/ { auth_basic; proxy_pass http://grafana_backend/; } # 认证
    location /jaeger/  { auth_basic; proxy_pass http://jaeger_backend/; }  # 认证
    location /nats/    { auth_basic; proxy_pass http://nats_monitor/; }    # 认证
    location /         { return 404 JSON; }                              # 默认
}
```

### 5.3 安全设计

| 层级 | 措施 |
|---|---|
| 传输层 | TLS 1.2/1.3 (Let's Encrypt) |
| API 层 | `/api/` 公开，`/admin/` `/metrics` Basic Auth |
| 调试层 | Grafana/Jaeger/NATS 均需 Basic Auth |
| 默认 | 未匹配路径返回 404 JSON |
| 日志 | 独立 access/error log |
| CORS | `Access-Control-Allow-Origin *` (便于浏览器调试) |

## 6. 开发效率提升点

| 能力 | 之前 | 之后 |
|---|---|---|
| 查看 stats | SSH 到 prod → curl localhost:8081 | `curl https://binance.wecode7.com/api/v1/stats` |
| 查看 stream 状态 | SSH → curl localhost:8081/admin/streams | 浏览器直接访问 |
| Grafana 仪表盘 | SSH 隧道 `-L 3000:localhost:3000` | `https://binance.wecode7.com/grafana/` |
| Jaeger 追踪 | SSH 隧道 `-L 16686:localhost:16686` | `https://binance.wecode7.com/jaeger/` |
| NATS 监控 | SSH → curl localhost:8222 | `https://binance.wecode7.com/nats/` |
| Prometheus 指标 | SSH → curl localhost:8081/metrics | `curl -u dev:... https://binance.wecode7.com/metrics` |

## 7. 部署步骤 (回溯)

```bash
# 1. DNS 已指向 84.247.154.45 (无需操作)

# 2. 创建 htpasswd
echo -n "dev:" | sudo tee /etc/nginx/.htpasswd_binance > /dev/null
echo -n "BncDebug2026!" | openssl passwd -stdin -apr1 | sudo tee -a /etc/nginx/.htpasswd_binance > /dev/null

# 3. 创建临时 HTTP-only 配置
sudo tee /etc/nginx/sites-available/binance.wecode7.com > /dev/null << 'EOF'
server {
    listen 80;
    server_name binance.wecode7.com;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { proxy_pass http://127.0.0.1:8081; proxy_set_header Host $host; }
}
EOF
sudo ln -sf /etc/nginx/sites-available/binance.wecode7.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 4. 获取 SSL 证书
sudo certbot --nginx -d binance.wecode7.com --non-interactive --agree-tos --email admin@wecode7.com --redirect

# 5. 替换为完整配置 (见 5.2 配置结构)
sudo tee /etc/nginx/sites-available/binance.wecode7.com > /dev/null << 'NGINX'
# ... 完整配置 ...
NGINX
sudo nginx -t && sudo systemctl reload nginx

# 6. 验证
curl https://binance.wecode7.com/api/v1/stats
curl -u dev:BncDebug2026! https://binance.wecode7.com/admin/streams
```

## 8. 运维操作

```bash
# 重载 nginx
sudo nginx -t && sudo systemctl reload nginx

# 查看 access log
sudo tail -f /var/log/nginx/binance.wecode7.com.access.log

# 查看错误 log
sudo tail -f /var/log/nginx/binance.wecode7.com.error.log

# 续期证书 (certbot 自动续期，手动检查)
sudo certbot renew --dry-run

# 更新 htpasswd
echo -n "newuser:" | sudo tee -a /etc/nginx/.htpasswd_binance > /dev/null
echo -n "password" | openssl passwd -stdin -apr1 | sudo tee -a /etc/nginx/.htpasswd_binance > /dev/null
```

## 9. 已知问题

### 9.1 已修复

| 问题 | 修复 | commit |
|---|---|---|
| 处理延迟 ~300s（吞吐 1.6/s，NATS 积压 205,861） | worker pool + TDengine 连接池 + skip-kafka，吞吐→915/s，freshness→11ms | `5f65211` |
| st_bar 数据为 0（stale rejection 阻止 bar 落库） | 同上，freshness 11ms 后 bar 正常写入（556+ growing） | `5f65211` |

### 9.2 当前问题

- **Kafka 下游广播中断**：`FOUNDATIONX_BINANCE_SKIP_KAFKA=1`（broker 不可达），事件只写 TDengine 不进 Kafka。依赖 Kafka 下游的消费方收不到数据。kafkax v1.1.2 已修复 producer 互斥锁串行化、HealthCheck broker 拨号、幂等配置等根因缺陷，broker 修复后可安全移除 skip。详见 [DEPLOY.md §13.4](./DEPLOY.md#134-kafka-producer-超时--skip-kafka)。
- **gap_detected=38272 历史遗留**：server→client gap 自动修复管线已完整闭环（replay worker → NATS → client subscriber → QueueGapFill → lifecycle worker → HistoryRuntime REST 回填）。纯观测性，不阻塞处理。详见 [DEPLOY.md §13.5](./DEPLOY.md#135-gap_detected38272--gap-repair-机制)。
