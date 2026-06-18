# redisx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.1
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/redisx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 redisx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/redisx/FEATURES.md && test -f module/redisx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/redisx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/redisx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/redisx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/redisx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/redisx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/redisx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001-1 | FR-001 | KeyBuilder 覆盖合法 Key、非法 segment、版本化 Key 和脱敏 pattern / TC-001 | ✅ | TRACEABILITY.md |
| AC-002-1 | FR-002 | Options 校验、New、Close、pool 参数和生命周期 hook 有单元或契约测试 / TC-002 | ✅ | TRACEABILITY.md |
| AC-003-1 | FR-003 | Get/Set/Del 覆盖存在、不存在、序列化失败、context 取消和删除幂等 / TC-003 | ✅ | TRACEABILITY.md |
| AC-004-1 | FR-004 | Exists/Expire/TTL/default TTL/jitter 均有测试，不允许缓存写入无意永不过期 / TC-004 | ✅ | TRACEABILITY.md |
| AC-005-1 | FR-005 | CacheClient 覆盖 hit、miss、loader error、null-cache、防击穿和 Codec 错误 / TC-005 | ✅ | TRACEABILITY.md |
| AC-006-1 | FR-006 | Hash/List 覆盖写入、读取、缺失、范围和 context 取消 / TC-006 | ✅ | TRACEABILITY.md |
| AC-007-1 | FR-007 | Pub/Sub 覆盖发布、接收、取消、连接失败和资源释放 / TC-007 | ✅ | TRACEABILITY.md |
| AC-008-1 | FR-008 | Pipeline 覆盖有序结果、部分错误、context 取消和非原子语义文档 / TC-008 | ✅ | TRACEABILITY.md |
| AC-009-1 | FR-009 | 锁竞争、TTL 到期、续期、误释放防护和 holder token 校验均通过 / TC-009 | ✅ | TRACEABILITY.md |
| AC-010-1 | FR-010 | Counter 与 RateLimitHelper 覆盖原子计数、窗口过期、并发和剩余额度 / TC-010 | ✅ | TRACEABILITY.md |
| AC-011-1 | FR-011 | 默认 JSON、自定义 Codec、Encode/Decode 错误和错误脱敏有测试 / TC-011 | ✅ | TRACEABILITY.md |
| AC-012-1 | FR-012 | Health、pool stats、hook 事件、指标名和低基数标签约束有测试 / TC-012 | ✅ | TRACEABILITY.md |
| AC-BR-001 | BR-001 | 裸 Key 和非法 segment 被拒绝 / TC-001 | ✅ | TRACEABILITY.md |
| AC-BR-002 | BR-002 | Options 默认值和校验路径不依赖配置包 / TC-002 | ✅ | TRACEABILITY.md |
| AC-BR-003 | BR-003 | 关键操作覆盖 context cancel/deadline 测试 / TC-003, TC-006, TC-008, TC-010 | ✅ | TRACEABILITY.md |
| AC-BR-004 | BR-004 | 默认 TTL、显式 no-expire 和 jitter 语义被区分 / TC-004, TC-005, TC-010 | ✅ | TRACEABILITY.md |
| AC-BR-005 | BR-005 | token mismatch 时 Release 不删除锁 / TC-009 | ✅ | TRACEABILITY.md |
| AC-BR-006 | BR-006 | 文档和测试覆盖非原子与部分错误 / TC-008 | ✅ | TRACEABILITY.md |
| AC-BR-007 | BR-007 | 错误包装和 hook payload 不包含敏感值 / TC-002, TC-005, TC-009 | ✅ | TRACEABILITY.md |
| AC-BR-008 | BR-008 | hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖 / TC-012 | ✅ | TRACEABILITY.md |
| AC-BR-009 | BR-009 | hook/metric 测试拒绝完整 Key 标签 / TC-012 | ✅ | TRACEABILITY.md |
| AC-BR-010 | BR-010 | 静态依赖守卫禁止直接 import configx/observex/resiliencx/contracts / TC-002, TC-012 + CI Gate | ✅ | TRACEABILITY.md |
| AC-NFR-001 | NFR-001 | go test ./...、接口编译测试、依赖守卫通过 / TC-002, TC-011 | ✅ | TRACEABILITY.md |
| AC-NFR-002 | NFR-002 | 集成测试可用 REDIS_ADDR 或 test harness 开启，默认短测不阻塞 / TC-003, TC-007, TC-009, TC-010 | ✅ | TRACEABILITY.md |
| AC-NFR-003 | NFR-003 | benchmark 结果记录在发布证据，超预算需说明 / BenchmarkKV, BenchmarkPipeline, BenchmarkLocker, BenchmarkRateLimit | ✅ | TRACEABILITY.md |
| AC-NFR-004 | NFR-004 | README 示例、CHANGELOG、DoD 证据和 task 链接完整 / Documentation evidence | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, BR-001 | go test ./... -run TestKeyBuilder | - | TRACEABILITY.md |
| TC-002 | FR-002, BR-002, BR-007, BR-010, NFR-001 | go test ./... -run TestOptions | - | TRACEABILITY.md |
| TC-003 | FR-003, BR-003, NFR-002 | go test ./... -run TestKV | - | TRACEABILITY.md |
| TC-004 | FR-004, BR-004 | go test ./... -run TestTTL | - | TRACEABILITY.md |
| TC-005 | FR-005, BR-004, BR-007 | go test ./... -run TestCache | - | TRACEABILITY.md |
| TC-006 | FR-006, BR-003 | go test ./... -run TestHashList | - | TRACEABILITY.md |
| TC-007 | FR-007, NFR-002 | go test ./... -run TestPubSub | - | TRACEABILITY.md |
| TC-008 | FR-008, BR-003, BR-006 | go test ./... -run TestPipeline | - | TRACEABILITY.md |
| TC-009 | FR-009, BR-005, BR-007, NFR-002 | go test ./... -run TestLocker | - | TRACEABILITY.md |
| TC-010 | FR-010, BR-003, BR-004, NFR-002 | go test ./... -run TestRateLimit | - | TRACEABILITY.md |
| TC-011 | FR-011, NFR-001 | go test ./... -run TestCodec | - | TRACEABILITY.md |
| TC-012 | FR-012, BR-008, BR-009, BR-010 | go test ./... -run TestHealth | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | KeyBuilder 与命名空间隔离 — 基于 namespace/env/service/version/entity/id/purpose 构造 Key，输出确定性 Key 和脱敏 pattern，拒绝空 segment、非法字符、超长 segment、直接业务裸 Key | AC-001-1 / TC-001 / go test ./... -run TestKeyBuilder | ✅ | TRACEABILITY.md |
| FR-002 | typed Options、New/Close 与连接生命周期 — 使用 typed Options 创建 Redis client、连接池、timeout、DB、TLS、Codec 和 kernel 生命周期 hook；多次 Close 幂等释放资源 | AC-002-1 / TC-002 / go test ./... -run TestOptions | ✅ | TRACEABILITY.md |
| FR-003 | KV Get/Set/Del — 所有调用尊重 context、Codec 和错误映射；missing key 返回 ErrNotFound，Del 对不存在 Key 幂等 | AC-003-1 / TC-003 / go test ./... -run TestKV | ✅ | TRACEABILITY.md |
| FR-004 | Exists/Expire 与默认 TTL 策略 — 返回存在数量、更新/读取 TTL，对未显式 TTL 的缓存写入应用默认 TTL 与 jitter | AC-004-1 / TC-004 / go test ./... -run TestTTL | ✅ | TRACEABILITY.md |
| FR-005 | CacheClient cache-aside、null-cache、防击穿 — 支持 cache-aside、null-cache、防击穿单进程合并、TTL jitter 和 Codec 解码失败处理 | AC-005-1 / TC-005 / go test ./... -run TestCache | ✅ | TRACEABILITY.md |
| FR-006 | Hash/List 最小封装 — HGet/HSet、LPush/LRange 提供稳定语义，missing field/key 返回可识别状态或空结果 | AC-006-1 / TC-006 / go test ./... -run TestHashList | ✅ | TRACEABILITY.md |
| FR-007 | Pub/Sub Publish/Subscribe — 发布返回订阅者数量，订阅尊重 context cancellation，重连失败通过错误事件返回并释放资源 | AC-007-1 / TC-007 / go test ./... -run TestPubSub | ✅ | TRACEABILITY.md |
| FR-008 | Pipeline 有序批量执行 — 以单次网络往返提交非原子批量命令，按排队顺序返回结果，暴露部分错误 | AC-008-1 / TC-008 / go test ./... -run TestPipeline | ✅ | TRACEABILITY.md |
| FR-009 | token owner 分布式锁 — 使用 token owner、TTL、续期和 Lua guarded release，禁止释放其他 owner 的锁 | AC-009-1 / TC-009 / go test ./... -run TestLocker | ✅ | TRACEABILITY.md |
| FR-010 | Counter 与 fixed-window RateLimitHelper — 原子执行 incr/add/get/reset/allow，返回 remaining/resetAt，保证窗口 TTL | AC-010-1 / TC-010 / go test ./... -run TestRateLimit | ✅ | TRACEABILITY.md |
| FR-011 | JSON 默认 Codec 与自定义 Codec SPI — 默认 JSON 稳定，Decode 接收目标类型，自定义 Codec 错误被分类且不泄露完整 Key | AC-011-1 / TC-011 / go test ./... -run TestCodec | ✅ | TRACEABILITY.md |
| FR-012 | Health、pool stats 与观测 hooks — 输出 PING 状态、pool active/idle、低基数指标/log hooks 和脱敏错误 | AC-012-1 / TC-012 / go test ./... -run TestHealth | ✅ | TRACEABILITY.md |
| BR-001 | Key 必须包含 namespace/env/service/version/entity/id 或 purpose，禁止业务直接传入裸 Key | TC-001 / 裸 Key 和非法 segment 被拒绝 | ✅ | TRACEABILITY.md |
| BR-002 | 配置只能通过 typed Options 注入；redisx 不读取文件、环境变量或配置中心 | TC-002 / Options 默认值和校验路径不依赖配置包 | ✅ | TRACEABILITY.md |
| BR-003 | 所有网络操作必须接受 context.Context 并尊重取消、deadline 和超时 | TC-003, TC-006, TC-008, TC-010 / 关键操作覆盖 context cancel/deadline 测试 | ✅ | TRACEABILITY.md |
| BR-004 | 缓存写入必须有明确 TTL 策略；默认 TTL 不得为无意永不过期，并应支持 jitter | TC-004, TC-005, TC-010 / 默认 TTL、显式 no-expire 和 jitter 语义被区分 | ✅ | TRACEABILITY.md |
| BR-005 | 分布式锁必须使用唯一 holder token、TTL、续期和释放校验 | TC-009 / token mismatch 时 Release 不删除锁 | ✅ | TRACEABILITY.md |
| BR-006 | Pipeline 是有序、非原子批量执行；部分失败必须返回有序结果和第一个错误 | TC-008 / 文档和测试覆盖非原子与部分错误 | ✅ | TRACEABILITY.md |
| BR-007 | 错误必须分类并脱敏；日志、metrics 和 trace 不得包含完整 Key、连接串或凭据 | TC-002, TC-005, TC-009 / 错误包装和 hook payload 不包含敏感值 | ✅ | TRACEABILITY.md |
| BR-008 | 重试、重连和熔断只能通过本地 hooks 或上层 adapter 接入，不直接依赖 resiliencx | TC-012 / hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖 | ✅ | TRACEABILITY.md |
| BR-009 | 指标标签必须低基数，只允许 operation、status、error_code、client、key_pattern | TC-012 / hook/metric 测试拒绝完整 Key 标签 | ✅ | TRACEABILITY.md |
| BR-010 | 生产代码直接依赖仅限 stdlib、kernel 和 Redis client library | TC-002, TC-012 / 静态依赖守卫禁止直接 import configx/observex/resiliencx/contracts + CI Gate | ✅ | TRACEABILITY.md |
| NFR-001 | 质量 | 单元与契约测试覆盖所有公开接口、错误分类和依赖边界 / go test ./... + dependency guard | ✅ | TRACEABILITY.md |
| NFR-002 | 质量 | 真实 Redis 集成测试覆盖成功路径、失败路径、并发路径和 context 取消 / go test -run Integration ./...（REDIS_ADDR 显式开启） | ✅ | TRACEABILITY.md |
| NFR-003 | 性能 | 性能基线记录 KV、Pipeline、Locker、RateLimit 的 benchmark 预算，超预算需说明 / go test -bench . ./... | ✅ | TRACEABILITY.md |
| NFR-004 | 文档 | README、配置投影说明、迁移说明和发布证据齐全 / Documentation evidence | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/redisx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收。
