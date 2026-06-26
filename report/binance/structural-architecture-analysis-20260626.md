# module/binance C/S 架构模式结构性深度分析

- Report-Date: 2026-06-26
- Scope: runtime 代码实态审计 + spec 声明对比 + 依赖拓扑分析 + 可复用性评估
- Runtime-HEAD: `/home/binance@756fbc5`
- Spec-Version: v3.7.1
- Verdict: **需要结构性优化 — 三层问题：client 扁平化膨胀 + 边界违规 + C/S 模式不可复用**

---

## 零、核心发现

通过逐文件代码实态审计 + 与 SPEC/RUNTIME-MAPPING/FOUNDATION-DEPS 交叉验证，发现 binance 的 C/S 架构存在三个层级的结构性问题：

| 层级            | 问题                                                                                                 | 严重度 | 证据                                        |
| --------------- | ---------------------------------------------------------------------------------------------------- | ------ | ------------------------------------------- |
| **L1 代码组织** | client 包扁平化：parser/mapper/normalizer/catalog 未拆分子包，与 RUNTIME-MAPPING 声明严重不符        | HIGH   | flat `.go` files vs docs claim sub-packages |
| **L2 边界违规** | client 包含 history/archive/reconciliation/exchangeInfo 逻辑 + import postgresx，违反 BOUNDARY-GATES | HIGH   | `history_state_postgres.go` in client       |
| **L3 模式复用** | C/S 架构模式不可复制——connector stub、7-infra 耦合、无模板提取                                       | HIGH   | okx/hyperliquid v0.1.0-draft                |

---

## 一、代码实态 vs 规格声明差分

### 1.1 RUNTIME-MAPPING.md 声称的目标结构

```
internal/client/
  catalog/          ← 产品线目录
  parser/           ← Binance 符号解析
  connectors/       ← spot.go, um_perp.go, cm_perp.go, options.go
  normalize/        ← 原生事件 → NormalizedEvent
  mapper/           ← NormalizedEvent → domain_market.MarketFactEnvelope
  admin/            ← Gin admin :8081
  publisher/        ← natsx publisher
```

### 1.2 代码实态（2026-06-26）

```
internal/client/
  [FLAT] admin.go, catalog.go, parser.go, normalize.go, mapper.go
  [FLAT] spot.go (433 lines), connector.go (51 lines)
  [FLAT] history_lifecycle.go (740 lines), history_rest.go (300 lines)
  [FLAT] history_fetcher.go, history_state_postgres.go ← import postgresx!
  [FLAT] archive_manifest.go, cron_reconcile.go
  [FLAT] exchangeinfo.go, exchangeinfo_refresh.go, exchangeinfo_option.go
  [FLAT] lifecycle.go (446 lines), stream_control.go, runtime.go
  [FLAT] queue.go (395 lines), relay.go
  [FLAT] resource_governance.go, throttle.go
  connectors/
    spot.go      ← 8 lines [STUB]
    um_perp.go   ← 8 lines [STUB]
    cm_perp.go   ← 8 lines [STUB]
    options.go   ← 8 lines [STUB]
  publisher/
    publisher.go ← 118 lines [REAL]
```

### 1.3 差分矩阵

| 文件                        | DOCS 声称位置                                  | 代码实际位置     | 严重度   |
| --------------------------- | ---------------------------------------------- | ---------------- | -------- |
| `catalog.go`                | `client/catalog/`                              | `client/` (flat) | MED      |
| `parser.go`                 | `client/parser/`                               | `client/` (flat) | MED      |
| `normalize.go` (662 lines)  | `client/normalize/`                            | `client/` (flat) | HIGH     |
| `mapper.go`                 | `client/mapper/`                               | `client/` (flat) | MED      |
| `spot.go` (connector)       | `client/connectors/spot.go`                    | `client/` (root) | HIGH     |
| connector stubs             | `connectors/{spot,um_perp,cm_perp,options}.go` | 8 行占位         | HIGH     |
| `admin.go`                  | `client/admin/`                                | `client/` (flat) | MED      |
| `history_state_postgres.go` | **不应在 client**                              | `client/`        | CRITICAL |
| `history_lifecycle.go`      | **不应在 client**                              | `client/`        | HIGH     |
| `archive_manifest.go`       | **server 专属**                                | `client/`        | HIGH     |
| `cron_reconcile.go`         | **server 专属**                                | `client/`        | HIGH     |
| `exchangeinfo_*.go`         | FR-031~036 Draft                               | `client/`        | MED      |

---

## 二、边界违规详细分析

### 2.1 CRITICAL：`history_state_postgres.go` 在 client 中 import postgresx

```go
// internal/client/history_state_postgres.go
import (
    "github.com/ZoneCNH/postgresx"  // ← 违反 BOUNDARY-GATES §7
)
```

**违规规则**：

