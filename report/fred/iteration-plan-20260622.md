# fred 完整更新迭代方案

- Date: 2026-06-22
- Branch: `docs/fred-iteration-plan-20260622`
- Scope: `report/fred/` 全部 4 份报告 + `module/fred/` 全部 7 份模块文件
- Output: 收敛 fred 现状分析、模块规格差异、迭代路线、backlog 与验收门禁的权威迭代方案
- Evidence Rule: `[COMPUTED]` 来自本仓库文件与命令输出；`[INFERRED]` 是基于证据的工程判断；`[KNOWN]` 是 FRED 官方 API 文档语义
- Related: 本报告收敛以下 4 份既有报告，不覆盖其细节，只统一结论与路线：
  - [deep-analysis-20260622.md](./deep-analysis-20260622.md) — fred 是否还需补充迭代（P0/P1/P2 排序）
  - [data-issues-resolution-20260622.md](./data-issues-resolution-20260622.md) — 历史数据/实时数据/同步/清洗/缺口
  - [ms_brain-integration-analysis-20260622.md](./ms_brain-integration-analysis-20260622.md) — ms_brain 下游消费契约
  - [structural-score-20260622.md](./structural-score-20260622.md) — 结构评分账本（68/42 分）

## 1. 总结判断

[COMPUTED][HIGH] `fred` 不是“缺规格”，而是“规格骨架完整但结构闭环不足”。`module/fred/` 已有 `goal.md`、`SPEC.md`、`TRACEABILITY.md`、`FEATURES.md`、`ACCEPTANCE.md`、`IMPLEMENTATION-PLAN.md`、`README.md` 七件套，目标架构（独立 C/S、共享基座、`domain_macro`、七类持久化）定义完整；但核心状态仍是 `Draft`/`Planned`/`Pending`，`/home/fred` 运行仓仍是旧 `Stores=None` 骨架。

[INFERRED][HIGH] 当前最高优先级不是扩展新组件，而是闭合三层落差：
1. **追溯一致性** — `TRACEABILITY.md` 业务规则表 BR 编号与 `SPEC.md` 漂移（仍存在）。
2. **目标边界迁移** — `/home/fred` 旧零存储门禁与目标七介质边界冲突。
3. **验收证据** — 所有 AC/TC 仍 `Pending`，无法证明 runtime 已闭环。

[INFERRED][HIGH] 最短可交付路径：先修文档追溯与契约（P0），再迁移 `/home/fred` 边界门禁与服务骨架，然后用一个最小 FRED series 打通 raw → checkpoint → observation → event → read model → API 查询证据链。

## 2. 证据范围

| 证据来源 | 内容 | 置信度 |
| --- | --- | --- |
| `module/fred/SPEC.md` | 23 节规格，Status=Draft，FR-001..FR-015、BR-001..BR-009、AC-001..AC-009、TC-001..TC-009、OPEN-001..OPEN-005 | [COMPUTED][HIGH] |
| `module/fred/TRACEABILITY.md` | G-SC-001..006、FR/BR/AC/TC 覆盖表、验证命令占位、GAP-001..004 | [COMPUTED][HIGH] |
| `module/fred/ACCEPTANCE.md` | V-001..V-011 验收命令、AC-001..009、TC-001..009、DoD、风险表 | [COMPUTED][HIGH] |
| `module/fred/IMPLEMENTATION-PLAN.md` | 阶段 0..6、FRED-TASK-001..007、约束 C-001..006 | [COMPUTED][HIGH] |
| `module/fred/goal.md` | GOAL-FRED-001、G-SC-001..006、G-NG-001..004、G-BD-001..004、G-R-001..004 | [COMPUTED][HIGH] |
| `module/fred/FEATURES.md` | FR-001..015 功能投影、BR-001..009、完成度勾稽、当前缺口 6 项 | [COMPUTED][HIGH] |
| `module/fred/README.md` | 模块索引、目标边界、ms_brain 消费画像、迁移提示 | [COMPUTED][HIGH] |
| `report/fred/deep-analysis-20260622.md` | P0 三项（BR 漂移、边界冲突、配置映射）+ P1 四项 + 推荐迭代顺序 | [COMPUTED][HIGH] |
| `report/fred/data-issues-resolution-20260622.md` | FRED 官方语义、历史/实时数据方案、同步对象/周期、清洗规则、缺口检测、七介质职责 | [COMPUTED][HIGH] |
| `report/fred/ms_brain-integration-analysis-20260622.md` | ms_brain 消费画像、初始序列锚点、PIT/no-lookahead、freshness/degrade 契约 | [COMPUTED][HIGH] |
| `report/fred/structural-score-20260622.md` | SPEC 84/100、结构健康 68/100、发布就绪 42/100；G2/G3 Fail | [COMPUTED][HIGH] |
| `/home/fred` 运行仓 | `cmd/fred-server/main.go` 仍称“adapter 零存储”，`bootstrap.Build` 用 `Stores: bootstrap.None`，边界脚本 `no-storage-adapter` gate | [COMPUTED][HIGH] |

