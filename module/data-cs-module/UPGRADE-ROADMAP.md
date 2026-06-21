# SDK → C/S Module 升级路线图

> 数据域 23 个数据源子模块从当前 SDK/Proto-C/S 状态升级到完整 C/S Module 的分阶段计划。

最后更新：2026-06-21

---

## 当前状态基线

### 行情域 (market_data)

| # | 模块 | 当前版本 | 当前状态 | cmd/server | internal/{c,s,cs} | pkg | SPEC |
|---|------|---------|---------|:---:|:---:|:---:|:---:|
| 1 | binance | v0.2.0 | **C/S Module（参考实现）** | ✅ | ✅ | ✅ | ✅ |
| 2 | okx | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 3 | bybit | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 4 | bitget | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 5 | kucoin | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 6 | gate | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 7 | mexc | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 8 | htx | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 9 | coinbase | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 10 | hyperliquid | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 11 | lighter | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 12 | upbit | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 13 | coinglass | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |

### 宏观域 (macro_data)

| # | 模块 | 当前版本 | 当前状态 | cmd/server | internal/{c,s,cs} | pkg | SPEC |
|---|------|---------|---------|:---:|:---:|:---:|:---:|
| 14 | fred | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 15 | treasury | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 16 | yield_curve | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 17 | bea | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 18 | ecb | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 19 | uk_cb | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 20 | japan_cb | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 21 | eastmoney | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 22 | jin10 | v0.2.0 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |
| 23 | yahoo | v0.1.1 | Proto-C/S | ✅ | ❌ | ❌ | ❌ |

> **Proto-C/S**：有 `cmd/{module}-server/main.go` 入口，但无 `internal/{client,server,cs}` 目录拆分。当前与旧 SDK 代码混存。全部需要 go.mod 独立化。

---

## 升级阶段定义

```text
Proto-C/S                     →     C/S Module (full)
───────────                         ────────────────
cmd/{m}-server ✅                   cmd/{m}-server ✅
internal/client  ❌           →     internal/client  ✅
internal/server  ❌                 internal/server  ✅
internal/cs      ❌                 internal/cs      ✅
pkg/{m}x         ❌                 pkg/{m}x         ✅
go.mod standalone ❌                go.mod standalone ✅
bootstrap 接入    ❌                bootstrap 接入    ✅
SPEC.md           ❌                SPEC.md (23节)   ✅
CI Gate           部分              CI Gate 全量     ✅
```

### 阶段 0：基线确认 ✅

binance 已完成，作为其余 22 个模块的参考实现。

### 阶段 1：SPEC 创建

基于 `module/data-cs-module/SPEC-TEMPLATE.md` 为模块创建 23 节 SPEC.md。

**产出**：`module/{module}/SPEC.md`（Draft → Approved）、`goal.md`、`TRACEABILITY.md`

**门禁**：spec-lint.sh 通过，Status = Approved

### 阶段 2：C/S 结构拆分

将现有 `cmd/{module}-server` 代码拆分为 C/S 三件套。独立化 go.mod。

**产出**：`internal/{client,server,cs}/`、`pkg/{module}x/adapter.go`

**门禁**：`go build ./...` + `go test ./... -race` 通过，BR-001/BR-002 边界合规

### 阶段 3：Bootstrap 接入

改造 main.go 使用 `bootstrap.Build(ctx, Spec{Module, Stores=None})`。

**门禁**：进程可启动、`/healthz` 返回 200、SIGTERM 优雅停止

### 阶段 4：交付语义

实现 at-least-once + idempotent acceptance + ACK-driven checkpoint。

**门禁**：集成测试 `client → server → dispatch` 完整数据流通过

### 阶段 5：CI + 可观测性

BOUNDARY-GATES.md + CI workflows + observex 集成。

**门禁**：覆盖率 ≥ 80%，全部 CI Gate 通过

---

## 优先级分派

### P0（第一批，4 个）

