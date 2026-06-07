# Traceability Matrix

> 需求追踪表：确保每个需求有验收标准、测试用例和实现。

最后更新：2026-06-07

---

## 使用方法

1. **防漏功能**：每个 FR/BR 必须有 AC 和 TC
2. **防做多**：每个实现必须有 spec 支持
3. **防测试盲区**：每个 AC 必须有 TC 覆盖
4. **方便 review**：reviewer 可以按编号逐条检查
5. **方便验收**：验收时按 AC 逐条确认

---

## kernel

| Requirement | Description            | Acceptance Criteria | Test Case              | Status |
| ----------- | ---------------------- | ------------------- | ---------------------- | ------ |
| FR-001      | Register 模块注册      | AC-001              | TC-001, TC-008         | ⬜     |
| FR-002      | Run 启动               | AC-002, AC-003      | TC-001, TC-002, TC-003 | ⬜     |
| FR-003      | Shutdown 停机          | AC-004              | TC-004                 | ⬜     |
| FR-004      | ModuleHealth 健康查询  | AC-005              | TC-009                 | ⬜     |
| FR-005      | DependencyGraph 依赖图 | AC-006              | TC-010                 | ⬜     |
| BR-001      | 依赖图不允许环         | AC-002              | TC-002                 | ⬜     |
| BR-002      | 拓扑序启动             | AC-003              | TC-001                 | ⬜     |
| BR-003      | 反序停止               | AC-004              | TC-004                 | ⬜     |
| BR-006      | Stop 超时 force        | AC-007              | TC-004                 | ⬜     |
| BR-008      | stdlib-only            | -                   | CI Gate                | ⬜     |

---

## configx

| Requirement | Description                  | Acceptance Criteria | Test Case | Status |
| ----------- | ---------------------------- | ------------------- | --------- | ------ |
| FR-001      | Load 文件加载                | AC-001              | TC-001    | ⬜     |
| FR-002      | WithEnvOverride 环境变量覆盖 | AC-002              | TC-001    | ⬜     |
| FR-003      | Validate 校验                | AC-003              | TC-002    | ⬜     |
| FR-004      | Get 读取                     | AC-004              | TC-003    | ⬜     |
| FR-005      | Watch 配置监听（可选）       | AC-005              | TC-configx-004 | ⬜     |
| BR-001      | 覆盖优先级                   | AC-002              | TC-001    | ⬜     |
| BR-002      | 启动时 fail-fast             | AC-003              | TC-002    | ⬜     |
| BR-005      | Reader 只读                  | AC-005              | TC-configx-005 | ⬜     |

---

## resiliencx

| Requirement | Description    | Acceptance Criteria | Test Case      | Status |
| ----------- | -------------- | ------------------- | -------------- | ------ |
| FR-001      | Timeout        | AC-001              | TC-001         | ⬜     |
| FR-002      | Retry          | AC-002              | TC-001         | ⬜     |
| FR-003      | CircuitBreaker | AC-003, AC-004      | TC-002, TC-003 | ⬜     |
| FR-004      | Bulkhead       | AC-005              | TC-004         | ⬜     |
| FR-005      | RateLimiter    | AC-006              | TC-resiliencx-005 | ⬜     |
| FR-006      | Fallback       | AC-007              | TC-resiliencx-006 | ⬜     |
| BR-004      | 熔断器并发安全 | -                   | -race test     | ⬜     |

---

## observex

