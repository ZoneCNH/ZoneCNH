# fred 完整验收清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Acceptance plan generated from current module SSOT |
| Last-Updated | 2026-06-22 |
| Module-Version | v1.0.0 |
| Module-State | 目标验收已定义；runtime 通过证据待补 |
| Layer | 数据域 · 宏观 |
| Module-Type | 独立 C/S Module |
| Runtime-Service | `fred` |
| Runtime-Repo | `/home/workspace/fred` |
| Config-Source | `sre/secrets/env/dev.md` |
| Sources | `goal.md`, `SPEC.md`, `TRACEABILITY.md`, `FEATURES.md`, `IMPLEMENTATION-PLAN.md` |

本文档定义 `fred` 从规格到发布的最小验收闭环。除“文档存在性”和“补丁格式”
外，其余 runtime 验收项在拿到 `/home/workspace/fred` 实现证据前均保持 `Pending`。

## 验收命令

| ID | 命令 | 通过标准 | 当前状态 |
| --- | --- | --- | --- |
| V-001 | `test -f module/fred/FEATURES.md && test -f module/fred/ACCEPTANCE.md` | 两个补齐文档均存在。 | Ready |
| V-002 | `git diff --check -- module/fred/FEATURES.md module/fred/ACCEPTANCE.md` | 无尾随空格、补丁格式错误。 | Ready |
| V-003 | `.github/ci/spec-lint.sh` | `module/fred/SPEC.md` 保持 23/23 结构完整，且不引入新的规格 lint 错误。 | Pending |
| V-004 | `rg -n "FR-001|FR-014|AC-001|AC-008|TC-001|TC-008" module/fred/SPEC.md module/fred/TRACEABILITY.md module/fred/FEATURES.md module/fred/ACCEPTANCE.md` | 关键 FR/AC/TC 锚点在规格、追溯和验收文档中可定位。 | Ready |
| V-005 | `cd /home/workspace/fred && go test ./pkg/fredx/...` | FRED SDK 的参数编码、分页、限流、重试和错误分类测试通过。 | Pending |
| V-006 | `cd /home/workspace/fred && go test ./internal/domain/... ./internal/client/...` | provider 响应可稳定转换为 `domain_macro` 模型。 | Pending |
| V-007 | `cd /home/workspace/fred && go test ./internal/server/... -run Idempotency` | backfill、observation、event 重放保持幂等。 | Pending |
| V-008 | `cd /home/workspace/fred && go test ./internal/server/... -run NoLookahead` | as-of 查询不暴露未来 vintage。 | Pending |
| V-009 | `cd /home/workspace/fred && bash scripts/boundary-gates.sh && go test ./...` | 共享基座接入和模块边界 gate 通过。 | Pending |
| V-010 | `cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md go test ./internal/integration/...` | OSS、Postgres、TDengine、Kafka、Redis、NATS、ClickHouse 集成写入和读取闭合。 | Pending |
| V-011 | `rg -n "FR-015|BR-009|AC-009|TC-009|ms_brain|DFII10|BAMLH0A0HYM2" module/fred/SPEC.md module/fred/TRACEABILITY.md module/fred/FEATURES.md module/fred/ACCEPTANCE.md` | `ms_brain` 消费契约、初始序列锚点和新增 FR/BR/AC/TC 可定位。 | Ready |

## Acceptance Criteria

| ID | 验收标准 | 覆盖需求 | 关联测试 | 当前状态 |
| --- | --- | --- | --- | --- |
| AC-001 | dev 服务可启动，并暴露 health、version、readiness。 | FR-001 | V-009、runtime smoke | Pending |
| AC-002 | 配置扫描证明 `module/fred/` 和 `/home/workspace/fred` 不包含 dev secret 值。 | FR-002 | V-002、secret scan | Pending |
| AC-003 | 单个 series backfill 完成 OSS raw、Postgres metadata/checkpoint、TDengine observation、Kafka event、ClickHouse read model 写入。 | FR-004、FR-006、FR-007、FR-008、FR-010、FR-012 | V-010 | Pending |
| AC-004 | 清空 Redis 后，查询结果可从权威存储重建。 | FR-009、BR-006 | V-010 | Pending |
| AC-005 | NATS admin trigger 能启动受控 backfill，且不替代 Kafka durable event。 | FR-011、BR-004 | V-010 | Pending |
| AC-006 | no-lookahead 测试证明查询不会暴露未来 vintage。 | FR-005、BR-003 | V-008 | Pending |
| AC-007 | boundary gate 禁止绕过共享基座直接连接基础设施。 | FR-014、BR-001、BR-008 | V-009 | Pending |
| AC-008 | Goal、FR、BR、AC、TC 追溯闭合，并记录剩余风险。 | 全部 | V-003、V-004 | Pending |
| AC-009 | `ms_brain` 可通过 `fred` contract fixture 获取初始宏观序列、PIT/as-of 查询、发布日历、修订事件和 freshness/degrade 元数据，且 `fred` 不输出策略状态或交易决策。 | FR-015、BR-009 | V-011、TC-009 | Pending |

## Test Case Registry

