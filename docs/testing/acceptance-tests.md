# Acceptance Tests: Foundation v1

> Foundation v1 跨模块端到端验收场景。验证模块协作的正确性，不是单模块测试。

最后更新：2026-06-07
Status: Approved

---

## 1. 目的

本文档定义 Foundation v1 的整体验收场景，聚焦于**跨模块协作**。单模块的单元测试见各模块 `specs/*/SPEC.md` Section 16。

验收场景回答的问题：**Foundation v1 作为一个整体是否可以正常工作？**

---

## 2. 场景总览

| 编号 | 场景 | 涉及模块 | 优先级 |
|------|------|----------|--------|
| AT-001 | 正常启动（完整链路） | x.go, kernel, configx, observex | P0 |
| AT-002 | 配置加载 → 模块初始化 | configx, kernel, 所有 L1 模块 | P0 |
| AT-003 | 模块启动失败回滚 | kernel, configx, observex | P0 |
| AT-004 | 优雅停机 | kernel, 所有已注册模块 | P0 |
| AT-005 | 健康检查全链路 | kernel, observex, 所有模块 | P1 |
| AT-006 | 弹性策略生效 | resiliencx, kernel | P1 |
| AT-007 | 横切模块贯穿 | alertx, observex, 业务域模块 | P1 |
| AT-008 | 配置热更新 | configx, 业务域模块 | P2 |
| AT-009 | Redis 缓存与分布式锁链路 | redisx | P1 |
| AT-010 | Kafka 生产-消费链路 | kafkax | P1 |
| AT-011 | NATS 请求-响应模式 | natsx | P1 |
| AT-012 | Postgres 事务与迁移 | postgresx | P1 |
| AT-013 | ClickHouse 批量写入与查询 | clickhousex | P2 |
| AT-014 | TDengine 时序数据写入与查询 | taosx | P2 |
| AT-015 | OSS 对象存储操作 | ossx | P2 |
| AT-016 | Contracts 契约 Breaking Change 检测 | contracts, xlibgate | P0 |
| AT-017 | 采集器 → Kafka → 消费者链路 | market-data, kafkax, contracts | P1 |
| AT-018 | schedulex 定时任务触发 | schedulex, kernel, observex | P1 |
| AT-019 | testkitx 边界守卫 | testkitx, kernel, observex | P1 |
| AT-020 | xlib-standard 门禁一致性 | xlib-standard, xlibgate | P1 |

---

## 3. 验收场景

### AT-001: 正常启动（完整链路）

**Given** x.go 配置文件就绪，包含 kernel、configx、observex 及若干业务域模块的配置
**When** 执行 `x.go` 启动应用
**Then**

- configx 读取并校验配置成功
- observex 初始化 logger、meter、tracer
- kernel 按拓扑序依次 Init → Start 所有模块
- 所有模块 Health() 返回 Ready=true, Live=true
- 应用进入 Running 状态

**验证方法：** 集成测试，检查所有模块最终状态为 `StateRunning`

---

### AT-002: 配置加载 → 模块初始化

**Given** 配置文件包含各模块的配置项
**When** configx 加载配置，kernel 初始化模块
**Then**

- 每个模块通过 `Deps.Config` 读取到正确的配置值
- 配置校验失败的模块不启动，返回明确错误
- 缺失必填配置的模块返回 `ValidationError`
- 可选配置使用默认值

**验证方法：** 集成测试，mock 配置文件，验证模块收到的配置值

---

### AT-003: 模块启动失败回滚

**Given** 注册模块 A（无依赖）、B（依赖 A）、C（依赖 A）
**When** A.Start 成功，B.Start 失败
**Then**

- kernel 立即中断启动流程
- A.Stop 被调用（反序清理）
- C 不启动（fail-fast）
- 应用返回 `ErrStartupFailed`，包含 B 的错误信息
- observex 记录启动失败日志

**验证方法：** 集成测试，注入一个 Start 返回错误的 mock 模块

---

### AT-004: 优雅停机

**Given** 应用处于 Running 状态，所有模块正常运行
**When** 收到 SIGTERM 信号
**Then**

