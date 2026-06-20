# FoundationX 仓库命名统一方案

**日期**: 2026-06-20  
**范围**: ZoneCNH 组织 86 个仓库  
**目标**: 消除 snake_case、PascalCase 命名混乱，建立统一约定，明确废弃路线

---

## 一、命名约定规则

### 规则 N1：x 后缀（基础设施 & 存储适配器）

适用于：Foundation 层基础模块、存储 adapter、横切 SDK

```
kernel   configx   observex   resiliencx   schedulex   alertx
redisx   kafkax   natsx   clickhousex   postgresx   taosx   ossx
transportx   decimalx   domainx   testkitx   xlibgate
backtestx   orderx   positionx   riskx   strategyx   flowx
```

**命名格式**：`{名称}x`（全小写，无连字符）

### 规则 N2：kebab-case（领域模块 & 数据管线 & 引擎）

适用于：分析域、决策域、执行域模块，数据收集管线，契约库，工具库

```
market_data   macro_data   alternative_data
domain_market   domain_exchange   domain_macro
regime_engine   factor_engine   signal_factory   feature_store
xlib_evidence   xlib_harness   xlib_standard
bootstrap   contracts   foundation_example   composer   maestro
```

**命名格式**：`{名称}`（全小写，连字符分隔）

### 规则 N3：裸名（外部数据源适配器）

适用于：交易所 SDK、宏观数据 SDK，名称取自数据源官方名称

```
binance   okx   bybit   coinbase   bitget   gate   htx   hyperliquid
kucoin   lighter   mexc   upbit
fred   bea   ecb   eastmoney   coinglass   jin10   yahoo   treasury
yield_curve   japan_cb   uk_cb
```

**命名格式**：官方名称全小写（连字符用于复合词）

### 规则 N4：禁止

| 禁止模式 | 示例 | 原因 |
|---|---|---|
| snake_case | `market_regime` | 与 GitHub kebab 惯例不符 |
| PascalCase | `GYM`, `OneKey` | 社区不可识别 |
| 混合 | `ms_brain` | 同上 |

---

## 二、问题清单与处置方案

### A 类：直接重命名（无 Go module 影响）

| 当前名称 | 主语言 | 问题 | 新名称 | 操作 |
|---|---|---|---|---|
| `market_regime` | — (空) | snake_case | `market_regime` | GitHub 重命名 |
| `macro_regime` | — (空) | snake_case | `macro_regime` | GitHub 重命名 |
| `ms_brain` | PLpgSQL | snake_case | `ms_brain` | GitHub 重命名 |
| `macro_data` | Python | snake_case + 与 Go `macro_data` 语义重叠 | `macro_data_py` | GitHub 重命名 + 描述说明 |
| `GYM` | — (空) | PascalCase | `gym` | GitHub 重命名 |
| `OneKey` | Shell | PascalCase | `onekey` | GitHub 重命名 |

> **零 Go 模块影响**：以上 6 个仓库均无 Go module 路径（无 go.mod 或非 Go 项目）

### B 类：Go module 路径迁移（需同步更新 go.mod + imports）

| 当前名称 | Go module 路径 | 新名称 | 已知依赖方 | 迁移成本 |
|---|---|---|---|---|
| `xlibgate` | `github.com/ZoneCNH/xlibgate` | `xlib-gate` | 仅自身（0 外部依赖） | **低** |

> `xlibgate` 是 xlib 家族唯一不一致成员：xlib_evidence / xlib_harness / xlib_standard 均已 kebab，只有 xlibgate 为 x 后缀风格。

### C 类：废弃旧占位仓库（双轨并存问题）

不重命名，而是将旧仓库标记 DEPRECATED：

| 旧仓库（占位） | 新规格模块 | 废弃行动 |
|---|---|---|
| `backtest_engine` | `backtestx` | 描述加 `[DEPRECATED → backtestx]`，README 加废弃声明 |
| `risk_engine` | `riskx` | 同上 |
| `order_engine` | `orderx` | 同上 |
| `portfolio_engine` | `positionx` | 同上，注意职责语义也有变化（portfolio → position） |

### D 类：{exchange}-market 与 {exchange} 关系澄清

当前并存 5 对：`binance` + `binance-market`，`bybit` + `bybit_market`，`coinbase` + `coinbase_market`，`okx` + `okx_market`，`bitget` + `bitget_market`

| 问题 | 建议 |
|---|---|
| 两者职责边界不清晰 | `{exchange}` = 完整交易 SDK（下单/账户）；`{exchange}-market` = 只读行情分发接口 |
| 命名已 kebab，不用改 | 在 README 中明确职责分工即可 |

### E 类：保持现状（已建立约定）

以下不需要变动：
- xlib 家族（xlib_evidence / xlib_harness / xlib_standard）
- Foundation x-suffix 模块（configx / observex / resiliencx ...）
- 宏观/交易所裸名（fred / bea / binance / okx ...）
- x.go（特殊：Composition Root，已成系统标志）
- ZoneCNH（GitHub profile，keep）
- .github（组织级 CI 模板，keep）

---

## 三、特殊注意：contracts / transportx 共享 Go module

```
contracts/go.mod    → module github.com/ZoneCNH/xlib_standard
transportx/go.mod   → module github.com/ZoneCNH/xlib_standard
xlib_standard/go.mod → module github.com/ZoneCNH/xlib_standard
```