| 模块 | 域 | 理由 |
|------|----|------|
| **okx** | 行情 | 交易量 Top 3，与 binance 互补覆盖主流 CEX |
| **bybit** | 行情 | 衍生品交易量领先，USDT 本位合约核心数据源 |
| **fred** | 宏观 | 美联储 — 利率/就业/GDP 核心宏观指标 |
| **treasury** | 宏观 | 美国国债 — 收益率曲线，资产定价基准 |

**退出条件**：4 模块全部完成阶段 1-5，composer 集成验证通过。

### P1（第二批，8 个）

| 模块 | 域 | 理由 |
|------|----|------|
| coinbase | 行情 | 美股合规交易所，USD 入金关联 |
| hyperliquid | 行情 | 领先 DEX，链上订单簿 |
| bitget | 行情 | 衍生品交易量增长快 |
| kucoin | 行情 | 长尾资产覆盖 |
| bea | 宏观 | GDP/消费/贸易数据 |
| ecb | 宏观 | 欧元区货币政策 |
| yield_curve | 宏观 | 多国债收益率曲线 |
| jin10 | 宏观 | 中国宏观数据 + 实时快讯 |

### P2（第三批，10 个）—— 长尾覆盖

gate, mexc, htx, upbit, lighter, coinglass (行情), uk_cb, japan_cb, eastmoney, yahoo (宏观)

---

## 依赖链

```text
contracts (传输契约就绪) + domain_market / domain_macro (canonical 类型)
    │
    ├──► P0: okx, bybit, fred, treasury
    │       │
    │       ▼
    ├──► P1: coinbase, hyperliquid, bitget, kucoin, bea, ecb, yield_curve, jin10
    │       │
    │       ▼
    └──► P2: gate, mexc, htx, upbit, lighter, coinglass, uk_cb, japan_cb, eastmoney, yahoo
            │
            ▼
        全部 23 模块 → dispatch 集成 → composer 全链路
```

---

## 每模块工作量估算

| 阶段 | 工时 | 说明 |
|:---:|:---:|------|
| 1. SPEC | 2-4h | 基于模板填写 |
| 2. C/S 拆分 | 4-8h | 从现有 cmd/server 代码重构 |
| 3. Bootstrap | 1-2h | 标准化接入 |
| 4. 交付语义 | 4-8h | spool + checkpoint + idempotency |
| 5. CI + 观测 | 2-4h | Gate 脚本 + metrics/logging |
| **合计** | **13-26h** | 每模块 |

> P0（4 模块）≈ 52-104h。全部 22 模块 ≈ 286-572h。

---

## 阶段门禁检查清单

### 阶段 1 门禁
- [ ] SPEC.md 通过 spec-lint.sh（23 节完整）
- [ ] 每个 FR 含 WHEN/THEN，每个 BR 含违反时处理
- [ ] Status: Approved

### 阶段 2 门禁
- [ ] `internal/{client,server,cs}/` 目录存在
- [ ] `pkg/{module}x/adapter.go` 存在
- [ ] `go.mod` 独立化
- [ ] `go build ./...` + `go test ./... -race` 通过
- [ ] 无跨 client/server import（BR-001/BR-002）

### 阶段 3 门禁
- [ ] `cmd/{module}-server/main.go` 使用 `bootstrap.Build()`
- [ ] 进程可启动，`/healthz` 返回 200
- [ ] SIGTERM 触发优雅停止

### 阶段 4 门禁
- [ ] client spool + checkpoint 实现
- [ ] server idempotency store 实现
- [ ] 集成测试 `client → server → dispatch` 通过

### 阶段 5 门禁
- [ ] BOUNDARY-GATES.md 存在且全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI workflows 配置（通用 + C/S Module 专属 6 项 Gate）
- [ ] observex 集成

---

## 相关文档

| 文档 | 用途 |
|------|------|
| [`SPEC-TEMPLATE.md`](./SPEC-TEMPLATE.md) | C/S Module 23 节 SPEC 模板 |
| [`../binance/SPEC.md`](../binance/SPEC.md) | C/S Module 参考实现 |
| [`../../ARCHITECTURE.md#模块架构类型`](../../ARCHITECTURE.md#模块架构类型) | 架构类型定义 |
| [`../../STATUS.md`](../../STATUS.md) | 模块当前状态 |
