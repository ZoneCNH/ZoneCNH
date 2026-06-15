# redisx 需求追溯矩阵

> 更新：2026-06-16
> 来源：module/redisx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## §1 功能需求追溯（FR）

| FR | Description | WHEN | THEN | AC | TC | Task | Status |
|----|-------------|------|------|----|----|------|--------|
| FR-001 | KeyBuilder 与命名空间隔离 | 调用 KeyBuilder 基于 namespace/env/service/version/entity/id/purpose 构造 Key | 输出确定性 Key 和脱敏 pattern，拒绝空 segment、非法字符、超长 segment、直接业务裸 Key | AC-001-1 | TC-001 | TASK-REDISX-001 | Pending |
| FR-002 | typed Options、New/Close 与连接生命周期 | 调用 `New(ctx, Options)` | 使用 typed Options 创建 Redis client、连接池、timeout、DB、TLS、Codec 和 kernel 生命周期 hook；多次 Close 幂等释放资源 | AC-002-1 | TC-002 | TASK-REDISX-000 | Pending |
| FR-003 | KV Get/Set/Del | 调用 KV Get/Set/Del | 所有调用尊重 context、Codec 和错误映射；missing key 返回 ErrNotFound，Del 对不存在 Key 幂等 | AC-003-1 | TC-003 | TASK-REDISX-002 | Pending |
| FR-004 | Exists/Expire 与默认 TTL 策略 | 调用 Exists/Expire/TTL 或使用默认 TTL 策略 | 返回存在数量、更新/读取 TTL，对未显式 TTL 的缓存写入应用默认 TTL 与 jitter | AC-004-1 | TC-004 | TASK-REDISX-002 | Pending |
| FR-005 | CacheClient cache-aside、null-cache、防击穿 | 调用 CacheClient.GetOrLoad/Set/Invalidate | 支持 cache-aside、null-cache、防击穿单进程合并、TTL jitter 和 Codec 解码失败处理 | AC-005-1 | TC-005 | TASK-REDISX-003 | Pending |
| FR-006 | Hash/List 最小封装 | 调用 Hash/List 最小封装 | HGet/HSet、LPush/LRange 提供稳定语义，missing field/key 返回可识别状态或空结果 | AC-006-1 | TC-006 | TASK-REDISX-004 | Pending |
| FR-007 | Pub/Sub Publish/Subscribe | 调用 Publish 或 Subscribe | 发布返回订阅者数量，订阅尊重 context cancellation，重连失败通过错误事件返回并释放资源 | AC-007-1 | TC-007 | TASK-REDISX-004 | Pending |
| FR-008 | Pipeline 有序批量执行 | 调用 Pipeline 添加命令并 Exec(ctx) | 以单次网络往返提交非原子批量命令，按排队顺序返回结果，暴露部分错误 | AC-008-1 | TC-008 | TASK-REDISX-005 | Pending |
| FR-009 | token owner 分布式锁 | 调用 Locker.Acquire/Renew/Release | 使用 token owner、TTL、续期和 Lua guarded release，禁止释放其他 owner 的锁 | AC-009-1 | TC-009 | TASK-REDISX-006 | Pending |
| FR-010 | Counter 与 fixed-window RateLimitHelper | 调用 Counter 或 fixed-window RateLimitHelper | 原子执行 incr/add/get/reset/allow，返回 remaining/resetAt，保证窗口 TTL | AC-010-1 | TC-010 | TASK-REDISX-007 | Pending |
| FR-011 | JSON 默认 Codec 与自定义 Codec SPI | 使用默认 Codec 或注入自定义 Codec | 默认 JSON 稳定，Decode 接收目标类型，自定义 Codec 错误被分类且不泄露完整 Key | AC-011-1 | TC-011 | TASK-REDISX-000, TASK-REDISX-003 | Pending |
| FR-012 | Health、pool stats 与观测 hooks | 调用 Health(ctx)、读取 pool stats 或执行 Redis 操作 | 输出 PING 状态、pool active/idle、低基数指标/log hooks 和脱敏错误 | AC-012-1 | TC-012 | TASK-REDISX-008, TASK-REDISX-009 | Pending |

---

## §2 业务规则追溯（BR）

