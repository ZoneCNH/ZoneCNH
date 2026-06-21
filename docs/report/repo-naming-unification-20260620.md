# FoundationX 仓库命名对齐同步闭环说明

**日期**: 2026-06-21
**范围**: ZoneCNH 组织 86 个仓库  
**目标**: 对齐 `README.md`、`ARCHITECTURE.md`、`docs/architecture/`、`STATUS.md` 与 `module/README.md` 的当前命名事实，移除过时的 kebab/PascalCase 迁移假设，只保留经权威正文支持的残留项。

> 说明：本文已收口为同步与修正闭环记录，不是 GitHub 重命名执行单。仓库名、目录名与文档投影以当前权威正文为准。
>
> 现实状态：`module/README.md` 已将 L2.5 显示层切换为 `snake_case`，但链接目标仍指向当前目录投影 `domain_market` / `domain_macro` / `domain_exchange`；本文继续把“目标命名口径”和“当前文件投影”分开记录，避免把闭环说明写成执行计划。
>
> 补充说明：`SignalIntent` 属于 contracts 契约投影，已在 `docs/architecture/08-contracts.md` 与 `STATUS.md` 固化，不计入本次 L2.5 命名清理；P1 / P2 事件与接口统一已归档为 `docs/report/architecture-structural-repair-plan-20260621.md` 的闭环记录，本文不展开执行树。
>
> 配套关系：`docs/report/architecture-structural-analysis-20260621.md` 负责结构性诊断摘要，`docs/report/architecture-structural-repair-plan-20260621.md` 负责闭环修复记录；本文只维护命名同步结果与历史投影边界。

---

## 一、当前命名口径

### 规则 N1：基座与横切模块（保留现名）

适用于：Foundation 层基础模块、存储 adapter、横切 SDK。

当前权威正文中已经稳定出现的名称包括：

`kernel` `configx` `observex` `resiliencx` `schedulex` `alertx`
`redisx` `kafkax` `natsx` `clickhousex` `postgresx` `taosx` `ossx`
`transportx` `decimalx` `testkitx` `xlib_standard` `xlib_harness` `xlib_evidence`
`bootstrap` `contracts` `xlibgate`

命名原则：保持小写；多词沿用现有下划线或既有后缀风格，不在本轮引入连字符。

### 规则 N2：领域模块、数据管线与引擎（snake_case）

适用于：分析域、决策域、执行域、L2.5 目录与数据域。

当前正文中的规范写法包括：

`domain_market` `domain_exchange` `domain_macro`
`market_data` `macro_data` `alternative_data`
`factor_engine` `factor_eval` `feature_store`
`market_regime` `macro_regime` `regime_engine`
`flowx`

命名原则：多词名称统一为 snake_case；单词仓库保留裸名。

### 规则 N3：外部数据源适配器（裸名 / 复合词下划线）

适用于：交易所 SDK、宏观数据源 SDK。

当前正文中的名称包括：

`binance` `okx` `bybit` `coinbase` `bitget` `gate` `htx` `hyperliquid`
`kucoin` `lighter` `mexc` `upbit`
`fred` `bea` `ecb` `eastmoney` `coinglass` `jin10` `yahoo` `treasury`
`yield_curve` `japan_cb` `uk_cb`

命名原则：保持来源可识别，不强行改写为连字符风格。

### 规则 N4：禁止

| 禁止模式 | 示例 | 原因 |
| -------- | ---- | ---- |
| kebab-case 作为新投影 | `domain_market`, `xlib-gate`, `factor_engine` | 与当前权威正文的现名不一致，制造同步漂移 |
| PascalCase | `GYM`, `OneKey` | 当前权威正文中没有稳定引用 |
| 未经证据的派生别名 | `macro_data_py` | 只是旧稿投影或说明性后缀，不应直接写成仓库名 |
| 把现名写成“需重命名” | `market_regime`, `macro_regime`, `ms_brain` | 与 `README.md` / `ARCHITECTURE.md` / `STATUS.md` 已有事实冲突 |

