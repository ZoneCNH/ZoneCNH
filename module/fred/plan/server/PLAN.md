# fred-server 实施计划

- Last-Updated: 2026-07-03
- Parent Plan: [../PLAN.md](../PLAN.md)
- Spec: [../../spec/server/SPEC.md](../../spec/server/SPEC.md)

## 阶段拆分

1. **P1 消费骨架**：NATS consumer、schema 校验、错误处理框架。
2. **P2 持久化主链**：postgres checkpoint/ledger + category/tag/source 图谱 + taos observation 写入。
3. **P3 派生层与缓存**：Redis 热缓存、ClickHouse 读模型。
4. **P4 事件输出**：Kafka durable events + outbox/idempotency。
5. **P5 查询与管理接口**：Query/Admin API、coverage audit API、鉴权、审计、no-lookahead 查询。
6. **P6 集成闭合**：端到端回放、失败注入、全量覆盖审计、边界门禁。

## 关键命令

```bash
cd /home/workspace/fred
go test ./internal/server/... -count=1
go test ./internal/integration/... -run PersistPipeline -count=1
go test ./internal/integration/... -run NATSIngestHandoff -count=1
go test ./internal/integration/... -run FullCoverageAudit -count=1
```

## 完成判定

- `matrix/server/TRACEABILITY.md` 覆盖项可追溯。
- TC-S001~TC-S006 全部通过。
- NATS/Kafka 分层、checkpoint 顺序和 no-lookahead 验证通过。
