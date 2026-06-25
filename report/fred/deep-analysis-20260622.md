# module/fred 深度分析报告

- Date: 2026-06-22
- Scope: `module/fred/`, `/home/fred`, 相关架构文档、`sre/secrets/env/dev.md` 的无值匹配计数
- Branch: `docs/fred-deep-analysis-20260622`
- Question: `fred` 是否还有其他需要补充、优化、迭代

## 1. 总结判断

`fred` 还需要补充和迭代，但重点不是继续增加中间件种类，而是闭合“目标规格已经升级、运行仓和追溯矩阵仍停在旧口径”的落差。[COMPUTED][HIGH]

现有 `module/fred/SPEC.md` 已明确 `fred` 是数据域 · 宏观的独立 C/S 服务，要求共享基座组件、使用 `domain_macro`，并覆盖 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 七类介质；因此不建议再补新的持久化或消息系统。[COMPUTED][HIGH]

当前最高优先级是把 `TRACEABILITY.md` 的规则编号漂移、`/home/fred` 的旧 `Stores=None` 门禁、配置 key mapping、API/event/schema 契约和验收证据补齐。[COMPUTED][HIGH]

## 2. 证据范围

| 证据                                           | 结论                                                                                                                     | 置信度           |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------- |
| `module/fred/SPEC.md:3`                        | 规格状态仍是 `Draft`。                                                                                                   | [COMPUTED][HIGH] |
| `module/fred/SPEC.md:14`                       | 规格声明自身是目标状态，`/home/fred` 当前仍保留旧 `Stores=None` 边界口径。                                               | [COMPUTED][HIGH] |
| `module/fred/SPEC.md:50-63`                    | 功能需求覆盖启动、配置、FRED client、作业、OSS、TDengine、Postgres、Redis、Kafka、NATS、ClickHouse、API、边界门禁。      | [COMPUTED][HIGH] |
| `module/fred/SPEC.md:69-76`                    | 业务规则定义幂等、`available_at` 可见性、Kafka/NATS 分工、checkpoint、可重建读模型、OSS path、`macro_data` 边界。        | [COMPUTED][HIGH] |
| `module/fred/TRACEABILITY.md:47-53`            | 业务规则矩阵与 `SPEC.md` 的 BR-002 到 BR-007 编号存在漂移。                                                              | [COMPUTED][HIGH] |
| `module/fred/TRACEABILITY.md:71-73`            | 未闭合项已承认旧零存储门禁、`domain_macro` 类型路径、dev 配置映射三项缺口。                                              | [COMPUTED][HIGH] |
| `module/fred/IMPLEMENTATION-PLAN.md:26-33`     | 阶段 1 已计划补 `bootstrap/configx`、配置 key mapping、边界脚本迁移和 redaction 测试。                                   | [COMPUTED][HIGH] |
| `/home/fred/cmd/fred-server/main.go:1-4`       | 当前服务入口注释仍称 `adapter 零存储`。                                                                                  | [COMPUTED][HIGH] |
| `/home/fred/cmd/fred-server/main.go:17-20`     | 当前 `bootstrap.Build` 使用 `Stores: bootstrap.None`。                                                                   | [COMPUTED][HIGH] |
| `/home/fred/scripts/boundary-gates.sh:101-105` | 当前边界门禁仍禁止直接依赖 L2 存储适配器，规则名是 `no-storage-adapter`。                                                | [COMPUTED][HIGH] |
| `docs/architecture/01-overview.md:107`         | 全局架构仍写 adapter 进程使用 `Stores=None`，未区分 `fred` 目标 C/S provider service。                                   | [COMPUTED][HIGH] |
| `docs/architecture/05-foundation.md:164`       | 全局模块表把 `fred` 标为已有、进度约 `80%`。                                                                             | [COMPUTED][HIGH] |
| `sre/secrets/env/dev.md` 无值匹配计数          | 关键词 `fred/FRED/taos/tdengine/kafka/postgres/redis/oss/nats/clickhouse` 匹配计数为 33；未读取或复制 secret 值。        | [COMPUTED][HIGH] |
| `/home/fred` 验证                              | 当前 `./scripts/boundary-gates.sh` 9 项通过，`go test ./...` 通过；这只能证明旧骨架当前自洽，不能证明目标 C/S 服务完成。 | [COMPUTED][HIGH] |
| `.github/ci/spec-lint.sh`                      | 全仓 spec lint 退出码为 1；其中 `fred` 行显示 `23/23 sections, 14 FRs, 15 WHEN clauses`。                                | [COMPUTED][HIGH] |

## 3. 关键问题排序

### P0: 追溯矩阵 BR 编号漂移

`SPEC.md` 中 BR-002 是幂等，BR-003 是 `available_at` 可见性，BR-005 是 Postgres checkpoint，BR-006 是 Redis/ClickHouse 可重建，BR-007 是 OSS raw path；`TRACEABILITY.md` 把这些摘要错位到了不同编号。[COMPUTED][HIGH]