---

## 二、当前状态与处置

| 名称 | 状态 | 处置 |
| ---- | ---- | ---- |
| `market_regime` | 已对齐 | `README.md` / `ARCHITECTURE.md` / `docs/architecture/` / `STATUS.md` 均使用现名 |
| `macro_regime` | 已对齐 | 同上 |
| `ms_brain` | 已对齐 | 同上 |
| `regime_engine` | 已对齐 | 同上 |
| `macro_data` | 已对齐 | 当前正文保留现名；`docs/architecture/07-three-engines.md` 的旧投影已回收 |
| `L2.5` 目录命名口径 | 已对齐（显示层完成） | 目标口径已固定为 `snake_case`；`module/README.md` 已切换为 `snake_case` 显示层，链接继续指向当前目录投影 |
| `xlibgate` | 保留现名 | `module/README.md`、`README.md`、`ARCHITECTURE.md`、`STATUS.md` 均使用该名；如需更名须单独做 import / go.mod 影响评审 |
| `backtest_engine` / `risk_engine` / `order_engine` / `portfolio_engine` | 历史占位 | 继续按 DEPRECATED 路线处理，不作为本轮仓库改名目标 |

> 旧稿中的 `GYM`、`OneKey`、`macro_data_py`、`xlib-gate` 已从执行清单中移除。

---

## 三、特殊注意：`contracts` / `transportx` 共享 Go module

```text
contracts/go.mod    → module github.com/ZoneCNH/xlib_standard
transportx/go.mod   → module github.com/ZoneCNH/xlib_standard
xlib_standard/go.mod → module github.com/ZoneCNH/xlib_standard
```

三个仓库共享同一 Go module `github.com/ZoneCNH/xlib_standard`，这是已知设计决策，非命名问题，无需变更。

---

## 四、同步收口结果

本轮 rename 执行面已清零；阶段 1 / 2 已完成，阶段 3 仅保留历史边界说明，不再作为本轮执行面。

### 阶段 1：锁定现名（已完成）

1. 保持 `README.md`、`ARCHITECTURE.md`、`docs/architecture/01-overview.md`、`02-domain-layers.md`、`05-foundation.md`、`08-contracts.md`、`STATUS.md`、`module/README.md` 中的现名不变。
2. 删除本文件中的旧版 rename 叙事，不再把 `market_regime`、`macro_regime`、`ms_brain`、`macro_data` 写成重命名目标。
3. 将 `xlibgate` 视为当前保留名；如果后续仍要更名，必须单独开 import / go.mod 评审，不与当前对齐同步混在一起。

### 阶段 2：修正文档投影（已完成）

1. 确认 `docs/architecture/07-three-engines.md` 已回收 `macro_data_py`，正文统一为 `macro_data`，并把 `L2.5` 目录命名口径固定为 `snake_case`。
2. 检查 `STATUS.md` 的投影块，确认没有把 `market_regime`、`macro_regime`、`ms_brain`、`regime_engine` 回写成旧名或 rename 目标。
3. 复核 `module/README.md` 的索引表，分清 `xlibgate` 保留现名和 `domain_market` / `domain_macro` / `domain_exchange` 的显示层口径，链接目标继续沿用当前目录投影，不把目录 rename 与文档说明混写。

### 阶段 3：历史遗留边界（仅说明，不再执行）

1. `backtest_engine` / `risk_engine` / `order_engine` / `portfolio_engine` 继续按 DEPRECATED 路线处理，不再和现名同步混写。
2. `GYM`、`OneKey`、`xlib-gate`、`macro_data_py` 只保留为历史提案或旧稿残留，不进入当前执行清单。

---

## 五、同步结果

