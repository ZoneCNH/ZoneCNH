# TASK-EASTMONEY-CLIENT-001 CMD/GMD/IED Collector

## Scope

- CMD/GMD/IED 三层采集任务编排
- 频率调度、发布日历触发、修订回拉
- OSS raw-first 与限流退避

## Non-scope

- server 持久化写入
- Kafka durable 事件发布
