# binance 完整验收清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-06-26 |
| Module-Version | v3.7.0 |
| Module-State | 验收清单已补齐；L1 边界治理 FR-009 Done（13 gates PASS）；L2 当前状态投影以 Runtime-Anchor `/home/binance@f046e16` 与 `TRACEABILITY.md` v3.7.0 为准：FR **24 Done / 10 Partial / 10 Pending**（含 v3.7.0 新增 FR-037~044 全 Pending）；Plan008 已闭合 release gate（GitHub Release `v0.2.0`，workflow `28126779885` completed/success，`release_closeable=YES`）。
| Runtime-Repo | `/home/binance` |
| Source | `SPEC.md`, `TRACEABILITY.md`, `DATA-LIFECYCLE.md`, `STANDARD.md`, `client/TRACEABILITY.md`, `server/TRACEABILITY.md`, `BOUNDARY-GATES.md` |

本文档是验收执行清单，不是通过证明。每个 Pending 项必须由实际命令输出、CI run、测试报告或 traceability 状态更新关闭。

### 状态口径 L1/L2 分层（RULES R4）

> 状态列每个值隐含 L1/L2 层级，不可用 boundary gate 证据替代功能验收：

| 状态值 | 层级 | 含义 | 证据要求 |
| --- | --- | --- | --- |
| `PASS` | L1 Boundary/Governance | 边界治理 AC（FR-009/BR-001~009）通过 boundary-gate.sh 或 CI workflow，并绑定 runtime SHA | local evidence log / CI URL + runtime SHA |
| `Done` | L1 Boundary/Governance | 边界治理 BR/TC 已有 runtime 证据（BOUNDARY-GATES.md + 变更历史 SHA） | runtime SHA + local evidence log 或 CI URL |
| `Partial / TC Pending` | L2 Functional | 功能 FR 已部分实现（如 Spot 产品线），但 TC 未全绿 | feature/integration test 输出 + runtime SHA |
| `Pending` | L2 Functional | runtime 仓未推送对应功能实现；默认 `Pending — 以 runtime 仓为准` | runtime feature test + integration test |

> [COMPUTED, HIGH] L1 状态可由本地 boundary gate 或 CI 证据标记，但必须绑定 runtime SHA；L2 状态必须附 runtime feature/integration test 输出与 runtime git SHA，runtime 仓未推送时所有 L2 FR 默认 Pending。
>
> [COMPUTED, HIGH] 2026-06-24 gated `natsx` integration 已在真实本地 NATS JetStream 上验证 PubAck duplicate、ManualAck 成功不重投、immediate Nak 至 `MaxDeliver=5` 后停止；TC-004/TC-006 仍保持 Pending，因为独立 client/server 进程、`NakWithDelay(5s)`、dead-letter/parking 和完整 live 链路未闭合。
>
> [COMPUTED, HIGH] 2026-06-24 kafkax fanout local unit subset 已验证 topic/key 与 strict handoff：目标 server 测试、`go test ./cmd/binance-server ./internal/server -count=1`、`go test ./...`、`go vet ./...`、`./scripts/boundary-gates.sh` 与 `plan006_task_4_7_repeat_checks=100` PASS；真实 Kafka broker e2e 与 production topic/ACL 仍未闭合；release evidence 已由后续 Plan008 closeout 闭合。

## 1. 验收命令

