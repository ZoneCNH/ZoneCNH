# kafkax 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: module/kafkax/SPEC.md (v1.1.1)

## §1 功能需求追溯 (FR)

| FR ID | Requirement | AC ID(s) | TC ID(s) | Task | Verification | Status |
|-------|-------------|----------|----------|------|-------------|--------|
| FR-001 | Producer.Send — Kafka 可用时发送成功返回 nil；不可用时按 retry 重试后失败返回包装错误；value nil 或 topic 为空返回 ErrInvalidMessage；ctx 取消返回 ctx.Err() | AC-001 | TC-001, TC-004 | TASK-KAFKA-001 | `go test -race -run=ProducerSend ./...` | ✅ |
| FR-002 | Producer.SendBatch — 有效批次全部发送返回 nil；部分失败返回第一个可诊断错误且不回滚；空列表返回 nil；ctx 取消返回 ctx.Err() | AC-002 | TC-002, TC-004 | TASK-KAFKA-002 | `go test -race -run=SendBatch ./...` | ✅ |
| FR-003 | Consumer.Subscribe — 正常连接加入消费组返回 nil；topics 为空返回错误；已订阅返回 ErrAlreadySubscribed | AC-003 | TC-001, TC-006 | TASK-KAFKA-003 | `go test -race -run=Subscribe ./...` | ✅ |
| FR-004 | Consumer.Poll — 有新消息返回 *Message；无消息阻塞至 ctx 超时/取消；未订阅返回 ErrNotSubscribed；反序列化失败返回可分类错误且不自动提交 offset | AC-004 | TC-001, TC-007 | TASK-KAFKA-004 | `go test -race -run=Poll ./...` | ✅ |
| FR-005 | Consumer.Commit — 有效消息提交 offset 返回 nil；nil 或非法 offset 返回 ErrInvalidMessage；commit 失败返回 ErrCommitFailed；ctx 取消返回 ctx.Err() | AC-005 | TC-003, TC-008 | TASK-KAFKA-005 | `go test -race -run=Commit ./...` | ✅ |
| FR-006 | Health — Kafka metadata 成功返回 {Ready:true, Live:true}；不可达返回 {Ready:false, Live:false} 及错误上下文 | AC-006 | TC-005 | TASK-KAFKA-006 | `go test -race -run=Health ./...` | ✅ |

## §2 业务规则追溯 (BR)

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
|-------|------|----------|------|--------------|--------|
| BR-001 | Producer 默认同步发送且 acks=all；非法 acks 在构造或首次发送前返回配置错误；默认值不得静默降级 | TC-001, TC-009 | TASK-KAFKA-007 | unit test | ✅ |
| BR-002 | Consumer 默认手动 offset 提交 (at-least-once)；自动提交不得作为默认值；需调用方显式 Commit | TC-003, TC-010 | TASK-KAFKA-008 | unit + integration | ✅ |
| BR-003 | 所有运行时操作 (Send/SendBatch/Subscribe/Poll/Commit/Close/Health) 接受 context.Context；ctx 取消必须返回 ctx.Err() 或包装错误 | TC-007, TC-011 | TASK-KAFKA-009 | unit | ✅ |
| BR-004 | Consumer Close(ctx) 处理最终 offset/资源释放边界；失败返回错误且不吞错；重复调用不 panic | TC-008, TC-012 | TASK-KAFKA-010 | unit | ✅ |
| BR-005 | Producer 重试策略可配置且默认 3 次；负数或非法重试配置返回配置错误；最终失败返回包装错误并记录指标 | TC-004, TC-009 | TASK-KAFKA-011 | unit | ✅ |
| BR-006 | Consumer max_poll_records、session_timeout、heartbeat_interval 合法性校验；非法值返回配置错误 | TC-006, TC-009 | TASK-KAFKA-012 | unit | ✅ |
| BR-007 | Health(ctx) 幂等且无副作用；多次调用不改变订阅、offset、连接生命周期；错误可重复观察 | TC-005 | TASK-KAFKA-013 | unit | ✅ |
| BR-008 | 错误消息不包含消息内容 (value/payload)；日志和错误必须脱敏；发现 payload/凭据泄露视为安全阻断 | TC-013 | TASK-KAFKA-014 | unit | ✅ |
| BR-009 | Consumer 不自动提交 offset；enable_auto_commit 默认 false；未显式 Commit 不得提交 offset | TC-003, TC-010 | TASK-KAFKA-015 | unit + integration | ✅ |

## §3 非功能需求追溯 (NFR)

