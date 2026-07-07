# fred FRED 系列分类目录（深度分析产物）

> 来源：`.beads/1.md`《FRED 宏观数据采集完整清单》（2026 版，12 类 + 采集方式 + 使用注意）。
> 用途：把 `.beads/1.md` 的"按经济领域分类的序列清单"系统化纳入 `fred` 模块的采集范围，作为 `spec/SPEC.md` §5.2/§5.3 的**权威扩展目录**。
> 关联：`spec/SPEC.md` §5.1（端点矩阵）、§5.2（核心指标包）、§5.3（扩展维度）、§9（`domain_macro`）、§11.1（采集策略）。

**分析口径说明**：本目录对 `.beads/1.md` 的每个序列补三列，使其可直接驱动 `fred` 采集与建模：

- **周期属性**：`领先 / 同步 / 滞后`（沿用 `.beads/1.md` §0 的"领先—同步—滞后"三层框架）。
- **采集节奏**：沿用 `spec/SPEC.md` §11.1 默认策略——日频每日、周频每周、月频/季频按发布后 24h 内触发，release calendar trigger 优先。
- **修订敏感度**：`高`（GDP/PCE/就业等多次修订，走最近 3 个月修订回拉窗口）、`低`（利率/汇率/价格类基本不修订）、`发布滞后`（财政/部分季频指标初值晚到）。
- **domain_macro 落点**：`Obs`（时间序列 → `MacroObservation`/`MacroPoint`）、`Series`（序列元数据 → `MacroSeries`）、`Cat/Tag/Src/Rel`（图谱实体）。

---

## 1. 分析框架：领先—同步—滞后

| 类型 | 含义 | 典型序列（本目录） |
| --- | --- | --- |
| **领先（Leading）** | 早于经济拐点变化，用于预判 | ICSA、PERMIT、HOUST、UMCSENT、T10Y2Y、T10Y3M、SP500、BAMLH0A0HYM2、DGORDER、AMTMNO、SAHMREALTIME |
| **同步（Coincident）** | 与经济同步变化，反映当前状态 | GDPC1、INDPRO、PAYEMS、UNRATE、CPIAUCSL、PCEPI、RSAFS、FEDFUNDS、WALCL、DEXUSEU |
| **滞后（Lagging）** | 晚于拐点变化，用于确认趋势 | UNRATE（口径上滞后）、CPI 类、M2SL、GFDEBTN、USREC |

> 注：同一序列在不同分析用途下可切换属性（如 `UNRATE` 作失业率确认时为滞后，作当前劳动力市场状态时为同步）。本目录在逐行标注中取"主用途"属性，建模时允许按上下文覆盖。

---

## 2. 分类目录总览

| # | 经济领域 | 序列数 | 主周期属性分布 |
| --- | --- | --- | --- |
| 1 | 产出与增长 | 8 | 同步为主，含潜在/收入法 |
| 2 | 就业与劳动力市场 | 13 | 同步 + 领先（ICSA/JTSQUR）+ 滞后（UNRATE/U6） |
| 3 | 通胀 | 10 | 滞后为主，含预期（T5YIE/T10YIE/T5YIFR/MICH） |
| 4 | 货币政策与货币供给 | 10 | 滞后/政策 + 日频利率 |
| 5 | 利率、收益率曲线与信用利差 | 9 | 同步/领先（利差） |
| 6 | 房地产 | 7 | 领先（HOUST/PERMIT）+ 同步/滞后（房价） |
| 7 | 消费者部门 | 8 | 同步 + 领先（UMCSENT） |
| 8 | 制造业与商业活动 | 4 | 领先（订单）+ 滞后（库存） |
| 9 | 对外贸易与汇率 | 7 | 同步（贸易）+ 日频汇率 |
| 10 | 金融市场与金融条件 | 6 | 领先（SP500/VIX）+ 同步（NFCI/STLFSI4） |
| 11 | 政府财政 | 5 | 滞后 |
| 12 | 衰退与周期指标 | 3 | 领先（概率）+ 滞后（USREC 确认） |
| — | **合计** | **90** | — |

> 计数含 `.beads/1.md` 全部命名序列（组合键如 `DGS3MO/DGS2/DGS10/DGS30` 计 4 个）与 `module/fred` 扩展锚点 `NROU`、`DFEDTARU`。`ECBASSETSW`/`JPNASSETS` 为外部路由，不计入本目录采集分母（见 §11）。

---

## 3. 逐类详表

