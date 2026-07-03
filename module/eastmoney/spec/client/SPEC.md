# eastmoney client 子模块规格

- Status: Draft
- Spec-Version: v0.1.0
- Last-Updated: 2026-07-04

## 职责

`eastmoney-client` 负责采集 Eastmoney 宏观数据、归档 OSS raw、转换 `domain_macro` 语义并发布 NATS ingest envelope。

## 关键需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| C-FR-001 | 调度触发 | 按日/周/月/季策略执行采集任务。 |
| C-FR-002 | 响应返回 | 先落 OSS raw，再进入规范化。 |
| C-FR-003 | 规范化完成 | 输出 `domain_macro` 模型并携带三时间 + vintage。 |
| C-FR-004 | handoff 发布 | 仅发布到 NATS ingest/control subject。 |
| C-FR-005 | 限流触发 | 429/5xx 走指数退避 + jitter。 |

## 边界

禁止写业务数据库、禁止发布 Kafka durable event、禁止暴露 provider 私有 DTO 给下游。