- kernel 按启动反序调用每个模块的 Stop
- 每个模块在 shutdown_timeout 内完成 Stop
- 超时模块被强制跳过，记录 `ErrShutdownTimeout`
- 所有模块最终状态为 `StateStopped`
- 应用进程退出码为 0

**验证方法：** 集成测试，发送 SIGTERM，检查模块停止顺序和最终状态

---

### AT-005: 健康检查全链路

**Given** 应用处于 Running 状态
**When** 调用 `ModuleHealth(name)` 查询每个模块
**Then**

- 每个模块返回 `HealthStatus{Ready: true, Live: true}`
- `Health()` 调用无副作用（幂等）
- 模块内部状态变化时，Health() 反映最新状态

**验证方法：** 集成测试，周期性调用 Health()，验证状态一致性

---

### AT-006: 弹性策略生效

**Given** resiliencx 配置了重试策略（max_retries=3）和超时策略（timeout=5s）
**When** 业务模块调用外部服务，首次失败后重试
**Then**

- 重试 3 次后成功 → 返回成功结果
- 重试 3 次后仍失败 → 返回错误，observex 记录重试日志
- 超时策略触发 → 操作在 5s 后中断，返回超时错误

**验证方法：** 集成测试，mock 外部服务，注入可控的失败模式

---

### AT-007: 横切模块贯穿

**Given** alertx 和 observex 已注册，业务域模块产生告警事件
**When** 业务模块触发告警条件
**Then**

- alertx 收到告警事件，发送通知
- observex 记录告警日志，包含 trace ID
- 告警不影响业务模块的正常运行
- 多个模块同时触发告警时不丢失事件

**验证方法：** 集成测试，注入告警触发条件，检查 alertx 和 observex 的输出

---

### AT-008: 配置热更新

**Given** 应用运行中，configx 支持配置热更新
**When** 配置文件变更
**Then**

- configx 检测到变更并重新加载
- 受影响的模块收到配置更新通知
- 不受影响的模块不重启
- 配置校验失败时保留旧配置，记录告警

**验证方法：** 集成测试，修改配置文件，验证模块行为变化

---

## 存储扩展验收场景

### AT-009: Redis 缓存与分布式锁链路

**Given：** redisx 已连接 Redis 实例
**When：** 业务模块通过 redisx.Cache 写入数据，然后通过 Locker.Acquire 获取锁
**Then：**

- Cache.Get 返回写入的值
- Locker.Acquire 成功获取锁
- 重复 Acquire 返回 ErrLockHeld
- Locker.Release 释放后可重新获取
- 连接断开时 Health 标记为 unhealthy

**验证方法：** 集成测试，使用 testcontainers 启动 Redis

---

### AT-010: Kafka 生产-消费链路

**Given：** kafkax 已连接 Kafka 集群
**When：** Producer.Send 发送消息，Consumer.Subscribe 订阅同一 topic
**Then：**

- 消息在 5s 内被消费者收到
- Consumer.Commit 后 offset 更新
- Producer 重试可配置（max_retries）
- 连接断开时自动重连

**验证方法：** 集成测试，使用 testcontainers 启动 Kafka

---

### AT-011: NATS 请求-响应模式

**Given：** natsx 已连接 NATS 服务器
**When：** 服务端 Subscribe 注册 handler，客户端 Request 发送请求
**Then：**

- 服务端收到请求并返回响应
- 客户端在 timeout 内收到响应
- 超时返回 ErrRequestTimeout
- JetStream 持久化消息不丢失

**验证方法：** 集成测试，使用嵌入式 NATS 或 testcontainers

---

### AT-012: Postgres 事务与迁移

**Given：** postgresx 已连接 PostgreSQL 实例
**When：** 开启事务执行多条 SQL，然后提交或回滚
**Then：**

- Tx.Commit 后数据持久化
- Tx.Rollback 后数据不变
- panic 自动 rollback
- Migration 幂等执行（重复执行不报错）

**验证方法：** 集成测试，使用 testcontainers 启动 PostgreSQL

---

### AT-013: ClickHouse 批量写入与查询

