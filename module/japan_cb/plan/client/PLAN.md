# japan-cb-client 实施计划

- Last-Updated: 2026-07-04
- Parent Plan: [../PLAN.md](../PLAN.md)
- Spec: [../../spec/client/SPEC.md](../../spec/client/SPEC.md)

## 阶段拆分

1. P1 采集骨架：配置映射、调度器、错误分类。
2. P2 数据拉取：dataset/series 分片拉取、分页、限流、重试。
3. P3 raw-first：OSS 归档 + digest + envelope 组装。
4. P4 发布：NATS ingest 发布与重试退避。
5. P5 验收：覆盖率快照、契约测试、边界扫描。

