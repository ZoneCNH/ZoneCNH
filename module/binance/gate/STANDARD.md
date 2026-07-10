# module/binance STANDARD.md — 发布与漂移标准

## Metadata

| Field | Value |
| --- | --- |
| Module-Version | v4.1.0 |
| Last-Updated | 2026-07-09 |
| Status | Active |
| Scope | `module/binance` 文档 gate、runtime release evidence、命名漂移与发布阻断标准 |
| Runtime-Repo | `/home/workspace/binance` |

> [FRAME, HIGH] 本文件是 `module/binance` 发布治理标准，不替代 `module/binance/spec/SPEC.md`、`module/binance/spec/NAMING.md`、`module/binance/matrix/TRACEABILITY.md` 或 runtime 仓证据。
>
> [COMPUTED, HIGH] 截至 2026-07-09，本仓文档 worker 只负责修复文档 gate 与标准；runtime worker 未合并最终证据前，本文件不得被解读为生产发布批准。

## 1. 业务边界

[FRAME, HIGH] `binance` 模块只承载 Binance 公共市场数据 ingestion、规范化、持久化、查询、白名单准入、下游 fanout 与订单簿行情状态机。

| 范围 | 标准 |
| --- | --- |
| 公共行情 | 允许采集 spot、um_perp、cm_perp、options 的公开 market data。 |
| 订单簿 | 允许维护 spot、um_perp、cm_perp 的本地 order book；options order book 仅在 §5 Phase 2 条件满足后激活。 |
| 白名单 | 以 PG 双表和 tierCapabilityMap 为准入 SSOT；runtime 配置文件不得重新引入多套白名单。 |
| 存储 | 原始事件进入 taosx；元数据、白名单和审计进入 postgresx；热缓存进入 redisx；下游桥接进入 kafkax；冷归档进入 ossx；OLAP 投影进入 clickhousex。 |
| 查询 | Gin REST/Admin API 只暴露 market data、health/readiness、白名单刷新和 order book health。 |
| Fanout | NATS JetStream 是主事件总线；Kafka 是 bridge-only 投影，不得替代 NATS 契约。 |
| 禁止 | 下单、账户管理、用户私有流、交易策略、生产凭证和私有端点不属于本模块。 |

[COMPUTED, HIGH] 当前白名单/符号刷新管理端点锚点为 `POST /api/v1/admin/symbols/reload`。旧规划名 `/api/v1/admin/catalog/reload` 不得作为 active contract 重新引入。

## 2. 产品线矩阵

[FRAME, HIGH] 产品线只允许 `spot`、`um_perp`、`cm_perp`、`options`。交割合约不新增 product_line，必须通过 `instrument_subtype=delivery` 表达。

