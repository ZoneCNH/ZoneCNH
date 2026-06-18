# clickhousex 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.1
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/clickhousex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 clickhousex 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | ClickHouse 连接、批写、查询、迁移、TTL 与健康检查适配 |
| 文档目录 | module/clickhousex |
| 运行时代码目录 | /home/clickhousex |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | NewClient：创建 ClickHouse 客户端，连接池初始化，DSN 校验 | AC-001, AC-002 / TC-005 / TASK-CLICKHOUSEX-001 / ⬜ | - | TRACEABILITY.md |
| FR-002 | Exec：执行 DDL/DML，支持 context 取消、连接断开恢复 | AC-003, AC-004, AC-023 / TC-001, TC-002 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| FR-003 | Query：执行 OLAP 查询，返回可迭代 Rows，空结果无错误 | AC-005, AC-006 / TC-001 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| FR-004 | InsertBatch：原生 batch insert 协议批量写入，列校验，表存在检查 | AC-007, AC-008, AC-009, AC-010, AC-011 / TC-001, TC-003 / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| FR-005 | Health：连接池健康检查，返回 Ready/Live/Message | AC-016, AC-017, AC-022 / TC-006 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| FR-006 | Close：关闭连接池，幂等，等待进行中查询 | AC-015 / TC-007 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| FR-007 | Rows.Next/Scan/Close：结果集迭代、行扫描、类型映射 | AC-005, AC-012, AC-013, AC-014 / TC-001, TC-004 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |
| FR-008 | Rows.ColumnTypes：返回列名、ClickHouse 类型、Nullable 标志 | AC-014 / TC-004 / TASK-CLICKHOUSEX-003 / ⬜ | - | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | 连接池大小默认 10，最大 100，通过 Config 配置 | 连接资源浪费或不足 / AC-018, Config.Validate() / TASK-CLICKHOUSEX-001 / ⬜ | - | TRACEABILITY.md |
| BR-002 | 批量写入使用原生 batch insert 协议，不使用拼接 SQL | 写入性能差、SQL 注入风险 / AC-019, TC-003 / TASK-CLICKHOUSEX-004 / ⬜ | - | TRACEABILITY.md |
| BR-003 | Exec / Query 的 args 使用参数化绑定，禁止 SQL 拼接 | SQL 注入漏洞 / AC-020, TC-001 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-004 | 连接断开后自动重试 3 次（指数退避），超过后返回 ErrConnectionLost | 临时故障导致服务不可用 / AC-021, TC-002 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-005 | Health() 必须是幂等的、无副作用的 | 健康检查自身影响系统状态 / AC-022, TC-006 / TASK-CLICKHOUSEX-005 / ⬜ | - | TRACEABILITY.md |
| BR-006 | 所有操作必须接受 context.Context，支持取消和超时 | 操作无法被取消，goroutine 泄漏 / AC-023, FR-002/FR-003/FR-004 WHEN ctx 取消 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
| BR-007 | 错误消息格式："clickhousex: <operation>: <detail>" | 错误不可定位，跨模块排查困难 / AC-024, go test 错误消息断言 / TASK-CLICKHOUSEX-002 / ⬜ | - | TRACEABILITY.md |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-CLICKHOUSEX-001 | TASK-CLICKHOUSEX-001 | module/clickhousex/tasks/TASK-CLICKHOUSEX-001.md | - | tasks/TASK-CLICKHOUSEX-001.md |
| TASK-CLICKHOUSEX-002 | TASK-CLICKHOUSEX-002 | module/clickhousex/tasks/TASK-CLICKHOUSEX-002.md | - | tasks/TASK-CLICKHOUSEX-002.md |
| TASK-CLICKHOUSEX-003 | TASK-CLICKHOUSEX-003 | module/clickhousex/tasks/TASK-CLICKHOUSEX-003.md | - | tasks/TASK-CLICKHOUSEX-003.md |
| TASK-CLICKHOUSEX-004 | TASK-CLICKHOUSEX-004 | module/clickhousex/tasks/TASK-CLICKHOUSEX-004.md | - | tasks/TASK-CLICKHOUSEX-004.md |
| TASK-CLICKHOUSEX-005 | TASK-CLICKHOUSEX-005 | module/clickhousex/tasks/TASK-CLICKHOUSEX-005.md | - | tasks/TASK-CLICKHOUSEX-005.md |
| TASK-CLICKHOUSEX-006 | TASK-CLICKHOUSEX-006 | module/clickhousex/tasks/TASK-CLICKHOUSEX-006.md | - | tasks/TASK-CLICKHOUSEX-006.md |
| TASK-CLICKHOUSEX-007 | TASK-CLICKHOUSEX-007 | module/clickhousex/tasks/TASK-CLICKHOUSEX-007.md | - | tasks/TASK-CLICKHOUSEX-007.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/clickhousex/goal.md |
| SPEC.md | 存在 | module/clickhousex/SPEC.md |
| TRACEABILITY.md | 存在 | module/clickhousex/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/clickhousex/IMPLEMENTATION-PLAN.md |
| tasks/ | 7 个 Markdown 文件 | module/clickhousex/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/clickhousex 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