- `BOUNDARY-GATES.md` §7: Server Owns Binance Storage — client 禁止直连 postgresx
- `RUNTIME-MAPPING.md` §10: Client 禁止 import `redisx, postgresx, taosx, kafkax, ossx`
- `SPEC.md` §4.1 C5: Client 不得 import server internals

**根因** `[INFERRED, HIGH]`：backfill 进度持久化需求被错误地放在了 client 侧。按原始架构设计，backfill planner（FR-016）、gap detection（FR-017）、reconciliation（FR-026）应属于 server 的 `internal/server/storage/` 或 `internal/server/processor/`。

### 2.2 HIGH：client 承载了超出声明 3 倍的职责

SPEC 声明 client 职责：

> 连接 Binance，解析交易所原生数据，映射到 domain_market envelope，并通过 natsx JetStream 发布

代码实态 client 额外职责：

| 额外职责          | 对应文件                    | 代码量 | 应归属                   |
| ----------------- | --------------------------- | ------ | ------------------------ |
| 历史回填管理器    | `history_lifecycle.go`      | 740 行 | server                   |
| REST 历史抓取     | `history_rest.go`           | 300 行 | server                   |
| 历史状态持久化    | `history_state_postgres.go` | 82 行  | server                   |
| 归档清单管理      | `archive_manifest.go`       | 157 行 | server                   |
| 日终对账          | `cron_reconcile.go`         | 143 行 | server                   |
| ExchangeInfo 拉取 | `exchangeinfo_*.go`         | 380 行 | client（合理但应在子包） |
| 队列/中继         | `queue.go` + `relay.go`     | 494 行 | client（合理）           |

**影响**：client 从 ~5000 行的轻量采集器膨胀为 ~10300 行的"类 server"。client 和 server 的职责边界已经模糊——client 在独立做 backfill 进度管理、归档、对账，这些本应是 server 通过 natsx control subjects 协调的。

### 2.3 MEDIUM：connectors/ 目录被架空

`connectors/spot.go`、`um_perp.go`、`cm_perp.go`、`options.go` 各 8 行，全是：

```go
package connectors
// spot.go — placeholder; actual connector is in spot.go at client/ root
```

真正的 connector 逻辑在 `client/spot.go`（433 行）。这意味着：

- 当 okx 想复用 binance 的 connector 模式时，找不到可参考的接口/实现分离
- `connector.go` 的 `ProductLineConnector` 接口定义在 client 根目录，而非 connectors 子包
- 四产品线没有独立的 connector 实现——um_perp、cm_perp、options 的 connector 只是占位

---

## 三、依赖拓扑分析

### 3.1 当前依赖图（go.mod）

```
binance
├─ [client 侧] natsx, domain-market, domain-exchange, domainx
│   └─ binance-connector-go (外部)
├─ [server 侧] redisx, postgresx, taosx, clickhousex, kafkax, ossx, gin
├─ [共享] bootstrap, configx, decimalx
└─ [边界违规] postgresx ← client 通过 history_state_postgres.go 依赖
```

### 3.2 目标依赖图（按 SPEC 边界声明）

```
binance-client (独立进程)
├─ natsx
├─ domain-market
├─ domain-exchange
├─ domainx
├─ configx
└─ binance-connector-go

binance-server (独立进程)
├─ natsx
├─ redisx, postgresx, taosx, clickhousex, kafkax, ossx
├─ gin, bootstrap
├─ domain-market, domain-exchange, domainx
└─ configx, decimalx
```

当前 `go.mod` 是单体的——client 和 server 共享同一个 module，依赖无法按进程隔离。15 个 direct deps 中有 7 个是 server 专属但被 client 代码触达的。

### 3.3 下游依赖压力

`FOUNDATION-DEPS.yaml` 登记了 8 个下游消费者：

```
factor_engine, feature_store, factor_eval, signal_factory,
strategyx, riskx, orderx, positionx
```

`[INFERRED, HIGH]` binance 的 kafkax topic schema 或 natsx subject format 的任何变更都会直接冲击 8 个下游模块。当前 FR-042（Schema Version Compatibility Policy）仍为 Pending——无兼容 gate 保护这 8 个下游。

---

## 四、C/S 模式可复用性评估

### 4.1 当前状态：不可复用

10 个数据域模块中，6 个是 `cs_module`（binance, okx, hyperliquid, coinglass, fred, treasury），但只有 binance 有实际代码。okx 和 hyperliquid 处于 `v0.1.0-draft`。

当 okx 团队想实现时，他们能复用 binance 的什么？

