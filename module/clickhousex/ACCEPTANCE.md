# clickhousex 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.1
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/clickhousex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 clickhousex 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/clickhousex/FEATURES.md && test -f module/clickhousex/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/clickhousex | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/clickhousex && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/clickhousex && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/clickhousex && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/clickhousex && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/clickhousex && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | 001 / NewClient 合法配置 → 返回 Client, nil 错误 | - | TRACEABILITY.md |
| AC-002 | FR-001 | 001 / NewClient 空 DSN → 返回 ErrInvalidConfig | - | TRACEABILITY.md |
| AC-003 | FR-002 | 002 / Exec 正常 SQL → 返回 nil | - | TRACEABILITY.md |
| AC-004 | FR-002 | 002 / Exec 语法错误 → 返回包装后的 ClickHouse 错误 | - | TRACEABILITY.md |
| AC-005 | FR-003, FR-007 | 003 / Query 有结果 → Rows 可迭代，Next() 返回 true | - | TRACEABILITY.md |
| AC-006 | FR-003 | 003 / Query 无结果 → 空 Rows，Next() 首次返回 false，nil 错误 | - | TRACEABILITY.md |
| AC-007 | FR-004 | 004 / InsertBatch 正常写入 → 返回 nil | - | TRACEABILITY.md |
| AC-008 | FR-004 | 004 / InsertBatch 空 rows → 返回 nil（空操作） | - | TRACEABILITY.md |
| AC-009 | FR-004 | 004 / InsertBatch 空 cols → 返回 ErrEmptyColumns | - | TRACEABILITY.md |
| AC-010 | FR-004 | 004 / InsertBatch 列数不匹配 → 返回 ErrColumnCountMismatch，含行号 | - | TRACEABILITY.md |
| AC-011 | FR-004, BR-010 | 004 / InsertBatch 表不存在 → 返回 ErrTableNotFound，不自动建表 | - | TRACEABILITY.md |
| AC-012 | FR-007 | 003 / Scan 列数不匹配 → 返回 ErrColumnCountMismatch | - | TRACEABILITY.md |
| AC-013 | FR-007, BR-011 | 003 / Scan Nullable 列到非指针类型 → 返回 ErrTypeMismatch | - | TRACEABILITY.md |
| AC-014 | FR-007, FR-008 | 003 / ColumnTypes 返回列名、ClickHouse 类型、Nullable 标志 | - | TRACEABILITY.md |
| AC-015 | FR-006, BR-009 | 005 / Close 幂等 → 多次调用不 panic，返回 nil | - | TRACEABILITY.md |
| AC-016 | FR-005 | 005 / Health 连接正常 → Ready=true, Live=true | - | TRACEABILITY.md |
| AC-017 | FR-005 | 005 / Health 连接异常 → Ready=false, Live=false | - | TRACEABILITY.md |
| AC-018 | BR-001 | 001 / 连接池默认 size=10, max=100，Config 可覆盖 | - | TRACEABILITY.md |
| AC-019 | BR-002 | 004 / 批量写入使用 ClickHouse 原生 batch insert 协议 | - | TRACEABILITY.md |
| AC-020 | BR-003 | 002 / SQL 参数使用占位符绑定，非字符串拼接 | - | TRACEABILITY.md |
| AC-021 | BR-004 | 002 / 连接断开后自动重试 3 次（指数退避），超过后返回 ErrConnectionLost | - | TRACEABILITY.md |
| AC-022 | BR-005 | 005 / Health() 多次调用结果一致，无副作用 | - | TRACEABILITY.md |
| AC-023 | BR-006 | 002 / ctx 取消/超时时操作中断，返回 ctx.Err() | - | TRACEABILITY.md |
| AC-024 | BR-007 | 002 / 错误消息格式为 "clickhousex: : " | - | TRACEABILITY.md |
| AC-025 | BR-008 | 006 / metrics 包含 table 标签（写入）或 query 标签（查询） | - | TRACEABILITY.md |
| AC-026 | BR-012 | 003 / Decimal 类型映射到 decimal.Decimal，无精度丢失 | - | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-002, FR-003, FR-004, FR-007, BR-003 | Given ClickHouse 可用且表已创建，When InsertBatch 写入 100 行，Then 返回 nil；When Query 查询这些行，Then 返回 100 行结果 | - | TRACEABILITY.md |
| TC-002 | FR-002, BR-004 | Given Client 已创建，When ClickHouse 临时不可达，Then Exec 返回 ErrConnectionLost；When ClickHouse 恢复，Then Exec 成功，自动重连 | - | TRACEABILITY.md |
| TC-003 | FR-004, BR-002 | Given 100000 行数据，When 调用 InsertBatch，Then 使用 batch insert 协议，< 1s 完成 | - | TRACEABILITY.md |
| TC-004 | FR-007, FR-008, BR-011 | Given 表有 Nullable(Int32) 列，When 查询该列为 NULL 的行，Then Scan 到 *int32 类型，值为 nil | - | TRACEABILITY.md |
| TC-005 | FR-001 | Given DSN 缺失或格式非法，When 创建 NewClient，Then 返回配置错误且不建立连接 | - | TRACEABILITY.md |
| TC-006 | FR-005, BR-005 | Given ClickHouse 连接正常，When 调用 Health，Then 返回 healthy；连接失败时返回 unhealthy | - | TRACEABILITY.md |
| TC-007 | FR-006, BR-009 | Given client 已关闭，When 再次调用 Close，Then 返回 nil 且不 panic | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | NewClient：创建 ClickHouse 客户端，连接池初始化，DSN 校验 | AC-001, AC-002 / TC-005 / TASK-CLICKHOUSEX-001 / ⬜ | - | TRACEABILITY.md |
| FR-002 | Exec：执行 DDL/DML，支持 context 取消、连接断开恢复 | AC-003, AC-004, AC-023 / TC-001, TC-002 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| FR-003 | Query：执行 OLAP 查询，返回可迭代 Rows，空结果无错误 | AC-005, AC-006 / TC-001 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| FR-004 | InsertBatch：原生 batch insert 协议批量写入，列校验，表存在检查 | AC-007, AC-008, AC-009, AC-010, AC-011 / TC-001, TC-003 / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| FR-005 | Health：连接池健康检查，返回 Ready/Live/Message | AC-016, AC-017, AC-022 / TC-006 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| FR-006 | Close：关闭连接池，幂等，等待进行中查询 | AC-015 / TC-007 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| FR-007 | Rows.Next/Scan/Close：结果集迭代、行扫描、类型映射 | AC-005, AC-012, AC-013, AC-014 / TC-001, TC-004 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| FR-008 | Rows.ColumnTypes：返回列名、ClickHouse 类型、Nullable 标志 | AC-014 / TC-004 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| BR-001 | 连接池大小默认 10，最大 100，通过 Config 配置 | 连接资源浪费或不足 / AC-018, Config.Validate() / TASK-CLICKHOUSEX-001 / ⬜ | - | TRACEABILITY.md |
| BR-002 | 批量写入使用原生 batch insert 协议，不使用拼接 SQL | 写入性能差、SQL 注入风险 / AC-019, TC-003 / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| BR-003 | Exec / Query 的 args 使用参数化绑定，禁止 SQL 拼接 | SQL 注入漏洞 / AC-020, TC-001 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-004 | 连接断开后自动重试 3 次（指数退避），超过后返回 ErrConnectionLost | 临时故障导致服务不可用 / AC-021, TC-002 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-005 | Health() 必须是幂等的、无副作用的 | 健康检查自身影响系统状态 / AC-022, TC-006 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| BR-006 | 所有操作必须接受 context.Context，支持取消和超时 | 操作无法被取消，goroutine 泄漏 / AC-023, FR-002/FR-003/FR-004 WHEN ctx 取消 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-007 | 错误消息格式："clickhousex: : " | 错误不可定位，跨模块排查困难 / AC-024, go test 错误消息断言 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-008 | 可观测指标必须包含 table 标签（写入操作）或 query 标签（查询操作） | 指标不可区分，监控失效 / AC-025, metrics 测试 / TASK-CLICKHOUSEX-006 / ⬜ | - | TRACEABILITY.md |
| BR-009 | Close() 必须是幂等的，多次调用不 panic | 重复关闭导致 panic / AC-015, TC-007 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| BR-010 | InsertBatch 不自动建表，表不存在时返回明确错误 | 意外建表、写入到错误表 / AC-011, FR-004 WHEN table 不存在 / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| BR-011 | ClickHouse Nullable 类型映射到 Go 指针类型 | 类型错误、NULL 值丢失 / AC-013, TC-004 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| BR-012 | ClickHouse Decimal 类型映射到 shopspring/decimal 或 apd.Decimal | 精度丢失 / AC-026, 类型映射表测试 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| NFR-001 | 单次 Exec 性能 | < 10ms / Benchmark BenchmarkExec / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| NFR-002 | InsertBatch 10000 行性能 | < 1s / Benchmark BenchmarkInsertBatch / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| NFR-003 | InsertBatch 100000 行性能 | < 10s / Benchmark BenchmarkInsertBatchLarge / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| NFR-004 | 单次 OLAP 查询性能 | < 100ms / Benchmark BenchmarkQuery / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| NFR-005 | 复杂聚合查询性能 | < 1s / Benchmark BenchmarkAggQuery / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| NFR-006 | 连接池获取连接性能 | < 1ms / Benchmark BenchmarkPoolAcquire / TASK-CLICKHOUSEX-001 / ⬜ | - | TRACEABILITY.md |
| NFR-007 | 常驻内存（空闲） | < 5MB / Profiling go test -memprofile / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-008 | 单元测试覆盖率 | ≥ 80% / go tool cover -func / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-009 | 编译通过 | 零错误 / go build ./... / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-010 | race 检测通过 | 零 data race / go test -race ./... / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-011 | vet 检查通过 | 零警告 / go vet ./... / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-012 | lint 检查通过 | 零错误 / golangci-lint run / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-013 | Secret 扫描通过 | 零命中 / gitleaks detect --no-git / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-014 | DSN 不泄露到日志 | 密码用 *** 替代 / review 日志输出格式 / TASK-CLICKHOUSEX-001 / ⬜ | - | TRACEABILITY.md |
| NFR-015 | 无直接依赖 configx | `go list -deps ./...` 输出不包含 configx / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |
| NFR-016 | metrics 指标输出正确 | histogram/counter/gauge 类型正确 / metrics 测试 / TASK-CLICKHOUSEX-006 / ⬜ | - | TRACEABILITY.md |
| NFR-017 | tracing span 传播正确 | exec/query/insert_batch span / tracing 测试 / TASK-CLICKHOUSEX-006 / ⬜ | - | TRACEABILITY.md |
| NFR-018 | 集成测试 ClickHouse 不可达时 skip | go test -tags=integration / 集成测试 CI gate / TASK-CLICKHOUSEX-007 / ⬜ | - | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/clickhousex 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收。