影响：后续任务、测试和验收会引用错误业务规则，导致实现通过了错误门禁或漏测真正约束。[INFERRED][HIGH]

建议：先修 `TRACEABILITY.md`，再展开 Task Spec；否则所有下游任务都会继承错误追溯链。[INFERRED][HIGH]

### P0: 目标服务边界和运行仓旧门禁冲突

`SPEC.md` 要求七类介质通过共享基座接入，`/home/fred` 当前入口和门禁仍以 `Stores=None` 和 `no-storage-adapter` 为目标。[COMPUTED][HIGH]

影响：若直接实现七类持久化，当前边界门禁可能把正确目标误判为违规；若保留当前门禁，则无法达到目标规格。[INFERRED][HIGH]

建议：把门禁从“禁止目标存储适配器”改为“允许经共享基座接入，禁止绕过基座直连驱动或在业务代码中散落基础设施细节”。[INFERRED][HIGH]

### P0: 配置映射还停在类别层

`SPEC.md` 已声明配置来源和类别，但未列出可审查的 key mapping、类型、必填性、默认值策略、redaction 规则和运行时校验错误码。[COMPUTED][HIGH]

影响：实施阶段很容易把 `sre/secrets/env/dev.md` 中的实际 secret 值带入文档、测试夹具或日志，也可能导致配置缺失时行为不一致。[INFERRED][HIGH]

建议：新增 redacted mapping 表，只写 key 名、路径、类型、是否必填、默认值来源、redaction 策略和消费组件，不写任何值。[INFERRED][HIGH]

### P1: API、事件、存储 schema 仍偏概念层

`SPEC.md` 已列出公共 API 和七类介质职责，但尚未固化 request/response 版本、错误码、Kafka topic/key/schema、NATS subject、Postgres table、TDengine supertable/tag、OSS path、Redis key namespace/TTL、ClickHouse table/view 的最小契约。[COMPUTED][HIGH]

影响：模块可以按大方向实现，但不同任务之间会在命名、幂等边界、重放语义和可观测字段上产生不兼容。[INFERRED][MED]

建议：补一份最小契约附录，不做大而全数据平台设计，只固化实现必须共享的字段和命名。[INFERRED][HIGH]

### P1: `domain_macro` 绑定仍未落地

`TRACEABILITY.md` 明确 `domain_macro` 具体类型名和包路径需在代码实施前确认，`IMPLEMENTATION-PLAN.md` 把这放在阶段 2。[COMPUTED][HIGH]

影响：如果先写 provider DTO 和私有模型，再事后映射 `domain_macro`，会增加重构成本，并提高 `macro_data` 误依赖 `fred/internal/*` 的风险。[INFERRED][MED]

建议：实现前先读取 `domain_macro` 当前代码，冻结 `MacroSeries`、`MacroObservation`、`MacroRelease`、`MacroRevision`、`MacroIngestJob` 的包路径、字段映射和 no-lookahead 夹具。[INFERRED][HIGH]

### P1: 全局架构文档口径需要分层

全局架构仍写 adapter 进程使用 `Stores=None`，并把 `fred` 标为已有、进度约 `80%`；`module/fred` 同时声明目标是独立 C/S 服务且当前运行仓仍是旧口径。[COMPUTED][HIGH]

影响：读者会以为 `fred` 已接近完成，或误认为所有 provider 都必须保持零存储 adapter 形态。[INFERRED][MED]

建议：全局文档应区分“轻量 adapter 旧口径”和“宏观 provider 独立 C/S 服务目标口径”，并把 `fred` 的进度描述改成不与 Draft 规格冲突的状态。[INFERRED][MED]

## 4. 建议补充清单

