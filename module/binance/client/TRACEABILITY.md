# module/binance/client TRACEABILITY

> 追溯矩阵 §1–§7，符合 `docs/governance/TRACEABILITY.md` 标准格式。
> 数据来源：`module/binance/client/SPEC.md` v1.0.0（23 节）。

Last-Updated: 2026-06-17

---

## §1 FR 追溯表

> FR ID 与 SPEC §7 对齐（FR-001 ~ FR-010）。Task 列引用 `module/binance/client/tasks/TASK-BINANCE-CLIENT-NNN`。FR-003 (Product-Line Connectors) 涵盖 4 个 connector 实现单元，对应 4 个 task。

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|:--------:|
| FR-001 | Product-Line Catalog：维护 Binance 四产品线目录，每条独立启停，支持热重载 | AC-001~004 | TC-001 | TASK-BINANCE-CLIENT-001 | ⬜ Pending |
| FR-002 | Instrument Parser：解析 Binance 原生 symbol 为规范身份组件，消除跨产品线身份碰撞 | AC-005~007 | TC-002, TC-003, TC-004 | TASK-BINANCE-CLIENT-002 | ⬜ Pending |
| FR-003 | Product-Line Connectors：Spot/USDⓈ-M/COIN-M/Options 4 个 connector，统一格式内部事件流，断线重连/限速感知/优雅关闭 | AC-008~012 | TC-005, TC-006 | TASK-BINANCE-CLIENT-003, 004, 005, 006 | ⬜ Pending |
| FR-004 | Raw Event Normalization：规范化原始事件，保留完整溯源（10 字段：product_line/symbol/event type/times/sequence-ids 等） | AC-013, AC-014 | TC-007 | TASK-BINANCE-CLIENT-007 | ⬜ Pending |
| FR-005 | Canonical Mapping：映射规范化事件为 domain-market 类型，无法识别 event type 返回错误 | AC-015, AC-016 | TC-008 | TASK-BINANCE-CLIENT-007 | ⬜ Pending |
| FR-006 | Idempotency Key Generation：跨重试稳定，按 event type 差异化策略 | AC-017, AC-018 | TC-009, TC-010 | TASK-BINANCE-CLIENT-007 | ⬜ Pending |
| FR-007 | Spool：SQLite 发送前持久化 + 状态机约束 + 重启恢复 | AC-019~024 | TC-011, TC-012 | TASK-BINANCE-CLIENT-009 | ⬜ Pending |
| FR-008 | Checkpoint：仅 server 持久 ACK 后推进，重启从 checkpoint 恢复 | AC-025~027 | TC-013, TC-014 | TASK-BINANCE-CLIENT-009 | ⬜ Pending |
| FR-009 | gRPC Sender：流式发送 IngestRequest，处理重连/背压/部分 ACK/reject 分类/spool 清理 | AC-028~033 | TC-015, TC-016 | TASK-BINANCE-CLIENT-008 | ⬜ Pending |
| FR-010 | Admin Surface：Gin HTTP 端点（healthz/readyz/debug/admin），仅操作本地状态 | AC-034~038 | TC-017, TC-018 | TASK-BINANCE-CLIENT-010 | ⬜ Pending |

> 历史 BNC-CLIENT-### 命名空间已废弃（v0 遗留）。原 BNC-CLIENT-014 (C/S contract tested) 与 BNC-CLIENT-015 (Boundary gates) 是测试覆盖与 BR 验证项，非 FR — 已分别归入 §4 TC-015/016 与 §2 BR-003/004 验证条目。
> AC 完整定义见 §5 AC 注册表（按 FR 分组，AC-001~038 共 38 条）。

## §2 BR 追溯表

