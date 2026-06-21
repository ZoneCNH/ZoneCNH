# binance 完整验收清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-06-21 |
| Module-Version | v2.0.0 |
| Module-State | 验收清单已补齐；runtime 通过状态仍以实际 `/home/binance` 测试为准 |
| Runtime-Repo | `/home/binance` |
| Source | `SPEC.md`, `TRACEABILITY.md`, `client/TRACEABILITY.md`, `server/TRACEABILITY.md`, `BOUNDARY-GATES.md` |

本文档是验收执行清单，不是通过证明。每个 Pending 项必须由实际命令输出、CI run、测试报告或 traceability 状态更新关闭。

## 1. 验收命令

| 验收面 | 命令 | 通过条件 |
| --- | --- | --- |
| 文档文件存在 | `cd /home/ZoneCNH/.worktree/workspaces/docs/binance-features-acceptance && test -f module/binance/FEATURES.md && test -f module/binance/ACCEPTANCE.md` | 两个文件都存在。 |
| 文档补丁格式 | `cd /home/ZoneCNH/.worktree/workspaces/docs/binance-features-acceptance && git diff --check -- module/binance` | 无 trailing whitespace 或 patch 格式错误。 |
| 追溯锚点覆盖 | `cd /home/ZoneCNH/.worktree/workspaces/docs/binance-features-acceptance && rg -n "FR-001|FR-010|TC-001|TC-022|AC-001|AC-035" module/binance/SPEC.md module/binance/TRACEABILITY.md module/binance/FEATURES.md module/binance/ACCEPTANCE.md` | 根级 FR、AC、TC 锚点在规格、追溯和补齐文档中可定位。 |
| Runtime build | `cd /home/binance && go build ./...` | 所有 package 构建通过。 |
| Runtime tests | `cd /home/binance && go test ./...` | 单元与集成测试通过。 |
| Runtime race | `cd /home/binance && go test ./... -race -count=1` | 并发路径无 race。 |
| Runtime vet | `cd /home/binance && go vet ./...` | 无 vet blocker。 |
| Runtime lint | `cd /home/binance && golangci-lint run` | 无 lint blocker。 |
| Secret scan | `cd /home/binance && gitleaks detect --no-git` | 无凭证泄漏。 |
| Boundary gates | `cd /home/binance && <run checks from module/binance/BOUNDARY-GATES.md>` | 禁止路径、禁止导入、禁止同进程 C/S、禁止 ownership drift 全部 PASS。 |

## 2. Acceptance Criteria 登记

