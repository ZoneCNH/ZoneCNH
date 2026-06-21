# binance 验收清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | v2.1.1 acceptance baseline; not pass proof |
| Last-Updated | 2026-06-21 |
| Module-Version | v2.1.1 |
| Module-State | 文档追溯已闭合；runtime boundary gate 预期失败，直到 `internal/cs`、同进程路径和 direct deps 全部修复 |
| Runtime-Repo | `/home/binance` |
| Source | `SPEC.md`, `TRACEABILITY.md`, `BOUNDARY-GATES.md`, `/home/binance/scripts/boundary-gates.sh` |

本文档是验收执行清单，不是通过证明。Release Done 只能由实际 runtime 命令、CI run 或测试报告关闭。

## 1. 验收命令

| 层级 | 命令 | 通过条件 |
| --- | --- | --- |
| 文档补丁 | `git diff --check -- module/binance` | 无 trailing whitespace 或 patch 格式问题。 |
| 追溯锚点 | `rg -n "FR-001|FR-011|TC-001|TC-028|AC-001|AC-047|SERVER-017" module/binance/SPEC.md module/binance/TRACEABILITY.md module/binance/ACCEPTANCE.md` | 关键锚点存在。 |
| 边界门禁 | `cd /home/binance && ./scripts/boundary-gates.sh` | 10 gates 全 PASS。 |
| runtime build | `cd /home/binance && go build ./...` | 所有 package 构建通过。 |
| runtime test | `cd /home/binance && go test ./... -race -count=1` | 全部通过且无 race。 |
| runtime static | `cd /home/binance && go vet ./... && golangci-lint run` | 零错误。 |
| secret scan | `cd /home/binance && gitleaks detect --no-git` | 零泄露。 |

## 2. Acceptance Criteria 登记