### 3.1 产出与增长（Output & Growth）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| GDPC1 | Real GDP（链式 2017 美元） | 季度 | 同步 | 季频发布后 24h | 高 | Obs |
| GDP | Nominal GDP | 季度 | 同步 | 季频发布后 24h | 高 | Obs |
| A191RL1Q225SBEA | Real GDP % Change (SAAR) | 季度 | 同步 | 季频发布后 24h | 高 | Obs |
| GDPPOT | Real Potential GDP | 季度 | 趋势（n/a） | 季频发布后 24h | 低 | Obs/Series |
| GDI | Gross Domestic Income | 季度 | 同步 | 季频发布后 24h | 高 | Obs |
| INDPRO | Industrial Production Index | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| TCU | Capacity Utilization: Total Industry | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| OPHNFB | Nonfarm Business Sector: Output Per Hour | 季度 | 同步/滞后 | 季频发布后 24h | 中 | Obs |

### 3.2 就业与劳动力市场（Labor Market）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| PAYEMS | All Employees: Total Nonfarm | 月度 | 同步 | 月频发布后 24h | 高 | Obs |
| UNRATE | Unemployment Rate (U-3) | 月度 | 滞后/同步 | 月频发布后 24h | 低 | Obs |
| U6RATE | U-6 Unemployment Rate | 月度 | 滞后 | 月频发布后 24h | 低 | Obs |
| CIVPART | Labor Force Participation Rate | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| EMRATIO | Employment-Population Ratio | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| ICSA | Initial Claims | 周度 | **领先** | 周频每周 | 低 | Obs |
| CCSA | Continued Claims | 周度 | 滞后 | 周频每周 | 低 | Obs |
| JTSJOL | Job Openings (JOLTS) | 月度 | 同步/滞后 | 月频发布后 24h | 低 | Obs |
| JTSQUR | Quits Rate (JOLTS) | 月度 | **领先** | 月频发布后 24h | 低 | Obs |
| JTSHIR | Hires Rate (JOLTS) | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| CES0500000003 | Average Hourly Earnings, Total Private | 月度 | 滞后/同步 | 月频发布后 24h | 低 | Obs |
| AWHAETP | Average Weekly Hours, Total Private | 月度 | 同步/领先 | 月频发布后 24h | 低 | Obs |
| NROU | Noncyclical Rate of Unemployment (CBO) | 季度 | 趋势/滞后 | 季频发布后 24h | 低 | Obs |

> 注：`NROU` 为 `module/fred` 扩展锚点（未在 `.beads/1.md` 原始清单出现），补入§3.2 作为自然失业率参考。

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| CPIAUCSL | CPI-U: All Items (SA) | 月度 | 滞后 | 月频发布后 24h | 中 | Obs |
| CPILFESL | Core CPI (ex Food & Energy) | 月度 | 滞后 | 月频发布后 24h | 中 | Obs |
| PCEPI | PCE Price Index | 月度 | 滞后 | 月频发布后 24h | 中 | Obs |
| PCEPILFE | Core PCE Price Index | 月度 | 滞后 | 月频发布后 24h | 中 | Obs |
| PPIACO | Producer Price Index: All Commodities | 月度 | 领先/同步 | 月频发布后 24h | 中 | Obs |
| T5YIE | 5-Year Breakeven Inflation Rate | 日度 | 预期（同步） | 日频每日 | 低 | Obs |
| T10YIE | 10-Year Breakeven Inflation Rate | 日度 | 预期（同步） | 日频每日 | 低 | Obs |
| T5YIFR | 5Y5Y Forward Inflation Expectation | 日度 | 预期 | 日频每日 | 低 | Obs |
| CORESTICKM159SFRBATL | Sticky Price CPI less Food & Energy | 月度 | 滞后 | 月频发布后 24h | 中 | Obs |
| MICH | Michigan Survey: Inflation Expectation | 月度 | 预期（领先） | 月频发布后 24h | 低 | Obs |

