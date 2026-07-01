# 08 业务域依赖矩阵扩展规划 — Business Domain Deps

- Module-Version: v1.1.0
- Last-Updated: 2026-06-26
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`module/FOUNDATION-DEPS.yaml`](../../../module/FOUNDATION-DEPS.yaml)、[`docs/architecture/03-boundaries.md`](../../architecture/03-boundaries.md)、[`boundary-gates-cross-module-promotion.md`](../boundary-gates-cross-module-promotion.md)
- 状态：**schema 已写入 FOUNDATION-DEPS.yaml v1.3.0（2026-06-26）；执行力待 Phase F（xlibgate 扩展）**

> 本专题将 FOUNDATION-DEPS.yaml 依赖矩阵从基座层扩展到业务域层，闭合"业务域无机器可读依赖矩阵"缺口。2026-06-26 已写入 `business_domain_modules` / `business_allowed_deps` / `business_forbidden_edges` 三段（方案 A：schema 先行数据），当前 xlibgate FoundationDeps struct 尚未消费，CI 不校验；执行力待 Phase F（xlibgate 扩展 FoundationDeps struct + scanImports 消费业务域边）。

---

## §1 缺口与目标

**缺口**：`FOUNDATION-DEPS.yaml` 覆盖 20 基座 + domainx 的允许/禁止 go.mod 依赖边；业务域模块（数据/分析/决策/执行域 ~50 模块）仅出现在 `forbidden_deps` 全局禁止清单（基座不得反向 import），**业务域之间的依赖边无机器可读矩阵**，只在 `docs/architecture/03-boundaries.md` 自然语言守卫表中描述。

**目标**：设计 FOUNDATION-DEPS.yaml 扩展 schema，登记业务域模块及其允许/禁止依赖边，使 CI（xlibgate）可消费。本专题定义 schema 与推广路径，**不修改** FOUNDATION-DEPS.yaml 实际内容。

---

## §2 现状分析

### §2.1 当前覆盖

| 层级 | FOUNDATION-DEPS 覆盖 | 业务域间依赖 |
| --- | --- | --- |
| 基座(20) + domainx | ✅ allowed_deps + forbidden_foundation_edges + constraints | N/A |
| L2.5 (decimalx/domain_market/domain_macro/domain_exchange) | ⚠️ 仅 domainx；其余在 module/README 自然语言描述 | N/A |
| 数据域 (market_data/macro_data/alternative_data) | ❌ 仅在 forbidden_deps 黑名单 | 自然语言（03-boundaries） |
| 分析域 (factor_engine/feature_store/...) | ❌ | 自然语言 |
| 决策域 (signal_factory/backtestx/...) | ❌ | 自然语言 |
| 执行域 (riskx/orderx/positionx/...) | ❌ | 自然语言 |
| 入口/横切 (composer/alertx) | ❌ | 自然语言 |

### §2.2 03-boundaries.md 中的自然语言守卫

`docs/architecture/03-boundaries.md` 依赖守卫表以自然语言描述业务域约束，例如：
- 决策→执行必须经 riskx
- 执行→决策只能走 fills 事件
- 分析域模块可依赖 L2.5 + 基座，不得依赖决策/执行域

这些约束目前**无机器可读登记**，CI 无法校验。

---

## §3 扩展 schema 设计

### §3.1 新增段落

在 FOUNDATION-DEPS.yaml 新增三个段落（规划，不立即实施）：

```yaml
# 业务域模块登记
business_domain_modules:
  <module_name>:
    domain: <data | analytics | decision | execution | entry | crosscut>
    layer: business
    repo: github.com/ZoneCNH/<module_name>
    description: "..."

# 业务域允许依赖边
business_allowed_deps:
  <module_name>:
    - <allowed_module>  # 允许单向依赖
    - <allowed_module>

# 业务域禁止依赖边
business_forbidden_edges:
  <module_name>:
    - <forbidden_module>  # 禁止依赖
```

### §3.2 与基座段的关系

- 基座段（`modules` / `allowed_deps` / `forbidden_foundation_edges`）保持不变
- `forbidden_deps` 全局禁止清单保持不变（基座不得 import 业务域）
- `business_allowed_deps` 只管业务域之间的边
- 业务域 → 基座/L2.5 的依赖隐含允许（单向下行），不重复登记

### §3.3 L2.5 补登记

L2.5 模块（decimalx/domain_market/domain_macro/domain_exchange）目前不在 `modules` 段（仅 domainx 在）。扩展时补登记：

```yaml
modules:
  # ... 现有 20 模块 ...
  decimalx:
    path: github.com/ZoneCNH/decimalx
    layer: l2_5
    stdlib_only: false
    description: "高精度十进制运算"
  domain_market:
    path: github.com/ZoneCNH/domain_market
    layer: l2_5
    stdlib_only: false
    description: "市场领域值对象"
  # ...
```

L2.5 依赖顺序：`decimalx → domainx → domain_market/domain_macro → domain_exchange`（来自 module/README.md）。

