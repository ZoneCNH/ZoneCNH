# postgresx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: [SPEC.md](./SPEC.md), [goal.md](./goal.md), `/home/postgresx`

---

## §1 功能需求追溯（FR）

| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Status |
| ----------- | ----------- | ------------------- | -------- | ---- | ------ |
| FR-001 | Config 与连接池生命周期 | `New` / `Open` 校验配置、填充默认值、初始 Ping 失败关闭池，`Close` 幂等 | TC-001, TC-008, `/home/postgresx/pkg/postgresx/client.go` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| FR-002 | SQL 执行接口 | `Exec`、`Query`、`QueryRow` 保留 context 语义，`Rows` 暴露 `Close` 和 `Err` | TC-002, `/home/postgresx/pkg/postgresx/query.go` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| FR-003 | 事务边界 | `WithTx` / `WithTxOptions` 覆盖 commit、rollback、context 取消和 panic 回滚 | TC-003, `/home/postgresx/pkg/postgresx/tx.go` | [TASK-PG-002a](./tasks/TASK-PG-002a.md) | Done |
| FR-004 | 迁移执行 | `MigrationRunner.Up` 升序执行未应用迁移，阻断重复版本和无效迁移 | TC-004, `/home/postgresx/pkg/postgresx/migration.go` | [TASK-PG-002b](./tasks/TASK-PG-002b.md) | Done |
| FR-005 | 健康检查与池状态 | `Name` / `Check` 符合 `foundationx.HealthChecker`，`Stats` 不泄露 Secret | TC-005, `/home/postgresx/pkg/postgresx/health.go` | [TASK-PG-002a](./tasks/TASK-PG-002a.md) | Done |
| FR-006 | 错误归一化与 retryability | PostgreSQL 和 context 错误映射到 `foundationx` 错误模型 | TC-006, `/home/postgresx/pkg/postgresx/errors.go` | [TASK-PG-002b](./tasks/TASK-PG-002b.md) | Done |
| FR-007 | 可观测适配与 Secret Hygiene | logger/metrics hook 可插拔，DSN 和参数不泄露 | TC-007, TC-009, `/home/postgresx/contracts/metrics.md`, `/home/postgresx/pkg/postgresx/metrics.go` | [TASK-PG-003](./tasks/TASK-PG-003.md) | Done |

---


| Requirement | Description | Acceptance Criteria | TC ID(s) | Task | Status |
| ----------- | ----------- | ------------------- | -------- | ---- | ------ |
| BR-001 | 不依赖业务域仓库或入口仓库 | `go.mod` 仅含允许的基座依赖 | TC-008, `/home/postgresx/go.mod` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-002 | 不读取环境变量、配置文件或 Secret 文件 | 仅通过显式 `Config` 构造连接 | TC-001, `/home/postgresx/pkg/postgresx/config.go` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-003 | 不实现 ORM、schema ownership 或全局 DB | API 面只暴露客户端、查询、事务、迁移和健康检查 | TC-008, public API review | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-004 | 所有外部 I/O 入口接受 context | `New`、`Ping`、`Close`、查询、事务、迁移、健康检查均传入 context | TC-001, TC-002, TC-003, TC-004, TC-005, TC-006 | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-005 | `Rows` 生命周期和迭代错误可控 | 调用方关闭 `Rows`，通过 `Err` 获取迭代错误 | TC-002 | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-006 | 事务提交/回滚规则稳定 | nil 提交，error/context/panic 回滚，panic 后重新抛出 | TC-003 | [TASK-PG-002a](./tasks/TASK-PG-002a.md) | Done |
| BR-007 | 迁移版本正整数且单调执行 | 非正版本、空名称、空 SQL、重复版本阻断 | TC-004 | [TASK-PG-002b](./tasks/TASK-PG-002b.md) | Done |
| BR-008 | 健康检查幂等且安全 | 不输出密码、完整 DSN 或 SQL 参数 | TC-005, TC-007 | [TASK-PG-002a](./tasks/TASK-PG-002a.md) | Done |
| BR-009 | 指标适配不泄露敏感信息且命名一致 | 代码和 contract 采用同一指标命名规范 | TC-007, TC-009 | [TASK-PG-003](./tasks/TASK-PG-003.md) | Done |
| BR-010 | PostgreSQL 错误码映射稳定 | SQLSTATE 到 `foundationx` kind 和 retryability 的映射有测试 | TC-006 | [TASK-PG-002b](./tasks/TASK-PG-002b.md) | Done |
| BR-011 | 发布证据支持 `GOWORK=off` | `go test`、`go vet`、release evidence 不依赖 workspace | TC-008, `/home/postgresx/docs/EVIDENCE-20260601.md`, `/home/postgresx/docs/RELEASE_MANIFEST-v1.0.0.md`, `/home/postgresx/release/manifest/v1.0.0.json` | [TASK-PG-001](./tasks/TASK-PG-001.md) | Done |
| BR-012 | 版本、API 和文档一致 | `go.mod`、版本矩阵、contract、SPEC 同步 | TC-009 | [TASK-PG-003](./tasks/TASK-PG-003.md) | Done |

