# xlibgate 需求追溯矩阵

> 更新：2026-06-14（Matrix v1.5 — Trust Alignment 追溯：FR-012~FR-019、BR-010、TC-014~TC-029、AC-015~AC-022、NFR-011~NFR-018 注册，仪表盘同步更新）
> 来源：module/xlibgate/SPEC.md v1.1.1
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | check imports：扫描 import 语句，检测禁止的依赖方向（业务域反向依赖基座、生产包依赖 testkitx），违规时输出文件路径和行号 | AC-001 | TC-001 | TASK-XLIBGATE-002 | ✅ |
| FR-002 | check gomod：执行 `go mod tidy` 检查 go.mod 整洁度，有 diff 时输出 diff 详情 | AC-002 | TC-002 | TASK-XLIBGATE-003 | ✅ |
| FR-003 | check baseline：验证所有模块 go.mod 中 `go` 指令版本与 expected 一致，不匹配时输出模块列表和版本差异 | AC-003 | TC-003 | TASK-XLIBGATE-004 | ✅ |
| FR-004 | check release：收集和校验 release evidence，缺失或不通过时输出失败列表 | AC-004 | TC-006 | TASK-XLIBGATE-005 | ✅ |
| FR-005 | check all：执行所有子检查（imports/gomod/baseline/release/secret_scan），部分失败继续执行其余检查，汇总所有子检查结果 | AC-005 | TC-004, TC-005, TC-008 | TASK-XLIBGATE-006 | ✅ |
| FR-006 | 输出格式：支持 JSON（含 status/checks[]/summary）和 human-readable（含文件路径行号、带颜色终端输出） | AC-006 | TC-007 | TASK-XLIBGATE-006 | ✅ |
| FR-007 | l2 validate-manifest：校验 .agent/l2-capabilities.yaml 能力清单格式和内容完整性 | AC-010 | TC-009 | TASK-XLIBGATE-009 (TBD) | ✅ |
| FR-008 | l2 plan：从能力清单和 registry 解析 L2 契约测试，生成 test-plan.json artifact | AC-011 | TC-010 | TASK-XLIBGATE-009 (TBD) | ✅ |
| FR-009 | l2 check-contracts：验证契约测试证据是否覆盖所有必需契约测试 | AC-012 | TC-011 | TASK-XLIBGATE-009 (TBD) | ✅ |
| FR-010 | l2 check-evidence：验证 L2 evidence 目录下必需证据文件是否存在 | AC-013 | TC-012 | TASK-XLIBGATE-009 (TBD) | ✅ |
| FR-011 | l2 release-check：完整 L2 发布就绪判定 | AC-014 | TC-013 | TASK-XLIBGATE-009 (TBD) | ✅ |
| FR-012 | trust identity：五源身份比对（README H1 / go.mod / .repo-contract.yaml / public_package / 身份声明），不匹配时输出 IDENTITY_MISMATCH | AC-015 | TC-014, TC-015 | TASK-XLIBGATE-011 | ❌ |
| FR-013 | trust template-residue：扫描下游仓库中的 BR-010 禁止模板身份短语 | AC-016 | TC-016, TC-017 | TASK-XLIBGATE-012 | ❌ |
| FR-014 | trust release-consistency：七源版本一致性校验（.repo-contract.yaml / go.mod / VERSION / CHANGELOG / git tag / release manifest / GitHub release），默认离线模式 | AC-017 | TC-018, TC-019 | TASK-XLIBGATE-013 | ❌ |
| FR-015 | trust maturity --factory：11 维工厂级成熟度判定，拒绝单个百分比替代 | AC-018 | TC-020, TC-021 | TASK-XLIBGATE-014 | ❌ |
| FR-016 | trust import-boundary：消费 FOUNDATION-DEPS.yaml 的 allowed_deps 和 forbidden_foundation_edges | AC-019 | TC-022, TC-023 | TASK-XLIBGATE-015 | ❌ |
| FR-017 | trust testkit-prod-import：检测生产代码中的 testkitx import，区分生产/测试路径 | AC-020 | TC-024, TC-025 | TASK-XLIBGATE-016 | ❌ |
| FR-018 | trust secret-redaction：扫描 release/evidence 文档中的密钥和私有端点 | AC-021 | TC-026, TC-027 | TASK-XLIBGATE-017 | ❌ |
| FR-019 | trust fleet-status：20 模块舰队状态聚合 → .foundationx/status/index.json | AC-022 | TC-028, TC-029 | TASK-XLIBGATE-018 | ❌ |