### 3.4 货币政策与货币供给（Monetary Policy & Money Supply）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| FEDFUNDS | Federal Funds Effective Rate | 月度 | 滞后/政策 | 月频发布后 24h | 低 | Obs |
| DFF | Federal Funds Effective Rate (Daily) | 日度 | 滞后/政策 | 日频每日 | 低 | Obs |
| WALCL | Fed Total Assets (Balance Sheet) | 周度 | 政策 | 周频每周 | 低 | Obs |
| M2SL | M2 Money Stock | 月度 | 滞后 | 月频发布后 24h | 低 | Obs |
| M1SL | M1 Money Stock | 月度 | 滞后 | 月频发布后 24h | 低 | Obs |
| BOGMBASE | Monetary Base | 月度 | 滞后 | 月频发布后 24h | 低 | Obs |
| RRPONTSYD | Overnight Reverse Repo Volume | 日度 | 政策 | 日频每日 | 低 | Obs |
| WTREGEN | Treasury General Account Balance (TGA) | 周度 | 政策 | 周频每周 | 低 | Obs |
| SOFR | Secured Overnight Financing Rate | 日度 | 同步（利率） | 日频每日 | 低 | Obs |
| DFEDTARU | Federal Funds Target Range - Upper Limit | 日度 | 政策 | 日频每日（FOMC 事件后刷新） | 低 | Obs |

> 注：`DFEDTARU` 为 `module/fred` 扩展锚点（未在 `.beads/1.md` 原始清单出现），补入§3.4 作为 FOMC 目标利率区间上沿。

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| DGS3MO | 3-Month Treasury Yield | 日度 | 同步 | 日频每日 | 低 | Obs |
| DGS2 | 2-Year Treasury Yield | 日度 | 同步 | 日频每日 | 低 | Obs |
| DGS10 | 10-Year Treasury Yield | 日度 | 同步 | 日频每日 | 低 | Obs |
| DGS30 | 30-Year Treasury Yield | 日度 | 同步 | 日频每日 | 低 | Obs |
| T10Y2Y | 10Y-2Y Treasury Spread | 日度 | **领先** | 日频每日（派生） | 低 | Obs（派生） |
| T10Y3M | 10Y-3M Treasury Spread | 日度 | **领先** | 日频每日（派生） | 低 | Obs（派生） |
| MORTGAGE30US | 30-Year Fixed Mortgage Rate | 周度 | 同步 | 周频每周 | 低 | Obs |
| BAA10Y | Baa Corporate Bond Spread over 10Y | 日度 | 同步/领先（风险） | 日频每日 | 低 | Obs |
| BAMLH0A0HYM2 | ICE BofA US High Yield Index OAS | 日度 | **领先**（风险） | 日频每日 | 低 | Obs |

### 3.6 房地产（Housing）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| HOUST | Housing Starts | 月度 | **领先** | 月频发布后 24h | 低 | Obs |
| PERMIT | Building Permits | 月度 | **领先** | 月频发布后 24h | 低 | Obs |
| CSUSHPISA | S&P/Case-Shiller National Home Price Index | 月度 | 同步/滞后 | 月频发布后 24h | 低 | Obs |
| MSPUS | Median Sales Price of Houses Sold | 季度 | 同步 | 季频发布后 24h | 低 | Obs |
| HSN1F | New One Family Houses Sold | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| EXHOSLUSM495S | Existing Home Sales | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| RHORUSQ156N | Homeownership Rate | 季度 | 同步 | 季频发布后 24h | 低 | Obs |

### 3.7 消费者部门（Consumer）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| PCE | Personal Consumption Expenditures | 月度 | 同步 | 月频发布后 24h | 中 | Obs |
| PCEC96 | Real PCE | 月度 | 同步 | 月频发布后 24h | 中 | Obs |
| PI | Personal Income | 月度 | 同步 | 月频发布后 24h | 中 | Obs |
| DSPIC96 | Real Disposable Personal Income | 月度 | 同步 | 月频发布后 24h | 中 | Obs |
| PSAVERT | Personal Saving Rate | 月度 | 同步/滞后 | 月频发布后 24h | 中 | Obs |
| RSAFS | Retail Sales | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| RSXFS | Retail Sales ex Auto | 月度 | 同步 | 月频发布后 24h | 低 | Obs |
| UMCSENT | Michigan Consumer Sentiment | 月度 | **领先** | 月频发布后 24h | 低 | Obs |

### 3.8 制造业与商业活动（Manufacturing & Business Activity）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| DGORDER | Durable Goods Orders | 月度 | **领先** | 月频发布后 24h | 低 | Obs |
| AMTMNO | Manufacturers' New Orders: Total Mfg | 月度 | **领先** | 月频发布后 24h | 低 | Obs |
| BUSINV | Total Business Inventories | 月度 | 滞后 | 月频发布后 24h | 低 | Obs |
| ISRATIO | Total Business: Inventories/Sales Ratio | 月度 | 领先/同步 | 月频发布后 24h | 低 | Obs |

