# module/binance/client TRACEABILITY

> 追溯矩阵 §1–§7，符合 `docs/governance/TRACEABILITY.md` 标准格式。
> 数据来源：`module/binance/client/SPEC.md` v2.1.1。

- Module-Version: v2.1.1（与 client SPEC Spec-Version 一致；root Module-Version v3.7.1）
- Last-Updated: 2026-06-25
- Spec-Reference: `module/binance/client/SPEC.md` v2.1.1

---

## §1 FR 追溯表

> **v2.0.0 架构变更**：FR-007（SQLite spool）和 FR-008（checkpoint）已归档，由 natsx JetStream 持久化替代。
> FR-009 重写为 natsx Publisher（替代 gRPC bidi stream sender）。

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|:--------:|
| FR-001 | Product-Line Catalog：维护 Binance 四产品线目录，每条独立启停，支持热重载 | AC-001~004 | TC-001 | TASK-BINANCE-CLIENT-001 | ⬜ Pending |
| FR-002 | Instrument Parser：解析 Binance 原生 symbol 为规范身份组件，消除跨产品线身份碰撞 | AC-005~007 | TC-002~004 | TASK-BINANCE-CLIENT-002 | ⬜ Pending |
| FR-003 | Product-Line Connectors：Spot/USDⓈ-M/COIN-M/Options 4 个 connector，断线重连/限速感知/优雅关闭 | AC-008~012 | TC-005, TC-006 | TASK-BINANCE-CLIENT-003~006 | ⬜ Pending |
| FR-004 | Raw Event Normalization：规范化原始事件，保留完整溯源（10 字段） | AC-013, AC-014 | TC-007 | TASK-BINANCE-CLIENT-007 | ⬜ Pending |
| FR-005 | Canonical Mapping：映射规范化事件为 domain_market 类型 | AC-015, AC-016 | TC-008 | TASK-BINANCE-CLIENT-007 | ⬜ Pending |
| FR-006 | Idempotency Key Generation：跨重试稳定，按 event type 差异化策略 | AC-017, AC-018 | TC-009, TC-010 | TASK-BINANCE-CLIENT-007 | ⬜ Pending |
| ~~FR-007~~ | ~~Spool：SQLite 发送前持久化~~  ⚠️ **ARCHIVED v2.0.0** — JetStream 持久化替代，见 SERVER-010 | — | — | ~~TASK-BINANCE-CLIENT-009~~ | 🗄️ Archived |
| ~~FR-008~~ | ~~Checkpoint：仅 server 持久 ACK 后推进~~ ⚠️ **ARCHIVED v2.0.0** — JetStream durable consumer 替代 | — | — | ~~TASK-BINANCE-CLIENT-009~~ | 🗄️ Archived |
| FR-009 | natsx Publisher：mapper 输出的 MarketFactEnvelope 通过 `natsx.Publish` **网络**发布到 JetStream；等待 PubAck 确认持久化；禁止同进程调用 | AC-019~023 | TC-011~013 | TASK-BINANCE-CLIENT-014 | ⬜ Pending（v2.0.0 重写） |
| FR-010 | Admin Surface：HTTP 端点（healthz/readyz/debug/admin），仅操作本地状态 | AC-024~028 | TC-014, TC-015 | TASK-BINANCE-CLIENT-010 | ⬜ Pending |

---

## §2 BR 追溯表