---

## §4 与 03-boundaries.md 的映射

扩展时须将 03-boundaries.md 自然语言守卫表逐条映射到 `business_allowed_deps` / `business_forbidden_edges`：

| 03-boundaries 守卫（自然语言） | 映射到 |
| --- | --- |
| 决策→执行必须经 riskx | `business_allowed_deps: {signal_factory, strategyx, ...}: [riskx]` |
| 执行→决策只能走 fills 事件 | `business_forbidden_edges: {riskx, orderx, ...}: [signal_factory, ...]`（事件除外） |
| 分析域不得依赖决策/执行域 | `business_forbidden_edges: {factor_engine, ...}: [riskx, orderx, ...]` |
| 数据域不得依赖分析/决策/执行域 | `business_forbidden_edges: {market_data, ...}: [factor_engine, ...]` |

> 完整映射须在实施时与 `docs/architecture/03-boundaries.md` 逐条核对，本专题仅给出 schema 与方向。

---

## §5 推广路径

参考 [`boundary-gates-cross-module-promotion.md`](../boundary-gates-cross-module-promotion.md) 的推广模式：

### §5.1 阶段划分

| 阶段 | 范围 | 产物 | 状态 |
| --- | --- | --- | --- |
| Phase A | L2.5 补登记（4 模块） | FOUNDATION-DEPS modules 段扩展 | ⏳ 待实施（会触发 CI clone，需先确认四仓就绪） |
| Phase B | 执行域登记（riskx/orderx/positionx/settlement） | business_domain_modules + allowed/forbidden | ✅ 已写入 FOUNDATION-DEPS v1.3.0 |
| Phase C | 决策域登记（signal_factory/backtestx/optimizer/strategyx/maestro） | 同上 | ✅ 已写入 FOUNDATION-DEPS v1.3.0 |
| Phase D | 分析域登记（factor_engine/feature_store/...） | 同上 | ✅ 已写入 FOUNDATION-DEPS v1.3.0 |
| Phase E | 数据域登记（market_data/macro_data/...） | 同上 | ✅ 已写入 FOUNDATION-DEPS v1.3.0 |
| Phase F | CI 集成（xlibgate 扩展 import graph 检查覆盖业务域） | xlibgate 更新 | ⏳ 待实施（独立仓库 /home/workspace/xlibgate） |

> 2026-06-26 已一次性写入 Phase B-E（全部业务域模块 + allowed/forbidden edges），采用方案 A（schema 先行数据，当前 CI 不消费）。Phase A（L2.5 补登记进 modules 段）与 Phase F（xlibgate 扩展）待后续推进。

### §5.2 实施前提【软】

每阶段实施前须确认：
1. 该域各模块 SPEC.md 的 Dependencies 节完整
2. 与 03-boundaries.md 守卫表核对一致
3. 各模块仓 go.mod 实际依赖与登记一致

### §5.3 当前实施边界（2026-06-26）

2026-06-26 已实施 Phase B-E 的 schema 写入（`business_domain_modules` / `business_allowed_deps` / `business_forbidden_edges` 三段，FOUNDATION-DEPS.yaml v1.3.0）。**关键约束**：
- schema 数据当前是"死数据"——xlibgate `FoundationDeps` struct（`boundary.go`）不消费 business_* 段，CI 不校验业务域依赖
- 未执行 Phase A（L2.5 补登记进 modules 段）——会触发 deps-matrix/evidence 主动 clone 校验，需先确认 decimalx/domain_market/domain_macro/domain_exchange 四仓 go.mod 就绪
- Phase F（xlibgate 扩展）是真正生效的前提：需扩展 `FoundationDeps` struct 新增 business_* 字段 + `scanImports` 覆盖业务域 import 扫描，在独立仓库 `/home/workspace/xlibgate` 实施

---

## §6 与 boundary-gates 推广的关系

[`boundary-gates-cross-module-promotion.md`](../boundary-gates-cross-module-promotion.md) 推广 CI 边界门禁（13 gate）；本专题推广依赖矩阵登记。两者互补：

| 维度 | boundary-gates | 本专题（业务域 deps） |
| --- | --- | --- |
| 管什么 | CI 边界门禁（import/process/storage/wire） | 依赖矩阵登记（allowed/forbidden edges） |
| 怎么执行 | boundary-gates.sh（runtime 仓 CI） | xlibgate import graph（本仓 CI + runtime 仓） |
| 关系 | boundary-gates 是依赖矩阵的**执行层** | 依赖矩阵是 boundary-gates 的**规则层** |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-26 | v1.1.0 | 实施方案 A：写入 business_domain_modules（30 模块）/ business_allowed_deps / business_forbidden_edges 三段到 FOUNDATION-DEPS.yaml v1.3.0；Phase B-E schema 完成，Phase A/F 待后续 | ZoneCNH |
| 2026-06-25 | v1.0.0 | 首次定义业务域依赖矩阵扩展 schema、03-boundaries 映射与推广路径（规划阶段） | ZoneCNH |
