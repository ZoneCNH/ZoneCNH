# uk_cb 需求追溯矩阵

Last-Updated: 2026-07-04  
Source: [spec/SPEC.md](../spec/SPEC.md) | Goal: GOAL-UK-CB-001 | Status: Planned

## Goal 到需求

| Goal / SC | FR | BR | AC |
| --------- | -- | -- | -- |
| G-SC-001 双服务独立 | FR-001, FR-010 | BR-001 | AC-001 |
| G-SC-002 子模块独立 C/S | FR-003, FR-008 | BR-002 | AC-005 |
| G-SC-003 配置不泄密 | FR-002 | BR-001 | AC-002 |
| G-SC-004 领域归一化 | FR-005 | BR-001, BR-003 | AC-003 |
| G-SC-005 完整持久化 | FR-004, FR-006 | BR-002, BR-004, BR-005 | AC-004 |
| G-SC-006 同步与回补 | FR-003, FR-008, FR-009 | BR-002, BR-005 | AC-005 |
| G-SC-007 下游稳定契约 | FR-007 | BR-001, BR-004 | AC-006 |

## FR 追溯

| FR | 需求摘要 | AC | 状态 |
| -- | -------- | -- | ---- |
| FR-001 | client/server 独立服务 | AC-001 | Planned |
| FR-002 | 配置映射与 secret 边界 | AC-002 | Planned |
| FR-003 | BoE 采集清单覆盖 | AC-005 | Planned |
| FR-004 | raw 优先归档 | AC-004 | Planned |
| FR-005 | `domain_macro` 归一化 | AC-003 | Planned |
| FR-006 | 多存储写入 + Kafka 发布 | AC-004 | Planned |
| FR-007 | 查询与 as-of/vintage | AC-006 | Planned |
| FR-008 | 频率/同步周期执行 | AC-005 | Planned |
| FR-009 | revision 与质量标签 | AC-005 | Planned |
| FR-010 | 边界门禁 | AC-001 | Planned |

## AC 注册

| AC | 验收摘要 | 覆盖需求 | 状态 |
| --- | --- | --- | --- |
| AC-001 | 双服务边界合规 | FR-001, FR-010 | Planned |
| AC-002 | 配置与 secret 合规 | FR-002 | Planned |
| AC-003 | 领域语义与 no-lookahead 合规 | FR-005 | Planned |
| AC-004 | 多存储 + 事件链路闭合 | FR-004, FR-006 | Planned |
| AC-005 | 采集频率、同步周期、回补窗口达标 | FR-003, FR-008, FR-009 | Planned |
| AC-006 | 下游查询契约稳定 | FR-007 | Planned |

