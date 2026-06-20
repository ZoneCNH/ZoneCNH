# module/binance/server TRACEABILITY

> 追溯矩阵版本：v1.1.1 | 最后更新：2026-06-17 | 对应 server SPEC v1.0.1

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | 实现状态 |
|-------|----------|-----|----------|:--------:|
| FR-001 | gRPC Server Binding — 实现 contracts-defined ingest server | server 注册并监听，接受 `MarketDataService.Ingest` 双向流 | TC-001 | ⬜ |
| FR-002 | Stream Lifecycle — 管理 stream 生命周期 | 启动/正常关闭/异常断开时清理；最终统计输出 | TC-002 | ⬜ |
| FR-003 | Request Validation — 验证 envelope/payload/domain enum | 缺字段→terminal_validation；不支持 product_line→terminal_validation；payload 不匹配→terminal_validation | TC-003, TC-004 | ⬜ |
| FR-004 | Idempotent Acceptance — 同一 key 最多 accept 一次 | 首次→accept+dispatch；重复同内容→idempotent ACK；重复冲突内容→terminal_conflict | TC-005, TC-006, TC-007 | ⬜ |
| FR-005 | Durable Acceptance — accept 后持久化 | durable write 成功→durable_indicator=true；失败→retryable reject（不标记已接受） | TC-008, TC-009 | ⬜ |
| FR-006 | ACK Generation — 返回可驱动 client checkpoint 的 ACK | ACK 含 stream_id/accepted keys/rejects/durable indicator/retry hint | TC-010 | ⬜ |
| FR-007 | Downstream Dispatch — 分发至 market_data downstream port | dispatch 成功→event 被下游接受；不实现物理存储；不暴露 query API | TC-011, TC-012 | ⬜ |
| FR-008 | Admin HTTP Endpoints — /healthz /readyz /debug /admin | healthz 200；readyz 反映 readiness；debug 只读；admin 仅 server-local；/admin/drain 拒绝新 stream | TC-013, TC-014, TC-015 | ⬜ |

