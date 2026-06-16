# 深度分析: `zonecnh-binance-module-patch`

> 日期: 2026-06-16
> 分析对象: `/home/zone/Downloads/zonecnh-binance-module-patch`
> 仓库上下文: `ZoneCNH/ZoneCNH` (FoundationX 文档枢纽)

## 一、概览

该 patch 是 **Binance 模块的规范落地包**（不是运行时代码）。它定义了一套完整的规格文档、任务拆分、边界门禁和实现计划，为 `github.com/ZoneCNH/binance` 仓库提供规格约束。

**20 个文件，5 层结构：**

```
APPLY-GUIDE.md           ← 合并计划（5 PRs）
docs/adr/                ← 架构决策记录
docs/services/           ← 服务描述
module/binance/           ← 核心规格模块（SPEC/TRACEABILITY/PLAN/TASKS/BOUNDARY/RUNTIME）
scripts/                  ← CI 边界校验脚本
repo-skeleton/            ← 推荐仓库布局（非代码）
```

---

## 二、核心发现

### 2.1 角色重定义：SDK → C/S Client Service

当前 ZoneCNH 文档体系已经将 `binance` 列为一个 **CEX SDK**（ARCHITECTURE.md 行 354、STATUS.md 行 108）。但该 patch 将其**重新定位**为一个完整的 **C/S Client 市场数据采集服务**，包含：

