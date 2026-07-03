# eastmoney 实施计划

Last-Updated: 2026-07-04

## 阶段拆分

| 阶段 | 目标 | 产出 |
| --- | --- | --- |
| P1 规格冻结 | 固化 goal/spec/matrix/gate/schema | 文档基线 v0.1.0 |
| P2 client 落地 | 完成采集调度、OSS first、NATS 发布 | `eastmoney-client` MVP |
| P3 server 落地 | 完成校验、多存储写入、Kafka 发布、查询 API | `eastmoney-server` MVP |
| P4 同步与回补 | 历史全量、增量同步、修订回拉和审计报告 | 数据闭环 |
| P5 生产就绪 | 观测、压测、故障演练、发布门禁 | release candidate |

## 同步策略执行基线

1. 历史全量：默认 `2005-01-01` 起。
2. 增量同步：`last_success_cursor -> now`。
3. 修订回拉：日频 3 个月、月频 18 个月、季频 12 季。
4. 发布触发优先：发布日历触发 > 定时轮询兜底。

## 模块分批上线顺序

1. 批次 A（CMD 核心）：GDP/CPI/PPI/M2/社融/PMI/失业率。
2. 批次 B（CMD 扩展 + IED）：产业链高频、地产、财政、区域分层。
3. 批次 C（GMD）：美欧日英德澳核心指标与利率决议。
4. 批次 D（增强）：政策事件、国际联动、情绪与人口结构。

## 20 轮深度检查执行

1. 覆盖检查：CMD/GMD/IED 与核心指标包逐项核对。
2. 频率检查：频率、同步周期、回拉窗口逐项核对。
3. 边界检查：NATS/Kafka、OSS first、no-lookahead、幂等规则核对。
4. 证据留存：检查结果写入 `evidence/2026-07-04/review/DEEP-ANALYSIS-20-PASS.md`。
