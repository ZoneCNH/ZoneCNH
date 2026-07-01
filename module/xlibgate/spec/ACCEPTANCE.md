# xlibgate 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-30
- Module-Version: v1.0.1
- Module-State: 本地发布门禁通过（远端发布待授权）
- Layer: L1 门禁
- Runtime-Repo: /home/workspace/xlibgate
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 xlibgate 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/workspace/ZoneCNH && test -f module/xlibgate/FEATURES.md && test -f module/xlibgate/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/workspace/ZoneCNH && git diff --check -- module/xlibgate | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/workspace/xlibgate && GOWORK=off go test ./... | 所有包测试通过 |
| 目标覆盖率证据 | cd /home/workspace/xlibgate && GOWORK=off go test ./... -covermode=atomic -coverprofile=/tmp/xlibgate_all_continue4.out | 全仓 statement coverage >= 80% |
| 依赖边界 | cd /home/workspace/xlibgate && GOWORK=off make boundary | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |
| 文档一致性 | cd /home/workspace/xlibgate && GOWORK=off make docs-check | 发布文档、CI 片段与命令口径一致 |
| 集成验证 | cd /home/workspace/xlibgate && GOWORK=off make integration | kernel/configx/redisx 集成验证通过 |
| 本地发布门禁 | cd /home/workspace/xlibgate && XLIB_CONTEXT=release_verify GOWORK=off make release-check | 发布检查通过并生成 release evidence |
| 最终本地门禁 | cd /home/workspace/xlibgate && XLIB_CONTEXT=release_verify GOWORK=off make release-final-check | 本地最终发布门禁通过 |

## 1.1 v1.0.1 验收证据（2026-06-21）

