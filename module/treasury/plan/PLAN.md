# treasury 实施计划

- Module-Version: v0.2.0
- Last-Updated: 2026-07-03
- Status: Planned（Production Target）
- Runtime-Repo: `/home/workspace/treasury`
- Template-Reference: `module/binance`

## 1. 目标

把 `treasury` 建设为数据域 · 宏观的生产级独立 C/S 服务集群：子模块 `yield`、`auction`、`fiscal`、`tic` 均可独立部署为 C/S 采集服务；统一复用共享基座组件，通过 `domain_macro` 输出领域语义；完成 `taos + kafka + postgres + Redis + oss + nats + clickhouse` 全链路持久化与分发。

## 2. 约束

| ID | 约束 |
| -- | ---- |
| C-001 | 不在 `module/treasury/` 或 `/home/workspace/treasury` 提交任何 secret 值。 |
| C-002 | 所有基础设施访问必须通过共享基座组件，不允许直连驱动绕过。 |
| C-003 | 各采集子模块保持独立 C/S 进程边界，禁止 client/server 进程内耦合。 |
| C-004 | NATS 负责 ingest/control，Kafka 负责 downstream durable event，不可混用。 |
| C-005 | 对外领域语义必须来自 `domain_macro`，不得暴露 provider DTO。 |
| C-006 | 每阶段完成后同步更新 `matrix/TRACEABILITY.md` 与验收证据。 |

## 3. 阶段 0：规格冻结与数据源契约

| 项 | 内容 |
| -- | ---- |
| 输入 | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`module/binance/` 样板、`/home/workspace/treasury` 现状 |
| 任务 | 冻结采集清单、更新频率、同步周期、历史起点、修订回拉窗口（含 Debt/Revenue/FX 分类） |
| 输出 | 规格冻结、字段映射清单、端点覆盖表 |
| 验证 | `spec/SPEC.md` 中 §5.1~§5.4 与 `matrix/TRACEABILITY.md` 一致 |

## 4. 阶段 1：根骨架与边界门禁

| 项 | 内容 |
| -- | ---- |
| 任务 | 建立 `treasury-{yield,auction,fiscal,tic}-{client,server}` 入口，统一 bootstrap/configx/observex 初始化 |
| 任务 | 更新 boundary gates：允许目标适配器经共享基座接入，禁止绕过基座 |
| 输出 | 子模块双服务可启动，配置缺失 fail-fast，边界脚本对齐目标架构 |
| 验证 | `go test ./...`、`bash scripts/boundary-gates.sh` |

## 5. 阶段 2：client 采集子模块

| 子模块 | 核心任务 | 同步策略落地 |
| ---- | ---- | ---- |
| `yield` | 收益率曲线采集、期限结构标准化、发布窗口轮询 | 每交易日 + 15min 发布窗口轮询，月度全量对账 |
| `auction` | 拍卖日历、公告、结果采集与状态机 | 拍卖日 10min，非拍卖日日频巡检，周度对账 |
| `fiscal` | DTS/MTS + Debt/Revenue/FX 采集与财政流量标准化 | DTS 小时级，MTS 发布后 4h 内，月度对账 |
| `tic` | TIC 月度持仓/净流入采集与版本化 | 发布周 6h，其余日频，月度对账 |

## 6. 阶段 3：server 持久化与消息链路

| 介质/子系统 | 任务 |
| ---- | ---- |
| `nats` | durable consumer + control plane（reload/backfill/pause/resume） |
| `postgres` | catalog、release calendar、checkpoint、idempotency ledger |
| `taos` | yield/fiscal 高频时序写入与查询 |
| `Redis` | 分布式锁、rate bucket、热缓存、短游标 |
| `oss` | raw-first 原始载荷归档（hash + 路径规范） |
| `clickhouse` | 宏观分析读模型、横截面宽表、可重建视图 |
| `kafka` | `Treasury*` 版本化 durable event |

验证：单个子模块 backfill 完成后，必须证明 raw、metadata、timeseries、cache、read model、event 全链路写入成功，且失败时可重放恢复。

## 7. 阶段 4：API 与宏观分析契约

| 项 | 内容 |
| -- | ---- |
| API | `QueryYieldCurve`、`QueryAuction`、`QueryFiscalFlow`、`QueryTIC`、`GetCatalogCoverage`、`StartBackfill`、`GetJobStatus`、`ReloadConfig` |
| 分析契约 | 输出期限利差、真实利率、供给压力、海外需求、财政脉冲等基础衍生字段 |
| 验证 | contract tests、no-lookahead 回归、跨源对账（Treasury vs FRED 交叉锚点） |

## 8. 阶段 5：集成验收与发布前闭环

| 项 | 内容 |
| -- | ---- |
| 测试 | 单元、契约、边界、集成、回放一致性、质量审计 |
| 调度 | 日频 ≤24h、月频 ≤48h、发布触发优先（ET 16:00 窗口）+ 定时轮询兜底 |
| 同步 | 增量为主，手动全量重同步可用；每月至少 1 次全量兜底；单轮同步目标 ≤30min |
| 文档 | 更新 traceability/acceptance 状态与验证证据 |
| 发布门禁 | 无 secret 泄露、边界门禁通过、七类介质职责有测试证据 |

## 9. 推荐任务拆分

| Task | 范围 | 依赖 |
| ---- | ---- | ---- |
| TASK-TRY-001 | 根骨架、4 个子模块 C/S、全链路持久化、API、验收闭环 | 阶段 0 |

## 10. 完成判定

只有当 `matrix/TRACEABILITY.md` 中 FR/BR/AC/TC 从 `Planned` 变为已验证状态，且 `/home/workspace/treasury` 的测试、边界脚本和配置 redaction 检查通过，才能声明 `treasury` 目标完成。
