# module/binance 部署文档

- Spec-Version: v3.9.6
- Runtime-Version: v0.8.0（anchor: `/home/binance@b2d9d83`）
- Target: jp1 (84.247.154.45)
- Last-Updated: 2026-06-30

## 文档索引

| 文档 | 用途 |
|------|------|
| [`DEPLOY.md`](DEPLOY.md) | 二进制构建、Docker 打包、部署流程、回滚、运维操作（单文件全流程） |

## 部署架构速览

```text
┌─ GitHub Actions CI/CD ─────────────────────────────────────┐
│  sre/storage-light (CI)          sre/deploy (CD)            │
│  build → test → lint → boundary  release → publish → smoke │
│  → evidence → gate                                          │
└──────────────────────────┬──────────────────────────────────┘
                           │ ghcr.io/zonecnh/binance:{tag}
                           ▼
┌─ jp1 (84.247.154.45) ──────────────────────────────────────┐
│  /opt/binance/                                              │
│  ├─ current/          ← docker-compose.yml symlink          │
│  ├─ releases/{tag}/   ← 版本化部署目录                      │
│  ├─ backups/          ← 回滚备份                            │
│  └─ secrets/prod.env  ← 敏感凭据（gitignored）              │
│                                                             │
│  systemd:                                                    │
│  ├─ binance-server.service  (Gin :8080, memory 4G)          │
│  └─ binance-client.service  (memory 512M, after=server)     │
│                                                             │
│  外部 infra（镜像外，host network 直连）:                    │
│  ┌──────────┬──────────┬───────────┬──────────┬──────────┐ │
│  │ NATS     │ Redis    │ PostgreSQL│ TDengine │ Kafka    │ │
│  │ :4222    │ :6379    │ :5432     │ :6030    │ :9092    │ │
│  ├──────────┼──────────┴───────────┴──────────┴──────────┤ │
│  │ClickHouse│ OSS (Aliyun)                                │ │
│  │ :9000    │ oss-cn-hangzhou.aliyuncs.com                │ │
│  └──────────┴─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 关键制品归属

| 制品 | 位置（运行时仓） | 说明 |
|------|-----------------|------|
| Dockerfile（合并构建） | `/home/binance/Dockerfile` | 多阶段构建，distroless 运行时 |
| Dockerfile.client | `/home/binance/Dockerfile.client` | client 独立镜像 |
| Dockerfile.server | `/home/binance/Dockerfile.server` | server 独立镜像 |
| docker-compose | `/home/binance/deploy/docker-compose.prod.yml` | 生产编排 |
| systemd units | `/home/binance/deploy/binance-{client,server}.service` | 进程管理 |
| deploy.sh | `/home/binance/deploy/deploy.sh` | 一键部署脚本 |
| health-check.sh | `/home/binance/deploy/health-check.sh` | 部署后验证 |
| secrets 模板 | `/home/binance/deploy/prod.env.example` | 凭据注入模板 |
| alertmanager | `/home/binance/deploy/alertmanager/config.yml` | 告警路由 |
| CI/CD 模板 | [`../ci-workflow.yaml`](../ci-workflow.yaml) | GitHub Actions 工作流 |
| 数据销毁 | `/home/binance/scripts/destruction-drill.sh` | 数据不可逆销毁演练 |
| Canary 部署 | `/home/binance/scripts/deploy-canary.sh` | 灰度部署 + gate 检查 |
| Canary Gate | `/home/binance/scripts/deploy-canary-gate.sh` | /readyz + error-rate + consumer-lag |
| 就绪审计 | `/home/binance/scripts/readiness-audit.sh` | 生产就绪检查 |

## 快速链接

- 架构设计：[`../design/DESIGN.md`](../design/DESIGN.md)
- 边界门禁：[`../gate/BOUNDARY-GATES.md`](../gate/BOUNDARY-GATES.md)
- 运维门禁：[`../gate/OPERATIONS.md`](../gate/OPERATIONS.md)
- 安全门禁：[`../gate/SECURITY.md`](../gate/SECURITY.md)
- Goal：[`../goal/goal.md`](../goal/goal.md)
