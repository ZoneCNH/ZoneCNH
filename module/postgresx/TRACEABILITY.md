# postgresx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-12
Source: [SPEC.md](./SPEC.md), [goal.md](./goal.md), `/home/postgresx`

## Requirement Matrix

| Requirement | Description | Acceptance Criteria | Test / Evidence | Task | Status |
| ----------- | ----------- | ------------------- | --------------- | ---- | ------ |
| FR-001 | Config 与连接池生命周期 | `New` / `Open` 校验配置、填充默认值、初始 Ping 失败关闭池，`Close` 幂等 | TC-001, TC-008, `/home/postgresx/pkg/postgresx/client.go` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| FR-002 | SQL 执行接口 | `Exec`、`Query`、`QueryRow` 保留 context 语义，`Rows` 暴露 `Close` 和 `Err` | TC-002, `/home/postgresx/pkg/postgresx/query.go` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| FR-003 | 事务边界 | `WithTx` / `WithTxOptions` 覆盖 commit、rollback、context 取消和 panic 回滚 | TC-003, `/home/postgresx/pkg/postgresx/tx.go` | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| FR-004 | 迁移执行 | `MigrationRunner.Up` 升序执行未应用迁移，阻断重复版本和无效迁移 | TC-004, `/home/postgresx/pkg/postgresx/migration.go` | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| FR-005 | 健康检查与池状态 | `Name` / `Check` 符合 `foundationx.HealthChecker`，`Stats` 不泄露 Secret | TC-005, `/home/postgresx/pkg/postgresx/health.go` | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| FR-006 | 错误归一化与 retryability | PostgreSQL 和 context 错误映射到 `foundationx` 错误模型 | TC-006, `/home/postgresx/pkg/postgresx/errors.go` | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| FR-007 | 可观测适配与 Secret Hygiene | logger/metrics hook 可插拔，DSN 和参数不泄露 | TC-007, `contracts/metrics.md`, `/home/postgresx/pkg/postgresx/metrics.go` | [TASK-PG-003](./tasks/TASK-PG-003.md) | In Progress |
| BR-001 | 不依赖业务域仓库或入口仓库 | `go.mod` 仅含允许的基座依赖 | TC-008, `/home/postgresx/go.mod` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-002 | 不读取环境变量、配置文件或 Secret 文件 | 仅通过显式 `Config` 构造连接 | TC-001, `/home/postgresx/pkg/postgresx/config.go` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-003 | 不实现 ORM、schema ownership 或全局 DB | API 面只暴露客户端、查询、事务、迁移和健康检查 | TC-008, public API review | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-004 | 所有外部 I/O 入口接受 context | `New`、`Ping`、`Close`、查询、事务、迁移、健康检查均传入 context | TC-001, TC-002, TC-003, TC-004, TC-005, TC-006 | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-005 | `Rows` 生命周期和迭代错误可控 | 调用方关闭 `Rows`，通过 `Err` 获取迭代错误 | TC-002 | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-006 | 事务提交/回滚规则稳定 | nil 提交，error/context/panic 回滚，panic 后重新抛出 | TC-003 | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| BR-007 | 迁移版本正整数且单调执行 | 非正版本、空名称、空 SQL、重复版本阻断 | TC-004 | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| BR-008 | 健康检查幂等且安全 | 不输出密码、完整 DSN 或 SQL 参数 | TC-005, TC-007 | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| BR-009 | 指标适配不泄露敏感信息且命名一致 | 代码和 contract 采用同一指标命名规范 | TC-007, TC-009 | [TASK-PG-003](./tasks/TASK-PG-003.md) | In Progress |
| BR-010 | PostgreSQL 错误码映射稳定 | SQLSTATE 到 `foundationx` kind 和 retryability 的映射有测试 | TC-006 | [TASK-PG-002](./tasks/TASK-PG-002.md) | Done |
| BR-011 | 发布证据支持 `GOWORK=off` | `go test`、`go vet`、release evidence 不依赖 workspace | TC-008, `/home/postgresx/docs/EVIDENCE-20260601.md` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-012 | 版本、API 和文档一致 | `go.mod`、版本矩阵、contract、SPEC 同步 | TC-009 | [TASK-PG-003](./tasks/TASK-PG-003.md) | In Progress |

## Test Case Catalog

| Test Case | Requirement Coverage | Evidence |
| --------- | -------------------- | -------- |
| TC-001 | FR-001, BR-002, BR-004 | Config 默认值、校验、DSN 和 RedactedDSN 测试 |
| TC-002 | FR-002, BR-005 | Exec、Query、QueryRow、Rows Close/Err 测试 |
| TC-003 | FR-003, BR-006 | WithTx、WithTxOptions、rollback、panic、read-only 测试 |
| TC-004 | FR-004, BR-007 | MigrationRunner 升序、幂等、重复版本和无效迁移测试 |
| TC-005 | FR-005, BR-008 | HealthChecker、Ping、Stats、超时和安全元数据测试 |
| TC-006 | FR-006, BR-010 | MapError、IsRetryable、SQLSTATE 映射测试 |
| TC-007 | FR-007, BR-008, BR-009 | Logger、Metrics、Secret hygiene 测试 |
| TC-008 | FR-001, BR-001, BR-003, BR-011 | `GOWORK=off go test ./...`、`go vet ./...`、依赖边界检查 |
| TC-009 | BR-009, BR-012 | 指标名、Go 版本、public API contract 与 SPEC 一致性检查 |

## Open Items

| Item | Owner | Status |
| ---- | ----- | ------ |
| 统一指标命名：`postgresx_query_total` 与 `postgresx.query.total` 二选一 | TASK-PG-003 | 未完成 |
| 统一 Go baseline：`go.mod` 与版本矩阵一致 | TASK-PG-003 | 未完成 |
| 清理 public API contract 中未实现符号 | TASK-PG-003 | 未完成 |

---

追溯结论：FR 覆盖已完整，BR-002/005/006/008/009/010/011/012 已补入矩阵。当前阻断项集中在 v1.0 契约冻结，不影响 v0.1.0 candidate 的代码基线评分。