| Requirement | Description          | Acceptance Criteria    | Test Case | Status |
| ----------- | -------------------- | ---------------------- | --------- | ------ |
| FR-001      | Logger               | DoD: 所有 FR 有测试    | TC-001    | ⬜     |
| FR-002      | Meter                | DoD: label policy check | TC-002    | ⬜     |
| FR-003      | Tracer               | DoD: 所有 FR 有测试    | TC-003    | ⬜     |
| FR-004      | Exporter             | DoD: 所有 FR 有测试    | TC-observex-004 | ⬜     |
| FR-005      | Redaction            | DoD: redaction leak check | TC-observex-005 | ⬜     |
| FR-006      | Label Policy         | DoD: label policy check | TC-002    | ⬜     |
| FR-007      | Health               | DoD: 所有 FR 有测试    | TC-observex-006 | ⬜     |
| BR-001      | Logger 并发安全      | -                      | -race test | ⬜     |
| BR-005      | With 不变性          | -                      | TC-001    | ⬜     |
| BR-006      | 指标命名规范         | DoD: metrics contract check | TC-observex-007 | ⬜     |
| BR-007      | 日志 secret 脱敏     | DoD: redaction leak check | TC-observex-008 | ⬜     |

---

## schedulex

| Requirement | Description            | Acceptance Criteria          | Test Case | Status |
| ----------- | ---------------------- | ---------------------------- | --------- | ------ |
| FR-001      | Schedule               | DoD: 所有 FR 有测试          | TC-001    | ⬜     |
| FR-002      | Trigger                | DoD: DST/timezone golden 测试 | TC-001    | ⬜     |
| FR-003      | Overlap Policy         | DoD: overlap contract 测试   | TC-002    | ⬜     |
| FR-004      | Misfire Policy         | DoD: misfire contract 测试   | TC-003    | ⬜     |
| FR-005      | Cancel                 | DoD: 所有 FR 有测试          | TC-schedulex-005 | ⬜     |
| FR-006      | Stop                   | DoD: shutdown leak/race 测试 | TC-schedulex-006 | ⬜     |
| FR-007      | EventSink              | DoD: 所有 FR 有测试          | TC-schedulex-007 | ⬜     |
| FR-008      | Locker                 | DoD: 所有 FR 有测试          | TC-004    | ⬜     |
| FR-009      | Clock                  | DoD: DST/timezone golden 测试 | TC-schedulex-008 | ⬜     |
| BR-002      | 重复 JobID 返回 ErrDuplicateJob | -                    | TC-schedulex-009 | ⬜     |
| BR-005      | job panic 被 catch     | DoD: shutdown race 测试      | TC-schedulex-010 | ⬜     |
| BR-007      | DST 切换触发正确       | DoD: DST/timezone golden 测试 | TC-schedulex-011 | ⬜     |

---

## testkitx

| Requirement | Description          | Acceptance Criteria      | Test Case    | Status |
| ----------- | -------------------- | ------------------------ | ------------ | ------ |
| FR-001      | FakeConfig           | DoD: 所有 FR 有测试      | TC-testkitx-001 | ⬜     |
| FR-002      | FakeLogger           | DoD: 编译期接口检查      | TC-testkitx-002 | ⬜     |
| FR-003      | FakeMeter            | DoD: 编译期接口检查      | TC-testkitx-003 | ⬜     |
| FR-004      | FakeTracer           | DoD: 编译期接口检查      | TC-testkitx-004 | ⬜     |
| FR-005      | FakeClock            | DoD: 确定性 fake         | TC-testkitx-005 | ⬜     |
| FR-006      | FakeBreaker          | DoD: 编译期接口检查      | TC-testkitx-006 | ⬜     |
| FR-007      | Eventually           | DoD: 所有 FR 有测试      | TC-testkitx-007 | ⬜     |
| FR-008      | GoldenUpdate         | DoD: GOLDEN_UPDATE 环境变量 | TC-testkitx-008 | ⬜     |
| FR-009      | BoundaryCheck        | DoD: 生产 import 无 testkitx | TC-testkitx-009 | ⬜     |
| FR-010      | GoroutineLeakCheck   | DoD: 所有 FR 有测试      | TC-testkitx-010 | ⬜     |
| BR-001      | 编译期接口检查       | -                        | CI Gate      | ⬜     |
| BR-002      | fake 确定性          | -                        | CI Gate      | ⬜     |
| BR-005      | 生产 import 无 testkitx | -                     | boundary-test | ⬜     |

