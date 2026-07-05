# 架构深度分析：当前结构性问题报告

> **归档说明（2026-07-05）**：本报告中"internal/wire 未迁移 contracts"相关条目（R3/§3.3 等，ADR-002 过渡态）已由 [ADR-007](../../module/binance/design/ADR-007-wire-to-contracts-migration.md) 闭环——`internal/wire` 已删除，C/S 契约迁入 `contracts` canonical（v0.5.0），binance 经 `internal/ingestcodec` boundary 引用。下文相关描述为 2026-06-25 时点状态，保留作历史追溯，不作为当前事实。

- **Date**: 2026-06-25
- **Scope**: FoundationX 20 基座模块 + 5 领域共享层 + `module/binance`
- **分析类型**: 架构/结构性问题深度分析（非功能缺陷）
- **证据来源**: 实时代码扫描（`go.mod` + `.go` import + 具体文件内容）
- **置信度**: [COMPUTED, HIGH] 除少量推断项外，所有结论均来自可复现命令

> **核心发现**：解耦的"硬门禁"（反向依赖、领域纯度、infra 同层互耦）已经通过；但**模块内部职责分层、依赖方向反转、配置 mega-struct、空模块**等结构性问题尚未解决。当前架构不是"已解耦"，而是"硬门禁通过但软结构脆弱"。

---

## 1. 执行摘要：Top 5 结构性问题

| #   | 问题                                                                        | 严重度       | 宪法条款                        | 证据                                                                                                                                                                       |
| --- | --------------------------------------------------------------------------- | ------------ | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| 1   | **binance 依赖 bootstrap**（依赖方向反转）                                  | **CRITICAL** | §3.1 依赖拓扑                   | `cmd/binance-server/main.go` import `github.com/ZoneCNH/bootstrap/pkg/bootstrap`                                                                                           |
| 2   | **binance internal/server 非纯 core**，直接 import 7 个 concrete infra 模块 | **CRITICAL** | §2.2 边界违规（越界职责）       | `runtime_adapters.go`、`kafka_dispatch.go`、`consumer.go`、`pg_log.go`、`redis_store.go`、`oss_archiver.go`、`taos_writer.go`、`clickhouse_olap.go` 均直接 import infra 包 |
| 3   | **contracts 与 transportx 零消费者**（空模块/架构死重）                     | **HIGH**     | §2.5 模块增殖约束（奥卡姆剃刀） | 全局 `rg "github.com/ZoneCNH/(contracts                                                                                                                                    | transportx)"` 命中 0 个非自身 Go 文件 |
| 4   | **binancecfg 是 mega-config**（配置语义未真正下放到各模块）                 | **HIGH**     | §3 配置机制 owner 唯一性        | `Config` 结构体包含 NATS/Redis/Postgres/Taos/Kafka/ClickHouse/OSS 全部子配置                                                                                               |
| 5   | **internal/wire 自包含契约**（重复 contracts 职责）                         | **HIGH**     | §2.2 重复定义                   | `internal/wire/types.go` 定义 `IngestRequest`/`IngestResult`，与 `module/contracts` 职责重叠                                                                               |

---

## 2. 依赖图结构性脆弱分析

### 2.1 扇入/扇出矩阵

| 模块              | 扇出（direct require） | 扇入（被依赖）           | 脆弱性                                      |
| ----------------- | ---------------------- | ------------------------ | ------------------------------------------- |
| `binance`         | 13 个 ZoneCNH 模块     | 0（业务顶层）            | 极宽依赖面，任何下层模块变动都可能引发升级  |
| `bootstrap`       | 11 个 ZoneCNH 模块     | 1（binance）             | 被 binance 依赖后，从"装配层"降级为"必选库" |
| `domain_exchange` | 3                      | 2+（binance, contracts） | 依赖链末端，版本替换风险                    |
| `contracts`       | 5                      | 0                        | **无消费者，架构死重**                      |
| `transportx`      | 4                      | 0                        | **无消费者，架构死重**                      |
| `decimalx`        | 0                      | 5+                       | 根锚点，合理                                |
| `kernel`          | 0                      | 多                       | 合理，L0 根                                 |

### 2.2 关键反转：binance → bootstrap

