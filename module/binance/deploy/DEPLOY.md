# binance 二进制构建与部署

- Runtime-Version: v0.12.0（anchor: `/home/workspace/binance@c24b4ce` — merge `fix/runtime-gap-phase2-5` + post-merge config 字段回归修复）
- Target: jp1 (84.247.154.45)
- Last-Updated: 2026-07-04

## 目录

1. [构建产物](#1-构建产物)
2. [二进制交叉编译（首选）](#2-二进制交叉编译首选)
3. [Docker 镜像构建（可选）](#3-docker-镜像构建可选)
4. [基础设施依赖](#4-基础设施依赖)
5. [基础设施配置踩坑](#5-基础设施配置踩坑)
6. [部署流程](#6-部署流程)
7. [systemd 进程管理](#7-systemd-进程管理)
8. [健康检查](#8-健康检查)
9. [回滚](#9-回滚)
10. [凭据管理](#10-凭据管理)
11. [运维操作](#11-运维操作)
12. [CI/CD 管线](#12-cicd-管线)
13. [已知部署 Bug 与修复](#13-已知部署-bug-与修复)

---

## 1. 构建产物

binance 模块编译为 **两个独立二进制文件**：

| 二进制           | 入口                  | 角色                                       | 体积 |
| ---------------- | --------------------- | ------------------------------------------ | ---- |
| `binance-client` | `cmd/binance-client/` | 连接 Binance WS/REST，解析→映射→NATS 发布  | ~17M |
| `binance-server` | `cmd/binance-server/` | NATS 消费→校验去重→存储→Gin API→Kafka 广播 | ~46M |

### 编译参数

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath \
    -ldflags="-s -w" \
    -o binance-client ./cmd/binance-client/

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath \
    -ldflags="-s -w" \
    -o binance-server ./cmd/binance-server/
```

- CGO 禁用：纯 Go 静态链接，无外部 .so 依赖
- `-trimpath`：去除构建路径信息
- `-ldflags="-s -w"`：去除符号表和 DWARF 调试信息，减小二进制体积
- Go 工具链：1.26.4（go.mod 声明 `go 1.25.0`，`toolchain go1.26.4`）

---

## 2. 二进制交叉编译（首选）

生产部署采用**二进制直部署**方式，在开发机交叉编译后 scp 到 jp1。

### 2.1 使用 Makefile

```bash
# 在 /home/workspace/binance 目录下
make build-linux-amd64

# 产物
# bin/binance-server-linux-amd64  (46M)
# bin/binance-client-linux-amd64  (17M)
```

### 2.2 手动编译

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath -ldflags="-s -w" \
  -o binance-server ./cmd/binance-server/

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath -ldflags="-s -w" \
  -o binance-client ./cmd/binance-client/
```

### 2.3 选择二进制部署而非 Docker 的原因

| 因素                | 说明                                                              |
| ------------------- | ----------------------------------------------------------------- |
| Docker build 超时   | jp1 资源有限，多阶段构建超时                                      |
| distroless 无 shell | `gcr.io/distroless/static-debian12` 不含 curl/shell，健康检查困难 |
| 调试不便            | 二进制直部署可直接 `strace`、`ltrace`、`gdb`                      |
| 启动速度            | 无容器启动开销，systemd 直接管理                                  |

---

## 3. Docker 镜像构建（可选）

如需容器化部署，可使用多阶段 Dockerfile 构建。

### 3.1 合并镜像（`Dockerfile`）

```dockerfile
# Stage 1: build
FROM golang:1.26-alpine AS builder
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
- **注意**：distroless 无 curl，健康检查需用二进制内置 `/healthz` 端点 + 外部 curl

### 3.2 独立镜像（可选）

| Dockerfile          | 基础镜像      | 特点                                    |
| ------------------- | ------------- | --------------------------------------- |
| `Dockerfile.client` | `alpine:3.20` | 轻量 client，含 ca-certificates         |
| `Dockerfile.server` | `alpine:3.20` | 含 curl（健康检查），暴露 :8090 / :8081 |

### 3.3 镜像构建与推送

```bash
docker build \
  --build-arg VERSION=v0.12.0 \
  --build-arg COMMIT=$(git rev-parse HEAD) \
  --build-arg BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -t ghcr.io/zonecnh/binance:v0.12.0 \
  -f Dockerfile .

docker push ghcr.io/zonecnh/binance:v0.12.0
```

---

## 4. 基础设施依赖

binance 模块本身是**纯 Go 二进制**，不内嵌任何中间件。以下 infra 为**外部独立服务**，部署前须确保可用：

| 服务                  | 端口                            | 用途                                | 客户端                         |
| --------------------- | ------------------------------- | ----------------------------------- | ------------------------------ |
| **NATS JetStream**    | `:4222` / `:8222`               | 异步消息总线（pub/sub）             | client（发布）+ server（消费） |
| **Redis**             | `:6379`                         | 幂等性（SetNX）+ 热缓存             | server                         |
| **PostgreSQL**        | `:5432`                         | 元数据 + 审计日志                   | server                         |
| **TDengine**          | `:6030` / `:6041`               | 时序数据存储（WebSocket）           | server                         |
| **Kafka**             | `:9092`                         | 下游数据广播（SASL_PLAINTEXT）      | server                         |
| **ClickHouse**        | `:9000` / `:8123`               | OLAP 分析（localhost only）         | server                         |
| **ClickHouse Keeper** | `:9181`                         | CH Raft 共识（ReplicatedMergeTree） | CH 内部                        |
| **Aliyun OSS**        | `oss-cn-hangzhou.aliyuncs.com`  | 冷存储归档                          | server                         |
| **Jaeger**            | `:16686`                        | 分布式追踪 UI                       | 可选                           |
| **Grafana**           | `:3000`                         | 监控面板                            | 可选                           |
| **OpenTelemetry**     | `:4317` (gRPC) / `:4318` (HTTP) | 遥测收集                            | 可选                           |

**网络拓扑**：所有服务通过 host network 直连 `127.0.0.1`，无 Docker 网络隔离层。

**OTel 端点**：binance 使用 **HTTP 协议** (`127.0.0.1:4318`)，不是 gRPC (`:4317`)。

> ⚠️ **Kafka 当前已跳过**：`FOUNDATIONX_BINANCE_SKIP_KAFKA=1`（broker 不可达），dispatcher=nil，事件只写 TDengine 不进 Kafka 下游广播。kafkax v1.1.2 已修复 producer 互斥锁串行化、HealthCheck broker 拨号、幂等配置等缺陷，broker 修复后可安全移除 skip。详见 [§13.4](#134-kafka-producer-超时--skip-kafka)。

### 最小可用集合

开发和功能验证只需以下 3 个服务：

```text
NATS :4222  +  Redis :6379  +  PostgreSQL :5432
```

完整生产部署需要全部 infra。

---

## 5. 基础设施配置踩坑

实际部署中遇到的 10 项基础设施层面问题及解决方案：

| #   | 问题                                        | 原因                                             | 解决方案                                                          |
| --- | ------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------------- |
| I1  | 端口 8080 被占用                            | jp1 上 code-server 已监听 `:8080`                | `FOUNDATIONX_BINANCE_GIN_ADDR=:8090`，`ADMIN_ADDR=127.0.0.1:8081` |
| I2  | ClickHouse `market_binance` 库不存在        | 首次部署未建库                                   | `CREATE DATABASE market_binance`                                  |
| I3  | ClickHouse 缺 `{shard}` macro               | ReplicatedMergeTree 引用 `{shard}` / `{replica}` | `/etc/clickhouse-server/config.d/macros.xml` 定义 macro           |
| I4  | ClickHouse ReplicatedMergeTree 无法创建     | 缺 ZooKeeper/Keeper 协调                         | 启用 `clickhouse-keeper` (`:9181`) + `zookeeper.xml` 配置         |
| I5  | Redis 密码与 prod.md 不符                   | prod.md 记录的密码过时                           | 修正 prod.md 为实际密码 `dai1ooShaigh0thahReeg5Eu`                |
| I6  | Redis 无 `admin` 用户                       | prod.md 假设有 admin 用户                        | 使用 `FOUNDATIONX_REDISX_USERNAME=default`                        |
| I7  | NATS 认证失败                               | URL 内未嵌凭据                                   | `nats://nats_admin:...@127.0.0.1:4222`                            |
| I8  | Admin 端口非环回需 TLS                      | Gin admin bind 非 127.0.0.1 触发 TLS 要求        | `ADMIN_ADDR=127.0.0.1:8081`（server）/ `127.0.0.1:8082`（client） |
| I9  | Client 发布 `.v1` 后缀不匹配 stream subject | NATS stream subject 与 publish subject 不一致    | NATS subject mapping 配置                                         |
| I10 | OTel 端口 gRPC/HTTP 不匹配                  | binance 用 HTTP 协议，默认配 gRPC 端口           | `FOUNDATIONX_OTEL_ENDPOINT=127.0.0.1:4318`                        |

### 5.1 ClickHouse macros.xml

```xml
<!-- /etc/clickhouse-server/config.d/macros.xml -->
<clickhouse>
  <macros>
    <shard>01</shard>
    <replica>01</replica>
  </macros>
</clickhouse>
```

### 5.2 ClickHouse zookeeper.xml

```xml
<!-- /etc/clickhouse-server/config.d/zookeeper.xml -->
<clickhouse>
  <zookeeper>
    <node>
      <host>127.0.0.1</host>
      <port>9181</port>
    </node>
  </zookeeper>
</clickhouse>
```

### 5.3 NATS subject mapping

```text
# /etc/nats/nats.conf
# 映射 binance.spot.trade.v1 → BINANCE_MARKET stream subject
mappings = {
  "binance.spot.>": "BINANCE_MARKET.>"
}
```

---

## 6. 部署流程

### 6.1 前置条件

- [ ] SSH 免密登录 jp1：`ssh -i ~/.ssh/id_ed25519 claude@84.247.154.45 echo ok`
- [ ] jp1 上 10 个 infra 服务运行中且可达（见 §4）
- [ ] `/opt/binance/secrets/prod.env` 已配置真实凭据，权限 `600`
- [ ] 开发机 Go 1.26.4 已安装

### 6.2 二进制部署（首选）

```bash
# 1. 交叉编译
cd /home/workspace/binance
make build-linux-amd64

# 2. 上传到 jp1
scp -i ~/.ssh/id_ed25519 bin/binance-server-linux-amd64 \
  claude@84.247.154.45:/opt/binance/bin/binance-server
scp -i ~/.ssh/id_ed25519 bin/binance-client-linux-amd64 \
  claude@84.247.154.45:/opt/binance/bin/binance-client

# 3. SSH 到 jp1
ssh -i ~/.ssh/id_ed25519 claude@84.247.154.45

# 4. 设置权限
chmod +x /opt/binance/bin/binance-server /opt/binance/bin/binance-client

# 5. 上传 systemd unit（首次部署）
sudo cp /tmp/binance-server.service /etc/systemd/system/
sudo cp /tmp/binance-client.service /etc/systemd/system/
sudo systemctl daemon-reload

# 6. 重启服务
sudo systemctl restart binance-server
sleep 5
sudo systemctl restart binance-client

# 7. 验证
curl http://127.0.0.1:8090/healthz
curl http://127.0.0.1:8081/admin/stats
curl http://127.0.0.1:8082/admin/stats
```

### 6.3 更新部署（迭代）

```bash
# 只需重新编译 + scp + restart
cd /home/workspace/binance
make build-linux-amd64

scp -i ~/.ssh/id_ed25519 bin/binance-server-linux-amd64 \
  claude@84.247.154.45:/opt/binance/bin/binance-server
scp -i ~/.ssh/id_ed25519 bin/binance-client-linux-amd64 \
  claude@84.247.154.45:/opt/binance/bin/binance-client

ssh -i ~/.ssh/id_ed25519 claude@84.247.154.45 \
  'chmod +x /opt/binance/bin/binance-server /opt/binance/bin/binance-client && \
   sudo systemctl restart binance-server && sleep 5 && \
   sudo systemctl restart binance-client'
```

### 6.4 目录结构（jp1）

```text
/opt/binance/
├── bin/
│   ├── binance-server          ← ~46M
│   └── binance-client          ← ~17M
├── secrets/
│   └── prod.env                ← chmod 600
└── logs/
    ├── server.log
    ├── server-error.log
    ├── client.log
    └── client-error.log
```

---

## 7. systemd 进程管理

### 7.1 binance-server.service

```ini
[Unit]
Description=binance Server — Market Data C/S (NATS consumer + Gin REST API)
After=network.target nats.service redis-server.service postgresql.service taosd.service
Wants=network.target

[Service]
Type=simple
User=claude
Group=claude
WorkingDirectory=/opt/binance
EnvironmentFile=/opt/binance/secrets/prod.env
Environment=FOUNDATIONX_BINANCE_ADMIN_ADDR=127.0.0.1:8081
ExecStart=/opt/binance/bin/binance-server
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
TimeoutStopSec=30
StandardOutput=append:/opt/binance/logs/server.log
StandardError=append:/opt/binance/logs/server-error.log
SyslogIdentifier=binance-server
MemoryHigh=3G
MemoryMax=4G
CPUQuota=200%
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 7.2 binance-client.service

```ini
[Unit]
Description=binance Client — Binance WS → NATS producer
After=network.target nats.service binance-server.service
Requires=binance-server.service

[Service]
Type=simple
User=claude
Group=claude
WorkingDirectory=/opt/binance
EnvironmentFile=/opt/binance/secrets/prod.env
Environment=FOUNDATIONX_BINANCE_ADMIN_ADDR=127.0.0.1:8082
ExecStart=/opt/binance/bin/binance-client
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
TimeoutStopSec=30
StandardOutput=append:/opt/binance/logs/client.log
StandardError=append:/opt/binance/logs/client-error.log
SyslogIdentifier=binance-client
MemoryHigh=384M
MemoryMax=512M
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### 7.3 关键设计决策

| 决策                                          | 原因                                                                                  |
| --------------------------------------------- | ------------------------------------------------------------------------------------- |
| `User=claude` 非 root                         | 最小权限原则                                                                          |
| `EnvironmentFile` + `Environment=` 共存       | `ADMIN_ADDR` 各 unit 不同，不能放 `prod.env`（否则 EnvironmentFile 覆盖 Environment） |
| `After=nats.service redis-server.service ...` | 确保依赖 infra 先启动                                                                 |
| `StandardOutput=append:...`                   | 日志持久化到文件，不依赖 journald                                                     |
| `LimitNOFILE=65536`                           | Binance WS 连接数高，需提高 fd 上限                                                   |

### 7.4 启动依赖链

```text
network.target → nats.service → binance-server.service → binance-client.service
                     redis-server.service ↗
                     postgresql.service ↗
                     taosd.service ↗
```

- server 必须先于 client 启动（client `Requires=binance-server.service`）

### 7.5 常用命令

```bash
# 查看状态
sudo systemctl status binance-server binance-client

# 查看日志（systemd journal）
sudo journalctl -u binance-server -f
sudo journalctl -u binance-client -f -n 100

# 查看日志（文件）
tail -f /opt/binance/logs/server.log
tail -f /opt/binance/logs/client.log

# 重启
sudo systemctl restart binance-server && sleep 5 && sudo systemctl restart binance-client

# 资源用量
systemctl show binance-server -p MemoryCurrent,CPUUsageNSec
```

---

## 8. 健康检查

### 8.1 端点

| 服务   | 端点                                                             | 用途                  | 预期                               |
| ------ | ---------------------------------------------------------------- | --------------------- | ---------------------------------- |
| server | `GET http://127.0.0.1:8090/healthz`                              | 存活检查（liveness）  | HTTP 200                           |
| server | `GET http://127.0.0.1:8090/metrics`                              | Prometheus 指标       | HTTP 200                           |
| server | `GET http://127.0.0.1:8090/readyz`                               | 就绪检查（readiness） | HTTP 200                           |
| server | `GET http://127.0.0.1:8081/admin/stats`                          | 服务统计              | JSON `{"accepted":N,"ingested":N}` |
| server | `GET http://127.0.0.1:8090/latest?symbol=BTCUSDT`                | 最新行情              | JSON 含 bid/ask/qty                |
| server | `GET http://127.0.0.1:8090/range?symbol=BTCUSDT&from=...&to=...` | 历史数据              | JSON 数组                          |
| client | `GET http://127.0.0.1:8082/admin/stats`                          | Client 统计           | JSON                               |

### 8.2 部署后验证

```bash
# 基础存活
curl -s http://127.0.0.1:8090/healthz | jq .

# 服务统计
curl -s http://127.0.0.1:8081/admin/stats | jq .
# 预期: {"accepted":N,"ingested":N}（ingested > 0 表示数据流入）

# 真实行情数据
curl -s 'http://127.0.0.1:8090/latest?symbol=BTCUSDT' | jq .
# 预期: bid/ask/qty 非零

# 进程存活
pgrep -a binance-server
pgrep -a binance-client

# 端口监听
ss -tlnp | grep -E '8090|808[12]'

# 磁盘使用率
df -h /opt
```

### 8.3 告警规则（alertmanager）

```yaml
# /home/workspace/binance/deploy/alertmanager/config.yml
route:
  group_by: ["alertname"]
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: "default" # → webhook → :9093
```

---

## 9. 回滚

### 9.1 二进制回滚

```bash
ssh -i ~/.ssh/id_ed25519 claude@84.247.154.45

# 1. 停止服务
sudo systemctl stop binance-client binance-server

# 2. 备份当前二进制（如需）
cp /opt/binance/bin/binance-server /opt/binance/bin/binance-server.bak.$(date +%Y%m%d%H%M%S)
cp /opt/binance/bin/binance-client /opt/binance/bin/binance-client.bak.$(date +%Y%m%d%H%M%S)

# 3. 恢复旧版本二进制
cp /opt/binance/bin/binance-server.bak.{旧时间戳} /opt/binance/bin/binance-server
cp /opt/binance/bin/binance-client.bak.{旧时间戳} /opt/binance/bin/binance-client

# 4. 启动
sudo systemctl start binance-server && sleep 5 && sudo systemctl start binance-client

# 5. 验证
curl http://127.0.0.1:8090/healthz
```

### 9.2 回滚前版本编译

在开发机上用 git checkout 到旧 commit 重新编译：

```bash
cd /home/workspace/binance
git checkout {旧 commit SHA}
make build-linux-amd64
scp bin/binance-server-linux-amd64 claude@84.247.154.45:/opt/binance/bin/binance-server
scp bin/binance-client-linux-amd64 claude@84.247.154.45:/opt/binance/bin/binance-client
```

### 9.3 CI 回滚演练

通过 GitHub Actions `workflow_dispatch` 触发：

```yaml
# ci-workflow.yaml → rollback-drill job
# 触发: workflow_dispatch + inputs.rollback_ref
# 产出: rollback-plan.md → artifacts
```

---

## 10. 凭据管理

### 10.1 Secrets 文件

```bash
# 模板
/home/workspace/binance/deploy/prod.env.example

# 部署到 jp1
scp prod.env.example claude@84.247.154.45:/opt/binance/secrets/prod.env
# 编辑真实凭据
ssh claude@84.247.154.45 "chmod 600 /opt/binance/secrets/prod.env"
```

### 10.2 必需凭据

| 环境变量                                      | 用途                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------ |
| **binance 运行时**                            |                                                                          |
| `FOUNDATIONX_BINANCE_MODE`                    | 运行模式（prod）                                                         |
| `FOUNDATIONX_BINANCE_GIN_ADDR`                | Gin API 监听地址（`:8090`）                                              |
| `FOUNDATIONX_BINANCE_REST_BASE_URL`           | Binance REST 端点                                                        |
| `FOUNDATIONX_BINANCE_UM_PERP_REST_BASE_URL`   | U 本位合约 REST 端点                                                     |
| `FOUNDATIONX_BINANCE_CM_PERP_REST_BASE_URL`   | 币本位合约 REST 端点                                                     |
| `FOUNDATIONX_BINANCE_OPTIONS_REST_BASE_URL`   | 期权 REST 端点                                                           |
| `FOUNDATIONX_BINANCE_ADMIN_TOKEN`             | Admin API 令牌                                                           |
| **PostgreSQL**                                |                                                                          |
| `FOUNDATIONX_POSTGRESX_HOST`                  | 主机（`127.0.0.1`）                                                      |
| `FOUNDATIONX_POSTGRESX_PORT`                  | 端口（`5432`）                                                           |
| `FOUNDATIONX_POSTGRESX_DATABASE`              | 库名（`market_binance`）                                                 |
| `FOUNDATIONX_POSTGRESX_USER`                  | 用户名                                                                   |
| `FOUNDATIONX_POSTGRESX_PASSWORD`              | 密码                                                                     |
| `FOUNDATIONX_POSTGRESX_SSLMODE`               | SSL 模式（`disable`）                                                    |
| **TDengine**                                  |                                                                          |
| `FOUNDATIONX_TAOSX_HOST`                      | 主机（`127.0.0.1`）                                                      |
| `FOUNDATIONX_TAOSX_ENDPOINT`                  | WebSocket 端点（`127.0.0.1:6041`）                                       |
| `FOUNDATIONX_TAOSX_PORT`                      | 端口（`6030`）                                                           |
| `FOUNDATIONX_TAOSX_DATABASE`                  | 库名（`market_binance`）                                                 |
| `FOUNDATIONX_TAOSX_USER`                      | 用户名                                                                   |
| `FOUNDATIONX_TAOSX_PASSWORD`                  | 密码                                                                     |
| **Redis**                                     |                                                                          |
| `FOUNDATIONX_REDISX_ADDR`                     | 地址（`127.0.0.1:6379`）                                                 |
| `FOUNDATIONX_REDISX_USERNAME`                 | 用户名（`default`）                                                      |
| `FOUNDATIONX_REDISX_PASSWORD`                 | 密码                                                                     |
| **NATS**                                      |                                                                          |
| `FOUNDATIONX_NATS_URL`                        | NATS URL（含凭据 `nats://user:pass@127.0.0.1:4222`）                     |
| `FOUNDATIONX_NATS_USERNAME`                   | 用户名                                                                   |
| `FOUNDATIONX_NATS_PASSWORD`                   | 密码                                                                     |
| **Kafka**                                     |                                                                          |
| `FOUNDATIONX_KAFKAX_BROKERS`                  | Broker 地址（`127.0.0.1:9092`）                                          |
| `FOUNDATIONX_KAFKAX_SASL_MECHANISM`           | SASL 机制（`PLAIN`，注：代码硬编码 PLAIN，此变量未被读取）               |
| `FOUNDATIONX_KAFKAX_SASL_USERNAME`            | SASL 用户名                                                              |
| `FOUNDATIONX_KAFKAX_SASL_PASSWORD`            | SASL 密码                                                                |
| `FOUNDATIONX_BINANCE_SKIP_KAFKA`              | **`1`=跳过 Kafka dispatch**（当前生产值 `1`，broker 不可达时的临时绕过；kafkax v1.1.2 已修复根因缺陷，broker 修复后应移除） |
| `FOUNDATIONX_BINANCE_CONSUMER_WORKERS`        | NATS 消费 worker 数（默认 `16`）                                         |
| `FOUNDATIONX_BINANCE_STALE_THRESHOLD_SECONDS` | stale 拒绝阈值（默认 `30`）                                              |
| **ClickHouse**                                |                                                                          |
| `FOUNDATIONX_CLICKHOUSEX_HOST`                | 主机（`127.0.0.1`）                                                      |
| `FOUNDATIONX_CLICKHOUSEX_PORT`                | 端口（`9000`）                                                           |
| `FOUNDATIONX_CLICKHOUSEX_DATABASE`            | 库名（`market_binance`）                                                 |
| `FOUNDATIONX_CLICKHOUSEX_USER`                | 用户名                                                                   |
| `FOUNDATIONX_CLICKHOUSEX_PASSWORD`            | 密码                                                                     |
| **Aliyun OSS**                                |                                                                          |
| `FOUNDATIONX_OSSX_ACCESS_KEY_ID`              | OSS AK                                                                   |
| `FOUNDATIONX_OSSX_ACCESS_KEY_SECRET`          | OSS SK                                                                   |
| `FOUNDATIONX_OSSX_BUCKET`                     | 桶名                                                                     |
| `FOUNDATIONX_OSSX_ENDPOINT`                   | 端点                                                                     |
| **OpenTelemetry**                             |                                                                          |
| `FOUNDATIONX_OTEL_ENDPOINT`                   | OTel HTTP 端点（`127.0.0.1:4318`）                                       |

### 10.3 ADMIN_ADDR 特殊处理

`FOUNDATIONX_BINANCE_ADMIN_ADDR` **不放在 `prod.env` 中**，因为：

- server 和 client 使用不同端口（8081 / 8082）
- systemd 的 `EnvironmentFile=` 会覆盖 `Environment=`

解决方案：各 systemd unit 独立设置 `Environment=`：

```ini
# binance-server.service
Environment=FOUNDATIONX_BINANCE_ADMIN_ADDR=127.0.0.1:8081

# binance-client.service
Environment=FOUNDATIONX_BINANCE_ADMIN_ADDR=127.0.0.1:8082
```

### 10.4 安全约束

- `prod.env` 必须 `chmod 600`，仅 owner 可读
- **绝不提交** `prod.env` 到 Git（已在 `.gitignore`）
- CI/CD 凭据通过 GitHub Secrets 注入
- 凭据在二进制外，通过 `EnvironmentFile` 注入

---

## 11. 运维操作

### 11.1 Canary 灰度部署

```bash
# 启动 canary 部署（K8s 环境自动灰度 30%，非 K8s 手动确认）
CANARY_TAG=v0.9.0 bash /home/workspace/binance/scripts/deploy-canary.sh
```

流程：

1. **Preflight** — 确认当前实例 `/healthz` 正常，rollback 资源可用
2. **启动 canary** — K8s: `kubectl set image` 灰度 30%；非 K8s: 手动启动新实例
3. **等待窗口** — 默认 300s（`CANARY_WINDOW_SECONDS`）
4. **Gate 检查** — 调用 `deploy-canary-gate.sh`，检查 `/readyz`、error-rate < 1%、consumer-lag < 阈值
5. **判定** — PASS → 全量 rollout；FAIL → 自动 rollback 并验证 `/healthz` 恢复

Canary gate 检查项（`deploy-canary-gate.sh`）：

| 检查项       | 方法                                                        | 阈值       |
| ------------ | ----------------------------------------------------------- | ---------- |
| `/readyz`    | `curl GET /readyz`                                          | HTTP 200   |
| error-rate   | `binance_ingest_requests_total{verdict="rejected"} / total` | < 1.0%     |
| consumer-lag | `binance_kafka_consumer_lag_messages`                       | < 10000 条 |

> ⚠️ Kafka 跳过时（`FOUNDATIONX_BINANCE_SKIP_KAFKA=1`）`consumer-lag` 指标不存在，canary gate 需跳过此项或标记为 N/A。

### 11.2 数据销毁演练

```bash
# DRY RUN（默认）
DRY_RUN=true RETENTION_DAYS=90 bash /home/workspace/binance/scripts/destruction-drill.sh

# 真实执行
DRY_RUN=false RETENTION_DAYS=90 bash /home/workspace/binance/scripts/destruction-drill.sh
```

流程：选择过期数据 → 不可逆销毁（OSS delete + TDengine DROP + PG DELETE）→ 生成证书 JSON → 归档到 OSS → 写入 audit_log。

### 11.3 生产就绪审计

```bash
bash /home/workspace/binance/scripts/readiness-audit.sh
```

检查项：`go.sum` 追踪、二进制不追踪、`.gitignore`、必需文件存在、Go 版本固定、README gate 状态、配置项完整性、runbook 引用链等。共 100+ 断言。

### 11.4 运行时证据收集

```bash
# 生成 release evidence package
bash /home/workspace/binance/scripts/runtime-release-evidence.sh
```

### 11.5 日志查看

```bash
# 文件日志（systemd StandardOutput=append）
tail -f /opt/binance/logs/server.log
tail -f /opt/binance/logs/client.log
tail -f /opt/binance/logs/server-error.log
tail -f /opt/binance/logs/client-error.log

# systemd journal
sudo journalctl -u binance-server --since "10 min ago"
sudo journalctl -u binance-client -S "2026-06-30 12:00:00"
```

### 11.6 资源限制

| 服务           | MemoryHigh | MemoryMax | CPUQuota | LimitNOFILE |
| -------------- | ---------- | --------- | -------- | ----------- |
| binance-server | 3G         | 4G        | 200%     | 65536       |
| binance-client | 384M       | 512M      | —        | 65536       |

```bash
# 实时资源用量
systemctl show binance-server -p MemoryCurrent,CPUUsageNSec
systemctl show binance-client -p MemoryCurrent,CPUUsageNSec
```

---

## 12. CI/CD 管线

### 12.1 机器池

| 阶段                                                                         | 池                  | 触发                |
| ---------------------------------------------------------------------------- | ------------------- | ------------------- |
| CI（preflight / build / test / lint / boundary / integration / secret-scan） | `sre/storage-light` | PR / push           |
| CD（release-preflight / publish / smoke）                                    | `sre/deploy`        | tag `v*`            |
| Rollback Drill                                                               | `sre/deploy`        | `workflow_dispatch` |

### 12.2 管线阶段

```text
PR / push to main:
  ci-preflight → [build │ test │ lint │ boundary │ integration │ secret-scan] → evidence

tag v* (在 evidence 通过后):
  release-preflight → release-publish → post-release-smoke
```

### 12.3 证据门禁

`evidence` job 生成 `ci-manifest.json` 并上传 CI evidence artifact。所有 CI job 必须在 release 前通过。

### 12.4 工作流文件

模板：`module/binance/ci-workflow.yaml` → 复制到 `github.com/ZoneCNH/binance/.github/workflows/ci.yml`

---

## 13. 已知部署 Bug 与修复

### 13.1 基础设施层面（I1-I10）

见 [§5 基础设施配置踩坑](#5-基础设施配置踩坑)。

### 13.2 代码层面（D1-D6）

以下 6 个代码级 Bug 在首次生产部署中发现并修复（PR [#358](https://github.com/ZoneCNH/binance/pull/358)）：

| #   | 症状                                   | 根因                                                                                                 | 修复                                                         |
| --- | -------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| D1  | TDengine tag 值错位                    | `renderPointInsert` 用 Go map 迭代 Tags 顺序非确定                                                   | 新增 `orderedTagKeys()` 按超表 schema 列顺序输出 TAGS        |
| D2  | partial depth 事件全零                 | `tickPayload` 缺 `bids`/`asks`/`lastUpdateId` 字段（`@depth20@100ms` 用 `bids`/`asks` 而非 `b`/`a`） | 添加字段 + `tickPoint` 回退逻辑                              |
| D3  | Market API `BNC_BACKEND_DOWN`          | `QueryRange` 用 `?` 参数化查询（taosWS 不支持）+ `.UTC()` 时区与 TDengine 本地时区不匹配             | 字符串插值 + `.Local()` 时区转换                             |
| D4  | Stats API `BNC_SERVICE_NOT_CONFIGURED` | `assemble.go` 未 wiring `Stats` provider                                                             | 新增 `ingestStatsProvider` adapter + `SnapshotStats()` 导出  |
| D5  | Client admin 端口冲突                  | systemd `EnvironmentFile=` 覆盖 `Environment=`                                                       | 从 `prod.env` 移除 `ADMIN_ADDR`，各 unit 独立 `Environment=` |
| D6  | Fields map 顺序随机                    | 同 D1 根因                                                                                           | field key 排序输出                                           |

### 13.3 taosx 库修复

taosx [PR #21](https://github.com/ZoneCNH/taosx/pull/21)（tag v1.0.3）修复了 `renderPointInsert` 中 tag/field 顺序非确定性问题。binance go.mod 引用 `taosx v1.0.3`。

### 13.4 Kafka producer 超时 → skip-kafka（commit 5f65211）

**症状**：生产环境 Kafka producer 超时，吞吐降至 1.6 events/s，NATS 积压 205,861 条，freshness 301,505ms。

**根因链**（代码证据见 `/home/workspace/binance` + `/home/workspace/kafkax`）：

| 层       | 根因                                                                                     | 位置                                                      |
| -------- | ---------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| 直接原因 | jp1 上 `127.0.0.1:9092` Kafka broker 未运行/不可达                                       | commit message: "broken Kafka broker"                     |
| 放大 1   | `segmentio/kafka-go` `Writer.WriteMessages` **同步阻塞**，等待 `RequiredAcks=All ISR`    | `kafkax/pkg/kafkax/kafkago/producer.go:68`                |
| 放大 2   | kafkax producer **全局互斥锁**串行化所有并发 Send（即使 16 worker 也只能一次发一条）     | `kafkax/pkg/kafkax/kafkago/producer.go:66-70`             |
| 放大 3   | `StrictDispatchHandoff=true`（修复前）将 Kafka dispatch 放在关键路径上，必须成功才能 ACK | `internal/server/assembly/dispatcher.go:99`（父 commit）  |
| 放大 4   | `Timeout=10s × MaxAttempts=3` + dispatch retry `[100ms,200ms,400ms]` = 单条最坏 **90s+** | `dispatcher.go:106,114` + `server.go:98-100`（父 commit） |
| 雪崩     | `AckWait=30s` < 90s 处理时间 → NATS 重新投递 → 积压雪崩                                  | `internal/server/consumer/consumer.go:24`                 |

**修复**（commit `5f65211`，6 项措施，吞吐 1.6/s → 915/s，572x）：

| 措施                        | 修改                                                                             | 位置                                           |
| --------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------- |
| skip-kafka                  | `FOUNDATIONX_BINANCE_SKIP_KAFKA=1` → dispatcher=nil，跳过 Kafka fanout           | `internal/server/assembly/dispatcher.go:49-52` |
| Kafka retry 收紧            | `MaxAttempts=1, Backoff=0, Timeout 10s→3s`（Kafka 启用但不健康时不再雪崩）       | `dispatcher.go:72-73,106`                      |
| dispatch retry 收紧         | `[100ms,200ms,400ms]` → `[0]`（单次尝试）                                        | `internal/server/server.go:98-100`             |
| StrictDispatchHandoff=false | Kafka 失败只记日志不阻塞 TDengine 写入                                           | `dispatcher.go:99`                             |
| Consumer worker pool        | 单 goroutine → 16 goroutines（`FOUNDATIONX_BINANCE_CONSUMER_WORKERS`）           | `internal/server/consumer/consumer.go`         |
| TDengine 连接池             | `MaxOpenConns 4→25, MaxIdleConns 2→10`，`WriteBatch` 改 `ExecContext` 消除 2 RTT | `internal/server/storage/`                     |

**skip-kafka 是临时绕过，非真正修复**。skip 后 dispatcher=nil，事件只写 TDengine，不进入 Kafka 下游广播。重新启用条件：

1. jp1 上启动 Kafka broker（`127.0.0.1:9092`，SASL PLAINTEXT/PLAIN）
2. 移除 `FOUNDATIONX_BINANCE_SKIP_KAFKA=1` 环境变量（位于 `/opt/binance/secrets/prod.env`）
3. kafkax v1.1.2 的防御性修改（producer 互斥锁拆分、3s timeout、单次尝试、`StrictDispatchHandoff=false`、HealthCheck broker 拨号、幂等配置强制 RequiredAcks=All）会保护系统在 broker 间歇性故障时不雪崩

**已修复的代码缺陷**（kafkax v1.1.2 + binance PR #359/#361）：

| 缺陷                                      | 修复版本         | 修复内容                                                      |
| ----------------------------------------- | ---------------- | ------------------------------------------------------------- |
| producer 全局互斥锁串行化 `WriteMessages` | kafkax v1.1.2    | 拆分锁，`WriteMessages` 不持锁，仅 `p.last` 访问受互斥锁保护  |
| `Idempotent: true` 被声明但完全忽略       | kafkax v1.1.2    | Idempotent 配置强制 `RequiredAcks=All`（kafka-go Writer 限制）|
| HealthCheck 不真正连接 broker             | kafkax v1.1.2    | HealthCheck 拨号 broker TCP，空 broker 保持兼容              |
| `SASL_MECHANISM` 环境变量未被代码读取     | kafkax v1.1.2 + binance #359 | Config 增加 `Mechanism` 字段，driver 读取并透传          |
| AlertDispatcher NATS publisher 为 nil     | binance #361     | `lazyNATSPublisher` 延迟绑定 NATS client，alerts 发布到 NATS |
| ReplayBridge 仅存储 job 无 worker         | binance #361     | 30s replay worker：Drain → 发布到 `binance.replay.requests` → MarkDone |

### 13.5 gap_detected=38272 — gap repair 机制

**症状**：`/admin/streams` 报告 `gap_detected=38272`（历史 gap，来自之前 purge/restart）。

**根因**：

- `gap_detected` 是 `qualityTracker` 中的**纯内存计数器**（`internal/server/quality.go:20,70`），进程重启归零
- purge/restart 后 `lastEventTime` / `lastSequence` map（`quality.go:18-19`）清空，重建 baseline 时业务序列号（trade_id 等）天然不连续，每条不连续触发 `gapDetected++`
- **这不是 NATS JetStream 消费者层面的 sequence gap**——NATS durable consumer（`consumer.go:20-29`，durable=`binance-server`，AckExplicit，AckWait=30s，MaxDeliver=5）本身不丢数据

**gap repair 机制现状**（binance #361/#362/#364 后更新）：

| 层面                            | 状态                          | 证据                                                            |
| ------------------------------- | ----------------------------- | --------------------------------------------------------------- |
| gap 检测                        | ✅ 完整                       | `quality.go:50-218`（sequence + event-time 双检测）             |
| gap 计数/metrics                | ✅ 完整                       | `quality.go:70`, `metrics.go:221-224`, `admin.go:255`           |
| AlertDispatcher                 | ✅ 已接线（NATS publisher + 5s timeout） | `assemble.go` — `lazyNATSPublisher` 延迟绑定 + `context.WithTimeout` |
| ReplayBridge                    | ✅ 已接线                     | `assemble.go` — `InMemoryReplayBridge` 实例化并注入             |
| Replay job worker               | ✅ 30s drain + NATS 发布      | `assemble.go` Run goroutine — Drain(64) → publish → MarkDone    |
| NATS 缺失消息请求               | ✅ 发布到 `binance.replay.requests` | replay worker 将 ReplayJob 作为 natsx Envelope 发布       |
| Server 侧 REST 回填             | ❌ 无代码（设计如此）         | server 不直接调 Binance REST，由 client 执行                    |
| Client 侧 gap-fill              | ✅ 自动触发（NATS 订阅）+ 无效区间跳过 | `runtime.go` — `GapAlertSubscriber` 订阅 → `QueueGapFill`（`startTime >= endTime` 跳过） |
| Repair re-publish               | ✅ RepairIngestor 回填再发布   | `history_lifecycle.go` — `republishBackfill` 以 `repair=verified` 元数据重新发布 |
| Stale gate 修复豁免             | ✅ repair=verified 豁免       | `server.go` — `SourceMetadata["repair"]=="verified"` 跳过 stale 检查 |
| Server↔Client 自动联动          | ✅ 完整闭环 + repair 验证     | server replay worker → NATS → client → QueueGapFill → REST fetch → RepairIngestor → server 豁免 stale → 存储 |
| durable historical fetch/replay | ✅ HistoryRuntime.RequestBackfill + RepairIngestor | `history_lifecycle.go` — HistoryFetcher async REST fetch → republishBackfill |
| Kline 存储路由                  | ✅ bar/kline 双匹配           | `taos_writer.go` — `toPoint`/`taosDeleteStable` 匹配 `"bar"` 和 `"kline"` |

**结论：38272 gap 为历史遗留。** gap 检测是纯观测性的，不阻塞处理（`quality.go:63-80` 在 `observe()` 内，事件仍正常接受/持久化/ACK）。server→client 自动联动已完整闭环：replay worker 30s drain → 发布到 `binance.replay.requests` → client 订阅 → 自动 `QueueGapFill` → lifecycle worker 30s drain（跳过零时长任务）→ `HistoryRuntime.RequestBackfill` → `HistoryFetcher.FetchHistorical` (REST，aggTrades 不传 interval 参数) → `RepairIngestor.Ingest`（`repair=verified` 元数据）→ server stale gate 豁免 → TDengine 存储持久化（kline→st_bar）。

**手动操作**：

1. **止血**：重启 binance-server，`gapDetected` 计数器归零（不修复已丢数据，仅清误报计数）
2. **回填已丢数据**：手动调用 client admin API `POST /api/v1/admin/backfill/gap-fill`（`internal/client/admin.go:114`），指定时间范围和 symbol 从 Binance REST 回填
3. **已实现（server）**：replay worker（30s drain + NATS 发布到 `binance.replay.requests`）+ AlertDispatcher NATS 发布（gap alert 到 `binance.alerts.runtime`）
4. **已实现（client 订阅）**：`GapAlertSubscriber` 订阅 `binance.replay.requests`，自动触发 `QueueGapFill`（`runtime.go` RunStandalone goroutine）
5. **已实现（client 执行）**：lifecycle worker 30s drain queued tasks（跳过零时长 `start >= end` 任务）→ `HistoryRuntime.RequestBackfill` → `HistoryFetcher.FetchHistorical` (REST) → `RepairIngestor.Ingest` 以 `repair=verified` 元数据重新发布 → server stale gate 豁免 → 存储

### 13.6 gap repair runtime bugs（commit f53303f，PR #364）

**症状**：gap repair 管线在首次端到端运行时发现 8 个运行时 bug，导致 NATS 发布超时、aggTrades REST 400、kline 事件未存储、stale gate 误拒回填事件、零时长任务空转等问题。

**修复**（commit `f53303f`，10 项措施）：

| #   | 症状                                       | 根因                                                                 | 修复                                                                        |
| --- | ------------------------------------------ | -------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| G1  | NATS 发布阻塞（lazyNATSPublisher 无超时）   | `lazyNATSPublisher.Publish` 直接透传 context，无超时保护              | 新增 `context.WithTimeout(ctx, 5s)` 防止单条发布阻塞                       |
| G2  | aggTrades REST 400 错误                     | `history_rest` 对所有 eventType 都传 `interval` 参数，aggTrades 不支持 | 仅 kline 类型传 `interval`，trade/aggTrade 不传                             |
| G3  | 零时长 gap 任务空转                         | `lifecycle_worker` 未检查 `EndTime <= StartTime`                     | `start >= end` 时直接标记完成跳过                                           |
| G4  | aggTrades JSON 解析失败                     | `history_rest` 用 `parseKlineArray` 解析 aggTrades 的 `[]object` 格式 | 新增 `parseAggTradeArray` 解析 aggTrades 响应                               |
| G5  | 回填事件未进入存储                         | `HistoryRuntime` fetch 完成后未重新发布到 ingest pipeline             | 新增 `RepairIngestor` 接口 + `republishBackfill` 以 `repair=verified` 发布 |
| G6  | Stale gate 误拒回填事件                    | `server.go` stale gate 对所有事件统一检查 `now.Sub(EventTime)`        | `SourceMetadata["repair"]=="verified"` 豁免 stale 检查                     |
| G7  | Kline 事件未写入 TDengine                  | `taos_writer.toPoint`/`taosDeleteStable` 仅匹配 `"bar"` 不匹配 `"kline"` | `"bar"` 和 `"kline"` 双匹配，路由到 `st_bar`                                |
| G8  | REST kline 数组未转换为事件对象             | `parseKlineArray` 直接 marshal 数组行，缺少 `e`/`E`/`k` 字段          | 转换为 `{e:"kline", E:openTime, k:{...}}` 对象格式                          |
| G9  | 无效 gap-fill（endTime <= startTime）      | `runtime.go` gap alert handler 未校验时间区间有效性                  | `startTime.Before(endTime)` 校验，无效区间跳过                              |
| G10 | KafkaConfig struct 字段未对齐（gofmt）      | `SASLMechanism` 字段对齐不一致                                        | gofmt 统一对齐                                                               |

**影响范围**：`history_lifecycle.go`、`history_rest.go`、`lifecycle_worker.go`、`runtime.go`、`server.go`、`assemble.go`、`taos_writer.go`、`config.go`（12 文件，+180/-24 行）。

---

## 参考

- 架构设计：[`../design/DESIGN.md`](../design/DESIGN.md)
- 数据流详解：`../design/DESIGN.md` §3
- 边界门禁：[`../gate/BOUNDARY-GATES.md`](../gate/BOUNDARY-GATES.md)
- 部署脚本源码：`/home/workspace/binance/deploy/`
- CI/CD 模板：[`../ci-workflow.yaml`](../ci-workflow.yaml)
- 审查报告：`/home/workspace/ZoneCNH/report/binance/REVIEW-20260630.md`
- 对齐总结：`/home/workspace/ZoneCNH/module/binance/evidence/2026-06-30/release/alignment-summary.md`
