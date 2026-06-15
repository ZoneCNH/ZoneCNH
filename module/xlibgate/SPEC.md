# xlibgate 规格

- Status: Approved
- Spec-Version: v1.1.2
- Last-Updated: 2026-06-14
- Layer: 基座 · CI 门禁
- Module-Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `xlib-standard`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`xlibgate` 是 Foundation 的机器可执行门禁 CLI 工具，提供三组子命令：
- `check`：在 CI 中验证依赖矩阵、import 边界、Go baseline、secret 扫描和 release evidence，输出标准化 pass/fail。
- `l2`：L2 发布就绪门禁，包含能力清单校验、契约测试计划生成、契约/证据完整性验证、发布就绪评分。
- `trust`：v2 Trust Alignment 门禁，包含身份对齐、模板残留扫描、发布一致性、成熟度工厂、import 边界、testkitx 生产隔离、secret 脱敏、舰队状态聚合。

消费 `xlib-standard` 定义的 Gate 和 Evidence 标准。

---

## 2. 问题与背景

Foundation 由 70+ 个 Go 模块组成，模块间的依赖关系、import 边界和发布质量需要机器强制执行。没有统一门禁工具，会导致：

- 业务域模块反向依赖 Foundation 基座层，破坏分层架构
- 生产包意外依赖 `testkitx`，引入测试代码到生产环境
- `go.mod` 不整洁，依赖树不可重现
- Go toolchain 版本不一致，编译行为不可预测
- release evidence 散落在各 CI 脚本中，无法统一校验

---

## 3. 目标

- 提供 CLI 工具，可在 CI 和本地统一执行所有门禁检查
- import 边界扫描：检测禁止的依赖方向（生产包不依赖 testkitx，业务域不反向依赖）
- go.mod 整洁度检查：确保 `go mod tidy` 无 diff
- Go baseline 对齐：确保所有模块使用统一的 Go toolchain 版本
- release evidence 校验：收集和验证发布必需的质量证据
- 依赖矩阵验证：消费 `FOUNDATION-DEPS.yaml` 校验完整依赖关系
- 输出格式支持 JSON 和 human-readable，适配 CI artifact
- secret 扫描门禁：集成 `gitleaks` 检测泄露（由 FR-005 `check all` 统一执行，配置见 §11 Config Schema `secret_scan` 节）
- L2 发布就绪门禁：校验 `.agent/l2-capabilities.yaml` 能力清单，从 registry 解析契约测试要求，验证契约测试证据和文件级证据完整性，生成发布就绪评分 artifact
- v2 Trust Alignment 门禁（`trust` 子命令组）：身份对齐（repo/go.mod/README/SPEC/contract 五源比对）、模板残留扫描（禁止下游仓库声称 xlib-standard 身份）、发布一致性离线校验（版本表/go.mod/VERSION/CHANGELOG/tag/release/manifest 七源比对）、成熟度工厂门禁（11 维工厂级判定，禁止单项 100% 替代）、import 边界校验（消费 FOUNDATION-DEPS.yaml 的 allowed_deps 和 forbidden_foundation_edges）、testkitx 生产隔离（禁止生产代码导入 testkitx）、secret 脱敏扫描（release/evidence 文档中的密钥/API key/私有端点/DSN）、舰队状态聚合（20 模块 → .foundationx/status/index.json）

---

## 4. 非目标

- 不参与运行时（纯 CLI 工具，不被任何模块 import）
- 不做 Go 源码解析或 AST 分析框架（依赖关系数据通过 `go list`、`go mod graph` 等标准工具获取，xlibgate 只做规则匹配和结果聚合，不构建自有代码分析引擎）
- 不做交易、行情、风控、订单或仓位等任何业务域计算（xlibgate 是纯 CI 门禁工具，只验证结构和合规性，不参与业务数据流或状态变更）
- 不替代 CI 平台本身（只提供检查能力，不管理流水线）
- 不替代 `xlib-standard`（标准定义在 xlib-standard，机器执行在 xlibgate）
- 不做代码格式化（→ `gofmt` / `goimports`）
- 不做代码审查（→ human review + AI reviewer）

---

## 5. 消费者

| 消费者              | 使用方式                                                    |
| ------------------- | ----------------------------------------------------------- |
| CI 流水线           | 在 PR check 和 release pipeline 中调用 `xlibgate check all` |
| 开发者本地          | 在提交前本地运行 `xlibgate check imports` 验证合规          |
| `x.go` release 流程 | 调用 `xlibgate check release` 收集 release evidence         |
| Foundation 治理     | 通过门禁结果监控架构合规性                                  |
| L2 发布管线         | 调用 `xlibgate l2 release-check` 判定发布就绪               |
| 模块维护者          | 调用 `xlibgate l2 validate-manifest` 校验能力清单           |
| Trust Alignment 门禁 | 调用 `xlibgate trust identity/release-consistency/maturity` 系列命令验证模块信任对齐 |
| Foundation 治理（舰队） | 调用 `xlibgate trust fleet-status` 生成舰队级信任状态聚合报告 |

---

## 6. 功能需求

### FR-001: check imports

WHEN 调用 `xlibgate check imports --config deps.yaml` 且所有 import 路径符合依赖矩阵
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check imports --config deps.yaml` 且检测到禁止的 import（如业务域反向依赖基座）
THEN 输出违规详情（文件路径、行号、违规的 import 路径），exit code 1

WHEN 调用 `xlibgate check imports` 且未提供 `--config` 参数
THEN 输出错误提示，exit code 2

WHEN 配置文件中定义了 `testkitx` 边界规则且生产包 import 了 `testkitx`
THEN 输出违规详情，exit code 1

### FR-002: check gomod

WHEN 调用 `xlibgate check gomod --path ./...` 且 `go mod tidy` 无 diff
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check gomod --path ./...` 且 `go mod tidy` 产生 diff
THEN 输出 diff 详情，exit code 1

WHEN 指定路径下不存在 `go.mod` 文件
THEN 输出错误提示，exit code 2

### FR-003: check baseline

WHEN 调用 `xlibgate check baseline --expected 1.23` 且所有模块的 `go.mod` 中 `go` 指令版本一致
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check baseline --expected 1.23` 且某些模块的 Go 版本不匹配
THEN 输出不匹配的模块列表和版本差异，exit code 1

WHEN 未提供 `--expected` 参数且配置文件中未定义 `baseline.go_version`
THEN 输出错误提示，exit code 2

### FR-004: check release

WHEN 调用 `xlibgate check release --evidence evidence.json` 且所有必需 evidence 项存在且通过
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check release --evidence evidence.json` 且某些必需 evidence 项缺失或不通过
THEN 输出缺失/失败的 evidence 列表，exit code 1

WHEN 未提供 `--evidence` 参数
THEN 输出错误提示，exit code 2

WHEN evidence 文件格式无效（非 JSON 或 schema 不匹配）
THEN 输出解析错误，exit code 2

### FR-005: check all

WHEN 调用 `xlibgate check all --config deps.yaml --evidence evidence.json` 且所有子检查（imports / gomod / baseline / release / secret_scan）均通过
THEN 输出汇总结果（每项子检查的 pass 状态），exit code 0

WHEN 调用 `xlibgate check all --config deps.yaml --evidence evidence.json` 且任一子检查失败
THEN 输出所有失败子检查的详情，exit code 1

WHEN `check all` 执行过程中某子检查发生内部错误（含 secret_scan 调用 gitleaks 失败）
THEN 跳过该子检查标记为 error，继续执行其余检查，最终 exit code 2

WHEN 未提供 `--evidence` 参数且配置文件中未定义 `release.evidence_path`
THEN release 子检查标记为 error（exit code 2），其余子检查继续执行。优先使用 `--evidence` 参数，其次使用配置 `release.evidence_path`

WHEN 配置中 `secret_scan.enabled=true`（默认）且执行 `check all`
THEN 调用 `gitleaks detect --no-git` 扫描源码，泄露时输出文件路径和行号，exit code 1

WHEN `check all` 执行完成且同时存在 fail 和 error 的子检查
THEN error 优先级高于 fail，最终 exit code 2

### FR-006: 输出格式

WHEN 未指定 `--output` 参数
THEN 默认输出 human-readable 格式（带颜色的终端输出）

WHEN 指定 `--output json`
THEN 输出 JSON 格式，包含 `status`、`checks[]`、`summary` 字段

WHEN 指定 `--output json --artifact path.json`
THEN 将 JSON 结果写入指定文件路径

### FR-007: l2 validate-manifest

验证 `.agent/l2-capabilities.yaml` 能力清单的格式和内容完整性。

WHEN 调用 `xlibgate l2 validate-manifest --manifest .agent/l2-capabilities.yaml` 且 manifest 有效
THEN 输出 repo、layer、release_level、required_capabilities 摘要，exit code 0

WHEN manifest 文件缺失或 YAML 解析失败
THEN 输出错误详情，exit code 1

### FR-008: l2 plan

