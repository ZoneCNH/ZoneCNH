# xlib-evidence

## 1. 模块定位
xlib-evidence 是 Foundation 的**证据收集与发布运行时**——在 CI pipeline 中收集各模块的覆盖率、门禁结果、发布 manifest，生成统一证据报告，支持远程证据验证。**证据边界：CI/发布期证据（CI/release-time evidence）**，不做测试也不生成原始证据——从各模块（含 testkitx）收集已有证据汇总为标准报告。Status=Approved（SPEC v1.2.1），模块版本 v0.2.4（GitHub Release 已发布，release evidence assets 已归档），Layer=基座·CI 证据运行时（L1 证据）。从 xlib-standard 拆分而来，独立 Go module。

## 2. 生产职责
- FR-001 collect-coverage：模块执行 `go test -cover` → 覆盖率报告收集并结构化存储
- FR-002 generate-manifest：模块通过所有门禁 → 生成 Release Manifest（version/commitSHA/gates/coverage/hash）
- FR-003 validate-manifest：CI 检查 manifest → 验证完整性/hash/内容一致性
- FR-004 remote-evidence：远程查询模块证据 → 返回结构化 manifest JSON
- FR-005 report：聚合多模块证据 → 生成跨模块统一报告

## 3. 边界定义
- manifest 必须包含门禁全绿证据（BR-001）
- 覆盖率低于 100.0% 不得发布（BR-002，边界值 99.99% 拒绝 / 100.00% 通过）
- manifest 不可事后篡改，hash 链校验（BR-003）
- evidence 存储必须不可变追加（BR-004）
- 仅 CI/发布期证据；testkitx 在 `go test` 进程内生成原始证据

## 4. 不负责什么
- 不定义标准（那是 xlib-standard）
- 不执行门禁检查（那是 xlib-harness / xlibgate）
- 不生成模块骨架（那是 xlib-harness）
- 不参与业务运行时
- 不生成原始测试证据（那是 testkitx 的 golden/contract/boundary/leak 证据）

## 5. 架构位置
基座层（L1 证据）。依赖方向：允许 Go 标准库；禁止 kernel/observex/configx/resiliencx/schedulex 等未授权运行时模块；禁止任何存储/网络后端（不连接 Redis/Postgres）；允许通过显式配置的 HTTP endpoint 查询远程 evidence（默认不连接）。分工链：testkitx 生成测试期原始证据 → xlib-evidence 在 CI 中收集 + 结合 coverage/gate 结果 → 生成发布期 manifest 和统一报告。

## 6. 生命周期
CI pipeline 期运行，无业务运行时生命周期。每次执行：collect（coverage/gate）→ generate（manifest）→ validate（hash/完整性）→ report（聚合）。证据存储不可变追加（BR-004），manifest hash 链防篡改（BR-003）。

## 7. 标准目录结构
```text
module/xlib-evidence/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/               # 6 个 task markdown

/home/xlib-evidence/   # 运行时代码（独立 Go module）
  coverage.go / coverage_test.go        # FR-001
  manifest.go / manifest_test.go        # FR-002/003
  remote.go / remote_test.go            # FR-004
  report.go / report_test.go            # FR-005
```

## 8. 配置规范
`xlib_evidence` YAML：`storage_path`（默认 `./evidence/`）、`manifest_path`（默认 `./manifest/`）、`coverage_threshold`（默认 100.0）、`remote.enabled`（默认 false）+ `remote.endpoint`。默认不连接远程服务，remote evidence 为可选。

## 9. 错误模型
公共错误：`ErrCoverageNotFound`（模块无覆盖率数据，先执行 `go test -cover`）、`ErrGateNotPassed`（门禁未全绿，修复后重试）、`ErrManifestTampered`（manifest hash 不匹配，重新生成或调查篡改）。

## 10. 日志规范
无运行时指标（不参与业务运行，SPEC §17）。证据报告格式 JSON。其他运行时日志遵循 observex 全局规范（SPEC 未细化运行时 logging，本模块为 CI 证据运行时）。