> 映射：BNC-SERVER-001→FR-001, BNC-SERVER-002→FR-003, BNC-SERVER-003→FR-004, BNC-SERVER-004→FR-006, BNC-SERVER-005→FR-007, BNC-SERVER-006→FR-008, BNC-SERVER-007→contract tests, BNC-SERVER-008→boundary gates

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | 实现状态 |
|-------|----------|----------|:--------:|
| BR-001 | Idempotency Key — Accept At Most Once | integration test: 相同 key 两次发送 | ⬜ |
| BR-002 | Duplicate With Conflicting Payload → Reject | integration test: 相同 key 不同 payload | ⬜ |
| BR-003 | ACK Only After Durable Acceptance | integration test: durable write 失败 → 不标记已接受 | ⬜ |
| BR-004 | Validation Failure → No Checkpoint Advancement | unit test: reject 不触发 durable acceptance | ⬜ |
| BR-005 | Admin Surface Isolation — admin 只能操作 server-local 状态 | unit test: admin 不能变更 client/下游/strategy 状态 | ⬜ |
| BR-006 | Server Must Not Import Client Internals | CI gate: `grep -R 'internal/client\|module/binance/client' internal/server cmd/binance-server` | ⬜ |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源(SPEC §) | 验证方式 |
|--------|-----------|-------------|----------|
| NFR-S01 | Validation P99 < 100μs | Performance Budget | `go test -bench` |
| NFR-S02 | Idempotency check P99 < 1ms | Performance Budget | `go test -bench` |
| NFR-S03 | ACK lag P99 < 100ms | Performance Budget | integration test |
| NFR-S04 | Metrics: active streams/ingested/accepted/duplicate/rejected (per reason)/ACK latency/dispatch latency/dispatch failures | Observability | metrics endpoint |
| NFR-S05 | Logs 含 stream_id/product_line/instrument_key/idempotency_key/ack status/reject reason | Observability | log inspection |
| NFR-S06 | No hardcoded secrets | Security | gitleaks |
| NFR-S07 | /debug/* 和 /admin/* 不暴露 secrets | Security | secret redaction test |
| NFR-S08 | Admin auth when exposed outside loopback-only mode | Security | auth test |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 测试类型 | 状态 |
|-------|-----------|----------|:----:|
| TC-001 | FR-001 | 单元 | ⬜ |
| TC-002 | FR-002 | 单元 | ⬜ |
| TC-003 | FR-003 | 单元 | ⬜ |
| TC-004 | FR-003 | 单元 | ⬜ |
| TC-005 | FR-004 | 集成 | ⬜ |
| TC-006 | FR-004 | 集成 | ⬜ |
| TC-007 | FR-004 | 集成 | ⬜ |
| TC-008 | FR-005 | 集成 | ⬜ |
| TC-009 | FR-005 | 集成 | ⬜ |
| TC-010 | FR-006 | 单元 | ⬜ |
| TC-011 | FR-007 | 集成 | ⬜ |
| TC-012 | FR-007 | 集成 | ⬜ |
| TC-013 | FR-008 | 单元 | ⬜ |
| TC-014 | FR-008 | 单元 | ⬜ |
| TC-015 | FR-008 | 单元 | ⬜ |

---

## §5 AC 注册表

| AC ID | 所属 FR/BR | AC 描述 | 验证方式 |
|-------|-----------|---------|----------|
| AC-001 | FR-001 | gRPC server 绑定端口成功 | TC-001 |
| AC-002 | FR-002 | 正常关闭 stream 时清理资源 | TC-002 |
| AC-003 | FR-003 | 缺必填字段→terminal_validation reject | TC-003 |
| AC-004 | FR-003 | 不支持 product_line→terminal_validation reject | TC-004 |
| AC-005 | FR-004 | 首次 key→accept+dispatch | TC-005 |
| AC-006 | FR-004 | 重复 key+相同 payload→idempotent ACK，不 dispatch | TC-006 |
| AC-007 | FR-004 | 重复 key+冲突 payload→terminal_conflict | TC-007 |
| AC-008 | FR-005 | durable write 成功→durable_indicator=true | TC-008 |
| AC-009 | FR-005 | durable write 失败→retryable reject | TC-009 |
| AC-010 | FR-006 | ACK 含所有必要字段，可驱动 checkpoint | TC-010 |
| AC-011 | FR-007 | dispatch 成功→event 被下游接受 | TC-011 |
| AC-012 | FR-007 | dispatch 失败→retry 或 rollback | TC-012 |
| AC-013 | FR-008 | /healthz 返回 200 | TC-013 |
| AC-014 | FR-008 | /readyz（下游不可达）返回 503 | TC-014 |
| AC-015 | FR-008 | /admin/drain 拒绝新 stream | TC-015 |
| AC-016 | BR-001 | Idempotency key accept at most once | TC-005, TC-006 |
| AC-017 | BR-002 | Conflicting payload→terminal_conflict | TC-007 |
| AC-018 | BR-006 | server 代码中无 client internal 引用 | CI gate |

---

## §6 覆盖率仪表盘

| 指标 | 计数 | 覆盖率 |
|------|:----:|:------:|
| 总 FR | 8 | — |
| 总 BR | 6 | — |
| 总 NFR | 8 | — |
| 总 TC | 15 | — |
| 总 AC | 18 | — |
| FR→TC 映射率 | 8 / 8 | 100% |
| BR→验证映射率 | 6 / 6 | 100% |
| TC→FR 回溯率 | 15 / 15 | 100% |
| AC→验证映射率 | 18 / 18 | 100% |
| 实现完成率 | 0 / 37 | 0% |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-06-16 | v1.0.0 | 初始版本：§1-§7 标准追溯矩阵，基于 server SPEC.md v1.0.0 (23节) 生成 |
| 2026-06-17 | v1.1.0 | **R7 AC 命名空间统一**：AC-S01~AC-S18 → AC-001~AC-018（18 处），消除评分器期望的 AC-### 格式偏差。注：§5.1 别名表已在更早的清理中删除，本 PR 仅完成 §1/§5 中 AC 主键与引用的最终统一 | ZoneCNH |
| 2026-06-17 | v1.1.1 | **同步 server SPEC v1.0.1 修订**：跟随 server SPEC §1 Metadata 字段统一（删除头部重复 metadata + Repository 修正为 monorepo `github.com/ZoneCNH/binance` + §14 重写为 `internal/server/` 布局）。本次仅同步 SPEC 引用版本号，FR/BR/AC/TC 主体未变，覆盖率保持 100% | ZoneCNH |
| 2026-06-17 | v1.1.2 | **同步 SPEC v1.0.2 Status 晋升**：跟随 server SPEC Status Review → Approved 晋升。本版仅同步 SPEC 引用版本号与状态，FR/BR/AC/TC 主体未变，覆盖率保持 100% | ZoneCNH |
