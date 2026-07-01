# 模块边界定义 — 彻底解耦架构报告（2026-06-25 更新验证）

- **Date**: 2026-06-25（更新验证）
- **Scope**: 20 个基座模块 + 5 个领域共享层模块 + `module/binance`
- **Evidence base**: go.mod require + `.go` import 代码级扫描（2026-06-25 实时证据线）
- **权威参考**: `CONSTITUTION.md §2`、`docs/constitution/02-module-boundaries.md`、`docs/architecture/03-boundaries.md`
- **前置报告**: `foundationx-binance-decoupling-architecture-20260624.md`

## 1. 分层概览

```text
┌─────────────────────────────────────────────────────┐
│ [治理/证据元层]  xlib_standard · xlib_harness       │
│                 xlib_evidence · xlibgate             │
│                 (零 ZoneCNH require，不参与业务运行) │
├─────────────────────────────────────────────────────┤
│ [L0]  kernel     (stdlib-only 最小原语)              │
├─────────────────────────────────────────────────────┤
│ [L1 运行时]  configx · observex · resiliencx         │
│             schedulex · testkitx (test-only)          │
│             (零 ZoneCNH require 的叶子基座)          │
├─────────────────────────────────────────────────────┤
│ [L1.5 infra]  redisx · kafkax · natsx · postgresx   │
│               taosx · ossx · clickhousex              │
│               contracts · transportx ✅ 已修复        │
│               (0 同层真实互耦，仅合规横切 observex    │
│                /resiliencx)                           │
├─────────────────────────────────────────────────────┤
│ [装配层]  bootstrap  (唯一跨 CORE+INFRA 聚合点)      │
├─────────────────────────────────────────────────────┤
│ [L2 领域共享]  decimalx(根锚点) · domainx ✅ 已补    │
│               domain_market · domain_macro            │
│               domain_exchange                        │
│               (纯度红线：零 infra/binance import)     │
├─────────────────────────────────────────────────────┤
│ [L3 业务模块]  module/binance                        │
│   ├── binance_core     (业务核心，持有窄接口 ports)   │
│   ├── binance_client   (采集端，不 import server)     │
│   ├── binance_server   (处理端，不 import client)     │
│   └── binance_assembly (cmd/*，仅构造注入)            │
└─────────────────────────────────────────────────────┘
```

## 2. 基座治理与证据模块（非运行时）

| 模块 | Owner（代码实证） | 明确不做 |
|------|------------------|---------|
| `xlib_standard` | [COMPUTED, HIGH] 标准 API、模板、门禁规则、release evidence runtime。零 ZoneCNH require。 | 不提供运行时代码，不依赖任何业务/infra/domain 模块。 |
| `xlib_harness` | [COMPUTED, HIGH] 标准化验证 harness、合规检查入口。零 ZoneCNH require。 | 不成 production dependency；fixtures 中的 observex import 是负向测试样本。 |
| `xlib_evidence` | [COMPUTED, HIGH] 证据采集、报告、审计材料结构。零 ZoneCNH require。 | 不成运行时链路，不写业务状态。 |
| `xlibgate` | [COMPUTED, HIGH] 依赖/边界/质量 gate 扫描与判定。零 ZoneCNH require。 | 不被运行时 import；`DefaultForbiddenModules` 把 infra 列为被审计对象而非依赖。 |

## 3. 基座运行时核心（零依赖叶子基座）

| 模块 | Owner（代码实证） | 明确不做 |
|------|------------------|---------|
| `kernel` | [COMPUTED, HIGH] errx/healthx/lifecycx/shutdownx/timex 等最小稳定 primitives。零 require。 | 不解析配置、不绑定 observability backend、不连 storage/network。 |
| `configx` | [COMPUTED, HIGH] 配置 source/merge/decode/secret binding/redaction/provenance。零 require。 | 不拥有各模块 typed Config 语义，不启动组件。 |
| `observex` | [COMPUTED, HIGH] log/metric/trace/health 接口与 adapter contract。零 require。 | 不硬编码业务标签，不拥有业务告警策略。 |
| `testkitx` | [COMPUTED, HIGH] contract/golden/fixture/harness/boundary evidence。零 require。 | **不进 production import graph**。 |
| `resiliencx` | [COMPUTED, HIGH] retry/timeout/circuit/backoff/bulkhead primitive。零 require。 | 不 import 业务/storage；不写业务重试策略。 |
| `schedulex` | [COMPUTED, HIGH] scheduler/lease-aware job/tick/cron primitive。零 require。最干净模块之一。 | 不拥有 ETL/归档业务内容，不 import storage/client。 |

## 4. 基础设施扩展层（storage / message / transport）