从能力清单和 registry 解析所需的 L2 契约测试，生成测试计划 artifact。

WHEN 调用 `xlibgate l2 plan --manifest ... --registry ... --output test-plan.json` 且 registry 覆盖所有 required capabilities
THEN 生成 test-plan.json（含 required_contract_tests 列表），exit code 0

WHEN registry 缺少某些 required capabilities 的契约测试
THEN 输出缺失列表，exit code 1

### FR-009: l2 check-contracts

验证原始契约测试证据（contract-test.json）是否覆盖测试计划中所有必需的契约测试。

WHEN 调用 `xlibgate l2 check-contracts --plan test-plan.json --contracts contract-test.json` 且所有必需契约测试通过
THEN 输出 passed/missing/failed 计数，exit code 0

WHEN 存在缺失或失败的必需契约测试
THEN 输出缺失/失败详情，exit code 1

### FR-010: l2 check-evidence

验证 L2 evidence 目录下必需证据文件是否存在。

WHEN 调用 `xlibgate l2 check-evidence --plan test-plan.json --evidence-root .agent/evidence` 且所有必需证据文件存在
THEN 输出 present/missing 计数，exit code 0

WHEN 存在缺失的必需证据文件
THEN 输出缺失列表，exit code 1

### FR-011: l2 release-check

执行完整的 L2 发布就绪判定：能力清单校验 → 测试计划生成 → 契约测试验证 → 证据完整性 → import 扫描 → secret 扫描 → 综合评分，输出 release-readiness.json artifact。

WHEN 调用 `xlibgate l2 release-check` 所有门禁通过且综合评分 ≥ 配置项 `l2.release_score_threshold`（默认 80）
THEN 输出 status=pass、score、hard_failures=0，exit code 0

WHEN 任一硬性门禁失败（硬失败 > 0）
THEN 输出 status=fail、hard_failures 列表，exit code 1

### FR-012: trust identity

WHEN 调用 `xlibgate trust identity --repo <repo-path>` 且 README H1 == repo name、go.mod module == `github.com/ZoneCNH/<repo>`、`public_package` 存在、下游仓库未声称 xlib-standard 身份
THEN 输出 JSON `{check: "identity", repo, status: "pass", reason_code: ""}`，exit code 0

WHEN README H1 不匹配 repo name 或 go.mod module 不匹配 `github.com/ZoneCNH/<repo>`
THEN 输出 findings 含不匹配字段详情，reason_code=IDENTITY_MISMATCH，exit code 1

WHEN 下游仓库声称 "Standard Source" / "Generator" / "Go Reference Template" 身份
THEN 输出 findings 含违规文件和声称内容，reason_code=IDENTITY_MISMATCH，exit code 1

WHEN repo 缺少 `public_package` 入口
THEN 输出 findings 含缺失项，reason_code=IDENTITY_MISMATCH，exit code 1

WHEN `.repo-contract.yaml` 缺失或解析失败
THEN reason_code=CONTRACT_PARSE_ERROR，exit code 2

### FR-013: trust template-residue

WHEN 调用 `xlibgate trust template-residue --repo <repo-path>` 且下游仓库不包含任何禁止短语
THEN 输出 JSON `{check: "template-residue", repo, status: "pass", reason_code: ""}`，exit code 0

WHEN 下游仓库（非 xlib-standard）包含禁止短语
THEN 输出 findings 含文件路径、行号和匹配短语，reason_code=TEMPLATE_RESIDUE，exit code 1

WHEN `--summary` 参数指定
THEN 输出命中统计（按短语分组计数），不改变 exit code

WHEN 目标仓库为 xlib-standard 自身
THEN 自动跳过检查，reason_code=TEMPLATE_RESIDUE_SELF_SKIP，status=pass，exit code 0

### FR-014: trust release-consistency

WHEN 调用 `xlibgate trust release-consistency --offline --repo <repo-path>` 且 .repo-contract.yaml versions.table_version、go.mod module、VERSION 文件、CHANGELOG latest section、git tag、GitHub latest release（离线模式以本地 manifest 和 tag 投影替代）、release/manifest/latest.json 七源一致
THEN 输出 JSON `{check: "release-consistency", repo, status: "pass", reason_code: ""}`，exit code 0

WHEN 七源中存在版本不一致
THEN 输出 findings 含不一致的源和各自版本值，reason_code=RELEASE_DRIFT，exit code 1

WHEN VERSION 文件或 CHANGELOG 缺失
THEN reason_code=RELEASE_DRIFT（作为缺失子项），exit code 1

WHEN 指定 `--online` 参数
THEN 在线查询 GitHub latest release API 替代本地 manifest/tag 投影，对不存在的 release 输出 reason_code=RELEASE_DRIFT

### FR-015: trust maturity

工厂级 11 维判定维度：`spec_complete`、`implementation_complete`、`unit_tests_complete`、`contract_tests_complete`、`traceability_complete`、`release_manifest_complete`、`live_integration_complete`、`failure_profiles_complete`、`external_ci_artifacts_complete`、`downstream_adoption_complete`、`production_soak_complete`。所有维度必须为 true 方可通过工厂级门禁，禁止用单个百分比值替代。

工厂级门禁必须 blocker-aware：除 11 维全部为 true 外，目标 repo 的发布状态和阻断项也参与判定。`release=false` 或存在任一 open blocker 时，`factory=false`，`overall=fail`，reason_code 保持 `FACTORY_GATE_BLOCKED`，exit code 1；不得把 release 缺失或 open blocker 投影为 factory pass。

WHEN 调用 `xlibgate trust maturity --factory --repo <repo-path>` 且所有 11 维工厂级判定均为 true
THEN 输出 JSON 含 11 维逐项判定和 overall=pass，reason_code=""，exit code 0

WHEN 任一工厂级维度不满足
THEN 输出未满足维度列表和各自现状值，reason_code=FACTORY_GATE_BLOCKED，exit code 1

WHEN maturity 数据源仅提供单个 "100%" 值而无 11 维明细
THEN 拒绝接受该值，reason_code=FACTORY_GATE_BLOCKED，exit code 1

WHEN `.repo-contract.yaml` 或状态投影中 `release=false`
THEN 输出 release gate 未满足的 findings，factory=false，reason_code=FACTORY_GATE_BLOCKED，exit code 1

WHEN `.repo-contract.yaml`、`.foundationx/blockers.json` 或状态投影中存在 target repo 的 open blocker
THEN 输出 open blocker 的 id/severity/source，factory=false，reason_code=FACTORY_GATE_BLOCKED，exit code 1

WHEN `.repo-contract.yaml` 中 `maturity` 节缺失
THEN reason_code=CONTRACT_PARSE_ERROR，exit code 2

### FR-016: trust import-boundary

WHEN 调用 `xlibgate trust import-boundary --repo <repo-path> --deps FOUNDATION-DEPS.yaml` 且所有 import 符合 allowed_deps 且不违反 forbidden_foundation_edges
THEN 输出 JSON `{check: "import-boundary", repo, status: "pass", reason_code: ""}`, exit code 0

WHEN 检测到违反 allowed_deps 或 forbidden_foundation_edges 的 import
THEN 输出 findings 含文件路径、行号、违规 import 路径和违反的规则，reason_code=IMPORT_BOUNDARY_VIOLATION，exit code 1

WHEN 目标模块为 kernel 且导入了非 stdlib 的包
THEN 特别标记为 kernel_stdlib_violation，reason_code=IMPORT_BOUNDARY_VIOLATION，exit code 1

WHEN FOUNDATION-DEPS.yaml 缺失或解析失败
THEN reason_code=CONTRACT_PARSE_ERROR，exit code 2

### FR-017: trust testkit-prod-import

WHEN 调用 `xlibgate trust testkit-prod-import --repo <repo-path>` 且生产代码中无 `testkitx` import
THEN 输出 JSON `{check: "testkit-prod-import", repo, status: "pass", reason_code: ""}`, exit code 0

WHEN 生产代码（pkg/、internal/ 运行时代码、cmd/ 生产二进制）中检测到 testkitx import
THEN 输出 findings 含文件路径、行号和 import 语句，reason_code=TESTKIT_PROD_IMPORT，exit code 1

WHEN testkitx import 出现在允许范围内（*_test.go、test/、testkit/、examples/、internal/test*、cmd/test*）
THEN 不触发违规，status=pass

WHEN `--strict` 参数指定且 testkitx 出现在 internal/ 非 test 子目录
THEN 将 internal/ 视为生产代码严格检查

### FR-018: trust secret-redaction

WHEN 调用 `xlibgate trust secret-redaction --repo <repo-path> --path release/evidence` 且所有文档无敏感信息
THEN 输出 JSON `{check: "secret-redaction", repo, status: "pass", reason_code: ""}`, exit code 0

WHEN 检测到 secrets（API keys、passwords、tokens、DSN with credentials）
THEN 输出 findings 含文件路径、行号和脱敏后的匹配类型（不输出密钥原文），reason_code=SECRET_LEAK，exit code 1

