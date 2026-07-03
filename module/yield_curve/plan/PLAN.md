# yield_curve 实施计划

- Module-Version: v0.1.0
- Last-Updated: 2026-07-03
- Status: Planned（Production Target）
- Runtime-Repo: `/home/workspace/yield_curve`
- Template-Reference: `module/binance`

## 1. 目标

把 `yield_curve` 建设为数据域 · 宏观的生产级独立 C/S 服务集群：子模块 `nominal_gilt`、`real_gilt`、`implied_inflation`、`ois`、`blc` 均可独立部署为 C/S 采集服务；统一复用共享基座组件，通过 `domain_macro` 输出领域语义；完成 `taos + kafka + postgres + Redis + oss + nats + clickhouse` 全链路持久化与分发。

## 2. 约束

| ID | 约束 |
| -- | ---- |
| C-001 | 不在 `module/yield_curve/` 或 `/home/workspace/yield_curve` 提交任何 secret 值。 |
| C-002 | 所有基础设施访问必须通过共享基座组件，不允许直连驱动绕过。 |
| C-003 | 各曲线子模块保持独立 C/S 进程边界。 |
| C-004 | NATS 负责 ingest/control，Kafka 负责 downstream durable event，不可混用。 |
| C-005 | 对外领域语义必须来自 `domain_macro`，不得暴露 provider DTO。 |
| C-006 | 每阶段完成后同步更新 `matrix/TRACEABILITY.md` 与验收证据。 |

## 3. 阶段 0：规格冻结与路由契约

| 项 | 内容 |
| -- | ---- |
| 输入 | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`module/binance/` 样板、`/home/workspace/yield_curve` 现状 |
| 任务 | 冻结采集清单、路由规则（latest/archive/BLC）、更新频率、历史起点、缓存 TTL |
| 输出 | 规格冻结、字段映射清单、端点覆盖表 |
| 验证 | `spec/SPEC.md` 中 §5.1~§5.5 与 `matrix/TRACEABILITY.md` 一致 |

## 4. 阶段 1：根骨架与边界门禁

| 项 | 内容 |
| -- | ---- |
| 任务 | 建立 `yc-{nominal,real,inflation,ois,blc}-{client,server}` 入口，统一 bootstrap/configx/observex 初始化 |
| 任务 | 更新 boundary gates：允许目标适配器经共享基座接入，禁止绕过基座 |
| 输出 | 子模块双服务可启动，配置缺失 fail-fast，边界脚本对齐目标架构 |
| 验证 | `go test ./...`、`bash scripts/boundary-gates.sh` |

## 5. 阶段 2：client 采集子模块

| 子模块 | 核心任务 | 同步策略落地 |
| ---- | ---- | ---- |
| `nominal_gilt` | latest + archive 拉取、spot/forward、standard/short 解析 | 日频 1h 增量、月度全量对账 |
| `real_gilt` | latest + archive 拉取、指标维度一致性 | 日频 1h 增量、月度全量对账 |
| `implied_inflation` | 从 nominal/real 联动构建与核验 | 日频 1h 增量、月度全量对账 |
| `ois` | OIS 曲线采集与历史分段拼接 | 日频 1h 增量、月度全量对账 |
| `blc` | archive-only 路由与月频采集 | 24h 增量、月度全量对账 |

## 6. 阶段 3：server 持久化与消息链路

| 介质/子系统 | 任务 |
| ---- | ---- |
| `nats` | durable consumer + control plane（reload/backfill/pause/resume） |
| `postgres` | catalog、source lineage、checkpoint、idempotency ledger |
| `taos` | 曲线点位时序写入与查询 |
| `Redis` | latest 24h / archive 30d 缓存、锁、限流桶 |
| `oss` | raw-first 原始 ZIP 与解包快照归档（hash + 路径规范） |
| `clickhouse` | 曲线分析读模型、期限利差宽表、可重建视图 |
| `kafka` | `YieldCurve*` 版本化 durable event |

验证：单个曲线子模块 backfill 完成后，必须证明 raw、metadata、timeseries、cache、read model、event 全链路写入成功，且失败时可重放恢复。

## 7. 阶段 4：API 与宏观分析契约

| 项 | 内容 |
| -- | ---- |
| API | `QueryCurve`、`QuerySpread`、`QueryBreakeven`、`GetCatalogCoverage`、`StartBackfill`、`GetJobStatus`、`ReloadConfig` |
| 分析契约 | 输出 slope/curvature、10Y-2Y、5y5y、breakeven、跨市场利差等衍生字段 |
| 验证 | contract tests、no-lookahead 回归、跨源对账（BoE vs FRED/UST） |

## 8. 阶段 5：集成验收与发布前闭环

| 项 | 内容 |
| -- | ---- |
| 测试 | 单元、契约、边界、集成、回放一致性、质量审计 |
| 调度 | daily `<24h`、monthly `<72h`，路由规则稳定 |
| 同步 | 增量为主，手动全量重同步可用；每月至少 1 次全量兜底；单轮同步目标 `<=30min` |
| 文档 | 更新 traceability/acceptance 状态与验证证据 |
| 发布门禁 | 无 secret 泄露、边界门禁通过、七类介质职责有测试证据 |

## 9. 推荐任务拆分

| Task | 范围 | 依赖 |
| ---- | ---- | ---- |
| TASK-YC-001 | 根骨架、5 个子模块 C/S、路由与解析、全链路持久化、API、验收闭环 | 阶段 0 |

## 10. 完成判定

只有当 `matrix/TRACEABILITY.md` 中 FR/BR/AC/TC 从 `Planned` 变为已验证状态，且 `/home/workspace/yield_curve` 的测试、边界脚本和配置 redaction 检查通过，才能声明 `yield_curve` 目标完成。