### 3.9 对外贸易与汇率（Trade & FX）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| BOPGSTB | Trade Balance: Goods and Services | 月度 | 同步 | 月频发布后 24h | 中 | Obs |
| EXPGS | Exports of Goods and Services | 季度 | 同步 | 季频发布后 24h | 中 | Obs |
| IMPGS | Imports of Goods and Services | 季度 | 同步 | 季频发布后 24h | 中 | Obs |
| DTWEXBGS | Trade Weighted U.S. Dollar Index: Broad | 日度 | 同步 | 日频每日 | 低 | Obs |
| DEXUSEU | US Dollar / Euro | 日度 | 同步 | 日频每日 | 低 | Obs |
| DEXJPUS | Japanese Yen / US Dollar | 日度 | 同步 | 日频每日 | 低 | Obs |
| DEXCHUS | Chinese Yuan / US Dollar | 日度 | 同步 | 日频每日 | 低 | Obs |

### 3.10 金融市场与金融条件（Financial Markets & Conditions）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| SP500 | S&P 500 Index | 日度 | **领先** | 日频每日 | 低 | Obs |
| VIXCLS | CBOE Volatility Index (VIX) | 日度 | **领先**（风险） | 日频每日 | 低 | Obs |
| NFCI | Chicago Fed National Financial Conditions Index | 周度 | 同步 | 周频每周 | 低 | Obs |
| STLFSI4 | St. Louis Fed Financial Stress Index | 周度 | 同步/领先 | 周频每周 | 低 | Obs |
| DCOILWTICO | WTI Crude Oil Price | 日度 | 同步 | 日频每日 | 低 | Obs |
| GOLDAMGBD228NLBM | Gold Price (London Fix) | 日度 | 同步 | 日频每日 | 低 | Obs |

### 3.11 政府财政（Government Fiscal）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| GFDEBTN | Federal Debt: Total Public Debt | 季度 | 滞后 | 季频发布后 24h | 低 | Obs |
| GFDEGDQ188S | Federal Debt as % of GDP | 季度 | 滞后 | 季频发布后 24h | 低 | Obs |
| FYFSD | Federal Surplus or Deficit | 财年 | 滞后 | 财年发布后 24h | 低 | Obs |
| FGEXPND | Federal Government Current Expenditures | 季度 | 同步 | 季频发布后 24h | 低 | Obs |
| FGRECPT | Federal Government Current Receipts | 季度 | 同步 | 季频发布后 24h | 低 | Obs |

### 3.12 衰退与周期指标（Recession & Cycle Indicators）

| Series ID | 名称 | 频率 | 周期属性 | 采集节奏 | 修订敏感度 | domain_macro 落点 |
| --- | --- | --- | --- | --- | --- | --- |
| USREC | NBER Based Recession Indicators | 月度 | 滞后（确认） | 月频发布后 24h | 低 | Obs（0/1 标记） |
| SAHMREALTIME | Real-Time Sahm Rule Recession Indicator | 月度 | **领先**/同步 | 月频发布后 24h | 低 | Obs |
| RECPROUSM156N | Smoothed Recession Probabilities | 月度 | **领先**（概率） | 月频发布后 24h | 低 | Obs |

---

## 4. 采集方式与速率（源自 .beads/1.md §13，映射为模块语义）

| 方式 | 模块落点 |
| --- | --- |
| 官方 REST API (`api.stlouisfed.org/fred/...`) | `internal/client` provider client，覆盖 §5.1 全端点矩阵 |
| Python `fredapi` / `pandas_datareader` / R `fredr` | 仅参考实现；runtime 为 Go，使用 `pkg/fredx` |
| 网站下载 CSV/Excel/JSON | OSS raw 归档回放输入（一次性补数） |
| **ALFRED**（vintage data） | 映射为 `MacroObservation.realtime_start/realtime_end` + `vintage_at`，支撑 BR-003 no-lookahead 与修订窗口策略 |

**API 限速**（模块 §11.1 已定义）：无 key `30 req/min`、有 key `120 req/min`、突发 `<=2 req/s`，429 走指数退避重试。批量采集 + 分页 + multi-series batch 减少请求放大。

---

## 5. 数据使用注意事项（源自 .beads/1.md §14，映射为模块语义）

