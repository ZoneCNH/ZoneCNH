# FoundationX 架构问题深度分析报告

**日期**: 2026-06-20  
**范围**: 全系统 75 组件 / 70+ 仓库  
**数据来源**: `.foundationx/status/index.json`、`STATUS.md`、各模块 `/home/{module}/` 本地源码树、管线评分表

---

## 一、🔴 致命问题：核心业务链路完全断裂

这是整个架构的最大风险，且比文档记录的更严重。

### 数据流现实

```
binance ✅ → market-data(dispatch) ✅ → market_regime ❌空仓库 → regime-engine ❌空仓库
macro-data ✅                        → macro_regime  ❌空仓库 → regime-engine ❌
                                                                ↓
                                                    signal-factory ❌ → riskx ❌ → orderx ❌
```

### 各域实际完成度

| 域 | 模块数 | 实际有代码 | 完成度 |
|---|---|---|---|
| Foundation | 21 | 18/21 factory | ~95% |
| Market Data | 3 | 3/3 有代码 | ~92% |
| Macro Data | 1 | 1/1 有代码 | ~100% |
| **分析域** | 8 | **0/8**（regime-engine 无 pkg） | **~0%** |
| **决策域** | 6 | **0/6**（全部仅 README） | **0%** |
| **执行域** | 7 | **0/7**（全部仅 README） | **0%** |

### P0 契约缺失

`contracts/pkg/contracts/` 只有 `contracts.go` + `ingestion.go`，**以下 P0 级 DTO 一条都未固化**：

| 契约 | 数据流路径 | 优先级 |
|---|---|---|
| `RegimeSnapshot` | market_regime → regime-engine | P0 |
| `RegimeCard` | macro_regime → regime-engine | P0 |
| `DecisionCard` | regime-engine → signal-factory / risk-engine | P0 |
| `MarketDataProvider` | market-data → market_regime | P0 |
| `MacroDataProvider` | macro-data → macro_regime | P0 |
| `FactorInput` / `FactorOutput` | factor-engine 内部 | P1 |
| `SignalIntent` | signal-factory → orderx | P1 |

> **风险**：上层三个域在没有任何契约定义的情况下写代码，将来必然出现接口不兼容，重构成本极高。

---

## 二、🔴 高风险：双轨并存，身份混乱

4 组模块"旧占位仓库 + 新规格模块"并存，没有明确废弃路线：

| 旧仓库（占位约 5%） | 新模块（SPEC draft） | 职责变化 |
|---|---|---|
| `risk-engine` | `riskx` | 无（命名重构） |
| `order-engine` | `orderx` | 无（命名重构） |
| `portfolio-engine` | `positionx` | portfolio → position（语义收窄） |
| `backtest-engine` | `backtestx` | 无（命名重构） |

**问题**：两者同时出现在 STATUS / README / ARCHITECTURE 中，外部消费者无法判断应该依赖哪个仓库。

另外 `market_regime` / `macro_regime` 使用 `snake_case` 命名，与全系统 `kebab-case` 约定不一致，属历史遗留问题。

---

## 三、🔴 基座阻塞：2 个 Open Blocker 卡住 Foundation factory 闭合

| Blocker | 模块 | 严重性 | 问题描述 |
|---|---|---|---|
| BLK-009 | `bootstrap` | medium | `stores.go:217` import `foundationx.SecretString`，遗留依赖未清除；Stores!=None 路径全部为 stub |
| BLK-010 | `ossx` | high | 公开 release v1.0.1 但仓库 0 pkg 源码（仅文档/脚本），evidence archive 缺失 |

**后果**：Foundation 整体卡在 non-factory（18/21），下游业务域无法宣称依赖了一个 factory-grade 基座。

---

## 四、🟡 中风险：7 个 x 模块横切重复实现未收敛

7 个存储 adapter（redisx / kafkax / natsx / clickhousex / postgresx / taosx / ossx）各自独立实现了：

```
health check × 7    ← 应收敛到 kernel/healthx
metrics 常量 × 7    ← 应收敛到 observex
lifecycle × 7       ← 已有 kernel/lifecycx，但未统一接入
retry loop × 2      ← clickhousex + ossx 有独立实现，应接入 resiliencx
```

每次改一个共性行为（如健康检查字段格式），需要修改 7 个仓库。

**现有方案**：`docs/report/x-modules-cross-cutting-dedup-plan-20260620.md`（尚未执行）

---

## 五、🟡 中风险：管线评分 6 个模块未达 98 分门禁

