# kafkax 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.2
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/kafkax
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 kafkax 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | Kafka producer/consumer/admin、offset、事务与观测适配 |
| 文档目录 | module/kafkax |
| 运行时代码目录 | /home/kafkax |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Producer.Send — Kafka 可用时发送成功返回 nil；不可用时按 retry 重试后失败返回包装错误；value nil 或 topic 为空返回 ErrInvalidMessage；ctx 取消返回 ctx.Err() | AC-001 / TC-001, TC-004 / go test -race -run=ProducerSend ./... | ✅ | TRACEABILITY.md |
| FR-002 | Producer.SendBatch — 有效批次全部发送返回 nil；部分失败返回第一个可诊断错误且不回滚；空列表返回 nil；ctx 取消返回 ctx.Err() | AC-002 / TC-002, TC-004 / go test -race -run=SendBatch ./... | ✅ | TRACEABILITY.md |
| FR-003 | Consumer.Subscribe — 正常连接加入消费组返回 nil；topics 为空返回错误；已订阅返回 ErrAlreadySubscribed | AC-003 / TC-001, TC-006 / go test -race -run=Subscribe ./... | ✅ | TRACEABILITY.md |
| FR-004 | Consumer.Poll — 有新消息返回 *Message；无消息阻塞至 ctx 超时/取消；未订阅返回 ErrNotSubscribed；反序列化失败返回可分类错误且不自动提交 offset | AC-004 / TC-001, TC-007 / go test -race -run=Poll ./... | ✅ | TRACEABILITY.md |
| FR-005 | Consumer.Commit — 有效消息提交 offset 返回 nil；nil 或非法 offset 返回 ErrInvalidMessage；commit 失败返回 ErrCommitFailed；ctx 取消返回 ctx.Err() | AC-005 / TC-003, TC-008 / go test -race -run=Commit ./... | ✅ | TRACEABILITY.md |
| FR-006 | Health — Kafka metadata 成功返回 {Ready:true, Live:true}；不可达返回 {Ready:false, Live:false} 及错误上下文 | AC-006 / TC-005 / go test -race -run=Health ./... | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-KAFKAX-001 | TASK-KAFKAX-001: Producer Send/SendBatch + acks + retry | module/kafkax/tasks/TASK-KAFKAX-001.md | - | tasks/TASK-KAFKAX-001.md |
| TASK-KAFKAX-002 | TASK-KAFKAX-002: Consumer Subscribe/Poll + ctx | module/kafkax/tasks/TASK-KAFKAX-002.md | - | tasks/TASK-KAFKAX-002.md |
| TASK-KAFKAX-003 | TASK-KAFKAX-003: 手动 offset 提交 + Close 边界 + 无自动提交 | module/kafkax/tasks/TASK-KAFKAX-003.md | - | tasks/TASK-KAFKAX-003.md |
| TASK-KAFKAX-004 | TASK-KAFKAX-004: 幂等 Health + sanitized errors | module/kafkax/tasks/TASK-KAFKAX-004.md | - | tasks/TASK-KAFKAX-004.md |
| TASK-KAFKAX-005 | TASK-KAFKAX-005: Consumer 配置校验 | module/kafkax/tasks/TASK-KAFKAX-005.md | - | tasks/TASK-KAFKAX-005.md |
| TASK-KAFKAX-006 | TASK-KAFKAX-006: CI + Release 基线 | module/kafkax/tasks/TASK-KAFKAX-006.md | - | tasks/TASK-KAFKAX-006.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/kafkax/goal.md |
| SPEC.md | 存在 | module/kafkax/SPEC.md |
| TRACEABILITY.md | 存在 | module/kafkax/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/kafkax/IMPLEMENTATION-PLAN.md |
| tasks/ | 6 个 Markdown 文件 | module/kafkax/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/kafkax 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