## 3. 现状评分

[COMPUTED][HIGH] 引自 `structural-score-20260622.md`，本报告不重新评分，只引用其账本。

| 评分对象 | 分数 | 结论 |
| --- | ---: | --- |
| SPEC 单文件结构 | 84/100 | 目标/边界/FR/BR/AC/TC/持久化/配置/安全较完整，4 个开放问题未关闭 |
| `module/fred/` 结构健康 | 68/100 | 文档骨架完整，追溯矩阵/验收命令/实施证据未闭环 |
| 发布验收就绪 | 42/100 | 所有 AC/TC 仍 Pending，不能证明 `/home/fred` 已满足目标状态 |

结构健康分项账本（68/100）：

| 维度 | 分数 | 扣分原因 |
| --- | ---: | --- |
| 需求与边界完整度 | 18/20 | FR/BR/AC/TC 与七介质已定义；`/home/fred` 旧 `Stores=None` 迁移未完成 |
| 领域共享层与 C/S 边界 | 14/20 | 已要求共享基座与 `domain_macro`，但具体包路径/字段仍是开放项 |
| 追溯一致性 | 9/20 | `TRACEABILITY.md` BR 编号语义与 `SPEC.md` 漂移 |
| 验收可执行性 | 13/20 | AC/TC/DoD 存在，但全 Pending，缺真实运行证据 |
| 实施就绪度 | 14/20 | 阶段/任务已拆分，配置映射/集成环境/运行时边界待补 |
| **总分** | **68/100** | 规格层可推进，未达发布或合并验收的结构闭环 |

## 4. 关键问题排序

### P0-1. 追溯矩阵 BR 编号漂移（仍存在）

[COMPUTED][HIGH] 以 `SPEC.md:69-79` 为权威，BR 语义为：
- BR-001 不暴露 provider DTO
- BR-002 相同 provider/series/period/vintage 写入幂等
- BR-003 `available_at` 是 no-lookahead 判定依据
- BR-004 Kafka durable / NATS control
- BR-005 Postgres checkpoint 先于 backfill completed
- BR-006 Redis/ClickHouse 可重建
- BR-007 OSS raw path 含可审计维度
- BR-008 `macro_data` 不依赖 `fred/internal/*`
- BR-009 `fred` 不实现 ms_brain 策略逻辑

[COMPUTED][HIGH] 但 `TRACEABILITY.md:47-56` 业务规则覆盖表中：
- BR-002 写成“`available_at` 后才可见”（实为 BR-003）
- BR-003 写成“provider/series/period/vintage 幂等”（实为 BR-002）
- BR-005 写成“ClickHouse/Redis 可重建”（实为 BR-006）
- BR-006 写成“OSS raw 路径包含可审计维度”（实为 BR-007）
- BR-007 写成“Postgres checkpoint 控制作业完成”（实为 BR-005）

即 BR-002↔BR-003、BR-005↔BR-006↔BR-007 两组循环错位。`FEATURES.md` 与 `ACCEPTANCE.md` 的 BR 表与 SPEC 一致（未漂移），问题集中在 `TRACEABILITY.md` 单点。