| 优先级 | 补充项                                                           | 目标文件                                                                 | 验收方式                                                                             |
| ------ | ---------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| P0     | 修正 BR 编号漂移，确保 `TRACEABILITY.md` 与 `SPEC.md` 一一对应。 | `module/fred/TRACEABILITY.md`                                            | `rg "BR-00[2-7]" module/fred/SPEC.md module/fred/TRACEABILITY.md` 人工核对无错位。   |
| P0     | 新增 redacted config mapping。                                   | `module/fred/SPEC.md` 或单独附录                                         | 映射表只含 key 名、类型、必填性、redaction 策略，不含 secret 值。                    |
| P0     | 更新 `/home/fred` 边界门禁目标。                                 | `/home/fred/scripts/boundary-gates.sh`                                   | 门禁允许共享基座存储 adapter，禁止直接驱动、私有连接池和绕过 `configx`。             |
| P0     | 增加配置 redaction 测试。                                        | `/home/fred` tests                                                       | 缺失配置 fail fast，日志和错误不泄露值。                                             |
| P1     | 冻结 `domain_macro` 绑定表。                                     | `module/fred/SPEC.md` 附录或 Task Spec                                   | 每个 FRED DTO 字段有目标 domain 字段、时区、空值、单位规则。                         |
| P1     | 固化 API 和 error contract。                                     | `module/fred/SPEC.md` 或 Task Spec                                       | API 请求、响应、状态码、错误类、版本字段可测试。                                     |
| P1     | 固化 Kafka/NATS contract。                                       | `module/fred/SPEC.md` 或 contracts 目录                                  | Kafka durable event 与 NATS control subject 不混用。                                 |
| P1     | 固化七类介质最小 schema。                                        | `module/fred/SPEC.md` 附录或 Task Spec                                   | 单 series backfill 能证明 raw、metadata、observation、cache、read model 和事件一致。 |
| P1     | 补 no-lookahead 和 revision fixture。                            | `/home/fred` tests                                                       | `released_at < available_at` 时，下游查询在 `available_at` 前不可见。                |
| P2     | 更新全局架构口径。                                               | `docs/architecture/01-overview.md`, `docs/architecture/05-foundation.md` | 不再把 `fred` 目标误读为普通零存储 adapter。                                         |

## 5. 不建议补充的内容

不建议新增第八类持久化、第三种消息总线、fred 专属配置系统或 fred 内部通用宏观主数据框架；现有目标已经足够覆盖用户要求，继续加组件只会扩大边界和测试负担。[INFERRED][HIGH]

不建议让 `fred` 直接拥有跨 provider 的宏观冲突仲裁、统一主数据排序或因子计算；这些已经被 `SPEC.md` 非目标排除，且更适合 `macro_data` 或分析域承担。[COMPUTED][HIGH]

不建议为了“完整”而在本阶段生成生产级全量 infra 编排；更小的验收路径是单 series、单 provider、单 dev profile 的端到端证据。[INFERRED][HIGH]

## 6. 推荐迭代顺序

1. 规格修正迭代：修正 `TRACEABILITY.md` BR 漂移，补 config mapping、API/event/schema 最小契约，把 `Draft` 推进到可审查状态。[INFERRED][HIGH]
2. 边界迁移迭代：改 `/home/fred` 的 `Stores=None` 入口和 `no-storage-adapter` 门禁，建立共享基座接入规则。[INFERRED][HIGH]
3. 领域映射迭代：先绑定 `domain_macro`，再写 FRED DTO 转换和 no-lookahead 夹具。[INFERRED][HIGH]
4. 最小写入迭代：用单个 series 证明 OSS raw、Postgres checkpoint/idempotency、TDengine observation、Kafka event 的一致性。[INFERRED][HIGH]
5. 读模型和控制面迭代：补 Redis、ClickHouse、NATS 和 API/client，验证可重建与控制面不替代 durable event。[INFERRED][MED]
6. 验收发布迭代：更新 traceability 状态和证据，跑 `/home/fred` 单元、契约、边界、集成、redaction、no-lookahead 测试。[INFERRED][HIGH]

## 7. 完成判定

`fred` 的目标完成不应按文件是否存在判断，而应按所有 FR、BR、AC、TC 从 `Planned` 更新为有证据的验证状态判断。[INFERRED][HIGH]

最低完成条件如下：[INFERRED][HIGH]

- `TRACEABILITY.md` 与 `SPEC.md` 的 BR 编号和含义完全一致。
- 配置 mapping 可审查且不包含 secret 值。
- `/home/fred` 不再以旧 `Stores=None` 作为目标边界。
- `domain_macro` 字段映射和 no-lookahead fixture 已落地。
- 单 series dev profile 能证明 raw archive、幂等、checkpoint、规范化 observation、durable event、读模型和 API 查询链路。
- `./scripts/boundary-gates.sh`、`go test ./...`、配置 redaction 测试、no-lookahead 测试均通过。

## 8. 未验证限制

没有读取 `sre/secrets/env/dev.md` 的具体 secret 值，本报告只使用关键词匹配计数作为配置覆盖线索。[COMPUTED][HIGH]

没有在本次报告中修改 `/home/fred` 代码或启动真实 dev infra，因此无法证明七类介质的运行时连接可用。[COMPUTED][HIGH]

没有在本次报告中审查 `domain_macro` 的当前源码字段，因此 `domain_macro` 具体包路径和类型名仍以 `module/fred` 未闭合项为准。[COMPUTED][HIGH]

## 9. 结论

需要补充、优化和迭代的内容明确存在，但它们集中在追溯一致性、目标边界迁移、配置映射、契约细化和验收证据，不是新增更多基础设施组件。[INFERRED][HIGH]

最短可交付路径是先修文档追溯和契约，再改 `/home/fred` 边界门禁与服务骨架，然后用一个最小 FRED series 打通 raw、checkpoint、observation、event、read model 和 API 查询证据。[INFERRED][HIGH]

[RULES I BROKE]：无
