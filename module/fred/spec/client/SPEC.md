# fred-client SPEC

- Status: Planned
- Spec-Version: v1.0.0
- Last-Updated: 2026-07-03
- Parent: [../SPEC.md](../SPEC.md)
- Plan: [../../plan/client/PLAN.md](../../plan/client/PLAN.md)

## 1. Goal

`fred-client` 负责从 FRED 采集宏观数据并发布标准化 ingest envelope，为 `fred-server` 提供可重放、可审计的输入流。

## 2. Scope

1. FRED API 拉取：series、observations、releases、vintages、categories、tags、sources、updates（覆盖 root SPEC §5.1 全端点矩阵）。
2. 分页、限流、重试、错误分类。
3. DTO → `domain_macro` 归一化。
4. raw-first：原始响应写入 `oss`。
5. 发布 NATS ingest envelope。

## 3. Non-Goals

- 不写 `taos/postgres/Redis/clickhouse`。
- 不发布 Kafka downstream business events。
- 不提供对外查询 API。

## 4. Functional Requirements

| ID      | WHEN                       | THEN                                                                                 |
| ------- | -------------------------- | ------------------------------------------------------------------------------------ |
| FR-C001 | WHEN 周期任务触发采集      | THEN 支持 root SPEC §5.1 定义的 FRED v1 全端点矩阵与核心指标包拉取、分页和批量采集 |
| FR-C002 | WHEN provider 限流或抖动   | THEN 使用共享韧性组件执行退避重试                                                    |
| FR-C003 | WHEN 收到 provider payload | THEN 先写 `oss` raw，再进入归一化流程                                                |
| FR-C004 | WHEN 归一化完成            | THEN 生成 `domain_macro` 语义 envelope                                               |
| FR-C005 | WHEN ingest envelope 就绪  | THEN 发布到 NATS durable subject，并附 schema version                                |
| FR-C006 | WHEN 发布失败              | THEN 保留重试状态并记录可重放凭据                                                    |
| FR-C007 | WHEN 缺少配置键            | THEN fail-fast，不降级为静默默认值                                                   |
| FR-C008 | WHEN 输出日志与指标        | THEN 必带 `job_id/series_id/request_id` 关联字段                                     |
| FR-C009 | WHEN 执行 full sync        | THEN 以默认 `1990-01-01` 起点执行分片回补，输出采集覆盖快照（series/release/category/tag/source/updates）并上报缺口分片，同时保留 `realtime_start/realtime_end` 版本维度    |

## 5. Business Rules

| ID      | 规则                                                              |
| ------- | ----------------------------------------------------------------- |
| BR-C001 | 不输出 provider DTO 作为跨模块契约                                |
| BR-C002 | payload hash 参与幂等键计算                                       |
| BR-C003 | `available_at` 必须保留到 envelope 字段                           |
| BR-C004 | secret 只以 reference 形式出现，不打印值                          |
| BR-C005 | 完整采集必须按 root SPEC §5.1 进行跨入口对账，增量同步每次回拉最近 3 个月覆盖修订，保留 `realtime_start/realtime_end` 版本维度，禁止单入口判定完整性 |

## 6. Acceptance / Tests

| AC      | 验收标准                             | TC      |
| ------- | ------------------------------------ | ------- |
| AC-C001 | 采集/分页/重试行为可测试             | TC-C001 |
| AC-C002 | raw-first 归档路径可审计             | TC-C002 |
| AC-C003 | NATS 发布带版本字段并可重试          | TC-C003 |
| AC-C004 | 归一化结果满足 `domain_macro` 契约   | TC-C004 |
| AC-C005 | 全量采集覆盖快照可用，缺口分片可输出 | TC-C005 |

| TC      | 命令建议                                                  |
| ------- | --------------------------------------------------------- |
| TC-C001 | `go test ./internal/client/... -run Collector`            |
| TC-C002 | `go test ./internal/client/... -run RawArchive`           |
| TC-C003 | `go test ./internal/client/... -run NATSIngestPublish`    |
| TC-C004 | `go test ./internal/domain/... -run DomainMacroMapping`   |
| TC-C005 | `go test ./internal/client/... -run FullCoverageSnapshot` |

## 7. Dependencies

- `configx`、`observex`、`resiliencx`
- `domain_macro`
- `ossx`
- `natsx`

## 8. Open Items

| ID      | 问题                                                         |
| ------- | ------------------------------------------------------------ |
| OPEN-C1 | FRED 大规模回补时的并发/限速策略阈值待基准测试确认           |
| OPEN-C2 | envelope schema 的版本升级策略需与 server 联动评审           |
| OPEN-C3 | categories/tags/sources 全量初次扫描耗时较长，需分片调度策略 |