| 验收面 | 命令 | 通过条件 |
| --- | --- | --- |
| 文档文件存在 | `cd /home/ZoneCNH && test -f module/binance/FEATURES.md && test -f module/binance/ACCEPTANCE.md` | 两个文件都存在。 |
| 文档补丁格式 | `cd /home/ZoneCNH && git diff --check -- module/binance` | 无 trailing whitespace 或 patch 格式错误。 |
| 追溯锚点覆盖 | `cd /home/ZoneCNH && rg -n "FR-001|FR-010|FR-030|TC-001|TC-022|TC-049|AC-001|AC-035|AC-104" module/binance/SPEC.md module/binance/TRACEABILITY.md module/binance/FEATURES.md module/binance/ACCEPTANCE.md` | 根级 FR、AC、TC 锚点在规格、追溯和补齐文档中可定位。 |
| Runtime build | `cd /home/binance && go build ./...` | 所有 package 构建通过。 |
| Runtime tests | `cd /home/binance && go test ./...` | 单元与集成测试通过。 |
| Runtime race | `cd /home/binance && go test ./... -race -count=1` | 并发路径无 race。 |
| Runtime vet | `cd /home/binance && go vet ./...` | 无 vet blocker。 |
| Runtime lint | `cd /home/binance && golangci-lint run` | 无 lint blocker。 |
| Secret scan | `cd /home/binance && gitleaks detect --no-git` | 无凭证泄漏。 |
| Boundary gates | `cd /home/binance && bash -n scripts/boundary-gates.sh && ./scripts/boundary-gates.sh` | 13/13 PASS：禁止路径、禁止导入、禁止同进程 C/S、禁止 ownership drift、natsx/storage/gin presence 与 go.mod drift 全部 PASS；本地证据归档见 `/home/binance/release/evidence/binance/20260623/boundary-gates.log`。 |

## 2. Acceptance Criteria 登记

