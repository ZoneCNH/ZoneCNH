# PROMPT-KAFKAX-001

- Task：[../tasks/](../tasks/)
- Trace：[../TRACEABILITY.md](../TRACEABILITY.md)
- Spec：[../SPEC.md](../SPEC.md)

## 任务

实现 kafkax Kafka 客户端封装：Producer/Consumer 接口、Typed Options、错误映射、health check。

## 要点

1. Typed Options + kernel 生命周期集成
2. Producer/Consumer context 尊重
3. SASL/TLS 配置可表达
4. 指标低基数标签
