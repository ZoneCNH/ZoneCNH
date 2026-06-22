# Binance Data Lifecycle Discussion Draft

- Status: Discussion Draft
- Doc-Version: v0.1.0
- Last-Updated: 2026-06-23
- Scope: `module/binance/`
- Confidence: MED

## 1. 非合同声明

[COMPUTED][HIGH] 本文件只记录数据生命周期方向的候选 FR，不是当前 `module/binance/SPEC.md` 合同，不改变 v2.2.3 的 FR-001 到 FR-011，也不改变当前 4x4 product line/event type 命名矩阵。

[INFERRED][HIGH] 本文件中的任何候选项进入实现前，都必须经过正式 spec bump、追溯矩阵更新、验收标准更新、任务拆分和迁移说明。未完成这些步骤前，不得把本文件当作 runtime、API、topic、subject 或发布承诺。

## 2. 候选 FR 与 issue 映射

| Candidate FR | 关联 issue | 候选方向 | 合同状态 |
| --- | --- | --- | --- |
| FR-012 | #880 | Symbol discovery：从交易所元数据发现 symbol、product line、可交易状态和过滤规则。 | Draft only |
| FR-013 | #881 | WebSocket connection policy：连接分组、限流、重连、订阅恢复和抖动控制。 | Draft only |
| FR-014 | #882 | Bar interval subscription set：定义 kline/bar interval 的订阅集合和变更策略。 | Draft only |
| FR-015 | #883 | Depth snapshot tier：按 product line 和 symbol 规模选择 depth snapshot 级别。 | Draft only |
| FR-016 | #884 | Historical backfill on cold start：冷启动时补齐必要历史窗口。 | Draft only |
| FR-017 | #885 | Gap detection and fill：检测行情空洞并触发补洞流程。 | Draft only |
| FR-018 | #886 | Backfill throttle and priority：限制补数速率并定义前后台优先级。 | Draft only |
| FR-019 | #887 | Backfill idempotency key strategy：为补数任务定义幂等键和重复写入策略。 | Draft only |
| FR-020 | #888 | Funding rate / mark price stream：候选新增资金费率与标记价格类行情。 | Draft only, requires spec bump |
| FR-021 | #889 | Daily reconciliation job：按日对齐采集状态、存储完整性和缺口摘要。 | Draft only |
| FR-022 | #890 | Cold data rehydration：从归档或历史源重建冷数据窗口。 | Draft only |
| FR-023 | #891 | Backfill progress API：暴露补数任务状态、进度和错误摘要。 | Draft only |
| FR-024 | #892 | Symbol subscription hot reload：不重启进程的 symbol 订阅刷新。 | Draft only |

## 3. #888 的命名影响

[COMPUTED][HIGH] 当前有效 event type 只有 `tick`、`trade`、`bar`、`depth` 四个。

[INFERRED][HIGH] #888 若纳入当前合同，至少会引入两个新增 event type 候选，例如 funding rate 和 mark price，使 event type 从 4 扩展到 6。该变化会把 NATS subject 与 Kafka topic 的矩阵从 4x4 改为 4x6，并影响 `SPEC.md`、`STANDARD.md`、`NAMING.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、client/server tasks、runtime mapping 和检查脚本。

[COMPUTED][HIGH] 因此 #888 不能作为文档补丁直接合入当前命名合同，必须先走正式 spec bump。

## 4. 进入合同前的最低门槛

1. [INFERRED][HIGH] 为每个候选 FR 写入根 spec，补齐 BR/NFR/AC/TC。
2. [INFERRED][HIGH] 更新 traceability，使候选 FR 能追溯到验收和测试。
3. [INFERRED][HIGH] 更新 naming 与 standard，明确是否改变 subject/topic 矩阵。
4. [INFERRED][HIGH] 拆分 client/server/runtime 任务，避免 Discussion Draft 直接驱动实现。
5. [INFERRED][HIGH] 写入迁移说明和兼容性策略，尤其是 topic/subject 扩展场景。

[RULES I BROKE]：无
