# binancex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: `patches/binancex/adapter.go`
Runtime: `github.com/ZoneCNH/runtime-patches/binancex`

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | TC ID(s) | Task | Verification | Status |
| ----- | ----------- | -------- | ---- | ------------ | ------ |
| FR-BX-001 | MarketDataFeed — 定义交易所无关的行情消费接口（Connect/Close/Subscribe/Unsubscribe/Events/Errors） | TC-BX-001 | TASK-BX-001 | `go test ./... -run TestMarketDataFeed` | ✅ |
| FR-BX-002 | FeedEvent — 标准化行情事件结构，含 InstrumentKey/EventType/EventTime/ReceivedAt/Source/SchemaVersion/Payload/Sequence/OrderingKey | TC-BX-002 | TASK-BX-002 | `go test ./... -run TestFeedEvent` | ✅ |
| FR-BX-003 | FeedConfig — 传输层配置（Endpoint/ReconnectBackoff/ReadTimeout/PingInterval/EventBufferSize 等 9 个字段） | TC-BX-003 | TASK-BX-003 | `go test ./... -run TestFeedConfig` | ✅ |
| FR-BX-004 | StreamSpec — 逻辑流订阅描述（InstrumentKey/Channel/Interval） | TC-BX-004 | TASK-BX-004 | `go test ./... -run TestStreamSpec` | ✅ |
| FR-BX-005 | DefaultFeedConfig — 返回生产安全默认值 | TC-BX-005 | TASK-BX-005 | `go test ./... -run TestDefaultFeedConfig` | ✅ |
| FR-BX-006 | Validate — 校验 FeedConfig 必填字段（Endpoint/ReadTimeout/PingInterval/EventBufferSize） | TC-BX-006 | TASK-BX-006 | `go test ./... -run TestFeedConfigValidate` | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
| ----- | ---- | -------- | ---- | ------------ | ------ |
| BR-BX-001 | 交易所无关：同一 MarketDataFeed 契约用于 Binance/Bybit/OKX，实现只包裹 vendor SDK | TC-BX-001 | TASK-BX-007 | interface compliance check | ✅ |
| BR-BX-002 | Events() 和 Errors() 返回只读 channel，消费者不得关闭 | TC-BX-001 | TASK-BX-008 | channel direction check | ✅ |
| BR-BX-003 | FeedConfig.Validate 拒绝空 Endpoint、非正 ReadTimeout/PingInterval/EventBufferSize | TC-BX-006 | TASK-BX-009 | validation test | ✅ |
| BR-BX-004 | 传输层（SDK adapter）与 ingest 逻辑（binance/server）清晰分离 | TC-BX-001 | TASK-BX-007 | package boundary check | ✅ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Verification | Status |
| ------ | -------- | ----------- | ---- | ------------ | ------ |
| NFR-BX-001 | 可测试性 | 接口设计支持 mock 实现，无需真实 WebSocket 连接即可测试 ingest pipeline | TASK-BX-010 | `go test ./... -count=1` | ✅ |
| NFR-BX-002 | 依赖边界 | 仅依赖 stdlib + `runtime-patches/domain-market`，不引入第三方 SDK | TASK-BX-011 | `go list -deps` | ✅ |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-BX-001 | FR-BX-001, BR-BX-001, BR-BX-002, BR-BX-004 | `go test ./... -run TestMarketDataFeed` |
| TC-BX-002 | FR-BX-002 | `go test ./... -run TestFeedEvent` |
| TC-BX-003 | FR-BX-003 | `go test ./... -run TestFeedConfig` |
| TC-BX-004 | FR-BX-004 | `go test ./... -run TestStreamSpec` |
| TC-BX-005 | FR-BX-005 | `go test ./... -run TestDefaultFeedConfig` |
| TC-BX-006 | FR-BX-006, BR-BX-003 | `go test ./... -run TestFeedConfigValidate` |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-BX-001 | FR-BX-001 | MarketDataFeed 接口含 6 个方法，编译期通过接口合规检查 | TC-BX-001 | ✅ |
| AC-BX-002 | FR-BX-002 | FeedEvent 含全部 11 个字段，使用 canonical domainmarket 类型 | TC-BX-002 | ✅ |
| AC-BX-003 | FR-BX-003~005 | FeedConfig 9 字段 + DefaultFeedConfig 非零默认值 | TC-BX-003, TC-BX-005 | ✅ |
| AC-BX-004 | FR-BX-006 | Validate 拒绝空 Endpoint 和 0 值 timeout/buffer | TC-BX-006 | ✅ |
| AC-BX-005 | BR-BX-001~004 | 接口边界不泄露 vendor SDK 类型，channel 方向正确 | TC-BX-001 | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 6 | 6 | 100% |
| BR (业务规则) | 4 | 4 | 100% |


| NFR (非功能需求) | 2 | 2 | 100% |
| AC (验收标准) | 5 | 5 | 100% |
| TC (测试用例) | 6 | 6 | 100% |
| **合计** | **23** | **23** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 `patches/binancex/adapter.go` 提取 FR/BR/NFR，创建完整 §1-§7 追溯矩阵 |
