# flowx 需求追溯矩阵

> 更新：2026-06-29（Goal 管线对齐：§1-§7 章节标准化，§6 覆盖率仪表盘标准化 Done/覆盖率格式）
> 来源：module/flowx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

Last-Updated: 2026-06-29

---

## §1 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Pipeline DAG：定义 Source/Transform/Window/Sink 四类节点；检测循环依赖 | AC-FLX-001 | TC-FLX-001 | - | 🔲 |
| FR-002 | Source：支持 Kafka/NATS/gRPC/WebSocket/CSV 五种数据源；声明输出数据类型 | AC-FLX-002 | TC-FLX-002 | - | 🔲 |
| FR-003 | Transform：支持 Filter/Map/FlatMap/KeyBy/Join/Enrich 操作 | AC-FLX-003 | TC-FLX-003 | - | 🔲 |
| FR-004 | Window：Tumbling/Sliding/Session 三种类型；Count/Sum/Avg/Min/Max/First/Last 聚合；事件时间+watermark+lateness 触发 | AC-FLX-004 | TC-FLX-004 | - | 🔲 |
| FR-005 | Sink：支持 Kafka/NATS/gRPC/InMemory/CSV 五种类型；返回 DeliveryReceipt（at-least-once）；至少一个 primary | AC-FLX-005 | TC-FLX-005 | - | 🔲 |
| FR-006 | Data Routing：按 symbol/exchange/dataType/自定义 key 分流；路由规则变更不丢数据 | AC-FLX-006 | TC-FLX-006 | - | 🔲 |
| FR-007 | Backpressure：Block/Drop/Spill 策略；Spill 磁盘满降级为 Drop | AC-FLX-007 | TC-FLX-007 | - | 🔲 |
| FR-008 | Pipeline Lifecycle：拓扑顺序启动；启动失败回滚；支持 Pause/Resume/Stop | AC-FLX-008 | TC-FLX-008 | - | 🔲 |
| FR-009 | Hot Reload：Drain-Then-Apply 热更新；offset checkpoint 保证不丢不重 | AC-FLX-009 | TC-FLX-009 | - | 🔲 |
| FR-010 | Module Identity：README H1 为 `# flowx`；Go module path 为 `github.com/ZoneCNH/flowx` | AC-FLX-010 | TC-FLX-010 | - | 🔲 |

---

## §2 业务规则追溯（BR）

| BR | Description | 违反后果 | TC ID(s) | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | Source 节点必须声明输出数据类型 | 编译失败 | TC-FLX-002 OutputType() 非空断言 | - | 🔲 |
| BR-002 | 至少一个 Sink 必须标注为 primary | Pipeline 创建失败 | TC-FLX-005 primary Sink 存在性检查 | - | 🔲 |
| BR-003 | DAG 中不得有循环依赖 | Pipeline 创建失败 | TC-FLX-001 循环检测断言 | - | 🔲 |
| BR-004 | Sink at-least-once 语义不可降级为 at-most-once | 拒绝启动 | TC-FLX-005 DeliveryReceipt ACK 断言 | - | 🔲 |
| BR-005 | 背压策略必须显式配置，不允许隐式默认 | 拒绝启动 | TC-FLX-007 背压配置非空检查 | - | 🔲 |

---

## §3 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | 单条 Transform 延迟 | < 100μs | Benchmark | - | 🔲 |
| NFR-002 | Window 聚合延迟 | < 1ms | Benchmark | - | 🔲 |
| NFR-003 | Pipeline 启动耗时 | < 1s | Benchmark | - | 🔲 |
| NFR-004 | 热更新耗时 | < 5s | Benchmark | - | 🔲 |
| NFR-005 | 吞吐量 | > 100K msg/s per pipeline | Benchmark | - | 🔲 |
| NFR-006 | 测试覆盖率 | >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-007 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | - | 🔲 |

---

## §4 TC→FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-FLX-001 | FR-001, BR-003 | Pipeline DAG 创建含四类节点；循环依赖检测触发错误 |
| TC-FLX-002 | FR-002, BR-001 | Source 支持 5 种数据源类型；OutputType() 非空 |
| TC-FLX-003 | FR-003 | Transform 支持 Filter/Map/FlatMap/KeyBy/Join/Enrich；函数签名为 `func(ctx, T) (U, error)`；Filter 返回 false 时丢弃 |
| TC-FLX-004 | FR-004 | Window 支持 Tumbling/Sliding/Session 三种类型；聚合函数完整；触发策略基于事件时间+watermark+lateness |
| TC-FLX-005 | FR-005, BR-002, BR-004 | Sink 支持 5 种类型；返回 DeliveryReceipt（at-least-once）；至少一个 primary Sink |
| TC-FLX-006 | FR-006 | 数据路由按 symbol/exchange/dataType/自定义 key 分流；路由规则变更不丢数据（drain old → apply new） |
| TC-FLX-007 | FR-007, BR-005 | 背压策略 Block/Drop/Spill 正确触发；Spill 磁盘满降级为 Drop；背压配置显式要求 |
| TC-FLX-008 | FR-008 | Pipeline 按拓扑顺序启动（Source→Transform→Window→Sink）；启动失败回滚；Pause/Resume/Stop 正确 |
| TC-FLX-009 | FR-009 | 热更新执行 Drain-Then-Apply；offset checkpoint 保证不丢不重 |
| TC-FLX-010 | FR-010 | README H1 为 `# flowx`；go.mod 声明 `module github.com/ZoneCNH/flowx` |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 |
|----|-----------|-------------|
| AC-FLX-001 | FR-001 | Pipeline DAG 定义四类节点；检测循环依赖并在创建时报错 |
| AC-FLX-002 | FR-002 | Source 支持 5 种数据源；声明输出数据类型 |
| AC-FLX-003 | FR-003 | Transform 支持 Filter/Map/FlatMap/KeyBy/Join/Enrich；函数签名正确 |
| AC-FLX-004 | FR-004 | Window 支持 Tumbling/Sliding/Session；聚合函数完整；事件时间+watermark+lateness |
| AC-FLX-005 | FR-005 | Sink 支持 5 种类型；返回 DeliveryReceipt；至少一个 primary |
| AC-FLX-006 | FR-006 | 数据路由按 symbol/exchange/dataType/自定义 key 分流；变更不丢数据 |
| AC-FLX-007 | FR-007 | 背压 Block/Drop/Spill 正确；Spill 磁盘满降级 Drop |
| AC-FLX-008 | FR-008 | Pipeline 拓扑顺序启动；启动失败回滚；Pause/Resume/Stop |
| AC-FLX-009 | FR-009 | 热更新 Drain-Then-Apply；offset checkpoint 不丢不重 |
| AC-FLX-010 | FR-010 | README H1 为 `# flowx`；go.mod 声明 `module github.com/ZoneCNH/flowx` |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 10 | 0 | 0% |
| BR | 5 | 0 | 0% |


| NFR | 7 | 0 | 0% |
| AC | 10 | 0 | 0% |
| TC | 10 | 0 | 0% |
| **合计** | **42** | **0** | **0%** |

> 说明：flowx 初始版本，所有 FR/BR/NFR 状态均为 🔲（Pending）。

---

## §7 变更历史

| 日期 | 版本 | 变更 |
| --- | --- | --- |
| 2026-06-29 | v1.1 | Goal 管线对齐：§1-§7 章节标题统一为 § 前缀格式；补全 §2 BR 表独立标题；§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 2026-06-15 | v1.0 | 初始版本：10 FR + 5 BR + 7 NFR + 10 TC + 10 AC |