```text
设计意图：
  application (cmd/*) → bootstrap（装配）
  application (cmd/*) → binance（业务库）
  bootstrap 不应被 binance import

现实：
  binance/cmd/binance-server/main.go
    └─ import "github.com/ZoneCNH/bootstrap/pkg/bootstrap"

后果：
  1. bootstrap 从"可替换的装配策略"变成 binance 的硬依赖
  2. 任何使用 binance 的模块/应用都必须引入 bootstrap
  3. 违反 §3.1 "单向下行"：业务模块反向依赖了入口/装配层
```

[COMPUTED] 证据：`rg "github.com/ZoneCNH/bootstrap" /home/workspace/binance/ --type go -l` → `/home/workspace/binance/cmd/binance-server/main.go`。

### 2.3 同层互耦：infra 表面干净，但 binance 内部成了"小 infra 聚合层"

虽然 `redisx`/`kafkax`/`natsx` 等 7 个模块之间无互相 import，但 `binance/internal/server` 同时 import 了其中 6 个：

```go
// internal/server/runtime_adapters.go
import (
    "github.com/ZoneCNH/clickhousex/pkg/clickhousex"
    "github.com/ZoneCNH/kafkax/pkg/kafkax"
    "github.com/ZoneCNH/natsx/pkg/natsx"
    "github.com/ZoneCNH/redisx/pkg/redisx"
    "github.com/ZoneCNH/taosx/pkg/taosx"
)
```

[INFERRED] 这意味着：infra 层的"横向隔离"被 binance 内部的"纵向聚合"所抵消。binance 不是业务 core，而是隐式装配层。

### 2.4 空模块风险：contracts 与 transportx

```text
rg "github.com/ZoneCNH/contracts" /home/{binance,kernel,configx,observex,resiliencx,schedulex,bootstrap,redisx,kafkax,natsx,postgresx,taosx,ossx,clickhousex,transportx,domainx,domain-market,domain-macro,domain-exchange}/ --type go -l
→ 0 命中

rg "github.com/ZoneCNH/transportx" /home/{...同上...}/ --type go -l
→ 0 命中
```

[INFERRED] 这两个模块当前对运行系统**无贡献**。它们可能是：

- 未来规划占位（违反 §2.5 YAGNI 禁令）
- 设计规格已过时，但代码未清理
- 迁移目标（internal/wire 应迁到 contracts，envelope 应迁到 transportx），但迁移未完成

无论哪种情况，都构成**架构债务**：维护者有义务维护零消费模块，但无法通过实际使用验证其设计正确性。

---

## 3. 边界违规判定

### 3.1 反向依赖：binance → bootstrap

| 维度     | 判定                                                                                                                                         |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 违规类型 | 反向依赖（业务域依赖装配层）                                                                                                                 |
| 宪法条款 | §3.1 依赖拓扑、§2.2 反向依赖                                                                                                                 |
| 严重度   | **CRITICAL**                                                                                                                                 |
| 证据     | `cmd/binance-server/main.go:13` 导入 `github.com/ZoneCNH/bootstrap/pkg/bootstrap`                                                            |
| 修复方向 | 将 `bootstrap.Run` 调用从 binance 的 cmd 迁出，或把 bootstrap 降级为 `cmd/binance-server` 的本地 helper；binance 模块本身不 import bootstrap |

### 3.2 越界职责：internal/server 直接 import concrete infra

| 文件                                              | 直接 import 的 infra                      | 问题                                                     |
| ------------------------------------------------- | ----------------------------------------- | -------------------------------------------------------- |
| `internal/server/runtime_adapters.go`             | clickhousex, kafkax, natsx, redisx, taosx | 构造 RuntimeIntegrations / 适配器，应属 assembly         |
| `internal/server/kafka_dispatch.go`               | kafkax                                    | dispatcher 实现，应属 adapter 子包或 assembly            |
| `internal/server/consumer/consumer.go`            | natsx/ingest                              | consumer 实现，应属 adapter 子包或 assembly              |
| `internal/server/cache/dist_lock.go`              | redisx                                    | Redis 分布式锁调用，属于合法端口消费，但应通过 interface |
| `internal/server/idempotency/pg_log.go`           | postgresx                                 | 幂等日志存储，属于合法端口消费，但应通过 interface       |
| `internal/server/idempotency/redis_store.go`      | redisx                                    | 幂等存储，属于合法端口消费，但应通过 interface           |
| `internal/server/storage/oss_archiver.go`         | ossx                                      | 归档存储，属于合法端口消费，但应通过 interface           |
| `internal/server/storage/taos_writer.go`          | taosx                                     | 时序写入，属于合法端口消费，但应通过 interface           |
| `internal/server/storage/olap/clickhouse_olap.go` | clickhousex                               | OLAP 写入，属于合法端口消费，但应通过 interface          |

