# module/eastmoney Tasks 入口

- Last-Updated: 2026-07-04
- 目标：把 root/client/server 任务拆分为可执行原子单元

## 命名规范

- `TASK-EASTMONEY-ROOT-XXX.md`
- `TASK-EASTMONEY-CLIENT-XXX.md`
- `TASK-EASTMONEY-SERVER-XXX.md`

## 子目录

- `client/`：采集、归一化、NATS handoff 任务
- `server/`：消费、持久化、Kafka/API 任务
