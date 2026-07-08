# RULES.md 提案草稿

> **状态**：提案（待审批后移至 `module/fred/RULES.md`）  
> **来源**：2026-07-08 深度分析报告 — 工程层建议  
> **授权要求**：创建模块专属规范文件须经治理层审批

---

## 背景

fred 模块具有以下独特工程属性，超出通用治理规范的覆盖范围，需要专属规则：

1. 双服务 C/S 架构 + NATS handoff 进程间契约演化
2. 七类持久化职责与容错写入顺序
3. 外部路由序列（source_component）的清单维护
4. 无前视语义（available_at/released_at/vintage_at 三时间戳不变式）
5. ms_brain 下游契约变更通知协议

---

## §1 进程边界不变式

- fred-client 和 fred-server 是独立进程，禁止直接函数调用
- 唯一通信通道：NATS JetStream（ingest/control）
- fred-client 禁止 import `fred/internal/server/*`
- fred-server 禁止直接调用 FRED API，所有数据通过 NATS 接收

---

## §2 持久化写入顺序规则（raw-first 守恒律）

每次 observation 写入必须严格按以下顺序执行，违反顺序视为违规：

```
1. OSS raw 归档（含路径 hash）
2. Postgres checkpoint 推进
3. TDengine observation 写入
4. Redis 缓存更新（可重建层）
5. ClickHouse 分析读模型（可重建层）
6. Kafka durable event 发布
```

幂等键五元组：`(series_id, vintage_at, released_at, available_at, source_component)` — 任何写入必须携带完整五元组。

---

## §3 无前视查询不变式（available_at 闸门）

- 所有 API 查询必须通过 `IsVisibleAt(t time.Time)` 过滤
- 禁止在查询结果中暴露 `available_at > query_time` 的观测值
- 外部路由序列（ECB/BoJ 等）降级为仅 `available_at` 过滤，不做 vintage 断言
- 违反此规则的 PR 自动 block

---

## §4 外部路由序列清单维护规程

- 外部路由序列在 `spec/SERIES-CATALOG.md §11` 维护权威清单
- 每个外部路由序列必须声明：`source_component`、`authority`、`domain_macro 落点`
- 新增外部路由序列须经 spec review，不得在代码中直接添加
- `source_component` 路由判定逻辑集中在 `internal/domain/source_router.go`，禁止在其他位置散落

---

## §5 NATS/Kafka 职责分层不可逾越条款

| 消息类型 | 通道 | 不可逾越 |
|---|---|---|
| ingest handoff（client→server）| NATS JetStream | 禁止改用 Kafka |
| control 信号（admin 触发）| NATS JetStream | 禁止改用 HTTP/RPC |
| durable business event（下游消费）| Kafka | 禁止改用 NATS |
| cache/rate bucket | Redis | 禁止改用内存 |

---

## §6 cs.IngestEnvelope 契约变更协议

- **minor bump**（新增可选字段）：backward compatible，仅更新 `cs.Version`
- **major bump**（删除/重命名必填字段）：必须新建 ADR，发布前通知 ms_brain 维护者，提供 2 周迁移窗口
- schema 版本变更必须同步更新 `schema/README.md` 中的版本演化历史

---

## §7 ms_brain 下游契约变更通知规程

1. 任何影响 ms_brain 消费接口的变更（`MacroDataPoint` 字段、API response schema）须提前 2 周通知
2. 变更必须在 `spec/SPEC.md §15` 依赖表中更新版本要求
3. `TASK-FRED-SERVER-003` 集成验收 Task 须确认 ms_brain 消费契约不受破坏

---

## §8 覆盖率与 Gate 最低阈值

| 包/组件 | 最低覆盖率 | 硬 Gate |
|---|---|---|
| `internal/client` | ≥ 90% | 是 |
| `internal/server` | ≥ 85% | 是 |
| `pkg/fredx` | ≥ 85% | 是 |
| `internal/cs` | ≥ 95% | 是 |
| `cmd/*` | ≥ 50% | 是 |
| boundary-gates | 0 failed | 是 |
| secret-scan | 0 findings | 是 |

---

## §9 evidence 归档义务

每个 Release 版本必须在 `evidence/{YYYY-MM-DD}/` 下包含四个子目录：

```
test/          — 单元测试和 boundary gate 日志
review/        — 代码审查结论（BG-001..013 逐条）
release/       — 发布门禁结果
retrospective/ — 风险复盘（OPEN item 状态更新）
```

缺少任意子目录视为 Release DoD 未满足。

---

## §10 ADR 触发条件

以下情况必须新建 ADR 后才能合入 main：

1. 更换任何持久化介质（如从 TDengine 迁移到 InfluxDB）
2. 变更进程间通信协议（如 NATS → gRPC）
3. 新增外部路由数据源（超过 10 个系列）
4. `cs.IngestEnvelope` major version bump
5. 变更认证/鉴权机制（如 API key → mTLS）
6. 更改双服务 C/S 架构为其他架构模式

---

## 附：建议文件位置

创建此文件后：

1. 在 `design/DESIGN.md` L1 添加引用：`> 模块专属规范见 [RULES.md](../RULES.md)`
2. 在 `gate/BOUNDARY-GATES.md` 顶部添加引用：`> 完整规则见 [RULES.md](../RULES.md)`
3. 在 `spec/SPEC.md §20 CI 门禁` 末尾引用：`> 覆盖率阈值和 Gate 定义见 RULES.md §8`

---

> [RULES I BROKE]：无  
> [COMPUTED, HIGH] 本草稿基于 2026-07-08 深度分析报告，引用具体文件内容和行号。最终生效须经治理层审批。