[INFERRED] 虽然部分调用是对具体客户端的**方法调用**（非构造函数），但 Go 的 import 关系本身就是编译耦合。真正的 core 应只依赖接口（ports），而接口的实现由 assembly 注入。

**关键区分**：

- ✅ 合法：core import `infra/types.go` 中声明的 interface（如 `taosx.Writer`）
- ❌ 违规：core import `infra/client.go` 并调用 `taosx.NewClient()` 或直接使用 `*taosx.Client` 具体类型

当前大量属于后者。

### 3.3 重复定义：internal/wire 与 contracts

```text
internal/wire/types.go 定义了：
  - IngestRequest
  - IngestResult
  - IngestAck / IngestReject
  - QualityVerdict / GapStatus / SLAStatus

module/contracts 的 SPEC 宣称负责：
  - 跨域 ports/event protocols/稳定 DTO
```

[INFERRED] 这是典型的"重复定义"：同一组跨域 DTO 同时出现在两个地方。修复方向是：

- 将 `internal/wire` 的 DTO 上提到 `contracts`
- binance 通过 `contracts` 消费这些 DTO
- 删除 `internal/wire` 或保留为仅含 binance 私有 wire 协议

### 3.4 过度抽象：contracts 与 transportx 无实际使用

[INFERRED] 如果模块存在但无消费者，则其抽象无法被验证。根据 §2.5，这是"为将来可能需要的功能创建模块"，属于被禁止的 YAGNI。

---

## 4. 配置与生命周期解耦的结构性问题

### 4.1 binancecfg 是 mega-config

```go
type Config struct {
    Role    Role
    Mode    string
    APIKey  configx.SecretString
    // ...
    NATS       NATSConfig
    Redis      RedisConfig
    Postgres   PostgresConfig
    Taos       TaosConfig
    Kafka      KafkaConfig
    ClickHouse ClickHouseConfig
    OSS        OSSConfig
}
```

[INFERRED] 虽然每个子配置都映射到对应模块的字段，但**所有配置集中在一个包内**。这导致：

- 任何模块的 config 变更都会影响 binancecfg
- binancecfg 知晓了 7 个 infra 模块的配置细节，成为事实上的"配置聚合层"
- 违反"每个模块声明自己的 typed Config + Validate()"原则

**正确形态**（设计意图）：

```text
configx        → 机制
natsx.Config   → NATS 拥有
redisx.Config  → Redis 拥有
binancecfg     → 只拥有 Binance 业务键（endpoint/product_lines/symbols）
assembly       → 将 binancecfg 中的 infra 字段拆成 natsx.Config / redisx.Config / ...
```

当前状态是：binancecfg 把 7 个 infra 配置都吞了，assembly 只是从它里面拆出来。虽然功能上成立，但**职责上不是严格解耦**。

### 4.2 binance-server 直接 os.Getenv 未收敛

```go
// cmd/binance-server/main.go
func smokeModeFromEnv() bool { ... os.Getenv("MODE") ... }
func isTruthyEnv(key string) bool { ... os.Getenv(key) ... }
brokers := splitCSV(os.Getenv("XGO_BINANCE_KAFKA_BROKERS"))
```

[COMPUTED] 这些调用仍未被 `binancecfg.Load` 覆盖。虽然 binancecfg 已经加载了 `FOUNDATIONX_KAFKAX_BROKERS`，但 server 仍使用 `XGO_BINANCE_KAFKA_BROKERS` 这一不同前缀。

[INFERRED] 这形成了**两套配置命名空间**：

- `FOUNDATIONX_*`：configx 机制统一加载
- `XGO_BINANCE_*`：遗留直接读取