| AC | 所属 FR | 验收意图 | 关联 TC | 当前状态 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | Spot market line 可接入、映射、发布、消费。 | TC-001 | Pending |
| AC-002 | FR-001 | USDM、COINM、Options product lines 纳入同一 contract。 | TC-001 | Pending |
| AC-003 | FR-001 | 不同 product line 的 symbol 与 subject 不互相污染。 | TC-001 | Pending |
| AC-004 | FR-002 | `instrument_key` 包含 exchange、product_line、symbol/contract identity。 | TC-002 | Pending |
| AC-005 | FR-002 | Spot、USDM、COINM、Options 同名 symbol 不冲突。 | TC-002 | Pending |
| AC-006 | FR-002 | Options expiry/strike/right 等身份字段可回放校验。 | TC-003 | Pending |
| AC-007 | FR-003 | Client 使用 `natsx` JetStream publish。 | TC-004 | Pending |
| AC-008 | FR-003 | Subject 遵循 `binance.market.{product_line}.{event_type}`。 | TC-004 | Pending |
| AC-009 | FR-003 | Publish 等待 PubAck，失败返回可观测错误。 | TC-005 | Pending |
| AC-010 | FR-003 | Server 使用 durable consumer `binance-server` 消费。 | TC-005 | Pending |
| AC-011 | FR-004 | Server 使用 ManualAck。 | TC-006 | Pending |
| AC-012 | FR-004 | 只有 `redisx + taosx + postgresx + kafkax` handoff 成功后 Ack。 | TC-006 | Pending |
| AC-013 | FR-004 | 失败 `NakWithDelay(5s)`，MaxDeliver 5 后进入 dead-letter。 | TC-006 | Pending |
| AC-014 | FR-005 | idempotency key 第一次出现时接受并落库。 | TC-007 | Pending |
| AC-015 | FR-005 | 重复 key 同 payload 时 Ack 并跳过副作用。 | TC-007 | Pending |
| AC-016 | FR-005 | 重复 key 不同 payload 时 terminal reject 并记录冲突。 | TC-008 | Pending |
| AC-017 | FR-006a | tick/depth facts 写入 `taosx`。 | TC-009 | Pending |
| AC-018 | FR-006a | 写入失败时不 Ack NATS message。 | TC-009 | Pending |
| AC-019 | FR-006b | hot cache 与 idempotency marker 使用 `redisx`。 | TC-010 | Pending |
| AC-020 | FR-006b | redisx cache TTL、SetNX 与 snapshot consistency 可验证。 | TC-010 | Pending |
| AC-021 | FR-007 | `GET /api/v1/market/ticks` 返回统一 JSON envelope。 | TC-012 | Pending |
| AC-022 | FR-007 | `GET /api/v1/market/depth/{instrument_key}` 返回深度快照或统一错误。 | TC-012 | Pending |
| AC-023 | FR-007 | 未授权请求返回 401。 | TC-013 | Pending |
| AC-024 | FR-007 | 超出限流返回 429 与 `Retry-After`。 | TC-014 | Pending |
| AC-025 | FR-007 | 下游 `market_data` 只能通过 HTTP 或 Kafka 消费，不导入 server internals。 | TC-015 | Pending |
| AC-026 | FR-006d | instrument catalog 与 replay metadata 写入 `postgresx`。 | TC-011 | Pending |
| AC-027 | FR-006d | replay metadata 可按 `instrument_key` 和时间范围查询。 | TC-011 | Pending |
| AC-028 | FR-006d | postgresx 写入失败时不 Ack NATS message。 | TC-011 | Pending |
| AC-029 | FR-008 | 归档路径遵循 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`。 | TC-016 | Pending |
| AC-030 | FR-008 | 删除 `taosx` 旧分区前必须校验对象 ETag。 | TC-017 | Pending |
| AC-031 | FR-008 | ETag 不匹配时停止删除并报警。 | TC-017 | Pending |
| AC-032 | FR-009 | Server 通过 `kafkax` 发送 `binance.market.{product_line}.{event_type}`。 | TC-018 | Pending |
| AC-033 | FR-009 | Kafka message key 为 symbol 或 instrument identity。 | TC-018 | Pending |
| AC-034 | FR-009 | Kafka handoff 失败时不 Ack NATS message。 | TC-019 | Pending |
| AC-035 | FR-009 | Binance 模块不得声明通用跨交易所 market storage/query/strategy 所有权。 | TC-020 | Blocked until boundary gate PASS |
| AC-036 | FR-006c | ClickHouse OLAP 表只接收 Binance 专属事实投影。 | TC-023 | Pending |
| AC-037 | FR-006c | ClickHouse 写入失败不阻塞 hot path，但必须进入可重放队列。 | TC-024 | Pending |
| AC-038 | FR-007a | Server admin API 只能暴露 server 状态、consumer lag 和 storage health。 | TC-025 | Pending |
| AC-039 | FR-007a | Client admin API 只能暴露采集器、连接和 publish 状态。 | TC-025 | Pending |
| AC-040 | FR-007a | admin API 不跨进程直接调用对端内部包。 | TC-025 | Blocked until boundary gate PASS |
| AC-041 | FR-010 | CI 禁止 `binance-client` 导入 server internals。 | TC-020 | Blocked until boundary gate PASS |
| AC-042 | FR-010 | CI 禁止 `binance-server` 导入 client internals。 | TC-020 | Blocked until boundary gate PASS |
| AC-043 | FR-010 | CI 禁止 `binance-market` 与 runtime `internal/cs` 回流。 | TC-021 | Blocked until boundary gate PASS |
| AC-044 | FR-010 | CI 禁止 Binance 模块定义 canonical market domain 或本地 proto/gRPC ingest schema。 | TC-022 | Blocked until boundary gate PASS |
| AC-045 | FR-011 | `go.mod` 直接依赖包含 `natsx/redisx/kafkax/postgresx/taosx/clickhousex/ossx/Gin`。 | TC-026 | Blocked until boundary gate PASS |
| AC-046 | FR-011 | client binary 不直接依赖 server-only storage adapters。 | TC-027 | Blocked until boundary gate PASS |
| AC-047 | FR-011 | server binary 不直接依赖 Binance exchange connector。 | TC-028 | Blocked until boundary gate PASS |

## 3. Test Case 登记

| TC | 覆盖 | 当前状态 | 关闭证据 |
| --- | --- | --- | --- |
| TC-001 | FR-001 product-line support | Pending | 四条 product line 的连接、publish、consume 集成测试输出。 |
| TC-002 | FR-002 identity uniqueness | Pending | 同名 symbol 跨 product line 无冲突测试。 |
| TC-003 | FR-002 options identity replay | Pending | Options expiry/strike/right 回放测试。 |
| TC-004 | FR-003 subject and publish path | Pending | `natsx` publish subject 与 payload contract 测试。 |
| TC-005 | FR-003 durable consumer and PubAck | Pending | PubAck、consumer restart、replay 测试。 |
| TC-006 | FR-004 at-least-once ManualAck | Pending | Ack/Nak、MaxDeliver、dead-letter 失败注入测试。 |
| TC-007 | FR-005 duplicate idempotency | Pending | Duplicate same payload side-effect skip 测试。 |
| TC-008 | FR-005 idempotency conflict | Pending | Duplicate different payload terminal reject 测试。 |
| TC-009 | FR-006a taosx persistence | Pending | facts persistence 与 no-Ack-on-failure 测试。 |
| TC-010 | FR-006b redisx cache/idempotency | Pending | TTL、SetNX、cache consistency 测试。 |
| TC-011 | FR-006d postgresx catalog/replay | Pending | catalog persistence 与 replay metadata 查询测试。 |
| TC-012 | FR-007 market API success | Pending | ticks/depth API success contract 测试。 |
| TC-013 | FR-007 auth | Pending | 401 测试。 |
| TC-014 | FR-007 rate limit | Pending | 429 与 `Retry-After` 测试。 |
| TC-015 | FR-007 downstream boundary | Pending | `market_data` 不导入 server internals 的 boundary test。 |
| TC-016 | FR-008 archive path | Pending | ossx path 与 parquet object 测试。 |
| TC-017 | FR-008 ETag guard | Pending | ETag mismatch 防删除测试。 |
| TC-018 | FR-009 Kafka dispatch | Pending | topic/key/handoff 测试。 |
| TC-019 | FR-009 Kafka failure handling | Pending | Kafka failure no Ack 测试。 |
| TC-020 | FR-009/FR-010 ownership and import gates | Blocked until boundary gate PASS | `/home/binance/scripts/boundary-gates.sh` 全 PASS。 |
| TC-021 | FR-010 legacy name and cs gates | Blocked until boundary gate PASS | CI grep gate 输出。 |
| TC-022 | FR-010 domain/wire ownership gates | Blocked until boundary gate PASS | ownership drift 与 schema drift gate 输出。 |
| TC-023 | FR-006c ClickHouse OLAP projection | Pending | ClickHouse table/write/query 测试。 |
| TC-024 | FR-006c OLAP replay queue | Pending | ClickHouse failure replay 测试。 |
| TC-025 | FR-007a admin boundary | Blocked until boundary gate PASS | admin API 跨边界导入检查。 |
| TC-026 | FR-011 direct dependency compliance | Blocked until boundary gate PASS | go.mod direct dependency gate。 |
| TC-027 | FR-011 client binary dependency compliance | Blocked until boundary gate PASS | client package dependency check。 |
| TC-028 | FR-011 server binary dependency compliance | Blocked until boundary gate PASS | server package dependency check。 |

## 4. 覆盖闭合矩阵

| FR | AC 覆盖 | TC 覆盖 | 当前闭合状态 |
| --- | --- | --- | --- |
| FR-001 | AC-001~AC-003 | TC-001 | Not Closed |
| FR-002 | AC-004~AC-006 | TC-002~TC-003 | Not Closed |
| FR-003 | AC-007~AC-010 | TC-004~TC-005 | Not Closed |
| FR-004 | AC-011~AC-013 | TC-006 | Not Closed |
| FR-005 | AC-014~AC-016 | TC-007~TC-008 | Not Closed |
| FR-006a | AC-017~AC-018 | TC-009 | Not Closed |
| FR-006b | AC-019~AC-020 | TC-010 | Not Closed |
| FR-006d | AC-026~AC-028 | TC-011 | Not Closed |
| FR-006c | AC-036~AC-037 | TC-023~TC-024 | Not Closed |
| FR-007 | AC-021~AC-025 | TC-012~TC-015 | Not Closed |
| FR-007a | AC-038~AC-040 | TC-025 | Not Closed |
| FR-008 | AC-029~AC-031 | TC-016~TC-017 | Not Closed |
| FR-009 | AC-032~AC-035 | TC-018~TC-020 | Not Closed |
| FR-010 | AC-041~AC-044 | TC-020~TC-022 | Not Closed |
| FR-011 | AC-045~AC-047 | TC-026~TC-028 | Not Closed |

## 5. Release Definition of Done

| 红线 | 结果 |
| --- | --- |
| `/home/binance/scripts/boundary-gates.sh` 非 0 | 不得 Release Done。 |
| `go build ./...` 或 `go test ./... -race -count=1` 失败 | 不得 Release Done。 |
| `go vet ./...` 或 `golangci-lint run` 失败 | 不得 Release Done。 |
| `TRACEABILITY.md` 出现 FR/AC/TC 错位，或 `Implemented` 无 runtime 证据 | 不得 Release Done。 |
| secret scan 发现凭证、交易所 API key、账户 ID、私有端点或实盘交易配置 | 不得 Release Done。 |

## 6. 当前验收缺口

| 缺口 | 风险 | 下一步关闭动作 |
| --- | --- | --- |
| runtime boundary gates 尚未全 PASS | 分布式 C/S 边界可能仍被同进程路径或旧依赖破坏。 | 修复 `/home/binance` 后重复执行 `./scripts/boundary-gates.sh`。 |
| FR-001~FR-011 均缺 runtime pass evidence | 文档不能替代实现验收。 | 按 `IMPLEMENTATION-PLAN.md` 顺序实现并回填测试证据。 |
| build/test/race/vet/lint/secret scan 未归档 | Release Done 缺少可审计证据。 | 在 runtime repo 执行命令并把结果链接到 release evidence。 |
