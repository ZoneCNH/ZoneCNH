# uk_cb client SPEC

- Parent: [../SPEC.md](../SPEC.md)
- Service: `uk-cb-client`
- Status: Draft

## 职责

1. 采集 BoE 数据集并执行分页、限流、退避。
2. 先写 OSS raw，再构建 ingest envelope。
3. 将归一化事件发布到 NATS ingest subject。
4. 维护采集游标与采集质量指标。

## 输入/输出

| 类型 | 说明 |
| ---- | ---- |
| 输入 | 调度任务、发布日历触发、回补任务参数 |
| 输出 | OSS raw、NATS ingest envelope、采集指标 |

## 禁止事项

- 不直写业务数据库。
- 不发布 Kafka durable event。
- 不暴露 provider DTO 作为跨模块契约。