三个仓库共享同一 Go module `github.com/ZoneCNH/xlib_standard`，**这是已知设计决策，非命名问题**，无需变更。

---

## 四、执行计划

### Phase 1：立即执行（A 类，6 个无影响重命名）

```bash
# 操作：GitHub 仓库重命名（Settings > Repository name）
# 或 gh api

gh api -X PATCH repos/ZoneCNH/market_regime -f name=market_regime
gh api -X PATCH repos/ZoneCNH/macro_regime   -f name=macro_regime
gh api -X PATCH repos/ZoneCNH/ms_brain       -f name=ms_brain
gh api -X PATCH repos/ZoneCNH/macro_data     -f name=macro_data_py
gh api -X PATCH repos/ZoneCNH/GYM            -f name=gym
gh api -X PATCH repos/ZoneCNH/OneKey         -f name=onekey
```

需同步更新的文档（自动重定向 2 年，但文档应主动更新）：
- `STATUS.md`：6 处链接 + 引用
- `README.md`：分析域模块列表
- `docs/architecture/01-overview.md` / `02-domain-layers.md`
- `ARCHITECTURE.md` stub

### Phase 2：下一个迭代（B 类，xlibgate → xlib-gate）

```bash
# Step 1: 更新 xlibgate/go.mod
module github.com/ZoneCNH/xlib-gate

# Step 2: GitHub 重命名
gh api -X PATCH repos/ZoneCNH/xlibgate -f name=xlib-gate

# Step 3: 扫描所有 go.mod / import 路径并更新
grep -r "ZoneCNH/xlibgate" /home/*/  --include="*.go" --include="go.mod"
```

> 当前无外部依赖，影响范围仅 xlibgate 自身。

### Phase 3：废弃标记（C 类，4 对旧引擎）

在旧仓库 README.md 首行添加：
```
> ⚠️ **DEPRECATED**: 本仓库已停止维护，请迁移至 [`{新仓库}`](https://github.com/ZoneCNH/{新仓库})。
```

GitHub 描述加 `[DEPRECATED → {新仓库}]`

---

## 五、命名健康度变化预测

| 指标 | 当前 | Phase 1 后 | Phase 1+2+3 后 |
|---|---|---|---|
| snake_case 仓库 | 4 | **0** | 0 |
| PascalCase 仓库 | 2 | **0** | 0 |
| xlib 家族不一致 | 1 | 1 | **0** |
| 双轨并存（无 DEPRECATED）| 4 对 | 4 对 | **0 对** |
| 命名规则违反总数 | 11 | **5** | **0** |

---

## 六、文档更新清单（Phase 1 执行后必须同步）

| 文件 | 变更内容 |
|---|---|
| `STATUS.md` | 6 个模块链接：`market_regime` → `market_regime` 等 |
| `README.md` | 分析域列表中的模块链接 |
| `docs/architecture/02-domain-layers.md` | 域内模块命名 |
| `docs/architecture/07-three-engines.md` | market_regime/macro_regime 引用 |
| `module/README.md` | 模块索引表 |
| `ARCHITECTURE.md` (stub) | 如有 market_regime 引用 |

---

## 附：全部 86 仓库命名分类

### Foundation（x-suffix，规范）
kernel · configx · observex · resiliencx · schedulex · alertx · transportx · decimalx · domainx · bootstrap · contracts · redisx · kafkax · natsx · clickhousex · postgresx · taosx · ossx · testkitx

### L2.5 Domain Libraries（kebab，规范）
domain_market · domain_exchange · domain_macro

### 分析域（kebab，规范）
factor_engine · factor_eval · feature_store · regime_engine

### 分析域（**需重命名**：snake → kebab）
`market_regime` → **market_regime** · `macro_regime` → **macro_regime**

### 决策域（x-suffix，规范）
riskx · strategyx · backtestx

### 决策域（**需废弃**）
~~risk_engine~~ · ~~backtest_engine~~

### 执行域（x-suffix，规范）
orderx · positionx · flowx · signal_factory

### 执行域（**需废弃**）
~~order_engine~~ · ~~portfolio_engine~~

### 数据域（kebab，规范）
market_data · macro_data · alternative_data · composer

### xlib 工具（kebab，规范 + 1 个待修复）
xlib_evidence · xlib_harness · xlib_standard · `xlibgate` → **xlib-gate**

### x.go（特殊，keep）
x.go

### 交易所 SDK（裸名，规范）
binance · okx · bybit · coinbase · bitget · gate · htx · hyperliquid · kucoin · lighter · mexc · upbit · binance-market · bybit_market · coinbase_market · okx_market · bitget_market

### 宏观 SDK（裸名/kebab，规范）
fred · bea · ecb · eastmoney · coinglass · jin10 · yahoo · treasury · yield_curve · japan_cb · uk_cb

### ML/研究（**需重命名**）
`ms_brain` → **ms_brain** · `GYM` → **gym**

### Infra/运维（keep）
sre · opsstack · wireguard · specs · composer · maestro · supergoal · foundation_example

### Python 数据（**需重命名**）
`macro_data` → **macro_data_py**

### 特殊（**需重命名**）
`OneKey` → **onekey**

### 元仓库（keep）
ZoneCNH · .github

### Rust
binance.rs · crcl