- **季节调整口径**：SA 版本（后缀 `S`）做趋势分析；`fred` 在 `MacroSeries.seasonal_adjustment` 字段保留该事实，下游按需在查询层区分。
- **修订与 Vintage**：GDP/PCE/就业等走最近 3 个月修订回拉窗口（§11.1）；做历史回测必须用 `realtime_start/realtime_end` 维度而非当前修订后值，避免前视偏差（BR-003）。
- **实际 vs 名义**：实际值（Real，后缀 `C96`/`C1`/Chained）与名义值区分存储，`MacroObservation` 增加 `unit` 字段承载。
- **频率对齐**：日/周/月/季混合数据统一前，高频取期末值或均值下采样（D->M、M->Q）；`fred` 保留原始频率事实，聚合在查询/物化视图层（§11.1）。
- **同比 vs 环比**：价格类同时观察 YoY 与 MoM SAAR；`fred` 原始采集不计算派生率，交由 `macro_data`/分析域。
- **发布滞后与修订日历**：每个序列的 Release 信息进 `postgres` release calendar，以 release calendar trigger 优先驱动同步（FR-016）。

---

## 6. 与 module/fred 初始指标包的差异对账（优化核心）

`spec/SPEC.md` §5.2 当前"核心指标包（初始）"共 27 个锚点。与 `.beads/1.md` 对账结果如下。

### 6.1 已覆盖（含别名对应）

| 模块 §5.2 锚点 | .beads/1.md 对应 | 备注 |
| --- | --- | --- |
| WALCL | §4 WALCL | 直接命中 |
| RRPONTSYD | §4 RRPONTSYD | 直接命中 |
| DEXUSEU | §9 DEXUSEU | 直接命中 |
| DEXJPUS | §9 DEXJPUS | 直接命中 |
| INDPRO | §1 INDPRO | 直接命中 |
| PERMIT | §6 PERMIT | 直接命中 |
| T5YIE | §3 T5YIE | 直接命中 |
| CPIAUCSL | §3 CPIAUCSL | 直接命中 |
| PCEPILFE | §3 PCEPILFE | 直接命中 |
| STLFSI4 | §10 STLFSI4 | 直接命中 |
| PCEPI | §3 PCEPI | 直接命中 |
| GDPC1 | §1 GDPC1 | 直接命中 |
| GDPPOT | §1 GDPPOT | 直接命中 |
| UNRATE | §2 UNRATE | 直接命中 |
| GDP | §1 GDP | 直接命中 |
| FEDFUNDS | §4 FEDFUNDS | 直接命中 |
| CPILFESL | §3 CPILFESL | 直接命中 |
| PAYEMS | §2 PAYEMS | 直接命中 |
| ICSA | §2 ICSA | 直接命中 |
| M2SL | §4 M2SL | 直接命中 |
| WDTGAL | ≈ §4 WTREGEN | **别名**：模块用 `WDTGAL`（TGA 广义键），`.beads` 用 `WTREGEN`；建议统一为 `WTREGEN` |
| VXVCLS | ≈ §10 VIXCLS | **别名**：模块用 `VXVCLS`，`.beads` 用 `VIXCLS`；建议统一为 `VIXCLS` |
| DGS10 | §5 DGS10 | 命中（`.beads` 以组合键 `DGS3MO/DGS2/DGS10/DGS30` 表达） |

### 6.2 模块专属扩展（不在 .beads/1.md，建议保留并标注来源）

| 模块 §5.2 锚点 | 说明 | 处置建议 |
| --- | --- | --- |
| ECBASSETSW | 欧央行的资产负债表规模（跨央行对比） | 保留，标注为"外部央行扩展"，不属 FRED 美宏观核心，纳入 `source_component` 路由（见 §9.2） |
| JPNASSETS | 日央行资产负债表规模 | 同上，保留并标注 |
| DFEDTARU | 联邦基金目标利率上限（FOMC target range upper） | 保留，FRED 有对应 `DFEDTARU` 但 `.beads` 未列；建议补入 §4 |
| NROU | 自然失业率（CBO 估算） | 保留，建议补入 §2 |

### 6.3 目录新增（.beads/1.md 有、§5.2 初始包未含的高价值序列）

全部 12 类中的其余 ~60 个序列（GDP 增速 `A191RL1Q225SBEA`、GDI、TCU、U6RATE、CIVPART、CCSA、JOLTS 三件套、CPI 派生、PPI、盈亏平衡通胀、粘性价格 CPI、M1/BOGMBASE、SOFR、完整收益率曲线 `DGS3MO/DGS2/DGS30`、T10Y3M、MORTGAGE30US、BAA10Y、BAMLH0A0HYM2、房价 `CSUSHPISA`、成屋/新房销售、PCE 族、UMCSENT、DGORDER/AMTMNO/BUSINV/ISRATIO、贸易差额/进出口、DEXCHUS、SP500、VIXCLS、NFCI、油价、金价、财政五件套、USREC/SAHMREALTIME/RECPROUSM156N 等）均应纳入 `fred` 采集范围（默认全量起点 `1990-01-01`，按 §11.1 节奏）。

