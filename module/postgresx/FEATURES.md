# postgresx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.1.0
- Module-State: Tag Exists / Release Pending
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/postgresx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 postgresx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | PostgreSQL 连接池、事务、迁移、查询与健康检查适配 |
| 文档目录 | module/postgresx |
| 运行时代码目录 | /home/postgresx |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Config 与连接池生命周期 | New / Open 校验配置、填充默认值、初始 Ping 失败关闭池，Close 幂等 / TC-001, TC-008, /home/postgresx/pkg/postgresx/client.go / TASK-PG-001 | Done | TRACEABILITY.md |
| FR-002 | SQL 执行接口 | Exec、Query、QueryRow 保留 context 语义，Rows 暴露 Close 和 Err / TC-002, /home/postgresx/pkg/postgresx/query.go / TASK-PG-001 | Done | TRACEABILITY.md |
| FR-003 | 事务边界 | WithTx / WithTxOptions 覆盖 commit、rollback、context 取消和 panic 回滚 / TC-003, /home/postgresx/pkg/postgresx/tx.go / TASK-PG-002a | Done | TRACEABILITY.md |
| FR-004 | 迁移执行 | MigrationRunner.Up 升序执行未应用迁移，阻断重复版本和无效迁移 / TC-004, /home/postgresx/pkg/postgresx/migration.go / TASK-PG-002b | Done | TRACEABILITY.md |
| FR-005 | 健康检查与池状态 | Name / Check 符合 foundationx.HealthChecker，Stats 不泄露 Secret / TC-005, /home/postgresx/pkg/postgresx/health.go / TASK-PG-002a | Done | TRACEABILITY.md |
| FR-006 | 错误归一化与 retryability | PostgreSQL 和 context 错误映射到 foundationx 错误模型 / TC-006, /home/postgresx/pkg/postgresx/errors.go / TASK-PG-002b | Done | TRACEABILITY.md |
| FR-007 | 可观测适配与 Secret Hygiene | logger/metrics hook 可插拔，DSN 和参数不泄露 / TC-007, TC-009, /home/postgresx/contracts/metrics.md, /home/postgresx/pkg/postgresx/metrics.go / TASK-PG-003 | Done | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-PG-001 | TASK-PG-001 | module/postgresx/tasks/TASK-PG-001.md | - | tasks/TASK-PG-001.md |
| TASK-PG-002 | a 文件范围与验证 | - | - | IMPLEMENTATION-PLAN.md |
| TASK-PG-002A | TASK-PG-002a | module/postgresx/tasks/TASK-PG-002a.md | - | tasks/TASK-PG-002a.md |
| TASK-PG-002B | TASK-PG-002b | module/postgresx/tasks/TASK-PG-002b.md | - | tasks/TASK-PG-002b.md |
| TASK-PG-003 | TASK-PG-003 | module/postgresx/tasks/TASK-PG-003.md | - | tasks/TASK-PG-003.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/postgresx/goal.md |
| SPEC.md | 存在 | module/postgresx/SPEC.md |
| TRACEABILITY.md | 存在 | module/postgresx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/postgresx/IMPLEMENTATION-PLAN.md |
| tasks/ | 4 个 Markdown 文件 | module/postgresx/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/postgresx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