> Status 说明：✅=已完成, ⚠️=部分完成/需修复, ❌=未按 SPEC 实现
> FR-001~FR-011：check + l2 子命令组已完成（v1.0.2），AC/TC 追溯链闭合
> FR-012~FR-019：trust 子命令组待实现（v1.1.1），SPEC/PLAN/Tasks 已完成

---


| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 标准化 exit code：0=pass, 1=fail, 2=error | CI 无法正确判断门禁结果 | TC-004, TC-005 | TASK-XLIBGATE-006 | ✅ |
| BR-002 | import 规则从 deps.yaml 读取，不硬编码 | 规则变更需改代码重新编译 | FR-001 WHEN/THEN `--config` 参数覆盖 | TASK-XLIBGATE-002 | ✅ |
| BR-003 | baseline 从配置或 `--expected` 参数获取，不硬编码 | 版本升级需改代码 | FR-003 WHEN/THEN 参数和配置 fallback | TASK-XLIBGATE-004 | ✅ |
| BR-004 | evidence schema 与 xlib-standard 定义的 Evidence 标准一致 | 跨工具 evidence 不可互操作 | FR-004 schema 验证（JSON 格式 + 必需字段） | TASK-XLIBGATE-005 | ✅ |
| BR-005 | secret 扫描使用 gitleaks 作为底层工具 | 自研扫描器漏报 | TC-008, check all 中 gitleaks 集成调用 | TASK-XLIBGATE-006 | ✅ |
| BR-006 | check all 必须执行所有子检查，即使前面检查已失败 | 部分检查被跳过，门禁不完整 | TC-004, TC-005 | TASK-XLIBGATE-006 | ✅ |
| BR-007 | JSON 输出必须包含 machine-readable 的 status 字段 | CI 解析失败 | TC-007 | TASK-XLIBGATE-006 | ✅ |
| BR-008 | human-readable 输出必须包含文件路径和行号 | 开发者无法定位违规位置 | TC-001, TC-002, TC-008 | TASK-XLIBGATE-002 | ✅ |
| BR-009 | 依赖矩阵文件 `FOUNDATION-DEPS.yaml` schema 与 xlib-standard 定义一致 | deps.yaml 解析失败 | FR-001 config 加载（YAML 解析 + schema 校验）+ Config.Validate() | TASK-XLIBGATE-002 | ✅ |
| BR-010 | 禁止模板身份短语：仅 xlib-standard 可含 5 条模板身份短语 | 模块身份定义冲突 | TC-016, TC-017 + template-residue 精确字符串匹配 | TASK-XLIBGATE-012 | ❌ |

> Status 说明：✅=已完成, ⚠️=部分完成/需修复, ❌=未按 SPEC 实现

---

## 3. 非功能需求追溯（NFR）

