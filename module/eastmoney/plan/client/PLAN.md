# eastmoney-client 实施计划

- Last-Updated: 2026-07-04
- Parent Plan: [../PLAN.md](../PLAN.md)
- Spec: [../../spec/client/SPEC.md](../../spec/client/SPEC.md)

## 阶段拆分

1. **P1 采集骨架**：调度器、配置映射、错误分类骨架。
2. **P2 数据拉取**：CMD/GMD/IED 三路采集，分页、限流、重试与回拉。
3. **P3 raw-first**：provider 响应先入 OSS，再做标准化转换。
4. **P4 语义映射与发布**：DTO -> `domain_macro`，发布 NATS ingest/control。
5. **P5 观测与验收**：覆盖率、采集时效、修订回拉与一致性审计。

## 完成判定

- `matrix/client/TRACEABILITY.md` 覆盖项可追溯。
- C-TC-001~C-TC-005 全部通过。
- 不输出 provider DTO 与明文 secret。
