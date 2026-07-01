# xlib_harness

## 1. 模块定位
xlib_harness 是 Foundation 的**模块生成器与门禁执行器**——从标准模板生成新模块骨架（generate），并对已有模块执行机器化合规检查（check）。与 xlibgate 互补：xlibgate 检查编译/依赖/发布，xlib_harness 检查规格结构/模板/格式。Status=Approved（SPEC v1.0.0），模块版本 v0.1.1（Acceptance-Baseline `/home/workspace/xlib-harness@335eef9`），Layer=基座·模块生成器与门禁执行器（L1 执行器）。从 xlib_standard 拆分而来，读取其模板/schema 作为输入（只读文件，非 import 依赖）。

## 2. 生产职责
- FR-001 generate-module：从 xlib_standard 模板生成完整模块骨架（SPEC.md/TRACEABILITY.md/goal.md/tasks/IMPLEMENTATION-PLAN.md）
- FR-002 spec-lint：检查 23 节结构完整性、FR WHEN/THEN 格式、AC 可验证性
- FR-003 boundary-check：验证允许/禁止依赖、production-import-testkitx 禁止、stdlib-only gate
- FR-004 template-validate：验证 xlib_standard 模板自举（模板自身符合模板定义）
- FR-005 format-check：检查 Markdown 结构、链接有效性、表格对齐
- FR-006 traceability-gate：FR → AC → TC 链路全闭合

## 3. 边界定义
- generate 在 5 秒内完成骨架生成（BR-001）
- check 不得修改被检模块的任何文件（BR-002）
- check 失败退出码必须非零（BR-003）
- 允许只读 xlib_standard 模板；禁止 `github.com/ZoneCNH/xlib-standard` Go import/module dependency（NFR-004）
- 禁止依赖 observex/configx/resiliencx/schedulex 及业务域模块

## 4. 不负责什么
- 不定义标准（那是 xlib_standard）
- 不收集/存储证据（那是 xlib_evidence）
- 不执行 CI 管线流程（那是 xlibgate）
- 不参与生产运行时

## 5. 架构位置
基座层（L1 执行器）。依赖方向：允许 xlib_standard（只读模板文件，非 import 依赖），禁止 observex/configx/resiliencx/schedulex/业务域任何模块。与 xlibgate 互补：xlibgate 管 CI 门禁（编译/依赖/发布），xlib_harness 管规格结构/模板/格式门禁。目录根：`module/xlib_harness/`（SPEC.md/goal.md/TRACEABILITY.md/IMPLEMENTATION-PLAN.md/tasks/）+ 运行时代码 `/home/workspace/xlib-harness`。

## 6. 生命周期
短生命周期 CLI 工具，无运行时生命周期管理。每次执行：加载配置（profiles）→ 生成或检查 → 输出 GenerateResult（FilesCreated/Warnings）或 CheckResult（Module/Passed/Checks[]/Summary）→ exit 0（通过）或非零（BR-003 失败）。

## 7. 标准目录结构
```text
module/xlib_harness/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/               # 5 个 task markdown

/home/workspace/xlib-harness/    # 运行时代码（独立 Go module）
  Generator / HarnessGate 接口实现
  GateProfile: full / spec / boundary
  fixtures/            # compliant/broken/bad-dep/format-issues/broken-trace 测试夹具
```

## 8. 配置规范
`xlib_harness` YAML：`template_source`（指向 `../xlib_standard/templates/`）+ `profiles`（full/spec/boundary 各自的检查组合）。full = spec-lint + boundary-check + format-check + traceability-gate；spec = spec-lint + format-check；boundary = boundary-check。

## 9. 错误模型
公共错误：`ErrModuleExists`（目标模块已存在，用 `--force` 覆盖或换名）、`ErrTemplateNotFound`（xlib_standard 模板路径无效，检查 template_source 配置）、`ErrCheckFailed`（门禁检查未通过，查看 CheckResult.Checks 逐项修复）。CheckResult 含 Module/Passed/Checks（CheckItem{Name,Passed,Detail}）/Summary。

## 10. 日志规范
无运行时指标（不参与业务运行）。门禁结果输出为结构化 JSON（NFR-002，`xlib_harness check --json | jq .`）。具体日志后端遵循 observex 全局规范（SPEC 未细化运行时 logging，本模块为执行器/生成器）。

## 11. Metrics
SPEC §17 明确"无运行时指标（不参与业务运行）"。门禁结果通过结构化 JSON 输出（CheckResult/GenerateResult），由 CI 系统聚合消费，无独立 metrics exporter。

## 12. Tracing
SPEC 未定义 Trace span 约定。执行流程通过 check 命令的 Checks[] 数组（逐项 CheckItem）重建调用链。如下游启用分布式追踪，遵循 observex 全局 OpenTelemetry 规范。

## 13. Reliability
generate 必须在 5 秒内完成（BR-001）。check 只读不写（BR-002，前后文件 hash 对比验证）。check 失败退出码非零（BR-003）。generate → check 自举闭环（生成后立即检查）。generate 写入路径限制在 module/ 下（NFR-003）。无 retry/backpressure/circuit breaker（非在线服务）。

## 14. Security
- 不读取密钥（SPEC §18）
- generate 写入路径必须限制在 module/ 下
- 不执行远程代码
- path traversal 防护：`xlib_harness generate ../escape` 应拒绝（NFR-003 验证）

## 15. Performance SLO
generate 延迟 < 5s（BR-001）；check 延迟（单模块）< 10s（NFR-001）。基线证据：`BenchmarkGenerate` 约 220281 ns/op，`BenchmarkCheckFullProfile` 约 223926 ns/op。覆盖率 total 88.8%，核心包 89.2%。

