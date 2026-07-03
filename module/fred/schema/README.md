# module/fred schema 索引

- Last-Updated: 2026-07-03
- Runtime-Repo: `/home/workspace/fred`

## 契约范围

| 契约 | 用途 | 版本策略 |
| --- | --- | --- |
| NATS ingest envelope | `fred-client` → `fred-server` handoff | `fred.ingest.v{major}` |
| NATS control command | reload/backfill/pause/resume/heartbeat | `fred.control.v{major}` |
| Kafka business event | 下游 durable event | `fred.macro.{event}.v{major}` |
| Query/Admin API | series/query/job/admin 接口 | `/api/v{major}/...` |
| Postgres schema | catalog/checkpoint/idempotency | migration version + checksum |
| TDengine schema | observation/vintage 时序表 | schema tag + retention policy |
| ClickHouse schema | 分析读模型 | schema version + rebuild marker |

## 约束

1. 任何契约升级必须带版本号，不允许 silent break。
2. 对外契约禁止引用 `fred/internal/*` 私有类型。
3. Schema 变更必须在 `matrix/TRACEABILITY.md` 关联 FR/AC/TC。
4. 运行时 schema 文件应放在 `/home/workspace/fred/internal/cs` 或 `migrations/`，本目录只保留索引说明。