| ID | 测试目标 | 覆盖范围 | 建议命令 | 当前状态 |
| --- | --- | --- | --- | --- |
| TC-001 | `pkg/fredx` 参数编码、错误分类、分页、限流和退避重试。 | FR-003、FR-013 | `cd /home/workspace/fred && go test ./pkg/fredx/...` | Pending |
| TC-002 | provider response 到 `domain_macro` 转换。 | FR-005、BR-001、BR-008 | `cd /home/workspace/fred && go test ./internal/domain/... ./internal/client/...` | Pending |
| TC-003 | observation、event、backfill job 幂等。 | FR-004、BR-002 | `cd /home/workspace/fred && go test ./internal/server/... -run Idempotency` | Pending |
| TC-004 | raw-first、多存储写入和 read model 集成闭合。 | FR-006、FR-007、FR-008、FR-010、FR-012 | `cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md go test ./internal/integration/...` | Pending |
| TC-005 | Redis 清空后可重建缓存。 | FR-009、BR-006 | `cd /home/workspace/fred && go test ./internal/server/... -run RedisRebuild` | Pending |
| TC-006 | NATS 控制面与 Kafka durable event 分离。 | FR-011、BR-004 | `cd /home/workspace/fred && go test ./internal/integration/... -run NATSControl` | Pending |
| TC-007 | as-of/no-lookahead 查询。 | FR-005、BR-003 | `cd /home/workspace/fred && go test ./internal/server/... -run NoLookahead` | Pending |
| TC-008 | 边界 gate 阻止绕过共享基座的直接 infra connection。 | FR-014、BR-001、BR-008 | `cd /home/workspace/fred && bash scripts/boundary-gates.sh` | Pending |
| TC-009 | `ms_brain` integration profile 和 contract fixture。 | FR-015、BR-009 | `cd /home/workspace/fred && go test ./internal/integration/... -run MsBrainContract` | Pending |

## 覆盖闭合矩阵

| 范围 | 必须闭合的证据 |
| --- | --- |
| 服务基线 | AC-001 通过，且启动、ready/live、version、shutdown 均有日志或测试证据。 |
| 配置安全 | AC-002 通过，配置只引用 `sre/secrets/env/dev.md` 键名，不复制 secret 值。 |
| FRED provider 接入 | TC-001 通过，覆盖分页、限流、错误分类、重试和审计字段。 |
| 领域共享层 | TC-002 通过，`domain_macro` 是出域唯一领域模型。 |
| 多存储持久化 | TC-004 通过，OSS、Postgres、TDengine、Kafka、ClickHouse 均有可定位写入证据。 |
| 派生层重建 | TC-005 通过，Redis/ClickHouse 均保持可重建属性。 |
| 控制面隔离 | TC-006 通过，NATS 只触发控制命令，Kafka 才是 durable event。 |
| 无前视 | TC-007 通过，以 `available_at` 判定 as-of 可见性。 |
| 边界治理 | TC-008 通过，直接 infra connection 和内部 DTO 外泄被 gate 拦截。 |
| `ms_brain` 消费契约 | TC-009 通过，覆盖 `DFII10`、`T10YIE`、`DFF`、`BAMLH0A0HYM2`、`T10Y2Y`、`ICSA`、`FYFSGDA188S`、`FDHBFRBN` 初始锚点、发布/修订事件和 freshness/degrade 元数据。 |
| 追溯闭合 | AC-008 通过，Goal、FR、BR、AC、TC 和剩余风险在文档中一致。 |

## Definition of Done

1. `FEATURES.md` 和 `ACCEPTANCE.md` 存在，且通过 `git diff --check`。
2. `SPEC.md`、`TRACEABILITY.md`、`FEATURES.md`、`ACCEPTANCE.md` 的 FR/BR/AC/TC 编号一致。
3. `/home/workspace/fred` runtime 完成 FR-001..FR-015 的实现，并保留对应测试证据。
4. 七类持久化/消息组件职责均有测试证明：`taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse`。
5. `sre/secrets/env/dev.md` 只作为配置来源，不向仓库复制 secret 值。
6. `scripts/boundary-gates.sh` 已从旧 `Stores=None` 口径迁移为完整目标边界。
7. AC-001..AC-009 全部通过，并在发布说明或报告中登记证据路径。

## 当前阻塞与风险

| 风险 | 影响 | 处理要求 |
| --- | --- | --- |
| `TRACEABILITY.md` BR 编号漂移 | 可能导致 BR 到 AC/TC 的追溯错误 | 以 `SPEC.md` 为准修正矩阵后再进行 release gate。 |
| 旧 `Stores=None` 边界口径 | 与目标七类持久化/消息边界冲突 | 实现前必须更新 boundary gate 和测试。 |
| `domain_macro` 契约未确认 | 可能出现字段映射和依赖方向返工 | 开发前确认包路径、字段、版本策略。 |
| dev infra 不可用 | 集成验收无法闭合 | 缺环境时只能标记 Not-tested，不得宣称 AC-003/AC-004/AC-005 通过。 |
| FRED 凭证不可复制 | 配置测试不能硬编码 secret | 只验证键名、装载路径和运行时注入，不提交任何 secret 值。 |
| `ms_brain` runtime 尚未落地 | 无法用真实下游进程证明消费契约 | 先用 `ms_brain` 文档/YAML/spec 提取 contract fixture，真实 runtime 接入后补端到端证据。 |