| BR ID | 业务规则 | SPEC §8 Ref | 验证方式 | 实现状态 |
|-------|---------|-------------|----------|:--------:|
| ~~BR-001~~ | ~~Checkpoint 仅在 server 持久 ACK 后推进~~ ⚠️ **ARCHIVED v2.0.0** — JetStream ManualAck 替代 | — | — | 🗄️ Archived |
| ~~BR-002~~ | ~~Spool 状态机 5 条合法转换~~ ⚠️ **ARCHIVED v2.0.0** — Spool 已废弃 | — | — | 🗄️ Archived |
| BR-003 | Client Go import 图不得出现 `module/binance/server`、`internal/cs` 的任何包 | BR-003 | CI Gate: BOUNDARY-GATES.md §3, §5 | ⬜ Pending |
| BR-004 | Client Go import 图不得出现 `storage/`、`query/`、`strategy/` 包 | BR-004 | CI Gate: BOUNDARY-GATES.md §4 | ⬜ Pending |
| BR-005 | 同一 symbol 在不同产品线中必须产生不同的规范身份 | BR-005 | TC-002~004 | ⬜ Pending |
| BR-006 | natsx Publisher 必须等待 JetStream PubAck 再返回；禁止 fire-and-forget | BR-006 | TC-012: mock PubAck 同步等待 | ⬜ Pending |
| BR-007 | Client 禁止与 server 同进程运行（独立二进制，独立机器可部署） | BR-007 | CI Gate: BOUNDARY-GATES.md §6 | ⬜ Pending |

---

## §3 NFR 追溯表

### 3.1 性能预算

| NFR ID | 非功能需求 | 目标 | 测量方式 | 实现状态 |
|--------|-----------|------|----------|:--------:|
| NFR-P01 | 事件规范化延迟 | P99 < 1ms | `go test -bench BenchmarkNormalize` | ⬜ Pending |
| NFR-P02 | 事件映射延迟 | P99 < 500μs | `go test -bench BenchmarkMapping` | ⬜ Pending |
| NFR-P03 | 幂等键生成延迟 | P99 < 100μs | `go test -bench BenchmarkIdempotencyKey` | ⬜ Pending |
| NFR-P04 | natsx Publish 延迟（含 JetStream PubAck 往返） | P99 < 5ms | integration test | ⬜ Pending |
| NFR-P05 | 单 connector 采集吞吐 | > 500 events/s | 集成 benchmark | ⬜ Pending |
| NFR-P06 | Client 内存稳态 | < 256MB | `go test -benchmem` long-running test | ⬜ Pending |
| NFR-P07 | Admin `/healthz` 延迟 | P99 < 1ms | httptest benchmark | ⬜ Pending |
| NFR-P08 | Client restart recovery | < 10s（JetStream durable consumer 自动恢复） | integration test | ⬜ Pending |

### 3.2 可观测性

| NFR ID | 非功能需求 | 说明 | 验证方式 | 实现状态 |
|--------|-----------|------|----------|:--------:|
| NFR-O01 | Metrics | Prometheus 指标，按 product_line 标注，前缀 `binance_client_`（含 publish TPS / PubAck latency / reconnect count） | metrics endpoint | ⬜ Pending |
| NFR-O02 | Structured logging | 所有日志含 product_line + stream_id + subject | observex 集成 | ⬜ Pending |

### 3.3 安全

