# fred-client 实施计划

- Last-Updated: 2026-07-03
- Parent Plan: [../PLAN.md](../PLAN.md)
- Spec: [../../spec/client/SPEC.md](../../spec/client/SPEC.md)

## 阶段拆分

1. **P1 采集骨架**：collector 调度、配置映射、错误分类骨架。
2. **P2 数据拉取能力**：series/observations/releases/vintages/categories/tags/sources/updates 拉取 + 分页 + 重试。
3. **P3 归一化与 raw-first**：DTO → `domain_macro`、OSS raw 归档。
4. **P4 NATS 发布**：ingest envelope schema + durable publish + retry。
5. **P5 观测与验收**：指标/日志/trace、覆盖率快照、契约测试与边界门禁。

## 关键命令

```bash
cd /home/workspace/fred
go test ./internal/client/... -count=1
go test ./internal/domain/... -count=1
go test ./pkg/fredx/... -count=1
go test ./internal/client/... -run FullCoverageSnapshot -count=1
```

## 完成判定

- `matrix/client/TRACEABILITY.md` 覆盖项可追溯。
- TC-C001~TC-C005 全部通过。
- 不输出 provider DTO 与明文 secret。
