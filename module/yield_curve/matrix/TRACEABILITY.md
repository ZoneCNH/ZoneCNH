# yield_curve 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-07-03  
Source: [spec/SPEC.md](../spec/SPEC.md) v0.1.0 | Goal: GOAL-YC-001 | Status: Planned（Production Target）

---

## Goal 到需求

| Goal / SC | FR | BR | AC | TC |
| --------- | -- | -- | -- | -- |
| G-SC-001 子模块独立 C/S | FR-YC-001, FR-YC-013, FR-YC-015 | BR-YC-001, BR-YC-004 | AC-YC-001, AC-YC-007, AC-YC-009 | TC-YC-006, TC-YC-007 |
| G-SC-002 共享基座与不泄密 | FR-YC-002 | BR-YC-008 | AC-YC-002, AC-YC-009 | TC-YC-007 |
| G-SC-003 领域归一化 | FR-YC-004, FR-YC-012 | BR-YC-002 | AC-YC-003, AC-YC-007 | TC-YC-001, TC-YC-010 |
| G-SC-004 七类介质落地 | FR-YC-012~015 | BR-YC-005, BR-YC-006, BR-YC-007 | AC-YC-007 | TC-YC-006, TC-YC-008 |
| G-SC-005 路由与同步闭环 | FR-YC-006~011, FR-YC-016 | BR-YC-009, BR-YC-010 | AC-YC-004~006, AC-YC-008 | TC-YC-002~005, TC-YC-009 |
| G-SC-007 宏观分析补充 | FR-YC-015, FR-YC-016 | BR-YC-010 | AC-YC-010 | TC-YC-010 |

---

## §1 功能需求追溯（FR）

| FR | 需求摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| FR-YC-001 | 五子模块 client/server 独立启动 | AC-YC-001 | TC-YC-006, TC-YC-007 | TASK-YC-001 | Planned |
| FR-YC-002 | 配置通过共享组件加载且不泄密 | AC-YC-002 | TC-YC-007 | TASK-YC-001 | Planned |
| FR-YC-003 | 五类曲线采集覆盖 | AC-YC-003 | TC-YC-001 | TASK-YC-001 | Planned |
| FR-YC-004 | spot/forward + standard/short 双维度 | AC-YC-003 | TC-YC-001 | TASK-YC-001 | Planned |
| FR-YC-005 | daily/monthly 双频输出 | AC-YC-003 | TC-YC-001 | TASK-YC-001 | Planned |
| FR-YC-006 | latest 路径采集 | AC-YC-004 | TC-YC-002 | TASK-YC-001 | Planned |
| FR-YC-007 | archive 路径采集 | AC-YC-004 | TC-YC-002 | TASK-YC-001 | Planned |
| FR-YC-008 | BLC 归档强制路由 | AC-YC-004 | TC-YC-002 | TASK-YC-001 | Planned |
| FR-YC-009 | source/source_url/fetched_at 审计 | AC-YC-005 | TC-YC-003 | TASK-YC-001 | Planned |
| FR-YC-010 | 多工作簿拼接 | AC-YC-006 | TC-YC-004 | TASK-YC-001 | Planned |
| FR-YC-011 | 旧版布局兼容解析 | AC-YC-006 | TC-YC-005 | TASK-YC-001 | Planned |
| FR-YC-012 | raw-first + taos/postgres 写入 | AC-YC-007 | TC-YC-006 | TASK-YC-001 | Planned |
| FR-YC-013 | NATS/Kafka 双总线分层 | AC-YC-007 | TC-YC-007 | TASK-YC-001 | Planned |
| FR-YC-014 | Redis 缓存与协调（24h/30d） | AC-YC-007 | TC-YC-008 | TASK-YC-001 | Planned |
| FR-YC-015 | ClickHouse 读模型 + 查询 API | AC-YC-007, AC-YC-010 | TC-YC-006, TC-YC-010 | TASK-YC-001 | Planned |
| FR-YC-016 | 增量/全量/重同步 + 缺口重采 | AC-YC-008, AC-YC-010 | TC-YC-009, TC-YC-010 | TASK-YC-001 | Planned |

---

## §2 业务规则追溯（BR）