影响：[INFERRED][HIGH] 管线评分和人工评审会把同一 BR 编号解释成不同约束，导致误判覆盖率；后续 Task/Prompt 若按 TRACEABILITY 执行，可能优先实现错误约束或漏验关键业务规则。

修复要求：
1. 以 `SPEC.md:69-79` 为权威，重写 `TRACEABILITY.md` BR 表的“规则摘要”列。
2. 同步修正 G-SC-004/006 行的 BR 引用（当前 G-SC-004 引 `BR-003,004,005,007`、G-SC-006 引 `BR-002,003,007`，需按修正后语义复核）。
3. 增加 `rg -n "BR-00[2-7]" module/fred` 的人工核对记录写入 GAP 关闭证据。

### P0-2. 目标服务边界与运行仓旧门禁冲突

[COMPUTED][HIGH] `SPEC.md` FR-014 要求边界门禁允许目标存储适配器经共享基座接入；但 `/home/fred/cmd/fred-server/main.go` 仍用 `Stores: bootstrap.None`，`scripts/boundary-gates.sh` 仍是 `no-storage-adapter` gate。

影响：[INFERRED][HIGH] 若直接实现七类持久化，当前门禁会把正确目标误判为违规；若保留当前门禁，则无法达到目标规格。

修复要求：把门禁从“禁止目标存储适配器”改为“允许经共享基座接入，禁止绕过基座直连驱动或在业务代码中散落基础设施细节”。

### P0-3. 配置映射停在类别层

[COMPUTED][HIGH] `SPEC.md:138-152` 已声明配置来源和类别，但未列出可审查的 key mapping、类型、必填性、默认值策略、redaction 规则和运行时校验错误码。`OPEN-003` 仍开放。

影响：[INFERRED][HIGH] 实施阶段易把 `sre/secrets/env/dev.md` 实际 secret 值带入文档、测试夹具或日志；配置缺失时行为不一致。

修复要求：新增 redacted mapping 表，只写 key 名、路径、类型、是否必填、默认值来源、redaction 策略和消费组件，不写任何值。

### P1-1. TC 注册表（已闭合，确认项）

[COMPUTED][HIGH] `structural-score-20260622.md` P0-2 指出 TC-007/TC-008 未进验证命令表。本次核对 `TRACEABILITY.md:60-70`：TC-001..TC-009 已全部进入验证命令占位表。该项**已闭合**，无需再修。

### P1-2. API/Event/Storage 契约偏概念层

[COMPUTED][HIGH] `SPEC.md` 已列公共 API 和七介质职责，但未固化 request/response 版本、错误码、Kafka topic/key/schema、NATS subject、Postgres table、TDengine supertable/tag、OSS path、Redis key namespace/TTL、ClickHouse table/view 的最小契约。

修复要求：补一份最小契约附录或 `contracts/` 索引，只固化实现必须共享的字段和命名，不做大而全数据平台设计。

### P1-3. `domain_macro` 绑定未落地

[COMPUTED][HIGH] `TRACEABILITY.md` GAP-002、`SPEC.md` OPEN-002 仍开放。`IMPLEMENTATION-PLAN.md` 阶段 2 负责此项。

修复要求：实现前先读取 `domain_macro` 当前代码，冻结 `MacroSeries`、`MacroObservation`、`MacroRelease`、`MacroRevision`、`MacroIngestJob` 的包路径、字段映射和 no-lookahead 夹具。

### P1-4. 全局架构文档口径需分层

[COMPUTED][HIGH] `docs/architecture/01-overview.md:107` 仍写 adapter 进程使用 `Stores=None`；`docs/architecture/05-foundation.md:164` 把 fred 标为已有、进度约 80%。与 `module/fred` Draft 规格冲突。

修复要求：全局文档区分“轻量 adapter 旧口径”和“宏观 provider 独立 C/S 服务目标口径”，fred 进度描述改成不与 Draft 规格冲突的状态。

### P2. ms_brain runtime 未落地

