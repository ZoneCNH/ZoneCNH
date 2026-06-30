# PROMPT-NATSX-001

- Task：[../tasks/](../tasks/)
- Trace：[../TRACEABILITY.md](../TRACEABILITY.md)
- Spec：[../SPEC.md](../SPEC.md)

## 任务

实现 natsx NATS 客户端：Core NATS Publish/Subscribe/Request + JetStream + Health + SubjectBuilder。

## 要点

1. Core NATS at-most-once 语义
2. JetStream at-least-once + Ack/Nack
3. SubjectBuilder domain.resource.action.v{version}
4. NatsMessageEnvelope traceId/messageId/schemaVersion
5. 自动重连指数退避
