# contracts 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-21
- Module-Version: v1.2.0
- Module-State: 已发布
- Layer: L2.5 共享契约
- Runtime-Repo: /home/contracts
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 contracts 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/contracts/FEATURES.md && test -f module/contracts/ACCEPTANCE.md && test -f module/contracts/README.md && test -f module/contracts/CHANGELOG.md | FEATURES.md、ACCEPTANCE.md、README.md 与 CHANGELOG.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/contracts | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/contracts && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/contracts && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/contracts && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/contracts && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/contracts && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | TC-001 / Covered by TC-001 test evidence | - | TRACEABILITY.md |
| AC-002 | FR-002 | TC-001 / Covered by TC-001 test evidence | - | TRACEABILITY.md |
| AC-003 | FR-003 | TC-005 / Covered by TC-005 test evidence | - | TRACEABILITY.md |
| AC-004 | FR-004 | TC-004 / Covered by TC-004 test evidence | - | TRACEABILITY.md |
| AC-005 | FR-005 | TC-005 / Covered by TC-005 test evidence | - | TRACEABILITY.md |
| AC-006 | FR-006 | TC-003 / Covered by TC-003 test evidence | - | TRACEABILITY.md |
| AC-007 | FR-007 | TC-008 / Covered by TC-008 test evidence | - | TRACEABILITY.md |
| AC-008 | FR-008 | TC-009 / Covered by TC-009 test evidence | - | TRACEABILITY.md |
| AC-BR-002 | BR-002 | CI Gate (PR 审查: 消费方/生产方/稳定期说明) | Pending | TRACEABILITY.md |
| AC-BR-004 | BR-004 | TC-006 (端口方法数 3-5) | Pending | TRACEABILITY.md |
| AC-BR-008 | BR-008 | CI Gate (go mod tidy + 依赖检查) | Pending | TRACEABILITY.md |
| AC-FR-001 | FR-001, FR-002, BR-007 | TC-001 (编译期检查) | Pending | TRACEABILITY.md |
| AC-FR-002 | FR-003 | TC-005 (Event 接口完整性) | Pending | TRACEABILITY.md |
| AC-FR-003 | FR-004, BR-006 | TC-004 (Topic 唯一性) | Pending | TRACEABILITY.md |
| AC-FR-004 | FR-005, BR-001, BR-005, BR-009 | TC-002 + TC-007 (JSON round-trip + 不可变性) | Pending | TRACEABILITY.md |
| AC-FR-005 | FR-006, BR-003, BR-010 | TC-003 (Breaking change 检测) | Pending | TRACEABILITY.md |
| AC-FR-006 | FR-008 | TC-009 (Binance C/S ingestion contract) | Pending | TRACEABILITY.md |
| AC-NFR-001 | NFR-001 | CI Gate (覆盖率 ≥ 80%) | Pending | TRACEABILITY.md |
| AC-NFR-002 | NFR-002 | CI Gate (go test -race) | Pending | TRACEABILITY.md |
| AC-NFR-003 | NFR-003 | CI Gate (vet + lint) | Pending | TRACEABILITY.md |
| AC-NFR-004 | NFR-004 | CI Gate (gitleaks) | Pending | TRACEABILITY.md |
| AC-NFR-005 | NFR-005 | CI Gate (breaking change 检查) | Pending | TRACEABILITY.md |
| AC-NFR-006 | NFR-006 | CI Gate (benchmark 对比) | Pending | TRACEABILITY.md |
| AC-NFR-007 | NFR-007 | Documentation evidence | Pending | TRACEABILITY.md |
| AC-NFR-008 | NFR-008 | TC-002 + CI Gate (错误格式检查: "contracts: ") | Pending | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-002, BR-007 | 编译期检查 / 端口接口编译期检查 (var _ Interface = (*impl)(nil)) | - | TRACEABILITY.md |
| TC-002 | FR-005, BR-001, BR-009, NFR-008 | 单元测试 / DTO JSON round-trip 序列化/反序列化 | - | TRACEABILITY.md |
| TC-003 | FR-006, BR-003, BR-010 | 单元测试 / Breaking change 检测（接口方法增删、DTO 字段变更） | - | TRACEABILITY.md |
| TC-004 | FR-004, BR-006 | 单元测试 / Topic 常量唯一性检查 | - | TRACEABILITY.md |
| TC-005 | FR-003 | 单元测试 / Event 接口完整性（所有 Event 实现满足接口） | - | TRACEABILITY.md |
| TC-006 | BR-004 | 单元测试 / 端口接口方法数检查（3-5 方法） | - | TRACEABILITY.md |
| TC-007 | FR-005, BR-005 | 单元测试 / DTO 不可变性检查 | - | TRACEABILITY.md |
| TC-008 | FR-007 | 单元测试 / Module Identity（README H1 与 go.mod module 声明） | - | TRACEABILITY.md |
| TC-009 | FR-008 | 单元测试 / Binance C/S ingestion contract（DTO serialization/deserialization + RejectCode coverage） | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | MarketDataProvider — Subscribe/GetSnapshot/GetHistory 端口 | AC-FR-001: 编译期检查通过，接口方法完整 / TC-001 / TASK-CONTRACTS-001 | Pending | TRACEABILITY.md |
| FR-002 | MacroDataProvider — GetLatest/GetHistory/Subscribe 端口 | AC-FR-001: 编译期检查通过，接口方法完整 / TC-001 / TASK-CONTRACTS-001 | Pending | TRACEABILITY.md |
| FR-003 | Event 接口 — EventID/EventType/Timestamp/Source 四方法 | AC-FR-002: Event 接口完整性 / TC-005 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| FR-004 | Topic 常量 — 全局唯一、点分命名 | AC-FR-003: Topic 无重复，命名合规 / TC-004 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| FR-005 | DTO 契约 — JSON tag snake_case、不可变、版本演进 | AC-FR-004: JSON round-trip + 不可变性 / TC-002, TC-007 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| FR-006 | Breaking Change 检测 — 接口/DTO 变更感知与版本升级 | AC-FR-005: breaking change 检测通过 / TC-003 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| FR-007 | Module Identity — README H1 与 go.mod module path 必须为 contracts | AC-007: Module Identity / TC-008 / TASK-CONTRACTS-005 | Pending | TRACEABILITY.md |
| FR-008 | Binance C/S ingestion contract — MarketDataService + IngestRequest + IngestAck + IngestReject + RejectCode DTOs | AC-008: Binance C/S ingestion contract / TC-009 / TASK-CONTRACTS-006 | Pending | TRACEABILITY.md |
| BR-001 | 所有跨域 DTO 必须在 contracts 中定义 | AC-FR-004: DTO集中定义 / TC-002 (JSON round-trip) / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| BR-002 | 新增契约必须说明消费方、生产方和稳定期 | AC-BR-002: 契约三方说明 / CI Gate: PR 审查 (新增契约审查) / TASK-CONTRACTS-004 | Pending | TRACEABILITY.md |
| BR-003 | 契约变更是 breaking change → 需要版本升级 | AC-FR-005: BC触发版本检查 / TC-003 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| BR-004 | 端口接口保持窄（3-5 个方法） | AC-BR-004: 方法数3-5 / TC-006 / TASK-CONTRACTS-001 | Pending | TRACEABILITY.md |
| BR-005 | 事件 DTO 不可变（只读字段） | AC-FR-004: DTO不可变 / TC-007 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| BR-006 | Topic 常量全局唯一，使用点分命名 | AC-FR-003: Topic 值无重复，命名符合 domain.action / TC-004 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| BR-007 | 接口实现方必须有编译期检查 (var _ Interface = (*Impl)(nil)) | AC-FR-001: 编译期检查 / TC-001 / TASK-CONTRACTS-001 | Pending | TRACEABILITY.md |
| BR-008 | contracts 只依赖 L2.5 领域共享层和 stdlib | AC-BR-008: 依赖纯洁 / CI Gate: go mod tidy + 依赖检查 / TASK-CONTRACTS-000 | Pending | TRACEABILITY.md |
| BR-009 | DTO 的 JSON tag 必须使用 snake_case | AC-FR-004: JSON tag snake_case / TC-002 (JSON round-trip) / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| BR-010 | 契约版本遵循 semver（breaking change → major） | AC-FR-005: semver版本策略 / TC-003 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| NFR-001 | 单元测试覆盖率 ≥ 80% | go test -cover 总覆盖率 ≥ 80% / CI Gate: 覆盖率检查 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| NFR-002 | -race 测试通过 | 无 data race / CI Gate: go test -race / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| NFR-003 | go vet / golangci-lint 无错误 | vet 和 lint 零告警 / CI Gate: vet + lint / TASK-CONTRACTS-000, TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| NFR-004 | Secret 扫描通过 | 无泄露 secret / CI Gate: gitleaks detect / TASK-CONTRACTS-004 | Pending | TRACEABILITY.md |
| NFR-005 | 公共 API 无破坏性变更（或已 bump major） | breaking change 检测通过 / CI Gate: breaking change 检查 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| NFR-006 | Benchmark 结果无 > 10% 回退 | benchmark 对比通过 / CI Gate: Benchmark 检查 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| NFR-007 | 文档齐全（README、CHANGELOG、godoc） | 所有公开接口有 godoc，README 完整 / Documentation evidence / TASK-CONTRACTS-004 | Pending | TRACEABILITY.md |
| NFR-008 | 错误格式统一 "contracts: " | 所有错误变量符合格式约定 / TC-002, CI Gate: 错误格式检查 / TASK-CONTRACTS-000 | Pending | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/contracts 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/contracts 实现、contract CI gates、coverage/race/vet/lint、breaking-change 与 benchmark 证据需要归档。