| BR | Rule | 违反后果 | Verification Method | Task | Status |
|----|------|----------|---------------------|------|--------|
| BR-001 | Key 必须包含 namespace/env/service/version/entity/id 或 purpose，禁止业务直接传入裸 Key | Key 无法治理和脱敏 | TC-001：裸 Key 和非法 segment 被拒绝 | TASK-REDISX-001 | Pending |
| BR-002 | 配置只能通过 typed Options 注入；redisx 不读取文件、环境变量或配置中心 | 配置入口混乱，依赖隐式 | TC-002：Options 默认值和校验路径不依赖配置包 | TASK-REDISX-001 | Pending |
| BR-003 | 所有网络操作必须接受 context.Context 并尊重取消、deadline 和超时 | 操作无法取消，资源泄漏 | TC-003, TC-006, TC-008, TC-010：关键操作覆盖 context cancel/deadline 测试 | TASK-REDISX-002, TASK-REDISX-004, TASK-REDISX-005, TASK-REDISX-007 | Pending |
| BR-004 | 缓存写入必须有明确 TTL 策略；默认 TTL 不得为无意永不过期，并应支持 jitter | 内存无限增长 | TC-004, TC-005, TC-010：默认 TTL、显式 no-expire 和 jitter 语义被区分 | TASK-REDISX-002, TASK-REDISX-003, TASK-REDISX-007 | Pending |
| BR-005 | 分布式锁必须使用唯一 holder token、TTL、续期和释放校验 | 误释放其他 owner 的锁，数据竞争 | TC-009：token mismatch 时 Release 不删除锁 | TASK-REDISX-006 | Pending |
| BR-006 | Pipeline 是有序、非原子批量执行；部分失败必须返回有序结果和第一个错误 | 结果语义不可诊断 | TC-008：文档和测试覆盖非原子与部分错误 | TASK-REDISX-005 | Pending |
| BR-007 | 错误必须分类并脱敏；日志、metrics 和 trace 不得包含完整 Key、连接串或凭据 | 敏感信息泄露 | TC-002, TC-005, TC-009：错误包装和 hook payload 不包含敏感值 | TASK-REDISX-000, TASK-REDISX-003, TASK-REDISX-006 | Pending |
| BR-008 | 重试、重连和熔断只能通过本地 hooks 或上层 adapter 接入，不直接依赖 resiliencx | 破坏 foundation deps | TC-012：hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖 | TASK-REDISX-008 | Pending |
| BR-009 | 指标标签必须低基数，只允许 operation、status、error_code、client、key_pattern | 观测系统成本失控 | TC-012：hook/metric 测试拒绝完整 Key 标签 | TASK-REDISX-008 | Pending |
| BR-010 | 生产代码直接依赖仅限 stdlib、kernel 和 Redis client library | 破坏 foundation deps | TC-002, TC-012 + CI Gate：静态依赖守卫禁止直接 import configx/observex/resiliencx/contracts | TASK-REDISX-000, TASK-REDISX-008 | Pending |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Requirement | Verification | Task | Status |
|-----|----------|-------------|--------------|------|--------|
| NFR-001 | 质量 | 单元与契约测试覆盖所有公开接口、错误分类和依赖边界 | TC-002, TC-011 + `go test ./...` + dependency guard | TASK-REDISX-000 | Pending |
| NFR-002 | 质量 | 真实 Redis 集成测试覆盖成功路径、失败路径、并发路径和 context 取消 | TC-003, TC-007, TC-009, TC-010 + `go test -run Integration ./...`（REDIS_ADDR 显式开启） | TASK-REDISX-009 | Pending |
| NFR-003 | 性能 | 性能基线记录 KV、Pipeline、Locker、RateLimit 的 benchmark 预算，超预算需说明 | BenchmarkKV, BenchmarkPipeline, BenchmarkLocker, BenchmarkRateLimit + `go test -bench . ./...` | TASK-REDISX-009 | Pending |
| NFR-004 | 文档 | README、配置投影说明、迁移说明和发布证据齐全 | Documentation evidence：README 示例、CHANGELOG、DoD 证据和 task 链接完整 | TASK-REDISX-009 | Pending |

---

## §4 TC → FR 反向追溯

