# configx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.4（运行时 version.go 实测 v0.1.3、CHANGELOG 最新 v0.1.4；git tag v1.0.0 已存在但 version.go 尚未对齐，见 ACCEPTANCE.md 版本基线说明）
- Module-State: 显式加载基线已交付（对应 git tag v1.0.0）；goal.md §2 的 v1.0 完整 MUST（热更新 / RemoteSource SPI / bind / ConfigSnapshot）未交付，划入 v1.1 路线
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
| BR-004 | 显式加载（无隐式发现） | 调用方必须显式 AddSource / CI Gate: NoGlobalStateGate / - / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
| BR-005 | SecretString 全路径脱敏 | String/JSON/GoString/Text 均返回 *** / TC-003 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| BR-006 | SecretPolicy 可配置模式 | 默认 7 模式 + CustomMatcher / TC-005 / - / TASK-CONFIGX-010 | ✅ | TRACEABILITY.md |
| BR-007 | StrictDecode 默认严格 | 拒绝未知字段和重复 key / TC-002 / - / TASK-CONFIGX-005 | ✅ | TRACEABILITY.md |
| BR-008 | 公共错误 configx: 前缀 | 所有错误变量使用 configx: 前缀 / CI Gate: go vet / - / TASK-CONFIGX-000 | ✅ | TRACEABILITY.md |
| BR-009 | 无全局状态 | 无进程级 config singleton / CI Gate: NoGlobalStateGate / - / TASK-CONFIGX-009 | ✅ | TRACEABILITY.md |
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
| TASK-CONFIGX-000 | TASK-CONFIGX-000 | module/configx/tasks/TASK-CONFIGX-000.md | - | tasks/TASK-CONFIGX-000.md |
| TASK-CONFIGX-001 | TASK-CONFIGX-001 | module/configx/tasks/TASK-CONFIGX-001.md | - | tasks/TASK-CONFIGX-001.md |
| TASK-CONFIGX-002 | TASK-CONFIGX-002 | module/configx/tasks/TASK-CONFIGX-002.md | - | tasks/TASK-CONFIGX-002.md |
| TASK-CONFIGX-003 | TASK-CONFIGX-003 | module/configx/tasks/TASK-CONFIGX-003.md | - | tasks/TASK-CONFIGX-003.md |
| TASK-CONFIGX-004 | TASK-CONFIGX-004 | module/configx/tasks/TASK-CONFIGX-004.md | - | tasks/TASK-CONFIGX-004.md |
| TASK-CONFIGX-005 | TASK-CONFIGX-005 | module/configx/tasks/TASK-CONFIGX-005.md | - | tasks/TASK-CONFIGX-005.md |
| TASK-CONFIGX-006 | TASK-CONFIGX-006 | module/configx/tasks/TASK-CONFIGX-006.md | - | tasks/TASK-CONFIGX-006.md |
| TASK-CONFIGX-007 | TASK-CONFIGX-007 | module/configx/tasks/TASK-CONFIGX-007.md | - | tasks/TASK-CONFIGX-007.md |
| TASK-CONFIGX-009 | TASK-CONFIGX-009 | module/configx/tasks/TASK-CONFIGX-009.md | - | tasks/TASK-CONFIGX-009.md |
| TASK-CONFIGX-010 | TASK-CONFIGX-010 | module/configx/tasks/TASK-CONFIGX-010.md | - | tasks/TASK-CONFIGX-010.md |
| TASK-CONFIGX-011 | TASK-CONFIGX-011: FR-006 through FR-010 | module/configx/tasks/TASK-CONFIGX-011.md | - | tasks/TASK-CONFIGX-011.md |
| TASK-CONFIGX-012 | TASK-CONFIGX-012 | module/configx/tasks/TASK-CONFIGX-012.md | - | tasks/TASK-CONFIGX-012.md |

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

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/configx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
