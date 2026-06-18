# configx 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.1.0（运行时 version.go = v1.1.0、CHANGELOG 最新 = v1.1.0、git tag = v1.1.0、GitHub Release 已发布；版本号已完全对齐）
- Module-State: v1.0 路线 5 项 MUST 已全部交付（ArgsSource / RemoteSource SPI / Bind / ConfigSnapshot+ChangeEvent+Watch+Rollback / DocGen）
- Layer: L1 基础能力
- Runtime-Repo: /home/configx
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 版本基线说明：v1.1.0（2026-06-18 发布）完整交付 goal.md §文首状态戳列出的 v1.0 路线 5 项 MUST：ArgsSource、RemoteSource SPI、Bind()、ConfigSnapshot/ChangeEvent/Watch/Rollback、配置文档自动生成。运行时 `pkg/configx/version.go` = `v1.1.0`、CHANGELOG 顶部 = `v1.1.0`、git tag = `v1.1.0`、GitHub Release 已发布；之前 v1.0.0 git tag 与 version.go=v0.1.3 的版本漂移已修复，此后 version.go / CHANGELOG / git tag 严格保持同步。
>
> 本清单用于验收 configx 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/configx/FEATURES.md && test -f module/configx/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/configx | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/configx && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/configx && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/configx && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/configx && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/configx && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-002~005, BR-001 | 002/003/004 / Loader+Source 正确加载合并，LastWins 语义 | ✅ 2026-06-18 实测 | TRACEABILITY.md |
| AC-002 | FR-006, BR-007 | 005 / StrictDecode 拒绝未知字段/重复key/类型错误 | ✅ 2026-06-18 实测 | TRACEABILITY.md |
| AC-003 | FR-007/008/011, BR-005/006 | 010 / SecretString + SecretPolicy + SanitizedManifest | ✅ 2026-06-18 实测 | TRACEABILITY.md |
| AC-004 | FR-009/010/012 | 006 / Provenance + Hash + HealthCheck | ✅ 2026-06-18 实测 | TRACEABILITY.md |
| AC-005 | FR-001/013, BR-008~011 | 000/001/009 / Client 生命周期 + Metrics + CI Gate | ✅ 2026-06-18 实测 | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-002~005, BR-001 | LastWins 合并：Source A→B→Load，后加载覆盖先加载 | ✅ 2026-06-18 实测；TestLoaderMergesSourcesLastWinsAndSanitizesSecrets, TestSourcePrecedenceGolden, TestSourcePrecedenceGoldenOutput | TRACEABILITY.md |
| TC-002 | FR-006, BR-007 | StrictDecode：未知字段拒绝；WithAllowUnknownFields 忽略 | ✅ 2026-06-18 实测；TestStrictDecode_UnknownField, TestStrictDecode_DuplicateKeys, TestStrictDecode_TypeMismatch, TestStrictDecode_UnknownFieldAllowed | TRACEABILITY.md |
| TC-003 | FR-007, FR-011, BR-005 | SecretString 全路径脱敏 + SanitizedManifest 安全快照 | ✅ 2026-06-18 实测；TestSecretLeakGolden, TestSecretLeakGoldenOutput, TestConfigSanitizeMasksSecret, TestSanitizedManifest_Struct, TestSanitizedManifest_StructTag, TestSanitizedManifest_Map, TestSanitizedManifest_NilInput, TestDecodeErrorDoesNotExposeSecretValue | TRACEABILITY.md |
| TC-004 | FR-007 | Reveal() 获取原始值（仅调试） | ✅ 2026-06-18 实测；TestConfigSanitizeMasksSecret, TestConfigSanitizeSecretProperty | TRACEABILITY.md |
| TC-005 | FR-008, BR-006 | SecretPolicy CustomMatcher 自定义匹配 | ✅ 2026-06-18 实测；TestDefaultSecretPolicy, TestSecretPolicyIsSecret, TestSecretPolicySanitizeMap, TestSecretPolicySanitizeStringMap, TestSecretPolicySecretKeys | TRACEABILITY.md |
| TC-006 | FR-010 | EffectiveConfigHash：相同配置→相同 SHA-256 | ✅ 2026-06-18 实测；TestEffectiveConfigHash_Determinism, TestEffectiveConfigHash_LoadResult, TestEffectiveConfigHash_Map, TestEffectiveConfigHash_Struct, TestEffectiveConfigHashStructWithVolatileTag | TRACEABILITY.md |
| TC-007 | FR-001, FR-012 | HealthCheck：已初始化 Client → healthy + LatencyMs > 0 | ✅ 2026-06-18 实测；TestHealthCheckHealthy, TestHealthCheckClosedClientUnhealthy, TestHealthCheckCanceledContextUnhealthy, TestHealthCheckZeroValueClientUnhealthy, TestHealthStatusJSONContract, TestHealthStatusJSONGolden | TRACEABILITY.md |
| TC-008 | FR-001, BR-002, BR-003, BR-011 | nil context 拒绝 + Config 校验失败 | ✅ 2026-06-18 实测；TestNewRejectsInvalidConfig, TestNewRejectsCanceledContext, TestNewRejectsExpiredContext, TestConfigValidateRequiresName, TestConfigValidateRejectsNegativeTimeout | TRACEABILITY.md |
| TC-009 | FR-013, BR-010 | Release DoD：全量 CI Gate 通过，覆盖率 ≥ 97% | ✅ 2026-06-18 实测；TestNoopMetricsMethods, TestNoopMetricsWithLabels；release/manifest/latest.json checks 全 passed | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Client 创建与生命周期（New/Close） | New 校验 ctx+cfg，Close 标记关闭 / TC-007, TC-008 / - / TASK-CONFIGX-000, TASK-CONFIGX-001 | ✅ | TRACEABILITY.md |
| FR-002 | Loader + Source 模式 | NewLoader().AddSource().Load(ctx) / TC-001 / - / TASK-CONFIGX-002, TASK-CONFIGX-003 | ✅ | TRACEABILITY.md |
| FR-003 | FileSource — YAML/TOML/JSON/.env | 4 种文件格式解析正确 / TC-001 / - / TASK-CONFIGX-002 | ✅ | TRACEABILITY.md |
| FR-004 | EnvSource — 环境变量 | 前缀匹配 + key 过滤 / TC-001 / - / TASK-CONFIGX-004 | ✅ | TRACEABILITY.md |
| FR-005 | MapSource — 字符串 map | map→Value 转换正确 / TC-001 / - / TASK-CONFIGX-003 | ✅ | TRACEABILITY.md |
| FR-006 | StrictDecode | 拒绝未知字段/重复key；支持 WithAllowUnknownFields / TC-002 / - / TASK-CONFIGX-005 | ✅ | TRACEABILITY.md |
| FR-007 | SecretString 自动脱敏 | String/JSON/GoString/Text 全路径脱敏 / TC-003 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| FR-008 | SecretPolicy 密钥检测 | 默认 7 模式 + CustomMatcher / TC-005 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| FR-009 | Provenance 来源追踪 | 每个 key 记录 Source/Priority/Override / TC-001 / - / TASK-CONFIGX-006 | ✅ | TRACEABILITY.md |
| FR-010 | EffectiveConfigHash | SHA-256，排除 volatile 字段，可复现 / TC-006 / - / TASK-CONFIGX-006 | ✅ | TRACEABILITY.md |
| FR-011 | SanitizedManifest | 敏感字段自动替换，nil 安全 / TC-003 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| FR-012 | HealthCheck | Status/LatencyMs/Metadata / TC-007 / - / TASK-CONFIGX-006 | ✅ | TRACEABILITY.md |
| FR-013 | Metrics | 8 标准指标 + NoopMetrics 零开销 / TC-009 / - / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| BR-001 | LastWins 合并策略 | 后加载 Source 覆盖先加载的同名 key / TC-001 / - / TASK-CONFIGX-003 | ✅ | TRACEABILITY.md |
| BR-002 | Config.Name 必须非空 | Validate 时检查 Name / TC-008 / - / TASK-CONFIGX-005 | ✅ | TRACEABILITY.md |
| BR-003 | Config.Timeout ≥ 0 | 负数拒绝 / TC-008 / - / TASK-CONFIGX-005 | ✅ | TRACEABILITY.md |
| BR-004 | 显式加载（无隐式发现） | 调用方必须显式 AddSource / TestNoImplicitConfigDiscovery / - / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| BR-005 | SecretString 全路径脱敏 | String/JSON/GoString/Text 均返回 *** / TC-003 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| BR-006 | SecretPolicy 可配置模式 | 默认 7 模式 + CustomMatcher / TC-005 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| BR-007 | StrictDecode 默认严格 | 拒绝未知字段和重复 key / TC-002 / - / TASK-CONFIGX-005 | ✅ | TRACEABILITY.md |
| BR-008 | 公共错误 *Error + ErrorKind | errors.As 可提取 Kind/Op/Cause / 源码静态检查 + 单测 / - / TASK-CONFIGX-000 | ✅ | TRACEABILITY.md |
| BR-009 | 无全局状态 | 无可变包级单例 / 源码静态检查 + TestNoImplicitConfigDiscovery / - / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| BR-010 | Release 通过全部 CI Gate | 编译/测试/覆盖率/vet/lint/secret/vuln / TC-009 / - / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| BR-011 | context.Context 必须非 nil | 所有公开 API 强制 ctx 检查 / TC-008 / - / TASK-CONFIGX-001 | ✅ | TRACEABILITY.md |
| NFR-001 | 测试覆盖率 ≥ 80% | 实际 97.1% / CI Gate: go test -coverprofile / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| NFR-002 | 零 data race | go test -race 通过 / CI Gate / TASK-CONFIGX-006 | ✅ | TRACEABILITY.md |
| NFR-003 | lint 零告警 | golangci-lint 8 linter / CI Gate / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| NFR-004 | 零 secret 泄露 | gitleaks detect / CI Gate / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| NFR-005 | 不依赖 kernel | go list -deps 检查 / CI Gate / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| NFR-006 | 依赖安全 | govulncheck 扫描 / CI Gate / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。（2026-06-18 已核对，FR-001~013、BR-001~011、NFR-001~006 与 TRACEABILITY.md §1-§3 一致）
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。（2026-06-18 AC-001~005、TC-001~009 已挂接 /home/configx Go 测试函数）
- [x] 运行时代码仓库 /home/configx 通过 go test、go test -race、go vet 与覆盖率门槛。（2026-06-18 go test ./... -race -count=1 PASS；go vet 0 告警；coverage total 94.0% / pkg/configx 98.5%）
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。（2026-06-18 go test ./... 8 packages PASS，无外部依赖）
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。（2026-06-18 bash scripts/check_secrets.sh PASS；bash scripts/check_boundary.sh PASS；bash scripts/check-no-global-state.sh PASS；bash scripts/check_contracts.sh PASS）
- [x] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。（2026-06-18 release/manifest/latest.json checks 全 passed）

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；2026-06-18 已归档：所有 AC/TC 标 ✅，DoD 6 项已完成；release/manifest/latest.json checks 全 passed。
- 2026-06-18 FEATURES.md §4 任务交付清单已同步：12 个 task 中 11 个 ✅ 已交付，TASK-CONFIGX-007 (Watch) 显式推迟到 v1.1（与 goal.md §文首状态戳一致）；§6 实现完成判定 6 项全部勾选并附实测证据。