| NFR     | Description                  | 目标值                              | 验证方式                           | Task              | Status   |
| ------- | ---------------------------- | ----------------------------------- | ---------------------------------- | ----------------- | -------- |
| NFR-001 | 全量门禁性能（50 模块）      | < 30s                               | Benchmark `BenchmarkCheckAll`      | TASK-XLIBGATE-006 | ⚠️       |
| NFR-002 | import 扫描性能（50 模块）   | < 10s                               | Benchmark `BenchmarkCheckImports`  | TASK-XLIBGATE-002 | ⚠️       |
| NFR-003 | go.mod 检查性能（50 模块）   | < 5s                                | Benchmark `BenchmarkCheckGomod`    | TASK-XLIBGATE-003 | ⚠️       |
| NFR-004 | baseline 检查性能（50 模块） | < 5s                                | Benchmark `BenchmarkCheckBaseline` | TASK-XLIBGATE-004 | ⚠️       |
| NFR-005 | JSON 报告生成性能            | < 100ms                             | Benchmark `BenchmarkReportJSON`    | TASK-XLIBGATE-006 | ⚠️       |
| NFR-006 | 内存占用                     | < 100MB                             | Profiling `go test -memprofile`    | TASK-XLIBGATE-006 | ⚠️       |
| NFR-007 | 测试覆盖率                   | >= 80%                              | `go tool cover -func`              | TASK-XLIBGATE-006 | ✅        |
| NFR-008 | 无硬编码密钥                 | 全仓扫描零命中                      | `gitleaks detect --no-git`         | TASK-XLIBGATE-006 | ✅        |
| NFR-009 | secret 扫描不泄露敏感数据    | 错误消息只含文件路径和行号          | review 错误输出格式                | TASK-XLIBGATE-006 | ⚠️       |
| NFR-010 | 无 Foundation 运行时依赖     | `go list -deps` 零命中 ZoneCNH 模块 | CI gate `go list -deps ./...`      | TASK-XLIBGATE-006 | ✅        |
| NFR-011 | trust identity 检查性能      | < 2s                                | Benchmark `BenchmarkTrustIdentity`  | TASK-XLIBGATE-011 | ❌       |
| NFR-012 | trust template-residue 扫描  | < 15s（50 模块）                     | Benchmark `BenchmarkTrustTemplate`  | TASK-XLIBGATE-012 | ❌       |
| NFR-013 | trust release-consistency    | < 3s                                | Benchmark `BenchmarkTrustRelease`   | TASK-XLIBGATE-013 | ❌       |
| NFR-014 | trust maturity 检查          | < 1s                                | Benchmark `BenchmarkTrustMaturity`  | TASK-XLIBGATE-014 | ❌       |
| NFR-015 | trust import-boundary 检查   | < 10s                               | Benchmark `BenchmarkTrustBoundary`  | TASK-XLIBGATE-015 | ❌       |
| NFR-016 | trust testkit-prod-import    | < 5s                                | Benchmark `BenchmarkTrustTestkit`   | TASK-XLIBGATE-016 | ❌       |
| NFR-017 | trust secret-redaction 扫描  | < 10s                               | Benchmark `BenchmarkTrustSecret`    | TASK-XLIBGATE-017 | ❌       |
| NFR-018 | trust fleet-status 聚合      | < 60s（20 模块）                     | Benchmark `BenchmarkTrustFleet`     | TASK-XLIBGATE-018 | ❌       |

> Status 说明：✅=已完成, ⚠️=需验证/待 benchmark, ❌=未实现
> NFR-001~006：核心逻辑已实现但 benchmark 未正式运行，status 标记 ⚠️（待验证）
> NFR-007：internal/check 80.0%，核心包达标
> NFR-008：gitleaks 集成已完成（BR-005）
> NFR-011~018：trust 子命令组待实现，benchmark 目标来自 SPEC §17

---

## 4. TC -> FR 反向追溯