WHEN 检测到私有端点（127.0.0.1、localhost、10.x.x.x、172.16-31.x.x、192.168.x.x），但以下开发上下文豁免：文件路径含 `test/`、`testdata/`、`_test.go`、`.md` 中的示例代码块标记为 `dev-only`、`README.md` 的本地开发章节
THEN 输出 findings 含文件路径、行号和端点地址，reason_code=PRIVATE_ENDPOINT_LEAK，exit code 1

WHEN 扫描路径下无 release/evidence 目录
THEN reason_code=CONTRACT_PARSE_ERROR，exit code 2

### FR-019: trust fleet-status

WHEN 调用 `xlibgate trust fleet-status --repos-root <foundation-root> --output .foundationx/status/index.json` 且 20 模块全部扫描成功
THEN 生成 index.json 含每模块 identity/release/maturity/boundaries/blockers/evidence-index 状态，exit code 0

WHEN repo 层 trust 子命令结果、`.repo-contract.yaml`、release manifest 或 `.foundationx/blockers.json` 投影到 index.json 后不一致（例如 release=false 但 factory=true，或存在 open blocker 但 factory=true）
THEN 将该模块标记 status=fail，reason_code=FACTORY_GATE_BLOCKED，findings 指出 projection drift 的源字段和值，exit code 1

WHEN 任一模块 release=false
THEN 该模块 factory 必须投影为 false；若输入声明 factory=true，按 projection drift 处理，reason_code=FACTORY_GATE_BLOCKED，exit code 1

WHEN 任一模块存在 open blocker
THEN 该模块 factory 必须投影为 false，并在 index.json 的 blockers 列表保留 open blocker 摘要；若输入声明 factory=true，按 projection drift 处理，reason_code=FACTORY_GATE_BLOCKED，exit code 1

WHEN 部分模块扫描失败（如缺失 .repo-contract.yaml）
THEN 在 index.json 中对应模块标记 status=error 和 error 详情，仍生成完整 index.json，exit code 1

WHEN `--repos-root` 下模块数量不为 20
THEN 输出实际模块数和预期差异，仍生成 index.json（含 warning），exit code 1

WHEN `.foundationx/status/` 目录不存在
THEN 自动创建目录，不报错

WHEN 指定 `--summary-only` 参数
THEN 只输出摘要 JSON（pass/fail/error 计数和 blocker 列表），不生成完整 index.json

---

## 7. 行为约束

### BR-001: 标准化 exit code

所有检查命令返回标准化 exit code：0=pass, 1=fail, 2=error。

**约束**：每个子命令的 exit code 语义不可互换。`exit 1` 仅表示检查未通过（业务失败），`exit 2` 仅表示内部错误（配置无效、文件缺失等）。

**违反时**：CI 无法正确判断门禁结果（将内部错误与业务失败混淆），导致错误地阻塞或放行。处理：检查自身在启动阶段校验配置完整性，子检查内部 error 时通过 FR-005 的汇总机制统一降级为 exit 2。

### BR-002: import 规则从配置文件读取

import 边界规则从 `deps.yaml` 配置文件读取，不硬编码。

**约束**：规则的新增、删除、修改只需更新配置文件，无需修改 xlibgate 源码或重新编译。

**违反时**：规则变更需改代码重新编译发布，CI 门禁无法灵活适应新的依赖约束。处理：拒绝接受命令行直接传入的 import 规则字符串；`--config` 缺失时仅报错，不回退到硬编码规则。

### BR-003: Go baseline 从配置或参数获取

Go baseline 版本从配置或 `--expected` 参数获取，不硬编码。

**约束**：版本升级时只需修改配置文件或 CI 脚本中的 `--expected` 参数值。

**违反时**：Go 版本升级需改动 xlibgate 源码重新编译，增加 CI 基础设施维护成本。处理：未提供 `--expected` 且配置无 `baseline.go_version` 时，输出明确错误提示（exit 2），不使用编译时硬编码的默认版本号。

### BR-004: evidence schema 与 xlib-standard 一致

release evidence 清单与 `xlib-standard` 定义的 Evidence schema 保持一致。

**约束**：evidence JSON 的字段名、类型、必需项、枚举值必须与 xlib-standard 的 Evidence Runtime 定义完全相同。

**违反时**：跨工具 evidence 不可互操作——xlibgate 生成的 evidence 无法被其他 xlib-standard 兼容工具校验，反之亦然。处理：evidence schema 校验阶段检测到不匹配时，返回 `ErrEvidenceInvalid`（exit 2），不静默接受。

### BR-005: secret 扫描使用 gitleaks

secret 扫描使用 `gitleaks` 作为底层工具，不自行实现扫描逻辑。

**约束**：gitleaks 作为外部命令调用；xlibgate 只负责调用、解析输出、集成到汇总报告中。

**违反时**：自研扫描器的规则覆盖面和准确性远不如经过社区长期验证的 gitleaks，存在漏报风险。处理：当 gitleaks 二进制不可用时，输出明确错误信息（"gitleaks not found, install from https://github.com/gitleaks/gitleaks"），exit 2。

### BR-006: check all 必须执行所有子检查

`check all` 必须执行所有子检查，即使前面的检查已失败。

**约束**：子检查的执行顺序不影响汇总结果；任一子检查失败或出错不影响其余子检查的独立执行。

**违反时**：部分检查被跳过，门禁不完整——例如 imports 失败导致 gomod/baseline/release/secret_scan 全部跳过，遗漏其他合规问题。处理：`check all` 实现中每个子检查在独立 goroutine 中运行，通过 errgroup 或 WaitGroup 等待全部完成后统一汇总。

### BR-007: JSON 输出含 machine-readable status

JSON 输出必须包含 machine-readable 的 status 字段（pass/fail/error）。

**约束**：顶层 `status` 字段和每项 `checks[].status` 字段均使用枚举值 `"pass" | "fail" | "error"`，不允许空字符串或其他值。

**违反时**：CI 解析失败，无法自动化判断门禁结果。处理：JSON 序列化前在 `CheckResult.Status` 的 `MarshalJSON` 中校验枚举值，非法值时 panic（编程错误，不应到达生产）。

### BR-008: human-readable 输出含文件路径和行号

检查结果的 human-readable 输出必须包含文件路径和行号（如有）。

**约束**：适用于所有可定位到源码位置的检查（imports 违规、gomod diff、secret_scan 命中）；不适用于 pure semantic 检查（如 baseline 版本不匹配只需模块名）。

**违反时**：开发者无法快速定位违规位置，需手动搜索全仓库。处理：`Violation` 结构体的 `File` 字段为必填，`Line` 可选；human-readable formatter 在 File 为空时输出 `"<unknown location>"` 提示信息不完整。

### BR-009: FOUNDATION-DEPS.yaml schema 与 xlib-standard 一致

依赖矩阵文件 `FOUNDATION-DEPS.yaml` 的 schema 与 `xlib-standard` 定义一致。

**约束**：YAML 结构、字段名、数据类型、必填/可选字段完全对齐 xlib-standard 的 Gate 模块中的 deps schema。

**违反时**：deps.yaml 解析失败或行为与预期不符，其他依赖 xlib-standard 的工具也无法读取同一份 deps 文件。处理：解析 deps.yaml 时执行 schema 校验，不匹配时返回 `ErrConfigInvalid` 并附详细错误路径（如 `imports.forbidden[0].source: field required`）。

### BR-010: 禁止模板身份短语（template-residue）

下游仓库（非 xlib-standard）不得包含以下五条禁止短语：

1. "承担五类职责：Standard Source、Go Reference Template、Generator、Harness 和 Evidence Runtime"
2. "本仓库不再把标准源与模板实现拆成两个角色"
3. "提供可编译参考包 pkg/templatex"
4. "渲染后会移动到 pkg/<package-name>"
5. "生成库包括 configx、observex、testkitx"

**约束**：只有 `github.com/ZoneCNH/xlib-standard` 仓库允许包含以上短语。其他所有 Foundation 仓库包含任一短语即违规。`template-residue` 检查必须执行精确字符串匹配（含标点和空格），不区分注释或代码上下文。

**违反时**：下游仓库包含模板身份声明，导致模块身份定义冲突——CI 和文档工具无法区分真正的标准源/生成器/模板实现与残留模板文案。处理：检查结果中逐文件、逐行列出匹配短语，给出 reason_code=TEMPLATE_RESIDUE。

---

## 8. 接口契约

### 8.1 CLI 命令