| BR ID | 业务规则 | SPEC §8 Ref | 验证方式 | 实现状态 |
|-------|---------|-------------|----------|:--------:|
| BR-001 | Checkpoint 仅在 server 持久 ACK 后推进；禁止在序列化成功/本地入队成功/gRPC 写成功/发送尝试成功时推进 | BR-001 | TC-013（ACK 后推进）、TC-014（未 ACK 不变）、CI Gate: Checkpoint 安全测试 (`TestCheckpointSafety`) | ⬜ Pending |
| BR-002 | Spool 状态机仅允许 5 条合法转换路径：pending→sending / pending→failed_terminal / sending→acked / sending→failed_retryable / failed_retryable→sending；禁止 acked→sending / failed_terminal→sending / pending→acked | BR-002 | TC-012（非法状态转换返回错误）、CI Gate: Spool 状态机测试 (`TestSpoolStateMachine`) | ⬜ Pending |
| BR-003 | Client Go import 图不得出现 `module/binance/server` 的任何包 | BR-003 | CI Gate: `go list -deps ./... \| grep -q 'binance/server' && exit 1 \|\| exit 0` | ⬜ Pending |
| BR-004 | Client Go import 图不得出现 `storage/`、`query/`、`strategy/` 包 | BR-004 | CI Gate: `go list -deps ./... \| grep -qE 'storage/\|query/\|strategy/' && exit 1 \|\| exit 0` | ⬜ Pending |
| BR-005 | 同一 symbol 在不同产品线中必须产生不同的规范身份（BTCUSDT Spot ≠ BTCUSDT USDⓈ-M Perpetual ≠ …） | BR-005 | TC-002（Spot 身份）、TC-003（USDⓈ-M 身份）、TC-004（Options 身份）；mapper 层检测碰撞并拒绝映射 | ⬜ Pending |

> BR-003/BR-004 为 CI Gate 级验证，不绑定 TC 编号。BR-005 同时覆盖 TC 和 mapper 层双重验证。

---

## §3 NFR 追溯表

### 3.1 性能预算（来源：SPEC §17）

| NFR ID | 非功能需求 | 目标 | 测量方式 | 实现状态 |
|--------|-----------|------|----------|:--------:|
| NFR-P01 | 事件规范化延迟 | P99 < 1ms | `go test -bench` | ⬜ Pending |
| NFR-P02 | 事件映射延迟 | P99 < 500μs | `go test -bench` | ⬜ Pending |
| NFR-P03 | 幂等键生成延迟 | P99 < 100μs | `go test -bench` | ⬜ Pending |
| NFR-P04 | Spool 写入延迟 | P99 < 5ms | `go test -bench` | ⬜ Pending |
| NFR-P05 | Spool ACK 更新延迟 | P99 < 2ms | `go test -bench` | ⬜ Pending |
| NFR-P06 | gRPC 发送吞吐 | > 1000 events/s | benchmark | ⬜ Pending |
| NFR-P07 | Admin `/healthz` 延迟 | P99 < 1ms | benchmark | ⬜ Pending |
| NFR-P08 | 单 connector 采集吞吐 | > 500 events/s | 集成 benchmark | ⬜ Pending |
| NFR-P09 | Client 内存稳态 | < 256MB | `go test -benchmem` long-running test | ⬜ Pending |

### 3.2 可观测性（来源：SPEC §18）

| NFR ID | 非功能需求 | 说明 | 验证方式 | 实现状态 |
|--------|-----------|------|----------|:--------:|
| NFR-O01 | Metrics 导出 | 12 个 Prometheus 指标（counter/gauge），按 product_line 标注，前缀 `binance_client_` | observex 集成；metrics endpoint 可查询 | ⬜ Pending |
| NFR-O02 | Structured logging | 所有日志含 product_line + stream_id；按级别可选含 raw_symbol / instrument_key / idempotency_key / checkpoint_position；12 种日志事件覆盖 info/warn/debug/error | observex 集成；log inspection | ⬜ Pending |

### 3.3 安全（来源：SPEC §19）