| NFR ID | 非功能需求 | 验证方式 | 实现状态 |
|--------|-----------|----------|:--------:|
| NFR-S01 | 不硬编码 API Key / Secret Key / 任何凭证 | gitleaks CI | ⬜ Pending |
| NFR-S02 | 不在日志中记录 API Key / Secret / 签名原文 | secret redaction test | ⬜ Pending |
| NFR-S03 | Admin 端点不暴露 secrets | 端点输出审查 | ⬜ Pending |
| NFR-S04 | natsx 连接使用 TLS（生产环境） | 配置审查 | ⬜ Pending |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 场景摘要 | 状态 |
|-------|-----------|-----------|:--------:|---------|:----:|
| TC-001 | FR-001 | — | 单元 | 加载 4 条产品线 catalog，验证独立启停 | ⬜ Pending |
| TC-002 | FR-002 | BR-005 | 单元 | BTCUSDT Spot 身份，与 USDⓈ-M 不碰撞 | ⬜ Pending |
| TC-003 | FR-002 | BR-005 | 单元 | BTCUSDT USDⓈ-M 永续身份 | ⬜ Pending |
| TC-004 | FR-002 | BR-005 | 单元 | Options Call/Put 身份 | ⬜ Pending |
| TC-005 | FR-003 | — | 集成 | Spot connector 连接并接收事件 | ⬜ Pending |
| TC-006 | FR-003 | — | 集成 | Connector 断开后自动重连，事件流继续 | ⬜ Pending |
| TC-007 | FR-004 | — | 单元 | 规范化 trade 事件，验证 10 字段完整 | ⬜ Pending |
| TC-008 | FR-005 | — | 单元 | 映射规范化事件到 `*domain_market.MarketEvent` | ⬜ Pending |
| TC-009 | FR-006 | — | 单元 | 同一事件两次生成幂等键，结果相同 | ⬜ Pending |
| TC-010 | FR-006 | — | 单元 | 不同 event type 使用不同 key 策略 | ⬜ Pending |
| TC-011 | FR-009 | BR-007 | 单元（mock JetStream） | Publish 调用 JetStream.Publish(subj, data) | ⬜ Pending |
| TC-012 | FR-009 | BR-006 | 单元 | Publish 等待 PubAck 返回后才 return nil | ⬜ Pending |
| TC-013 | FR-009 | BR-003 | 单元 | JetStream 不可达 → Publish 返回 error，不 panic | ⬜ Pending |
| TC-014 | FR-010 | — | 单元 | `/healthz` 返回 HTTP 200 | ⬜ Pending |
| TC-015 | FR-010 | — | 单元 | Admin pause 产品线，connector 停止产生新事件 | ⬜ Pending |

### 4.1 CI Gate 专用验证

| Gate ID | 覆盖 BR(s) | 命令 | 通过条件 | 状态 |
|---------|-----------|------|----------|:----:|
| CI-BOUNDARY-SERVER | BR-003 | `grep -r 'internal/server\|internal/cs' internal/client/` | 零匹配 | ⬜ Pending |
| CI-BOUNDARY-STORAGE | BR-004 | `go list -deps ./... \| grep -qE 'storage/\|query/\|strategy/'` | 零匹配 | ⬜ Pending |
| CI-NO-CS-PKG | BR-003 | BOUNDARY-GATES.md §5 脚本 | PASS | ⬜ Pending |
| CI-NO-SAME-PROCESS | BR-007 | BOUNDARY-GATES.md §6 脚本 | PASS | ⬜ Pending |

---

## §5 AC 注册表

### FR-001: Product-Line Catalog

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-001 | Client 启动时加载全部 4 条产品线 | TC-001 |
| AC-002 | 每条产品线可独立配置启用/禁用 | TC-001 |
| AC-003 | Catalog reload 不中断已启用产品线的活跃连接 | TC-001 |
| AC-004 | 查询 catalog entry 返回完整字段（exchange/product_line/symbol/base_asset/quote_asset 等） | TC-001 |

### FR-002: Instrument Parser

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-005 | Parser 区分 Spot / USDⓈ-M / COIN-M / Options Call / Options Put 五种身份 | TC-002~004 |
| AC-006 | 不可解析 symbol 返回 error，不产生歧义映射 | TC-002 |
| AC-007 | Parser 输出作为 domain_market 规范类型输入，不自定义规范枚举 | TC-008 |

### FR-003: Product-Line Connectors

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-008 | 启用产品线时 connector 启动连接并开始采集 | TC-005 |
| AC-009 | 连接断开后 connector 自动重连并恢复订阅 | TC-006 |
| AC-010 | 收到交易所限速响应时以限速感知策略恢复 | TC-006 |
| AC-011 | 收到原始事件时捕获 raw payload + 本地时间戳 + product_line，输出统一格式内部事件流 | TC-005 |
| AC-012 | 禁用产品线时 connector 优雅关闭，不再产生新事件 | TC-015 |

### FR-004: Raw Event Normalization

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-013 | 规范化事件保留 product_line / source stream / raw symbol / event type / exchange event time / local receive time / raw payload / compact payload / sequence-id / update-id 共 10 字段 | TC-007 |
| AC-014 | 规范化完成后事件进入 canonical mapping 阶段 | TC-007→TC-008 数据流 |