> **优化结论**：将本目录（§3）设为 `fred` 采集的**权威系列清单**，§5.2 的 27 个锚点作为"首期 P0 优先级"，其余作为 P1/P2 扩展。这样既保持初始包聚焦，又把 `.beads/1.md` 的完整性纳入目标态。

---

## 7. 采集优先级分层建议（优化产出）

| 优先级 | 范围 | 说明 |
| --- | --- | --- |
| **P0（首期）** | §5.2 已定义的 27 个锚点（统一别名后） | 初始指标包，最先接入并跑通端到端 |
| **P1（核心扩展）** | 衰退/领先组合：USREC、SAHMREALTIME、T10Y2Y、T10Y3M、ICSA、UMCSENT、HOUST、PERMIT、SP500、VIXCLS、BAMLH0A0HYM2、CPI/PCE 全族、GDPC1 增速族、JOLTS | 宏观状态机与拐点预判最关键 |
| **P2（完整覆盖）** | 本目录其余全部序列 | 满足 FR-016 六域覆盖审计与 `.beads/1.md` 完整性 |

**修订密集型（强制走 3 个月回拉窗口）**：GDPC1、GDP、A191RL1Q225SBEA、GDI、PAYEMS、CPIAUCSL、CPILFESL、PCEPI、PCEPILFE、PCE、PCEC96、PI、DSPIC96、BOPGSTB、EXPGS、IMPGS。
**PIT 关键（as-of/no-lookahead 强约束）**：全部日频（利率、汇率、SP500、VIX、通胀预期、RRP、SOFR）+ 周频（ICSA、WALCL、NFCI、STLFSI4）+ release calendar 驱动的高频发布序列。

---

## 8. 对 `fred` 模块的实施影响（待确认项）

- **OPEN-CAT-1**：§5.2 别名统一——`WDTGAL→WTREGEN`、`VXVCLS→VIXCLS`，并在 client 采集清单与 `domain_macro` 锚点同步。
- **OPEN-CAT-2**：~~`DFEDTARU`、`NROU` 补入 §3 对应类别（§4 货币政策、§2 就业）~~ 已闭合：`DFEDTARU` 已补入 §3.4，`NROU` 已补入 §3.2。
- **OPEN-CAT-3**：ECBASSETSW/JPNASSETS 明确标注 `source_component` 外部路由，避免被误判为 FRED 美宏观核心（详见 §11 与 `spec/SERIES-API.md`）。
- **OPEN-CAT-4**：本目录应作为 FR-016 覆盖审计的"目标全集"——六域覆盖率从"series 是否采集"升级为"目录序列命中率"（详见 §10）。
- **OPEN-CAT-5**：派生序列（`T10Y2Y`、`T10Y3M`）不进原始采集，由 `MacroObservation` 利率原始值在计算/物化层派生，避免重复存储原始事实。

---

## 9. Endpoint → 经济领域 覆盖映射（支撑 BR-010 跨入口对账）

`fred` 全量采集必须按 `spec/SPEC.md` §5.1 全端点矩阵做跨入口交叉校验，禁止单入口口径宣称"完整"。下表把 12 个经济领域映射到驱动它们的 FRED v1 端点族，确保六域（series/release/category/tag/source/updates）对账可落到具体领域。

| FRED v1 端点族 | 主要服务的经济领域 | 说明 |
| --- | --- | --- |
| Series：`/series/observations`、`/series/vintagedates` | 全部 12 类 | 时间序列主体与 vintage/修订来源 |
| Series：`/series`、`/series/categories`、`/series/tags`、`/series/release` | 全部 12 类 | 序列元数据、归类、打标、归属 release |
| Series：`/series/search`、`/series/search/tags`、`/series/search/related_tags` | 全部 12 类（发现新增） | 增量发现与缺口补齐的输入 |
| Series：`/series/updates` | 全部 12 类 | `updates` 域对账，识别新增/修订序列 |
| Release：`/releases`、`/release`、`/releases/dates`、`/release/dates`、`/release/series`、`/release/tables` | 产出/就业/通胀/货币/利率/地产/消费/制造/贸易/财政 | release calendar 驱动同步的核心 |
| Release：`/release/sources`、`/release/tags`、`/release/related_tags` | 全部（发布侧打标） | release 侧标签/来源对账 |
| Category：`/category*` 全族 | 全部 12 类 | category 树枚举，驱动领域归类与覆盖率分母 |
| Source：`/sources`、`/source`、`/source/releases` | 全部（按发布机构） | 来源对账：BLS/BEA/Census/Treasury/Fed/ECB/BoJ 等 |
| Tags：`/tags`、`/related_tags`、`/tags/series` | 全部（主题横切） | 主题标签对账（通胀/劳动力/利率等） |