| 模块 | 最低分项 | 评分 | 原因 |
|---|---|---|---|
| `xlib-standard` | spec & matrix | 80 | 快照格式特殊，23节结构不完整 |
| `xlib-evidence` | spec | 83 | WHEN/THEN 章节不完整 |
| `xlib-harness` | spec | 83 | 同上 |
| `transportx` | spec | 84 | 23 节结构缺失 |
| `natsx` | tasks | 92 | 任务追溯缺口 |
| `configx` | tasks | 96 | 小幅缺口 |

这 6 个模块均为已发布的 factory-ready 模块，但 Spec 管线形式上未闭合，影响治理体系一致性。

---

## 六、🟡 中风险：x.go 体量异常大

`x.go` 仓库本地目录 2.8MB，声称包含 33 项。按 Composition Root 原则，入口应只包含 wiring + lifecycle，2.8MB 远超预期。

**待核实**：是否混入了因子计算逻辑、信号判断、风控规则或订单路由等业务逻辑。

**影响**：违反 P13 设计原则（x.go 只做编排），且业务逻辑散落入口会导致无法被上层域复用。

---

## 七、🟡 中风险：75 个仓库无统一命名前缀

当前命名混杂 3 种风格：`configx`（x 后缀）/ `market-data`（kebab）/ `market_regime`（snake）/ `binance`（裸名）/ `x.go`（特殊）。

70+ 仓库增长后维护困难，外部访问时无法识别模块归属。

**已有规划**（R12）但未推进：

```
foundation-*  → kernel / configx / observex / resiliencx ...
adapter-*     → binance / okx / fred ...
engine-*      → factor-engine / risk-engine ...
lab-*         → ms_brain / alternative-data ...
```

---

## 八、🟡 中风险：数据域 binance 已实现但无消费者

`binance` 已实现（v0.2.0，4 产品线，bootstrap 接入，domain-exchange 适配），但：
- `market_regime` 完全为空，binance 输出的 domain-market 数据无处消费
- 其余 12 个 CEX/DEX SDK（okx/bybit/...）均停在约 80%，没有统一的 C/S Module 封装
- `market-data` dispatch 的下游 receiver 不明确

---

## 九、问题优先级矩阵

| 优先级 | 问题 | 阻塞目标 |
|---|---|---|
| **P0** | contracts P0 DTO 未固化 | 分析域/决策域/执行域无法开始 |
| **P0** | 分析域三引擎（market_regime/macro_regime/regime-engine）全空 | 核心业务闭环 |
| **P1** | BLK-009 bootstrap 遗留依赖 | Foundation factory 闭合 |
| **P1** | BLK-010 ossx 无源码 | Foundation factory 闭合 |
| **P1** | 双轨模块废弃路线不明 | 开发者认知统一 |
| **P2** | 7 模块横切重复收敛 | 维护成本降低 |
| **P2** | 管线 6 模块评分未达 98 | 治理一致性 |
| **P3** | x.go 体量核实 | 架构守卫 |
| **P3** | 75 仓库命名统一 | 长期可维护性 |

---

## 十、建议行动路径

### 本周（解锁业务域）

1. **固化 contracts P0 DTO**：`RegimeSnapshot` / `RegimeCard` / `DecisionCard`
   - 这是解锁上层三个域的**唯一前置条件**
   - 修改范围：`/home/contracts/pkg/contracts/`，新增 3 个接口文件

2. **清理 BLK-009**：`bootstrap/stores.go:217` 去除 `foundationx.SecretString` 依赖
   - 改动范围小，可立即执行，解除 Foundation factory 阻塞

### 下两周（最小链路闭环）

3. `market_regime` 最小实现（依赖 domain-market ✅ + contracts P0 ✅）
4. `macro_regime` 最小实现（依赖 domain-macro ✅ + contracts P0 ✅）
5. 为旧占位仓库（risk-engine / order-engine / portfolio-engine / backtest-engine）添加 DEPRECATED 标记

### 下一个月（架构收敛）

6. 执行 x 模块横切收敛计划（已有方案）
7. `regime-engine` 最小实现 → DecisionCard 链路打通
8. `signal-factory` 骨架（消费 DecisionCard）
9. 补齐 6 个模块 Spec 至 98 分

---

## 附：相关文档

| 文档 | 路径 |
|---|---|
| x 模块横切去重计划 | `docs/report/x-modules-cross-cutting-dedup-plan-20260620.md` |
| Foundation 20 模块评分 | `docs/report/foundation-20-modules-scoring-20260619.md` |
| 架构总览 | `docs/architecture/01-overview.md` |
| 三引擎规格 | `docs/architecture/07-three-engines.md` |
| 契约固化清单 | `docs/architecture/08-contracts.md` |
| Blocker 列表 | `.foundationx/blockers.json` |
| Factory 状态 | `.foundationx/status/index.json` |