---

## xlibgate

| Requirement | Description          | Acceptance Criteria | Test Case          | Status |
| ----------- | -------------------- | ------------------- | ------------------ | ------ |
| FR-001      | check imports        | DoD: 所有 FR 有测试 | TC-001             | ⬜     |
| FR-002      | check gomod          | DoD: 所有 FR 有测试 | TC-002             | ⬜     |
| FR-003      | check baseline       | DoD: 所有 FR 有测试 | TC-003             | ⬜     |
| FR-004      | check release        | DoD: 所有 FR 有测试 | TC-xlibgate-006 | ⬜     |
| FR-005      | check all            | DoD: 所有 FR 有测试 | TC-004, TC-005     | ⬜     |
| FR-006      | 输出格式             | DoD: 所有 FR 有测试 | TC-xlibgate-007 | ⬜     |
| BR-001      | 标准化 exit code     | -                   | TC-004, TC-005     | ⬜     |
| BR-006      | check all 执行所有子检查 | -               | TC-004             | ⬜     |

---

## xlib-standard

| Requirement | Description          | Acceptance Criteria | Test Case       | Status |
| ----------- | -------------------- | ------------------- | --------------- | ------ |
| FR-001      | 命名规范             | DoD: 所有 FR 有测试 | TC-xlib-standard-004 | ⬜     |
| FR-002      | 错误规范             | DoD: 所有 FR 有测试 | TC-xlib-standard-005 | ⬜     |
| FR-003      | 接口规范             | DoD: 所有 FR 有测试 | TC-xlib-standard-006 | ⬜     |
| FR-004      | 目录规范             | DoD: 所有 FR 有测试 | TC-xlib-standard-007 | ⬜     |
| FR-005      | 配置规范             | DoD: 所有 FR 有测试 | TC-xlib-standard-008 | ⬜     |
| FR-006      | Gate 定义            | DoD: Gate 一致性    | TC-003          | ⬜     |
| FR-007      | Evidence 定义        | DoD: 所有 FR 有测试 | TC-xlib-standard-009 | ⬜     |
| FR-008      | 模块骨架生成         | DoD: 模板可编译     | TC-001, TC-002  | ⬜     |
| BR-001      | 唯一标准来源         | -                   | TC-xlib-standard-010 | ⬜     |
| BR-004      | Reference Template 可编译 | -              | TC-002          | ⬜     |

---

## redisx

| Requirement | Description          | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------- | ------------------- | --------- | ------ |
| FR-001      | Get                  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Set                  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Del                  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-004      | Exists               | DoD: 所有 FR 有测试 | TC-redisx-004 | ⬜     |
| FR-005      | Expire               | DoD: 所有 FR 有测试 | TC-redisx-005 | ⬜     |
| FR-006      | HGet / HSet          | DoD: 所有 FR 有测试 | TC-redisx-006 | ⬜     |
| FR-007      | LPush / LRange       | DoD: 所有 FR 有测试 | TC-redisx-007 | ⬜     |
| FR-008      | Subscribe            | DoD: 所有 FR 有测试 | TC-redisx-008 | ⬜     |
| FR-009      | Pipeline             | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-010      | Locker.Acquire       | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-011      | Locker.Release       | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-012      | Health               | DoD: 所有 FR 有测试 | TC-redisx-009 | ⬜     |
| BR-004      | 分布式锁唯一持有者   | -                   | TC-002    | ⬜     |
| BR-006      | Pipeline 原子性      | -                   | TC-003    | ⬜     |

---

## kafkax

| Requirement | Description          | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------- | ------------------- | --------- | ------ |
| FR-001      | Producer.Send        | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Producer.SendBatch   | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-003      | Consumer.Subscribe   | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-004      | Consumer.Poll        | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-005      | Consumer.Commit      | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-006      | Health               | DoD: 所有 FR 有测试 | TC-kafkax-005 | ⬜     |
| BR-001      | Producer 同步发送 acks=all | -             | TC-001    | ⬜     |
| BR-002      | Consumer 手动 offset | -                   | TC-003    | ⬜     |
| BR-005      | Producer 重试可配置  | -                   | TC-004    | ⬜     |

