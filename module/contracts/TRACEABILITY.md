# contracts 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-14
Source: module/contracts/SPEC.md

## §1 功能需求追溯（FR）

| Requirement | Description | Acceptance Criteria | Test Case | Task | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | MarketDataProvider — Subscribe/GetSnapshot/GetHistory 端口 | AC-FR-001: 编译期检查通过，接口方法完整 | TC-001 | TASK-CONTRACTS-001 | Pending |
| FR-002 | MacroDataProvider — GetLatest/GetHistory/Subscribe 端口 | AC-FR-001: 编译期检查通过，接口方法完整 | TC-001 | TASK-CONTRACTS-001 | Pending |
| FR-003 | Event 接口 — EventID/EventType/Timestamp/Source 四方法 | AC-FR-002: Event 接口完整性 | TC-005 | TASK-CONTRACTS-002 | Pending |
| FR-004 | Topic 常量 — 全局唯一、点分命名 | AC-FR-003: Topic 无重复，命名合规 | TC-004 | TASK-CONTRACTS-002 | Pending |
| FR-005 | DTO 契约 — JSON tag snake_case、不可变、版本演进 | AC-FR-004: JSON round-trip + 不可变性 | TC-002, TC-007 | TASK-CONTRACTS-002 | Pending |
| FR-006 | Breaking Change 检测 — 接口/DTO 变更感知与版本升级 | AC-FR-005: breaking change 检测通过 | TC-003 | TASK-CONTRACTS-003 | Pending |
| FR-007 | Module Identity — README H1 与 go.mod module path 必须为 contracts | AC-007: Module Identity | TC-008 | TASK-CONTRACTS-005 | Pending |

## §2 业务规则追溯（BR）

| Requirement | Description | Acceptance Criteria | Verification | Task | Status |
| --- | --- | --- | --- | --- | --- |
| BR-001 | 所有跨域 DTO 必须在 contracts 中定义 | AC-FR-004: DTO集中定义 | TC-002 (JSON round-trip) | TASK-CONTRACTS-002 | Pending |
| BR-002 | 新增契约必须说明消费方、生产方和稳定期 | AC-BR-002: 契约三方说明 | CI Gate: PR 审查 (新增契约审查) | TASK-CONTRACTS-004 | Pending |
| BR-003 | 契约变更是 breaking change → 需要版本升级 | AC-FR-005: BC触发版本检查 | TC-003 | TASK-CONTRACTS-003 | Pending |
| BR-004 | 端口接口保持窄（3-5 个方法） | AC-BR-004: 方法数3-5 | TC-006 | TASK-CONTRACTS-001 | Pending |
| BR-005 | 事件 DTO 不可变（只读字段） | AC-FR-004: DTO不可变 | TC-007 | TASK-CONTRACTS-002 | Pending |
| BR-006 | Topic 常量全局唯一，使用点分命名 | AC-FR-003: Topic 值无重复，命名符合 `domain.action` | TC-004 | TASK-CONTRACTS-002 | Pending |
| BR-007 | 接口实现方必须有编译期检查 (`var _ Interface = (*Impl)(nil)`) | AC-FR-001: 编译期检查 | TC-001 | TASK-CONTRACTS-001 | Pending |
| BR-008 | contracts 只依赖 L2.5 领域共享层和 stdlib | AC-BR-008: 依赖纯洁 | CI Gate: `go mod tidy` + 依赖检查 | TASK-CONTRACTS-000 | Pending |
| BR-009 | DTO 的 JSON tag 必须使用 snake_case | AC-FR-004: JSON tag snake_case | TC-002 (JSON round-trip) | TASK-CONTRACTS-002 | Pending |
| BR-010 | 契约版本遵循 semver（breaking change → major） | AC-FR-005: semver版本策略 | TC-003 | TASK-CONTRACTS-003 | Pending |

## §3 非功能需求追溯（NFR）

| Requirement | Description | Acceptance Criteria | Verification | Task | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | 单元测试覆盖率 ≥ 80% | `go test -cover` 总覆盖率 ≥ 80% | CI Gate: 覆盖率检查 | TASK-CONTRACTS-003 | Pending |
| NFR-002 | `-race` 测试通过 | 无 data race | CI Gate: `go test -race` | TASK-CONTRACTS-003 | Pending |
| NFR-003 | `go vet` / `golangci-lint` 无错误 | vet 和 lint 零告警 | CI Gate: vet + lint | TASK-CONTRACTS-000, TASK-CONTRACTS-003 | Pending |
| NFR-004 | Secret 扫描通过 | 无泄露 secret | CI Gate: `gitleaks detect` | TASK-CONTRACTS-004 | Pending |
| NFR-005 | 公共 API 无破坏性变更（或已 bump major） | breaking change 检测通过 | CI Gate: breaking change 检查 | TASK-CONTRACTS-003 | Pending |
| NFR-006 | Benchmark 结果无 > 10% 回退 | benchmark 对比通过 | CI Gate: Benchmark 检查 | TASK-CONTRACTS-003 | Pending |
| NFR-007 | 文档齐全（README、CHANGELOG、godoc） | 所有公开接口有 godoc，README 完整 | Documentation evidence | TASK-CONTRACTS-004 | Pending |
| NFR-008 | 错误格式统一 `"contracts: <desc>"` | 所有错误变量符合格式约定 | TC-002, CI Gate: 错误格式检查 | TASK-CONTRACTS-000 | Pending |

