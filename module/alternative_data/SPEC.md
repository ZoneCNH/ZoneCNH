# alternative_data 规格

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-06-30
- Layer: 数据域 · 另类数据（独立进程聚合层）
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/alternative_data](https://github.com/ZoneCNH/alternative_data)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/contracts`, `module/pe_data`, `module/market_data`

> 占位规格（Draft）。alternative_data 是链上数据、社交情绪、新闻 NLP 的独立进程聚合层，与 market_data/macro_data 同属数据域聚合层。架构类型为独立进程（非 C/S）。完整 23 节规格待进入 Spec→Code 管线时补齐。

---

## 1. 摘要

`module/alternative_data` 是另类数据聚合层（独立进程），整合链上数据（on-chain）、社交情绪（social sentiment）、新闻 NLP 等非结构化数据源，归一化为统一的信号/特征输入，供下游 factor_engine / signal_factory 消费。

```text
链上数据源 / 社交情绪 / 新闻 NLP
  ↓
module/alternative_data (独立进程) → 归一化聚合
  ↓
factor_engine / signal_factory (直接消费)
```

---

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 另类数据源采集协调、非结构化→结构化归一化、数据时效性与质量门禁、聚合层分发 |
| Depends on | `module/contracts`（`AlternativeDataProvider` 接口 + DTO）、基座层、`module/pe_data`（PE 另类数据子模块） |
| Consumed by | `module/factor_engine`（另类因子）、`module/signal_factory`（情绪/链上信号）、`module/factor_eval` |
| Excludes | 具体数据源爬取实现（→ 子模块/采集器）、信号生成（→ signal_factory）、数据持久化（聚合层只做分发协调） |

---

## 3. 数据域定位

alternative_data 与 market_data / macro_data 并列，构成数据域三大聚合层：

| 聚合层 | 数据类型 | 子模块/采集器 |
| --- | --- | --- |
| market_data | 行情数据（tick/trade/bar/depth） | binance/okx/hyperliquid/coinglass |
| macro_data | 宏观经济数据 | fred/treasury |
| alternative_data | 另类数据（链上/情绪/新闻） | pe_data 等 |

---

## 4. 功能需求

待补充。

---

## 5. 行为约束

待补充。

---

## 6. 非功能需求

待补充。

---

## 7. Acceptance Criteria Registry

待补充。

---

## 8. 追溯与测试门禁

待补充。

---

## 9. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-30 | v0.1.0 | 初始占位规格（Draft），仅 §1-§3 与 §21 待解决问题落地 | ZoneCNH |

---

## 10. 错误处理

待补充。

---

## 11. 边界情况

待补充。

---

## 12. 目录结构

待补充。

---

## 13. 依赖

| 依赖 | 用途 |
| --- | --- |
| （待补充） | |

---

## 14. 测试

待补充。

---

## 15. 性能预算

待补充。

---

## 16. 可观测性

待补充。

---

## 17. 安全

待补充。

---

## 18. CI 门禁

待补充。

---

## 19. 升级兼容性

待补充。

---

## 20. 发布 DoD

待补充。

---

## 21. 待解决问题

- [ ] alternative_data 与 pe_data 的边界（pe_data 是子模块还是独立采集器）？
- [ ] 链上数据源清单（Glassnode/Etherscan/Chainlink 等）的优先级？
- [ ] 完整 23 节规格进入 Spec→Code 管线的优先级？

---

## 22. 运行时边界

待补充。

---

## 23. 变更历史

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-30 | v0.1.0 | 初始占位规格（Draft），仅 §1-§3 与 §21 待解决问题落地 | ZoneCNH |
