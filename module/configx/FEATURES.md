# configx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.1.0（运行时 version.go = v1.1.0、CHANGELOG 最新 = v1.1.0、git tag = v1.1.0、GitHub Release 已发布）
- Module-State: v1.0 路线 5 项 MUST 已全部交付（ArgsSource / RemoteSource SPI / Bind / ConfigSnapshot+ChangeEvent+Watch+Rollback / DocGen），详见 ACCEPTANCE.md 版本基线说明
- Layer: L1 基础能力
- Runtime-Repo: /home/configx
- Source: goal.md, SPEC.md, DESIGN.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 configx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 配置加载、覆盖、校验、安全红线（热更新/快照属 v1.1 路线，见 goal.md） |
| 文档目录 | module/configx |
| 运行时代码目录 | /home/configx |
| Go 基线 | 1.23 |
| 允许依赖 | stdlib + `gopkg.in/yaml.v3` + `github.com/pelletier/go-toml/v2`（实测 go.mod；不依赖 kernel，见 NFR-005） |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖 kernel、observex、resiliencx、schedulex、testkitx 或上层业务域 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
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

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
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

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-CONFIGX-000 | 项目骨架（go.mod / doc.go / errors.go） | module/configx/tasks/TASK-CONFIGX-000.md | ✅ 2026-06-18 已交付（实现演进为 ErrorKind 枚举 + *Error，见 SPEC §9.5） | tasks/TASK-CONFIGX-000.md |
| TASK-CONFIGX-001 | 接口定义（Client / Config / Option） | module/configx/tasks/TASK-CONFIGX-001.md | ✅ 2026-06-18 已交付（Client + Loader + Source 模式，见 SPEC §8） | tasks/TASK-CONFIGX-001.md |
| TASK-CONFIGX-002 | 配置加载（YAML/TOML/JSON/.env Source） | module/configx/tasks/TASK-CONFIGX-002.md | ✅ 2026-06-18 已交付（FR-003，TC-001 实测） | tasks/TASK-CONFIGX-002.md |
| TASK-CONFIGX-003 | LastWins 合并策略 | module/configx/tasks/TASK-CONFIGX-003.md | ✅ 2026-06-18 已交付（BR-001，TC-001 实测） | tasks/TASK-CONFIGX-003.md |
| TASK-CONFIGX-004 | EnvSource 环境变量覆盖 | module/configx/tasks/TASK-CONFIGX-004.md | ✅ 2026-06-18 已交付（FR-004，TC-001 实测） | tasks/TASK-CONFIGX-004.md |
| TASK-CONFIGX-005 | StrictDecode + Validate | module/configx/tasks/TASK-CONFIGX-005.md | ✅ 2026-06-18 已交付（FR-006/BR-002/BR-003/BR-007，TC-002/TC-008 实测） | tasks/TASK-CONFIGX-005.md |
| TASK-CONFIGX-006 | Provenance / Hash / HealthCheck | module/configx/tasks/TASK-CONFIGX-006.md | ✅ 2026-06-18 已交付（FR-009/010/012，TC-006/TC-007 实测） | tasks/TASK-CONFIGX-006.md |
| TASK-CONFIGX-007 | Watch 文件监控（可选） | module/configx/tasks/TASK-CONFIGX-007.md | ⏸️ 推迟到 v1.1（goal.md §文首状态戳明确未交付） | tasks/TASK-CONFIGX-007.md |
| TASK-CONFIGX-009 | 文档 + Release DoD | module/configx/tasks/TASK-CONFIGX-009.md | ✅ 2026-06-18 已交付（BR-004/009/010，TC-009 + release/manifest/latest.json checks 全 passed） | tasks/TASK-CONFIGX-009.md |
| TASK-CONFIGX-010 | SecretString / SecretPolicy / SanitizedManifest | module/configx/tasks/TASK-CONFIGX-010.md | ✅ 2026-06-18 已交付（FR-007/008/011, BR-005/006，TC-003/TC-005 实测） | tasks/TASK-CONFIGX-010.md |
| TASK-CONFIGX-011 | FR-006 through FR-010 coverage | module/configx/tasks/TASK-CONFIGX-011.md | ✅ 2026-06-18 已交付（FR-006~010 全部 ✅，pkg/configx 98.5% 覆盖率） | tasks/TASK-CONFIGX-011.md |
| TASK-CONFIGX-012 | FR-011 / FR-012 / FR-013 coverage | module/configx/tasks/TASK-CONFIGX-012.md | ✅ 2026-06-18 已交付（FR-011~013 全部 ✅，TC-003/TC-007/TC-009 实测） | tasks/TASK-CONFIGX-012.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/configx/goal.md |
| SPEC.md | 存在 | module/configx/SPEC.md |
| DESIGN.md | 存在 | module/configx/DESIGN.md |
| TRACEABILITY.md | 存在 | module/configx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/configx/IMPLEMENTATION-PLAN.md |
| tasks/ | 12 个 Markdown 文件 | module/configx/tasks |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。（2026-06-18 FR-001~013 全部 ✅，TRACEABILITY.md §1 实测）
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。（2026-06-18 BR-001~011、NFR-001~006 全部 ✅，TRACEABILITY.md §2/§3 实测）
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。（2026-06-18 §4 任务交付清单已挂接 FR/BR/TC，TASK-CONFIGX-007 显式标记推迟 v1.1）
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。（2026-06-18 `go list -deps` 无 kernel；`scripts/check_boundary.sh` PASS）
- [x] 运行时代码仓库 /home/configx 的 lint、typecheck、test、race、coverage 验证证据已归档。（2026-06-18 go test ./... -race -count=1 PASS；vet 0 告警；coverage total 94.0% / pkg/configx 98.5%）
- [x] 发布说明、版本标签与本目录登记状态一致。（2026-06-18 release/manifest/latest.json checks 全 passed；STATUS.md / README.md / ARCHITECTURE.md 已对齐 v1.0.0 (tag) / v0.1.4 (runtime)）