| TC     | FR/BR                  | Given/When/Then 场景                                                                                                                                                                       |
| ------ | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| TC-001 | FR-001, BR-008         | Given 配置禁止业务域 import 基座层，When 扫描到 `binance` import `kernel`，Then 输出违规详情（文件路径、行号），exit code 1                                                                |
| TC-002 | FR-002                 | Given 项目 go.mod 已 tidy，When 运行 `check gomod`，Then 输出 pass，exit code 0                                                                                                            |
| TC-003 | FR-003                 | Given 配置要求 Go 1.23，某模块 go.mod 指定 1.22，When 运行 `check baseline --expected 1.23`，Then 输出不匹配模块列表，exit code 1                                                          |
| TC-004 | FR-005, BR-001, BR-006 | Given imports 检查失败，gomod 检查通过，When 运行 `check all`，Then 输出所有子检查结果，imports 为 fail，gomod 为 pass，exit code 1                                                        |
| TC-005 | FR-005, BR-001, BR-006 | Given imports 检查正常，baseline 检查因配置缺失报 error，When 运行 `check all`，Then imports 结果正常输出，baseline 标记为 error，继续执行其余检查，exit code 2                            |
| TC-006 | FR-004                 | Given release evidence 文件存在且 schema 合法，When 运行 `check release`，Then 输出 pass，exit code 0                                                                                      |
| TC-007 | FR-006, BR-007         | Given 检查结果包含 pass、fail 和 error，When 使用 JSON 输出，Then 输出包含 status、checks[]、summary 字段                                                                                  |
| TC-008 | FR-005, BR-005         | Given 项目源码包含硬编码密钥（如 AWS_SECRET_ACCESS_KEY=...），When 配置 `secret_scan.enabled=true` 且运行 `check all`，Then gitleaks 检测到泄露，输出文件路径、行号和匹配规则，exit code 1 |
| TC-009 | FR-007                 | Given .agent/l2-capabilities.yaml 格式正确且必填字段完整，When 运行 `l2 validate-manifest`，Then 输出 repo/layer/release_level/required_capabilities 摘要，exit code 0                     |
| TC-010 | FR-008                 | Given registry 覆盖所有 required_capabilities，When 运行 `l2 plan`，Then 生成 test-plan.json 含 required_contract_tests 列表，exit code 0                                                  |
| TC-011 | FR-009                 | Given 测试计划含 3 项必需契约测试且 contract-test.json 全部通过，When 运行 `l2 check-contracts`，Then 输出 passed=3/missing=0/failed=0，exit code 0                                        |
| TC-012 | FR-010                 | Given .agent/evidence/ 下所有必需证据文件存在，When 运行 `l2 check-evidence`，Then 输出 present 计数、missing=0，exit code 0                                                               |
| TC-013 | FR-011                 | Given 所有硬性门禁通过且综合评分 ≥ 80，When 运行 `l2 release-check`，Then 输出 status=pass、hard_failures=0，exit code 0                                                                   |
| TC-014 | FR-012                 | Given README H1/go.mod/contract 五源一致，When 运行 `trust identity`，Then status=pass, reason_code="", exit 0                                                                            |
| TC-015 | FR-012                 | Given README H1 不匹配 repo name，When 运行 `trust identity`，Then findings 含不匹配详情, reason_code=IDENTITY_MISMATCH, exit 1                                                             |
| TC-016 | FR-013, BR-010         | Given 下游仓库无 BR-010 禁止短语，When 运行 `trust template-residue`，Then status=pass, exit 0                                                                                              |
| TC-017 | FR-013, BR-010         | Given 下游仓库含 "承担五类职责：Standard Source..."，When 运行 `trust template-residue`，Then findings 含文件路径/行号/短语, reason_code=TEMPLATE_RESIDUE, exit 1                           |
| TC-018 | FR-014                 | Given 七源版本一致，When 运行 `trust release-consistency --offline`，Then status=pass, exit 0                                                                                               |
| TC-019 | FR-014                 | Given VERSION vs CHANGELOG 不一致，When 运行 `trust release-consistency --offline`，Then findings 含不一致值, reason_code=RELEASE_DRIFT, exit 1                                             |
| TC-020 | FR-015                 | Given 11 维工厂级判定全 true，When 运行 `trust maturity --factory`，Then overall=pass, exit 0                                                                                               |
| TC-021 | FR-015                 | Given unit_tests_complete=false, live_integration_complete=false，When 运行 `trust maturity --factory`，Then findings 含未满足维度, reason_code=FACTORY_GATE_BLOCKED, exit 1                |
| TC-022 | FR-016                 | Given import 符合 FOUNDATION-DEPS.yaml，When 运行 `trust import-boundary`，Then status=pass, exit 0                                                                                         |
| TC-023 | FR-016                 | Given binance import kernel 违反 forbidden_foundation_edges，When 运行 `trust import-boundary`，Then findings 含文件路径/行号, reason_code=IMPORT_BOUNDARY_VIOLATION, exit 1                |
| TC-024 | FR-017                 | Given 生产代码无 testkitx 但 test 文件有，When 运行 `trust testkit-prod-import`，Then test 文件不触发违规, exit 0                                                                           |
| TC-025 | FR-017                 | Given pkg/ 中 import testkitx，When 运行 `trust testkit-prod-import`，Then findings 含文件路径/行号, reason_code=TESTKIT_PROD_IMPORT, exit 1                                                |
| TC-026 | FR-018                 | Given release/evidence 无泄露，When 运行 `trust secret-redaction`，Then status=pass, exit 0                                                                                                 |
| TC-027 | FR-018                 | Given deploy-log.md 含 AWS_SECRET_ACCESS_KEY，When 运行 `trust secret-redaction`，Then findings 含文件路径/匹配类型（脱敏）, reason_code=SECRET_LEAK, exit 1                                |
| TC-028 | FR-019                 | Given 20 模块全成功，When 运行 `trust fleet-status`，Then 生成 index.json 含各模块状态, exit 0                                                                                              |
| TC-029 | FR-019                 | Given 2 模块缺少 .repo-contract.yaml，When 运行 `trust fleet-status`，Then 生成 index.json（含 2 error 模块）, exit 1                                                                       |