## §4 TC→FR 反向追溯

| Test Case | 覆盖需求 | 测试类型 | 描述 |
| --- | --- | --- | --- |
| TC-001 | FR-001, FR-002, BR-007 | 编译期检查 | 端口接口编译期检查 (`var _ Interface = (*impl)(nil)`) |
| TC-002 | FR-005, BR-001, BR-009, NFR-008 | 单元测试 | DTO JSON round-trip 序列化/反序列化 |
| TC-003 | FR-006, BR-003, BR-010 | 单元测试 | Breaking change 检测（接口方法增删、DTO 字段变更） |
| TC-004 | FR-004, BR-006 | 单元测试 | Topic 常量唯一性检查 |
| TC-005 | FR-003 | 单元测试 | Event 接口完整性（所有 Event 实现满足接口） |
| TC-006 | BR-004 | 单元测试 | 端口接口方法数检查（3-5 方法） |
| TC-007 | FR-005, BR-005 | 单元测试 | DTO 不可变性检查 |
| TC-008 | FR-007 | 单元测试 | Module Identity（README H1 与 go.mod module 声明） |

## §5 全局 AC 注册表

| AC ID | 所属需求 | 验证方式 | 状态 |
| --- | --- | --- | --- |
| AC-FR-001 | FR-001, FR-002, BR-007 | TC-001 (编译期检查) | Pending |
| AC-FR-002 | FR-003 | TC-005 (Event 接口完整性) | Pending |
| AC-FR-003 | FR-004, BR-006 | TC-004 (Topic 唯一性) | Pending |
| AC-FR-004 | FR-005, BR-001, BR-005, BR-009 | TC-002 + TC-007 (JSON round-trip + 不可变性) | Pending |
| AC-FR-005 | FR-006, BR-003, BR-010 | TC-003 (Breaking change 检测) | Pending |
| AC-BR-002 | BR-002 | CI Gate (PR 审查: 消费方/生产方/稳定期说明) | Pending |
| AC-BR-004 | BR-004 | TC-006 (端口方法数 3-5) | Pending |
| AC-BR-008 | BR-008 | CI Gate (go mod tidy + 依赖检查) | Pending |
| AC-NFR-001 | NFR-001 | CI Gate (覆盖率 ≥ 80%) | Pending |
| AC-NFR-002 | NFR-002 | CI Gate (go test -race) | Pending |
| AC-NFR-003 | NFR-003 | CI Gate (vet + lint) | Pending |
| AC-NFR-004 | NFR-004 | CI Gate (gitleaks) | Pending |
| AC-NFR-005 | NFR-005 | CI Gate (breaking change 检查) | Pending |
| AC-NFR-006 | NFR-006 | CI Gate (benchmark 对比) | Pending |
| AC-NFR-007 | NFR-007 | Documentation evidence | Pending |
| AC-NFR-008 | NFR-008 | TC-002 + CI Gate (错误格式检查: `"contracts: <desc>"`) | Pending |

## §6 覆盖率仪表盘

| 类别 | 总数 | 已覆盖 | 覆盖率 | 状态 |
| --- | --- | --- | --- | --- |
| FR | 7 | 7 | 100% | ✅ |
| BR | 10 | 10 | 100% | ✅ |
| NFR | 8 | 8 | 100% | ✅ |
| TC | 8 | 8 | 100% | ✅ |
| AC | 16 | 16 | 100% | ✅ |
| Task | 5 | 5 | — | All Pending |

## §7 变更历史

| 日期 | 变更内容 | 作者 |
| --- | --- | --- |
| 2026-06-09 | 初始版本（迁移前全局矩阵） | ZoneCNH |
| 2026-06-14 | 完整重建：补全 BR-001/002/007/008/009/010 + NFR §1-§8 + TC→FR §4 + AC §5 + 仪表盘 §6 | ZoneCNH |
| 2026-06-14 | 修复：FR行AC列改用AC ID引用、BR行AC列引用AC ID、补充AC-NFR-008（AC总数 15→16）、仪表盘更新 | ZoneCNH |

## Acceptance Criteria Linkage

| Acceptance Criterion | Requirement | Test Case | Current Evidence |
| -------------------- | ----------- | --------- | ---------------- |
| AC-001 | FR-001 | TC-001 | Covered by TC-001 test evidence |
| AC-002 | FR-002 | TC-001 | Covered by TC-001 test evidence |
| AC-003 | FR-003 | TC-005 | Covered by TC-005 test evidence |
| AC-004 | FR-004 | TC-004 | Covered by TC-004 test evidence |
| AC-005 | FR-005 | TC-005 | Covered by TC-005 test evidence |
| AC-006 | FR-006 | TC-003 | Covered by TC-003 test evidence |
| AC-007 | FR-007 | TC-008 | Covered by TC-008 test evidence |
| AC-008 | FR-003 | TC-005 | Covered by TC-005 test evidence |
