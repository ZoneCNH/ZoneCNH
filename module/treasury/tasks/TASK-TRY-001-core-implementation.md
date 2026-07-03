# TASK-TRY-001 Core Implementation

## Objective

实现 `treasury` 生产级目标骨架：四子模块（`yield`/`auction`/`fiscal`/`tic`）独立 C/S 服务、共享基座接入、`domain_macro` 归一化、`taos + kafka + postgres + Redis + oss + nats + clickhouse` 全链路持久化与分发、覆盖率审计与缺口重采闭环。

## Covers

- FR-TRY-001 ~ FR-TRY-016
- BR-TRY-001 ~ BR-TRY-010
- AC-TRY-001 ~ AC-TRY-010

## Key Deliverables

1. 四子模块 C/S 启动入口与边界门禁。
2. 采集清单落地：收益率、拍卖、财政（DTS/MTS/Debt/Revenue/FX）、TIC。
3. 同步策略落地：频率、增量游标、历史起点、修订回拉、增量/全量重同步。
4. 多存储链路：OSS raw-first、Postgres checkpoint、taos、Kafka、ClickHouse、Redis、NATS。
5. API/作业控制与覆盖率审计报表。

## Acceptance Criteria

1. `go test ./... -count=1` 通过。
2. `go vet ./...` 零警告。
3. `bash scripts/boundary-gates.sh` 通过。
4. NATS/Kafka 职责分层测试通过。
5. 覆盖率审计可生成缺口重采任务并闭合证据，单轮同步目标 ≤30min。

## Dependencies

- `domain_macro`（领域共享层与 no-lookahead 语义）
- `contracts` / `transportx`（API/事件契约）
- 共享基座组件（`bootstrap/configx/observex/resiliencx`）
- 基础设施适配层（`taosx/kafkax/postgresx/redisx/ossx/natsx/clickhousex`）
