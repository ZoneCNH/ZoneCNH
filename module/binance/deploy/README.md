# module/binance 部署文档

- Spec-Version: v4.1.0
- Runtime-Version: v0.15.0（anchor: `/home/workspace/binance@main`）
- Target: jp1 (84.247.154.45)
- Last-Updated: 2026-07-08

## 文档索引

| 文档 | 用途 |
|------|------|
| [`DEPLOY.md`](DEPLOY.md) | 二进制构建、部署流程、systemd 管理、回滚、运维操作（单文件全流程） |

## 部署架构速览

```text
┌─ 开发机 (交叉编译) ─────────────────────────────────────────┐
│  make build-linux-amd64                                     │
│  → bin/binance-server-linux-amd64  (46M)                    │
│  → bin/binance-client-linux-amd64  (17M)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ scp
                           ▼
┌─ jp1 (84.247.154.45) ──────────────────────────────────────┐
│  /opt/binance/                                              │
│  ├─ bin/               ← 二进制文件                          │
│  │   ├─ binance-server                                     │
│  │   └─ binance-client                                     │
│  ├─ secrets/prod.env   ← 敏感凭据（chmod 600）              │
│  └─ logs/              ← 日志文件                            │
│                                                             │
│  systemd:                                                    │
│  ├─ binance-server.service  (GIN :8090, admin 127.0.0.1:8081, MemoryMax 4G)  │
│  └─ binance-client.service  (admin 127.0.0.1:8082, MemoryMax 512M, after=server) │
│                                                             │
│  外部 infra（host network 直连 127.0.0.1）:                  │
│  ┌──────────┬──────────┬───────────┬──────────┬──────────┐ │
│  │ NATS     │ Redis    │ PostgreSQL│ TDengine │ Kafka    │ │
│  │ :4222    │ :6379    │ :5432     │ :6030    │ :9092    │ │
│  ├──────────┼──────────┼───────────┼──────────┼──────────┤ │
│  │ClickHouse│ CH-Keeper│ Jaeger    │ Grafana  │ OTel     │ │
│  │ :9000    │ :9181    │ :16686    │ :3000    │ :4318    │ │
│  └──────────┴──────────┴───────────┴──────────┴──────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 关键制品归属

| 制品 | 位置 | 说明 |
|------|------|------|
| Makefile | `/home/workspace/binance/Makefile` | 含 `build-linux-amd64` / `build-linux-arm64` 交叉编译目标 |
| systemd units | `/etc/systemd/system/binance-{server,client}.service` | jp1 上 systemd 进程管理 |
| secrets 模板 | `/home/workspace/binance/deploy/prod.env.example` | 凭据注入模板 |
| Dockerfile（可选） | `/home/workspace/binance/Dockerfile` | 多阶段构建，distroless 运行时（可选方案） |
| docker-compose（可选） | `/home/workspace/binance/deploy/docker-compose.prod.yml` | Docker 编排（可选方案） |
| alertmanager | `/home/workspace/binance/deploy/alertmanager/config.yml` | 告警路由 |
| CI/CD 模板 | [`../ci-workflow.yaml`](../ci-workflow.yaml) | GitHub Actions 工作流 |
| 数据销毁 | `/home/workspace/binance/scripts/destruction-drill.sh` | 数据不可逆销毁演练 |
| Canary 部署 | `/home/workspace/binance/scripts/deploy-canary.sh` | 灰度部署 + gate 检查 |
| Canary Gate | `/home/workspace/binance/scripts/deploy-canary-gate.sh` | /readyz + error-rate + consumer-lag |
| 就绪审计 | `/home/workspace/binance/scripts/readiness-audit.sh` | 生产就绪检查 |

## 快速链接

- 架构设计：[`../design/DESIGN.md`](../design/DESIGN.md)
- 边界门禁：[`../gate/BOUNDARY-GATES.md`](../gate/BOUNDARY-GATES.md)
- 运维门禁：[`../gate/OPERATIONS.md`](../gate/OPERATIONS.md)
- 安全门禁：[`../gate/SECURITY.md`](../gate/SECURITY.md)
- Goal：[`../goal/goal.md`](../goal/goal.md)