> [COMPUTED, HIGH] 7 个 infra 模块 **0 处真实同层互耦**。所有"兄弟模块引用"均为发布工具链中的字符串 manifest 字面量，非 Go import 声明。

| 模块 | Owner（代码实证） | 明确不做 |
|------|------------------|---------|
| `redisx` | Redis client/pool、SetNX/TTL/lock/cache。零 ZoneCNH require。 | 不知 Binance subject/symbol/ack 语义；不依赖兄弟 infra。 |
| `kafkax` | Kafka producer/consumer/admin。require observex（横切合规）。 | 不定义业务 topic 命名规则；不依赖兄弟 infra。 |
| `natsx` | NATS/JetStream stream/publish/durable consumer/ManualAck/Nak。零 require。 | 不决定 Binance 消息何时 Ack，不解析 payload。 |
| `postgresx` | Postgres connection/transaction/migration/query。零 require。 | 不拥有 instrument catalog 业务 schema；不依赖兄弟 infra。 |
| `taosx` | TDengine 时序写入查询。零 require。 | 不定义 retention/归档业务规则；不依赖兄弟 infra。 |
| `ossx` | Object storage client/bucket/path/ETag。require resiliencx（横切合规）。 | 不决定 parquet 分区策略；不依赖兄弟 infra。 |
| `clickhousex` | ClickHouse OLAP 写入查询。require observex/resiliencx（横切合规）。 | 不拥有分析 API 语义；不依赖兄弟 infra。 |
| `contracts` | 跨域 ports/event protocols/稳定 DTO。零 ZoneCNH require。 | 不放 domain-internal interface，不放临时 adapter。 |
| `transportx` | 通信基础契约/wire envelope/codec/QoS/error mapping。✅ go.mod module name 已修复。 | 不绑定具体 broker SDK；不包含 domain 全量集合。 |

## 5. 装配层

| 模块 | Owner（代码实证） | 明确不做 |
|------|------------------|---------|
| `bootstrap` | [COMPUTED, HIGH] composition root：require 全部 6 基座 + 7 infra。唯一跨 CORE+INFRA 聚合点。 | 不定义业务模型，不处理行情语义；**应单列为"装配层"**。 |

## 6. 领域共享层

> [COMPUTED, HIGH] 纯度红线成立：5 个领域模块对 binance/provider/infra 全部 **0 命中**（仅测试文件中的字符串字面量如 mock adapter name "binance"）。依赖单向链：`domain_exchange → domain_market + domainx → decimalx`，无环无反向。

| 模块 | Owner（代码实证） | 明确不做 |
|------|------------------|---------|
| `decimalx` | [COMPUTED, HIGH] 精确数值/quantization/rounding/scale 语义 root。**零 ZoneCNH require，整个依赖图的根锚点**。 | 不放交易所精度规则，不依赖任何上层。 |
| `domainx` | [COMPUTED, HIGH] Portfolio/order/position/account 等 exchange-neutral 领域值对象。require decimalx。✅ **2026-06-25 已补 go.mod**。 | 不实现 order lifecycle engine，不连 RPC/network。 |
| `domain_market` | [COMPUTED, HIGH] Market data canonical values/`InstrumentKey`/`MarketFactEnvelope`。require decimalx。 | 不实现 provider adapter，不放 DB tags。 |
| `domain_macro` | [COMPUTED, HIGH] Macro observation/status/info set canonical values。require decimalx。 | 不连 transport/storage，不定义 provider client。 |
| `domain_exchange` | [COMPUTED, HIGH] Exchange interface/adapter SPI，返回 canonical types。require decimalx + domain_market + domainx。 | 不拥有 order state SSOT，不复制 market value objects。 |

## 7. module/binance 子边界

| 子边界 | Owner | 明确不做 |
|--------|-------|---------|
| `binance_core` | WS/REST 协议适配、raw event normalize、canonical mapper、业务校验、idempotency key、ack/archive/fanout policy。**持有窄接口**（六边形 ports）。 | 不创建 `natsx`/`redisx`/`postgresx`/`taosx`/`kafkax`/`ossx`/`clickhousex` 客户端；不解析 env/config file。 |
| `binance_client` | Binance 采集端、产品线订阅、event mapping、publish port 调用。 | 不 import server internals，不自实现 JetStream publisher，不持有 server storage。 |
| `binance_server` | consume 后处理编排、validate、幂等判定、storage/cache/fanout/archive/API policy。 | 不 import client internals，不自实现 infra client/pool，不拥有通用 lifecycle framework。 |
| `binance_assembly` | `cmd/*`：构造全部 infra client 并注入；`os.Getenv` 仅在此处 + `test/`。 | 不写业务算法；应统一经 `binancecfg.Load` 装配。 |

## 8. 边界违规判定体系

