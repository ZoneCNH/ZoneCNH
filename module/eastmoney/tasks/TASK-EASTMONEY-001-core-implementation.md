# TASK-EASTMONEY-001 Core Implementation

## Objective

实现 eastmoney 宏观数据 C/S 模块：采集、`domain_macro` 归一化、NATS->server->多存储->Kafka 主链闭环。

## Covers

`module/eastmoney/spec/SPEC.md` 中 FR-001~FR-017、BR-001~BR-007、AC-001~AC-008。

## Acceptance Criteria

1. C/S 边界清晰，client/server 独立部署。
2. 七类持久化职责可追溯。
3. 20 轮一致性检查证据可复现。
