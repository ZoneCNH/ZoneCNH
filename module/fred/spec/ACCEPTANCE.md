# fred 完整验收清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Acceptance verified (unit) · integration CI-gated |
| Last-Updated | 2026-07-08 |
| Module-Version | v1.1.0 |
| Module-State | Runtime 实现完成；单元测试全量通过；集成测试经 `//go:build integration` 接入 dev secret，本地 SKIP、CI 闭环 |
| Layer | 数据域 · 宏观 |
| Module-Type | 独立 C/S Module（client/server 双服务） |
| Runtime-Repo | `/home/workspace/fred` |
| Config-Source | `sre/secrets/env/dev.md` |
| Sources | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/FEATURES.md`、`plan/PLAN.md` |

本文件定义 `fred` 从规格到发布的最小验收闭环。除“文档存在性”和“补丁格式”
外，其余 runtime 验收项在拿到 `/home/workspace/fred` 实现证据前均保持 `Pending`。

## 验收命令

| ID | 命令 | 通过标准 | 当前状态 |
| --- | --- | --- | --- |
| V-001 | `test -f module/fred/spec/FEATURES.md && test -f module/fred/spec/ACCEPTANCE.md` | 两个补齐文档均存在。 | Passed |
| V-002 | `git diff --check -- module/fred/spec/FEATURES.md module/fred/spec/ACCEPTANCE.md` | 无尾随空格、补丁格式错误。 | Passed |
| V-003 | `.github/ci/spec-lint.sh` | `module/fred/spec/SPEC.md` 保持 23/23 结构完整，且不引入新的规格 lint 错误。 | Passed (结构保持; CI 复核) |
| V-004 | `rg -n "FR-001|FR-016|AC-001|AC-010|TC-001|TC-010" module/fred/spec/SPEC.md module/fred/matrix/TRACEABILITY.md module/fred/spec/FEATURES.md module/fred/spec/ACCEPTANCE.md` | 关键 FR/AC/TC 锚点在规格、追溯和验收文档中可定位。 | Passed |
| V-005 | `cd /home/workspace/fred && go test ./pkg/fredx/...` | FRED SDK 的参数编码、分页、限流、重试和错误分类测试通过。 | Passed |
| V-006 | `cd /home/workspace/fred && go test ./internal/domain/... ./internal/client/...` | provider 响应可稳定转换为 `domain_macro` 模型。 | Passed |
| V-007 | `cd /home/workspace/fred && go test ./internal/server/... -run Idempotency` | backfill、observation、event 重放保持幂等。 | Passed |
| V-008 | `cd /home/workspace/fred && go test ./internal/domain/... -run IsVisibleAt` | as-of 查询（`IsVisibleAt`）不暴露未来 vintage。 | Passed |
| V-009 | `cd /home/workspace/fred && bash scripts/boundary-gates.sh && go test ./...` | 共享基座接入和模块边界 gate 通过。 | Passed |
| V-010 | `cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md go test ./internal/integration/...` | OSS、Postgres、TDengine、Kafka、Redis、NATS、ClickHouse 集成写入和读取闭合。 | Pending (CI-gated) |
| V-011 | `rg -n "FR-015|BR-009|AC-009|TC-009|ms_brain|DFII10|BAMLH0A0HYM2" module/fred/spec/SPEC.md module/fred/matrix/TRACEABILITY.md module/fred/spec/FEATURES.md module/fred/spec/ACCEPTANCE.md` | `ms_brain` 消费契约、初始序列锚点和新增 FR/BR/AC/TC 可定位。 | Passed |
| V-012 | `cd /home/workspace/fred && go test ./internal/integration/... -run NATSIngestHandoff` | `fred-client` 到 `fred-server` 的 NATS ingest handoff 可用，且不替代 Kafka durable event。 | Pending (CI-gated) |
| V-013 | `cd /home/workspace/fred && go test ./internal/integration/... -run FullCoverageAudit` | 全量采集覆盖审计通过：series/release/category/tag/source/updates 六域覆盖率、默认 `1990-01-01` 全量起点与最近 3 个月修订回拉可验证。 | Pending (CI-gated) |
| V-014 | `rg -n "category/related|release/related_tags|release/sources|releases/dates|series/categories|series/release|series/tags|series/search/tags|series/search/related_tags|sources" module/fred/spec/SPEC.md module/fred/README.md` | FRED v1 全端点矩阵在模块规格与索引文档中可定位。 | Passed |
| V-015 | `rg -n "1990-01-01|最近 3 个月|30 req/min|120 req/min|2 req/s|发布后 24h" module/fred/spec/SPEC.md module/fred/README.md module/fred/plan/PLAN.md` | 默认回溯窗口、修订回拉、限流策略与同步周期在规格/索引/计划中可定位。 | Passed |
| V-016 | `rg -n "批量采集|频率聚合|D->M|M->Q|realtime_start|realtime_end|ALFRED" module/fred/spec/SPEC.md module/fred/README.md` | 批量采集、频率聚合和版本维度策略在规格与索引文档中可定位。 | Passed |

## Acceptance Criteria

| ID | 验收标准 | 覆盖需求 | 关联测试 | 当前状态 |
| --- | --- | --- | --- | --- |
| AC-001 | `fred-client`/`fred-server` 可启动，并暴露 health、version、readiness。 | FR-001、FR-013 | V-009、runtime smoke | Passed (unit) |
| AC-002 | 配置扫描证明 `module/fred/` 和 `/home/workspace/fred` 不包含 dev secret 值。 | FR-002 | V-002、secret scan | Passed |
| AC-003 | 单个 series backfill 完成 OSS raw、Postgres metadata/checkpoint、TDengine observation、Kafka event、ClickHouse read model 写入。 | FR-004、FR-006、FR-007、FR-008、FR-010、FR-012 | V-010 | Pending (CI-gated) |
| AC-004 | 清空 Redis 后，查询结果可从权威存储重建。 | FR-009、BR-006 | V-010 | Pending (CI-gated) |
| AC-005 | NATS ingest/control 可驱动受控 backfill，且不替代 Kafka durable event。 | FR-011、BR-004 | V-010、V-012 | Pending (CI-gated) |
| AC-006 | no-lookahead 测试证明查询不会暴露未来 vintage。 | FR-005、BR-003 | V-008 | Passed |
| AC-007 | boundary gate 禁止绕过共享基座直接连接基础设施。 | FR-014、BR-001、BR-008 | V-009 | Passed |
| AC-008 | Goal、FR、BR、AC、TC 追溯闭合，并记录剩余风险。 | 全部 | V-003、V-004 | Passed |
| AC-009 | `ms_brain` 可通过 `fred` contract fixture 获取初始宏观序列、PIT/as-of 查询、发布日历、修订事件和 freshness/degrade 元数据，且 `fred` 不输出策略状态或交易决策。 | FR-015、BR-009 | V-011、TC-009 | Pending (CI-gated) |
| AC-010 | 全量采集覆盖审计通过：series/release/category/tag/source/updates 六域覆盖率达到阈值，默认 `1990-01-01` 全量起点、最近 3 个月修订回拉与 `realtime_start/realtime_end` 版本维度可验证，缺口可追踪并重采闭合。 | FR-016、BR-010 | V-013、TC-010 | Pending (CI-gated) |

## Test Case Registry

| ID | 测试目标 | 覆盖范围 | 建议命令 | 当前状态 |
| --- | --- | --- | --- | --- |
| TC-001 | `pkg/fredx` 全信息域端点（series/release/category/tag/source/update）参数编码、错误分类、分页、批量采集、频率聚合、限流（30/120 req/min 与 <=2 req/s）和退避重试。 | FR-003、FR-013 | `cd /home/workspace/fred && go test ./pkg/fredx/...` | Passed |
| TC-002 | provider response 到 `domain_macro` 转换。 | FR-005、BR-001、BR-008 | `cd /home/workspace/fred && go test ./internal/domain/... ./internal/client/...` | Passed |
| TC-003 | observation、event、backfill job 幂等。 | FR-004、BR-002 | `cd /home/workspace/fred && go test ./internal/server/... -run Idempotency` | Passed |
| TC-004 | raw-first、多存储写入和 read model 集成闭合。 | FR-006、FR-007、FR-008、FR-010、FR-012 | `cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md go test ./internal/integration/...` | Pending (CI-gated) |
| TC-005 | Redis 清空后可重建缓存。 | FR-009、BR-006 | `cd /home/workspace/fred && go test ./internal/server/... -run RedisRebuild` | Pending (CI-gated) |
| TC-006 | NATS ingest/control 与 Kafka durable event 分离。 | FR-011、BR-004 | `cd /home/workspace/fred && go test ./internal/integration/... -run NATSIngestHandoff` | Pending (CI-gated) |
| TC-007 | as-of/no-lookahead 查询。 | FR-005、BR-003 | `cd /home/workspace/fred && go test ./internal/domain/... -run IsVisibleAt` | Passed |
| TC-008 | 边界 gate 阻止绕过共享基座的直接 infra connection。 | FR-014、BR-001、BR-008 | `cd /home/workspace/fred && bash scripts/boundary-gates.sh` | Passed |
| TC-009 | `ms_brain` integration profile 和 contract fixture。 | FR-015、BR-009 | `cd /home/workspace/fred && go test ./internal/integration/... -run MsBrainContract` | Pending (CI-gated) |
| TC-010 | 全量采集覆盖审计、默认 `1990-01-01` 全量起点与最近 3 个月修订回拉、`realtime_start/realtime_end` 版本闭合、缺口回补。 | FR-016、BR-010 | `cd /home/workspace/fred && go test ./internal/integration/... -run FullCoverageAudit` | Pending (CI-gated) |

## Definition of Done

1. `spec/FEATURES.md` 和 `spec/ACCEPTANCE.md` 存在，且通过 `git diff --check`。
2. `spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/FEATURES.md`、`spec/ACCEPTANCE.md` 的 FR/BR/AC/TC 编号一致。
3. `/home/workspace/fred` runtime 完成 FR-001..FR-016 的实现；单元测试基于内存/接口 fake 全量通过并保留证据；集成测试经 `//go:build integration` 接入 dev secret，于 CI 闭环（OPEN-004）。
4. 七类持久化/消息组件职责均有测试证明：`taos`/`kafka`/`postgres`/`Redis`/`oss`/`nats`/`clickhouse` —— 单元测试覆盖 nil-guard、接口 fake 与纯 helper；真实介质写入于集成测试（CI-gated）闭合。
5. `sre/secrets/env/dev.md` 只作为配置来源，不向仓库复制 secret 值（git/secret-scan 无泄露）。
6. `scripts/boundary-gates.sh` §9 已从旧 `Stores=None` 零存储口径迁移为“经共享基座接入、禁止业务代码直连”，9 道门禁全过。
7. AC-001..AC-010 中单元可验证项已通过并登记证据路径；AC-003/004/005/009/010 等依赖真实介质的集成项于 CI 闭环（dev secret 提供后标记 Passed）。