**Given：** clickhousex 已连接 ClickHouse 实例
**When：** InsertBatch 写入 1000 行数据，Query 查询
**Then：**

- 数据在 1s 内可查询到
- Query 返回正确的行数和列类型
- Nullable 列正确映射为 Go 指针
- TTL 配置后数据自动过期

**验证方法：** 集成测试，使用 testcontainers 启动 ClickHouse

---

### AT-014: TDengine 时序数据写入与查询

**Given：** taosx 已连接 TDengine 实例
**When：** InsertBatch 写入时序数据，Query 按时间范围查询
**Then：**

- 数据写入成功
- 时间范围查询返回正确结果
- 超级表继承字段正确
- 连接断开自动重试

**验证方法：** 集成测试，使用 testcontainers 启动 TDengine

---

### AT-015: OSS 对象存储操作

**Given：** ossx 已连接对象存储服务
**When：** Put 上传文件，Get 下载，List 列举
**Then：**

- Put 后 Get 返回相同内容
- Delete 后 Get 返回 ErrObjectNotFound
- List 返回正确的 key 列表
- 大文件（>100MB）自动分片上传

**验证方法：** 集成测试，使用 MinIO 或 localstack

---

## 跨域链路验收场景

### AT-016: Contracts 契约 Breaking Change 检测

**Given：** contracts 模块已定义 MarketDataProvider 接口
**When：** 修改接口方法签名（如添加新参数）
**Then：**

- breaking change 检测脚本报告不兼容
- CI Gate 阻止合并
- 版本号需升级（minor → major）

**验证方法：** CI 脚本，对比接口签名

---

### AT-017: 采集器 → Kafka → 消费者链路

**Given：** market-data 采集器和消费者模块均已配置
**When：** 采集器从交易所获取行情，通过 Kafka 发布
**Then：**

- 消费者在 5s 内收到行情数据
- 数据格式符合 contracts.MarketDataProvider 定义
- 采集器断开后消费者 Health 标记为 degraded

**验证方法：** 端到端集成测试，使用 mock 交易所 + testcontainers Kafka

---

## 工具与标准验收场景

### AT-018: schedulex 定时任务触发

**Given：** schedulex 已注册 cron job（`*/1 * * * *`）和 interval job（`Interval: 5s`），配置了 `OverlapPolicy = Skip` 和 `MisfirePolicy = RunOnce`
**When：** FakeClock 推进到触发时间，然后快速推进 2 个调度周期
**Then：**

- cron job 按 cron 表达式触发，Handler 被调用
- interval job 按 5s 间隔触发，Handler 被调用
- 重复注册同一 JobID 返回 `ErrDuplicateJob`
- `Cancel(id)` 取消后不再触发，`Cancel` 不存在的 ID 返回 `ErrJobNotFound`
- job handler panic 被 catch，不影响其他 job 继续执行
- `Stop(ctx)` 等待正在执行的 job 完成；超时则 force cancel，返回 `ErrShutdownTimeout`
- 无效 cron 语法返回 `ErrInvalidTrigger`，`interval <= 0` 返回 `ErrInvalidTrigger`
- observex 记录 job 触发、完成、失败事件

**验证方法：** 集成测试，注入 FakeClock，验证触发次数、顺序和可观测事件

---

### AT-019: testkitx 边界守卫

**Given：** Foundation 各模块（kernel、configx、observex、resiliencx、schedulex）的测试使用 testkitx 提供的 fake 实现
**When：** 运行 `go list -deps` 检查生产依赖图，并执行 contract 测试
**Then：**

- `BoundaryCheck(t, module)` 验证生产包不依赖 testkitx，违反时报错并报告依赖路径
- `GoroutineLeakCheck(t)` 验证测试结束后无 goroutine 泄漏，泄漏时报告堆栈
- `FakeLogger` 的 `AssertLogged` / `AssertNoErrors` / `Entries()` 断言正确
- `FakeMeter` 的 `AssertCounterValue` / `AssertHistogramRecorded` 断言正确
- `FakeClock` 的 `Advance` / `Set` 控制时间确定性，不调用 `time.Now`
- `FakeConfig` 的 `Get(key)` 返回正确值，不存在的 key 返回 nil
- `Eventually(t, fn, timeout, interval)` 条件满足时通过，超时时失败并输出诊断
- `GoldenUpdate()` 仅在 `GOLDEN_UPDATE=1` 环境变量下返回 true
- 所有 fake 编译期接口检查通过（`var _ Interface = (*FakeImpl)(nil)`）
- `-race` 测试通过，fake 并发安全

