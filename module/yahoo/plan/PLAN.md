# yahoo 实施计划（生产级）

## 阶段拆分

| 阶段 | 目标 | 关键交付 |
| ---- | ---- | ---- |
| S1 规格冻结 | 冻结目标与边界 | goal/spec/matrix |
| S2 client 实现 | 完成采集、归档、NATS 发布 | `yahoo-client` |
| S3 server 实现 | 完成消费、持久化、查询、Kafka 发布 | `yahoo-server` |
| S4 数据质量 | revision、coverage、freshness、回放审计 | 质量报告 |
| S5 发布就绪 | 边界门禁、CI、证据归档 | release 候选 |

## 里程碑

1. M1：采集清单、频率、同步周期、历史起点落地（FR-003/FR-012）。
2. M2：七类介质链路闭合（FR-004~FR-011）。
3. M3：查询契约与 no-lookahead 闭合（FR-005/FR-013）。
4. M4：生产门禁通过（FR-014 + AC 全绿）。

## 任务分解（最小闭环）

| 任务 | 目标 | 对应需求 |
| --- | --- | --- |
| TASK-YAHOO-001 | C/S 启动与配置映射 | FR-001, FR-002 |
| TASK-YAHOO-CLIENT-001 | 采集清单与调度执行 | FR-003, FR-012 |
| TASK-YAHOO-CLIENT-002 | 归一化与 NATS 发布 | FR-005, FR-010 |
| TASK-YAHOO-SERVER-001 | 多存储写入与幂等 | FR-004, FR-006, FR-007, FR-008, FR-011 |
| TASK-YAHOO-SERVER-002 | Kafka 事件与查询 API | FR-009, FR-013 |
| TASK-YAHOO-003 | 边界门禁与验证闭环 | FR-014 |

