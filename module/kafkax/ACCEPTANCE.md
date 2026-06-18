# kafkax 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.2
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/kafkax
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 kafkax 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/kafkax/FEATURES.md && test -f module/kafkax/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/kafkax | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/kafkax && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/kafkax && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/kafkax && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/kafkax && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/kafkax && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | Send 在 Kafka 可用时发送成功返回 nil；不可用或 value nil 时返回错误 / unit test | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 | SendBatch 有效批次全部发送；部分失败返回第一个错误；空列表返回 nil / unit test | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 | Subscribe 正常连接加入消费组；空 topics 或重复订阅返回错误 / unit test | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | Poll 有消息返回消息；无消息阻塞至 ctx 超时；未订阅返回错误 / unit test | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 | Commit 有效消息提交 offset；nil 或非法 offset 返回错误 / unit test | ✅ | TRACEABILITY.md |
| AC-006 | FR-006 | Health 在 Kafka 可达时返回 ready/live；不可达返回 unhealthy 及错误 / unit test | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-003, BR-001 | go test -race -run="ProducerSend / Subscribe" ./... | - | TRACEABILITY.md |
| TC-002 | FR-002 | go test -race -run=SendBatch ./... | - | TRACEABILITY.md |
| TC-003 | FR-005, BR-002, BR-009 | go test -race -run="Commit / ManualOffset" ./... | - | TRACEABILITY.md |
| TC-004 | FR-001, FR-002, BR-005 | go test -race -run="Retry / Send" ./... | - | TRACEABILITY.md |
| TC-005 | FR-006, BR-007 | go test -race -run=Health ./... | - | TRACEABILITY.md |
| TC-006 | FR-003, BR-006 | go test -race -run=Subscribe ./... | - | TRACEABILITY.md |
| TC-007 | FR-004, BR-003 | go test -race -run="Poll / Context" ./... | - | TRACEABILITY.md |
| TC-008 | FR-005, BR-004 | go test -race -run=Commit ./... | - | TRACEABILITY.md |
| TC-009 | BR-001, BR-005, BR-006 | go test -race -run=Config ./... | - | TRACEABILITY.md |
| TC-010 | BR-002, BR-009 | go test -race -run=AutoCommit ./... | - | TRACEABILITY.md |
| TC-011 | BR-003 | go test -race -run=Context ./... | - | TRACEABILITY.md |
| TC-012 | BR-004 | go test -race -run=Close ./... | - | TRACEABILITY.md |
| TC-013 | BR-008 | go test -race -run=Sanitize ./... | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Producer.Send — Kafka 可用时发送成功返回 nil；不可用时按 retry 重试后失败返回包装错误；value nil 或 topic 为空返回 ErrInvalidMessage；ctx 取消返回 ctx.Err() | AC-001 / TC-001, TC-004 / go test -race -run=ProducerSend ./... | ✅ | TRACEABILITY.md |
| FR-002 | Producer.SendBatch — 有效批次全部发送返回 nil；部分失败返回第一个可诊断错误且不回滚；空列表返回 nil；ctx 取消返回 ctx.Err() | AC-002 / TC-002, TC-004 / go test -race -run=SendBatch ./... | ✅ | TRACEABILITY.md |
| FR-003 | Consumer.Subscribe — 正常连接加入消费组返回 nil；topics 为空返回错误；已订阅返回 ErrAlreadySubscribed | AC-003 / TC-001, TC-006 / go test -race -run=Subscribe ./... | ✅ | TRACEABILITY.md |
| FR-004 | Consumer.Poll — 有新消息返回 *Message；无消息阻塞至 ctx 超时/取消；未订阅返回 ErrNotSubscribed；反序列化失败返回可分类错误且不自动提交 offset | AC-004 / TC-001, TC-007 / go test -race -run=Poll ./... | ✅ | TRACEABILITY.md |
| FR-005 | Consumer.Commit — 有效消息提交 offset 返回 nil；nil 或非法 offset 返回 ErrInvalidMessage；commit 失败返回 ErrCommitFailed；ctx 取消返回 ctx.Err() | AC-005 / TC-003, TC-008 / go test -race -run=Commit ./... | ✅ | TRACEABILITY.md |
| FR-006 | Health — Kafka metadata 成功返回 {Ready:true, Live:true}；不可达返回 {Ready:false, Live:false} 及错误上下文 | AC-006 / TC-005 / go test -race -run=Health ./... | ✅ | TRACEABILITY.md |
| BR-001 | Producer 默认同步发送且 acks=all；非法 acks 在构造或首次发送前返回配置错误；默认值不得静默降级 | TC-001, TC-009 / unit test | ✅ | TRACEABILITY.md |
| BR-002 | Consumer 默认手动 offset 提交 (at-least-once)；自动提交不得作为默认值；需调用方显式 Commit | TC-003, TC-010 / unit + integration | ✅ | TRACEABILITY.md |
| BR-003 | 所有运行时操作 (Send/SendBatch/Subscribe/Poll/Commit/Close/Health) 接受 context.Context；ctx 取消必须返回 ctx.Err() 或包装错误 | TC-007, TC-011 / unit | ✅ | TRACEABILITY.md |
| BR-004 | Consumer Close(ctx) 处理最终 offset/资源释放边界；失败返回错误且不吞错；重复调用不 panic | TC-008, TC-012 / unit | ✅ | TRACEABILITY.md |
| BR-005 | Producer 重试策略可配置且默认 3 次；负数或非法重试配置返回配置错误；最终失败返回包装错误并记录指标 | TC-004, TC-009 / unit | ✅ | TRACEABILITY.md |
| BR-006 | Consumer max_poll_records、session_timeout、heartbeat_interval 合法性校验；非法值返回配置错误 | TC-006, TC-009 / unit | ✅ | TRACEABILITY.md |
| BR-007 | Health(ctx) 幂等且无副作用；多次调用不改变订阅、offset、连接生命周期；错误可重复观察 | TC-005 / unit | ✅ | TRACEABILITY.md |
| BR-008 | 错误消息不包含消息内容 (value/payload)；日志和错误必须脱敏；发现 payload/凭据泄露视为安全阻断 | TC-013 / unit | ✅ | TRACEABILITY.md |
| BR-009 | Consumer 不自动提交 offset；enable_auto_commit 默认 false；未显式 Commit 不得提交 offset | TC-003, TC-010 / unit + integration | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | 单条发送 < 5ms / go test -bench=BenchmarkProducerSend ./... | ✅ | TRACEABILITY.md |
| NFR-002 | Performance | 批量发送 100 条 < 20ms / go test -bench=BenchmarkSendBatch ./... | ✅ | TRACEABILITY.md |
| NFR-003 | Performance | 单条消费 < 5ms / go test -bench=BenchmarkConsumerPoll ./... | ✅ | TRACEABILITY.md |
| NFR-004 | Resource | 常驻内存 (空闲) < 10MB / profiling | ✅ | TRACEABILITY.md |
| NFR-005 | Resource | Consumer lag < 1000 条 / integration test | ✅ | TRACEABILITY.md |
| NFR-006 | Quality | 单元测试覆盖率 >= 80% / go tool cover -func=.coverage/cover.out | ✅ | TRACEABILITY.md |
| NFR-007 | Quality | race 检测通过，零 data race / go test -race ./... | ✅ | TRACEABILITY.md |
| NFR-008 | Quality | vet 检查通过，零警告 / go vet ./... | ✅ | TRACEABILITY.md |
| NFR-009 | Quality | lint 检查通过，零错误 / golangci-lint run | ✅ | TRACEABILITY.md |
| NFR-010 | Security | Secret 扫描通过，零命中 / gitleaks detect --no-git | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/kafkax 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/kafkax 最新测试、race/vet/lint、覆盖率与 Kafka 集成/发布证据需要归档。
