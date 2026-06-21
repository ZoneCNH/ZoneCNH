# contracts 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-21
- Module-Version: v1.2.0
- Module-State: 已发布
- Layer: L2.5 共享契约
- Runtime-Repo: /home/contracts
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 contracts 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 跨域 DTO、枚举、事件、错误码与兼容性契约 |
| 文档目录 | module/contracts |
| 运行时代码目录 | /home/contracts |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | MarketDataProvider — Subscribe/GetSnapshot/GetHistory 端口 | AC-FR-001: 编译期检查通过，接口方法完整 / TC-001 / TASK-CONTRACTS-001 | Pending | TRACEABILITY.md |
| FR-002 | MacroDataProvider — GetLatest/GetHistory/Subscribe 端口 | AC-FR-001: 编译期检查通过，接口方法完整 / TC-001 / TASK-CONTRACTS-001 | Pending | TRACEABILITY.md |
| FR-003 | Event 接口 — EventID/EventType/Timestamp/Source 四方法 | AC-FR-002: Event 接口完整性 / TC-005 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| FR-004 | Topic 常量 — 全局唯一、点分命名 | AC-FR-003: Topic 无重复，命名合规 / TC-004 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| FR-005 | DTO 契约 — JSON tag snake_case、不可变、版本演进 | AC-FR-004: JSON round-trip + 不可变性 / TC-002, TC-007 / TASK-CONTRACTS-002 | Pending | TRACEABILITY.md |
| FR-006 | Breaking Change 检测 — 接口/DTO 变更感知与版本升级 | AC-FR-005: breaking change 检测通过 / TC-003 / TASK-CONTRACTS-003 | Pending | TRACEABILITY.md |
| FR-007 | Module Identity — README H1 与 go.mod module path 必须为 contracts | AC-007: Module Identity / TC-008 / TASK-CONTRACTS-005 | Pending | TRACEABILITY.md |
| FR-008 | Binance C/S ingestion contract — MarketDataService + IngestRequest + IngestAck + IngestReject + RejectCode DTOs | AC-008: Binance C/S ingestion contract / TC-009 / TASK-CONTRACTS-006 | Pending | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-CONTRACTS-000 | TASK-CONTRACTS-000 | module/contracts/tasks/TASK-CONTRACTS-000.md | - | tasks/TASK-CONTRACTS-000.md |
| TASK-CONTRACTS-001 | TASK-CONTRACTS-001 | module/contracts/tasks/TASK-CONTRACTS-001.md | - | tasks/TASK-CONTRACTS-001.md |
| TASK-CONTRACTS-002 | TASK-CONTRACTS-002 | module/contracts/tasks/TASK-CONTRACTS-002.md | - | tasks/TASK-CONTRACTS-002.md |
| TASK-CONTRACTS-003 | TASK-CONTRACTS-003 | module/contracts/tasks/TASK-CONTRACTS-003.md | - | tasks/TASK-CONTRACTS-003.md |
| TASK-CONTRACTS-004 | TASK-CONTRACTS-004 | module/contracts/tasks/TASK-CONTRACTS-004.md | - | tasks/TASK-CONTRACTS-004.md |
| TASK-CONTRACTS-005 | §8.4 Ingestion Contract (MarketDataService/IngestRequest/IngestResult/RejectCode) | 2h | - | IMPLEMENTATION-PLAN.md |
| TASK-CONTRACTS-005-BINANCE-CS-INGESTION-CONTRACT | TASK-CONTRACTS-005 Binance C/S Ingestion Contract | module/contracts/tasks/TASK-CONTRACTS-005-binance-cs-ingestion-contract.md | - | tasks/TASK-CONTRACTS-005-binance-cs-ingestion-contract.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/contracts/goal.md |
| SPEC.md | 存在 | module/contracts/SPEC.md |
| TRACEABILITY.md | 存在 | module/contracts/TRACEABILITY.md |
| README.md | 存在 | module/contracts/README.md |
| CHANGELOG.md | 存在 | module/contracts/CHANGELOG.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/contracts/IMPLEMENTATION-PLAN.md |
| tasks/ | 6 个 Markdown 文件 | module/contracts/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/contracts 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
