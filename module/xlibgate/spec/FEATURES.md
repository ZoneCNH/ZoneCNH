# xlibgate 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-21
- Module-Version: v1.0.1
- Module-State: 本地发布门禁通过（远端发布待授权）
- Layer: L1 门禁
- Runtime-Repo: /home/xlibgate
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 xlibgate 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | check/l2/trust gate 与规则化评分门禁 |
| 文档目录 | module/xlibgate |
| 运行时代码目录 | /home/xlibgate |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | check imports：扫描 import 语句，检测禁止的依赖方向（业务域反向依赖基座、生产包依赖 testkitx），违规时输出文件路径和行号 | AC-001 / TC-001 / TASK-XLIBGATE-002 | ✅ | TRACEABILITY.md |
| FR-002 | check gomod：执行 go mod tidy 检查 go.mod 整洁度，有 diff 时输出 diff 详情 | AC-002 / TC-002 / TASK-XLIBGATE-003 | ✅ | TRACEABILITY.md |
| FR-003 | check baseline：验证所有模块 go.mod 中 go 指令版本与 expected 一致，不匹配时输出模块列表和版本差异 | AC-003 / TC-003 / TASK-XLIBGATE-004 | ✅ | TRACEABILITY.md |
| FR-004 | check release：收集和校验 release evidence，缺失或不通过时输出失败列表 | AC-004 / TC-006 / TASK-XLIBGATE-005 | ✅ | TRACEABILITY.md |
| FR-005 | check all：执行所有子检查（imports/gomod/baseline/release/secret_scan），部分失败继续执行其余检查，汇总所有子检查结果 | AC-005 / TC-004, TC-005, TC-008 / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| FR-006 | 输出格式：支持 JSON（含 status/checks[]/summary）和 human-readable（含文件路径行号、带颜色终端输出） | AC-006 / TC-007 / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| FR-007 | l2 validate-manifest：校验 .agent/l2-capabilities.yaml 能力清单格式和内容完整性 | AC-010 / TC-009 / TASK-XLIBGATE-009（矩阵登记待落任务文档） | ✅ | TRACEABILITY.md |
| FR-008 | l2 plan：从能力清单和 registry 解析 L2 契约测试，生成 test-plan.json artifact | AC-011 / TC-010 / TASK-XLIBGATE-009（矩阵登记待落任务文档） | ✅ | TRACEABILITY.md |
| FR-009 | l2 check-contracts：验证契约测试证据是否覆盖所有必需契约测试 | AC-012 / TC-011 / TASK-XLIBGATE-009（矩阵登记待落任务文档） | ✅ | TRACEABILITY.md |
| FR-010 | l2 check-evidence：验证 L2 evidence 目录下必需证据文件是否存在 | AC-013 / TC-012 / TASK-XLIBGATE-009（矩阵登记待落任务文档） | ✅ | TRACEABILITY.md |
| FR-011 | l2 release-check：完整 L2 发布就绪判定 | AC-014 / TC-013 / TASK-XLIBGATE-009（矩阵登记待落任务文档） | ✅ | TRACEABILITY.md |
| FR-012 | trust identity：五源身份比对（README H1 / go.mod / .repo-contract.yaml / public_package / 身份声明），不匹配时输出 IDENTITY_MISMATCH | AC-015 / TC-014, TC-015 / TASK-XLIBGATE-011 | ✅ | TRACEABILITY.md |
| FR-013 | trust template-residue：扫描下游仓库中的 BR-010 禁止模板身份短语 | AC-016 / TC-016, TC-017 / TASK-XLIBGATE-012 | ✅ | TRACEABILITY.md |
| FR-014 | trust release-consistency：七源版本一致性校验（.repo-contract.yaml / go.mod / VERSION / CHANGELOG / git tag / release manifest / GitHub release），默认离线模式；远端 tag/GitHub release 校验待发布授权后补跑 | AC-017 / TC-018, TC-019 / TASK-XLIBGATE-013 | ✅ | TRACEABILITY.md |
| FR-015 | trust maturity --factory：11 维工厂级成熟度判定，拒绝单个百分比替代 | AC-018 / TC-020, TC-021 / TASK-XLIBGATE-014 | ✅ | TRACEABILITY.md |
| FR-016 | trust import-boundary：消费 FOUNDATION-DEPS.yaml 的 allowed_deps 和 forbidden_foundation_edges | AC-019 / TC-022, TC-023 / TASK-XLIBGATE-015 | ✅ | TRACEABILITY.md |
| FR-017 | trust testkit-prod-import：检测生产代码中的 testkitx import，区分生产/测试路径 | AC-020 / TC-024, TC-025 / TASK-XLIBGATE-016 | ✅ | TRACEABILITY.md |
| FR-018 | trust secret-redaction：扫描 release/evidence 文档中的密钥和私有端点 | AC-021 / TC-026, TC-027 / TASK-XLIBGATE-017 | ✅ | TRACEABILITY.md |
| FR-019 | trust fleet-status：20 模块舰队状态聚合 → .foundationx/status/index.json | AC-022 / TC-028, TC-029 / TASK-XLIBGATE-018 | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | 标准化 exit code：0=pass, 1=fail, 2=error | CI 无法正确判断门禁结果 / TC-004, TC-005 / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| BR-002 | import 规则从 deps.yaml 读取，不硬编码 | 规则变更需改代码重新编译 / FR-001 WHEN/THEN --config 参数覆盖 / TASK-XLIBGATE-002 | ✅ | TRACEABILITY.md |
| BR-003 | baseline 从配置或 --expected 参数获取，不硬编码 | 版本升级需改代码 / FR-003 WHEN/THEN 参数和配置 fallback / TASK-XLIBGATE-004 | ✅ | TRACEABILITY.md |
| BR-004 | evidence schema 与 xlib_standard 定义的 Evidence 标准一致 | 跨工具 evidence 不可互操作 / FR-004 schema 验证（JSON 格式 + 必需字段） / TASK-XLIBGATE-005 | ✅ | TRACEABILITY.md |
| BR-005 | secret 扫描使用 gitleaks 作为底层工具 | 自研扫描器漏报 / TC-008, check all 中 gitleaks 集成调用 / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| BR-006 | check all 必须执行所有子检查，即使前面检查已失败 | 部分检查被跳过，门禁不完整 / TC-004, TC-005 / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| BR-007 | JSON 输出必须包含 machine-readable 的 status 字段 | CI 解析失败 / TC-007 / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| BR-008 | human-readable 输出必须包含文件路径和行号 | 开发者无法定位违规位置 / TC-001, TC-002, TC-008 / TASK-XLIBGATE-002 | ✅ | TRACEABILITY.md |
| BR-009 | 依赖矩阵文件 FOUNDATION-DEPS.yaml schema 与 xlib_standard 定义一致 | deps.yaml 解析失败 / FR-001 config 加载（YAML 解析 + schema 校验）+ Config.Validate() / TASK-XLIBGATE-002 | ✅ | TRACEABILITY.md |
| BR-010 | 禁止模板身份短语：仅 xlib_standard 可含 5 条模板身份短语 | 模块身份定义冲突 / TC-016, TC-017 + template-residue 精确字符串匹配 / TASK-XLIBGATE-012 | ✅ | TRACEABILITY.md |
| NFR-001 | 全量门禁性能（50 模块） | < 30s / Benchmark BenchmarkCheckAll / TASK-XLIBGATE-006 | ⚠️ | TRACEABILITY.md |
| NFR-002 | import 扫描性能（50 模块） | < 10s / Benchmark BenchmarkCheckImports / TASK-XLIBGATE-002 | ⚠️ | TRACEABILITY.md |
| NFR-003 | go.mod 检查性能（50 模块） | < 5s / Benchmark BenchmarkCheckGomod / TASK-XLIBGATE-003 | ⚠️ | TRACEABILITY.md |
| NFR-004 | baseline 检查性能（50 模块） | < 5s / Benchmark BenchmarkCheckBaseline / TASK-XLIBGATE-004 | ⚠️ | TRACEABILITY.md |
| NFR-005 | JSON 报告生成性能 | < 100ms / Benchmark BenchmarkReportJSON / TASK-XLIBGATE-006 | ⚠️ | TRACEABILITY.md |
| NFR-006 | 内存占用 | < 100MB / Profiling go test -memprofile / TASK-XLIBGATE-006 | ⚠️ | TRACEABILITY.md |
| NFR-007 | 测试覆盖率 | >= 80% / go tool cover -func / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| NFR-008 | 无硬编码密钥 | 全仓扫描零命中 / gitleaks detect --no-git / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| NFR-009 | secret 扫描不泄露敏感数据 | 错误消息只含文件路径和行号 / review 错误输出格式 / TASK-XLIBGATE-006 | ⚠️ | TRACEABILITY.md |
| NFR-010 | 无 Foundation 运行时依赖 | go list -deps 零命中 ZoneCNH 模块 / CI gate go list -deps ./... / TASK-XLIBGATE-006 | ✅ | TRACEABILITY.md |
| NFR-011 | trust identity 检查性能 | < 2s / Benchmark BenchmarkTrustIdentity / TASK-XLIBGATE-011 | ⚠️ | TRACEABILITY.md |
| NFR-012 | trust template-residue 扫描 | < 15s（50 模块） / Benchmark BenchmarkTrustTemplate / TASK-XLIBGATE-012 | ⚠️ | TRACEABILITY.md |
| NFR-013 | trust release-consistency | < 3s / Benchmark BenchmarkTrustRelease / TASK-XLIBGATE-013 | ⚠️ | TRACEABILITY.md |
| NFR-014 | trust maturity 检查 | < 1s / Benchmark BenchmarkTrustMaturity / TASK-XLIBGATE-014 | ⚠️ | TRACEABILITY.md |
| NFR-015 | trust import-boundary 检查 | < 10s / Benchmark BenchmarkTrustBoundary / TASK-XLIBGATE-015 | ⚠️ | TRACEABILITY.md |
| NFR-016 | trust testkit-prod-import | < 5s / Benchmark BenchmarkTrustTestkit / TASK-XLIBGATE-016 | ⚠️ | TRACEABILITY.md |
| NFR-017 | trust secret-redaction 扫描 | < 10s / Benchmark BenchmarkTrustSecret / TASK-XLIBGATE-017 | ⚠️ | TRACEABILITY.md |
| NFR-018 | trust fleet-status 聚合 | < 60s（20 模块） / Benchmark BenchmarkTrustFleet / TASK-XLIBGATE-018 | ⚠️ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-XLIBGATE-000 | TASK-XLIBGATE-000 | module/xlibgate/tasks/TASK-XLIBGATE-000.md | - | tasks/TASK-XLIBGATE-000.md |
| TASK-XLIBGATE-001 | TASK-XLIBGATE-001 | module/xlibgate/tasks/TASK-XLIBGATE-001.md | - | tasks/TASK-XLIBGATE-001.md |
| TASK-XLIBGATE-002 | TASK-XLIBGATE-002 | module/xlibgate/tasks/TASK-XLIBGATE-002.md | - | tasks/TASK-XLIBGATE-002.md |
| TASK-XLIBGATE-003 | TASK-XLIBGATE-003 | module/xlibgate/tasks/TASK-XLIBGATE-003.md | - | tasks/TASK-XLIBGATE-003.md |
| TASK-XLIBGATE-004 | TASK-XLIBGATE-004 | module/xlibgate/tasks/TASK-XLIBGATE-004.md | - | tasks/TASK-XLIBGATE-004.md |
| TASK-XLIBGATE-005 | TASK-XLIBGATE-005 | module/xlibgate/tasks/TASK-XLIBGATE-005.md | - | tasks/TASK-XLIBGATE-005.md |
| TASK-XLIBGATE-006 | TASK-XLIBGATE-006 | module/xlibgate/tasks/TASK-XLIBGATE-006.md | - | tasks/TASK-XLIBGATE-006.md |
| TASK-XLIBGATE-007 | TASK-XLIBGATE-007 | module/xlibgate/tasks/TASK-XLIBGATE-007.md | - | tasks/TASK-XLIBGATE-007.md |
| TASK-XLIBGATE-008 | TASK-XLIBGATE-008 | module/xlibgate/tasks/TASK-XLIBGATE-008.md | - | tasks/TASK-XLIBGATE-008.md |
| TASK-XLIBGATE-009 | TASK-XLIBGATE-009 | module/xlibgate/tasks/TASK-XLIBGATE-009.md | - | tasks/TASK-XLIBGATE-009.md |
| TASK-XLIBGATE-010 | TASK-XLIBGATE-010 | module/xlibgate/tasks/TASK-XLIBGATE-010.md | - | tasks/TASK-XLIBGATE-010.md |
| TASK-XLIBGATE-011 | TASK-XLIBGATE-011 | module/xlibgate/tasks/TASK-XLIBGATE-011.md | - | tasks/TASK-XLIBGATE-011.md |
| TASK-XLIBGATE-012 | TASK-XLIBGATE-012 | module/xlibgate/tasks/TASK-XLIBGATE-012.md | - | tasks/TASK-XLIBGATE-012.md |
| TASK-XLIBGATE-013 | TASK-XLIBGATE-013 | module/xlibgate/tasks/TASK-XLIBGATE-013.md | - | tasks/TASK-XLIBGATE-013.md |
| TASK-XLIBGATE-014 | TASK-XLIBGATE-014 | module/xlibgate/tasks/TASK-XLIBGATE-014.md | - | tasks/TASK-XLIBGATE-014.md |
| TASK-XLIBGATE-015 | TASK-XLIBGATE-015 | module/xlibgate/tasks/TASK-XLIBGATE-015.md | - | tasks/TASK-XLIBGATE-015.md |
| TASK-XLIBGATE-016 | TASK-XLIBGATE-016 | module/xlibgate/tasks/TASK-XLIBGATE-016.md | - | tasks/TASK-XLIBGATE-016.md |
| TASK-XLIBGATE-017 | TASK-XLIBGATE-017 | module/xlibgate/tasks/TASK-XLIBGATE-017.md | - | tasks/TASK-XLIBGATE-017.md |
| TASK-XLIBGATE-018 | TASK-XLIBGATE-018 | module/xlibgate/tasks/TASK-XLIBGATE-018.md | - | tasks/TASK-XLIBGATE-018.md |
| TASK-XLIBGATE-019 | TASK-XLIBGATE-019 | module/xlibgate/tasks/TASK-XLIBGATE-019.md | - | tasks/TASK-XLIBGATE-019.md |
| TASK-XLIBGATE-TRUST-PROMPT | Context Packet — Trust Alignment 子命令组 | module/xlibgate/tasks/TASK-XLIBGATE-TRUST-PROMPT.md | - | tasks/TASK-XLIBGATE-TRUST-PROMPT.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/xlibgate/goal.md |
| SPEC.md | 存在 | module/xlibgate/SPEC.md |
| DESIGN.md | 存在 | module/xlibgate/DESIGN.md |
| TRACEABILITY.md | 存在 | module/xlibgate/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/xlibgate/IMPLEMENTATION-PLAN.md |
| tasks/ | 21 个 Markdown 文件 | module/xlibgate/tasks |