| NFR ID | 非功能需求 | 验证方式 | 实现状态 |
|--------|-----------|----------|:--------:|
| NFR-S01 | 不硬编码 API Key / Secret Key / 任何凭证 | CI Gate: gitleaks；代码审查 | ⬜ Pending |
| NFR-S02 | 不在日志中记录 API Key / Secret Key / 签名原文 | 日志格式审查；敏感字段脱敏验证 | ⬜ Pending |
| NFR-S03 | Admin 端点不暴露 secrets | 端点输出审查 | ⬜ Pending |
| NFR-S04 | Admin 变更操作仅允许本地访问（绑定 `127.0.0.1`） | 配置审查；集成测试 | ⬜ Pending |
| NFR-S05 | gRPC 通信使用 TLS（生产环境） | 配置审查 | ⬜ Pending |
| NFR-S06 | Catalog reload 输入校验，防注入非法 product_line 配置 | TC-001（catalog 加载）；模糊测试 | ⬜ Pending |
| NFR-S07 | Spool 文件权限设为 `0600`（仅 owner 可读写） | 文件权限检查；CI 自动化验证 | ⬜ Pending |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 场景摘要 | 状态 |
|-------|-----------|-----------|:--------:|---------|:----:|
| TC-001 | FR-001 | — | 单元 | 加载包含 4 条产品线的 catalog，验证 4 条均加载且状态正确 | ⬜ Pending |
| TC-002 | FR-002 | BR-005 | 单元 | 解析 `BTCUSDT` + `product_line=spot` → 返回 Spot 身份，非 USDⓈ-M | ⬜ Pending |
| TC-003 | FR-002 | BR-005 | 单元 | 解析 `BTCUSDT` + `product_line=usdm_futures` → 返回 USDⓈ-M 永续身份 | ⬜ Pending |
| TC-004 | FR-002 | BR-005 | 单元 | 解析 `BTC-240628-50000-C` → 返回 Options Call 身份 | ⬜ Pending |
| TC-005 | FR-003 | — | 集成 | Spot connector 连接并接收事件，验证 product_line=spot | ⬜ Pending |
| TC-006 | FR-003 | — | 集成 | Connector 断开后自动重连，事件流继续 | ⬜ Pending |
| TC-007 | FR-004 | — | 单元 | 规范化原始 trade 事件，验证输出包含完整溯源字段 | ⬜ Pending |
| TC-008 | FR-005 | — | 单元 | 映射规范化事件到 domain-market 类型，输出 `*domain_market.MarketEvent` | ⬜ Pending |
| TC-009 | FR-006 | — | 单元 | 同一事件两次生成幂等键，验证两次 key 相同 | ⬜ Pending |
| TC-010 | FR-006 | — | 单元 | 不同 event type 使用不同 key 策略，验证 key 格式符合各 type 预期 | ⬜ Pending |
| TC-011 | FR-007 | BR-002 | 单元 | 写入 spool → 状态 pending；重启恢复 pending/failed_retryable 事件 | ⬜ Pending |
| TC-012 | FR-007 | BR-002 | 单元 | 非法状态转换被拦截，返回错误 | ⬜ Pending |
| TC-013 | FR-008 | BR-001 | 单元 | 收到 ACK 后 checkpoint 推进到 ACK 位置 | ⬜ Pending |
| TC-014 | FR-008 | BR-001 | 单元 | 未 ACK 时 checkpoint 停留在原位 | ⬜ Pending |
| TC-015 | FR-009 | — | 集成 | Sender 发送事件到 mock server，server 收到事件 | ⬜ Pending |
| TC-016 | FR-009 | — | 集成 | Sender 重连，事件从 checkpoint 恢复，无重复 | ⬜ Pending |
| TC-017 | FR-010 | — | 单元 | `/healthz` 返回 HTTP 200 | ⬜ Pending |
| TC-018 | FR-010 | — | 单元 | Admin pause 某产品线，connector 停止产生新事件 | ⬜ Pending |

### 4.1 CI Gate 专用验证

| Gate ID | 覆盖 BR(s) | 命令 | 通过条件 | 状态 |
|---------|-----------|------|----------|:----:|
| CI-BOUNDARY-SERVER | BR-003 | `go list -deps ./... \| grep -q 'binance/server' && exit 1 \|\| exit 0` | 零匹配 | ⬜ Pending |
| CI-BOUNDARY-STORAGE | BR-004 | `go list -deps ./... \| grep -qE 'storage/\|query/\|strategy/' && exit 1 \|\| exit 0` | 零匹配 | ⬜ Pending |
| CI-SPOOL-FSM | BR-002 | `go test -run TestSpoolStateMachine ./...` | 全部通过 | ⬜ Pending |
| CI-CHECKPOINT-SAFETY | BR-001 | `go test -run TestCheckpointSafety ./...` | 全部通过 | ⬜ Pending |
| CI-IDEMPOTENCY-STABILITY | FR-006 | `go test -run TestIdempotencyKeyStability ./...` | 全部通过 | ⬜ Pending |