> 跨入口对账实操：覆盖率分母 = 本目录 §3 的 90 序列（FRED-native 部分；外部路由序列 `ECBASSETSW`/`JPNASSETS` 不计入 FRED 分母，见 §11）；分子 = 实际已采集且通过校验的序列。BR-010 要求 series/release/category/tag/source/updates 六域分别计数，任一域未达阈值不得宣称"完整"。

## 10. FR-016 覆盖审计目标表（可度量）

本表把目录转为 FR-016 审计可直接度量的目标，配合 `GetCatalogCoverage`（§7 API）输出覆盖率、缺口分片与重采任务。

| 经济领域 | 序列数 | P0 | P1 | P2 | 修订窗口 | 默认全量起点 | 采集节奏 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 产出与增长 | 8 | GDPC1, GDP, GDPPOT, INDPRO | A191RL1Q225SBEA, GDI | TCU, OPHNFB | 高（GDP 族） | 1990-01-01 | 月/季频发布后 24h |
| 2 就业 | 13 | PAYEMS, UNRATE, ICSA, NROU | JTSJOL/JTSQUR/JTSHIR, U6RATE, CIVPART, EMRATIO, CCSA, CES0500000003, AWHAETP | — | 高（PAYEMS） | 1990-01-01 | 月频发布后 24h + 周频 ICSA |
| 3 通胀 | 10 | CPIAUCSL, CPILFESL, PCEPI, PCEPILFE, T5YIE | T10YIE, T5YIFR, CORESTICKM159SFRBATL, MICH | PPIACO | 中（CPI/PCE 族） | 1990-01-01 | 月频发布后 24h + 日频预期 |
| 4 货币与供给 | 10 | FEDFUNDS, WALCL, M2SL, RRPONTSYD, WTREGEN, DFEDTARU | DFF, M1SL, BOGMBASE, SOFR | — | 低 | 1990-01-01 | 月/周/日频 |
| 5 利率与信用 | 9(+2 派生) | DGS10 | DGS3MO, DGS2, DGS30, T10Y2Y(派), T10Y3M(派), MORTGAGE30US, BAA10Y, BAMLH0A0HYM2 | — | 低 | 1990-01-01 | 日频 + 周频 |
| 6 房地产 | 7 | PERMIT, HOUST | CSUSHPISA, HSN1F, EXHOSLUSM495S, MSPUS, RHORUSQ156N | — | 低 | 1990-01-01 | 月/季频 |
| 7 消费者 | 8 | RSAFS | PCE, PCEC96, PI, DSPIC96, PSAVERT, RSXFS, UMCSENT | — | 中（PCE/PI 族） | 1990-01-01 | 月频 |
| 8 制造业 | 4 | — | DGORDER, AMTMNO, BUSINV, ISRATIO | — | 低 | 1990-01-01 | 月频 |
| 9 贸易与汇率 | 7 | DEXUSEU, DEXJPUS | BOPGSTB, EXPGS, IMPGS, DTWEXBGS, DEXCHUS | — | 中（贸易） | 1990-01-01 | 日频 + 月/季频 |
| 10 金融市场 | 6 | VIXCLS, STLFSI4 | SP500, NFCI, DCOILWTICO, GOLDAMGBD228NLBM | — | 低 | 1990-01-01 | 日/周频 |
| 11 政府财政 | 5 | — | GFDEBTN, GFDEGDQ188S, FYFSD, FGEXPND, FGRECPT | — | 低 | 1990-01-01 | 季/财年频 |
| 12 衰退与周期 | 3 | — | USREC, SAHMREALTIME, RECPROUSM156N | — | 低 | 1990-01-01 | 月频 |
| **合计** | **90** | **27** | **60** | **3** | — | — | — |

> 说明：P0 与 §5.2 初始包一致（27 个，统一别名后）；P1 为衰退/领先核心组合与关键扩展；P2 为其余完整覆盖序列。派生序列（T10Y2Y/T10Y3M）由利率原始值计算层派生，不计入原始采集但计入审计覆盖率分母（视为 P1）。审计阈值建议：P0=100%、P1≥95%、P2≥90% 方允许进入 completed。