| BR | 规则摘要 | AC | TC ID(s) | Task | 状态 |
| -- | -------- | -- | -------- | ---- | ---- |
| BR-YC-001 | 子模块独立 C/S 边界 | AC-YC-009 | TC-YC-007 | TASK-YC-001 | Planned |
| BR-YC-002 | `available_at` no-lookahead 约束 | AC-YC-003, AC-YC-010 | TC-YC-010 | TASK-YC-001 | Planned |
| BR-YC-003 | 同键写入幂等 | AC-YC-007 | TC-YC-006 | TASK-YC-001 | Planned |
| BR-YC-004 | NATS/Kafka 分层 | AC-YC-007 | TC-YC-007 | TASK-YC-001 | Planned |
| BR-YC-005 | checkpoint 先于 completed | AC-YC-007 | TC-YC-006 | TASK-YC-001 | Planned |
| BR-YC-006 | Redis/ClickHouse 可重建 | AC-YC-007 | TC-YC-008 | TASK-YC-001 | Planned |
| BR-YC-007 | OSS raw 路径可审计 | AC-YC-007 | TC-YC-006 | TASK-YC-001 | Planned |
| BR-YC-008 | 下游契约边界 | AC-YC-002, AC-YC-009 | TC-YC-007 | TASK-YC-001 | Planned |
| BR-YC-009 | latest/archive/BLC 路由可审计 | AC-YC-004, AC-YC-005 | TC-YC-002, TC-YC-003 | TASK-YC-001 | Planned |
| BR-YC-010 | 历史起点与同步模式可审计 | AC-YC-008, AC-YC-010 | TC-YC-009, TC-YC-010 | TASK-YC-001 | Planned |

---

## §3 非功能需求追溯（NFR）

| NFR | 类别 | Requirement | Task | 状态 |
| --- | ---- | ----------- | ---- | ---- |
| NFR-YC-001 | Freshness | daily `<24h`，monthly `<72h` | TASK-YC-001 | Planned |
| NFR-YC-002 | Latency | 单轮同步 `<=30min` | TASK-YC-001 | Planned |
| NFR-YC-003 | Throughput | 多曲线并行回补不互阻 | TASK-YC-001 | Planned |
| NFR-YC-004 | Reliability | 失败不推进 checkpoint，可回放 | TASK-YC-001 | Planned |
| NFR-YC-005 | Observability | source/path/cache/replay 指标闭合 | TASK-YC-001 | Planned |
| NFR-YC-006 | Security | secret redaction 通过 | TASK-YC-001 | Planned |
| NFR-YC-007 | Governance | 覆盖率与缺口任务可追溯 | TASK-YC-001 | Planned |

---

## §4 TC→FR 反向追溯

| TC | 覆盖需求 | 目标命令 |
| -- | -------- | -------- |
| TC-YC-001 | FR-YC-003~005 | `go test ./internal/client/... -run CurveCollector` |
| TC-YC-002 | FR-YC-006~008, BR-YC-009 | `go test ./internal/client/... -run RouteSelector` |
| TC-YC-003 | FR-YC-009 | `go test ./internal/server/... -run SourceAudit` |
| TC-YC-004 | FR-YC-010 | `go test ./internal/client/... -run WorkbookStitch` |
| TC-YC-005 | FR-YC-011 | `go test ./internal/client/... -run LegacyLayout` |
| TC-YC-006 | FR-YC-012, FR-YC-015, BR-YC-003, BR-YC-005 | `go test ./internal/integration/... -run StoragePipeline` |
| TC-YC-007 | FR-YC-001, FR-YC-013, BR-YC-001, BR-YC-004, BR-YC-008 | `bash scripts/boundary-gates.sh` |
| TC-YC-008 | FR-YC-014, BR-YC-006 | `go test ./internal/server/... -run CacheTTL` |
| TC-YC-009 | FR-YC-016, BR-YC-010 | `go test ./internal/integration/... -run ReSync` |
| TC-YC-010 | FR-YC-015, FR-YC-016, BR-YC-002, AC-YC-010 | `go test ./internal/analytics/... -run MacroDerived` |

---

## §5 全局 AC 注册表

| AC | 验收摘要 | 覆盖需求 | 状态 |
| --- | --- | --- | --- |
| AC-YC-001 | 五子模块独立双服务启动 | FR-YC-001 | Planned |
| AC-YC-002 | 配置不泄密 | FR-YC-002, BR-YC-008 | Planned |
| AC-YC-003 | 曲线清单覆盖完整 | FR-YC-003~005, BR-YC-002 | Planned |
| AC-YC-004 | latest/archive/BLC 路由正确 | FR-YC-006~008, BR-YC-009 | Planned |
| AC-YC-005 | source 审计字段完整 | FR-YC-009 | Planned |
| AC-YC-006 | 拼接与兼容解析通过 | FR-YC-010, FR-YC-011 | Planned |
| AC-YC-007 | raw-first + 多存储链路闭合 | FR-YC-012~015 | Planned |
| AC-YC-008 | 同步与重采闭环 | FR-YC-016, BR-YC-010 | Planned |
| AC-YC-009 | 边界门禁通过 | BR-YC-001, BR-YC-008 | Planned |
| AC-YC-010 | 宏观分析补充项可用 | FR-YC-015, FR-YC-016 | Planned |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 16 | 0 | 0% |
| BR | 10 | 0 | 0% |
| NFR | 7 | 0 | 0% |
| AC | 10 | 0 | 0% |
| TC | 10 | 0 | 0% |
| **合计** | **53** | **0** | **0%** |

> 说明：`yield_curve` 当前为生产目标规格态，状态从 `Planned` 起步。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-07-03 | 初始化生产目标追溯矩阵，补齐 FR/BR/NFR/AC/TC 与覆盖率口径 |