| NFR ID | Category | Requirement | Task | Verification | Status |
|--------|----------|-------------|------|-------------|--------|
| NFR-001 | Performance | 单条发送 < 5ms | TASK-KAFKA-016 | `go test -bench=BenchmarkProducerSend ./...` | ✅ |
| NFR-002 | Performance | 批量发送 100 条 < 20ms | TASK-KAFKA-017 | `go test -bench=BenchmarkSendBatch ./...` | ✅ |
| NFR-003 | Performance | 单条消费 < 5ms | TASK-KAFKA-018 | `go test -bench=BenchmarkConsumerPoll ./...` | ✅ |
| NFR-004 | Resource | 常驻内存 (空闲) < 10MB | TASK-KAFKA-019 | profiling | ✅ |
| NFR-005 | Resource | Consumer lag < 1000 条 | TASK-KAFKA-020 | integration test | ✅ |
| NFR-006 | Quality | 单元测试覆盖率 >= 80% | TASK-KAFKA-021 | `go tool cover -func=.coverage/cover.out` | ✅ |
| NFR-007 | Quality | race 检测通过，零 data race | TASK-KAFKA-022 | `go test -race ./...` | ✅ |
| NFR-008 | Quality | vet 检查通过，零警告 | TASK-KAFKA-023 | `go vet ./...` | ✅ |
| NFR-009 | Quality | lint 检查通过，零错误 | TASK-KAFKA-024 | `golangci-lint run` | ✅ |
| NFR-010 | Security | Secret 扫描通过，零命中 | TASK-KAFKA-025 | `gitleaks detect --no-git` | ✅ |

## §4 TC→FR 反向追溯

| TC ID | Covers FR(s) | Command |
|-------|-------------|---------|
| TC-001 | FR-001, FR-003, BR-001 | `go test -race -run="ProducerSend|Subscribe" ./...` |
| TC-002 | FR-002 | `go test -race -run=SendBatch ./...` |
| TC-003 | FR-005, BR-002, BR-009 | `go test -race -run="Commit|ManualOffset" ./...` |
| TC-004 | FR-001, FR-002, BR-005 | `go test -race -run="Retry|Send" ./...` |
| TC-005 | FR-006, BR-007 | `go test -race -run=Health ./...` |
| TC-006 | FR-003, BR-006 | `go test -race -run=Subscribe ./...` |
| TC-007 | FR-004, BR-003 | `go test -race -run="Poll|Context" ./...` |
| TC-008 | FR-005, BR-004 | `go test -race -run=Commit ./...` |
| TC-009 | BR-001, BR-005, BR-006 | `go test -race -run=Config ./...` |
| TC-010 | BR-002, BR-009 | `go test -race -run=AutoCommit ./...` |
| TC-011 | BR-003 | `go test -race -run=Context ./...` |
| TC-012 | BR-004 | `go test -race -run=Close ./...` |
| TC-013 | BR-008 | `go test -race -run=Sanitize ./...` |

## §5 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
|-------|-----------|-----------|-------------|--------|
| AC-001 | FR-001 | Send 在 Kafka 可用时发送成功返回 nil；不可用或 value nil 时返回错误 | unit test | ✅ |
| AC-002 | FR-002 | SendBatch 有效批次全部发送；部分失败返回第一个错误；空列表返回 nil | unit test | ✅ |
| AC-003 | FR-003 | Subscribe 正常连接加入消费组；空 topics 或重复订阅返回错误 | unit test | ✅ |
| AC-004 | FR-004 | Poll 有消息返回消息；无消息阻塞至 ctx 超时；未订阅返回错误 | unit test | ✅ |
| AC-005 | FR-005 | Commit 有效消息提交 offset；nil 或非法 offset 返回错误 | unit test | ✅ |
| AC-006 | FR-006 | Health 在 Kafka 可达时返回 ready/live；不可达返回 unhealthy 及错误 | unit test | ✅ |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | Partial | Pending | 覆盖率 |
|------|:---:|:---:|:-------:|:-------:|:------:|
| FR | 6 | 6 | 0 | 0 | 100% |
| BR | 9 | 9 | 0 | 0 | 100% |
| NFR | 10 | 10 | 0 | 0 | 100% |
| AC | 6 | 6 | 0 | 0 | 100% |
| TC | 13 | 13 | 0 | 0 | 100% |
| **合计** | **44** | **44** | **0** | **0** | **100%** |

| 门禁 | 状态 |
|------|:----:|
| FR 验证链路闭合 | ✅ 6/6 |
| BR 验证链路闭合 | ✅ 9/9 |
| NFR 验证链路闭合 | ✅ 10/10 |
| AC→FR 映射完整 | ✅ 6/6 |
| TC→FR 反向追溯完整 | ✅ 13/13 |
| Task 列已填充 | ✅ 25/25 |

## §7 变更历史

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-06-29 | 补齐 Task 列、§6 覆盖率仪表盘、§7 变更历史；Goal 管线对齐 | Claude |
| 2026-06-21 | 初始追溯矩阵创建 | Zone |