```bash
# import 边界检查
xlibgate check imports --config deps.yaml [--output json] [--artifact result.json]

# go.mod 整洁度
xlibgate check gomod --path ./... [--output json]

# Go baseline 对齐
xlibgate check baseline --expected 1.23 [--output json]

# release evidence
xlibgate check release --evidence evidence.json [--output json]

# 全量门禁
xlibgate check all --config deps.yaml --evidence evidence.json [--output json] [--artifact result.json]

# L2 能力清单校验
xlibgate l2 validate-manifest --manifest .agent/l2-capabilities.yaml

# L2 测试计划生成
xlibgate l2 plan --manifest .agent/l2-capabilities.yaml --registry contracts/registry.yaml --output test-plan.json

# L2 契约测试验证
xlibgate l2 check-contracts --plan test-plan.json --contracts contract-test.json

# L2 证据完整性
xlibgate l2 check-evidence --plan test-plan.json --evidence-root .agent/evidence

# L2 发布就绪判定
xlibgate l2 release-check --manifest .agent/l2-capabilities.yaml --registry contracts/registry.yaml --evidence-root .agent/evidence [--output json] [--artifact release-readiness.json]

# v2 Trust Alignment — 身份对齐
xlibgate trust identity --repo <repo-path> [--output json]

# v2 Trust Alignment — 模板残留扫描
xlibgate trust template-residue --repo <repo-path> [--summary] [--output json]

# v2 Trust Alignment — 发布一致性（离线模式）
xlibgate trust release-consistency --offline --repo <repo-path> [--online] [--output json]

# v2 Trust Alignment — 成熟度工厂门禁
xlibgate trust maturity --factory --repo <repo-path> [--output json]

# v2 Trust Alignment — import 边界
xlibgate trust import-boundary --repo <repo-path> --deps FOUNDATION-DEPS.yaml [--output json]

# v2 Trust Alignment — testkitx 生产隔离
xlibgate trust testkit-prod-import --repo <repo-path> [--strict] [--output json]

# v2 Trust Alignment — secret 脱敏扫描
xlibgate trust secret-redaction --repo <repo-path> --path release/evidence [--output json]

# v2 Trust Alignment — 舰队状态聚合
xlibgate trust fleet-status --repos-root <foundation-root> --output .foundationx/status/index.json [--summary-only] [--output json]

# 版本
xlibgate version
```

### 8.2 Exit Code 定义

```text
0 — pass：所有检查通过
1 — fail：至少一项检查未通过
2 — error：发生内部错误（配置无效、文件缺失等）
```

### 8.3 JSON 输出格式

```json
{
  "status": "pass|fail|error",
  "timestamp": "2026-06-07T12:00:00Z",
  "checks": [
    {
      "name": "imports",
      "status": "pass|fail|error",
      "details": [],
      "duration_ms": 1234
    }
  ],
  "summary": {
    "total": 5,
    "passed": 5,
    "failed": 0,
    "errors": 0
  }
}
```

`check all` 多子检查混合结果示例（imports=fail, gomod=pass, baseline=error, release=pass, secret_scan=pass）：

```json
{
  "status": "fail",
  "timestamp": "2026-06-12T14:30:00Z",
  "checks": [
    {"name": "imports",     "status": "fail",  "details": [{"file": "pkg/strategy.go", "line": 5, "message": "forbidden import: github.com/ZoneCNH/kernel"}], "duration_ms": 2340},
    {"name": "gomod",       "status": "pass",  "details": [], "duration_ms": 1200},
    {"name": "baseline",    "status": "error", "details": [{"file": "", "line": 0, "message": "baseline.go_version not configured"}], "duration_ms": 10},
    {"name": "release",     "status": "pass",  "details": [], "duration_ms": 450},
    {"name": "secret_scan", "status": "pass",  "details": [], "duration_ms": 3200}
  ],
  "summary": {
    "total": 5,
    "passed": 3,
    "failed": 1,
    "errors": 1
  }
}
```

### 9.3.1 Trust Alignment 统一输出格式

所有 `trust` 子命令输出统一的 per-check JSON schema：

```json
{
  "check": "<检查名>",
  "repo": "github.com/ZoneCNH/<repo>",
  "status": "pass|fail|error",
  "severity": "info|warn|block",
  "findings": [
    {
      "file": "路径",
      "line": 42,
      "rule": "规则名",
      "message": "人类可读描述"
    }
  ],
  "reason_code": "IDENTITY_MISMATCH|TEMPLATE_RESIDUE|RELEASE_DRIFT|FACTORY_GATE_BLOCKED|IMPORT_BOUNDARY_VIOLATION|TESTKIT_PROD_IMPORT|SECRET_LEAK|PRIVATE_ENDPOINT_LEAK|CONTRACT_PARSE_ERROR|TEMPLATE_RESIDUE_SELF_SKIP",
  "evidence": {
    "projection": {
      "release": true,
      "factory": true,
      "open_blockers": []
    }
  }
}
```

**字段说明**：

| 字段 | 说明 |
|------|------|
| `check` | 子命令名：`identity` / `template-residue` / `release-consistency` / `maturity` / `import-boundary` / `testkit-prod-import` / `secret-redaction` / `fleet-status` |
| `repo` | 目标仓库的完整 Go module 路径 |
| `status` | `pass`（exit 0）/ `fail`（exit 1）/ `error`（exit 2） |
| `severity` | `info`（status=pass 时）/ `warn`（status=fail 但非阻塞）/ `block`（status=fail 且阻塞门禁） |
| `findings` | 违规详情数组，status=pass 时为空 |
| `reason_code` | 机器可读原因码，status=pass 时为空字符串 |
| `evidence` | 检查中收集的辅助证据（如 identity 的比对表、maturity 的 11 维明细、release-consistency 的版本源值、fleet-status 的 release/factory/open_blockers 投影），供仲裁和审计使用 |

**reason_code 枚举**：

| reason_code | 含义 | 触发检查 |
|-------------|------|----------|
| `IDENTITY_MISMATCH` | 身份字段不匹配（README H1 / go.mod / contract） | identity |
| `TEMPLATE_RESIDUE` | 下游仓库包含禁止的模板身份短语 | template-residue |
| `TEMPLATE_RESIDUE_SELF_SKIP` | 目标为 xlib-standard，自动跳过 | template-residue |
| `RELEASE_DRIFT` | 七源版本信息不一致 | release-consistency |
| `FACTORY_GATE_BLOCKED` | 工厂级成熟度门禁未通过；或 release=false / open blocker / factory 投影不一致导致 factory=false | maturity / fleet-status |
| `IMPORT_BOUNDARY_VIOLATION` | import 违反 allowed_deps 或 forbidden_foundation_edges | import-boundary |
| `TESTKIT_PROD_IMPORT` | 生产代码导入了 testkitx | testkit-prod-import |
| `SECRET_LEAK` | 文档中检测到密钥/API key/token/DSN | secret-redaction |
| `PRIVATE_ENDPOINT_LEAK` | 文档中检测到私有端点地址 | secret-redaction |
| `CONTRACT_PARSE_ERROR` | `.repo-contract.yaml` 或 `FOUNDATION-DEPS.yaml` 缺失/解析失败 | 多个检查 |

### 8.4 配置格式

```yaml
# xlibgate.yaml
baseline:
  go_version: "1.23"

imports:
  forbidden:
    - source: "github.com/ZoneCNH/testkitx"
      targets: ["*"]
    - source: "github.com/ZoneCNH/binance"
      targets: ["github.com/ZoneCNH/kernel", "github.com/ZoneCNH/configx"]

release:
  require:
    - test_coverage >= 80%
    - race_test_pass
    - secret_scan_pass
    - gomod_tidy
    - vet_clean
```

---

## 9. 数据模型

### 9.1 公共错误

```go
var (
    ErrConfigInvalid    = errors.New("xlibgate: invalid config")
    ErrConfigMissing    = errors.New("xlibgate: config file not found")
    ErrEvidenceInvalid  = errors.New("xlibgate: invalid evidence format")
    ErrEvidenceMissing  = errors.New("xlibgate: required evidence missing")
    ErrBaselineMismatch = errors.New("xlibgate: go baseline version mismatch")
    ErrImportViolation  = errors.New("xlibgate: import boundary violation")
    ErrGomodDirty       = errors.New("xlibgate: go.mod not tidy")
)
```

### 9.2 检查结果结构

```go
type CheckResult struct {
    Name       string        `json:"name"`
    Status     CheckStatus   `json:"status"`
    Details    []Violation   `json:"details,omitempty"`
    DurationMs int64         `json:"duration_ms"`
}

type CheckStatus string

const (
    StatusPass  CheckStatus = "pass"
    StatusFail  CheckStatus = "fail"
    StatusError CheckStatus = "error"
)

type Violation struct {
    File    string `json:"file"`
    Line    int    `json:"line,omitempty"`
    Message string `json:"message"`
}
```

---

## 10. 配置模式

```yaml
# xlibgate.yaml 完整 schema
baseline:
  go_version: string          # required，期望的 Go 版本（如 "1.23"）

imports:
  forbidden:                  # 禁止的 import 规则列表
    - source: string          # 源包路径（支持通配符）
      targets: [string]       # 禁止 import 的目标包（["*"] 表示所有）

release:
  evidence_path: string        # optional，evidence 文件路径（check all 时若未传 --evidence 则使用此值）
  require: [string]            # 必需的 release evidence 条件列表

secret_scan:
  enabled: bool               # default: true
  config_path: string         # gitleaks 配置文件路径（可选）
```