| AC | 所属 FR | 验收说明 | 关联 TC | 当前状态 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | Spot market line 可接入、映射、发布、消费；Client 在 product-line 已启用时建立 WebSocket 连接并开始采集。 | TC-001 | Partial / TC Pending |
| AC-002 | FR-001 | USDM、COINM、Options product lines 纳入同一 contract；连接断开后自动重连，JetStream durable consumer 自动恢复消费位置。 | TC-001 | Pending |
| AC-003 | FR-001 | 不同 product line 的 symbol 与 subject 不互相污染；收到 Binance 原生事件后映射为 MarketFactEnvelope 并通过 natsx 发布。 | TC-004 | Pending |
| AC-004 | FR-002 | `instrument_key` 包含 exchange、product_line、symbol/contract identity；Binance 原生事件映射为 canonical MarketFactEnvelope 且必填字段正确填充。 | TC-002 | Partial / TC Pending |
| AC-005 | FR-002 | Spot、USDM、COINM、Options 同名 symbol 不冲突；Binance 原生字段缺失时由 product-line 配置补全。 | TC-002 | Pending |
| AC-006 | FR-002 | Options expiry/strike/right 等身份字段可回放校验；同 symbol 跨 product_line 时 InstrumentKey 可区分。 | TC-003 | Pending |
| AC-007 | FR-003 | Client 使用 `natsx` JetStream publish 并等待 PubAck；通过 `natsx.Publish(subj, json)` 发送且确保持久化。 | TC-004 | Pending |
| AC-008 | FR-003 | Subject 遵循 `binance.market.{product_line}.{event_type}`，大小写统一小写；Server 通过 `natsx.Subscribe(durable)` 订阅并与 client 进程隔离。 | TC-004, TC-005 | Pending |
| AC-009 | FR-003 | Publish 等待 PubAck，失败返回可观测错误；C/S 可在不同机器独立启动且 CI gate 验证无跨进程 import。 | TC-005 | Pending |
| AC-010 | FR-003 | Server 使用 durable consumer `binance-server` 消费；consumer 重启后从上次 Ack 位置恢复。 | TC-006 | Pending |
| AC-011 | FR-004 | Server 使用 ManualAck；处理成功后执行 `msg.Ack()`。 | TC-006 | Pending |
| AC-012 | FR-004 | 只有 `redisx + taosx + postgresx + kafkax` handoff 成功后 Ack；处理失败时 `msg.NakWithDelay(5s)`，`MaxDeliver=5` 后进入 dead-letter。 | TC-006 | Pending |
| AC-013 | FR-005 | idempotency key 第一次出现时接受并落库；首次消息（SetNX 成功）继续写入 taosx。 | TC-007 | Pending |
| AC-014 | FR-005 | 重复 key 同 payload 时 Ack 并跳过副作用；重复消息（SetNX 失败）Ack 并跳过，不写 taosx。 | TC-007 | Pending |
| AC-015 | FR-005 | 重复 key 不同 payload 时 terminal reject 并记录冲突；Redis 不可达时返回 error，consumer NakWithDelay。 | TC-008 | Pending |
| AC-016 | FR-006a | tick/depth facts 写入 `taosx`；`taosx.WriteTick` 使用 symbol+product_line 子表名并自动创建子表。 | TC-009 | Pending |
| AC-017 | FR-006a / FR-006b | instrument catalog 与 replay metadata 写入 `postgresx`；`taosx.WriteBatch` 合并多条消息一次网络往返。 | TC-009 | Pending |
| AC-018 | FR-006b / FR-006c | hot cache 与 idempotency marker 使用 `redisx`；`postgresx.UpsertSymbol` 幂等（ON CONFLICT DO UPDATE）。 | TC-010 | Pending |
| AC-019 | FR-006b / FR-006d | 冷归档使用 `ossx`，不把通用 market_data 存储上移到本模块外；`postgresx.UpdateIngestStatus` 更新 last_seq 用于 gap fill。 | TC-011 | Pending |
| AC-020 | FR-007 | `GET /api/v1/market/ticks` 返回统一 JSON envelope，并从 taosx 查询，支持 symbol、time range、limit。 | TC-012 | Pending |
| AC-021 | FR-007 | `GET /api/v1/market/depth/{instrument_key}` 返回深度快照或统一错误，并从 redisx 读取最新快照。 | TC-013 | Pending |
| AC-022 | FR-007 | 未授权请求返回 401；无效 API key 返回 401。 | TC-014 | Pending |
| AC-023 | FR-007 | 超出限流返回 429 与 `Retry-After`；限流阈值以 1000 req/min 为准。 | TC-015 | Pending |
| AC-024 | FR-007 | 下游 `market_data` 只能通过 HTTP 或 Kafka 消费，不导入 server internals；`/readyz` 在任一组件断连时返回 503。 | TC-012, TC-015 | Pending |
| AC-025 | FR-007 | `/readyz` 在任一组件断连时返回 503，且 readiness 不掩盖下游 storage、NATS、Kafka 或 API 依赖异常。 | TC-012 | Pending |
| AC-026 | FR-006d | 归档路径遵循 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`；每日定时查询 cutoff（now - 90d）之前的 taosx 数据。 | TC-016, TC-017 | Pending |
| AC-027 | FR-006d | 删除 `taosx` 旧分区前必须校验对象 ETag；ossx ETag 验证通过后才执行 taosx.Delete（先写冷再删热）。 | TC-016 | Pending |
| AC-028 | FR-006d | ETag 不匹配时停止删除并报警；ossx path 与 parquet object 格式可回放校验。 | TC-017 | Pending |
| AC-029 | FR-008 | Server 通过 `kafkax` 发送 `binance.{product_line}.{event_type}.v1`；Kafka topic 与 natsx subject 明确分离。 | TC-018 | Partial（local adapter topic 已验证；真实 broker e2e pending） |
| AC-030 | FR-008 | Kafka message key 为 symbol 或 instrument identity；partition key = symbol，相同 symbol 有序到达同一 partition。 | TC-018 | Partial（local key=symbol 已验证；真实 partition/order e2e pending） |
| AC-031 | FR-008 | Kafka handoff 失败时不 Ack NATS message；Kafka 不可达时返回 error，进入 retry/dead-letter/告警路径。 | TC-019 | Partial（strict dispatch failure → retryable BNC-008 before durable/Ack 已验证；broker/DLQ e2e pending） |
| AC-032 | FR-009 | CI 禁止 `binance-client` 导入 server internals；server 源码无 client 内部包或运行时共享包导入。 | TC-020 | PASS |
| AC-033 | FR-009 | CI 禁止 `binance-server` 导入 client internals；任何代码 reintroduce `binance-market` 引用时 CI no-legacy gate 失败。 | TC-021 | PASS |
| AC-034 | FR-009 | CI 禁止 `binance-market` 与运行时共享包回流；go.mod 中 natsx/redisx/postgresx/taosx/clickhousex/kafkax/ossx/gin 均保持 direct 依赖。 | TC-022 | PASS |
| AC-035 | FR-009 | `BOUNDARY-GATES` 全量检查通过，且 client/server 边界、进程边界、运行时共享包禁止与依赖边界均保持可审计。 | TC-020, TC-022 | PASS |
| AC-036~AC-047 | FR-006c/FR-007a/FR-010/FR-011 | redisx hot cache、analytics API、clickhousex ETL 与 distributed coordinator lock。 | TC-023~TC-028 | Pending |
| AC-048~AC-059 | FR-012~FR-015 | stream session lifecycle、reliability controls、observability、pause/resume/drain。 | TC-029~TC-032 | Pending |
| AC-060~AC-071 | FR-016~FR-019 | historical backfill planner、gap replay、archive manifest/restore、resource governance。 | TC-033~TC-036 | Pending |
| AC-072~AC-080 | FR-020~FR-022 | funding rate、mark/index price 与 event-type governance matrix。 | TC-037~TC-039 | Pending |
| AC-081~AC-086 | FR-023~FR-024 | release evidence bundle 与 runtime config hot reload。 | TC-040~TC-042 | Pending |
| AC-087~AC-098 | FR-025~FR-028 | backfill throttle/priority、daily reconciliation、cold data rehydration、progress API。 | TC-043~TC-046 | Pending |
| AC-099~AC-104 | FR-029~FR-030 | freshness SLA、Options raw field pass-through。 | TC-047~TC-049 | Pending |

## 3. Test Case 登记

| TC | 覆盖 | 类型 / 验证口径 | 当前状态 | 关闭证据 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | 集成（Binance testnet；四条 product line 的连接、publish、consume；断线重连与 durable recovery） | Partial（Spot 基本通路可用；USDM/COINM/Options 未完成）| 四条 product line 的连接、publish、consume 集成测试输出。 |
| TC-002 | FR-002, BR-007 | 单元（product_line identity / canonical identity 字段） | Partial（Spot identity 已验证；跨产品线碰撞未全覆盖）| canonical identity 字段与必填字段测试输出。 |
| TC-003 | FR-002, BR-007 | 单元（cross product_line 不碰撞 / options identity replay） | Pending | 同名 symbol 跨 product_line 不碰撞与 Options 回放测试输出。 |
| TC-004 | FR-003, BR-005 | 集成（client natsx Publish，server 独立进程接收） | Pending | 2026-06-24 gated local JetStream test 已证明 accepted PubAck 与 duplicate PubAck；仍需独立 client/server 进程接收证明与完整 live 链路证据。 |
| TC-005 | FR-003, BR-002, BR-003 | CI gate（跨进程边界检查） | Pending | FR-003 独立进程 publish/consume 仍需集成输出；BR-002/BR-003 boundary 证据由 TC-020/TC-021 与 `BOUNDARY-GATES.md` 承载。 |
| TC-006 | FR-004, BR-004 | 集成（JetStream ManualAck：处理成功→Ack，失败→NakWithDelay） | Pending | 2026-06-24 gated local JetStream test 已证明 Ack 后不重投与 immediate Nak 到 `MaxDeliver=5` 后停止；仍需 `NakWithDelay(5s)` 与 dead-letter/parking 失败注入证据。 |
| TC-007 | FR-005 | 单元（SetNX 首次→新消息；重复→跳过） | Pending | 首次写入和重复跳过测试输出。 |
| TC-008 | FR-005 | 单元（idempotency conflict / Redis 不可达→error→NakWithDelay） | Pending | Duplicate different payload terminal reject 与 Redis 故障注入测试输出。 |
| TC-009 | FR-006a, BR-006 | 单元（taosx WriteTick + WriteBatch） | Pending | taosx 写入和批量写入测试输出。 |
| TC-010 | FR-006b, BR-006 | 单元（postgresx UpsertSymbol 幂等 + UpdateIngestStatus） | Pending | postgresx upsert 与 ingest status 测试输出。 |
| TC-011 | FR-006a / FR-006d | 集成（taosx QueryRange 时间范围过滤 / ossx lifecycle） | Pending | taosx 时间范围查询与 archive lifecycle 测试输出。 |
| TC-012 | FR-007 | httptest（/api/v1/market/ticks；ticks API success；readyz） | Pending | ticks API success 与 readyz 测试输出。 |
| TC-013 | FR-007 | httptest（/api/v1/market/depth；redisx snapshot；401 auth） | Pending | depth API redisx snapshot 与 401 测试输出。 |
| TC-014 | FR-007 | httptest（API key 401；rate limit 429 and Retry-After） | Pending | 401 与 429 测试输出。 |
| TC-015 | FR-007 | boundary test（market_data 不导入 server internals；HTTP/Kafka only） | Pending | market_data boundary test 输出。 |
| TC-016 | FR-006d, BR-006 | 单元（先写 ossx 后删 taosx） | Pending | ETag 通过后删除 taosx 的生命周期测试输出。 |
| TC-017 | FR-006d | 单元（归档路径格式） | Pending | ossx path 格式测试输出。 |
| TC-018 | FR-008 | 单元（kafkax topic + partition key） | Partial | 2026-06-24 local unit subset：`go test ./internal/server -run 'TestKafkaDispatch' -count=1 -v` 与 `plan006_task_4_7_repeat_checks=100` PASS；真实 Kafka broker topic 未验证。 |
| TC-019 | FR-008, BR-004 | 单元（kafkax 不可达→error/不 Ack） | Partial | 2026-06-24 strict handoff unit subset：目标 `TestProcess_Strict*` / `TestProcess_DispatchRetryExhausted` 与 `plan006_task_4_7_repeat_checks=100` PASS；真实 broker/DLQ e2e 未验证。 |
| TC-020 | FR-009, BR-005 | CI gate（运行时共享包/client 包 import 检查） | PASS | `/home/binance/release/evidence/binance/20260623/boundary-gates.log` |
| TC-021 | FR-009, BR-001 | CI gate（no-legacy 引用检查） | PASS | `/home/binance/release/evidence/binance/20260623/boundary-gates.log` |
| TC-022 | FR-009, BR-009 | CI gate（go.mod 合规） | PASS | `/home/binance/release/evidence/binance/20260623/boundary-gates.log` + `/home/binance/release/evidence/binance/20260623/go-build.log` |
| TC-023~TC-028 | FR-006c/FR-007a/FR-010/FR-011 | 单元 + 集成 + httptest（redisx hot cache、analytics API、clickhousex ETL、coordinator lock） | Pending | 对应 runtime tests 与 traceability PASS。 |
| TC-029~TC-032 | FR-012~FR-015 | active stream registry/reliability/metrics/operator controls | Pending | no-restart stream add/remove、retry budget、pause/resume/drain 证据。 |
| TC-033~TC-036 | FR-016~FR-019 | backfill planner/gap replay/archive/resource governance | Pending | historical lifecycle runtime tests 与 restore evidence。 |
| TC-037~TC-039 | FR-020~FR-022 | funding/mark/index event support + R2 governance matrix | Pending | event mapping/storage/query/fanout 与 checker evidence。 |
| TC-040~TC-042 | FR-023~FR-024 | evidence bundle/release gate/runtime hot reload | Pending | release evidence、CI/live smoke、no-restart reload proof。 |
| TC-043~TC-046 | FR-025~FR-028 | backfill throttle/reconciliation/rehydration/progress。 | Pending | 对应 runtime tests、metrics、contract tests 与 release evidence。 |
| TC-047~TC-049 | FR-029~FR-030 | freshness SLA、Options raw field pass-through。 | Pending | 对应 runtime tests、metrics、contract tests 与 release evidence。 |

## 4. 覆盖闭合矩阵

| FR | AC 覆盖 | TC 覆盖 | 当前闭合状态 |
| --- | --- | --- | --- |
| FR-001 | AC-001~AC-003 | TC-001 | Not Closed |
| FR-002 | AC-004~AC-006 | TC-002~TC-003 | Not Closed |
| FR-003 | AC-007~AC-010 | TC-004~TC-005 | Not Closed |
| FR-004 | AC-011~AC-013 | TC-006 | Not Closed |
| FR-005 | AC-014~AC-016 | TC-007~TC-008 | Not Closed |
| FR-006a | AC-016~AC-017 | TC-009, TC-011 | Not Closed |
| FR-006b | AC-017~AC-019 | TC-010 | Not Closed |
| FR-007 | AC-021~AC-025 | TC-012~TC-015 | Not Closed |
| FR-006d | AC-026~AC-028 | TC-016~TC-017 | Not Closed |
| FR-008 | AC-029~AC-031 | TC-018~TC-019 | Not Closed（local unit subset Partial；broker e2e pending） |
| FR-009 | AC-032~AC-035 | TC-020~TC-022 | Done（L1 边界治理，本地 runtime evidence 已归档；远端 CI/release evidence 仍单独验收）|
| FR-010 | AC-041~AC-044 | TC-025~TC-026 | Not Closed |
| FR-006c | AC-036~AC-037 | TC-023 | Not Closed |
| FR-007a | AC-038~AC-040 | TC-024 | Not Closed |
| FR-011 | AC-045~AC-047 | TC-027~TC-028 | Not Closed |
| FR-012~FR-015 | AC-048~AC-059 | TC-029~TC-032 | Not Closed |
| FR-016~FR-019 | AC-060~AC-071 | TC-033~TC-036 | Not Closed |
| FR-020~FR-022 | AC-072~AC-080 | TC-037~TC-039 | Not Closed |
| FR-023~FR-024 | AC-081~AC-086 | TC-040~TC-042 | Not Closed |
| FR-025~FR-028 | AC-087~AC-098 | TC-043~TC-046 | Not Closed |
| FR-029~FR-030 | AC-099~AC-104 | TC-047~TC-049 | Not Closed |

## 5. Release Definition of Done

| 检查项 | 当前状态 | 关闭标准 |
| --- | --- | --- |
| `FEATURES.md` 存在 | Done | 本文件同目录存在完整实现清单。 |
| `ACCEPTANCE.md` 存在 | Done | 当前文件存在完整验收清单。 |
| 根、Client、Server traceability 存在 | Done | 三个 traceability 文件可定位。 |
| natsx / ManualAck / redisx / ossx / kafkax 边界已写入规格 | Done | `SPEC.md` 与 `TRACEABILITY.md` 可定位对应 FR/AC/TC。 |
| Boundary gates 文档化 | Done | `BOUNDARY-GATES.md` 存在。 |
| 所有 FR implemented | 24 Done / 10 Partial / 10 Pending | 当前口径以 `TRACEABILITY.md` v3.7.0 为准：基于 Runtime-Anchor `/home/binance@f046e16` 与 Issue-Ledger `../../report/binance/issues-sync-20260625.md`；Partial FR 为 FR-007/007a/011/016/017/023/024/026/027/028；Pending FR 为 FR-037~044（v3.7.0 新增）+ FR-031~036（Draft）。 |
| 所有 AC passed | Not Done | AC-001~AC-130 全部有测试证据。 |
| 所有 TC passed | Not Done | TC-001~TC-065 全部 PASS。 |
| Runtime test evidence | Local+CI+Release Evidence Done / Full external E2E Pending | `/home/binance/release/evidence/binance/{20260623,20260625}/` 已归档 build/test/race/vet/lint/smoke/boundary gate/testnet-live/SLO；runtime anchor `/home/binance@f18a329`；Plan008 release gate 已闭合：GitHub Release `v0.2.0`，workflow `28126779885` completed/success，`release_closeable=YES`；真实 Kafka broker e2e、覆盖率/性能与全量 AC/TC 仍按本表单独治理。 |
| Coverage and performance evidence | Not Done | 覆盖率、延迟、吞吐、重放与故障注入报告归档。 |
| CI pass | Done (release workflow) | GitHub Actions workflow `28126779885` completed/success and linked to release closeout. |

## 6. 当前验收缺口

| 缺口 | 风险 | 下一步关闭动作 |
| --- | --- | --- |
| release gate 已闭合但不等于 30/30 FR Done | Release `v0.2.0` + workflow `28126779885` 关闭发布证据与 Plan008 ledger，不自动关闭 remaining FR/AC/TC。 | 后续按 `TRACEABILITY.md` 单独重判 FR/AC/TC 与 production-grade external E2E。 |
| FR-001/FR-002 Partial | 四 product line 与 identity contract 不完整。 | 补齐 USDM、COINM、Options parser/mapper/connector/server acceptance。 |
| FR-003~FR-008/FR-010~FR-030 未整体闭合 | C/S runtime、存储、API、广播、归档、实时控制面、历史生命周期、事件治理、数据质量、Options 字段透传未整体闭合；release gate 已由 Plan008 闭合但不自动关闭这些 FR；FR-008 仅 local unit subset Partial。 | 按 `IMPLEMENTATION-PLAN.md` 和 tasks 顺序实现并更新 traceability。 |
| 生产级 DoD 未达成 | 已发布 `v0.2.0` 不等于生产级全量 DoD。 | 补齐全量 AC/TC、覆盖率/性能与外部 E2E 后再声明 30/30 FR L2 Done。 |

## 7. GitHub Issue Closure Ledger（2026-06-23）

> [COMPUTED, HIGH] 2026-06-23 GitHub 核查后，#923~#931 均为 `CLOSED`。完整账本见 [`report/binance/github-issues-923-931-closure-ledger-20260623.md`](../../report/binance/github-issues-923-931-closure-ledger-20260623.md)。
>
> [COMPUTED, HIGH] 本节记录 2026-06-23 issue tracking closure，而不是 runtime/release promotion。后续 Plan008 已关闭 release artifact/tag/remote workflow 证据；live/external E2E 与 FR runtime promotion 仍必须由对应 acceptance/release gate 单独关闭。

| Issue | GitHub 状态 | 已有证据 | Runtime/release 边界 |
| --- | --- | --- | --- |
| #923 | Closed | `RUNTIME-MAPPING.md`、`BOUNDARY-GATES.md`、`/home/binance/release/evidence/binance/20260623/SUMMARY.md` | 不关闭 live Binance WebSocket、完整 `natsx` JetStream TC-004/TC-006（独立进程、`NakWithDelay`、dead-letter/parking）、durable storage/fanout/query、post-fix release tag。 |
| #924 | Closed | 本地 evidence bundle 与 PR #14 可作为候选证据入口。 | 不替代远端 CI、GitHub Release、live smoke、release artifact linkage。 |
| #925 | Closed | `README.md`、`docs/architecture/`、`SPEC.md`、`TRACEABILITY.md`、`DATA-LIFECYCLE.md` 已对齐 v3.5.0 投影。 | 无额外 runtime 声明。 |
| #926 | Closed | `DATA-LIFECYCLE.md` §9 形式化闭合备忘录：FR-012~FR-030 登记完成、影响台账完整、旧 issue 映射完成。 | Runtime 实现仍由 FR/runtime gates 治理。 |
| #927 | Closed | FR-012~FR-015 已登记。 | 不关闭 `exchangeInfo` discovery、catalog refresh、stream policy、depth tier、real reconnect/degradation evidence。 |
| #928 | Closed | FR-016~FR-024 已登记。 | 不关闭 cold-start backfill、gap replay、funding/mark-price、reconciliation、rehydration、progress API、hot reload runtime proof。 |
| #929 | Closed | FR-025~FR-030 已登记。 | 不关闭 throttle、validation、gap repair、SLA metrics、schema drift 与 quality evidence。 |
| #930 | Closed | stale v3.3/v3.4 projection 已移除；legacy `binance-market` 引用已压缩到边界/追踪语境；DEEP analysis archive/index 已拆分。 | 无额外 runtime 声明。 |
| #931 | Closed | #923~#930 的状态入口已统一登记。 | Runtime/release readiness 继续按 acceptance/release gates 判断。 |