## 11. Metrics
SPEC §17 明确"无运行时指标（不参与业务运行）"。证据报告为 JSON 格式（CoverageReport/Manifest/EvidenceBundle），由 CI 系统消费，无独立 metrics exporter。

## 12. Tracing
SPEC 未定义 Trace span 约定。证据链路通过 manifest hash 链（BR-003）和不可变追加存储（BR-004）保证可追溯。如下游启用分布式追踪，遵循 observex 全局 OpenTelemetry 规范。

## 13. Reliability
manifest 生成延迟 < 1s（NFR-001），20 模块证据聚合 < 5s（NFR-002）。manifest hash 完整性校验防篡改（NFR-003）。覆盖率边界 100.00% 稳定判定（BR-002）。多 CI job 并发生成同一模块 manifest（§12 边界情况）。远程 evidence endpoint 不可用时降级（§12）。无 retry/backpressure/circuit breaker 运行时逻辑（CI 期工具）。

## 14. Security
- manifest hash 用于完整性校验（NFR-003）
- 不读取密钥（NFR-004：`rg -n "os\.Getenv|TOKEN|SECRET|PASSWORD|Redis|Postgres"` 无匹配）
- 不连接远程服务（remote evidence 为可选，默认 disabled）
- 禁止依赖存储/网络后端（NFR-005：Redis/Postgres）

## 15. Performance SLO
manifest 生成 < 1s（BenchmarkManifestGen 20340 ns/op）；20 模块证据聚合 < 5s（BenchmarkMultiModuleAggregate 543300 ns/op）。覆盖率 total 100.0% >= 100.0%。

## 16. 测试标准
单元测试（manifest 生成/验证独立可测）+ 集成测试（collect → generate → validate 端到端）+ Golden 测试（固定覆盖率输入 → 固定 manifest 输出）。Traceability TC：TC-001 mock 覆盖率 → CoverageReport 正确、TC-002 全门禁通过 → manifest 生成且 hash 有效、TC-003 合法 manifest 通过/篡改拒绝、TC-004 HTTP endpoint 返回 JSON 证据、TC-005 3 模块输入 → 统合报告列出全部状态。覆盖 5 AC（AC-001~005）全 ✅。

## 17. Chaos
SPEC 未定义 chaos 注入维度。等效韧性由边界情况覆盖（§12）：覆盖率恰好 100.00%（边界值）、manifest 文件被手动修改（hash 校验失败）、多 CI job 并发生成同一模块 manifest、远程 evidence endpoint 不可用时降级。

## 18. Contract
```go
type EvidenceCollector interface {
    CollectCoverage(module string) (*CoverageReport, error)
    CollectGateResults(module string) (*GateResults, error)
}
type ManifestGenerator interface {
    Generate(module string, evidence EvidenceBundle) (*Manifest, error)
}
type ManifestValidator interface {
    Validate(manifest Manifest) (*ValidationResult, error)
}
```
CoverageReport{Module, TotalPct, PerPkg, Timestamp}；Manifest{Module, Version, CommitSHA, Gates[], Coverage, Hash}；EvidenceBundle{Coverage, Gates[], Timestamp}。

## 19. CI Gate
`go test ./...`、`go test ./... -race -count=1`、`go vet ./...`、`go build ./...`、`go test ./... -coverprofile=coverage.out` 且 total coverage >= 100.0%、`go list -deps ./...` + `go list -m all` 依赖边界审计（SPEC §19）。

## 20. Release Gate
DoD（SPEC §21，全 ✅）：SPEC Approved、所有 FR 实现并测试、collect → generate → validate 闭环、文档齐全。ACCEPTANCE §5 发布 DoD 全 ✅：FR/BR/NFR 与 SSOT 一致、AC/TC 与测试名一致、运行时通过 test/race/vet/build/coverage、无凭证/私有端点、v0.2.4 tag/release 已发布且 release evidence assets 已归档。