---

## §5 AC 注册表

### FR-001 / BNC-CLIENT-001: Product-Line Catalog

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-001 | Client 启动时加载全部 4 条产品线（Spot / USDⓈ-M / COIN-M / Options） | TC-001 |
| AC-002 | 每条产品线可独立配置启用/禁用 | TC-001 |
| AC-003 | Catalog reload 不中断已启用产品线的活跃连接 | TC-001 |
| AC-004 | 查询 catalog entry 返回完整 18 字段（exchange/product_line/instrument_type/symbol/base_asset/quote_asset/margin_asset/settlement_asset/expiry/strike/option_type/contract_code/price_precision/quantity_precision/status） | TC-001 |

### FR-002 / BNC-CLIENT-002: Instrument Parser

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-005 | Parser 区分 BTCUSDT Spot / BTCUSDT USDⓈ-M Perpetual / BTCUSD COIN-M Perpetual / BTC-YYYYMMDD-STRIKE-C / BTC-YYYYMMDD-STRIKE-P 五种身份 | TC-002, TC-003, TC-004 |
| AC-006 | 不可解析 symbol 返回错误，不产生歧义映射 | TC-002 |
| AC-007 | Parser 输出作为 domain-market 规范类型输入，不自定义规范枚举 | TC-008 |

### FR-003 / BNC-CLIENT-003~006: Product-Line Connectors

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-008 | 启用产品线时对应 connector 启动连接并开始采集 | TC-005 |
| AC-009 | 连接断开后 connector 自动重连并恢复订阅 | TC-006 |
| AC-010 | 收到交易所限速响应时以限速感知策略恢复 | TC-006 |
| AC-011 | 收到原始事件时捕获原始 payload、本地时间戳、product_line，输出统一格式内部事件流 | TC-005 |
| AC-012 | 禁用产品线时 connector 优雅关闭，不再产生新事件 | TC-018 |

### FR-004 / BNC-CLIENT-012: Raw Event Normalization

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-013 | 规范化事件保留 product_line / source stream / raw symbol / event type / exchange event time / local receive time / raw payload reference / compact payload / sequence-id / update-id 共 10 字段 | TC-007 |
| AC-014 | 规范化完成后事件进入 canonical mapping 阶段 | TC-007 → TC-008 数据流 |

### FR-005 / BNC-CLIENT-007: Canonical Mapping

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-015 | Mapper 输出 `*domain_market.MarketEvent`，类型系统完全依赖 domain-market | TC-008 |
| AC-016 | 映射遇到无法识别 event type 时返回错误，不生成半规范事件 | TC-008 |

### FR-006 / BNC-CLIENT-013: Idempotency Key Generation

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-017 | 同一事件两次生成幂等键，结果相同（跨重试稳定） | TC-009 |
| AC-018 | 不同 event type 使用不同 key 策略：bar 含 interval/open_time，trade 含 trade_id，depth 含 update_id_range，通用含 exchange/product_line/instrument_key/event_type/event_time | TC-010 |

### FR-007 / BNC-CLIENT-009: Spool

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-019 | 事件生成幂等键后写入 SQLite spool，状态为 pending | TC-011 |
| AC-020 | 正常路径状态转换：pending → sending → acked | TC-011 |
| AC-021 | 重试路径：pending → sending → failed_retryable → sending | TC-011 |
| AC-022 | 终端路径：pending → sending → failed_terminal（超过 `max_retry_per_event` 或永久拒绝） | TC-011 |
| AC-023 | 非法状态转换（acked→sending / failed_terminal→sending / pending→acked）被 spool 层拒绝 | TC-012 |
| AC-024 | 进程重启后 spool 中所有 pending 和 failed_retryable 事件恢复为可发送状态 | TC-011 |

### FR-008 / BNC-CLIENT-010: Checkpoint

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-025 | Checkpoint 仅在收到 server 持久 ACK 后推进到已确认位置 | TC-013 |
| AC-026 | 序列化成功 / 本地入队成功 / gRPC 写成功 / 发送尝试成功均不推进 checkpoint | TC-014 |
| AC-027 | Client 重启后从 checkpoint 位置恢复发送 | TC-013 |

