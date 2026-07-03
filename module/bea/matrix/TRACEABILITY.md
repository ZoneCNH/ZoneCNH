# bea 需求追溯矩阵

Last-Updated: 2026-07-04  
Source: [spec/SPEC.md](../spec/SPEC.md) | Goal: GOAL-BEA-001 | Status: Planned (Production Target)

---

## Goal 到需求

| Goal / SC | FR/BR | AC | TC |
| --------- | ----- | -- | -- |
| G-SC-001 独立 C/S 服务 | BR-BEA-001 | AC-BEA-001 | TC-BEA-001 |
| G-SC-002 共享基座与七介质 | BR-BEA-002, BR-BEA-004~006 | AC-BEA-002, AC-BEA-004 | TC-BEA-002, TC-BEA-004 |
| G-SC-003 领域共享与 no-lookahead | BR-BEA-003, BR-BEA-007 | AC-BEA-006 | TC-BEA-006 |
| G-SC-004 三层采集与同步治理 | BR-BEA-008~010 | AC-BEA-003, AC-BEA-005, AC-BEA-007 | TC-BEA-003, TC-BEA-005 |
| G-SC-005 分析与报告闭环 | BR-BEA-011 | AC-BEA-008, AC-BEA-009 | TC-BEA-007, TC-BEA-008 |

---

## BR 追溯

| BR | 规则摘要 | AC | TC | 状态 |
| -- | -------- | -- | -- | ---- |
| BR-BEA-001 | 子模块独立 C/S 边界 | AC-BEA-001 | TC-BEA-001 | Planned |
| BR-BEA-002 | 共享基座强制 | AC-BEA-002 | TC-BEA-002 | Planned |
| BR-BEA-003 | 领域共享层强制 | AC-BEA-006 | TC-BEA-006 | Planned |
| BR-BEA-004 | NATS/Kafka 分层 | AC-BEA-004 | TC-BEA-004 | Planned |
| BR-BEA-005 | checkpoint 先于 completed | AC-BEA-004 | TC-BEA-004 | Planned |
| BR-BEA-006 | Redis/ClickHouse 可重建 | AC-BEA-004 | TC-BEA-004 | Planned |
| BR-BEA-007 | no-lookahead fail-closed | AC-BEA-006 | TC-BEA-006 | Planned |
| BR-BEA-008 | 同步策略可审计 | AC-BEA-005 | TC-BEA-005 | Planned |
| BR-BEA-009 | 元数据/字典同步 | AC-BEA-003 | TC-BEA-003 | Planned |
| BR-BEA-010 | 发布日历触发优先 | AC-BEA-007 | TC-BEA-005 | Planned |
| BR-BEA-011 | 跨源映射一致性 | AC-BEA-008 | TC-BEA-007 | Planned |

---

## AC 注册表

| AC | 验收摘要 | 覆盖需求 | 状态 |
| -- | -------- | -------- | ---- |
| AC-BEA-001 | 子模块 client/server 独立启动并通过 health/readiness | BR-BEA-001 | Planned |
| AC-BEA-002 | 配置仅使用 secret reference 且通过脱敏扫描 | BR-BEA-002 | Planned |
| AC-BEA-003 | 三层采集清单与参数枚举完整 | BR-BEA-009 | Planned |
| AC-BEA-004 | Raw-First + 七介质链路闭合 | BR-BEA-004~006 | Planned |
| AC-BEA-005 | 增量/全量/Re-sync 作业追踪可用 | BR-BEA-008 | Planned |
| AC-BEA-006 | no-lookahead 与修订可见性通过 | BR-BEA-003, BR-BEA-007 | Planned |
| AC-BEA-007 | 发布日历触发采集路径生效 | BR-BEA-010 | Planned |
| AC-BEA-008 | 跨源一致性与质量评分可输出 | BR-BEA-011 | Planned |
| AC-BEA-009 | 仪表盘+报告+预警全链路可运行 | NFR-BEA-008 | Planned |

---

## TC 注册表

| TC | 覆盖需求 | 目标命令 |
| -- | -------- | -------- |
| TC-BEA-001 | BR-BEA-001 | `go test ./cmd/... -run Startup` |
| TC-BEA-002 | BR-BEA-002 | `go test ./internal/config/...` |
| TC-BEA-003 | BR-BEA-009 | `go test ./internal/client/... -run DatasetCatalog` |
| TC-BEA-004 | BR-BEA-004~006 | `go test ./internal/server/... -run Pipeline` |
| TC-BEA-005 | BR-BEA-008, BR-BEA-010 | `go test ./internal/integration/... -run SyncAndCalendar` |
| TC-BEA-006 | BR-BEA-003, BR-BEA-007 | `go test ./internal/server/... -run NoLookahead` |
| TC-BEA-007 | BR-BEA-011 | `go test ./internal/integration/... -run CrossSourceConsistency` |
| TC-BEA-008 | NFR-BEA-008 | `go test ./internal/reporting/... -run DashboardAndAlert` |