| product_line | 默认启用策略 | 当前支持的 implemented event_type | Unsupported / postponed |
| --- | --- | --- | --- |
| `spot` | `prime`/`standard`/`lite` 按 tierCapabilityMap 启用；`blocked` 禁止采集。 | `book_ticker`, `trade`, `kline`, `depth_update` | `funding_rate`, `mark_price_update` 不适用。 |
| `um_perp` | `prime`/`standard`/`lite` 按 tierCapabilityMap 启用；永续与交割由 `instrument_subtype` 区分。 | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update` | 不得拆出 `um_delivery`。 |
| `cm_perp` | `prime`/`standard`/`lite` 按 tierCapabilityMap 启用；永续与交割由 `instrument_subtype` 区分。 | `book_ticker`, `trade`, `kline`, `depth_update`, `funding_rate`, `mark_price_update` | 不得拆出 `cm_delivery`。 |
| `options` | 默认需要人工审核或显式 tier 准入；采集分桶与准入层解耦。 | `trade`, `kline`, `depth_update`, `option_tick` raw stream | `book_ticker`, `funding_rate`, `mark_price_update` 不适用；order book manager Phase 2 postponed。 |

> [COMPUTED, HIGH] 扩展能力当前投影：`ticker`（四产品线可显式解析，spot/UM/CM 默认订阅；options 需显式配置）、`open_interest`（options 的 `optionOpenInterest` 数组流）、`index_reference`（UM/CM 的 composite/asset/reference 变体，CM 不适用的组合仍标记）、`contract_info`（UM/CM `!contractInfo` 全局流）。`force_order` 为 UM/CM 独立 opt-in scaffold，默认不订阅，仍需独立 live gate；所有扩展的 external durable/fanout/query 证据由 release checklist 管理。

[FRAME, HIGH] 2026-07-10 当前口径：`ticker`、`open_interest`、`index_reference`、`contract_info` 已有 runtime local normalize→storage/query 链路；`force_order` 只有隔离的 opt-in scaffold，仍为 postponed release。五类都不能由本地测试替代 external release evidence；force_order 另须 release owner 独立批准。

## 3. Canonical event_type 与迁移

[FRAME, HIGH] 既有稳定 canonical event_type 为以下 7 个；扩展类型状态见本节当前口径：

```text
book_ticker
trade
kline
depth_update
funding_rate
mark_price_update
option_tick
```

[FRAME, HIGH] 扩展 canonical event_type 为以下 5 个，其中 force_order 为 opt-in/postponed，其余四类已完成 local runtime chain：

```text
ticker
force_order
open_interest
index_reference
contract_info
```

| 命名面 | Canonical 模板 |
| --- | --- |
| NATS subject | `binance.market.{product_line}.{event_type}.v1` |
| Kafka topic | `binance.{product_line}.{event_type}.v1` |
| TDengine supertable | `{event_type}`，不加 `st_` 前缀。 |
| Redis latest key | `binance:{event_type}:{product_line}:{symbol}` |
| OSS path | `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` |
| REST query path | `GET /api/v1/market/{event_type}/:symbol` |

[FRAME, HIGH] legacy alias 只允许出现在 `spec/NAMING.md`、历史 changelog、归档 task、报告和漂移证据中。新契约不得使用 `tick`、`bar`、`depth`、`mark_price`、`st_tick`、`st_bar`、`st_depth` 或 `st_mark_price`。

[FRAME, HIGH] 双发窗口必须有明确任务、开始日期、结束日期、下游消费者确认和 rollback 条件。无截止日期的 dual publish 等同于漂移，不能通过 release gate。

## 4. 合约身份标准

[FRAME, HIGH] runtime payload identity 必须由 `domain_market`/`contracts` canonical 类型承载，binance 只做 Binance 私有码到 canonical 字段的边界转换。

| 字段 | 标准 |
| --- | --- |
| `exchange` | 固定为 `binance`。 |
| `product_line` | `spot`、`um_perp`、`cm_perp`、`options`。 |
| `instrument_type` | 来自 canonical domain 类型，不得在 binance 本地另建枚举。 |
| `instrument_subtype` | `PERPETUAL` 映射为 `perpetual`；`CURRENT_QUARTER`、`NEXT_QUARTER`、带交割日期的合约映射为 `delivery`；不得只靠 symbol 字符串猜测。 |
| `symbol` | 保留交易所原始 symbol，同时提供 canonical identity 字段。 |
| `expiry`/`strike`/`option_type` | options 必填；spot 不适用；perp 为 null 或 canonical zero value。 |

[FRAME, HIGH] `contractType`、`deliveryDate`、`expiryDate` 等交易所字段必须进入解析证据。仅通过 `BTCUSDT_240329` 这类字符串后缀推断 delivery 身份，不能作为生产级依据。

## 5. Options 支持级别

[FRAME, HIGH] options 当前只允许声明 raw market stream 与 identity/catalog 能力。options order book manager 激活前必须满足以下全部条件：

| Phase 2 条件 | 必需证据 |
| --- | --- |
| 官方 payload capture | testnet 或公开样本覆盖增量、快照、断线重连和异常序号。 |
| 序号规则 | 明确 options depth 的 `U/u/pu` 或等价字段规则；没有规则时不得复用 futures 校验。 |
| 对齐算法 | REST snapshot 与 WS buffer 的 initial alignment 可重复验证。 |
| 存储契约 | TDengine/Redis/OSS key 均使用 `depth_update` canonical event_type。 |
| 下游语义 | 非 ALIGNED 时输出 `stale=true`，做市、风控、策略消费者必须暂停使用该 symbol order book。 |
| 回归测试 | spot、um_perp、cm_perp 不因 options 分支回归。 |

## 6. Order Book 标准

[FRAME, HIGH] order book 发布证据必须覆盖状态机、对齐、重建、checksum 和下游停用语义。

| 维度 | 标准 |
| --- | --- |
| 状态机 | `UNINITIALIZED -> BUFFERING -> ALIGNED -> REBUILDING`，per-symbol 独立运行，不用全局锁阻塞全部 symbol。 |
| 初始对齐 | REST snapshot 与 WS buffer 按交易所序号规则闭合；无法闭合时重新拉快照。 |
| 序号校验 | spot 使用 spot depth 规则；um_perp/cm_perp 使用 futures depth 规则；不得跨产品线复用未知规则。 |
| 自动重建 | gap、checksum drift、snapshot mismatch 必须触发 per-symbol rebuild，并记录 rebuild_start/rebuild_complete。 |
| Checksum | 至少采样式 REST snapshot vs memory book diff；发布证据需包含采样频率和失败处理。 |
| Stale 语义 | `stale=true` 表示该 symbol order book 不可用于交易、风控或做市决策；下游必须暂停使用，直到恢复 ALIGNED。 |
| TopN | TopN snapshot 可以继续输出最后已知值，但必须附 `stale=true`。 |

## 7. Foundation 依赖版本标准

[FRAME, HIGH] 发布证据必须证明 runtime clean checkout 使用单一、可解析、可复现的 Foundation 依赖版本线。

| 依赖 | 标准 |
| --- | --- |
| `contracts` | C/S DTO canonical 来源；禁止 `contracts` v0/v1 版本线打架。`go list -m all` 与 `go mod graph` 必须证明只有一个可用主版本线满足 runtime 引用字段。 |
| `domain_market` | InstrumentKey 与市场身份 canonical 来源；binance 不拥有 domain enum。 |
| `natsx` | NATS JetStream 发布/消费；subject 必须使用 `binance.market.{product_line}.{event_type}.v1`。 |
| `kafkax` | downstream bridge；topic 必须使用 `binance.{product_line}.{event_type}.v1`。 |
| `taosx` | 原始 time-series 存储；stable 名必须等于 canonical event_type。 |
| `postgresx` | catalog、whitelist、审计、幂等元数据；migration 必须可幂等重跑。 |
| `redisx` | hot cache、幂等、锁和限流；key 必须使用 canonical event_type。 |
| `ossx` | cold archive；path 必须使用 canonical event_type。 |
| `clickhousex` | OLAP 投影；不得冒充原始事件 SSOT。 |

[COMPUTED, HIGH] `todo.md` 当前记录了 `contracts v0.5.2` 规格引用与 runtime `contracts v1.4.0` 解析的版本线风险。runtime worker 未给出 clean checkout `go test ./...` 证据前，不能把该风险关闭。

## 8. 发布证据清单

[FRAME, HIGH] 发布前必须重新生成以下 evidence，不能复用过期本地输出：

| Gate | 必需命令或证据 |
| --- | --- |
| Clean checkout | 从干净 clone 或 clean worktree 运行，不依赖本地 `replace` 或未提交代码。 |
| Build/Test | `go test ./...`、`go vet ./...`、必要包 `go test -race ./...`。 |
| Runtime boundary | `/home/workspace/binance/scripts/boundary-gates.sh` 全 PASS。 |
| Runtime drift | `/home/workspace/binance/scripts/spec-runtime-drift-check.sh` 全 PASS。 |
| Docs drift | 在本仓运行 `bash scripts/check-binance-docs.sh`。 |
| Live capture | WS capture、NATS PubAck/ManualAck、storage/fanout/query E2E 证据。 |
| Order book | alignment、rebuild、checksum、stale=true 下游暂停证据。 |
| Release | 远端 CI URL、release tag、release notes、部署前检查、回滚路径。 |

## 9. Gate 职责边界

[FRAME, HIGH] 本仓 `scripts/check-binance-docs.sh` 是 L1 文档治理 gate，只扫描以下 goal-driven 文档：

```text
module/binance/spec/SPEC.md
module/binance/spec/NAMING.md
module/binance/matrix/TRACEABILITY.md
module/binance/gate/RULES.md
module/binance/gate/STANDARD.md
```

[FRAME, HIGH] 该脚本检查 canonical event_type、产品线、subject/topic/storage/REST 命名锚点和本标准的漂移规则。它不读取或修改 runtime 仓，也不证明 runtime 功能正确。

[FRAME, HIGH] runtime 侧 gate 仍由 `/home/workspace/binance/scripts/boundary-gates.sh`、`spec-runtime-drift-check.sh`、`go test ./...` 和 release CI 负责。两类 gate 均通过后，才允许合并最终 evidence。

## 10. Stop Conditions

[FRAME, HIGH] 出现以下任一情况，必须保持 `No-Go`：

| 条件 | 原因 |
| --- | --- |
| `go test ./...` 在 clean checkout 失败 | build/test 是 release gate 基线。 |
| `contracts` 或其他 Foundation 依赖出现不可解析版本线 | 契约身份不稳定。 |
| active subject/topic/stable/key/path 使用 legacy event_type | 下游契约漂移。 |
| options order book 缺少官方 payload capture | 无法证明对齐与重建算法适用。 |
| order book `stale=true` 下游暂停规则无证据 | 风控/做市可能使用坏 book。 |
| release tag、CI、release notes、rollback evidence 不一致 | 发布事实不可追溯。 |

## 11. Change History

| Date | Version | Change |
| --- | --- | --- |
| 2026-07-09 | v4.1.0 | 升级为发布与漂移标准：补业务边界、产品线矩阵、canonical event_type、合约身份、options Phase 2、order book、Foundation 依赖版本、发布证据和 docs/runtime gate 职责边界。 |
| 2026-07-06 | v4.0.0 | 建立 FR-024 runtime control 标准入口。 |

[RULES I BROKE]：无
