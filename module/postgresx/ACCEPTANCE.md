# postgresx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/postgresx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 postgresx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/postgresx/FEATURES.md && test -f module/postgresx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/postgresx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/postgresx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/postgresx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/postgresx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/postgresx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/postgresx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | TC-001 / Covered by TC-001 test evidence | - | TRACEABILITY.md |
| AC-002 | FR-002 | TC-002 / Covered by TC-002 test evidence | - | TRACEABILITY.md |
| AC-003 | FR-003 | TC-003 / Covered by TC-003 test evidence | - | TRACEABILITY.md |
| AC-004 | FR-004 | TC-004 / Covered by TC-004 test evidence | - | TRACEABILITY.md |
| AC-005 | FR-005 | TC-005 / Covered by TC-005 test evidence | - | TRACEABILITY.md |
| AC-006 | FR-006 | TC-006 / Covered by TC-006 test evidence | - | TRACEABILITY.md |
| AC-007 | FR-007 | TC-007 / Covered by TC-007 test evidence | - | TRACEABILITY.md |
| AC-PGX-001 | FR-001 | New 校验配置+填充默认值+构造 pgxpool；初始 Ping 失败时关闭池；Close 幂等关闭后查询/事务返回已关闭错误 | - | SPEC.md |
| AC-PGX-002 | FR-002 | Exec/Query/QueryRow 转发底层 pgxpool 保留 context 取消/超时语义；Query 返回 Rows 时调用方负责 Close 且 Rows.Err() 暴露迭代错误 | - | SPEC.md |
| AC-PGX-003 | FR-003 | WithTx fn 返回 nil 时提交；fn 返回 error 或 ctx 取消时回滚；fn panic 时先回滚再重新抛出 | - | SPEC.md |
| AC-PGX-004 | FR-004 | MigrationRunner.Up 按版本升序执行未应用迁移并记录版本/名称/执行时间；版本重复/非正/名称空/SQL 空均拒绝返回错误 | - | SPEC.md |
| AC-PGX-005 | FR-005 | Name/Check 符合 HealthChecker 接口输出 healthy/degraded/unhealthy+耗时+安全元数据；Stats 返回池快照不暴露密码/DSN/SQL 参数 | - | SPEC.md |
| AC-PGX-006 | FR-006 | MapError 将 PostgreSQL/context 错误归一化为结构化 Error；IsRetryable 正确暴露可重试语义 | - | SPEC.md |
| AC-PGX-007 | FR-007 | WithLogger/WithMetrics 适配器正确记录查询/事务/健康/池状态；Config.RedactedDSN() 隐藏密码；日志/指标不含完整连接串或 SQL 参数值 | - | SPEC.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, BR-002, BR-004 | Config 默认值、校验、DSN 和 RedactedDSN 测试 | - | TRACEABILITY.md |
| TC-002 | FR-002, BR-005 | Exec、Query、QueryRow、Rows Close/Err 测试 | - | TRACEABILITY.md |
| TC-003 | FR-003, BR-006 | WithTx、WithTxOptions、rollback、panic、read-only 测试 | - | TRACEABILITY.md |
| TC-004 | FR-004, BR-007 | MigrationRunner 升序、幂等、重复版本和无效迁移测试 | - | TRACEABILITY.md |
| TC-005 | FR-005, BR-008 | HealthChecker、Ping、Stats、超时和安全元数据测试 | - | TRACEABILITY.md |
| TC-006 | FR-006, BR-010 | MapError、IsRetryable、SQLSTATE 映射测试 | - | TRACEABILITY.md |
| TC-007 | FR-007, BR-008, BR-009 | Logger、Metrics、Secret hygiene 测试 | - | TRACEABILITY.md |
| TC-008 | FR-001, BR-001, BR-003, BR-011 | GOWORK=off go test ./...、go vet ./...、依赖边界检查 | - | TRACEABILITY.md |
| TC-009 | BR-009, BR-012 | 指标名、Go 版本、public API contract 与 SPEC 一致性检查 | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Config 与连接池生命周期 | New / Open 校验配置、填充默认值、初始 Ping 失败关闭池，Close 幂等 / TC-001, TC-008, /home/postgresx/pkg/postgresx/client.go / TASK-PG-001 | Done | TRACEABILITY.md |
| FR-002 | SQL 执行接口 | Exec、Query、QueryRow 保留 context 语义，Rows 暴露 Close 和 Err / TC-002, /home/postgresx/pkg/postgresx/query.go / TASK-PG-001 | Done | TRACEABILITY.md |
| FR-003 | 事务边界 | WithTx / WithTxOptions 覆盖 commit、rollback、context 取消和 panic 回滚 / TC-003, /home/postgresx/pkg/postgresx/tx.go / TASK-PG-002a | Done | TRACEABILITY.md |
| FR-004 | 迁移执行 | MigrationRunner.Up 升序执行未应用迁移，阻断重复版本和无效迁移 / TC-004, /home/postgresx/pkg/postgresx/migration.go / TASK-PG-002b | Done | TRACEABILITY.md |
| FR-005 | 健康检查与池状态 | Name / Check 符合 foundationx.HealthChecker，Stats 不泄露 Secret / TC-005, /home/postgresx/pkg/postgresx/health.go / TASK-PG-002a | Done | TRACEABILITY.md |
| FR-006 | 错误归一化与 retryability | PostgreSQL 和 context 错误映射到 foundationx 错误模型 / TC-006, /home/postgresx/pkg/postgresx/errors.go / TASK-PG-002b | Done | TRACEABILITY.md |
| FR-007 | 可观测适配与 Secret Hygiene | logger/metrics hook 可插拔，DSN 和参数不泄露 / TC-007, TC-009, /home/postgresx/contracts/metrics.md, /home/postgresx/pkg/postgresx/metrics.go / TASK-PG-003 | Done | TRACEABILITY.md |
| BR-001 | 不依赖业务域仓库或入口仓库 | go.mod 仅含允许的基座依赖 / TC-008, /home/postgresx/go.mod / TASK-PG-001 | Done | TRACEABILITY.md |
| BR-002 | 不读取环境变量、配置文件或 Secret 文件 | 仅通过显式 Config 构造连接 / TC-001, /home/postgresx/pkg/postgresx/config.go / TASK-PG-001 | Done | TRACEABILITY.md |
| BR-003 | 不实现 ORM、schema ownership 或全局 DB | API 面只暴露客户端、查询、事务、迁移和健康检查 / TC-008, public API review / TASK-PG-001 | Done | TRACEABILITY.md |
| BR-004 | 所有外部 I/O 入口接受 context | New、Ping、Close、查询、事务、迁移、健康检查均传入 context / TC-001, TC-002, TC-003, TC-004, TC-005, TC-006 / TASK-PG-001 | Done | TRACEABILITY.md |
| BR-005 | Rows 生命周期和迭代错误可控 | 调用方关闭 Rows，通过 Err 获取迭代错误 / TC-002 / TASK-PG-001 | Done | TRACEABILITY.md |
| BR-006 | 事务提交/回滚规则稳定 | nil 提交，error/context/panic 回滚，panic 后重新抛出 / TC-003 / TASK-PG-002a | Done | TRACEABILITY.md |
| BR-007 | 迁移版本正整数且单调执行 | 非正版本、空名称、空 SQL、重复版本阻断 / TC-004 / TASK-PG-002b | Done | TRACEABILITY.md |
| BR-008 | 健康检查幂等且安全 | 不输出密码、完整 DSN 或 SQL 参数 / TC-005, TC-007 / TASK-PG-002a | Done | TRACEABILITY.md |
| BR-009 | 指标适配不泄露敏感信息且命名一致 | 代码和 contract 采用同一指标命名规范 / TC-007, TC-009 / TASK-PG-003 | Done | TRACEABILITY.md |
| BR-010 | PostgreSQL 错误码映射稳定 | SQLSTATE 到 foundationx kind 和 retryability 的映射有测试 / TC-006 / TASK-PG-002b | Done | TRACEABILITY.md |
| BR-011 | 发布证据支持 GOWORK=off | go test、go vet、release evidence 不依赖 workspace / TC-008, /home/postgresx/docs/EVIDENCE-20260601.md, /home/postgresx/docs/RELEASE_MANIFEST-v1.0.0.md, /home/postgresx/release/manifest/v1.0.0.json / TASK-PG-001 | Done | TRACEABILITY.md |
| BR-012 | 版本、API 和文档一致 | go.mod、版本矩阵、contract、SPEC 同步 / TC-009 / TASK-PG-003 | Done | TRACEABILITY.md |
| NFR-001 | 单次 Exec 性能 | < 10ms / Benchmark / - / Deferred (v1.x) | - | TRACEABILITY.md |
| NFR-002 | InsertBatch 100行 | < 50ms / Benchmark / - / Deferred (v1.x) | - | TRACEABILITY.md |
| NFR-003 | 单次 Query 性能 | < 10ms / Benchmark / - / Deferred (v1.x) | - | TRACEABILITY.md |
| NFR-004 | 连接池获取性能 | < 1ms / Benchmark / - / Deferred (v1.x) | - | TRACEABILITY.md |
| NFR-005 | 常驻内存（空闲） | < 5MB / Profiling / - / Deferred (v1.x) | - | TRACEABILITY.md |
| NFR-006 | 单元测试覆盖率 | >= 80% / go tool cover / TASK-PG-001 | Done | TRACEABILITY.md |
| NFR-007 | race 检测通过 | 零 data race / go test -race / TASK-PG-001 | Done | TRACEABILITY.md |
| NFR-008 | vet 检查通过 | 零警告 / go vet / TASK-PG-001 | Done | TRACEABILITY.md |
| NFR-009 | lint 检查通过 | 零错误 / golangci-lint / TASK-PG-001 | Done | TRACEABILITY.md |
| NFR-010 | Secret 扫描通过 | 零命中 / gitleaks / TASK-PG-001 | Done | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/postgresx 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/postgresx 最新复验证据、下游接入成熟度证据与发布状态一致性需要归档。