[COMPUTED][HIGH] `/home/ms_brain` 当前主要是文档/spec/YAML，`framework/` 下暂无可运行代码（`ms_brain-integration-analysis-20260622.md` 证据）。`OPEN-005`/`GAP-004` 仍开放。

处理：[INFERRED][HIGH] 先在 `/home/fred` 建 `MsBrainContract` fixture（覆盖 `DFII10`、`T10YIE`、`DFF`、`BAMLH0A0HYM2`、`T10Y2Y`、`ICSA`、`FYFSGDA188S`、`FDHBFRBN`）；待 ms_brain runtime 落地后补 E2E。本项不阻塞 fred 自身发布，只阻塞 AC-009 的端到端证据。

## 5. 迭代路线（7 阶段）

[INFERRED][HIGH] 本路线对齐 `IMPLEMENTATION-PLAN.md` 阶段 0..6，但按 P0 优先级重排：把“追溯修正”从隐含前置显式化为阶段 1，把“边界迁移”作为阶段 3，确保文档闭环先于代码实现。

| 阶段 | 目标 | 主要产出 | 验收 | 优先级 |
| --- | --- | --- | --- | --- |
| **阶段 1：追溯修正** | 闭合 P0-1、P1-1 | `TRACEABILITY.md` BR 表重写、G-SC BR 引用复核、BR 核对记录 | `rg -n "BR-00[2-7]" module/fred` 人工核对无错位；G2 追溯闭环 Pass | P0 |
| **阶段 2：配置与契约补齐** | 闭合 P0-3、P1-2、P1-3 | redacted config mapping 表、API/event/schema 最小契约附录、`domain_macro` 绑定表 | 映射表不含 secret 值；每个 FRED DTO 字段有目标 domain 字段、时区、空值、单位规则 | P0/P1 |
| **阶段 3：边界迁移与服务骨架** | 闭合 P0-2 | `/home/fred` 边界脚本改为目标存储白名单 + 基座强制规则；`cmd/fred-server` 用 `bootstrap`/`configx` 组装；health/version/readiness | `bash scripts/boundary-gates.sh` 通过；配置缺失 fail fast；redaction 测试通过 | P0 |
| **阶段 4：领域映射与权威写入** | 闭合 P1-3 实施 + raw-first | `internal/domain` FRED DTO→`domain_macro` 转换；OSS raw archive + Postgres checkpoint/idempotency + Taos observation | 单 series backfill 证明 raw、metadata、observation 一致；no-lookahead fixture 通过 | P1 |
| **阶段 5：事件、控制面与读模型** | durable event + 控制面分离 + 读模型 | Kafka durable event + outbox；NATS control plane；Redis cache/lock/rate bucket；ClickHouse read model | 重复 backfill 不产生重复副作用；NATS 不替代 Kafka；Redis 清空可重建；ClickHouse 可重放 | P1 |
| **阶段 6：服务 API 与客户端** | 出域契约 | `GetSeries`/`QueryObservations`/`StartBackfill`/`GetJobStatus`/`ScanRevisions`/`ReloadConfig`；`pkg/fredx` 稳定 API；ms_brain integration profile fixture | client contract tests、server handler tests、兼容性 fixture 通过 | P1 |
| **阶段 7：验收与发布** | 闭合 AC/TC | 单元/契约/边界/集成/no-lookahead/回放一致性测试；traceability 状态更新；证据登记 | AC-001..AC-009 全部从 Pending→Verified；V-005..V-010 通过 | P0 |

### 阶段依赖与并行

```
阶段1 (追溯) ─┐
              ├─→ 阶段2 (契约) ─→ 阶段3 (边界/骨架) ─→ 阶段4 (领域/写入) ─┐
              │                                                              ├─→ 阶段6 (API) ─→ 阶段7 (验收)
              └─────────────────────────────────────────────→ 阶段5 (事件/读模型) ┘
```

