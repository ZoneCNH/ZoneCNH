# kafkax 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: SPEC.md v1.0.0-spec-baseline（Draft，未仲裁）

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| ----------- | ----------- | ------------------- | --------- | ---- | ------ |
| FR-001 | Producer.Send 支持同步发送并返回错误 | 可用 broker 返回 nil；不可用 broker 返回发送错误；nil value 返回错误 | TC-001, TC-004 | TASK-KAFKAX-001 | Pending |
| FR-002 | Producer.SendBatch 支持批量发送 | 有效批次全部发送；部分失败返回第一个错误且不回滚已发送消息；空批次返回 nil | TC-002 | TASK-KAFKAX-001 | Pending |
| FR-003 | Consumer.Subscribe 加入消费组并防止非法订阅 | 有效 topics 成功订阅；空 topics 返回错误；重复订阅返回错误 | TC-001 | TASK-KAFKAX-002 | Pending |
| FR-004 | Consumer.Poll 支持阻塞、消息返回和 ctx 取消 | 有消息返回 Message；无消息阻塞到消息或超时；ctx 取消返回 ctx.Err() | TC-001 | TASK-KAFKAX-002 | Pending |
| FR-005 | Consumer.Commit 手动提交 offset | 有效消息提交成功；nil 或非法 offset 返回错误 | TC-003 | TASK-KAFKAX-003 | Pending |
| FR-006 | Health(ctx) 反映 Kafka metadata 可达性 | broker 可达返回 ready/live；不可达返回 not ready/not live 和诊断 message | TC-005 | TASK-KAFKAX-004 | Pending |
| BR-001 | Producer 默认同步发送 acks=all，可配置切换 | 默认配置为 acks=all；非法 acks 阻止启动或返回配置错误 | TC-001 | TASK-KAFKAX-001 | Pending |
| BR-002 | Consumer 默认手动 offset，提供 at-least-once 基线 | enable_auto_commit 默认为 false；自动提交配置路径被测试阻断 | TC-003 | TASK-KAFKAX-003 | Pending |
| BR-003 | 阻塞/外部 I/O 公共操作接受 context.Context | Send/SendBatch/Subscribe/Poll/Commit/Close/Health 均接受 ctx；取消返回 ctx.Err() | TC-001, TC-003, CI-API | TASK-KAFKAX-005 | Pending |
| BR-004 | Consumer Close(ctx) 提交最终 offset | Close(ctx) 在需要时提交最终 offset；失败返回错误且不吞掉底层原因 | TC-003 | TASK-KAFKAX-003 | Pending |
| BR-005 | Producer 重试策略可配置，默认 3 次 | 默认 retries=3；非法配置返回错误；耗尽后返回最终包装错误 | TC-004 | TASK-KAFKAX-001 | Pending |
| BR-006 | Consumer 轮询间隔可配置 | 默认 poll interval 可验证；非法配置返回配置错误 | TC-001 | TASK-KAFKAX-002 | Pending |
| BR-007 | Health(ctx) 幂等且无副作用 | 多次 Health 不改变订阅、offset 或连接生命周期 | TC-005 | TASK-KAFKAX-004 | Pending |
| BR-008 | 错误和日志不得泄露消息内容 | 错误/log 仅包含 operation/topic/partition/offset，不包含 key/value/payload | CI-SEC, TC-004 | TASK-KAFKAX-006 | Pending |
| BR-009 | Consumer 不自动提交 offset | 未调用 Commit 时不推进 offset；重启后从未提交位置继续 | TC-003 | TASK-KAFKAX-003 | Pending |

---

## Task Reference Notes

- `TASK-KAFKAX-*` 为 v1.0 baseline 的实现/验证任务占位，用于把规格需求映射到后续执行单元；当前文件不声明实现已完成。
- `CI-API` 表示公共 API 形状检查（接口必须接受 `context.Context` 并返回 `error`）。
- `CI-SEC` 表示错误/日志敏感信息静态检查或审查门禁。