## 16. 测试标准
单元测试（每个 check 独立可测）+ 集成测试（generate → check 端到端自举）+ 基准测试（generate 性能 < 5s）。Traceability TC：TC-001 空目录 generate 后文件齐全、TC-002 合规/不合规模块逐项报告、TC-003 违规依赖检出、TC-004 模板自举验证、TC-005 格式问题逐项输出、TC-006 断开 FR→AC→TC 链路检出。CLI smoke 覆盖 build/dependency-boundary/template-validate/generate/check-full/readonly/negative-gates/explicit-xlib_standard-rejected/security-boundary。

## 17. Chaos
SPEC 未定义 chaos 注入维度。等效韧性由边界情况覆盖（§12）：模块名含特殊字符（路径遍历攻击）、xlib_standard 模板目录不存在、生成时目标目录已存在部分文件、门禁检查超大 TRACEABILITY 文件。

## 18. Contract
```go
type Generator interface {
    Generate(module string, opts ...GenerateOption) (*GenerateResult, error)
}
type HarnessGate interface {
    Check(module string, profile GateProfile) (*CheckResult, error)
}
type GateProfile string  // full / spec / boundary
```
GenerateResult{FilesCreated, Warnings}；CheckResult{Module, Passed, Checks[]CheckItem, Summary}；CheckItem{Name, Passed, Detail}。

## 19. CI Gate
`make test`、`make vet`、`make boundary`（SPEC §19）。验收命令：`go test ./...`、`go test -race -count=1`、`go vet ./...`、`go test -coverprofile=coverage.out`、`go list -deps ./...` + `go list -m all`（依赖边界审计，不出现 xlib_standard import/module dependency）。

## 20. Release Gate
DoD（SPEC §21，全部 ✅）：SPEC Approved、所有 FR 实现并测试、generate → check 自举闭环、文档齐全。FEATURES 实现完成判定 6 项全 ✅：FR/BR/NFR 覆盖、任务追溯、依赖边界、运行时证据归档、版本标签一致。

## 21. Versioning
v1 门禁 profile 名称保持稳定（full/spec/boundary）。check 输出格式向后兼容。当前 v0.1.1（2026-06-18 补齐验收证据、性能基线与发布文档同步），从 xlib_standard 拆分的初始版本为 v1.0.0（2026-06-14）。

## 22. 兼容性策略
门禁 profile 名称稳定（v1 保持 full/spec/boundary）。check 输出 JSON 格式向后兼容。generate 生成的骨架文件清单稳定（SPEC.md/TRACEABILITY.md/goal.md/tasks/IMPLEMENTATION-PLAN.md）。profile 是否允许用户自定义组合列为待解决问题（OQ）。

## 23. Failover
非在线服务，无服务级 failover。失败模式：generate 目标已存在（`--force` 覆盖）、模板路径无效（检查 template_source）、check 未通过（逐项修复）。退出码非零即失败信号，无自动恢复。

## 24. Backpressure
无流式/在线 backpressure。generate/check 为批处理命令。资源约束：超大 TRACEABILITY 文件门禁检查、path traversal 拒绝、写入路径限制 module/ 下。

## 25. 审计要求
门禁检查结果输出结构化 JSON CheckResult，逐项 CheckItem（Name/Passed/Detail）可追溯。traceability-gate（FR-006）检查 FR→AC→TC 链路闭合，断链或缺环报告缺口。boundary-check（FR-003）审计允许/禁止依赖、production-import-testkitx 禁止、stdlib-only gate。只读检查不改文件（BR-002）保证审计无副作用。

## 26. 熵减规则
- check 不得修改被检模块任何文件（BR-002）
- generate 仅生成 5 类固定文件骨架（SPEC/TRACEABILITY/goal/tasks/IMPLEMENTATION-PLAN）
- 禁止 xlib_standard Go import/module dependency（只读模板文件）
- 门禁 profile 名称稳定（full/spec/boundary）

## 27. AI Constraints
- AI 不得通过 generate 写入 module/ 之外的路径
- 不得在 check 中修改被检模块文件
- 不得引入 xlib_standard Go import 依赖（只读模板）
- 不得依赖 observex/configx/resiliencx/schedulex/业务域模块

## 28. Forbidden Patterns
- generate 写入路径越界（path traversal）
- check 修改被检模块文件（BR-002 违反）
- import `github.com/ZoneCNH/xlib-standard`（NFR-004 禁止 Go import/module dependency）
- check 失败退出码为零（BR-003 违反）
- 依赖业务域模块或未授权基座

## 29. Production Ready Checklist
- [x] 所有 FR 实现并有测试覆盖（FR-001~006，AC-001~006 ✅）
- [x] BR-001~003 行为约束（generate < 5s、check 只读、失败非零 ✅）
- [x] NFR-001~004 性能/可观测/安全/依赖边界（✅）
- [x] go test/-race/go vet/coverage 88.8% 通过
- [x] CLI smoke 全 PASS（build/generate/check-full/readonly/negative-gates/security-boundary）
- [x] generate → check 自举闭环
- [x] v0.1.1 发布（Acceptance-Baseline 335eef9，远端 Actions 为补充信号）
- [x] 无开放发布缺口

## 30. Roadmap
- v1.0.0 初始版本，从 xlib_standard 拆分（2026-06-14）
- v0.1.1 补齐验收证据、性能基线与发布文档同步（2026-06-18）
- 待解决（OQ）：generate 支持哪些模板变体（仅 SPEC / 完整骨架）、check 是否集成到 xlibgate 统一入口、门禁 profile 是否允许用户自定义组合
