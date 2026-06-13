# postgresx 实现计划

> 来源：[SPEC.md](./SPEC.md)
> 生成日期：2026-06-14
> 最后更新：2026-06-14（TASK-PG-002 拆分 + 风险/回滚/里程碑补充）

---

## 1. 依赖 DAG

```text
TASK-PG-001 (Config + SQL 执行基线)
├── TASK-PG-002a (事务 + 健康检查)
├── TASK-PG-002b (迁移 + 错误归一化)
└── TASK-PG-003 (可观测契约 + 文档冻结) ← 依赖 002a + 002b
```

## 2. 实现阶段

### Phase 1: Foundation — 核心能力基线

| Task | Scope | FR/BR 覆盖 | Effort | Priority |
|------|-------|-----------|--------|----------|
| TASK-PG-001 | Config、连接池生命周期与 SQL 执行基线 | FR-001, FR-002, BR-001-005, BR-011 | 4h | P0 |
| TASK-PG-002a | 事务边界（WithTx/WithTxOptions）与健康检查（HealthChecker/Stats） | FR-003, FR-005, BR-006, BR-008 | 3h | P0 |
| TASK-PG-002b | 迁移执行（MigrationRunner）与错误归一化（MapError/IsRetryable） | FR-004, FR-006, BR-007, BR-010 | 3h | P0 |

#### TASK-PG-001 文件范围与验证

| 文件 | 验证命令 |
|------|---------|
| `pkg/postgresx/client.go` | `GOWORK=off go test -run "TestNew|TestOpen|TestClose|TestPing" ./pkg/postgresx/` |
| `pkg/postgresx/config.go` | `GOWORK=off go test -run TestConfig ./pkg/postgresx/` |
| `pkg/postgresx/query.go` | `GOWORK=off go test -run "TestExec|TestQuery|TestQueryRow|TestRows" ./pkg/postgresx/` |
| `pkg/postgresx/dsn.go` | (含于 config 测试) |
| `go.mod` | `GOWORK=off go vet ./...` |

#### TASK-PG-002a 文件范围与验证

| 文件 | 验证命令 |
|------|---------|
| `pkg/postgresx/tx.go` | `GOWORK=off go test -run "TestWithTx|TestTxOptions|TestTxPanic" ./pkg/postgresx/` |
| `pkg/postgresx/health.go` | `GOWORK=off go test -run "TestHealth|TestStats|TestName" ./pkg/postgresx/` |

#### TASK-PG-002b 文件范围与验证

| 文件 | 验证命令 |
|------|---------|
| `pkg/postgresx/migration.go` | `GOWORK=off go test -run "TestMigration|TestMigrationRunner" ./pkg/postgresx/` |
| `pkg/postgresx/errors.go` | `GOWORK=off go test -run "TestMapError|TestIsRetryable" ./pkg/postgresx/` |

### Phase 2: Quality Gate & Contract Freeze

| Task | Scope | FR/BR 覆盖 | Effort | Priority |
|------|-------|-----------|--------|----------|
| TASK-PG-003 | 可观测契约（Logger/Metrics hooks）与 v1.0 文档冻结 | FR-007, BR-009, BR-012 | 2h | P1 |

> Phase 2 无新增功能 Task（全部 7 FR 已在 Phase 1 覆盖），TASK-PG-003 聚焦 contract 一致性、指标命名冻结、版本矩阵对齐和 release evidence 收束。

#### TASK-PG-003 文件范围与验证

| 文件 | 验证命令 |
|------|---------|
| `pkg/postgresx/metrics.go` | `GOWORK=off go test -run "TestLogger|TestMetrics" ./pkg/postgresx/` |
| `pkg/postgresx/options.go` | (含于 metrics 测试) |
| `contracts/metrics.md` | `GOWORK=off VERSION=v1.0.0 make release-evidence-check` |
| `module/postgresx/SPEC.md` | CI: spec-lint, traceability-check |
| `module/postgresx/TRACEABILITY.md` | CI: traceability-check |

## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Phase 1: Foundation | 3 | 10h |
| Phase 2: Quality Gate & Contract Freeze | 1 | 2h |
| **Total** | **4** | **12h** |

## 4. 风险识别

| 风险 | 影响 | 可能性 | 缓解措施 |
|------|------|--------|---------|
| 迁移版本冲突导致启动失败 | 高 | 中 | `MigrationRunner` 自动检测重复版本并阻断，CI Gate 包含迁移测试 |
| 事务 panic 回滚后连接泄漏 | 高 | 低 | `WithTx` panic 路径先回滚再 re-panic，`go test -race` 覆盖 |
| PostgreSQL SQLSTATE 错误映射遗漏 | 中 | 中 | `MapError` 覆盖 6 类常见 SQLSTATE（认证/约束/序列化/连接/停机/no rows）；未映射错误降级为 `ErrInternal` |
| 指标命名代码与 contract 不一致 | 中 | 低 | TASK-PG-003 contract check gate 自动校验 dotted `postgresx.*` 命名 |
| DSN / 密码泄露到日志或指标 | 高 | 低 | `RedactedDSN()` 强制脱敏；gitleaks + secret scan gate 阻断 |
| GOWORK 依赖掩盖模块依赖问题 | 中 | 低 | 所有 release evidence 强制 `GOWORK=off`；`make release-final-check` 包含 workspace 隔离校验 |
| pgx/v5 或 foundationx 依赖 breaking change | 低 | 低 | `go.mod` 锁定版本；`Dependabot/Renovate` 升级前触发完整 CI |

## 5. 回滚策略

| 高风险项 | 回滚路径 |
|---------|---------|
| TASK-PG-002a（事务语义变更） | `WithTx` panic 路径已内建回滚；若 commit/rollback 契约变更导致下游问题，revert 到前一 tag 并发 patch release |
| TASK-PG-002b（迁移逻辑变更） | `MigrationRunner` 只做升序执行，不提供自动回滚；若迁移文件有误，修复迁移 SQL 后发 patch release |
| TASK-PG-002b（错误映射变更） | `MapError` 映射表变更需要同步更新所有依赖该映射的下游模块；通过 `foundationx` 版本矩阵管理兼容性 |
| TASK-PG-003（contract 变更） | contract 变更通过 VERSION_MATRIX 回退；不重写已发布的 `v1.0.0` tag；新 contract 以 v1.1.0 发布 |
| 整体 v1.0.0 | `git tag -d v1.0.0 && git push origin :v1.0.0` 后重新打 tag（仅在 release evidence 失败时） |

## 6. CI Gate 矩阵

| Gate | Phase | 条件 |
|------|-------|------|
| go build | All | 零错误 |
| go test | All | 全部通过 |
| go test -race | All | 零 data race |
| go vet | Final | 零警告 |
| coverage >= 80% | Final | 覆盖率达标 |
| golangci-lint | Final | 零错误 |
| gitleaks | Final | 零命中 |
| contract check | Final | metrics 命名一致、public API 无遗漏 |
| import check | Final | 无业务域反向依赖 |

## 7. 里程碑

| 里程碑 | 完成条件 | 状态 |
|--------|---------|:---:|
| M1: Core Client | TASK-PG-001 done，Config + SQL 执行基线可独立测试 | ✅ |
| M2: Advanced Features | TASK-PG-002a + TASK-PG-002b done，事务/迁移/健康检查/错误归一化覆盖 | ✅ |
| M3: v1.0.0 Release | TASK-PG-003 done，contract / metrics / version matrix 冻结，`v1.0.0` tag + GitHub release | ✅ |