| AC | 所属 FR | 验收口径 | 关联 TC | 当前状态 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | Client 启动且 product-line 已启用时建立 WebSocket 连接并开始采集。 | TC-001 | Partial / TC Pending |
| AC-002 | FR-001 | WebSocket 连接断开后自动重连，JetStream durable consumer 自动恢复消费位置。 | TC-001 | Pending |
| AC-003 | FR-001 | 收到 Binance 原生事件后映射为 MarketFactEnvelope 并通过 natsx 发布。 | TC-004 | Pending |
| AC-004 | FR-002 | Binance 原生事件映射为 canonical MarketFactEnvelope，所有必填字段正确填充。 | TC-002 | Partial / TC Pending |
| AC-005 | FR-002 | Binance 原生字段缺失时使用 product-line 配置补全。 | TC-002 | Pending |
| AC-006 | FR-002 | 同 symbol 跨 product_line 时 InstrumentKey 可区分（BTCUSDT Spot != BTCUSDT USDⓈ-M）。 | TC-003 | Pending |
| AC-007 | FR-003 | Client 通过 `natsx.Publish(subj, json)` 发布事件，等待 JetStream PubAck（确保持久化）。 | TC-004 | Pending |
| AC-008 | FR-003 | Server 通过 `natsx.Subscribe(durable)` 订阅，不共享 client 进程或内存。 | TC-004, TC-005 | Pending |
| AC-009 | FR-003 | Subject 格式 `binance.market.{product_line}.{event_type}`，大小写统一小写。 | TC-004 | Pending |
| AC-010 | FR-003 | C/S 可在不同机器独立启动，CI gate 验证无跨进程 import。 | TC-005 | Pending |
| AC-011 | FR-004 | JetStream durable consumer（durable: `binance-server`）进程重启后从上次 Ack 位置恢复。 | TC-006 | Pending |
| AC-012 | FR-004 | 处理成功（redisx+taosx+postgresx+kafkax handoff 全完成）后 `msg.Ack()`。 | TC-006 | Pending |
| AC-013 | FR-004 | 处理失败时 `msg.NakWithDelay(5s)`，`MaxDeliver=5` 后进入死信。 | TC-006 | Pending |
| AC-014 | FR-005 | 首次消息（SetNX 成功）继续写入 taosx。 | TC-007 | Pending |
| AC-015 | FR-005 | 重复消息（SetNX 失败）Ack 并跳过，不写 taosx。 | TC-007 | Pending |
| AC-016 | FR-005 | Redis 不可达时返回 error，consumer `NakWithDelay`。 | TC-008 | Pending |
| AC-017 | FR-006 | taosx `WriteTick` 使用 symbol+product_line 子表名，自动创建子表。 | TC-009 | Pending |
| AC-018 | FR-006 | taosx `WriteBatch` 合并多条消息一次网络往返。 | TC-009 | Pending |
| AC-019 | FR-006 | postgresx `UpsertSymbol` 幂等（ON CONFLICT DO UPDATE）。 | TC-010 | Pending |
| AC-020 | FR-006 | postgresx `UpdateIngestStatus` 更新 last_seq 用于 gap fill。 | TC-010 | Pending |
| AC-021 | FR-007 | `GET /api/v1/market/ticks` 从 taosx 查询，支持 symbol、time range、limit。 | TC-012 | Pending |
| AC-022 | FR-007 | `GET /api/v1/market/depth/:symbol` 从 redisx 读取最新快照。 | TC-013 | Pending |
| AC-023 | FR-007 | 无效 API key 返回 401。 | TC-014 | Pending |
| AC-024 | FR-007 | 超限（1000 req/min）返回 429 和 `Retry-After`。 | TC-015 | Pending |
| AC-025 | FR-007 | `GET /readyz` 任一组件断连时返回 503。 | TC-012 | Pending |
| AC-026 | FR-008 | 每日定时查询 cutoff（now - 90d）之前的 taosx 数据。 | TC-016 | Pending |
| AC-027 | FR-008 | ossx ETag 验证通过后才执行 taosx.Delete（先写冷再删热）。 | TC-016 | Pending |
| AC-028 | FR-008 | 归档路径格式 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet`。 | TC-017 | Pending |
| AC-029 | FR-009 | kafkax topic = `binance.market.{product_line}.{event_type}`。 | TC-018 | Pending |
| AC-030 | FR-009 | partition key = symbol，相同 symbol 有序到达同一 partition。 | TC-018 | Pending |
| AC-031 | FR-009 | Kafka 不可达时返回 error；未完成 kafkax handoff 前不 Ack，进入 retry/dead-letter/告警路径。 | TC-019 | Pending |
| AC-032 | FR-010 | server 源码无 `internal/client` 或 `internal/cs` 导入（CI gate）。 | TC-020 | PASS |
| AC-033 | FR-010 | 任何代码 reintroduce `binance-market` 引用时 CI no-legacy gate 失败。 | TC-021 | Pending |
| AC-034 | FR-010 | go.mod gin/ossx 为 direct；五个 infra 模块从 indirect 升为 direct。 | TC-022 | Pending |
| AC-035 | FR-010 | BOUNDARY-GATES §5（cs 包禁止）+ §6（同进程禁止）+ §11（go.mod 合规）全 PASS。 | TC-020, TC-022 | Partial |

## 3. Test Case 登记

| TC | 覆盖 | 类型 / 验证口径 | 当前状态 | 关闭证据 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | 集成（Binance testnet） | Pending | 四条 product line 的连接、publish、consume 集成测试输出。 |
| TC-002 | FR-002, BR-007 | 单元（product_line identity） | Pending | canonical identity 字段与必填字段测试输出。 |
| TC-003 | FR-002, BR-007 | 单元（cross product_line 不碰撞） | Pending | 同名 symbol 跨 product_line 不碰撞测试输出。 |
| TC-004 | FR-003, BR-005 | 集成（client natsx Publish，server 独立进程接收） | Pending | `natsx` publish、subject、PubAck、独立进程接收测试输出。 |
| TC-005 | FR-003, BR-002, BR-003 | CI gate（跨进程边界检查） | Pending | client/server 无跨边界 import gate 输出。 |
| TC-006 | FR-004, BR-004 | 集成（JetStream ManualAck：处理成功→Ack，失败→NakWithDelay） | Pending | Ack/Nak、MaxDeliver、dead-letter 失败注入测试输出。 |
| TC-007 | FR-005 | 单元（SetNX 首次→新消息；重复→跳过） | Pending | 首次写入和重复跳过测试输出。 |
| TC-008 | FR-005 | 单元（Redis 不可达→error→NakWithDelay） | Pending | Redis 故障注入与 consumer NakWithDelay 测试输出。 |
| TC-009 | FR-006, BR-006 | 单元（taosx WriteTick + WriteBatch） | Pending | taosx 写入和批量写入测试输出。 |
| TC-010 | FR-006, BR-006 | 单元（postgresx UpsertSymbol 幂等） | Pending | postgresx upsert 与 ingest status 测试输出。 |
| TC-011 | FR-006 | 集成（taosx QueryRange 时间范围过滤） | Pending | taosx 时间范围查询测试输出。 |
| TC-012 | FR-007 | httptest（/api/v1/market/ticks） | Pending | ticks API success 与 readyz 测试输出。 |
| TC-013 | FR-007 | httptest（/api/v1/market/depth redisx） | Pending | depth API redisx snapshot 测试输出。 |
| TC-014 | FR-007 | httptest（API key 401） | Pending | 401 测试输出。 |
| TC-015 | FR-007 | httptest（限流 429） | Pending | 429 与 Retry-After 测试输出。 |
| TC-016 | FR-008, BR-006 | 单元（先写 ossx 后删 taosx） | Pending | ETag 通过后删除 taosx 的生命周期测试输出。 |
| TC-017 | FR-008 | 单元（归档路径格式） | Pending | ossx path 格式测试输出。 |
| TC-018 | FR-009 | 单元（kafkax topic + partition key） | Pending | topic 与 partition key 测试输出。 |
| TC-019 | FR-009, BR-004 | 单元（kafkax 不可达→error/不 Ack） | Pending | Kafka 故障不 Ack 测试输出。 |
| TC-020 | FR-010, BR-005 | CI gate（cs 包/client 包 import 检查） | PASS | `TRACEABILITY.md` 已标注 PASS。 |
| TC-021 | FR-010, BR-001 | CI gate（no-legacy 引用检查） | Pending | legacy name grep gate 输出。 |
| TC-022 | FR-010, BR-009 | CI gate（go.mod 合规） | Pending | go.mod direct dependency gate 输出。 |

## 4. 覆盖闭合矩阵

| FR | AC 覆盖 | TC 覆盖 | 当前闭合状态 |
| --- | --- | --- | --- |
| FR-001 | AC-001~AC-003 | TC-001 | Not Closed |
| FR-002 | AC-004~AC-006 | TC-002~TC-003 | Not Closed |
| FR-003 | AC-007~AC-010 | TC-004~TC-005 | Not Closed |
| FR-004 | AC-011~AC-013 | TC-006 | Not Closed |
| FR-005 | AC-014~AC-016 | TC-007~TC-008 | Not Closed |
| FR-006 | AC-017~AC-020 | TC-009~TC-011 | Not Closed |
| FR-007 | AC-021~AC-025 | TC-012~TC-015 | Not Closed |
| FR-008 | AC-026~AC-028 | TC-016~TC-017 | Not Closed |
| FR-009 | AC-029~AC-031 | TC-018~TC-019 | Not Closed |
| FR-010 | AC-032~AC-035 | TC-020~TC-022 | Partially Closed |

## 5. Release Definition of Done

| 检查项 | 当前状态 | 关闭标准 |
| --- | --- | --- |
| `FEATURES.md` 存在 | Done | 本文件同目录存在完整实现清单。 |
| `ACCEPTANCE.md` 存在 | Done | 当前文件存在完整验收清单。 |
| 根、Client、Server traceability 存在 | Done | 三个 traceability 文件可定位。 |
| natsx / ManualAck / redisx / ossx / kafkax 边界已写入规格 | Done | `SPEC.md` 与 `TRACEABILITY.md` 可定位对应 FR/AC/TC。 |
| Boundary gates 文档化 | Done | `BOUNDARY-GATES.md` 存在。 |
| 所有 FR implemented | Not Done | FR-001~FR-009 状态全部闭合。 |
| 所有 AC passed | Not Done | AC-001~AC-035 全部有测试证据。 |
| 所有 TC passed | Not Done | TC-001~TC-022 全部 PASS。 |
| Runtime test evidence | Not Done | `/home/binance` 的 build/test/race/vet/lint/secret scan 输出归档。 |
| Coverage and performance evidence | Not Done | 覆盖率、延迟、吞吐、重放与故障注入报告归档。 |
| CI pass | Not Done | GitHub Actions 或等价 CI run 通过并链接到 release evidence。 |

## 6. 当前验收缺口

| 缺口 | 风险 | 下一步关闭动作 |
| --- | --- | --- |
| 文档仓库无 runtime 测试输出 | 不能从 docs repo 推断实现完成。 | 在 `/home/binance` 执行 build/test/race/vet/lint/secret scan 并回填证据。 |
| FR-001/FR-002 Partial | 四 product line 与 identity contract 不完整。 | 补齐 USDM、COINM、Options parser/mapper/connector/server acceptance。 |
| FR-003~FR-009 Pending | C/S runtime、存储、API、广播、归档未闭合。 | 按 `IMPLEMENTATION-PLAN.md` 和 tasks 顺序实现并更新 traceability。 |
| TC-021/TC-022 Pending | Boundary enforcement 仍缺完整 CI 证据。 | 将 `BOUNDARY-GATES.md` gate 命令接入 CI 并记录 PASS。 |
| Release DoD 未达成 | 不能声明 binance v2.0.0 已可发布。 | 全量 AC/TC PASS 后再更新 release 状态。 |
