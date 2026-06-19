# module/binance TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环可追溯。
>
> 规范来源：`docs/governance/TRACEABILITY.md`

- Matrix-Version: v1.3.0
- Last-Updated: 2026-06-17
- Spec-Reference: `module/binance/SPEC.md` v1.0.0

---

## §1 FR 追溯表

> FR 描述与 SPEC §7 标题对齐；AC 编号与 §5 注册表对齐。

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|----------|
| FR-001 | Product-Line Support：Client 可独立采集 Spot / USDⓈ-M / COIN-M / Options 四产品线 | AC-001, AC-002, AC-003 | TC-001 | TASK-BINANCE-ROOT-001, TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | **Partial** — Spot connector 已实现（骨架 PR feat/market-data-cs-skeleton）；USDⓈ-M/COIN-M/Options connector 待后续迭代 |
| FR-002 | Instrument Identity：四产品线 canonical instrument identity 跨 product_line 不碰撞 | AC-015, AC-016 | TC-002, TC-003 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-004, TASK-BINANCE-ROOT-007 | **Partial** — spotParser 已实现 product_line 防碰撞（首版仅 Spot 解析器；mapper 复用 domainmarket.Tick/Quote/Bar）；USDM/COINM/Options parser 待后续 |
| FR-003 | gRPC Ingestion：Client/Server 通过 contracts-defined `MarketDataService` bidi stream 通信 | AC-006, AC-007, AC-008 | TC-004 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-005, TASK-BINANCE-ROOT-006, TASK-BINANCE-ROOT-007 | **Partial** — 首版用原生 Go 接口（internal/cs + IngestClient/ingestAdapter）替代 gRPC bidi stream（见 ADR：自包含契约层）；gRPC 升级留后续 |
| FR-004 | At-Least-Once Delivery：Client 持久化 spool + ACK 后推进 checkpoint | AC-012, AC-013, AC-014 | TC-005 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | **Partial** — in-memory spool 状态机 + checkpoint（仅 durable ACK 后推进，含单测）已实现；SQLite 持久化留后续 |
| FR-005 | Idempotent Acceptance：Server 同 idempotency key 最多 accept 一次 + downstream dispatch 一次 | AC-009, AC-010, AC-011 | TC-006, TC-007 | TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | **Implemented** — in-memory IdempotencyStore（CheckAndSet + 冲突检测 + MarkDurable）+ retry-first dispatch + dead-letter 已实现并测试（含 e2e 去重验证） |
| FR-006 | Admin Surface：Client/Server 各自暴露 Gin admin HTTP 端点（健康/调试/管理）| AC-017, AC-018, AC-019, AC-020 | TC-008, TC-009 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | **Partial** — client/server 各 net/http admin（healthz/readyz/debug/admin）已实现（首版用 net/http，未引 gin）；端点功能覆盖，Gin 迁移 + 认证留后续 |
| FR-007 | Boundary Enforcement：CI gate 阻断 client/server 跨界、legacy binance-market 引用、storage/query/strategy 所有权声明 | AC-021, AC-022, AC-023 | TC-010, TC-011, TC-012 | TASK-BINANCE-ROOT-000, TASK-BINANCE-ROOT-007, TASK-BINANCE-CLIENT-012, TASK-BINANCE-SERVER-008 | **Implemented** — scripts/boundary-gates.sh 封装 9 道门禁，本地全 PASS |

---

## §2 BR 追溯表

> BR 编号与 SPEC §8 一致（BR-001 ~ BR-009）。BR-002/BR-003 已拆分为 client→server 与 server→client 各自独立 BR，对应 BOUNDARY-GATES §3/§4 的两个独立 CI gate。

