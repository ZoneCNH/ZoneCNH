# uk_cb 实施计划（生产级）

## 阶段拆分

| 阶段 | 目标 | 关键交付 |
| ---- | ---- | ---- |
| S1 规格冻结 | 冻结目标与边界 | goal/spec/matrix |
| S2 client 实现 | 完成采集、归档、NATS 发布 | `uk-cb-client` |
| S3 server 实现 | 完成消费、持久化、查询、Kafka 发布 | `uk-cb-server` |
| S4 数据质量 | revision、coverage、freshness、回放审计 | 质量报告 |
| S5 发布就绪 | 边界门禁、CI、证据归档 | release 候选 |

## 里程碑

1. M1：采集清单与调度策略落地（FR-003/008）。
2. M2：七类介质写入链路闭合（FR-004/006）。
3. M3：查询、回补、修订闭合（FR-007/009）。
4. M4：生产门禁通过（FR-010 + AC 全绿）。