### FR-005: Canonical Mapping

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-015 | Mapper 输出 `*domain_market.MarketEvent`，类型完全依赖 domain_market | TC-008 |
| AC-016 | 映射遇到无法识别 event type 时返回 error，不生成半规范事件 | TC-008 |

### FR-006: Idempotency Key Generation

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-017 | 同一事件两次生成幂等键，结果相同（跨重试稳定） | TC-009 |
| AC-018 | 不同 event type 使用不同 key 策略（trade: trade_id；depth: update_id；bar: open_time+interval） | TC-010 |

### FR-009: natsx Publisher（v2.0.0 — 替代 gRPC Sender）

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-019 | mapper 输出的 `MarketFactEnvelope` 通过 `js.Publish(subj, json)` 发布，等待 PubAck | TC-011, TC-012 |
| AC-020 | subject 格式 `binance.market.{product_line}.{event_type}`，均小写 | TC-011: 验证 subject 参数 |
| AC-021 | PubAck 同步等待成功后 Publish 返回 nil（不 fire-and-forget） | TC-012: mock PubAck 阻塞验证 |
| AC-022 | JetStream 不可达或超时时 Publish 返回 error，由调用方决定重试 | TC-013: mock 超时 → error |
| AC-023 | Publisher 不导入 `internal/server`、`internal/cs` 或任何 server 类型 | CI-BOUNDARY-SERVER gate |

### FR-010: Admin Surface

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-024 | `/healthz` 返回 client 进程健康状态 200 | TC-014 |
| AC-025 | `/readyz` 返回 client 就绪状态 | TC-014 |
| AC-026 | `/debug/*` 返回只读 pprof 调试信息 | TC-014 |
| AC-027 | `/admin/*` 提供：list product lines / pause-resume / show natsx stats / catalog reload | TC-015 |
| AC-028 | Admin 变更操作不修改 server 状态 / 不暴露 secrets / 不触发交易动作 | TC-015 |

---

## §6 覆盖率仪表盘

| 指标 | 计数 | 覆盖率 |
|------|:----:|:------:|
| FR 总数（活跃，不含归档 FR-007/008） | 8 | — |
| BR 总数（活跃，不含归档 BR-001/002） | 5 | — |
| NFR 总数 | 14 | — |
| TC 总数 | 15 | — |
| CI Gate | 4 | — |
| AC 总数 | 28 | — |
| FR→TC 映射率 | 8 / 8 | 100% |
| BR→验证映射率 | 5 / 5 | 100% |
| TC→FR 回溯率 | 15 / 15 | 100% |
| AC→验证映射率 | 28 / 28 | 100% |
| 实现完成率 | 0 / 8 FR | 0%（文档对齐 v2.1.1，代码待实现） |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-16 | v1.0.0 | 初始版本：从 client SPEC.md v1.0.0 提取 FR/BR/NFR/TC/AC | ZoneCNH |
| 2026-06-17 | v1.1.0 | §1 FR 命名空间统一，BNC-CLIENT-### → FR-001~010 | ZoneCNH |
| 2026-06-17 | v1.2.0 | 同步 SPEC v1.0.1 Status 晋升 | ZoneCNH |
| 2026-06-21 | v2.0.0 | **v2.0.0 分布式架构对齐**：归档 FR-007（SQLite spool）+ FR-008（checkpoint）+ BR-001/002（spool/checkpoint 约束）；FR-009 重写为 natsx Publisher（替代 gRPC bidi stream）；新增 BR-006（PubAck 同步等待）+ BR-007（禁止同进程）；NFR 删除 spool/gRPC 延迟，新增 natsx PubAck 预算；TC-011~013 替换为 natsx publisher 测试；AC 从 38 条精简为 28 条（归档 spool/checkpoint AC）；CI Gate 更新为 cs 包/同进程禁止检查 | ZoneCNH |
| 2026-06-22 | v2.1.1 | 命名同步：两套旧合约别名收敛到 `um_perp/cm_perp`（catalog enum + go 文件名 + TC-003）；Spec-Reference 指向 client/SPEC.md v2.1.1 | ZoneCNH |