| 项目 | 证据 |
| --- | --- |
| 运行时代码提交 | `/home/workspace/xlibgate` 分支 `ci/sre-cicd-pools-20260618`，提交 `e76725b` |
| 全仓测试 | `GOWORK=off go test ./... -covermode=atomic -coverprofile=/tmp/xlibgate_all_continue4.out` 通过 |
| 覆盖率 | 全仓 statement coverage `86.1%`；其中 `cmd/goalcli` package coverage `85.2%`，满足当前 `>= 80%` 本地门槛但未达到 `100%` |
| 边界检查 | `GOWORK=off make boundary` 通过 |
| 文档检查 | `GOWORK=off make docs-check` 通过 |
| 集成检查 | `GOWORK=off make integration` 通过 |
| 发布检查 | `XLIB_CONTEXT=release_verify GOWORK=off make release-check` 通过，release evidence hash `e61617b0c44dd836b0c3a80e166fdadd471dd4824f2d1f4e3b9af054c3add870` |
| 最终本地发布检查 | `XLIB_CONTEXT=release_verify GOWORK=off make release-final-check` 通过，release evidence hash `451a937f91125127d79cf9333ab4dfe0b7610834c96405751365d74efa2e7ef8`；score `10/10`，debt score `10/10` |
| 依赖治理提示 | `release-final-check` 中 dependency governance 命令通过，但输出 `standard_contract_generator_review_required=true`，需在人工发布审查中保留该提示 |
| CI/CD 准备 | `.github/workflows/ci.yml` 固定 release-check 为 `GOWORK=off XLIB_CONTEXT=ci_pull_request make release-check`，并上传 release evidence artifact |
| 外部发布边界 | `git push`、`v1.0.1` tag、GitHub Release 与远端 CI 未执行，等待显式授权 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | 002 / import 违规检测输出文件路径、行号、违规 import 路径，合规时 pass，exit code 0 | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 | 003 / go.mod tidy 无 diff → pass（exit 0），有 diff → 输出 diff 详情（exit 1），无 go.mod → error（exit 2） | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 | 004 / baseline 匹配 → pass（exit 0），不匹配 → 输出模块列表（exit 1），无 expected → error（exit 2） | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | 005 / evidence 完整且通过 → pass（exit 0），缺失 → 输出缺失列表（exit 1），格式无效 → error（exit 2） | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 | 006 / 全部 pass → exit 0，任一 fail 且无 error → exit 1，任一 error → exit 2（error 优先于 fail）；checks[] 含全部 5 个子检查条目（含 pass 项，非仅失败项）；未提供 --evidence 且无配置 → release 标记 error | ✅ | TRACEABILITY.md |
| AC-006 | FR-006 | 006 / 默认 human-readable（含颜色），--output json 输出含 status/checks[]/summary，--artifact 写入文件 | ✅ | TRACEABILITY.md |
| AC-007 | BR-001 | 006 / exit code 映射：所有 pass→0，任一 fail→1（非 error 覆盖），任一 error→2 | ✅ | TRACEABILITY.md |
| AC-008 | BR-009 | 002 / FOUNDATION-DEPS.yaml 解析正确，schema 校验通过，无效 yaml → ErrConfigInvalid | ✅ | TRACEABILITY.md |
| AC-009 | BR-005 | 006 / gitleaks 可用时执行扫描：零命中 → pass，命中 → fail（含文件路径/行号/规则）；gitleaks 不可用 → error | ✅ | TRACEABILITY.md |
| AC-010 | FR-007 | 009 / manifest 有效时输出摘要（repo/layer/release_level/required_capabilities），exit 0；缺失或 YAML 解析失败时输出错误详情，exit 1 | ✅ | TRACEABILITY.md |
| AC-011 | FR-008 | 009 / registry 覆盖所有 required_capabilities 时生成 test-plan.json（含 required_contract_tests 列表），exit 0；缺失 capabilities 时输出缺失列表，exit 1 | ✅ | TRACEABILITY.md |
| AC-012 | FR-009 | 009 / 所有必需契约测试通过时输出 passed/missing/failed 计数，exit 0；存在缺失或失败时输出详情，exit 1 | ✅ | TRACEABILITY.md |
| AC-013 | FR-010 | 009 / 所有必需证据文件存在时输出 present/missing 计数，exit 0；存在缺失时输出缺失列表，exit 1 | ✅ | TRACEABILITY.md |
| AC-014 | FR-011 | 009 / 所有硬性门禁通过且综合评分 ≥ 80 时输出 status=pass/score/hard_failures=0，exit 0；硬失败 >0 时输出 fail 状态和 hard_failures 列表，exit 1 | ✅ | TRACEABILITY.md |
| AC-015 | FR-012 | 011 / 五源身份一致 → exit 0；任一不匹配 → exit 1, reason_code=IDENTITY_MISMATCH；.repo-contract.yaml 缺失 → exit 2, CONTRACT_PARSE_ERROR | ✅ | TRACEABILITY.md |
| AC-016 | FR-013, BR-010 | 012 / 下游仓库无禁止短语 → exit 0；含禁止短语 → exit 1, reason_code=TEMPLATE_RESIDUE；xlib_standard 自身 → exit 0, TEMPLATE_RESIDUE_SELF_SKIP | ✅ | TRACEABILITY.md |
| AC-017 | FR-014 | 013 / 七源版本一致 → exit 0；不一致 → exit 1, reason_code=RELEASE_DRIFT；VERSION/CHANGELOG 缺失 → exit 1；--online 查询 GitHub API | ✅（离线源已验，远端发布后补 online） | TRACEABILITY.md |
| AC-018 | FR-015 | 014 / 11 维全 true → exit 0；任一维度 false → exit 1, reason_code=FACTORY_GATE_BLOCKED；单百分比拒绝 → exit 1；maturity 节缺失 → exit 2, CONTRACT_PARSE_ERROR | ✅ | TRACEABILITY.md |
| AC-019 | FR-016 | 015 / import 合规 → exit 0；违反 forbidden edge → exit 1, reason_code=IMPORT_BOUNDARY_VIOLATION；kernel 导入非 stdlib → 标记 kernel_stdlib_violation；FOUNDATION-DEPS.yaml 缺失 → exit 2 | ✅ | TRACEABILITY.md |
| AC-020 | FR-017 | 016 / 生产代码无 testkitx → exit 0；生产代码有 → exit 1, reason_code=TESTKIT_PROD_IMPORT；test 文件豁免；--strict 检查 internal/ | ✅ | TRACEABILITY.md |
| AC-021 | FR-018 | 017 / 文档无泄露 → exit 0；检测到密钥 → exit 1, reason_code=SECRET_LEAK（脱敏输出）；私有端点 → PRIVATE_ENDPOINT_LEAK；开发上下文豁免；release/evidence 缺失 → exit 2 | ✅ | TRACEABILITY.md |
| AC-022 | FR-019 | 018 / 20 模块全成功 → exit 0, 生成 index.json；部分失败 → exit 1, 仍生成 index.json；--summary-only 仅输出摘要 | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, BR-008 | Given 配置禁止业务域 import 基座层，When 扫描到 binance import kernel，Then 输出违规详情（文件路径、行号），exit code 1 | ✅ | TRACEABILITY.md |
| TC-002 | FR-002 | Given 项目 go.mod 已 tidy，When 运行 check gomod，Then 输出 pass，exit code 0 | ✅ | TRACEABILITY.md |
| TC-003 | FR-003 | Given 配置要求 Go 1.23，某模块 go.mod 指定 1.22，When 运行 check baseline --expected 1.23，Then 输出不匹配模块列表，exit code 1 | ✅ | TRACEABILITY.md |
| TC-004 | FR-005, BR-001, BR-006 | Given imports 检查失败，gomod 检查通过，When 运行 check all，Then 输出所有子检查结果，imports 为 fail，gomod 为 pass，exit code 1 | ✅ | TRACEABILITY.md |
| TC-005 | FR-005, BR-001, BR-006 | Given imports 检查正常，baseline 检查因配置缺失报 error，When 运行 check all，Then imports 结果正常输出，baseline 标记为 error，继续执行其余检查，exit code 2 | ✅ | TRACEABILITY.md |
| TC-006 | FR-004 | Given release evidence 文件存在且 schema 合法，When 运行 check release，Then 输出 pass，exit code 0 | ✅ | TRACEABILITY.md |
| TC-007 | FR-006, BR-007 | Given 检查结果包含 pass、fail 和 error，When 使用 JSON 输出，Then 输出包含 status、checks[]、summary 字段 | ✅ | TRACEABILITY.md |
| TC-008 | FR-005, BR-005 | Given 项目源码包含硬编码密钥（如 AWS_SECRET_ACCESS_KEY=...），When 配置 secret_scan.enabled=true 且运行 check all，Then gitleaks 检测到泄露，输出文件路径、行号和匹配规则，exit code 1 | ✅ | TRACEABILITY.md |
| TC-009 | FR-007 | Given .agent/l2-capabilities.yaml 格式正确且必填字段完整，When 运行 l2 validate-manifest，Then 输出 repo/layer/release_level/required_capabilities 摘要，exit code 0 | ✅ | TRACEABILITY.md |
| TC-010 | FR-008 | Given registry 覆盖所有 required_capabilities，When 运行 l2 plan，Then 生成 test-plan.json 含 required_contract_tests 列表，exit code 0 | ✅ | TRACEABILITY.md |
| TC-011 | FR-009 | Given 测试计划含 3 项必需契约测试且 contract-test.json 全部通过，When 运行 l2 check-contracts，Then 输出 passed=3/missing=0/failed=0，exit code 0 | ✅ | TRACEABILITY.md |
| TC-012 | FR-010 | Given .agent/evidence/ 下所有必需证据文件存在，When 运行 l2 check-evidence，Then 输出 present 计数、missing=0，exit code 0 | ✅ | TRACEABILITY.md |
| TC-013 | FR-011 | Given 所有硬性门禁通过且综合评分 ≥ 80，When 运行 l2 release-check，Then 输出 status=pass、hard_failures=0，exit code 0 | ✅ | TRACEABILITY.md |
| TC-014 | FR-012 | Given README H1/go.mod/contract 五源一致，When 运行 trust identity，Then status=pass, reason_code="", exit 0 | ✅ | TRACEABILITY.md |
| TC-015 | FR-012 | Given README H1 不匹配 repo name，When 运行 trust identity，Then findings 含不匹配详情, reason_code=IDENTITY_MISMATCH, exit 1 | ✅ | TRACEABILITY.md |
| TC-016 | FR-013, BR-010 | Given 下游仓库无 BR-010 禁止短语，When 运行 trust template-residue，Then status=pass, exit 0 | ✅ | TRACEABILITY.md |
| TC-017 | FR-013, BR-010 | Given 下游仓库含 "承担五类职责：Standard Source..."，When 运行 trust template-residue，Then findings 含文件路径/行号/短语, reason_code=TEMPLATE_RESIDUE, exit 1 | ✅ | TRACEABILITY.md |
| TC-018 | FR-014 | Given 七源版本一致，When 运行 trust release-consistency --offline，Then status=pass, exit 0 | ✅ | TRACEABILITY.md |
| TC-019 | FR-014 | Given VERSION vs CHANGELOG 不一致，When 运行 trust release-consistency --offline，Then findings 含不一致值, reason_code=RELEASE_DRIFT, exit 1 | ✅ | TRACEABILITY.md |
| TC-020 | FR-015 | Given 11 维工厂级判定全 true，When 运行 trust maturity --factory，Then overall=pass, exit 0 | ✅ | TRACEABILITY.md |
| TC-021 | FR-015 | Given unit_tests_complete=false, live_integration_complete=false，When 运行 trust maturity --factory，Then findings 含未满足维度, reason_code=FACTORY_GATE_BLOCKED, exit 1 | ✅ | TRACEABILITY.md |
| TC-022 | FR-016 | Given import 符合 FOUNDATION-DEPS.yaml，When 运行 trust import-boundary，Then status=pass, exit 0 | ✅ | TRACEABILITY.md |
| TC-023 | FR-016 | Given binance import kernel 违反 forbidden_foundation_edges，When 运行 trust import-boundary，Then findings 含文件路径/行号, reason_code=IMPORT_BOUNDARY_VIOLATION, exit 1 | ✅ | TRACEABILITY.md |
| TC-024 | FR-017 | Given 生产代码无 testkitx 但 test 文件有，When 运行 trust testkit-prod-import，Then test 文件不触发违规, exit 0 | ✅ | TRACEABILITY.md |
| TC-025 | FR-017 | Given pkg/ 中 import testkitx，When 运行 trust testkit-prod-import，Then findings 含文件路径/行号, reason_code=TESTKIT_PROD_IMPORT, exit 1 | ✅ | TRACEABILITY.md |
| TC-026 | FR-018 | Given release/evidence 无泄露，When 运行 trust secret-redaction，Then status=pass, exit 0 | ✅ | TRACEABILITY.md |
| TC-027 | FR-018 | Given deploy-log.md 含 AWS_SECRET_ACCESS_KEY，When 运行 trust secret-redaction，Then findings 含文件路径/匹配类型（脱敏）, reason_code=SECRET_LEAK, exit 1 | ✅ | TRACEABILITY.md |
| TC-028 | FR-019 | Given 20 模块全成功，When 运行 trust fleet-status，Then 生成 index.json 含各模块状态, exit 0 | ✅ | TRACEABILITY.md |
| TC-029 | FR-019 | Given 2 模块缺少 .repo-contract.yaml，When 运行 trust fleet-status，Then 生成 index.json（含 2 error 模块）, exit 1 | ✅ | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
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

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/workspace/xlibgate 通过全仓测试、覆盖率、release-check 与 release-final-check 本地门槛；全仓 statement coverage 为 86.1%，不是 100%。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、CHANGELOG、release note 与本目录本地状态一致；远端 tag、GitHub Release 与远端 CI 待显式授权后闭合。

## 6. 当前缺口登记

- 当前文档已记录 `/home/workspace/xlibgate` v1.0.1 本地发布证据，但不替代远端 CI、远端 tag 或 GitHub Release 结果。
- 当前覆盖率证据为全仓 statement coverage `86.1%`，满足现行 `>= 80%` 门槛但未满足用户期望的 `100%`。
- `git push`、`v1.0.1` tag、GitHub Release 与远端 CI 尚未执行，等待显式授权。
- `release-preflight VERSION=v1.0.1` 尚未执行；该脚本要求位于 `main`、工作区干净且 `HEAD == origin/main`，需在授权合并/推送路径中闭合。
- NFR-001 至 NFR-006、NFR-009、NFR-011 至 NFR-018 仍登记为 ⚠️；需要独立 benchmark、memprofile 或错误输出审计证据后才能升级为 ✅。