---

## natsx

| Requirement | Description          | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------- | ------------------- | --------- | ------ |
| FR-001      | Publish（Core NATS） | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Subscribe（Core NATS） | DoD: 所有 FR 有测试 | TC-001 | ⬜     |
| FR-003      | Request（Core NATS） | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-004      | JetStream.Publish    | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-005      | JetStream.Subscribe  | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-006      | JetStream.AddStream  | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-007      | JetStream.AddConsumer | DoD: 所有 FR 有测试 | TC-003   | ⬜     |
| FR-008      | Health               | DoD: 所有 FR 有测试 | TC-natsx-005 | ⬜     |
| BR-001      | Core NATS at-most-once | -                | TC-001    | ⬜     |
| BR-002      | JetStream at-least-once | -               | TC-003    | ⬜     |
| BR-005      | 自动重连指数退避     | -                   | TC-004    | ⬜     |

---

## postgresx

| Requirement | Description          | Acceptance Criteria | Test Case      | Status |
| ----------- | -------------------- | ------------------- | -------------- | ------ |
| FR-001      | Query                | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-002      | QueryRow             | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-003      | Exec                 | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-004      | Tx                   | DoD: 所有 FR 有测试 | TC-002, TC-003 | ⬜     |
| FR-005      | Health               | DoD: 所有 FR 有测试 | TC-postgresx-005 | ⬜     |
| FR-006      | Migration            | DoD: 所有 FR 有测试 | TC-004         | ⬜     |
| BR-001      | 参数化查询防 SQL 注入 | -                  | TC-001         | ⬜     |
| BR-003      | 事务自动 commit/rollback | -              | TC-002         | ⬜     |
| BR-004      | 事务 panic 自动 rollback | -               | TC-003         | ⬜     |
| BR-007      | 迁移脚本幂等         | -                   | TC-004         | ⬜     |

---

## taosx

| Requirement | Description          | Acceptance Criteria | Test Case      | Status |
| ----------- | -------------------- | ------------------- | -------------- | ------ |
| FR-001      | NewClient            | DoD: 所有 FR 有测试 | TC-taosx-004 | ⬜     |
| FR-002      | Exec                 | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-003      | Query                | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-004      | InsertBatch          | DoD: 所有 FR 有测试 | TC-001, TC-003 | ⬜     |
| FR-005      | Health               | DoD: 所有 FR 有测试 | TC-taosx-005 | ⬜     |
| FR-006      | Close                | DoD: 所有 FR 有测试 | TC-taosx-006 | ⬜     |
| FR-007      | Rows.Next/Scan/Close | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| BR-002      | STMT 批量写入        | -                   | TC-003         | ⬜     |
| BR-003      | 参数化绑定防 SQL 拼接 | -                  | TC-001         | ⬜     |
| BR-004      | 连接断开自动重试     | -                   | TC-002         | ⬜     |

---

## ossx

| Requirement | Description          | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------- | ------------------- | --------- | ------ |
| FR-001      | NewClient            | DoD: 所有 FR 有测试 | TC-ossx-003 | ⬜     |
| FR-002      | Put                  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Get                  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-004      | Delete               | DoD: 所有 FR 有测试 | TC-ossx-004 | ⬜     |
| FR-005      | List                 | DoD: 所有 FR 有测试 | TC-ossx-005 | ⬜     |
| FR-006      | PresignURL           | DoD: 所有 FR 有测试 | TC-ossx-006 | ⬜     |
| FR-007      | Health               | DoD: 所有 FR 有测试 | TC-ossx-007 | ⬜     |
| FR-008      | Close                | DoD: 所有 FR 有测试 | TC-ossx-008 | ⬜     |
| BR-001      | key 非空且不以 / 开头 | -                  | TC-ossx-009 | ⬜     |
| BR-002      | multipart upload 阈值 100MB | -            | TC-002    | ⬜     |
| BR-008      | Delete 幂等          | -                   | TC-ossx-010 | ⬜     |