---

## 5. 全局 AC 注册表

| AC     | 所属 FR/BR  | Task   | 验收条件摘要                                                                                                                                                                                           |
| ------ | ----------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-001 | FR-001      | 002    | import 违规检测输出文件路径、行号、违规 import 路径，合规时 pass，exit code 0                                                                                                                          |
| AC-002 | FR-002      | 003    | go.mod tidy 无 diff → pass（exit 0），有 diff → 输出 diff 详情（exit 1），无 go.mod → error（exit 2）                                                                                                  |
| AC-003 | FR-003      | 004    | baseline 匹配 → pass（exit 0），不匹配 → 输出模块列表（exit 1），无 expected → error（exit 2）                                                                                                         |
| AC-004 | FR-004      | 005    | evidence 完整且通过 → pass（exit 0），缺失 → 输出缺失列表（exit 1），格式无效 → error（exit 2）                                                                                                        |
| AC-005 | FR-005      | 006    | 全部 pass → exit 0，任一 fail 且无 error → exit 1，任一 error → exit 2（error 优先于 fail）；checks[] 含全部 5 个子检查条目（含 pass 项，非仅失败项）；未提供 --evidence 且无配置 → release 标记 error |
| AC-006 | FR-006      | 006    | 默认 human-readable（含颜色），`--output json` 输出含 status/checks[]/summary，`--artifact` 写入文件                                                                                                   |
| AC-007 | BR-001      | 006    | exit code 映射：所有 pass→0，任一 fail→1（非 error 覆盖），任一 error→2                                                                                                                                |
| AC-008 | BR-009      | 002    | FOUNDATION-DEPS.yaml 解析正确，schema 校验通过，无效 yaml → ErrConfigInvalid                                                                                                                           |
| AC-009 | BR-005      | 006    | gitleaks 可用时执行扫描：零命中 → pass，命中 → fail（含文件路径/行号/规则）；gitleaks 不可用 → error                                                                                                   |
| AC-010 | FR-007      | 009    | manifest 有效时输出摘要（repo/layer/release_level/required_capabilities），exit 0；缺失或 YAML 解析失败时输出错误详情，exit 1                                                                          |
| AC-011 | FR-008      | 009    | registry 覆盖所有 required_capabilities 时生成 test-plan.json（含 required_contract_tests 列表），exit 0；缺失 capabilities 时输出缺失列表，exit 1                                                     |
| AC-012 | FR-009      | 009    | 所有必需契约测试通过时输出 passed/missing/failed 计数，exit 0；存在缺失或失败时输出详情，exit 1                                                                                                        |
| AC-013 | FR-010      | 009    | 所有必需证据文件存在时输出 present/missing 计数，exit 0；存在缺失时输出缺失列表，exit 1                                                                                                                |
| AC-014 | FR-011      | 009    | 所有硬性门禁通过且综合评分 ≥ 80 时输出 status=pass/score/hard_failures=0，exit 0；硬失败 >0 时输出 fail 状态和 hard_failures 列表，exit 1                                                              |
| AC-015 | FR-012      | 011    | 五源身份一致 → exit 0；任一不匹配 → exit 1, reason_code=IDENTITY_MISMATCH；.repo-contract.yaml 缺失 → exit 2, CONTRACT_PARSE_ERROR                                                                     |
| AC-016 | FR-013, BR-010 | 012 | 下游仓库无禁止短语 → exit 0；含禁止短语 → exit 1, reason_code=TEMPLATE_RESIDUE；xlib-standard 自身 → exit 0, TEMPLATE_RESIDUE_SELF_SKIP                                                               |
| AC-017 | FR-014      | 013    | 七源版本一致 → exit 0；不一致 → exit 1, reason_code=RELEASE_DRIFT；VERSION/CHANGELOG 缺失 → exit 1；--online 查询 GitHub API                                                                            |
| AC-018 | FR-015      | 014    | 11 维全 true → exit 0；任一维度 false → exit 1, reason_code=FACTORY_GATE_BLOCKED；单百分比拒绝 → exit 1；maturity 节缺失 → exit 2, CONTRACT_PARSE_ERROR                                               |
| AC-019 | FR-016      | 015    | import 合规 → exit 0；违反 forbidden edge → exit 1, reason_code=IMPORT_BOUNDARY_VIOLATION；kernel 导入非 stdlib → 标记 kernel_stdlib_violation；FOUNDATION-DEPS.yaml 缺失 → exit 2                     |
| AC-020 | FR-017      | 016    | 生产代码无 testkitx → exit 0；生产代码有 → exit 1, reason_code=TESTKIT_PROD_IMPORT；test 文件豁免；--strict 检查 internal/                                                                             |
| AC-021 | FR-018      | 017    | 文档无泄露 → exit 0；检测到密钥 → exit 1, reason_code=SECRET_LEAK（脱敏输出）；私有端点 → PRIVATE_ENDPOINT_LEAK；开发上下文豁免；release/evidence 缺失 → exit 2                                        |
| AC-022 | FR-019      | 018    | 20 模块全成功 → exit 0, 生成 index.json；部分失败 → exit 1, 仍生成 index.json；--summary-only 仅输出摘要                                                                                              |