| TC | Covers FR(s) | Scenario | Command |
|----|-------------|----------|---------|
| TC-001 | FR-001, BR-001 | KeyBuilder 合法/非法 segment、版本、pattern；裸 Key 被拒绝 | `go test ./... -run TestKeyBuilder` |
| TC-002 | FR-002, BR-002, BR-007, BR-010, NFR-001 | Options 校验、New、Close、pool、lifecycle hook；纯 Options 配置入口；错误脱敏；依赖边界 | `go test ./... -run TestOptions` |
| TC-003 | FR-003, BR-003, NFR-002 | Get/Set/Del、ErrNotFound、Codec、context 取消 | `go test ./... -run TestKV` |
| TC-004 | FR-004, BR-004 | Exists/Expire/TTL/default TTL/jitter；永不过期防护 | `go test ./... -run TestTTL` |
| TC-005 | FR-005, BR-004, BR-007 | Cache hit/miss/null-cache/GetOrLoad 防击穿；错误脱敏 | `go test ./... -run TestCache` |
| TC-006 | FR-006, BR-003 | Hash/List 写入、读取、缺失和 context 取消 | `go test ./... -run TestHashList` |
| TC-007 | FR-007, NFR-002 | Publish/Subscribe、取消、失败事件、资源释放 | `go test ./... -run TestPubSub` |
| TC-008 | FR-008, BR-003, BR-006 | Pipeline 有序结果、部分错误、非原子语义 | `go test ./... -run TestPipeline` |
| TC-009 | FR-009, BR-005, BR-007, NFR-002 | Lock acquire/renew/release、token mismatch、TTL；并发 | `go test ./... -run TestLocker` |
| TC-010 | FR-010, BR-003, BR-004, NFR-002 | Counter、RateLimit、并发、窗口 TTL | `go test ./... -run TestRateLimit` |
| TC-011 | FR-011, NFR-001 | JSON Codec、自定义 Codec、Encode/Decode 错误 | `go test ./... -run TestCodec` |
| TC-012 | FR-012, BR-008, BR-009, BR-010 | Health、PoolStats、HookEvent、指标名；低基数标签；依赖边界 | `go test ./... -run TestHealth` |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 | Verification |
|----|-----------|-------------|--------------|
| AC-001-1 | FR-001 | KeyBuilder 覆盖合法 Key、非法 segment、版本化 Key 和脱敏 pattern | TC-001 |
| AC-002-1 | FR-002 | Options 校验、New、Close、pool 参数和生命周期 hook 有单元或契约测试 | TC-002 |
| AC-003-1 | FR-003 | Get/Set/Del 覆盖存在、不存在、序列化失败、context 取消和删除幂等 | TC-003 |
| AC-004-1 | FR-004 | Exists/Expire/TTL/default TTL/jitter 均有测试，不允许缓存写入无意永不过期 | TC-004 |
| AC-005-1 | FR-005 | CacheClient 覆盖 hit、miss、loader error、null-cache、防击穿和 Codec 错误 | TC-005 |
| AC-006-1 | FR-006 | Hash/List 覆盖写入、读取、缺失、范围和 context 取消 | TC-006 |
| AC-007-1 | FR-007 | Pub/Sub 覆盖发布、接收、取消、连接失败和资源释放 | TC-007 |
| AC-008-1 | FR-008 | Pipeline 覆盖有序结果、部分错误、context 取消和非原子语义文档 | TC-008 |
| AC-009-1 | FR-009 | 锁竞争、TTL 到期、续期、误释放防护和 holder token 校验均通过 | TC-009 |
| AC-010-1 | FR-010 | Counter 与 RateLimitHelper 覆盖原子计数、窗口过期、并发和剩余额度 | TC-010 |
| AC-011-1 | FR-011 | 默认 JSON、自定义 Codec、Encode/Decode 错误和错误脱敏有测试 | TC-011 |
| AC-012-1 | FR-012 | Health、pool stats、hook 事件、指标名和低基数标签约束有测试 | TC-012 |
| AC-BR-001 | BR-001 | 裸 Key 和非法 segment 被拒绝 | TC-001 |
| AC-BR-002 | BR-002 | Options 默认值和校验路径不依赖配置包 | TC-002 |
| AC-BR-003 | BR-003 | 关键操作覆盖 context cancel/deadline 测试 | TC-003, TC-006, TC-008, TC-010 |
| AC-BR-004 | BR-004 | 默认 TTL、显式 no-expire 和 jitter 语义被区分 | TC-004, TC-005, TC-010 |
| AC-BR-005 | BR-005 | token mismatch 时 Release 不删除锁 | TC-009 |
| AC-BR-006 | BR-006 | 文档和测试覆盖非原子与部分错误 | TC-008 |
| AC-BR-007 | BR-007 | 错误包装和 hook payload 不包含敏感值 | TC-002, TC-005, TC-009 |
| AC-BR-008 | BR-008 | hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖 | TC-012 |
| AC-BR-009 | BR-009 | hook/metric 测试拒绝完整 Key 标签 | TC-012 |
| AC-BR-010 | BR-010 | 静态依赖守卫禁止直接 import configx/observex/resiliencx/contracts | TC-002, TC-012 + CI Gate |
| AC-NFR-001 | NFR-001 | go test ./...、接口编译测试、依赖守卫通过 | TC-002, TC-011 |
| AC-NFR-002 | NFR-002 | 集成测试可用 REDIS_ADDR 或 test harness 开启，默认短测不阻塞 | TC-003, TC-007, TC-009, TC-010 |
| AC-NFR-003 | NFR-003 | benchmark 结果记录在发布证据，超预算需说明 | BenchmarkKV, BenchmarkPipeline, BenchmarkLocker, BenchmarkRateLimit |
| AC-NFR-004 | NFR-004 | README 示例、CHANGELOG、DoD 证据和 task 链接完整 | Documentation evidence |