---

## clickhousex

| Requirement | Description          | Acceptance Criteria | Test Case      | Status |
| ----------- | -------------------- | ------------------- | -------------- | ------ |
| FR-001      | NewClient            | DoD: 所有 FR 有测试 | TC-clickhousex-005 | ⬜     |
| FR-002      | Exec                 | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-003      | Query                | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-004      | InsertBatch          | DoD: 所有 FR 有测试 | TC-001, TC-003 | ⬜     |
| FR-005      | Health               | DoD: 所有 FR 有测试 | TC-clickhousex-006 | ⬜     |
| FR-006      | Close                | DoD: 所有 FR 有测试 | TC-clickhousex-007 | ⬜     |
| FR-007      | Rows.Next/Scan/Close | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-008      | Rows.ColumnTypes     | DoD: 所有 FR 有测试 | TC-004         | ⬜     |
| BR-002      | 原生 batch insert 协议 | -                 | TC-003         | ⬜     |
| BR-003      | 参数化绑定防 SQL 拼接 | -                  | TC-001         | ⬜     |
| BR-004      | 连接断开自动重试     | -                   | TC-002         | ⬜     |
| BR-011      | Nullable 映射 Go 指针 | -                  | TC-004         | ⬜     |

---

## xgo

| Requirement | Description            | Acceptance Criteria | Test Case | Status |
| ----------- | ---------------------- | ------------------- | --------- | ------ |
| FR-001      | Compose 模块组装       | AC-001              | TC-001    | ⬜     |
| FR-002      | Run 启动               | AC-002              | TC-002    | ⬜     |
| FR-003      | Shutdown 停机          | AC-003              | TC-003    | ⬜     |
| FR-004      | Health 健康检查        | AC-004              | TC-004    | ⬜     |
| FR-005      | Signal 信号处理        | AC-005              | TC-005    | ⬜     |
| FR-006      | Config 配置加载        | AC-006              | TC-006    | ⬜     |
| BR-001      | 组合根不包含业务逻辑   | -                   | import check | ⬜  |
| BR-003      | 只编排不实现           | -                   | code review | ⬜   |
| BR-005      | 单进程运行             | AC-002              | TC-002    | ⬜     |

---

## contracts

| Requirement | Description          | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------- | ------------------- | --------- | ------ |
| FR-001      | MarketDataProvider   | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | MacroDataProvider    | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Event 接口           | DoD: 所有 FR 有测试 | TC-contracts-005 | ⬜     |
| FR-004      | Topic 常量           | DoD: 所有 FR 有测试 | TC-004    | ⬜     |
| FR-005      | DTO 契约             | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-006      | Breaking Change 检测 | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| BR-003      | breaking change 需版本升级 | -             | TC-003    | ⬜     |
| BR-004      | 端口接口 3-5 方法    | -                   | TC-contracts-006 | ⬜     |
| BR-005      | 事件 DTO 不可变      | -                   | TC-contracts-007 | ⬜     |
| BR-006      | Topic 全局唯一点分命名 | -                 | TC-004    | ⬜     |

---

## 状态说明

| 符号 | 含义     |
| ---- | -------- |
| ⬜   | 未开始   |
| 🔵   | 开发中   |
| ✅   | 已完成   |
| ❌   | 验收失败 |
| ⏭️   | 推迟     |

---

## 使用 Prompt

```markdown
请根据 Traceability Matrix 检查当前实现。

要求：

- 找出未实现的 Requirement（Status = ⬜ 但应该已实现的）
- 找出没有测试覆盖的 Requirement（Test Case = -）
- 找出实现了但没有 Spec 支持的功能（scope creep）
- 不要修改代码，只输出分析结果
```