| BR ID | 业务规则 | 验证方式 | Task | 实现状态 |
|-------|----------|----------|------|----------|
| BR-001 | No binance-market：禁止在 active architecture 中引用 `binance-market` | CI Gate: BOUNDARY-GATES.md §2 (`grep -R -E 'module/binance-market\|github.com/ZoneCNH/binance-market'` — 零匹配除 `docs/migrations/` 和 `CHANGELOG.md`) | TASK-BINANCE-ROOT-000 | Pending |
| BR-002 | Client Must Not Import Server Internals：client 不得 import server internal 包 | CI Gate: BOUNDARY-GATES.md §3 boundary-check script | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| BR-003 | Server Must Not Import Client Internals：server 不得 import client internal 包 | CI Gate: BOUNDARY-GATES.md §4 boundary-check script | TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | Pending |
| BR-004 | Checkpoint Requires ACK：client checkpoint 仅可在 server 返回 durable ACK 后推进 | CI Gate: BOUNDARY-GATES.md §9 + TC-005（ACK 语义单元测试） | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| BR-005 | No Domain Ownership：模块不得定义 canonical domain semantics SSOT，必须引用 `module/domain-market` | CI Gate: BOUNDARY-GATES.md §7 (canonical enum 定义检查) | TASK-BINANCE-ROOT-004, TASK-BINANCE-ROOT-007 | Pending |
| BR-006 | No Storage/Query/Strategy Ownership：模块不得拥有存储引擎、query API、strategy API | CI Gate: BOUNDARY-GATES.md §5 (ownership 关键字检查) | TASK-BINANCE-ROOT-001, TASK-BINANCE-ROOT-007 | Pending |
| BR-007 | Wire Contract Externality：模块不得定义自己的 proto 或 wire schema，必须引用 `module/contracts` | CI Gate: BOUNDARY-GATES.md §6 (无本地 proto 文件 + 无 wire SSOT 声明) | TASK-BINANCE-ROOT-005, TASK-BINANCE-ROOT-007 | Pending |
| BR-008 | Idempotency Key Stability：client 生成的 idempotency key 在 retry 场景下稳定 | TC-007（同 key 两次发送验证）+ FR-005 WHEN/THEN 行为引用 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| BR-009 | Admin Boundary：client admin 仅变更 client-local state，server admin 仅变更 server-local state | CI Gate: BOUNDARY-GATES.md §8 (admin 跨边界访问检查) + TC-009 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | Pending |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源 (SPEC §) | 验证方式 |
|--------|------------|---------------|----------|
| NFR-001 | Client event normalization 延迟 P99 < 1ms | §17 性能预算 | `go test -bench BenchmarkNormalize` |
| NFR-002 | Canonical mapping 延迟 P99 < 100μs | §17 性能预算 | `go test -bench BenchmarkCanonicalMapping` |
| NFR-003 | Spool 写入延迟 P99 < 5ms | §17 性能预算 | `go test -bench BenchmarkSpoolWrite` |
| NFR-004 | gRPC 单 event 投递延迟 P99 < 10ms | §17 性能预算 | integration test |
| NFR-005 | Server validation 延迟 P99 < 100μs | §17 性能预算 | `go test -bench BenchmarkValidation` |
| NFR-006 | Server idempotency check 延迟 P99 < 1ms | §17 性能预算 | `go test -bench BenchmarkIdempotencyCheck` |
| NFR-007 | ACK lag (server receive → ACK send) P99 < 100ms | §17 性能预算 | integration test: client→server→client RTT 测量 |
| NFR-008 | Client restart recovery 时间 < 10s | §17 性能预算 | integration test |
| NFR-009 | 13 个 Prometheus metrics 正确暴露（按 product_line / reason 分组） | §18.1 Metrics | `GET /metrics` 端点检查 + `promtool` 校验 |
| NFR-010 | 7 种 logging 事件正确分级（info/warn/debug/error） | §18.2 Logging | 日志级别检查 + 结构化字段验证 |
| NFR-011 | API Key / Secret 从环境变量读取，不硬编码 | §19 安全 | CI Gate: `gitleaks detect --no-git` + 代码审查 |
| NFR-012 | Secrets 不出现于 log、debug、admin 端点输出 | §19 安全 | CI Gate: `gitleaks detect --no-git` + AC-019 验证 |
| NFR-013 | Admin 端点对外暴露时必须认证（mTLS 或反向代理）| §19 安全 | TC-009 + admin auth 集成测试 |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 状态 |
|-------|------------|------------|----------|------|
| TC-001 | FR-001 | — | 集成测试（Binance testnet） | Pending |
| TC-002 | FR-002 | BR-005 | 单元测试 | Pending |
| TC-003 | FR-002 | BR-005 | 单元测试 | Pending |
| TC-004 | FR-003 | BR-007 | 契约测试（gRPC mock server） | Pending |
| TC-005 | FR-004 | BR-004, BR-008 | 集成测试 | Pending |
| TC-006 | FR-005 | BR-008 | 集成测试 | Pending |
| TC-007 | FR-005 | BR-008 | 集成测试 | Pending |
| TC-008 | FR-006 | — | 单元测试（HTTP endpoint） | Pending |
| TC-009 | FR-006 | BR-009 | 集成测试（HTTP endpoint） | Pending |
| TC-010 | FR-007 | BR-002, BR-003 | CI gate（双向 import 边界检查） | Pending |
| TC-011 | FR-007 | BR-001 | CI gate（no-legacy 引用检查） | Pending |
| TC-012 | FR-007 | BR-006 | CI gate（ownership 关键字检查） | Pending |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 | FR-001 | Client 启动且 product-line 已启用时建立 REST/WebSocket 连接并开始采集 | TC-001: 集成测试验证 WebSocket 连接成功并收到数据 |
| AC-002 | FR-001 | WebSocket 连接断开后自动重连并从最近 checkpoint 恢复 | 集成测试: 模拟断连 → 验证重连 + checkpoint 恢复 |
| AC-003 | FR-001 | 收到 Binance 原生事件后写入本地 SQLite spool | 单元测试: 验证 spool 写入记录存在 |
| AC-004 | FR-002 | Binance 原生事件映射为 canonical MarketFactEnvelope，所有必填字段正确填充 | 单元测试: 验证每个字段映射 |
| AC-005 | FR-002 | Binance 原生字段缺失 canonical 所需信息时，使用 product-line 配置补全 | 单元测试: 构造不完整原生事件 → 验证补全逻辑 |
| AC-006 | FR-003 | 有待投递 canonical events 时打开 Ingest bidirectional stream 并发送含 idempotency key 的 IngestRequest | TC-004: 契约测试验证 server 收到 event |
| AC-007 | FR-003 | gRPC stream 断开后重连并从未 ACK 的 checkpoint 恢复投递 | 集成测试: 模拟 stream 中断 → 验证重连 + 恢复 |
| AC-008 | FR-003 | 收到 server IngestAck 后解析 ACK 确认哪些 events 已持久化接收 | 单元测试: mock server ACK → 验证 client 解析 |
| AC-009 | FR-005 | Server 收到新 idempotency key 的 IngestRequest → 接受 event，返回 accepted ACK，dispatch downstream | TC-006: 集成测试验证 accepted 路径 |
| AC-010 | FR-005 | Server 收到已见 idempotency key 且 payload 一致 → 返回 idempotent ACK，不重复 dispatch | TC-006: 集成测试验证 duplicate 路径 |
| AC-011 | FR-005 | Server 收到已见 idempotency key 但 payload 冲突 → 返回 terminal_conflict reject | TC-007: 集成测试验证 conflict 路径 |
| AC-012 | FR-004 | Client 收到 durable_acceptance=true 的 ACK → 推进 checkpoint，标记 spool 记录已投递 | TC-005: 集成测试验证 checkpoint 推进 |
| AC-013 | FR-004 | Client 收到 durable_acceptance=false 的 ACK 或未收到 ACK → 不推进 checkpoint，按 retry hint 重试 | TC-005: 集成测试验证 checkpoint 不推进 + 重试触发 |
| AC-014 | FR-004 | Client 重启后从最后一个 durable ACK 位置恢复发送，不重复推进 | 集成测试: kill -9 → 重启 → 检查 checkpoint 与 spool 一致 |
| AC-015 | FR-002 | 产出 canonical event 时 ProductLine 和 InstrumentKey 所有字段正确填充 | TC-002: 单元测试验证字段值 |
| AC-016 | FR-002 | 同 symbol 跨 product line 时 InstrumentKey 可区分，不产生碰撞（BTCUSDT Spot vs USDⓈ-M perpetual 不相等） | TC-003: 单元测试验证身份不等 |
| AC-017 | FR-006 | GET /healthz → 返回 200 及进程存活状态 | TC-008: HTTP 集成测试 |
| AC-018 | FR-006 | GET /readyz → 返回模块就绪状态（不检查下游业务正确性，server 未就绪 → 503）| TC-008: HTTP 集成测试 |
| AC-019 | FR-006 | GET /debug/* → 返回只读调试信息，不暴露 secrets | 集成测试: 检查响应不含 API Key/Secret |
| AC-020 | FR-006 | POST /admin/* 无认证访问 → 返回 401（生产模式 + 非 loopback-only 时） | TC-009: 集成测试验证 401 |
| AC-021 | FR-007 | Client 代码 import server internal 包时 CI boundary gate 失败（exit 1） | TC-010: BOUNDARY-GATES.md §3, §4 gate script |
| AC-022 | FR-007 | 任何代码 reintroduce `binance-market` 引用（除 `docs/migrations/` 和 `CHANGELOG.md`）时 CI no-legacy gate 失败 | TC-011: BOUNDARY-GATES.md §2 gate script |
| AC-023 | FR-007 | 模块内声明 storage / query / strategy 所有权关键字时 CI ownership gate 失败 | TC-012: BOUNDARY-GATES.md §5 gate script |

---

## §6 覆盖率仪表盘

| 指标 | 总数 | 已覆盖 | 覆盖率 | 说明 |
|------|------|--------|--------|------|
| 功能需求 (FR) | 7 | 7 | 100% | FR-001 ~ FR-007 全部有 AC + TC |
| 业务规则 (BR) | 9 | 9 | 100% | BR-001 ~ BR-009 全部有 CI Gate 或 TC 验证（BR-002/BR-003 client/server 边界各自独立） |
| 非功能需求 (NFR) | 13 | 13 | 100% | NFR-001 ~ NFR-013 全部有验证方式 |
| 测试用例 (TC) | 12 | 12 | 100% | TC-001 ~ TC-012 全部有对应 FR/BR |
| 验收标准 (AC) | 23 | 23 | 100% | AC-001 ~ AC-023 全部有验证方式（FR-007 边界强制现已覆盖 AC-021~023） |
| 任务 (Task) | 8 | — | — | TASK-BINANCE-ROOT-000 ~ 007 |
| FR→TC 覆盖率 | — | 7/7 | 100% | 每个 FR 至少 1 个 TC |
| BR→验证覆盖率 | — | 9/9 | 100% | 每个 BR 至少 1 个 CI Gate 或 TC |
| AC→验证覆盖率 | — | 23/23 | 100% | 每个 AC 有明确验证方式 |
| 实现状态 | — | 5/7 FR（2 Implemented + 5 Partial） | 71% | FR-005/007 Implemented；FR-001/002/003/004/006 Partial（骨架 PR feat/market-data-cs-skeleton，Spot 单线 + in-memory + 原生 Go 接口） |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 从零创建 §1-§7 标准追溯矩阵；从 SPEC.md v1.0.0 提取 FR-001~007、BR-001~011、TC-001~009、NFR-001~013、AC-001~020；映射 TASK-BINANCE-ROOT-000~007 | ZoneCNH |
| 2026-06-17 | v1.1.0 | **修复 FR/BR/AC 错位**：(1) §1 FR 描述与 SPEC §7 标题对齐，AC 引用按语义重新分配（FR-002↔身份, FR-004↔交付, FR-005↔幂等, FR-006↔admin, FR-007↔边界）；(2) §2 BR 编号统一为 SPEC §7 的 8 条（移除越权的 BR-009/010/011，将其概念归入对应 BR 验证条目）；(3) §5 新增 AC-021/022/023 覆盖 FR-007 边界强制；(4) §4 TC 扩展至 12 条以支撑边界 gate 验证；(5) §6 仪表盘对齐新计数 | ZoneCNH |
| 2026-06-17 | v1.2.0 | **BR-002/BR-003 拆分 + Status 标准化**：原 BR-002 (Client/Server Boundary) 双向约束拆为 BR-002 (Client→Server, BOUNDARY-GATES §3) + BR-003 (Server→Client, BOUNDARY-GATES §4)，原 BR-003~008 顺移至 BR-004~009；§4 TC-010 BR 引用扩展为 BR-002, BR-003；§6 仪表盘 BR 总数 8→9；同步 SPEC §8 BR 拆分；root SPEC Status 从非标 `Docs Baseline Approved` 标准化为 `Review` | ZoneCNH |
| 2026-06-17 | v1.3.0 | **同步 SPEC v1.0.1 Status 晋升**：跟随 root SPEC Status Review → Approved 晋升。本版仅同步 SPEC 引用版本号与状态，FR/BR/AC/TC 主体未变，覆盖率保持 100% | ZoneCNH |
| 2026-06-17 | v1.3.0 | **SPEC 23 节模板对齐**：(1) root SPEC 新增 §1 Metadata 标准节（包裹 frontmatter）；(2) 原 §0 Upstream Contract Gate 移至 Appendix D（保留全部内容，标题改名）；(3) 章节倒序重编号 §1~22 → §2~23（22 个 sed 操作）；(4) 内部自引用更新（§9 Data Model → §10）；(5) TRACEABILITY 同步：NFR 来源引用 §16/§17/§18 → §17/§18/§19（§17.X observability 子节随之），SPEC §6/§7 引用 → §7/§8 | ZoneCNH |
| 2026-06-17 | v1.4.0 | **runtime 骨架落地（feat/market-data-cs-skeleton）**：(1) §1 FR 实现状态从全 Pending 更新为 2 Implemented（FR-005 幂等验收 + FR-007 边界门禁）+ 5 Partial（FR-001/002/003/004/006）；(2) §6 仪表盘实现状态 0% → 71%；(3) 首版取舍：Spot 单产品线、in-memory spool/idempotency、原生 Go 接口替代 gRPC、net/http 替代 gin、RejectCode 9 码（对齐 patches 实际值）；(4) 9 道 boundary-gates 脚本落地 scripts/boundary-gates.sh 全 PASS | ZoneCNH |
