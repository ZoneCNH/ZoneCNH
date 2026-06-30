# Archived Client Tasks（v2.0.0 前架构）

本目录保存 v2.0.0 重构前的废弃 task 文件，**不得作为新实现输入**。仅供历史追溯。

| Archived | 替代 | 原架构 → 新架构 |
|---------|------|----------------|
| `TASK-BINANCE-CLIENT-008-grpc-sender.md` | `TASK-BINANCE-CLIENT-014-natsx-publisher.md` | gRPC bidi stream → natsx JetStream Publish |
| `TASK-BINANCE-CLIENT-009-spool-checkpoint.md` | 删除（无替代） | SQLite spool + checkpoint → JetStream durable consumer |

参考决策：`module/binance/spec/SPEC.md` Appendix A ADR + `module/binance/CHANGELOG.md` v2.0.0 条目。