| 违规类型 | 严重性 | 示例 | 当前代码状态 |
|----------|--------|------|-------------|
| 反向依赖 | **CRITICAL** | 数据域 import 分析域 / Foundation import binance | [COMPUTED, HIGH] PASS（0 命中） |
| 跨域数据职责 | **CRITICAL** | 数据域包含因子计算逻辑 | [COMPUTED, HIGH] PASS |
| 越界职责 | **HIGH** | `resiliencx` 包含交易风控逻辑 | [COMPUTED, HIGH] PASS |
| 重复定义 | **HIGH** | 业务域自定义 Price 类型而非使用 L2.5 | [COMPUTED, HIGH] PASS |
| 过度抽象 | **MEDIUM** | 为未来可能的需求创建接口 | [COMPUTED, MED] binance `internal/wire` 自包含契约为过渡态 |
| Assembly 越界 | ~~**MEDIUM**~~ | core 包内直接构造 infra 客户端 | ~~[COMPUTED, MED]~~ ✅ **已修复**（2026-06-25） |
| Module name bug | ~~**HIGH**~~ | transportx go.mod 声明为 xlib_standard | ~~[COMPUTED, HIGH]~~ ✅ **已修复**（2026-06-25） |

## 9. 边界仲裁优先级

当两个模块的边界存在争议时，按以下优先级裁定（`CONSTITUTION.md §2.3`）：

1. 宪法第一条设计原则（`03-boundaries.md` 硬门禁）
2. `module/*/SPEC.md` 中的"明确不做"声明
3. `ARCHITECTURE.md` 中的依赖拓扑
4. `module/foundation-modules.md` 中的能力需求

## 10. 已知边界隐患与迁移落点

### 10.1 ~~[高] transportx module name bug~~ ✅ 已修复

`/home/workspace/transportx/go.mod` 现已声明 `module github.com/ZoneCNH/transportx`。

### 10.2 ~~[高] domain_* module path 下划线 vs 连字符分叉~~ ✅ 已修复

domain_market/macro/exchange 的 main go.mod 统一为 `github.com/ZoneCNH/domain_*`（snake_case 下划线）。

### 10.3 ~~[中] domainx 主目录无 go.mod~~ ✅ 已修复

`/home/workspace/domainx/go.mod` 已存在，`module github.com/ZoneCNH/domainx`。

### 10.4 ~~[中] binance client assembly 越界~~ ✅ 已修复

`internal/client/runtime.go` 的 `natsx.New` 已移除；`RunStandalone` 强制要求 `IngestEndpoint` 注入。

### 10.5 [中] binance-server cmd 仍直接读 os.Getenv

`cmd/binance-server/main.go` 仍直接读取 `os.Getenv("MODE")`、`os.Getenv("XGO_BINANCE_KAFKA_BROKERS")` 等，应统一走 `binancecfg.Load`。

### 10.6 [中] binance internal/wire 未迁移到 contracts

ADR-002 过渡态，binance 未 import `contracts`/`transportx`。`internal/wire/` 仍存在 3 文件（`doc.go`, `transport.go`, `types.go`）。

### 10.7 [低] bootstrap 分层定位需明确

bootstrap require 全部 CORE+INFRA，建议单列为"装配层"而非"基座核心层"。

## 11. Import Gate 强制执行清单

| Gate | 规则 | 当前状态 |
|------|------|---------|
| Foundation reverse dependency | kernel/configx/observex/resiliencx/schedulex/testkitx/*x/contracts 禁止 import binance | ✅ PASS |
| Domain shared purity | decimalx/domainx/domain_market/domain_macro/domain_exchange 禁止 import binance/provider/infra | ✅ PASS |
| Infra sibling isolation | 7 个 infra 模块禁止互相 import（manifest 字符串除外） | ✅ PASS |
| Binance core purity | `internal/client`/`internal/server` 核心包禁止 import concrete infra 构造函数 | ✅ PASS（已修复） |
| Assembly-only infra | concrete infra `*.New` 构造只允许出现在 `cmd/**` | ✅ PASS |
| Client/server boundary | client 禁止 import server internals；server 禁止 import client internals | ✅ PASS |
| No duplicate infra wrapper | 禁止 `internal/infra/{redis,nats,kafka,...}` 通用 wrapper | ✅ PASS |
| No provider DTO leak | domain_*/contracts 禁止出现 Binance raw field/SDK type | ✅ PASS |
| Config/lifecycle split | `module/binance/internal/**` 禁止直接 `os.Getenv` | ✅ PASS（仅 test 文件） |
| go.mod module path | 所有模块 go.mod module 声明与目录名一致（snake_case） | ✅ PASS（已修复） |

[RULES I BROKE]: 无