## 21. Versioning
manifest 格式 v1 保持稳定（SPEC §20）。新字段为追加，不删除旧字段。当前 v0.2.4（2026-06-20 GitHub Release 已发布，release evidence assets 已归档），从 xlib-standard 拆分的初始版本为 v1.0.0（2026-06-14）。

## 22. 兼容性策略
manifest 格式 v1 稳定，新字段追加不删除旧字段。CoverageReport/Manifest/EvidenceBundle 数据模型向后兼容。远程 evidence endpoint JSON 格式稳定。覆盖率阈值通过配置可调（默认 100.0）。

## 23. Failover
非在线服务，无服务级 failover。失败模式：覆盖率缺失（先跑 `go test -cover`）、门禁未全绿（修复后重试）、manifest 篡改（重新生成或调查）。远程 evidence endpoint 不可用时降级处理（§12 边界情况）。

## 24. Backpressure
无流式/在线 backpressure。CI 期批处理工具。资源约束：多 CI job 并发生成同一模块 manifest、20 模块聚合 < 5s、manifest 生成 < 1s。evidence 存储不可变追加（BR-004）约束存储增长模式。

## 25. 审计要求
**本模块的核心职责即证据归档审计**。Release Manifest 含 version/commitSHA/gates/coverage/hash，是发布审计的事实来源。manifest hash 链校验（BR-003）保证不可事后篡改。evidence 存储不可变追加（BR-004）保证审计轨迹完整。report（FR-005）生成跨模块统一报告供审计/治理消费。远程 evidence（FR-004）返回结构化 manifest JSON 支持外部审计验证。

## 26. 熵减规则
- manifest 不可事后篡改（hash 链校验，BR-003）
- evidence 存储不可变追加（BR-004）
- manifest 格式 v1 稳定，新字段追加不删除旧字段
- 仅 CI/发布期证据，不与 testkitx 测试期证据职责混淆

## 27. AI Constraints
- AI 不得生成覆盖率低于 100.0% 的发布 manifest（BR-002 强制）
- 不得接受 manifest hash 不匹配（ErrManifestTampered）
- 不得引入存储/网络后端依赖（Redis/Postgres，NFR-005）
- 不得读取密钥/连接未配置的远程服务（NFR-004）

## 28. Forbidden Patterns
- manifest hash 链缺失或可篡改（BR-003 违反）
- evidence 存储可变覆盖（BR-004 违反，必须不可变追加）
- 依赖 kernel/observex/configx/resiliencx/schedulex（NFR-005 禁止）
- 读取密钥/连接 Redis/Postgres（NFR-004 禁止）
- 生成原始测试证据（那是 testkitx 职责）

## 29. Production Ready Checklist
- [x] 所有 FR 实现（FR-001~005，AC-001~005 ✅）
- [x] BR-001~004 行为约束（门禁全绿/100.0% 阈值/hash 链/不可变追加 ✅）
- [x] NFR-001~005 性能/安全/依赖边界（✅）
- [x] go test/-race/go vet/go build/coverage 100.0% 通过
- [x] collect → generate → validate 闭环
- [x] BenchmarkManifestGen 20340 ns/op，BenchmarkMultiModuleAggregate 543300 ns/op
- [x] 禁止依赖扫描 + 凭证/外部服务关键字扫描无匹配
- [x] v0.2.4 GitHub Release 已发布，release evidence assets 已归档
- [x] Trust Alignment 与 CI/CD workflows 已部署并纳入发布证据

## 30. Roadmap
- v1.0.0 初始版本，从 xlib-standard 拆分（2026-06-14）
- v1.0.1 对齐独立 Go module 验收、实际测试名、依赖边界与 CI 门禁（2026-06-18）
- v0.2.4 GitHub Release 发布，release evidence assets 与 Trust Alignment/CI-CD 证据闭合（2026-06-20）
- 待解决（OQ）：remote evidence 是否需要签名、证据存储是否支持 SQLite/文件双后端、manifest 是否包含 reproducible build info
