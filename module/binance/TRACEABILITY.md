# module/binance TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环可追溯。
>
> 规范来源：`docs/governance/TRACEABILITY.md`

- Matrix-Version: v1.0.0
- Last-Updated: 2026-06-16
- Spec-Reference: `module/binance/SPEC.md` v1.0.0

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|----------|
| FR-001 | Binance 数据采集：Client REST/WebSocket 采集全产品线行情数据 | AC-001, AC-002, AC-003 | TC-001 | TASK-BINANCE-ROOT-001, TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| FR-002 | Canonical 事件映射：Binance 原生事件 → canonical MarketFactEnvelope | AC-004, AC-005 | TC-002 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-004, TASK-BINANCE-ROOT-007 | Pending |
| FR-003 | gRPC 流式投递：Bidirectional stream 向 server 投递 canonical events | AC-006, AC-007, AC-008 | TC-003 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-005, TASK-BINANCE-ROOT-006, TASK-BINANCE-ROOT-007 | Pending |
| FR-004 | 幂等接收：Server 对重复 event 执行幂等处理，不产生下游重复 | AC-009, AC-010, AC-011 | TC-004 | TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | Pending |
| FR-005 | Checkpoint 推进：Client 仅在 durable ACK 后推进 checkpoint | AC-012, AC-013, AC-014 | TC-005, TC-006 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| FR-006 | 产品线标识：Events 携带无碰撞 ProductLine 和 InstrumentKey | AC-015, AC-016 | TC-007 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-004, TASK-BINANCE-ROOT-007 | Pending |
| FR-007 | 管理端点：Client/Server 各自暴露 Gin admin HTTP 端点 | AC-017, AC-018, AC-019, AC-020 | TC-008, TC-009 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | Pending |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | Task | 实现状态 |
|-------|----------|----------|------|----------|
| BR-001 | 禁止引用旧 `binance-market` 代码或模块 | CI Gate: `grep -r "binance-market" . --include="*.go"` — 零匹配 | TASK-BINANCE-ROOT-000 | Pending |
| BR-002 | Client 不得 import server 内部包 | CI Gate: `go build ./client/...` + 边界门禁测试 `TestBoundaryGates` | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| BR-003 | Server 不得 import client 内部包 | CI Gate: `go build ./server/...` + 边界门禁测试 `TestBoundaryGates` | TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | Pending |
| BR-004 | Client/server 通信必须使用 `contracts` 定义的 gRPC | CI Gate: proto 导入路径检查 + `go build` 编译验证 | TASK-BINANCE-ROOT-005, TASK-BINANCE-ROOT-007 | Pending |
| BR-005 | Domain 语义必须来自 `module/domain-market` | CI Gate: import 路径检查 — 禁止自行定义 InstrumentKey / ProductLine / MarketFactEnvelope 等类型 | TASK-BINANCE-ROOT-004, TASK-BINANCE-ROOT-007 | Pending |
| BR-006 | Wire protocol 必须来自 `module/contracts` | CI Gate: proto 导入路径检查 — 禁止自行定义 proto | TASK-BINANCE-ROOT-005, TASK-BINANCE-ROOT-007 | Pending |
| BR-007 | Product line × instrument 组合必须全局无碰撞 | TC-007: 跨 product line 同 symbol 的 InstrumentKey 不相等 | TASK-BINANCE-ROOT-004, TASK-BINANCE-ROOT-007 | Pending |
| BR-008 | Secrets（API Key / Secret）不得出现在 log、debug 端点、admin 端点输出中 | CI Gate: `gitleaks detect --no-git` + 代码审查 | TASK-BINANCE-ROOT-007 | Pending |
| BR-009 | Client 不得在收到 `durable_acceptance=true` 前推进 checkpoint | TC-005, TC-006: ACK 语义单元测试 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-007 | Pending |
| BR-010 | `module/binance` 不得拥有 storage / query / strategy 逻辑 | CI Gate: import 路径检查 — 禁止导入 storage/query/strategy 相关包 | TASK-BINANCE-ROOT-001, TASK-BINANCE-ROOT-007 | Pending |
| BR-011 | Admin 端点对外暴露时必须认证 | TC-009 + admin auth 集成测试: 无认证访问 `/admin/*` → 401 | TASK-BINANCE-ROOT-002, TASK-BINANCE-ROOT-003, TASK-BINANCE-ROOT-007 | Pending |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源 (SPEC §) | 验证方式 |
|--------|------------|---------------|----------|
| NFR-001 | Canonical 映射延迟 P99 < 1ms | §16 性能预算 | `go test -bench BenchmarkCanonicalMapping` |
| NFR-002 | Client spool 写入延迟 P99 < 5ms | §16 性能预算 | `go test -bench BenchmarkSpoolWrite` |
| NFR-003 | gRPC 单 event 投递延迟 P99 < 10ms | §16 性能预算 | `go test -bench BenchmarkGRPCSend` |
| NFR-004 | Server 幂等检查延迟 P99 < 1ms | §16 性能预算 | `go test -bench BenchmarkIdempotencyCheck` |
| NFR-005 | ACK 往返延迟 P99 < 50ms | §16 性能预算 | 集成测试: client→server→client RTT 测量 |
| NFR-006 | Client 采集吞吐 > 1000 events/s | §16 性能预算 | `go test -bench BenchmarkCollectionThroughput` |
| NFR-007 | 8 个 Prometheus metrics 正确暴露（按 product_line / reason 分组） | §17.1 Metrics | `GET /metrics` 端点检查 + `promtool` 校验 |
| NFR-008 | 8 种 logging 事件正确分级（info/warn/debug/error） | §17.2 Logging | 日志级别检查 + 结构化字段验证 |
| NFR-009 | `/healthz` 返回进程存活状态，`/readyz` 返回模块就绪状态 | §17.3 Health Signals | TC-008, TC-009: HTTP 端点集成测试 |
| NFR-010 | API Key / Secret 从环境变量读取，不硬编码 | §18 安全 | CI Gate: `gitleaks detect --no-git` + 代码审查 |
| NFR-011 | Secrets 不出现于 log、debug 端点、admin 端点输出 | §18 安全 | CI Gate: `gitleaks detect --no-git` + AC-019 验证 |
| NFR-012 | Admin 端点对外暴露时必须认证 | §18 安全 | TC-009 + admin auth 集成测试 |
| NFR-013 | gRPC 跨网络部署时需 mTLS | §18 安全 | 配置检查: 非 localhost gRPC target 时 mTLS 证书配置存在 |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 状态 |
|-------|------------|------------|----------|------|
| TC-001 | FR-001 | — | 集成测试（Binance testnet） | Pending |
| TC-002 | FR-002 | — | 单元测试 | Pending |
| TC-003 | FR-003 | — | 集成测试（gRPC loopback） | Pending |
| TC-004 | FR-004 | — | 单元测试 | Pending |
| TC-005 | FR-005 | BR-009 | 单元测试 | Pending |
| TC-006 | FR-005 | BR-009 | 单元测试 | Pending |
| TC-007 | FR-006 | BR-007 | 单元测试 | Pending |
| TC-008 | FR-007 | — | 集成测试（HTTP endpoint） | Pending |
| TC-009 | FR-007 | BR-011 | 集成测试（HTTP endpoint） | Pending |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 | FR-001 | Client 启动且 product-line 已启用时建立 REST/WebSocket 连接并开始采集 | TC-001: 集成测试验证 WebSocket 连接成功并收到数据 |
| AC-002 | FR-001 | WebSocket 连接断开后自动重连并从最近 checkpoint 恢复 | 集成测试: 模拟断连 → 验证重连 + checkpoint 恢复 |
| AC-003 | FR-001 | 收到 Binance 原生事件后写入本地 SQLite spool | 单元测试: 验证 spool 写入记录存在 |
| AC-004 | FR-002 | Binance 原生事件映射为 canonical MarketFactEnvelope，所有必填字段正确填充 | TC-002: 单元测试验证每个字段映射 |
| AC-005 | FR-002 | Binance 原生字段缺失 canonical 所需信息时，使用 product-line 配置补全 | 单元测试: 构造不完整原生事件 → 验证补全逻辑 |
| AC-006 | FR-003 | 有待投递 canonical events 时打开 Ingest bidirectional stream 并发送含 idempotency key 的 IngestRequest | TC-003: 集成测试验证 server 收到 event |
| AC-007 | FR-003 | gRPC stream 断开后重连并从未 ACK 的 checkpoint 恢复投递 | 集成测试: 模拟 stream 中断 → 验证重连 + 恢复 |
| AC-008 | FR-003 | 收到 server IngestAck 后解析 ACK 确认哪些 events 已持久化接收 | 单元测试: mock server ACK → 验证 client 解析 |
| AC-009 | FR-004 | 收到新 idempotency key 的 IngestRequest → 接受 event，返回 accepted ACK | TC-004: 单元测试验证 accepted 路径 |
| AC-010 | FR-004 | 收到已见 idempotency key 的 IngestRequest → 返回 duplicate ACK，无下游副作用 | TC-004: 单元测试验证 duplicate 路径 |
| AC-011 | FR-004 | 收到校验失败的 IngestRequest → 返回 rejected ACK + reject reason | 单元测试: 构造无效 event → 验证 rejected + reason |
| AC-012 | FR-005 | 收到 durable_acceptance=true 的 ACK → 推进 checkpoint，标记 spool 记录已投递 | TC-005: 单元测试验证 checkpoint 推进 |
| AC-013 | FR-005 | 收到 durable_acceptance=false 的 ACK → 不推进 checkpoint，按 retry hint 重试 | TC-006: 单元测试验证 checkpoint 不推进 + 重试触发 |
| AC-014 | FR-005 | 超时未收到 ACK → 重发未确认 events | 单元测试: mock ACK timeout → 验证重发行为 |
| AC-015 | FR-006 | 产出 canonical event 时 ProductLine 和 InstrumentKey 所有字段正确填充 | TC-007: 单元测试验证字段值 |
| AC-016 | FR-006 | 同 symbol 跨 product line 时 InstrumentKey 可区分，不产生碰撞 | TC-007: BTCUSDT Spot vs USDⓈ-M perpetual 不相等 |
| AC-017 | FR-007 | GET /healthz → 返回 200 及进程存活状态 | TC-008: HTTP 集成测试 |
| AC-018 | FR-007 | GET /readyz → 返回模块就绪状态（不检查下游业务正确性） | TC-009: HTTP 集成测试（server 未就绪 → 503） |
| AC-019 | FR-007 | GET /debug/* → 返回只读调试信息，不暴露 secrets | 集成测试: 检查响应不含 API Key/Secret |
| AC-020 | FR-007 | POST /admin/* 无认证访问 → 返回 401 | 集成测试: 无认证请求 → 验证 401 |

---

## §6 覆盖率仪表盘

| 指标 | 总数 | 已覆盖 | 覆盖率 | 说明 |
|------|------|--------|--------|------|
| 功能需求 (FR) | 7 | 7 | 100% | FR-001 ~ FR-007 全部有 AC + TC |
| 业务规则 (BR) | 11 | 11 | 100% | BR-001 ~ BR-011 全部有验证方式 |
| 非功能需求 (NFR) | 13 | 13 | 100% | NFR-001 ~ NFR-013 全部有验证方式 |
| 测试用例 (TC) | 9 | 9 | 100% | TC-001 ~ TC-009 全部有对应 FR/BR |
| 验收标准 (AC) | 20 | 20 | 100% | AC-001 ~ AC-020 全部有验证方式 |
| 任务 (Task) | 8 | — | — | TASK-BINANCE-ROOT-000 ~ 007 |
| FR→TC 覆盖率 | — | 7/7 | 100% | 每个 FR 至少 1 个 TC |
| BR→验证覆盖率 | — | 11/11 | 100% | 每个 BR 至少 1 个 CI Gate 或 TC |
| AC→验证覆盖率 | — | 20/20 | 100% | 每个 AC 有明确验证方式 |
| 实现状态 | — | 0/7 FR | 0% | 全部 FR 为 Pending，代码尚未实现 |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 从零创建 §1-§7 标准追溯矩阵；从 SPEC.md v1.0.0 提取 FR-001~007、BR-001~011、TC-001~009、NFR-001~013、AC-001~020；映射 TASK-BINANCE-ROOT-000~007 | ZoneCNH |
