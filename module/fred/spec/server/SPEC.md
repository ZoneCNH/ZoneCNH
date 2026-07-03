# fred-server SPEC

- Status: Planned
- Spec-Version: v1.0.0
- Last-Updated: 2026-07-03
- Parent: [../SPEC.md](../SPEC.md)
- Plan: [../../plan/server/PLAN.md](../../plan/server/PLAN.md)

## 1. Goal

`fred-server` 负责把 ingest envelope 转换为可查询、可回放、可审计的宏观数据服务输出，并对下游提供稳定契约。

## 2. Scope

1. 消费 NATS ingest envelope。
2. 幂等校验 + checkpoint 管理。
3. 写入 `postgres/taos/Redis/clickhouse`（含 category/tag/source/release 图谱）。
4. 发布 Kafka durable events。
5. 提供 Query/Admin API（含 coverage 审计视图）。

## 3. Non-Goals

- 不执行 FRED provider 直连抓取。
- 不承载策略、交易、风控决策。
- 不把 Redis/ClickHouse 当权威源。

## 4. Functional Requirements

| ID | WHEN | THEN |
| --- | --- | --- |
| FR-S001 | WHEN 收到 ingest envelope | THEN 校验 schema version 与必填字段 |
| FR-S002 | WHEN 幂等键重复 | THEN 不产生重复副作用 |
| FR-S003 | WHEN 持久化路径执行 | THEN `postgres` checkpoint 与状态机顺序一致 |
| FR-S004 | WHEN observation 通过校验 | THEN 写入 `taos` 时间序列 |
| FR-S005 | WHEN 热点查询访问 | THEN 使用 `Redis` 缓存并保持可重建 |
| FR-S006 | WHEN 分析投影生成 | THEN 写入 `clickhouse` 读模型并可重建 |
| FR-S007 | WHEN 业务事实确定 | THEN 发布 Kafka durable event（版本化） |
| FR-S008 | WHEN 外部查询调用 | THEN API 返回 `domain_macro` 语义并执行 no-lookahead |
| FR-S009 | WHEN admin 指令触发 | THEN 走 NATS control subject 并落审计日志 |
| FR-S010 | WHEN 任一关键步骤失败 | THEN job 不得标记 completed，需可重放恢复 |
| FR-S011 | WHEN 执行覆盖审计 | THEN 生成 series/release/category/tag/source/updates 六域覆盖率、缺口分片和重采任务视图，并按 root SPEC §5.1 细分端点级缺口，核对默认 `1990-01-01` 全量起点、最近 3 个月修订回拉与 `realtime_start/realtime_end` 版本结果 |

## 5. Business Rules

| ID | 规则 |
| --- | --- |
| BR-S001 | `available_at` 是 as-of 可见性闸门 |
| BR-S002 | Kafka 仅承载 durable business events |
| BR-S003 | NATS 仅承载 handoff/control，不替代 Kafka |
| BR-S004 | checkpoint 成功推进前不得完成 job |
| BR-S005 | 所有 API/事件均禁止暴露 provider DTO |
| BR-S006 | 覆盖审计必须基于跨入口对账结果，不得以单表行数替代完整性结论 |

## 6. Acceptance / Tests

| AC | 验收标准 | TC |
| --- | --- | --- |
| AC-S001 | 幂等与 checkpoint 顺序正确 | TC-S001 |
| AC-S002 | 多存储写入闭合且可回放 | TC-S002 |
| AC-S003 | Kafka/NATS 分层正确 | TC-S003 |
| AC-S004 | no-lookahead 查询语义正确 | TC-S004 |
| AC-S005 | API/admin 契约与鉴权可验证 | TC-S005 |
| AC-S006 | 覆盖审计接口可返回六域覆盖率与缺口分片 | TC-S006 |

| TC | 命令建议 |
| --- | --- |
| TC-S001 | `go test ./internal/server/... -run Idempotency` |
| TC-S002 | `go test ./internal/integration/... -run PersistPipeline` |
| TC-S003 | `go test ./internal/integration/... -run NATSIngestHandoff` |
| TC-S004 | `go test ./internal/server/... -run NoLookahead` |
| TC-S005 | `go test ./internal/server/... -run APIContract` |
| TC-S006 | `go test ./internal/integration/... -run FullCoverageAudit` |

## 7. Dependencies

- `postgresx`、`taosx`、`redisx`、`clickhousex`
- `kafkax`、`natsx`
- `domain_macro`
- `contracts`、`transportx`

## 8. Open Items

| ID | 问题 |
| --- | --- |
| OPEN-S1 | backfill 峰值负载下的批量写入参数待压测确定 |
| OPEN-S2 | API 鉴权策略需与网关层统一（mTLS/JWT） |
| OPEN-S3 | 全量覆盖审计计算窗口与查询成本需评估并设置分层缓存 |