长期维护会出现 source of truth 分裂。

### 4.3 bootstrap 未包含 schedulex 与 contracts

```text
bootstrap go.mod require:
  clickhousex, configx, kafkax, kernel, natsx, observex, ossx, postgresx, redisx, resiliencx, taosx
  缺少：schedulex, contracts, decimalx, domainx, domain_market, domain_macro, domain_exchange, transportx, xlib_*
```

[INFERRED] 如果 bootstrap 是"composition root"，它应当聚合整个应用所需的所有模块。当前它缺少：

- `schedulex`：生命周期编排应包含调度器
- `contracts` / `transportx`：契约与运输层（如果它们是应用的一部分）
- 所有 `domain_*`：领域共享层（虽然 bootstrap 不需要直接 import，但 assembly 通常需要引用）

这说明 bootstrap 的职责范围尚未完全定义清楚。

---

## 5. 反模式目录（带具体实例）

### 5.1 工具依赖文件（`tools/dependencies.go`）

```go
//go:build tools
package tools
import (
    _ "github.com/ZoneCNH/clickhousex/pkg/clickhousex"
    _ "github.com/ZoneCNH/kafkax/pkg/kafkax"
    _ "github.com/ZoneCNH/natsx/pkg/natsx"
    _ "github.com/ZoneCNH/ossx/pkg/ossx"
    _ "github.com/ZoneCNH/postgresx/pkg/postgresx"
    _ "github.com/ZoneCNH/redisx/pkg/redisx"
    _ "github.com/ZoneCNH/taosx/pkg/taosx"
    _ "github.com/gin-gonic/gin"
)
```

[INFERRED] 这是一个典型的"dependency graph workaround"。当实际代码没有自然 import 某些模块时，用 blank import 强制把它们加入 go.mod。这通常出现在两种情况下：

1. 实际依赖被隐藏在 reflect / plugin / 字符串中
2. 模块依赖关系设计不清晰，需要人为维持

本例更可能是后者：binance 应该直接 import 它需要的东西，而不是靠 tools 文件维持。

### 5.2 `replace` 指令用于本地路径

```text
binance go.mod:    replace github.com/ZoneCNH/natsx => /home/workspace/natsx
domain-exchange go.mod: replace github.com/ZoneCNH/domain-market => /home/workspace/domain-market
```

[INFERRED] `replace` 用于本地开发是合理的，但进入主分支/稳定版本则意味着：

- 模块的发布版本与本地代码不一致
- 依赖图无法被外部用户复现
- 存在 main vs worktree 分叉风险

### 5.3 间接依赖泄露

```text
binance go.mod 中：
  github.com/ZoneCNH/kernel v1.0.0 // indirect
  github.com/ZoneCNH/observex v0.3.1 // indirect
  github.com/ZoneCNH/resiliencx v0.4.9 // indirect
```

[INFERRED] 如果 binance 的业务代码直接 import 这些模块（通过 interface 或 primitives），它们应该是 direct require。当前作为 indirect 出现，说明它们只是通过 bootstrap 或其他模块传递而来。这种间接性掩盖了真实的依赖关系。

### 5.4 internal/wire 的 package 命名暴露架构问题

`internal/wire` 命名暗示它是"wire 协议/DTO"，但：

- 它只被 binance 内部使用
- 它包含的 `IngestRequest` 等类型明显是跨域契约
- 它 import 了 `domain-market` 的 canonical type

[INFERRED] 这证明了 ADR-002（迁移到 contracts）尚未完成，但旧结构仍在生产代码中运行。

---

## 6. 宪法合规差距

| 宪法条款      | 要求                                           | 当前状态                                                                                           | 差距                            |
| ------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------- |
| §2.1 明确不做 | 每个模块 SPEC 必须声明"不拥有"并指定委派方     | 已声明，但代码未完全遵守                                                                           | binance 内部越界拥有 infra 适配 |
| §2.2 边界违规 | 反向依赖/越界职责/重复定义                     | 反向依赖 binance→bootstrap 存在；internal/wire 重复 contracts；越界职责在 internal/server 普遍存在 | 3 类违规均存在                  |
| §2.5 模块增殖 | 禁止 YAGNI；新增模块须满足必要性/唯一性/净收益 | contracts/transportx 零消费者                                                                      | 可能违反                        |
| §3.1 依赖拓扑 | 单向下行                                       | binance→bootstrap 反向                                                                             | 违反                            |
| §3.2 同层平级 | 同域同层模块无编译依赖                         | 7 infra 模块之间满足                                                                               | 满足                            |
| §3.4 禁止依赖 | 存储扩展禁止互相依赖                           | 满足                                                                                               | 满足                            |