---

## 11. 错误处理

| 错误                  | 调用方处理                                                       |
| --------------------- | ---------------------------------------------------------------- |
| `ErrConfigInvalid`    | 检查 YAML 语法和 schema，修复配置文件                            |
| `ErrConfigMissing`    | 确认 `--config` 参数路径正确，或在项目根目录放置 `xlibgate.yaml` |
| `ErrEvidenceInvalid`  | 检查 evidence JSON 格式，确认与 schema 匹配                      |
| `ErrEvidenceMissing`  | 运行对应的 CI 步骤生成缺失的 evidence                            |
| `ErrBaselineMismatch` | 更新模块的 `go.mod` 中 `go` 指令版本，或更新 baseline 配置       |
| `ErrImportViolation`  | 移除违规的 import 语句，调整模块依赖关系                         |
| `ErrGomodDirty`       | 运行 `go mod tidy` 并提交变更                                    |
| `ErrIdentityMismatch`  | 检查 README H1、go.mod module、contract identity 字段，修复不匹配项 |
| `ErrTemplateResidue`   | 从下游仓库文档中移除 BR-010 定义的禁止短语 |
| `ErrReleaseDrift`      | 对齐 .repo-contract.yaml、VERSION、CHANGELOG、git tag、release manifest 七源版本 |
| `ErrFactoryGateBlocked` | 补充未满足的成熟度维度证据（如补齐单元测试、集成测试、契约测试） |
| `ErrSecretLeak`        | 从 release/evidence 文档中移除泄露的密钥/端点，轮换已暴露的凭证 |
| `ErrFleetPartialFail`  | 检查失败模块的 .repo-contract.yaml，修复后重新运行 fleet-status |

**错误消息格式：** `"xlibgate: <check>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 12. 边界情况

| 场景                                 | 预期行为                                                                                                                  |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| 配置文件为空                         | 使用默认值（无 forbidden 规则、无 baseline 要求）                                                                         |
| 配置文件只有注释                     | 同上，视为空配置                                                                                                          |
| `--path` 指向不存在的目录            | 输出错误提示，exit code 2                                                                                                 |
| `--path` 指向非 Go 项目（无 go.mod） | 输出错误提示，exit code 2                                                                                                 |
| import 路径包含 vendor 目录          | 跳过 vendor 目录，只扫描项目自身代码                                                                                      |
| Go 模块使用 replace 指令             | baseline 检查只验证 `go` 指令版本，不检查 replace                                                                         |
| evidence 文件超大（>100MB）          | 正常解析，内存 < 文件大小 2x                                                                                              |
| 并发运行多个 `xlibgate` 实例         | 各实例独立，无状态冲突                                                                                                    |
| `check all` 中某子检查超时           | 标记为 error，继续执行其余检查                                                                                            |
| CI 环境无 color 支持                 | 自动检测终端，无 color 时输出纯文本                                                                                       |
| 子检查失败后自动重试                 | 默认不重试（单次执行）；可通过配置 `retry: {max_attempts: N, backoff: "constant"}` 启用有限重试，N 次后仍失败标记为 error |
| trust identity 目标仓库无 .repo-contract.yaml | reason_code=CONTRACT_PARSE_ERROR，exit code 2 |
| trust template-residue 扫描二进制文件（.png、.so） | 跳过非文本文件，只扫描 .md/.yaml/.go/.txt/.json 等文本格式 |
| trust release-consistency 离线模式下 VERSION 文件为空 | reason_code=RELEASE_DRIFT，作为缺失子项 |
| trust maturity 数据源仅提供单个百分比值 | 拒绝接受，reason_code=FACTORY_GATE_BLOCKED，exit code 1 |
| trust maturity release=false 但 11 维均为 true | factory=false，输出 release gate finding，reason_code=FACTORY_GATE_BLOCKED，exit code 1 |
| trust maturity 存在 open blocker 但 11 维均为 true | factory=false，输出 blocker id/severity/source，reason_code=FACTORY_GATE_BLOCKED，exit code 1 |
| trust import-boundary 目标模块无 FOUNDATION-DEPS.yaml | reason_code=CONTRACT_PARSE_ERROR，exit code 2 |
| trust testkit-prod-import 目标为 testkitx 自身 | 自动跳过检查，status=pass，reason_code=""（testkitx 允许引用自身） |
| trust secret-redaction 扫描路径含符号链接 | 跟踪符号链接，但限制深度 max 3 层防止循环 |
| trust fleet-status repos-root 下模块目录名与 go.mod module 不一致 | 输出 warning，记录不一致详情，不阻塞聚合 |
| trust fleet-status 输入声明 release=false 但 factory=true | 标记 projection drift，强制 factory=false，reason_code=FACTORY_GATE_BLOCKED，exit code 1 |
| trust fleet-status 输入存在 open blocker 但 factory=true | 标记 projection drift，强制 factory=false，保留 blocker 摘要，reason_code=FACTORY_GATE_BLOCKED，exit code 1 |
| trust fleet-status 输出文件已存在 | 覆盖写入，不报错 |

---

## 13. 目录结构

```text
xlibgate/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── main.go                     # CLI 入口
├── cmd/
│   ├── root.go                 # root 命令和全局 flags
│   ├── check.go                # check 父命令
│   ├── imports.go              # check imports 子命令
│   ├── gomod.go                # check gomod 子命令
│   ├── baseline.go             # check baseline 子命令
│   ├── release.go              # check release 子命令
│   ├── all.go                  # check all 子命令
│   ├── trust.go                # trust 父命令
│   ├── trust_identity.go       # trust identity 子命令
│   ├── trust_template.go       # trust template-residue 子命令
│   ├── trust_release.go        # trust release-consistency 子命令
│   ├── trust_maturity.go       # trust maturity 子命令
│   ├── trust_boundary.go       # trust import-boundary 子命令
│   ├── trust_testkit.go        # trust testkit-prod-import 子命令
│   ├── trust_secret.go         # trust secret-redaction 子命令
│   └── trust_fleet.go          # trust fleet-status 子命令
├── scanner/
│   ├── imports.go              # import 边界扫描器
│   ├── gomod.go                # go.mod 整洁度检查器
│   ├── baseline.go             # Go baseline 检查器
│   └── trust/
│       ├── identity.go         # 身份对齐扫描器
│       ├── template.go         # 模板残留扫描器
│       ├── release.go          # 发布一致性扫描器
│       ├── maturity.go         # 成熟度工厂扫描器
│       ├── boundary.go         # import 边界扫描器（trust 版）
│       ├── testkit.go          # testkitx 生产隔离扫描器
│       ├── secret.go           # secret 脱敏扫描器
│       └── fleet.go            # 舰队状态聚合器
├── evidence/
│   ├── collector.go            # evidence 收集
│   └── validator.go            # evidence 校验
├── config.go                   # 配置加载和解析
├── report.go                   # 报告生成（JSON + human-readable）
├── errors.go                   # 公共错误变量
├── internal/
│   ├── gomod/                  # go.mod 解析工具
│   └── ast/                    # Go AST 解析工具
├── testdata/
│   ├── config.yaml
│   ├── deps.yaml
│   ├── evidence.json
│   └── fixtures/
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/xlibgate