| 维度 | 当前文档（旧） | Patch 定义（新） |
|------|---------------|-----------------|
| 角色 | CEX SDK | Market Data C/S Client Service |
| 产品线 | 未定义 | Spot + USDⓈ-M + COIN-M + Options |
| 传输 | 未定义 | gRPC client streaming → MarketDataService |
| 可靠性 | 未定义 | SQLite spool + checkpoint + idempotency |
| 管理面 | 未定义 | Gin admin (/healthz, /readyz, /debug/*, /admin/*) |
| 输出 | 未定义 | Canonical `MarketEvent` via gRPC |

**这是一个重大的架构升级**——从"被动 SDK 库"变为"主动数据采集服务"。

### 2.2 缺失的架构组件：Market Data Server

Patch 大量引用 `MarketDataService` 作为 gRPC 服务端（接收 binance 发来的 MarketEvent），但：

- **ZoneCNH 当前没有任何模块定义 `MarketDataService` 服务端**
- `module/contracts` 定义了 `MarketEvent` DTO 和 `MarketDataProvider` 接口（Go Port），但**没有 gRPC 服务定义**
- Patch 的 PR-003 试图在 `module/contracts/proto` 中添加 proto 定义，但**谁实现 MarketDataService 服务端？**

这暴露了一个架构空白：binance 向谁发数据？可能是 `market-data` 模块（当前已列出 18 个组件），但 patch 中未明确这个接收端的规格。

### 2.3 依赖模块升级幅度

| PR | 目标模块 | 变更量估算 | 风险 |
|----|---------|-----------|------|
| PR-001 | `module/binance/` 新建 | 全新 20 文件 | 🟢 纯增量 |
| PR-002 | `module/domain-market` | 需新增 ~6 个类型 | 🟡 现有 API 可能需要兼容迁移 |
| PR-003 | `module/contracts` | 新增 5 个 proto 文件 | 🟡 proto 生成代码管理策略需明确 |
| PR-004 | `module/transportx` | 补充策略声明 | 🟢 纯策略文本 |
| PR-005 | `github.com/ZoneCNH/binance` | 全量实现 | 🔴 依赖 PR-002/003/004 完成 |

**PR-002 是最关键的阻塞项**：`domain-market` 当前 SPEC 定义的是 `MarketEventEnvelope`（包含 Bar/Tick），而 patch 需要的是 `InstrumentKey`、`ProductLine`、`PriceKind`、`InstrumentType`、`OptionType`、`MarketScope`、`MarketFactEnvelope`、`decision_time` —— 这些在当前 `domain-market/SPEC.md` 中**全都不存在**。

### 2.4 与现有 STATE 的冲突

当前文档已有 `binance-market` 作为 Provider 模块（ARCHITECTURE.md 行 367）：
```
| binance-market | v0.1.0 | ✅ P0 | 80% | Binance Kline/Ticker Provider |
```

Patch 没有说明 `binance`（新 C/S Client）与 `binance-market`（旧 Provider）的关系：
- 是否替代 `binance-market`？
- 是否共存？谁负责什么？
- 如果 `binance` 已包含 Spot/USDM/Options 的 Kline/Ticker 采集，`binance-market` 是否冗余？

### 2.5 边界门禁脚本的技术问题

`scripts/check-binance-boundaries.sh` 依赖 `rg`（ripgrep），但 ZoneCNH 项目没有任何地方使用 ripgrep。CI 中需要额外安装依赖。建议改为 `grep -r` 以降低外部依赖。

---

## 三、文档质量评估

### ✅ 做得好的

1. **边界定义清晰**：`BOUNDARY-GATES.md` 的 6 个门禁是**可执行、可验证**的，直接对应 SPEC 中 "Does not own" 条款
2. **追溯链完整**：`TRACEABILITY.md` 14 条需求 → 12 个任务 → 验证方法，全链路闭合
3. **任务拆分合理**：12 个 TASK 有清晰的 A/C 和依赖关系，独立可测
4. **ADR 结构标准**：Context → Decision → Consequences 三段式
5. **SPEC §10 A/C 可测试**：每项都是布尔断言（如 "Spot BTCUSDT and USDⓈ-M BTCUSDT produce distinct InstrumentKey"）
6. **RUNTIME-MAPPING.md**：spec↔impl 映射明确，禁止的导入路径列举清晰

### ⚠️ 需要修复

| # | 问题 | 严重度 | 建议 |
|---|------|--------|------|
| 1 | `binance` vs `binance-market` 关系未澄清 | HIGH | APPLY-GUIDE 中说明两模块的演进关系 |
| 2 | MarketDataService 服务端无人认领 | HIGH | 在 SPEC §7 或 ADR 中明确接收端是哪个模块 |
| 3 | `domain-market` 升级范围未细化 | MEDIUM | PR-002 应附带具体的类型变更 diff 预览 |
| 4 | `scripts/check-binance-boundaries.sh` 依赖 `rg` | LOW | 改为 POSIX `grep` 或声明 `ripgrep` 为 CI 依赖 |
| 5 | 缺少 `module/binance/GOAL.md` | LOW | 按 ZoneCNH 约定，模块应包含 Goal 文件 |
| 6 | SPEC §3 "Owns" 列出 22 项，但包含具体实现路径（`internal/binance/spot`） | LOW | 这些是实现细节，应移到 IMPLEMENTATION-PLAN |

---

## 四、架构影响
移除 binance-market
```
当前架构：
  数据域: binance (SDK) + binance-market (Provider) + ...18 个组件

Patch 后架构：
  数据域: binance (C/S Client Service) ← 角色升级
          binance-market ← 关系待澄清
          + 隐式引入 MarketDataService Server（接收端，归属未定）
```

**关键问题**：Patch 实际上声明了一个新的架构模式——C/S market data pipeline——但**只定义了 Client 端**。Server 端的规格缺失会导致：
- PR-003 的 proto 定义没有对应实现模块
- PR-005 的 gRPC sender 没有对端可测试
- 集成测试（TASK-BINANCE-011）缺少 mock/real server

---

## 五、合并建议

### 合并前必须解决

1. **明确 Service 端归宿**：`MarketDataService` 由哪个模块实现？（建议在 ADR 或 SPEC §7 中注明）
2. **澄清 binance vs binance-market**：替代还是共存？在 APPLY-GUIDE 中加一节
3. **PR-002 domain-market 升级**：给出具体的新增类型清单和向后兼容策略

### 建议的合并顺序

```
PR-001 (module/binance spec)      ← 先落地规格，不依赖其他变更
    ↓
PR-003 (contracts proto)          ← 定义跨域契约，domain-market 可引用
    ↓
PR-002 (domain-market upgrade)    ← 基于 proto 定义实现 Go 类型
    ↓
PR-004 (transportx policy)        ← 声明 gRPC/Gin 策略
    ↓
PR-005 (binance runtime impl)     ← 全部依赖就绪
```

### 总体评估

**这是一份结构完整、边界清晰、可执行的模块规格落地包**。核心亮点是边界门禁的可自动化验证，以及 5-PR 分阶段合并策略。主要风险在于**架构空白**（Service 端归属）和**与现有文档体系的概念冲突**（SDK vs Service）。解决这两个问题后，建议按上述顺序合并。

---

## 六、文件清单

| # | 文件路径 | 行数 | 类型 |
|---|---------|------|------|
| 1 | `APPLY-GUIDE.md` | 101 | 合并计划 |
| 2 | `module/binance/SPEC.md` | 230 | 模块规格 |
| 3 | `module/binance/README.md` | 35 | 模块说明 |
| 4 | `module/binance/IMPLEMENTATION-PLAN.md` | 77 | 实现计划 |
| 5 | `module/binance/TRACEABILITY.md` | 19 | 追溯矩阵 |
| 6 | `module/binance/BOUNDARY-GATES.md` | 64 | 边界门禁 |
| 7 | `module/binance/RUNTIME-MAPPING.md` | 133 | 运行时代码映射 |
| 8 | `module/binance/tasks/TASK-BINANCE-001-product-line-catalog.md` | — | 任务 |
| 9 | `module/binance/tasks/TASK-BINANCE-002-instrument-parser.md` | — | 任务 |
| 10 | `module/binance/tasks/TASK-BINANCE-003-spot-connector.md` | — | 任务 |
| 11 | `module/binance/tasks/TASK-BINANCE-004-usdm-futures-connector.md` | — | 任务 |
| 12 | `module/binance/tasks/TASK-BINANCE-005-coinm-futures-connector.md` | — | 任务 |
| 13 | `module/binance/tasks/TASK-BINANCE-006-options-connector.md` | — | 任务 |
| 14 | `module/binance/tasks/TASK-BINANCE-007-market-event-mapper.md` | — | 任务 |
| 15 | `module/binance/tasks/TASK-BINANCE-008-grpc-cs-client.md` | — | 任务 |
| 16 | `module/binance/tasks/TASK-BINANCE-009-spool-checkpoint.md` | — | 任务 |
| 17 | `module/binance/tasks/TASK-BINANCE-010-gin-admin.md` | — | 任务 |
| 18 | `module/binance/tasks/TASK-BINANCE-011-contract-tests.md` | — | 任务 |
| 19 | `module/binance/tasks/TASK-BINANCE-012-boundary-gates.md` | — | 任务 |
| 20 | `docs/adr/ADR-2026-06-binance-module-boundary.md` | 75 | 架构决策 |
| 21 | `docs/services/binance-market-client-svc.md` | 56 | 服务描述 |
| 22 | `scripts/check-binance-boundaries.sh` | 41 | CI 脚本 |
| 23 | `repo-skeleton/README.md` | 21 | 仓库骨架 |
