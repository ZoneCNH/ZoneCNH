# Archived Server Tasks（v2.0.0 前架构）

本目录保存 v2.0.0 重构前的废弃 task 文件，**不得作为新实现输入**。仅供历史追溯。

| Archived | 替代 | 原架构 → 新架构 |
|---------|------|----------------|
| `TASK-BINANCE-SERVER-001-grpc-ingest-server.md` | `TASK-BINANCE-SERVER-010-natsx-consumer.md` | gRPC ingest server → natsx durable consumer |
| `TASK-BINANCE-SERVER-004-ingest-ack.md` | 删除（无替代） | gRPC ACK → natsx ManualAck |
| `TASK-BINANCE-SERVER-005-downstream-dispatch.md` | `TASK-BINANCE-SERVER-012/013/014/015/016` | DownstreamDispatchPort → 7 infra adapters + Gin |

参考决策：`module/binance/SPEC.md` Appendix A ADR + `module/binance/CHANGELOG.md` v2.0.0 条目。