| 项目 | 状态 | 备注 |
| ---- | ---- | ---- |
| 已统一的现名 | `market_regime`, `macro_regime`, `ms_brain`, `regime_engine`, `macro_data`, `xlibgate` | 作为当前正文的稳定投影保留 |
| `L2.5` 目录命名口径 | 已对齐（显示层完成） | 目标命名已统一为 `snake_case`，`module/README.md` 已完成显示层同步 |
| 已回收文档投影 | `docs/architecture/07-three-engines.md` 的 `macro_data_py` | 已统一为 `macro_data` |
| 未来专项边界 | `xlibgate` 如未来要更名，需单独评审 | 本轮不执行；当前保持现名 |
| 已移出本轮清单 | `GYM`, `OneKey`, `xlib-gate`, `macro_data_py` | 仅保留历史痕迹，不再作为执行目标 |

---

## 六、文档更新清单

| 文件 | 变更内容 |
| ---- | -------- |
| `README.md` | 分析域、数据域、xlib 引用维持现名 |
| `ARCHITECTURE.md` | 分层图和模块表维持现名 |
| `docs/architecture/01-overview.md` | 三引擎与数据流引用维持现名 |
| `docs/architecture/02-domain-layers.md` | 域内模块命名保持 snake_case / 现名 |
| `docs/architecture/05-foundation.md` | 基座与模块索引保持 `xlibgate`、`xlib_standard` 等现名 |
| `docs/architecture/07-three-engines.md` | `macro_data_py` 已回收为 `macro_data` |
| `docs/architecture/08-contracts.md` | `market_regime` / `macro_regime` / `regime_engine` 继续使用现名 |
| `docs/report/architecture-structural-analysis-20260621.md` | 诊断摘要已固定 `L2.5` 命名基准为 `snake_case`，并将 `x.go` / `composer` 入口口径与 `README.md` / `ARCHITECTURE.md` / `docs/architecture/*` 的入口说明同步收口；`macro_data` / `market_data` 统一为数据域表述；完整修复动作已归档为 `docs/report/architecture-structural-repair-plan-20260621.md` 的闭环记录 |
| `STATUS.md` | 维持现名投影；结构修复只保留闭环摘要并指向 repair plan，不在此处重复完整执行树 |
| `module/README.md` | L2.5 显示层已切换为 `domain_market` / `domain_macro` / `domain_exchange`，并补充 `data_cs_module` / `data_independent_process` 标准化入口；链接目标继续使用当前目录投影，`xlibgate` 保持现名 |

---

## 附：全部 86 仓库命名分类

### Foundation（当前保留）

`kernel` `configx` `observex` `resiliencx` `schedulex` `alertx`
`transportx` `decimalx` `testkitx` `xlib_standard` `xlib_harness` `xlib_evidence`
`bootstrap` `contracts` `redisx` `kafkax` `natsx` `clickhousex` `postgresx` `taosx` `ossx` `xlibgate`

### L2.5 Domain Libraries（snake_case 目标口径，历史路径投影待清零）

`domain_market` `domain_exchange` `domain_macro`

### 分析域（snake_case，当前对齐）

`factor_engine` `factor_eval` `feature_store` `market_regime` `macro_regime` `regime_engine` `ms_brain` `flowx`

### 数据域（snake_case，当前对齐）

`market_data` `macro_data` `alternative_data`

### xlib 工具（当前保留 `xlibgate`）

`xlib_evidence` `xlib_harness` `xlib_standard` `xlibgate`

### x.go（特殊，keep）

`x.go`

### 交易所 SDK（裸名，当前对齐）

`binance` `okx` `bybit` `coinbase` `bitget` `gate` `htx` `hyperliquid` `kucoin` `lighter` `mexc` `upbit`

### 宏观 SDK（裸名 / 复合词下划线，当前对齐）

`fred` `bea` `ecb` `eastmoney` `coinglass` `jin10` `yahoo` `treasury` `yield_curve` `japan_cb` `uk_cb`

### ML / 研究（当前保留）

`ms_brain`

### 历史提案（已移出本轮）

`GYM` `OneKey` `xlib-gate` `macro_data_py`

### 元仓库（keep）

`ZoneCNH` `.github`

### Rust

`binance.rs` `crcl`
