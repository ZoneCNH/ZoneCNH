# Plan007 执行对齐文档

- Plan: `plans/binance/007-binance-readiness-arch-fix.md`
- Execution-Start: 2026-06-24
- Execution-End: 2026-06-25
- Executor: ZCode (direct + Agent Team)
- Final-Status: **18/18 DONE ✅**
- Baseline-HEAD: `8290dc9` (Plan006 final, PR #73)
- Final-HEAD: binance `e02b190` · ZoneCNH `79068320`

---

## Phase 0 基线确认

| 检查项 | 结果 | 证据 |
|--------|:----:|------|
| binance HEAD | `8290dc9` | git log |
| anchor-1~8 全部核实 | PASS | §1.3 grep/Read |
| go test ./... | 18/18 PASS | go test -short |
| boundary-gates.sh | 13/13 PASS | bash |

---

## 执行记录

### Round 1 — 跨仓库炸弹拆除 + 规格刷新 (2026-06-24)

| ID | 任务 | Executor | Commit | 结果 |
|:---|:-----|:---------|:-------|:----:|
| B3 | domainx 补 go.mod | executor-3 | `e26bf7d` | ✅ |
| B2 | domain_* worktree path 统一 | executor-3 | `bfdeebc`/`d3ebe97`/`2411c3e` | ✅ |
| B1 | transportx name fix | ZCode | `3127a4f` | ✅ |
| — | natsx NakWithDelay 支持 | ZCode | `9bf6a5c` | ✅ |
| A3 | NakWithDelay + DLQ | ZCode | `1ec9d26` | ✅ |
| A8 | 规格端一致性刷新 | ZCode | `b2fa06f4` | ✅ |

### Round 2 — binance runtime 功能修复 (2026-06-24)

| ID | 任务 | Executor | Commit | 结果 |
|:---|:-----|:---------|:-------|:----:|
| A4 | 跨产品线碰撞测试 | ZCode | `f9c2c01` | ✅ |
| A7 | options normalize 补全 | ZCode | `b82d5b1` | ✅ |
| A1 | 历史回填接真实 REST | ZCode | `9d95f84` | ✅ |

### Round 3 — 架构收尾 + 文档 (2026-06-25)

| ID | 任务 | Executor | Commit | 结果 |
|:---|:-----|:---------|:-------|:----:|
| B4 | client assembly 下沉 | ZCode | `be3bd6c` | ✅ |
| B5 | wire→contracts 过渡文档 | ZCode | `8e9019a` | ✅ |
| A9 | §12.10/§12.11 代码复核 | ZCode | `8e9019a` | ✅ |
| A10 | FR-024 hot reload 评估 | ZCode | `8e9019a` | ✅ |
| B6 | bootstrap 装配层文档 | ZCode | `7784ee5` | ✅ |
| B7 | domain main↔worktree 同步 | ZCode | `1a68ee5`/`4b21134` | ✅ |
| B8 | gate 模板固化 | ZCode | `7437caaa` | ✅ |
| A5 | release.yml 验证 | ZCode | 配置核实 | ✅ |
| A6 | bench + SLO 报告 | ZCode | 24 benchmarks PASS | ✅ |

### Round 4 — 真实集成测试 (2026-06-25)

| ID | 任务 | Executor | Commit | 结果 |
|:---|:-----|:---------|:-------|:----:|
| A2 | testnet live 集成测试 | ZCode | `07aa167`/`1f097df` | ✅ |

---

## A2 真实集成测试证据

| 测试 | 结果 | 时间 | 详情 |
|:-----|:----:|:----:|:-----|
| TestTestnetLive_SpotTradeStream | ✅ | 3.65s | BTCUSDT price=60222.01 |
| TestTestnetLive_SpotBookTicker | ✅ | 9.75s | bid=60222.00 ask=60222.01 |
| TestTestnetLive_SpotKline | ✅ | 3.58s | interval=1m close=60222.01 |
| TestNATSXIntegrationJetStreamSemantics | ✅ | 20.59s | PubAck/dup/NakWithDelay/MaxDeliver |
| 24 Benchmarks | ✅ | — | 全部远超 NFR 预算 |

**凭据来源**: `sre/secrets/env/dev.md` — 本地 infra (PG/TD/CH/NATS)
**Binance testnet**: `testnet.binance.vision` — 公开，无需凭据
**证据归档**: `release/evidence/binance/20260625/`

---

## 完成状态

### Track A — 功能就绪 (10/10 ✅)

| ID | 标题 | 优先级 | 状态 |
|:---|:-----|:------:|:----:|
| A1 | 历史回填接真实 REST | P0 | ✅ |
| A2 | 真实外部集成测试 + evidence | P0 | ✅ |
| A3 | NakWithDelay + DLQ 写入侧 | P1 | ✅ |
| A4 | 跨产品线碰撞测试 | P1 | ✅ |
| A5 | Release artifact 验证 | P1 | ✅ |
| A6 | 压测与 SLO 报告 | P1 | ✅ |
| A7 | options 结构化 parser | P1 | ✅ |
| A8 | 规格端一致性收尾 | P2 | ✅ |
| A9 | §12.10/§12.11 代码复核 | P2 | ✅ |
| A10 | FR-024 hot reload 评估 | P2 | ✅ |

### Track B — 架构卫生 (8/8 ✅)

| ID | 标题 | 优先级 | 状态 |
|:---|:-----|:------:|:----:|
| B1 | transportx module name bug | 高 | ✅ |
| B2 | domain_* module path 统一 | 高 | ✅ |
| B3 | domainx 主目录补 go.mod | 中 | ✅ |
| B4 | binance client assembly 下沉 | 中 | ✅ |
| B5 | wire → contracts 迁移 | 中 | ✅ |
| B6 | bootstrap 分层文档 | 低 | ✅ |
| B7 | domain main↔worktree 同步 | 低 | ✅ |
| B8 | gate 推广 | 低 | ✅ |

---

## 涉及仓库与提交

| 仓库 | 新 HEAD | 变更 |
|:-----|:--------|:-----|
| natsx | `9bf6a5c` | FetchMessage.NakWithDelay |
| transportx | `3127a4f` | module name fix (26 files) |
| domainx | `e26bf7d` | 主目录补 go.mod |
| domain-market | `bfdeebc` | worktree/v100 snake_case |
| domain-macro | `1a68ee5` | decimalx v0.1.0→v1.0.0 |
| domain-exchange | `4b21134` | 新增 domainx, 删 replace |
| bootstrap | `7784ee5` | B6 装配层文档 |
| binance | `e02b190` | A1~A7 + B4/B5 + evidence (7 commits) |
| ZoneCNH | `79068320` | A8/B8 + 对齐 + 计划更新 (5 commits) |

**总计**: 9 repos · 20 commits

---

## 验证历史

| 日期 | 迭代 | go test | gates | 结果 |
|:-----|:----:|:-------:|:-----:|:----:|
| 2026-06-24 | 10x | 18/18 | 13/13 | ✅ |
| 2026-06-25 | 10x | 18/18 | 13/13 | ✅ |
| 2026-06-25 (final) | 1x | 18/18 | 13/13 | ✅ |

**累计**: 21 迭代 · 378 test PASS · 273 gate PASS · 0 失败

---

## GitHub Issues

| 状态 | 数量 |
|:-----|:----:|
| 关闭 | **22** |
| 开放 | **0** |

全部 22 个 issue (#1033~#1054) 已通过 `gh issue close` 关闭，关闭原因均包含本对齐文档链接。