| 可复用项           | 当前状态                      | 可复用性                       |
| ------------------ | ----------------------------- | ------------------------------ |
| SPEC 模板          | binance SPEC 2176 行，44 FR   | ❌ 太复杂，需提取 C/S 最小模板 |
| client 包结构      | 扁平化，无子包边界            | ❌ 无清晰接口可复用            |
| connector 模式     | 接口在 client 根，实现是 stub | ❌ 无可参考的实现              |
| natsx subject 规范 | NAMING.md 4×6 矩阵            | ✅ 命名规范可复用              |
| server 存储装配    | `storageFromEnv` 模式         | △ 模式可复用但需适配           |
| BOUNDARY-GATES     | 13 gates                      | ✅ 可裁剪复用                  |

### 4.2 理想的 C/S 模板结构

一个新交易所模块（如 okx）的理想起步形态：

```
okx/
├── cmd/
│   ├── okx-client/main.go       ← 从模板复制
│   └── okx-server/main.go       ← 从模板复制
├── internal/
│   ├── client/
│   │   ├── catalog/             ← 产品线目录（catalog.go 模板）
│   │   ├── parser/              ← 交易所符号解析（parser.go 接口）
│   │   ├── connectors/          ← 产品线 connector（每个 100-200 行，实现接口）
│   │   │   ├── connector.go     ← Connector 接口
│   │   │   ├── spot.go          ← 交易所特定实现
│   │   │   └── ...
│   │   ├── normalize/           ← 通用 normalize（可复用 binance 的）
│   │   ├── mapper/              ← 通用 mapper（可复用 binance 的）
│   │   └── publisher/           ← natsx publisher（可复用）
│   └── server/
│       ├── consumer/            ← natsx consumer（可复用）
│       ├── processor/           ← 可复用管线
│       ├── storage/             ← 按需装配
│       └── api/                 ← Gin REST（可复用路由模板）
├── pkg/
│   └── wire/                    ← 从 domain_market 衍生
└── SPEC.md                      ← ≤800 行，≤20 FR
```

---

## 五、优化方案

### Phase A：修复边界违规（立即，1-2 天）

| #   | 行动                                                                           | 影响                   |
| --- | ------------------------------------------------------------------------------ | ---------------------- |
| A1  | 将 `history_state_postgres.go` 从 client 移至 server                           | 消除 critical 边界违规 |
| A2  | 将 `history_lifecycle.go`、`history_rest.go`、`history_fetcher.go` 移至 server | client 减 1122 行      |
| A3  | 将 `archive_manifest.go`、`cron_reconcile.go` 移至 server                      | client 减 300 行       |
| A4  | 重跑 `boundary-gates.sh` 验证无 client→postgresx import                        | CI 阻断                |

### Phase B：client 包结构重组（短期，3-5 天）

| #   | 行动                                                                                               |
| --- | -------------------------------------------------------------------------------------------------- |
| B1  | 创建 `internal/client/catalog/`，移入 `catalog.go`                                                 |
| B2  | 创建 `internal/client/parser/`，移入 `parser.go`                                                   |
| B3  | 创建 `internal/client/normalize/`，移入 `normalize.go`（662 行→拆分为 normalize + normalize_test） |
| B4  | 创建 `internal/client/mapper/`，移入 `mapper.go`                                                   |
| B5  | 将 `spot.go` 的 connector 逻辑拆分到 `connectors/spot.go`                                          |
| B6  | 实现 `connectors/um_perp.go`、`cm_perp.go`、`options.go` 的真实 connector                          |
| B7  | 创建 `internal/client/admin/`，移入 `admin.go`                                                     |
| B8  | 更新 `RUNTIME-MAPPING.md` 对齐重组后的结构                                                         |

### Phase C：C/S 模板提取（中期，5-7 天）

| #   | 行动                                                                                           |
| --- | ---------------------------------------------------------------------------------------------- |
| C1  | 从 binance 提取 `client` 通用包 → `pkg/csclient/`（catalog/parser/normalize/mapper 接口）      |
| C2  | 从 binance 提取 `server` 通用管线 → `pkg/csserver/`（consumer/processor/storage adapter 接口） |
| C3  | 创建 `docs/governance/templates/CS-MODULE-TEMPLATE.md`                                         |
| C4  | 以 okx 为试点，用模板搭建 v0.2.0 骨架                                                          |

### Phase D：依赖隔离（长期）

| #   | 行动                                                                               |
| --- | ---------------------------------------------------------------------------------- |
| D1  | 评估 `go.mod` 拆分为 `binance-client` 和 `binance-server` 两个独立 module 的可行性 |
| D2  | 建立 schema compatibility gate（FR-042 实现）保护 8 个下游                         |
| D3  | 将 `internal/wire` 提升为独立包或归入 `domain_market`                              |

---

## 六、变更历史

| 日期       | 版本   | 变更                                                       |
| ---------- | ------ | ---------------------------------------------------------- |
| 2026-06-26 | v1.0.0 | 初始：代码实态审计 + spec 差分 + 依赖拓扑 + 四阶段优化方案 |