[INFERRED][HIGH] 阶段 1 与阶段 2 的 `domain_macro` 绑定可并行（一个改文档追溯，一个读领域代码）。阶段 4 与阶段 5 部分可并行（权威写入与事件/读模型），但阶段 5 的 Kafka outbox 依赖阶段 4 的 checkpoint。阶段 6 必须在 4/5 之后。阶段 7 必须最后。

## 6. Backlog 清单

[COMPUTED][HIGH] 以下 backlog 融合 4 份报告的建议清单与 `IMPLEMENTATION-PLAN.md` 任务拆分，按阶段归集。

### 阶段 1（P0 追溯修正）

| ID | 项 | 目标文件 | 验收 |
| --- | --- | --- | --- |
| FRED-BL-001 | 重写 `TRACEABILITY.md` BR 表“规则摘要”列，对齐 SPEC BR-001..009 | `module/fred/TRACEABILITY.md` | BR 编号语义与 SPEC 一一对应 |
| FRED-BL-002 | 复核 G-SC-004/006 行 BR 引用 | `module/fred/TRACEABILITY.md` | G-SC→BR 映射按修正后语义正确 |
| FRED-BL-003 | 记录 BR 核对证据 | `module/fred/TRACEABILITY.md` 未闭合项 | `rg -n "BR-00[2-7]" module/fred` 输出归档 |

### 阶段 2（P0/P1 契约补齐）

| ID | 项 | 目标文件 | 验收 |
| --- | --- | --- | --- |
| FRED-BL-004 | 新增 redacted config mapping 表 | `module/fred/SPEC.md` §11 或附录 | 只含 key 名/类型/必填/redaction，不含值 |
| FRED-BL-005 | 固化 API request/response/错误码/版本 | `module/fred/SPEC.md` §7 或 contracts 索引 | API 字段可测试 |
| FRED-BL-006 | 固化 Kafka topic/key/schema + NATS subject | `module/fred/SPEC.md` §10 或 contracts | durable event 与 control subject 不混用 |
| FRED-BL-007 | 固化七介质最小 schema（Postgres table/Taos supertable/OSS path/Redis key TTL/ClickHouse table） | `module/fred/SPEC.md` 附录 | 单 series backfill 能证明各介质命名一致 |
| FRED-BL-008 | 冻结 `domain_macro` 绑定表 | `module/fred/SPEC.md` §9 附录 | 每个 FRED DTO 字段有目标 domain 字段、时区、空值、单位规则 |

### 阶段 3（P0 边界迁移）

| ID | 项 | 目标文件 | 验收 |
| --- | --- | --- | --- |
| FRED-BL-009 | 改造 `/home/fred/scripts/boundary-gates.sh` | `/home/fred/scripts/boundary-gates.sh` | 允许共享基座存储 adapter，禁止直连驱动/私有连接池/绕过 configx |
| FRED-BL-010 | 迁移 `cmd/fred-server/main.go` 入口 | `/home/fred/cmd/fred-server/main.go` | 移除“adapter 零存储”注释，`Stores` 从 None 改为目标装配 |
| FRED-BL-011 | 配置 redaction 测试 | `/home/fred` tests | 缺失配置 fail fast，日志/错误不泄露值 |

### 阶段 4（P1 领域映射与权威写入）

| ID | 项 | 验收 |
| --- | --- | --- |
| FRED-BL-012 | FRED DTO→`domain_macro` 转换 + no-lookahead fixture | `released_at < available_at` 时下游查询在 `available_at` 前不可见 |
| FRED-BL-013 | OSS raw archive + content hash + manifest | raw payload 可从 OSS 重放 |
| FRED-BL-014 | Postgres catalog/release calendar/checkpoint/idempotency ledger | checkpoint 可恢复中断任务 |
| FRED-BL-015 | Taos observation/vintage 写入与查询 | 按 series/time/vintage selector 查询正确 |
| FRED-BL-016 | 缺失值/修订 fixture（覆盖 `"."`/空值/单位变化/频率变化/revision-only/initial-release-only） | 缺失是可解释事实而非数据消失 |

### 阶段 5（P1 事件/控制面/读模型）