go 1.23
```

### 14.2 直接依赖

| 依赖                                                                              | 版本          | 用途                                                       | 来源       |
| --------------------------------------------------------------------------------- | ------------- | ---------------------------------------------------------- | ---------- |
| stdlib (`go/parser`, `go/ast`, `go/token`, `os/exec`, `encoding/json`, `flag` 等) | Go 1.23       | Go 源码 AST 解析、外部命令调用、JSON 序列化、CLI flag 解析 | 标准库     |
| `gopkg.in/yaml.v3`                                                                | v3            | YAML 配置文件解析（`xlibgate.yaml`、`deps.yaml`）          | 第三方     |
| `gitleaks`                                                                        | latest stable | secret 扫描引擎（作为外部命令调用，非 Go import）          | 外部二进制 |

### 14.3 间接依赖

xlibgate 是纯 CLI 工具，不被任何模块 import。仅通过 `go/parser` 标准库间接引入 Go 工具链的标准依赖，无第三方传递依赖。

### 14.4 依赖方向

| 可以依赖                                    | 禁止依赖                                                   |
| ------------------------------------------- | ---------------------------------------------------------- |
| stdlib                                      | 所有 Foundation 运行时模块（kernel, configx, observex 等） |
| `gopkg.in/yaml.v3`（配置解析）              | 所有业务域实现                                             |
| Go AST 解析库（`go/parser`, `go/ast`）      | 所有 L2.5 领域共享层                                       |
| `gitleaks`（secret 扫描，作为外部命令调用） |                                                            |

### 14.5 特殊说明

xlibgate 是纯 CLI 工具，不被任何模块 import。它只扫描其他模块的代码，不产生运行时依赖。

---

## 15. 测试

### 15.1 测试工具

| 工具                           | 用途                           |
| ------------------------------ | ------------------------------ |
| `testing`                      | Go 标准测试框架                |
| `testify`                      | 断言库（`assert` / `require`） |
| `go tool cover`                | 覆盖率报告                     |
| `go test -race`                | 竞态检测                       |
| `go test -bench` / `-benchmem` | 性能基准测试                   |

### 15.2 单元测试

| 测试场景              | 验证点                                             |
| --------------------- | -------------------------------------------------- |
| import 违规检测       | 业务域反向依赖 Foundation → 报错，含文件路径和行号 |
| testkitx 边界         | 生产包依赖 testkitx → 报错                         |
| import 合规           | 符合依赖矩阵 → pass                                |
| go.mod 不整洁         | `go mod tidy` 有 diff → 报错                       |
| go.mod 整洁           | `go mod tidy` 无 diff → pass                       |
| baseline 不匹配       | go.mod 中 go 版本 != expected → 报错               |
| baseline 匹配         | go.mod 中 go 版本 == expected → pass               |
| release evidence 缺失 | 必需 evidence 项缺失 → 报错                        |
| release evidence 完整 | 所有必需 evidence 项存在且通过 → pass              |
| config 解析           | 有效 YAML → 正确加载                               |
| config 无效           | 语法错误 → ErrConfigInvalid                        |
| config 缺失           | 文件不存在 → ErrConfigMissing                      |
| exit code             | pass=0, fail=1, error=2                            |
| JSON 输出             | 格式正确，包含所有必需字段                         |
| human-readable 输出   | 包含文件路径和行号                                 |
| secret 扫描通过       | gitleaks 零命中 → pass                             |
| secret 扫描命中       | gitleaks 检测到泄露 → 报错，含文件路径和行号       |
| trust identity 匹配   | README H1/go.mod/contract 五源一致 → pass          |
| trust identity 不匹配 | README H1 不匹配 repo name → fail，reason_code=IDENTITY_MISMATCH |
| trust template 无残留 | 下游仓库无禁止短语 → pass                          |
| trust template 有残留 | 下游含 "承担五类职责" → fail，reason_code=TEMPLATE_RESIDUE |
| trust release 一致    | 七源版本一致 → pass                                |
| trust release 不一致  | VERSION vs CHANGELOG 不一致 → fail，reason_code=RELEASE_DRIFT |
| trust maturity 通过   | 11 维工厂级全 true → pass                          |
| trust maturity 阻塞   | 某维度 false → fail，reason_code=FACTORY_GATE_BLOCKED |
| trust maturity release 阻塞 | release=false 即使 11 维全 true → factory=false，reason_code=FACTORY_GATE_BLOCKED |
| trust maturity blocker 阻塞 | 存在 open blocker 即使 11 维全 true → factory=false，reason_code=FACTORY_GATE_BLOCKED |
| trust boundary 合规   | import 符合 FOUNDATION-DEPS.yaml → pass            |
| trust boundary 违规   | 违反 forbidden_foundation_edges → fail              |
| trust testkit 隔离    | 生产代码无 testkitx → pass                         |
| trust testkit 违规    | pkg/ 中 import testkitx → fail，reason_code=TESTKIT_PROD_IMPORT |
| trust secret 清洁     | release/evidence 无泄露 → pass                     |
| trust secret 泄露     | 检测到 AWS key → fail，reason_code=SECRET_LEAK     |
| trust fleet 全通过    | 20 模块全成功 → exit 0                             |
| trust fleet 部分失败  | 2 模块 error → exit 1，index.json 仍生成            |
| trust fleet 投影漂移  | release=false 或 open blocker 时输入 factory=true → 输出 projection drift finding，强制 factory=false，exit 1 |

### 15.3 Given/When/Then 用例

**TC-001: import 边界违规**
Given 配置禁止业务域 import 基座层
When 扫描到 `binance` import 了 `kernel`
Then 输出违规详情（文件路径、行号），exit code 1

**TC-002: go.mod 整洁**
Given 项目 go.mod 已 tidy
When 运行 `check gomod`
Then 输出 pass，exit code 0

**TC-003: baseline 不匹配**
Given 配置要求 Go 1.23，某模块 go.mod 指定 1.22
When 运行 `check baseline --expected 1.23`
Then 输出不匹配模块列表，exit code 1

**TC-004: check all 部分失败**
Given imports 检查失败，gomod 检查通过
When 运行 `check all`
Then 输出所有子检查结果，imports 为 fail，gomod 为 pass，exit code 1

**TC-005: check all 某子检查 error**
Given imports 检查正常，baseline 检查因配置缺失报 error
When 运行 `check all`
Then imports 结果正常输出，baseline 标记为 error，继续执行其余检查，exit code 2

**TC-006: check release evidence**
Given release evidence 文件存在且 schema 合法
When 运行 `check release`
Then 输出 pass，exit code 0

**TC-007: 输出格式**
Given 检查结果包含 pass、fail 和 error
When 使用 JSON 输出
Then 输出包含 status、checks[]、summary 字段

**TC-008: secret 扫描**
Given 项目源码包含硬编码密钥（如 AWS_SECRET_ACCESS_KEY=...）
When 配置 `secret_scan.enabled=true` 且运行 `check all`
Then gitleaks 检测到泄露，输出文件路径、行号和匹配规则，exit code 1

**TC-009: l2 validate-manifest**
Given .agent/l2-capabilities.yaml 格式正确且必填字段完整
When 运行 `xlibgate l2 validate-manifest`
Then 输出 repo、layer、release_level、required_capabilities 摘要，exit code 0

**TC-010: l2 plan 覆盖完整**
Given registry 覆盖所有 required_capabilities 的契约测试
When 运行 `xlibgate l2 plan`
Then 生成 test-plan.json，含 required_contract_tests 列表，exit code 0

**TC-011: l2 check-contracts 全通过**
Given test-plan.json 含 3 项必需契约测试且 contract-test.json 全部通过
When 运行 `xlibgate l2 check-contracts`
Then 输出 passed=3, missing=0, failed=0，exit code 0

**TC-012: l2 check-evidence 完整**
Given .agent/evidence/ 下所有必需证据文件存在
When 运行 `xlibgate l2 check-evidence`
Then 输出 present 计数 > 0, missing=0，exit code 0

**TC-013: l2 release-check pass**
Given 所有硬性门禁通过且综合评分 ≥ 80
When 运行 `xlibgate l2 release-check`
Then 输出 status=pass, score ≥ 80, hard_failures=0，exit code 0

**TC-014: trust identity pass**
Given 目标仓库 README H1 == repo name、go.mod module == github.com/ZoneCNH/<repo>、public_package 存在、未声称 xlib-standard 身份
When 运行 `xlibgate trust identity --repo <repo-path>`
Then 输出 status=pass, reason_code=""，exit code 0

**TC-015: trust identity mismatch**
Given 目标仓库 README H1 为 "My Lib" 而 repo name 为 "xlibgate"
When 运行 `xlibgate trust identity --repo <repo-path>`
Then 输出 findings 含 README H1 不匹配详情，reason_code=IDENTITY_MISMATCH，exit code 1

**TC-016: trust template-residue pass**
Given 下游仓库（非 xlib-standard）不包含任何 BR-010 定义的禁止短语
When 运行 `xlibgate trust template-residue --repo <repo-path>`
Then 输出 status=pass, reason_code=""，exit code 0

**TC-017: trust template-residue fail**
Given 下游仓库 README.md 包含 "承担五类职责：Standard Source、Go Reference Template、Generator、Harness 和 Evidence Runtime"
When 运行 `xlibgate trust template-residue --repo <repo-path>`
Then 输出 findings 含文件路径、行号和匹配短语，reason_code=TEMPLATE_RESIDUE，exit code 1

**TC-018: trust release-consistency offline pass**
Given .repo-contract.yaml versions.table_version、go.mod module、VERSION 文件、CHANGELOG latest section、git tag、release/manifest/latest.json 七源版本一致
When 运行 `xlibgate trust release-consistency --offline --repo <repo-path>`
Then 输出 status=pass, reason_code=""，exit code 0

**TC-019: trust release-consistency fail**
Given VERSION 文件值为 "v1.2.0" 而 CHANGELOG latest section 为 "v1.1.0"
When 运行 `xlibgate trust release-consistency --offline --repo <repo-path>`
Then 输出 findings 含 VERSION 和 CHANGELOG 的不一致值，reason_code=RELEASE_DRIFT，exit code 1

**TC-020: trust maturity factory pass**
Given .repo-contract.yaml maturity 节中所有 11 维工厂级判定均为 true
When 运行 `xlibgate trust maturity --factory --repo <repo-path>`
Then 输出 11 维逐项判定均为 pass，overall=pass，reason_code=""，exit code 0

**TC-021: trust maturity factory fail**
Given .repo-contract.yaml maturity 节中 unit_tests_complete=false、live_integration_complete=false
When 运行 `xlibgate trust maturity --factory --repo <repo-path>`
Then 输出未满足维度列表（unit_tests_complete、live_integration_complete），reason_code=FACTORY_GATE_BLOCKED，exit code 1

**TC-021a: trust maturity release gate blocks factory**
Given .repo-contract.yaml maturity 11 维均为 true，但 release.published=false
When 运行 `xlibgate trust maturity --factory --repo <repo-path>`
Then 输出 release gate finding，factory=false，reason_code=FACTORY_GATE_BLOCKED，exit code 1

**TC-021b: trust maturity open blocker blocks factory**
Given .repo-contract.yaml maturity 11 维均为 true，且 .foundationx/blockers.json 中目标 repo 存在 status=open 的 blocker
When 运行 `xlibgate trust maturity --factory --repo <repo-path>`
Then 输出 blocker id/severity/source，factory=false，reason_code=FACTORY_GATE_BLOCKED，exit code 1

**TC-022: trust import-boundary pass**
Given FOUNDATION-DEPS.yaml 定义了 allowed_deps 和 forbidden_foundation_edges，且模块所有 import 均合规
When 运行 `xlibgate trust import-boundary --repo <repo-path> --deps FOUNDATION-DEPS.yaml`
Then 输出 status=pass, reason_code=""，exit code 0

**TC-023: trust import-boundary fail**
Given FOUNDATION-DEPS.yaml 禁止 binance import kernel，而 pkg/trade.go 第 5 行 import 了 kernel
When 运行 `xlibgate trust import-boundary --repo <repo-path> --deps FOUNDATION-DEPS.yaml`
Then 输出 findings 含文件路径 pkg/trade.go、行号 5、违规 import 路径，reason_code=IMPORT_BOUNDARY_VIOLATION，exit code 1

**TC-024: trust testkit-prod-import pass**
Given 模块生产代码中无 testkitx import，但 *_test.go 文件中有 testkitx import
When 运行 `xlibgate trust testkit-prod-import --repo <repo-path>`
Then *_test.go 中的 testkitx import 不触发违规，status=pass，exit code 0

**TC-025: trust testkit-prod-import fail**
Given pkg/engine.go 第 8 行 import 了 github.com/ZoneCNH/testkitx
When 运行 `xlibgate trust testkit-prod-import --repo <repo-path>`
Then 输出 findings 含 pkg/engine.go、行号 8，reason_code=TESTKIT_PROD_IMPORT，exit code 1

**TC-026: trust secret-redaction pass**
Given release/evidence/ 下所有文档不含 secrets/API keys/私有端点/DSN with credentials
When 运行 `xlibgate trust secret-redaction --repo <repo-path> --path release/evidence`
Then 输出 status=pass, reason_code=""，exit code 0

**TC-027: trust secret-redaction fail**
Given release/evidence/deploy-log.md 包含 AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
When 运行 `xlibgate trust secret-redaction --repo <repo-path> --path release/evidence`
Then 输出 findings 含文件路径、行号和脱敏后的匹配类型（不输出密钥原文），reason_code=SECRET_LEAK，exit code 1

**TC-028: trust fleet-status pass**
Given --repos-root 下精确有 20 个 Foundation 模块且全部扫描成功
When 运行 `xlibgate trust fleet-status --repos-root <foundation-root> --output .foundationx/status/index.json`
Then 生成 index.json 含 20 模块各自身份/发布/成熟度/边界/阻断项/证据索引状态，exit code 0

**TC-029: trust fleet-status partial fail**
Given --repos-root 下有 20 个模块，其中 2 个缺少 .repo-contract.yaml 扫描失败
When 运行 `xlibgate trust fleet-status --repos-root <foundation-root> --output .foundationx/status/index.json`
Then 生成 index.json（含 2 个 status=error 模块），exit code 1

**TC-030: trust fleet-status projection drift**
Given --repos-root 下某模块 release=false 或存在 open blocker，但输入状态声明 factory=true
When 运行 `xlibgate trust fleet-status --repos-root <foundation-root> --output .foundationx/status/index.json`
Then 生成 index.json 时该模块 factory=false，findings 含 projection drift 的源字段和值，reason_code=FACTORY_GATE_BLOCKED，exit code 1

### 15.4 Benchmark

| 场景                     | 目标    |
| ------------------------ | ------- |
| 全量门禁（50 模块）      | < 30s   |
| import 扫描（50 模块）   | < 10s   |
| go.mod 检查（50 模块）   | < 5s    |
| baseline 检查（50 模块） | < 5s    |
| JSON 报告生成            | < 100ms |

### 15.5 集成测试

| 场景             | 验证点                                             |
| ---------------- | -------------------------------------------------- |
| 完整 CI 流程     | `check all` → 所有子检查执行 → 汇总报告            |
| 自检             | `xlibgate check all --config xlibgate.yaml` → pass |
| CI artifact 输出 | `--artifact result.json` → 文件写入且格式正确      |

---

## 16. 性能预算

| 操作                     | 目标    | 测量方式       |
| ------------------------ | ------- | -------------- |
| 全量门禁（50 模块）      | < 30s   | benchmark test |
| import 扫描（50 模块）   | < 10s   | benchmark test |
| go.mod 检查（50 模块）   | < 5s    | benchmark test |
| baseline 检查（50 模块） | < 5s    | benchmark test |
| JSON 报告生成            | < 100ms | benchmark test |
| 内存占用                 | < 100MB | profiling      |
| trust identity 检查       | < 2s    | benchmark test |
| trust template-residue 扫描（50 模块） | < 15s | benchmark test |
| trust release-consistency 检查 | < 3s | benchmark test |
| trust maturity 检查       | < 1s    | benchmark test |
| trust import-boundary 检查 | < 10s  | benchmark test |
| trust testkit-prod-import 检查 | < 5s | benchmark test |
| trust secret-redaction 扫描 | < 10s | benchmark test |
| trust fleet-status 聚合（20 模块） | < 60s | benchmark test |

---

## 17. 可观测性

> xlibgate 是短生命周期 CLI 工具，不集成运行时 metrics exporter 或 tracing exporter。以下日志事件作为可观测性的主要载体，覆盖 Constitution §6.2 的"操作耗时"和"错误计数"需求（通过结构化日志中的 `duration_ms` 和 `status` 字段由 CI 日志系统聚合）。CLI 短生命周期工具无需健康检查端点（exit code 0/1/2 即为健康信号）。

### 17.1 Logging（主要可观测载体）

| 类型   | 名称                       | 说明                                     |
| ------ | -------------------------- | ---------------------------------------- |
| log    | `xlibgate.check.started`   | info，检查开始，含 check name            |
| log    | `xlibgate.check.completed` | info，检查完成，含 status 和 duration_ms |
| log    | `xlibgate.check.failed`    | warn，检查失败，含 violation 详情        |
| log    | `xlibgate.check.error`     | error，检查出错，含 error message        |
| log    | `xlibgate.config.loaded`   | info，配置加载完成，含文件路径           |

### 17.2 Metrics（CI 日志聚合等效）

CLI 工具不启动 HTTP metrics 端点。以下指标通过 CI 系统对结构化日志的解析实现等效聚合：

| 指标名                                        | 类型      | 说明                                            | 来源日志                                         |
| --------------------------------------------- | --------- | ----------------------------------------------- | ------------------------------------------------ |
| `foundationx_xlibgate_check_duration_seconds` | histogram | 各子检查耗时分布，label: `check_name`, `status` | `xlibgate.check.completed` 的 `duration_ms` 字段 |
| `foundationx_xlibgate_check_total`            | counter   | 检查执行总次数，label: `check_name`, `status`   | `xlibgate.check.completed` 的事件计数            |
| `foundationx_xlibgate_check_errors_total`     | counter   | 检查错误次数，label: `check_name`               | `xlibgate.check.error` 的事件计数                |

### 17.3 Tracing

CLI 短生命周期工具不启动 tracing exporter。执行流程通过父子日志事件的关联字段（`check_name`、`timestamp`）重建调用链，等效于 span 语义：

| 逻辑 Span                    | 对应日志                                               | 说明                     |
| ---------------------------- | ------------------------------------------------------ | ------------------------ |
| `xlibgate.check_all`         | `check.started` + `check.completed` (name=all)         | 全量门禁根 span          |
| `xlibgate.check_imports`     | `check.started` + `check.completed` (name=imports)     | import 扫描子 span       |
| `xlibgate.check_gomod`       | `check.started` + `check.completed` (name=gomod)       | gomod 检查子 span        |
| `xlibgate.check_baseline`    | `check.started` + `check.completed` (name=baseline)    | baseline 检查子 span     |
| `xlibgate.check_release`     | `check.started` + `check.completed` (name=release)     | release evidence 子 span |
| `xlibgate.check_secret_scan` | `check.started` + `check.completed` (name=secret_scan) | secret 扫描子 span       |
| `xlibgate.trust_identity` | `trust.started` + `trust.completed` (name=identity) | 身份对齐检查 span |
| `xlibgate.trust_template` | `trust.started` + `trust.completed` (name=template-residue) | 模板残留检查 span |
| `xlibgate.trust_release` | `trust.started` + `trust.completed` (name=release-consistency) | 发布一致性检查 span |
| `xlibgate.trust_maturity` | `trust.started` + `trust.completed` (name=maturity) | 成熟度检查 span |
| `xlibgate.trust_boundary` | `trust.started` + `trust.completed` (name=import-boundary) | import 边界检查 span |
| `xlibgate.trust_testkit` | `trust.started` + `trust.completed` (name=testkit-prod-import) | testkitx 隔离检查 span |
| `xlibgate.trust_secret` | `trust.started` + `trust.completed` (name=secret-redaction) | secret 脱敏检查 span |
| `xlibgate.trust_fleet` | `trust.started` + `trust.completed` (name=fleet-status) | 舰队状态聚合 span |

---

## 18. 安全

| 要求                       | 实现方式                                                                                                                                                                                |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| secret 扫描                | 集成 `gitleaks`，扫描所有源文件                                                                                                                                                         |
| 配置文件不泄露敏感数据     | 配置文件只包含规则定义，不含密钥                                                                                                                                                        |
| 错误消息不泄露文件内容     | 错误消息只包含文件路径和行号，不包含源代码                                                                                                                                              |
| CLI 参数和配置文件输入校验 | 使用 Go `flag` 库类型校验 + YAML schema 校验；配置加载时对 `baseline.go_version`（semver）、`imports.forbidden[].source`（非空字符串）、`release.require`（已知条件枚举）进行合法性检查 |

---

## 19. CI 门禁

### 19.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |

### 19.2 xlibgate 专属 Gate

| Gate                     | 命令                                        | 阻塞条件              |                  |                    |                |
| ------------------------ | ------------------------------------------- | --------------------- |                  |                    |                |
| 自检                     | `xlibgate check all --config xlibgate.yaml` | 自身门禁不通过        |                  |                    |                |
| 不依赖 Foundation 运行时 | `go list -deps ./... \                      | grep "ZoneCNH/kernel\ | ZoneCNH/configx\ | ZoneCNH/observex"` | 依赖运行时模块 |

### 19.3 Trust Alignment Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 身份对齐 | `xlibgate trust identity --repo .` | IDENTITY_MISMATCH 或 CONTRACT_PARSE_ERROR |
| 模板残留 | `xlibgate trust template-residue --repo .` | 非 xlib-standard 仓库命中禁止短语 |
| 发布一致性 | `xlibgate trust release-consistency --offline --repo .` | RELEASE_DRIFT |
| 成熟度工厂 | `xlibgate trust maturity --factory --repo .` | FACTORY_GATE_BLOCKED（11 维不满足、release=false、open blocker） |
| import 边界 | `xlibgate trust import-boundary --repo . --deps FOUNDATION-DEPS.yaml` | IMPORT_BOUNDARY_VIOLATION |
| testkitx 隔离 | `xlibgate trust testkit-prod-import --repo .` | TESTKIT_PROD_IMPORT |
| secret 脱敏 | `xlibgate trust secret-redaction --repo . --path release/evidence` | SECRET_LEAK 或 PRIVATE_ENDPOINT_LEAK |
| 舰队状态 | `xlibgate trust fleet-status --repos-root .. --output .foundationx/status/index.json` | 任一模块 error、projection drift、release=false=>factory=true、open blocker=>factory=true |

---

## 20. 升级兼容性

| 变更类型 | 版本升级 | 迁移方式 |
|----------|----------|----------|
| CLI 命令结构变更（子命令增删） | **minor** | 更新 CI 脚本中的命令引用；新增子命令向后兼容，删除子命令在发布说明中标注替代方案 |
| exit code 语义变更 | **major** | 更新所有 CI 脚本中依赖 exit code 的条件判断；在发布说明中提供新旧 exit code 对照表和升级检查清单 |
| JSON 输出格式变更（字段增删） | **minor** | 新增字段向后兼容（旧解析器忽略未知字段）；删除字段在 MINOR 版本中标记 deprecated，MAJOR 版本中移除 |
| JSON 输出格式变更（字段重命名/删除） | **major** | 更新 CI artifact 解析脚本中的字段名；提供过渡期兼容映射（保留旧字段名作为 alias 至少一个 MAJOR 周期） |
| 配置 schema 变更（新增可选字段） | **minor** | 无需迁移；旧配置文件继续有效，新增字段使用默认值 |
| 配置 schema 变更（新增必填字段） | **minor**（带默认值） | 提供字段默认值避免旧配置文件报错；如无安全默认值，在 CHANGELOG 中标注为"soft required"并给出配置示例 |
| 配置 schema 变更（字段删除/重命名） | **major** | 在至少一个 MINOR 版本中同时支持新旧字段名；旧字段标记 deprecated；MAJOR 版本移除旧字段并提供自动迁移脚本 |
| 新增检查子命令 | **minor** | `check all` 默认不自动包含新增子命令（避免破坏现有 CI 预期）；在发布说明中引导用户更新 CI 配置以启用新检查 |

---

## 21. 发布 DoD

- [ ] CLI 帮助文档完整（`--help` 输出所有子命令和参数）
- [ ] 所有 check 子命令有使用示例
- [ ] exit code 文档化
- [ ] JSON 输出格式文档化（含示例）
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、CLI 参考
- [ ] 单元测试覆盖率 >= 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 自检通过（`xlibgate check all`）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试
- [ ] trust 子命令全部实现并通过 TC-014~TC-029
- [ ] trust 统一 JSON 输出格式符合 §9.3.1 schema
- [ ] trust fleet-status 可对 20 模块基金会产生正确聚合

---

## 22. 待解决问题

### Blocking（阻塞开发）

无。

### Non-blocking（不阻塞开发）

| ID     | 问题                                                            | 状态   | 负责人   |
| ------ | --------------------------------------------------------------- | ------ | -------- |
| OQ-001 | 是否需要支持增量扫描（只扫描变更文件）？当前为全量扫描。        | 待评估 | -        |
| OQ-002 | 是否需要支持多配置文件合并（如项目级 + 组织级配置）？           | 待评估 | -        |
| OQ-003 | 是否需要支持基础插件机制（用户定义的门禁规则脚本/二进制调用）？ | 待评估 | -        |

### Future（未来考虑）

| ID     | 问题                                                         | 状态   | 负责人   |
| ------ | ------------------------------------------------------------ | ------ | -------- |
| OQ-004 | 是否需要支持高级插件能力（如插件市场、动态加载、沙箱隔离）？ | 待评估 | -        |
| OQ-005 | import 边界规则是否需要支持正则表达式匹配？                  | 待评估 | -        |
| OQ-006 | release evidence 是否需要支持从远程 URL 获取？               | 待评估 | -        |


## 23. 变更历史

| 日期       | 版本   | 变更内容                                                                                                                                                                                                                                                                    | 作者    |
| ---------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本                                                                                                                                                                                                                                                                    | ZoneCNH |
| 2026-06-12 | v1.0.1 | 结构评分修复：BR 逐条"违反时"、Open Questions 分类编号、Observability 补充 Metrics/Tracing、Edge Cases 补充重试、Upgrade Compatibility 补迁移步骤、Security 补输入校验、Testing 补工具声明、Dependencies 补直接/间接依赖表、FR-005 显式枚举 secret_scan 子检查、新增 TC-008 | ZoneCNH |
| 2026-06-12 | v1.0.2 | 范围对齐（R1/R2 修复）：§2 Summary + §4 Goals 新增 `l2` 子命令组、新增 FR-007~FR-011（l2 validate-manifest / plan / check-contracts / check-evidence / release-check）                                                                                                      | ZoneCNH |
| 2026-06-12 | v1.0.2 | Status: Draft → Approved（Spec 四源评分 Claude 98 + rules 100，0 红线；Codex/Copilot 环境缺失由维护者 override）                                                                                                                                                            | ZoneCNH |
| 2026-06-14 | v1.1.0 | v2 Trust Alignment 检查：新增 FR-012~FR-019（identity / template-residue / release-consistency / maturity / import-boundary / testkit-prod-import / secret-redaction / fleet-status）；新增 BR-010（禁止模板身份短语）；统一定义 per-check JSON 输出格式（含 reason_code、evidence 字段） | ZoneCNH |
| 2026-06-14 | v1.1.1 | Trust Alignment 补充：新增 TC-014~TC-029（16 条验收标准，每 FR 2 条）；新增 6 个 trust 错误码；Edge Cases 补充 10 个 trust 边界场景；§16.2 单元测试补充 16 个 trust 测试场景 | ZoneCNH |
| 2026-06-14 | v1.1.2 | Trust Hardening：明确 projection drift、blocker-aware factory gate、release=false=>factory=false、open blocker=>factory=false；保持 exit code 0/1/2 与既有 reason_code 稳定 | ZoneCNH |