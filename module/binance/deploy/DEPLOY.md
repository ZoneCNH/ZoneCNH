# binance 二进制构建与部署

- Runtime-Version: v0.8.0（anchor: `/home/binance@b2d9d83`）
- Target: jp1 (84.247.154.45)
- Last-Updated: 2026-06-30

## 目录

1. [构建产物](#1-构建产物)
2. [Docker 镜像构建](#2-docker-镜像构建)
3. [基础设施依赖](#3-基础设施依赖)
4. [部署流程](#4-部署流程)
5. [systemd 进程管理](#5-systemd-进程管理)
6. [健康检查](#6-健康检查)
7. [回滚](#7-回滚)
8. [凭据管理](#8-凭据管理)
9. [运维操作](#9-运维操作)
10. [CI/CD 管线](#10-cicd-管线)

---

## 1. 构建产物

binance 模块编译为 **两个独立二进制文件**，通过单一多阶段 Dockerfile 构建：

| 二进制 | 入口 | 角色 |
|--------|------|------|
| `binance-client` | `cmd/binance-client/` | 连接 Binance WS/REST，解析→映射→NATS 发布 |
| `binance-server` | `cmd/binance-server/` | NATS 消费→校验去重→存储→Gin API→Kafka 广播 |

### 编译参数

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath \
    -ldflags="-s -w -X main.Version=${VERSION} -X main.Commit=${COMMIT} -X main.BuildTime=${BUILD_TIME}" \
    -o binance-client ./cmd/binance-client/

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath \
    -ldflags="-s -w -X main.Version=${VERSION} -X main.Commit=${COMMIT} -X main.BuildTime=${BUILD_TIME}" \
    -o binance-server ./cmd/binance-server/
```

- CGO 禁用：纯 Go 静态链接
- `-trimpath`：去除构建路径信息
- `-ldflags="-s -w"`：去除符号表和 DWARF 调试信息，减小二进制体积
- 版本信息通过 `main.Version` / `main.Commit` / `main.BuildTime` 注入

---

## 2. Docker 镜像构建

### 2.1 合并镜像（推荐：`Dockerfile`）

多阶段构建，最终镜像基于 `gcr.io/distroless/static-debian12:nonroot`：

```dockerfile
# Stage 1: build (golang:1.25-alpine)
FROM golang:1.25-alpine AS builder
# → go mod download → go build binance-client + binance-server

# Stage 2: runtime (distroless)
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/binance-client /usr/local/bin/binance-client
COPY --from=builder /out/binance-server /usr/local/bin/binance-server
ENTRYPOINT ["/usr/local/bin/binance-server"]
```

- 运行时不含 shell，攻击面最小
- nonroot 用户（UID=65532）
- 通过 `docker-compose` 的 `command` 字段区分 client/server

### 2.2 独立镜像（可选）

| Dockerfile | 基础镜像 | 特点 |
|------------|---------|------|
| `Dockerfile.client` | `alpine:3.20` | 轻量 client，含 ca-certificates |
| `Dockerfile.server` | `alpine:3.20` | 含 curl（健康检查），暴露 :8080 / :8081 |

### 2.3 镜像构建与推送

```bash
# 合并镜像（CI 自动执行）
docker build \
  --build-arg VERSION=v0.8.0 \
  --build-arg COMMIT=$(git rev-parse HEAD) \
  --build-arg BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -t ghcr.io/zonecnh/binance:v0.8.0 \
  -f Dockerfile .

docker push ghcr.io/zonecnh/binance:v0.8.0
```

---

## 3. 基础设施依赖

binance 模块本身是**纯 Go 二进制**，不内嵌任何中间件。以下 7 个 infra 为**外部独立服务**，部署前须确保可用：

| 服务 | 端口 | 用途 | 客户端 |
|------|------|------|--------|
| **NATS JetStream** | `:4222` | 异步消息总线（pub/sub） | client（发布）+ server（消费） |
| **Redis** | `:6379` | 幂等性（SetNX）+ 热缓存 | server |
| **PostgreSQL** | `:5432` | 元数据 + 审计日志 | server |
| **TDengine** | `:6030` | 时序数据存储 | server |
| **Kafka** | `:9092` | 下游数据广播 | server |
| **ClickHouse** | `:9000` | OLAP 分析 | server |
| **Aliyun OSS** | `oss-cn-hangzhou.aliyuncs.com` | 冷存储归档 | server |

**网络拓扑**：所有服务通过 `network_mode: host` 直连 `127.0.0.1`，无 Docker 网络隔离层。

**OpenTelemetry**：OTEL gRPC endpoint `127.0.0.1:4317`（可选）。

### 最小可用集合

开发和功能验证只需以下 3 个服务：

```text
NATS :4222  +  Redis :6379  +  PostgreSQL :5432
```

完整生产部署需要全部 7 个 infra + OTEL。

---

## 4. 部署流程

### 4.1 前置条件

- [ ] SSH 免密登录 jp1：`ssh claude@84.247.154.45 echo ok`
- [ ] jp1 上 Docker 已安装：`docker --version`
- [ ] 7 个 infra 服务运行中且可达
- [ ] `/opt/binance/secrets/prod.env` 已配置真实凭据，权限 `600`
- [ ] `ghcr.io/zonecnh/binance` 镜像仓库可访问

### 4.2 使用 deploy.sh（推荐）

```bash
# 预演（不实际部署）
./deploy.sh --dry-run

# 生产部署（交互确认）
./deploy.sh --env prod --tag v0.8.0

# 开发环境
./deploy.sh --env dev --tag latest
```

**deploy.sh 执行步骤**：

1. **preflight** — SSH 连通性检查，创建目标目录
2. **build_and_push** — Docker 构建 + 推送到 ghcr.io
3. **deploy** — 上传配置 → 停止旧服务 → 备份 → 拉取镜像 → 安装 systemd → 启动
4. **health_check** — 轮询 `/healthz`（最多 12 次 × 10s = 2 分钟）
5. **cleanup** — 清理 6 代之前的旧 release + 7 天前的 Docker 镜像

### 4.3 手动部署

```bash
# 1. 构建并推送
docker build -t ghcr.io/zonecnh/binance:v0.8.0 -f Dockerfile .
docker push ghcr.io/zonecnh/binance:v0.8.0

# 2. 上传配置到 jp1
scp deploy/docker-compose.prod.yml claude@84.247.154.45:/opt/binance/releases/v0.8.0/docker-compose.yml
scp deploy/binance-server.service claude@84.247.154.45:/tmp/
scp deploy/binance-client.service claude@84.247.154.45:/tmp/
scp deploy/health-check.sh claude@84.247.154.45:/opt/binance/releases/v0.8.0/

# 3. SSH 到 jp1
ssh claude@84.247.154.45

# 4. 停止旧服务
sudo systemctl stop binance-client binance-server

# 5. 备份当前
OLD=$(readlink /opt/binance/current)
cp -a $OLD /opt/binance/backups/$(date +%Y%m%d-%H%M%S)

# 6. 拉取镜像
docker pull ghcr.io/zonecnh/binance:v0.8.0

# 7. 安装 systemd unit
sudo cp /tmp/binance-server.service /etc/systemd/system/
sudo cp /tmp/binance-client.service /etc/systemd/system/
sudo systemctl daemon-reload

# 8. 更新 current 软链接
ln -sfn /opt/binance/releases/v0.8.0 /opt/binance/current

# 9. 启动
sudo systemctl enable binance-server binance-client
sudo systemctl start binance-server
sleep 5
sudo systemctl start binance-client

# 10. 验证
curl http://127.0.0.1:8080/healthz
bash /opt/binance/current/health-check.sh
```

### 4.4 目录结构（jp1）

```text
/opt/binance/
├── current -> releases/v0.8.0/     ← systemd 工作目录
├── releases/
│   ├── v0.8.0/
│   │   ├── docker-compose.yml
│   │   └── health-check.sh
│   └── v0.7.0/
├── backups/
│   └── 20260630-120000/
├── secrets/
│   └── prod.env                    ← chmod 600
└── (docker 数据卷由各 infra 管理)
```

---

## 5. systemd 进程管理

### 5.1 binance-server.service

```ini
[Unit]
Description=Binance Server — NATS consumer + Gin REST API
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/binance/current
ExecStartPre=/usr/bin/docker compose pull binance-server
ExecStart=/usr/bin/docker compose up binance-server
ExecStop=/usr/bin/docker compose stop binance-server
ExecReload=/usr/bin/docker compose restart binance-server
Restart=always
RestartSec=10
TimeoutStopSec=30
MemoryHigh=3.5G
MemoryMax=4G
CPUQuota=200%
```

### 5.2 binance-client.service

```ini
[Unit]
Description=Binance Client — Market Data Ingestion
After=binance-server.service
Requires=binance-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/binance/current
ExecStartPre=/usr/bin/docker compose pull binance-client
ExecStart=/usr/bin/docker compose up binance-client
ExecStop=/usr/bin/docker compose stop binance-client
Restart=always
RestartSec=10
TimeoutStopSec=30
MemoryHigh=400M
MemoryMax=512M
CPUQuota=100%
```

### 5.3 启动依赖链

```text
docker.service → binance-server.service → binance-client.service
```

- server 必须先于 client 启动（client `Requires=binance-server.service`）
- docker-compose 额外配置 `depends_on: service_healthy` 确保启动顺序

### 5.4 常用命令

```bash
# 查看状态
sudo systemctl status binance-server binance-client

# 查看日志
sudo journalctl -u binance-server -f
sudo journalctl -u binance-client -f -n 100

# 重启
sudo systemctl restart binance-server && sleep 5 && sudo systemctl restart binance-client

# 资源用量
systemctl show binance-server -p MemoryCurrent,CPUUsageNSec
```

---

## 6. 健康检查

### 6.1 端点

| 端点 | 用途 | 预期 |
|------|------|------|
| `GET /healthz` | 存活检查（liveness） | HTTP 200 |
| `GET /metrics` | Prometheus 指标 | HTTP 200 |
| `GET /readyz` | 就绪检查（readiness） | HTTP 200 |

### 6.2 Docker healthcheck（30s 间隔）

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://127.0.0.1:8080/healthz"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s
```

### 6.3 health-check.sh（部署后完整验证）

```bash
bash /opt/binance/current/health-check.sh [host] [port]
```

检查项：
- ✅ `GET /healthz` → HTTP 200
- ✅ `GET /metrics` → HTTP 200
- ✅ 进程存活（`pgrep binance-server` / `pgrep binance-client`）
- ✅ 端口监听（`:8080`）
- ✅ Docker 容器运行中
- ✅ 磁盘使用率 < 85%

### 6.4 告警规则（alertmanager）

```yaml
# /home/binance/deploy/alertmanager/config.yml
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'    # → webhook → :9093
```

---

## 7. 回滚

### 7.1 自动回滚（deploy.sh 内置）

`deploy.sh` 健康检查失败时自动触发回滚：

```bash
# deploy.sh 内置逻辑
rollback() {
    # 1. 停止当前服务
    sudo systemctl stop binance-client binance-server
    # 2. 恢复最近的备份
    ln -sfn /opt/binance/backups/{latest} /opt/binance/current
    # 3. 启动
    sudo systemctl start binance-server && sleep 5 && sudo systemctl start binance-client
}
```

### 7.2 手动回滚

```bash
# SSH 到 jp1
ssh claude@84.247.154.45

# 查看可用备份
ls -lt /opt/binance/backups/

# 停止当前
sudo systemctl stop binance-client binance-server

# 切换到备份
ln -sfn /opt/binance/backups/20260630-120000 /opt/binance/current

# 启动
sudo systemctl start binance-server && sleep 5 && sudo systemctl start binance-client

# 验证
curl http://127.0.0.1:8080/healthz
```

### 7.3 CI 回滚演练

通过 GitHub Actions `workflow_dispatch` 触发：

```yaml
# ci-workflow.yaml → rollback-drill job
# 触发: workflow_dispatch + inputs.rollback_ref
# 产出: rollback-plan.md → artifacts
```

---

## 8. 凭据管理

### 8.1 Secrets 文件

```bash
# 模板
/home/binance/deploy/prod.env.example

# 部署到 jp1
scp prod.env.example claude@84.247.154.45:/opt/binance/secrets/prod.env
# 编辑真实凭据
ssh claude@84.247.154.45 "chmod 600 /opt/binance/secrets/prod.env"
```

### 8.2 必需凭据

| 环境变量 | 用途 |
|----------|------|
| `FOUNDATIONX_POSTGRESX_PASSWORD` | PostgreSQL 密码 |
| `FOUNDATIONX_TAOSX_PASSWORD` | TDengine 密码 |
| `FOUNDATIONX_REDISX_PASSWORD` | Redis 密码 |
| `FOUNDATIONX_NATSX_TOKEN` | NATS 认证令牌 |
| `FOUNDATIONX_OSSX_ACCESS_KEY_ID` | Aliyun OSS AK |
| `FOUNDATIONX_OSSX_ACCESS_KEY_SECRET` | Aliyun OSS SK |
| `FOUNDATIONX_BINANCE_ADMIN_TOKEN` | Admin API 令牌 |

### 8.3 安全约束

- `prod.env` 必须 `chmod 600`，仅 root 可读
- **绝不提交** `prod.env` 到 Git（已在 `.gitignore`）
- CI/CD 凭据通过 GitHub Secrets 注入，不写入镜像
- 凭据在镜像外，通过 `env_file` 注入容器

---

## 9. 运维操作

### 9.1 Canary 灰度部署

```bash
# 启动 canary 部署（K8s 环境自动灰度 30%，非 K8s 手动确认）
CANARY_TAG=v0.9.0 bash /home/binance/scripts/deploy-canary.sh
```

流程：
1. **Preflight** — 确认当前实例 `/healthz` 正常，rollback 资源可用
2. **启动 canary** — K8s: `kubectl set image` 灰度 30%；非 K8s: 手动启动新实例
3. **等待窗口** — 默认 300s（`CANARY_WINDOW_SECONDS`）
4. **Gate 检查** — 调用 `deploy-canary-gate.sh`，检查 `/readyz`、error-rate < 1%、consumer-lag < 阈值
5. **判定** — PASS → 全量 rollout；FAIL → 自动 rollback 并验证 `/healthz` 恢复

Canary gate 检查项（`deploy-canary-gate.sh`）：

| 检查项 | 方法 | 阈值 |
|--------|------|------|
| `/readyz` | `curl GET /readyz` | HTTP 200 |
| error-rate | `binance_ingest_requests_total{verdict="rejected"} / total` | < 1.0% |
| consumer-lag | `binance_kafka_consumer_lag_messages` | < 10000 条 |

### 9.2 数据销毁演练

```bash
# DRY RUN（默认）
DRY_RUN=true RETENTION_DAYS=90 bash /home/binance/scripts/destruction-drill.sh

# 真实执行
DRY_RUN=false RETENTION_DAYS=90 bash /home/binance/scripts/destruction-drill.sh
```

流程：选择过期数据 → 不可逆销毁（OSS delete + TDengine DROP + PG DELETE）→ 生成证书 JSON → 归档到 OSS → 写入 audit_log。

详见 `/home/binance/scripts/destruction-drill.sh`。

### 9.3 生产就绪审计

```bash
bash /home/binance/scripts/readiness-audit.sh
```

检查项：`go.sum` 追踪、二进制不追踪、`.gitignore`、必需文件存在、Go 版本固定、README gate 状态、配置项完整性、runbook 引用链等。共 100+ 断言。

### 9.4 运行时证据收集

```bash
# 生成 release evidence package
bash /home/binance/scripts/runtime-release-evidence.sh
```

### 9.5 容器日志

```bash
# Docker 日志（json-file driver，100MB × 5 文件轮转）
docker logs binance-server --tail 200 -f
docker logs binance-client --tail 200 -f

# systemd journal
sudo journalctl -u binance-server --since "10 min ago"
sudo journalctl -u binance-client -S "2026-06-30 12:00:00"
```

### 9.6 资源限制

| 容器 | Memory Limit | Memory Reservation | CPU |
|------|-------------|--------------------|-----|
| binance-server | 4G | 1G | 200% |
| binance-client | 512M | 256M | 100% |

---

## 10. CI/CD 管线

### 10.1 机器池

| 阶段 | 池 | 触发 |
|------|-----|------|
| CI（preflight / build / test / lint / boundary / integration / secret-scan） | `sre/storage-light` | PR / push |
| CD（release-preflight / publish / smoke） | `sre/deploy` | tag `v*` |
| Rollback Drill | `sre/deploy` | `workflow_dispatch` |

### 10.2 管线阶段

```text
PR / push to main:
  ci-preflight → [build │ test │ lint │ boundary │ integration │ secret-scan] → evidence

tag v* (在 evidence 通过后):
  release-preflight → release-publish → post-release-smoke
```

### 10.3 证据门禁

`evidence` job 生成 `ci-manifest.json` 并上传 CI evidence artifact。所有 CI job 必须在 release 前通过。

### 10.4 工作流文件

模板：`module/binance/ci-workflow.yaml` → 复制到 `github.com/ZoneCNH/binance/.github/workflows/ci.yml`

---

## 参考

- 架构设计：[`../design/DESIGN.md`](../design/DESIGN.md)
- 数据流详解：`../design/DESIGN.md` §3
- 边界门禁：[`../gate/BOUNDARY-GATES.md`](../gate/BOUNDARY-GATES.md)
- 部署脚本源码：`/home/binance/deploy/deploy.sh`
- CI/CD 模板：[`../ci-workflow.yaml`](../ci-workflow.yaml)