---

## 7. 风险热图

| 模块/区域                 | 反向依赖    | 越界职责    | 重复定义 | 配置分裂 | 版本分叉 | 综合严重度                          |
| ------------------------- | ----------- | ----------- | -------- | -------- | -------- | ----------------------------------- |
| `binance → bootstrap`     | ✅ CRITICAL | —           | —        | —        | —        | **CRITICAL**                        |
| `binance/internal/server` | —           | ✅ CRITICAL | —        | —        | —        | **CRITICAL**                        |
| `binancecfg`              | —           | —           | —        | ✅ HIGH  | —        | **HIGH**                            |
| `internal/wire`           | —           | —           | ✅ HIGH  | —        | —        | **HIGH**                            |
| `contracts`               | —           | —           | —        | —        | —        | **HIGH**（空模块）                  |
| `transportx`              | —           | —           | —        | —        | —        | **HIGH**（空模块）                  |
| `cmd/binance-server`      | —           | —           | —        | ✅ MED   | —        | **MED**                             |
| `bootstrap`               | —           | —           | —        | ✅ MED   | —        | **MED**（缺失 schedulex/contracts） |
| `binance go.mod`          | —           | —           | —        | —        | ✅ MED   | **MED**（replace natsx）            |
| `domain-exchange go.mod`  | —           | —           | —        | —        | ✅ MED   | **MED**（replace domain-market）    |

---

## 8. 修复建议（按优先级排序）

### 8.1 立即修复（CRITICAL）

#### R1: 移除 binance → bootstrap 的依赖

**目标**：让 binance 模块不 import bootstrap。

**方案**：

1. 将 `cmd/binance-server/main.go` 中的 `bootstrap.Run` 调用封装为一个独立的 `cmd/binance-server` 本地 helper（或完全移出 binance 模块）
2. 如果 bootstrap 提供的 lifecycle 功能是 binance 必需的，应将其抽象为 binance 自己的 `LifecycleManager` interface，由 bootstrap 实现并注入
3. 从 `binance/go.mod` 中移除 `bootstrap` require

**验证**：`rg "github.com/ZoneCNH/bootstrap" /home/workspace/binance/ --type go` → 0 命中。

#### R2: 将 binance/internal/server 拆分为 core + adapter + assembly

**目标**：internal/server 只保留业务编排；所有 concrete infra 调用迁到 adapter 或 cmd。

**方案**：

1. 创建 `internal/server/adapter/` 或 `internal/adapter/` 目录
2. 将 `kafka_dispatch.go`、`consumer.go`、`runtime_adapters.go` 中直接 import infra 的代码迁到 adapter 包
3. 为每个 infra 定义 narrow port interface（如 `IdempotencyStore`、`MarketWriter`、`DispatchPublisher`）
4. `internal/server` 只持有这些 interface，不 import infra 包
5. `cmd/binance-server/main.go` 负责：构造 infra client → 构造 adapter → 注入 server

**验证**：`rg "github.com/ZoneCNH/(clickhousex|kafkax|natsx|postgresx|redisx|taosx|ossx)" /home/workspace/binance/internal/server/ --type go | grep -v "_test.go" | grep -v "/adapter/"` → 0 命中。

### 8.2 高优先级修复（HIGH）

#### R3: 将 internal/wire 迁移到 contracts

**目标**：让 `contracts` 真正承载跨域契约。

**方案**：

1. 将 `IngestRequest`、`IngestResult`、`IngestAck`、`IngestReject` 等上提到 `contracts`
2. 修改 binance 内部引用，从 `internal/wire` 改为 `contracts`
3. 如果 binance 需要私有扩展，保留 `internal/wire` 但只含 binance 私有类型

**验证**：`rg "github.com/ZoneCNH/contracts" /home/workspace/binance/ --type go -l` → 非空；`internal/wire/types.go` 不再定义与 contracts 同构类型。