## 6. v1.0.1 本地发布证据（2026-06-21）

| 项目 | 证据 |
| --- | --- |
| 运行时代码提交 | `/home/xlibgate` 分支 `ci/sre-cicd-pools-20260618`，提交 `e76725b` |
| 版本同步 | `AGENTS.md`、`README.md`、`docs/release.md`、`docs/standard/release-standard.md`、`CHANGELOG.md`、`.agent/harness/harness.yaml`、`release/manifest/template.json`、`cmd/goalcli/governance.go`、`pkg/templatex/version.go` 均同步到 `v1.0.1` |
| 核心测试 | `GOWORK=off go test ./... -covermode=atomic -coverprofile=/tmp/xlibgate_all_continue4.out` 通过 |
| 覆盖率 | 全仓 statement coverage `86.1%`；其中 `cmd/goalcli` package coverage `85.2%`，满足当前 `>= 80%` 本地门槛但未达到 `100%` |
| 边界与文档 | `GOWORK=off make boundary`、`GOWORK=off make docs-check` 通过 |
| 集成验证 | `GOWORK=off make integration` 通过 |
| 发布门禁 | `XLIB_CONTEXT=release_verify GOWORK=off make release-check` 通过，release evidence hash `e61617b0c44dd836b0c3a80e166fdadd471dd4824f2d1f4e3b9af054c3add870` |
| 最终本地门禁 | `XLIB_CONTEXT=release_verify GOWORK=off make release-final-check` 通过，release evidence hash `451a937f91125127d79cf9333ab4dfe0b7610834c96405751365d74efa2e7ef8`；score `10/10`，debt score `10/10` |
| 依赖治理提示 | `release-final-check` 中 dependency governance 命令通过，但输出 `standard_contract_generator_review_required=true`，需在人工发布审查中保留该提示 |
| 远端发布边界 | `git push`、`v1.0.1` tag、GitHub Release 与远端 CI 未执行，等待显式授权 |

## 7. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [x] 所有 BR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [x] 运行时代码仓库 /home/xlibgate 的 test、boundary、docs-check、integration、release-check、release-final-check 与覆盖率验证证据已归档；全仓 statement coverage 为 86.1%，不是 100%。
- [ ] 发布说明、本地版本与本目录登记状态一致；远端 `v1.0.1` tag、GitHub Release 与远端 CI 待显式授权后执行。