| ID | 项 | 验收 |
| --- | --- | --- |
| FRED-BL-017 | Kafka durable event + outbox + 幂等键 | 重复 backfill 不产生重复副作用；事件可重放 |
| FRED-BL-018 | NATS control plane（reload/backfill/pause/resume/heartbeat） | NATS command 不承担 durable event |
| FRED-BL-019 | Redis cache/lock/rate bucket/cursor | Redis 丢失后可从 Postgres checkpoint + Kafka/OSS 重建 |
| FRED-BL-020 | ClickHouse read model + materialized view | 从 Kafka event 或权威存储重放生成 |
| FRED-BL-021 | 四数量对账（OSS raw/normalized/Taos/Kafka）+ 每日 ClickHouse 对账 | 行数、最大 observation date、最大 available_at、revision count 一致 |

### 阶段 6（P1 API 与客户端）

| ID | 项 | 验收 |
| --- | --- | --- |
| FRED-BL-022 | 服务 API 6 端点实现 + 错误码 + 鉴权 | client contract tests、server handler tests 通过 |
| FRED-BL-023 | `pkg/fredx` 稳定 API，隐藏传输细节 | 不泄漏 server transport 细节 |
| FRED-BL-024 | ms_brain integration profile fixture（8 序列锚点 + PIT/as-of + release/calendar event + freshness/degrade） | `MsBrainContract` 测试通过；fred 不输出策略状态/交易决策 |

### 阶段 7（P0 验收发布）

| ID | 项 | 验收 |
| --- | --- | --- |
| FRED-BL-025 | 跑通 V-005..V-010 验收命令 | 命令通过，证据登记 |
| FRED-BL-026 | AC-001..AC-009 从 Pending→Verified | 每个 AC 有测试输出/退出码/关键输出摘要 |
| FRED-BL-027 | 更新 `TRACEABILITY.md` 状态与证据 | FR/BR/AC/TC 全部已验证 |
| FRED-BL-028 | 更新全局架构文档口径（`docs/architecture/01-overview.md`、`05-foundation.md`） | 不再把 fred 目标误读为普通零存储 adapter；进度描述与 Draft 规格不冲突 |
| FRED-BL-029 | spec-lint 23/23 + secret scan + `go test ./...` + boundary-gates 全通过 | CI 门禁绿 |

## 7. 验收门禁

[COMPUTED][HIGH] 引自 `ACCEPTANCE.md` V-001..V-011 与 `SPEC.md` §20 CI 门禁。本报告不新增门禁，只标注当前状态与目标状态。

| Gate | 当前 | 目标 | 关闭条件 |
| --- | :---: | :---: | --- |
| G0 规格存在 | Pass | Pass | `module/fred/SPEC.md` 存在且 23/23 结构完整 |
| G1 目标边界清楚 | Pass | Pass | 独立 C/S、共享基座、`domain_macro`、七介质、配置来源已定义 |
| G2 追溯闭环 | **Fail** | Pass | 修正 BR 编号漂移；TC-001..009 已闭合（P1-1 确认） |
| G3 验收可执行 | **Fail** | Pass | AC/TC 从 Pending→Verified，有运行输出和退出码 |
| G4 实施就绪 | Conditional | Pass | 可进入追溯修复与设计补齐；不宜宣称已可发布 |

[INFERRED][HIGH] 结构健康分预测：修 P0-1（BR 漂移）后 G2 Pass，结构健康分预计从 68→75 左右；再补 P0-3/P1-2/P1-3（config mapping/契约/domain_macro 绑定）后预计 80+；最后补 `/home/fred` 真实验收证据后发布就绪分有机会超 80。

## 8. 风险