#### R4: 收缩 binancecfg 职责

**目标**：binancecfg 只拥有 Binance 业务键；infra 配置由各模块拥有。

**方案**：

1. 在 `natsx`、`redisx`、`postgresx`、`taosx`、`kafkax`、`clickhousex`、`ossx` 中定义自己的 `Config` + `FromBinanceCfg` 或 `FromEnvPrefix` 方法
2. 或者保留 binancecfg 作为"读取入口"，但明确声明它不对这些字段拥有语义，只是转发
3. 更激进：删除 `binancecfg` 中的 infra 字段，让 assembly 直接通过各模块的 `LoadFromEnv(prefix)` 读取

**验证**：`binancecfg.Config` 不再包含 `NATS`、`Redis` 等 infra 子结构；或这些字段被标记为 `transitive` 并附加说明。

#### R5: 处理 contracts/transportx 零消费者问题

**方案 A（推荐）**：完成 R3 和 envelope 标准化，让 contracts 与 transportx 有实际消费者。

**方案 B（如果短期内无消费者）**：将 contracts/transportx 标记为 `draft` 或归档，直到有实际使用；否则违反 §2.5 YAGNI。

### 8.3 中优先级修复（MED）

#### R6: 收敛 binance-server 的 os.Getenv

**目标**：所有配置统一走 `binancecfg.Load`。

**方案**：

1. 将 `XGO_BINANCE_KAFKA_BROKERS` 改为 `FOUNDATIONX_KAFKAX_BROKERS`（或让 binancecfg 兼容）
2. 将 `MODE` 测试模式纳入 `binancecfg`（如 `Role` 或 `SelfTest` 字段）
3. 删除所有 `isTruthyEnv`/`smokeModeFromEnv` 中的直接 env 读取

**验证**：`rg "os\.Getenv" /home/workspace/binance/cmd/binance-server/main.go` → 0 命中。

#### R7: 修复 bootstrap 依赖完整性

**目标**：bootstrap 作为 composition root，应明确聚合哪些模块。

**方案**：

1. 如果 bootstrap 需要编排 schedulex，则添加 require
2. 如果 bootstrap 不需要直接 require contracts/transportx（因为它们是 library 而非 runtime），则文档明确说明
3. 总体原则：bootstrap 不应是一个"被业务模块 import 的库"，而应是"导入业务模块并启动它们的入口"

#### R8: 清理 replace 指令与版本分叉

**目标**：主分支 go.mod 不应包含本地路径 replace。

**方案**：

1. 合并 natsx 的 worktree 变更到 main 并发布新版本
2. 合并 domain-market 的 worktree 变更到 main 并发布新版本
3. 从 binance 和 domain-exchange 的 go.mod 中移除 replace 指令

### 8.4 低优先级（LOW）

#### R9: 清理 `tools/dependencies.go`

如果 R2 完成后，binance 自然 import 所需 infra 包，则 `tools/dependencies.go` 可以删除或仅保留真正 tools-only 的依赖（如 gin）。

#### R10: 更新架构文档

将本报告结论同步到 `docs/architecture/`、`ARCHITECTURE.md`、`module/*/SPEC.md` 中，确保文档与代码一致。

---

## 9. 结论

[COMPUTED, HIGH] 当前架构的**硬门禁**（反向依赖、领域纯度、infra 同层互耦）已经通过；但**软结构**存在严重脆弱性：

1. **binance 依赖 bootstrap** 是最危险的结构反转，必须立即修复。
2. **binance/internal/server 不是纯 core**，而是 concrete infra 的聚合层，违反了"六边形 ports"和"禁止多层实现"原则。
3. **contracts 与 transportx 零消费者** 使这两个模块成为架构死重，要么完成迁移让它们被使用，要么承认 YAGNI 违规。
4. **binancecfg 的 mega-config** 结构是配置语义未真正解耦的表征。
5. **internal/wire 重复 contracts 职责** 是明确的重复定义违规。

如果不修复这些结构性问题，系统虽然能运行，但会随着功能增长逐渐退化为**"以 binance 为中心的 spaghetti 架构"**，最终需要更昂贵的重构。

[RULES I BROKE]: 无