**验证方法：** 集成测试，运行 contract test suite + boundary scan + goroutine leak check

---

### AT-020: xlib-standard 门禁一致性

**Given：** `xlib-standard` 定义了 Gate 清单（`gates/common.yaml`）和 Evidence schema（`evidence/schema.json`），`xlibgate` 消费这些定义
**When：** 对比 `xlib-standard` 的 Gate 定义与 `xlibgate` 的实际检查配置，并验证各模块 CI artifact
**Then：**

- `gates/common.yaml` 的 8 项 Gate（build、test、coverage、vet、lint、dependency、secret_scan、benchmark）与 `xlibgate.yaml` 完全匹配
- 每个 Foundation 模块的 CI 执行所有 blocking Gate，且阈值与标准一致（coverage ≥ 80%）
- `xlibgate check all` 对使用 `init.sh` 生成的模块骨架返回全部通过
- Evidence schema 的 required 字段（test_coverage、race_test、secret_scan）与 CI artifact 格式一致
- 标准规范文档（naming、errors、interfaces、directory、config）每条规范至少有一个正例和一个反例
- Gate 定义不一致时，CI 中的同步检查报错并阻止合并
- Evidence 格式变更时，`xlibgate check release` 检测到不兼容

**验证方法：** CI 脚本，`diff` 对比 Gate 定义 + `xlibgate check all` 验证模块骨架 + JSON schema 验证 Evidence artifact

---

## 4. 测试环境要求

| 要求 | 说明 |
|------|------|
| 隔离性 | 测试不依赖真实外部服务（交易所、消息队列） |
| 可重复 | 每次运行结果一致，无随机失败 |
| 快速 | 完整验收套件 < 60s |
| 标记 | 使用 `//go:build acceptance` 构建标签 |

---

## 5. 验收标准

Foundation v1 整体验收通过的条件：

- [ ] AT-001 至 AT-004 全部通过（P0 场景）
- [ ] AT-005 至 AT-007 全部通过（P1 场景）
- [ ] AT-008 通过（P2 场景，可推迟）
- [ ] AT-009 至 AT-015 全部通过（存储扩展验收）
- [ ] AT-016 至 AT-017 全部通过（跨域链路验收）
- [ ] AT-018 至 AT-020 全部通过（工具与标准验收）
- [ ] 所有场景无 data race（`-race` 通过）
- [ ] 验收测试覆盖率 ≥ 80%

---

## 6. 性能预算验收

> 将各 SPEC.md 中定义的 Performance Budget 纳入验收条件。

### AT-PERF-001: 模块性能预算达标

**前置条件**：模块已实现并通过所有功能验收

**验收标准**：

- [ ] 各 SPEC.md §17 定义的延迟指标达标（P99 < 标注值）
- [ ] 各 SPEC.md §17 定义的内存指标达标
- [ ] Benchmark 结果记录在模块 README.md 中
- [ ] 无性能退化（与基线对比 < 10%）

**验证方式**：`go test -bench=. -benchmem -count=3 ./...`

---

## 7. 非功能测试策略

### 7.1 Fuzz Testing

- 对所有解析类函数（配置加载、协议解析、类型转换）补充 fuzz 测试
- 使用 Go 1.18+ 原生 fuzz，文件命名 `*_fuzz_test.go`
- CI 中以 `-fuzz=. -fuzztime=30s` 运行

### 7.2 Soak Testing

- 对长时间运行模块（schedulex、kafkax、natsx）补充 soak 测试
- 持续运行 ≥ 10 分钟，监控内存泄漏和 goroutine 泄漏
- 使用 `runtime.NumGoroutine()` 和 `runtime.ReadMemStats()` 断言