### FR-009 / BNC-CLIENT-008: gRPC Sender

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-028 | Spool 中有待发送事件时 sender 流式发送 IngestRequest 到 server | TC-015 |
| AC-029 | 连接断开后 sender 自动重连并恢复流 | TC-016 |
| AC-030 | 遇到背压时 sender 减速发送，不丢弃事件 | TC-015 |
| AC-031 | 收到部分 ACK 时仅确认对应事件的 spool 状态和 checkpoint | TC-015 |
| AC-032 | 收到 reject 时分 retryable（→ failed_retryable）和 terminal（→ failed_terminal）两类处理 | TC-015 |
| AC-033 | ACK 确认后按清理策略回收 spool 空间 | TC-015 |

### FR-010 / BNC-CLIENT-011: Admin Surface

| AC ID | 验收标准 | 验证方式 |
|-------|---------|----------|
| AC-034 | `/healthz` 返回 client 进程健康状态 | TC-017 |
| AC-035 | `/readyz` 返回 client 就绪状态 | TC-017 |
| AC-036 | `/debug/*` 返回 pprof 调试信息 | TC-017 |
| AC-037 | `/admin/*` 提供本地管理操作：list enabled product lines / list active streams / pause-resume product-line / show spool stats / show checkpoint stats / trigger safe catalog reload | TC-018 |
| AC-038 | Admin 变更操作不修改 server 状态 / 不删除 checkpoint（非受保护显式操作）/ 不暴露 secrets / 不触发交易动作 | TC-018 |

> **AC 总数**：38 条（AC-001 ~ AC-038），覆盖 SPEC §7 全部 10 个 FR。

---

## §6 覆盖率仪表盘

| 指标 | 计数 | 覆盖率 |
|------|:----:|:------:|
| FR 总数（§1，与 SPEC §7 对齐） | 10 | — |
| BR 总数（§2） | 5 | — |
| NFR 总数（§3） | 18 | — |
| 性能 NFR | 9 | — |
| 可观测性 NFR | 2 | — |
| 安全 NFR | 7 | — |
| TC 总数（§4） | 18 | — |
| CI Gate 专用验证（§4.1） | 5 | — |
| AC 总数（§5） | 38 | — |
| FR→TC 映射率 | 10 / 10 | 100% |
| BR→验证映射率 | 5 / 5 | 100% |
| TC→FR 回溯率 | 18 / 18 | 100% |
| AC→验证映射率 | 38 / 38 | 100% |
| 实现完成率 | 0 / 38 | 0% |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-06-16 | v1.0.0 | 初始版本：从 client SPEC.md v1.0.0（23 节）提取全部 FR/BR/NFR/TC/AC，按 `docs/governance/TRACEABILITY.md` 标准格式重写为 §1–§7。保留 v0 BNC-CLIENT-001~013 ID 作为主键，补全原缺失的 FR-004（BNC-CLIENT-012）和 FR-006（BNC-CLIENT-013）行，新增 BNC-CLIENT-014~015 覆盖 C/S contract test 和 boundary gates。修正 TC 总数 16→18（补 TC-017/TC-018 覆盖 FR-010 全部 admin 端点）。 | ZoneCNH |
| 2026-06-17 | v1.1.0 | **§1 FR 命名空间统一**：(1) 主键从 BNC-CLIENT-001~015 改为 FR-001~010，与 SPEC §7 严格对齐；(2) 删除孤儿 BNC-CLIENT-014/015（非 FR — 是测试覆盖与 BR 验证项，已归入 §4 TC-015/016 与 §2 BR-003/004 验证）；(3) FR-003 涵盖 4 个 connector 实现，Task 列引用 4 个 task；(4) §6 仪表盘 FR 总数 15→10，删除冗余 "FR 对应 SPEC §7 功能需求" 行 | ZoneCNH |
| 2026-06-17 | v1.2.0 | **同步 SPEC v1.0.1 Status 晋升**：跟随 client SPEC Status Review → Approved 晋升。本版仅同步 SPEC 引用版本号与状态，FR/BR/AC/TC 主体未变，覆盖率保持 100% | ZoneCNH |