---

## 6. 覆盖率仪表盘

| 指标            | 数值         | 说明                    |
| --------------- | ------------ | ----------------------- |
| FR 总数         | 19           | FR-001 ~ FR-019         |
| FR 有 AC 覆盖   | 19/19 (100%) |                         |
| FR 有 TC 覆盖   | 19/19 (100%) |                         |
| FR 有 Task 分配 | 19/19 (100%) |                         |
| BR 总数         | 10           | BR-001 ~ BR-010         |
| BR 有 TC 覆盖   | 10/10 (100%) |                         |
| BR 有 Task 分配 | 10/10 (100%) |                         |
| NFR 总数        | 18           | NFR-001 ~ NFR-018       |
| AC 总数         | 22           | AC-001 ~ AC-022         |
| TC 总数         | 29           | TC-001 ~ TC-029         |
| Task 总数       | 19           | TASK-XLIBGATE-000 ~ 018 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v1.0 | 初始版本：完整 7 列矩阵 + BR 行 + NFR 行 + TC 反向追溯 + AC 注册表 + 覆盖率仪表盘 |
| 2026-06-12 | v1.1 | 结构评分修复：FR 表 AC 列改为具体 AC-00X 引用、BR-005 补充 TC-008 引用、新增 secret 扫描测试用例 + AC-009（gitleaks 验收）、BR-008 验证方式追加 TC-008、仪表盘同步更新 |
| 2026-06-12 | v1.2 | 实现状态回填：FR/BR/NFR Status 列全部更新反映实际实现进展（✅/⚠️/❌）；仪表盘 Task 总数 7→9 修正（补充 TASK-007 集成测试、TASK-008 文档+DoD）；§1-§3 新增 Status 说明和修复项注释 |
| 2026-06-12 | v1.3 | 范围对齐（R1/R2 修复）：SPEC v1.0.2 新增 FR-007~FR-011（l2 子命令组）；FR 总数 6→11；BR-002/004/005/007 + NFR-007/008 Status → ✅；移除过时修复项注释 |
| 2026-06-12 | v1.4 | 追溯链闭合（SPEC 结构评分 REDLINE 修复）：FR-007~FR-011 AC/TC 列填入 AC-010~AC-014 / TC-009~TC-013；§4 TC→FR 表格新增 TC-009~TC-013；§5 AC 注册表新增 AC-010~AC-014；仪表盘 AC 9→14 / TC 8→13 / FR 覆盖率 6/6→11/11 |
| 2026-06-14 | v1.5 | Trust Alignment 追溯：SPEC v1.1.1 FR-012~FR-019 + BR-010 + TC-014~TC-029 + AC-015~AC-022 + NFR-011~NFR-018；仪表盘 FR 11→19 / BR 9→10 / NFR 10→18 / AC 14→22 / TC 13→29 / Task 9→19 |