---

## §3 非功能需求追溯（NFR）

| Requirement | Description | 目标值 | 验证方式 | Task | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | 单次 Exec 性能 | < 10ms | Benchmark | - | Deferred (v1.x) |
| NFR-002 | InsertBatch 100行 | < 50ms | Benchmark | - | Deferred (v1.x) |
| NFR-003 | 单次 Query 性能 | < 10ms | Benchmark | - | Deferred (v1.x) |
| NFR-004 | 连接池获取性能 | < 1ms | Benchmark | - | Deferred (v1.x) |
| NFR-005 | 常驻内存（空闲） | < 5MB | Profiling | - | Deferred (v1.x) |
| NFR-006 | 单元测试覆盖率 | >= 80% | go tool cover | TASK-PG-001 | Done |
| NFR-007 | race 检测通过 | 零 data race | go test -race | TASK-PG-001 | Done |
| NFR-008 | vet 检查通过 | 零警告 | go vet | TASK-PG-001 | Done |
| NFR-009 | lint 检查通过 | 零错误 | golangci-lint | TASK-PG-001 | Done |
| NFR-010 | Secret 扫描通过 | 零命中 | gitleaks | TASK-PG-001 | Done |

---

## §4 TC→FR 反向追溯

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

---

## §5 全局 AC 注册表

| Acceptance Criterion | Requirement | Test Case | Current Evidence |
| -------------------- | ----------- | --------- | ---------------- |
| AC-001 | FR-001 | TC-001 | Covered by TC-001 test evidence |
| AC-002 | FR-002 | TC-002 | Covered by TC-002 test evidence |
| AC-003 | FR-003 | TC-003 | Covered by TC-003 test evidence |
| AC-004 | FR-004 | TC-004 | Covered by TC-004 test evidence |
| AC-005 | FR-005 | TC-005 | Covered by TC-005 test evidence |
| AC-006 | FR-006 | TC-006 | Covered by TC-006 test evidence |
| AC-007 | FR-007 | TC-007 | Covered by TC-007 test evidence |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 7 | 7 | 100% |
| BR (业务规则) | 12 | 12 | 100% |


| NFR (非功能需求) | 10 | 5 | 50% |
| AC (验收标准) | 7 | 7 | 100% |
| TC (测试用例) | 9 | 9 | 100% |
| **合计** | **45** | **40** | **88.9%** |

> 说明：NFR-001~NFR-005 标记为 Deferred (v1.x)，未计入 Done。所有 FR/BR/AC/TC 全部 Done。Task 总数 = TASK-PG-001/002a/002b/003 共 4 项，均已关闭。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线对齐：Requirement Matrix 拆分为 §1 FR/§2 BR 独立表；Test Case Catalog 重编号为 §4 TC→FR 反向追溯；Acceptance Criteria Linkage 重编号为 §5 全局 AC 注册表；新增 §6 覆盖率仪表盘；新增 §7 变更历史 |
| 2026-06-13 | 初始版本：FR/BR 混合 Requirement Matrix、Test Case Catalog、§3 NFR、Acceptance Criteria Linkage、Open Items |

---

## Open Items

| Item | Owner | Status |
| ---- | ----- | ------ |
| 统一指标命名：dotted `postgresx.*` 命名为 v1.0.0 contract | TASK-PG-003 | 已关闭 |
| 统一 Go baseline：`go.mod` 与版本矩阵一致 | TASK-PG-003 | 已关闭 |
| 清理 public API contract 中未实现符号 | TASK-PG-003 | 已关闭 |
| 下游真实接入证据 | 下游模块 | 后续跟踪 |

---

追溯结论：FR/BR 全部 Done，全部 4 Task（TASK-PG-001/002a/002b/003）已关闭；v1.0.0 发布证据已覆盖 GOWORK=off、contracts、race、secret scan 与真实 PostgreSQL integration。下游接入证据作为 v1.x/post-release 成熟度项跟踪，不计入 v1.0.0 发布范围扣分。
