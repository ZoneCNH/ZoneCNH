# PROMPT-MD-001

- Task：[../tasks/](../tasks/)
- Trace：[../TRACEABILITY.md](../TRACEABILITY.md)
- Spec：[../SPEC.md](../SPEC.md)

## 任务

实现 market_data 接收侧：DownstreamDispatchPort、幂等判定、ordering 校验、质量门禁、Observability。

## 关联需求

FR-MD-001~008（dispatch-port/canonical-input/idempotency/ordering/quality-gate/retry-classification/batch/observability）。

## 要点

1. DownstreamDispatchPort 接口定义
2. AcceptedMarketEvent 12 字段输入契约
3. DispatchAck/DispatchReject/DispatchFailure 三级 outcome
4. 8 种 reject reason + binance-native 映射
5. 跨模块字段命名对齐（contracts JSON / domain_market Go / market_data doc）