| ID | 风险 | 影响 | 控制 |
| --- | --- | --- | --- |
| R-001 | FRED release calendar 误当成可用时间 | 破坏回测 no-lookahead 保证 | 强制 `available_at` 过滤，`released_at` 只表示数据源发布日 |
| R-002 | 静默丢弃 `"."`/解析失败/异常值 | provider 缺失误报为 fred 缺口已修复 | 保留 null observation + quality flag + skip reason |
| R-003 | ClickHouse/Redis 误当成权威事实库 | rebuild 后数据不一致且无法追责 | 明确七介质权威性层级，Redis/ClickHouse 只作可重建派生层 |
| R-004 | dev secret 误写入文档/测试/日志 | 密钥泄露 | 只引用键名/路径，redaction 测试，secret scan 门禁 |
| R-005 | `domain_macro` 字段事后映射 | provider DTO 返工，`macro_data` 误依赖 `fred/internal/*` | 编码前冻结领域共享层契约 |
| R-006 | ms_brain runtime 未落地 | AC-009 端到端证据无法闭合 | 先 contract fixture，runtime 落地后补 E2E；不阻塞 fred 自身发布 |
| R-007 | 旧 `Stores=None` 门禁未迁移就写代码 | 正确目标被门禁误判违规 | 阶段 3 先迁门禁，再进阶段 4 实现 |

## 9. 不建议补充的内容

[INFERRED][HIGH] 不建议新增第八类持久化、第三种消息总线、fred 专属配置系统或 fred 内部通用宏观主数据框架；现有目标已覆盖用户要求，继续加组件只会扩大边界和测试负担。

[COMPUTED][HIGH] 不建议让 fred 直接拥有跨 provider 宏观冲突仲裁、统一主数据排序或因子计算；这些已被 SPEC §3 非目标排除，且更适合 `macro_data` 或分析域承担。

[INFERRED][HIGH] 不建议在本阶段生成生产级全量 infra 编排；更小的验收路径是单 series、单 provider、单 dev profile 的端到端证据。

## 10. 完成判定

[INFERRED][HIGH] fred 的目标完成不应按文件是否存在判断，而应按所有 FR/BR/AC/TC 从 `Planned`/`Pending` 更新为有证据的验证状态判断。

最低完成条件：

- `TRACEABILITY.md` 与 `SPEC.md` 的 BR 编号和含义完全一致（P0-1 闭合）。
- 配置 mapping 可审查且不包含 secret 值（P0-3 闭合）。
- `/home/fred` 不再以旧 `Stores=None` 作为目标边界（P0-2 闭合）。
- `domain_macro` 字段映射和 no-lookahead fixture 已落地（P1-3 闭合）。
- 单 series dev profile 能证明 raw archive、幂等、checkpoint、规范化 observation、durable event、读模型和 API 查询链路。
- `./scripts/boundary-gates.sh`、`go test ./...`、配置 redaction 测试、no-lookahead 测试均通过。
- AC-001..AC-009 全部 Verified，证据登记至 `ACCEPTANCE.md`。

## 11. 未验证限制

[COMPUTED][HIGH] 本报告未运行 `/home/fred` 的集成环境，也未读取 `sre/secrets/env/dev.md` 的密钥值；只使用既有 4 份报告的关键词匹配计数作为配置覆盖线索。

[COMPUTED][HIGH] 本报告未审查 `domain_macro` 的当前源码字段；`domain_macro` 具体包路径和类型名仍以 `module/fred` 未闭合项为准。

[COMPUTED][HIGH] 本报告未修改 `/home/fred` 代码或 `module/fred/` 规格文件；只产出迭代方案文档。P0-1 BR 漂移的修复留待阶段 1 执行。

[INFERRED][MED] 阶段预测分数（68→75→80+）基于 `structural-score-20260622.md` 账本的线性推断，实际分数以重跑 `spec-structural-score` / `matrix-structural-score` 为准。

## 12. 结论

[INFERRED][HIGH] fred 需要补充、优化和迭代的内容明确存在，但集中在追溯一致性、目标边界迁移、配置映射、契约细化和验收证据，不是新增更多基础设施组件。

[INFERRED][HIGH] 最短可交付路径：先修文档追溯和契约（阶段 1-2），再改 `/home/fred` 边界门禁与服务骨架（阶段 3），然后用一个最小 FRED series 打通 raw → checkpoint → observation → event → read model → API 查询证据链（阶段 4-6），最后验收发布（阶段 7）。

[RULES I BROKE]：无