---

## 11. 外部路由实施细节（source_component，闭合 OPEN-CAT-3）

`ECBASSETSW`/`JPNASSETS` 等序列的真实权威来源不是 FRED（欧/日央行），fred 经 FRED 端点取得或仅登记指针时，必须标记 `source_component` 并交由上游数据域路由，避免被误判为"FRED 美宏观核心"、虚增 FRED 完整性。

### 11.1 路由判定规则

| 路由类型 | 判定 | `provider` | `source_component` | fred 角色 |
| --- | --- | --- | --- | --- |
| **FRED-native** | 真实权威 = FRED（GDP/CPI/PAYEMS/利率/房价等） | `FRED` | `FRED` | 系统记录：承担 revision/vintage（`realtime_start/realtime_end`）+ no-lookahead |
| **外部路由** | 真实权威 ≠ FRED（ECB/BoJ 等） | `FRED`（检索渠道） | `<authority>` | 非系统记录：仅取数/登记，交上游数据域路由 |

```
route(series) = if series.authority == "FRED" then NATIVE else EXTERNAL(series.authority)
```

### 11.2 受影响的目录序列

| 模块锚点 | 真实权威 | 目录归类 | 路由 |
| --- | --- | --- | --- |
| ECBASSETSW | 欧洲央行 ECB | §4 货币政策（扩展） | EXTERNAL(ECB) |
| JPNASSETS | 日本央行 BoJ | §4 货币政策（扩展） | EXTERNAL(BoJ) |

**非外部（澄清，避免误标）**：`DFEDTARU`（FOMC 目标利率上限，FRED 发布）、`NROU`（CBO 自然失业率，经 FRED 发布）属 FRED-native，不外部路由，仅补入对应类别（§6.2、OPEN-CAT-2）。

### 11.3 domain_macro 落点

- 复用 `MacroSeries.source` 表达真实权威（`source_component` 语义）；`provider` 固定为检索渠道 `FRED`。即 `source` 与 `provider` 解耦：native 序列 `source==provider==FRED`，外部路由 `provider=FRED, source=ECB|BoJ`。
- `MacroObservation` 透传 `source` 字段，供 `macro_data`/下游按权威路由；不影响 `available_at` 与 no-lookahead（仍按 FRED 实际发布时间）。
- 外部路由序列**不在** `MacroRevision` 上做 FRED vintage 断言；若权威源自带版本维度，以该源 schema 记录并标注 `source_component`，不混入 ALFRED `realtime_start/realtime_end` 流。

### 11.4 采集与归一化差异

| 阶段 | FRED-native | 外部路由 |
| --- | --- | --- |
| 采集 | FRED v1 端点（§5.1） | 若 FRED 再分发则同端点取数；否则由上游数据域负责，fred 仅登记 `MacroSeries` 指针 |
| 修订/版本 | `realtime_start/realtime_end` + 最近 3 个月回拉 | 不声称 FRED vintage，仅记 retrieval 时刻 |
| raw-first | OSS（含 provider/endpoint hash） | 同左，endpoint 标注 `external-source` 透传 |
| 覆盖审计 | 计入 FR-016 分母 | **排除出 FRED 分母**，单列「外部路由清单」 |

### 11.5 查询 / API 语义

- `GetSeries` 返回 `source_component`；下游据其值决定消费路径（native 直接消费，外部路由走对应上游域）。
- `GetCatalogCoverage` 覆盖率分母仅含 FRED-native 序列；外部路由序列在响应中单列 `external_routed` 计数——既不静默丢弃，也不虚增 FRED 完整性。

### 11.6 实施清单（闭合 OPEN-CAT-3）

- [ ] `internal/domain` 增加 `source_component` 路由判定（基于 series authority 表）。
- [ ] 文档化 `MacroSeries.source`（真实权威）与 `provider`（检索渠道）的解耦语义。
- [ ] client 采集清单将 ECBASSETSW/JPNASSETS 标 `EXTERNAL`，不进入 P0/P1/P2 的 FRED 完整性审计。
- [ ] `GetCatalogCoverage` 增加 `external_routed` 维度。
- [ ] 边界 gate 禁止把外部路由序列误写入"FRED 完整采集"断言。

---

> 本目录为 `.beads/1.md` 的深度分析结果，不改变 `spec/SPEC.md` 既有的 23 节结构与 FR/BR/AC/TC 编号；仅作为 §5 系列范围的权威扩展引用。所有 secret 仍只引用 `sre/secrets/env/dev.md` 键名，不复制值。
