# xlibgate

## 1. 模块定位
xlibgate 是 Foundation 的**机器可执行门禁 CLI 工具**，提供三组子命令：`check`（CI 中验证依赖矩阵/import 边界/Go baseline/secret 扫描/release evidence）、`l2`（L2 发布就绪门禁：能力清单校验、契约测试计划、证据完整性、发布评分）、`trust`（v2 Trust Alignment 门禁：身份对齐/模板残留/发布一致性/成熟度工厂/import 边界/testkitx 隔离/secret 脱敏/舰队状态）。Status=Approved（SPEC v1.1.2），模块版本 v1.0.0，Layer=基座·CI 门禁（L1）。消费 xlib-standard 的 Gate/Evidence 标准，纯 CLI 工具不被任何模块 import。

## 2. 生产职责
- FR-001 check imports（依赖矩阵/import 边界违规，输出文件路径行号）
- FR-002 check gomod（`go mod tidy` 无 diff）
- FR-003 check baseline（Go 版本对齐）
- FR-004 check release（release evidence 收集校验）
- FR-005 check all（全量门禁，含 secret_scan/gitleaks）
- FR-006 输出格式（JSON/human-readable）
- FR-007~011 l2 子命令组（validate-manifest/plan/check-contracts/check-evidence/release-check）
- FR-012~019 trust 子命令组（identity/template-residue/release-consistency/maturity/import-boundary/testkit-prod-import/secret-redaction/fleet-status）

## 3. 边界定义
- 纯 CLI 工具，不被任何模块 import（§14.5）
- 标准化 exit code：0=pass，1=fail，2=error（BR-001，语义不可互换）
- import 规则从 `deps.yaml` 读取，不硬编码（BR-002）
- Go baseline 从配置或 `--expected` 获取（BR-003）
- evidence schema 与 xlib-standard 一致（BR-004）
- secret 扫描使用 gitleaks（BR-005）
- check all 必须执行所有子检查（BR-006）

## 4. 不负责什么
- 不参与运行时（纯 CLI 工具）
- 不做 Go 源码 AST 分析框架（用 `go list`/`go mod graph` 标准工具）
- 不做交易/行情/风控/订单/仓位业务域计算
- 不替代 CI 平台本身
- 不替代 xlib-standard（标准定义 vs 机器执行）
- 不做代码格式化（→ gofmt）/代码审查（→ human+AI review）

## 5. 架构位置
基座层（L1 门禁），消费 xlib-standard 的 Gate/Evidence 标准但不 import 它。依赖方向：仅允许 stdlib（`go/parser`/`go/ast`/`os/exec`/`encoding/json`/`flag`）、`gopkg.in/yaml.v3`、`gitleaks`（外部命令）。禁止依赖所有 Foundation 运行时模块、业务域实现、L2.5 领域共享层。入口：`main.go` → cmd/（root/check/trust）→ scanner/（imports/gomod/baseline/trust/*）→ evidence/ + report.go。

## 6. 生命周期
短生命周期 CLI 工具，无运行时生命周期管理。每次执行：config loaded → 各子检查 started → completed（含 status 和 duration_ms）→ failed/error 日志 → exit 0/1/2。exit code 即为健康信号，无健康检查端点。

## 7. 标准目录结构
```text
xlibgate/
├── main.go / go.mod / README.md / CHANGELOG.md / LICENSE
├── cmd/        # root/check/imports/gomod/baseline/release/all + trust_*（8 个 trust 子命令）
├── scanner/    # imports/gomod/baseline + trust/（identity/template/release/maturity/boundary/testkit/secret/fleet）
├── evidence/   # collector + validator
├── config.go / report.go / errors.go
├── internal/   # gomod + ast 工具
├── testdata/   # config.yaml/deps.yaml/evidence.json/fixtures
├── example_test.go / benchmark_test.go / integration_test.go
```

## 8. 配置规范
`xlibgate.yaml`：`baseline.go_version`（required，如 "1.23"）、`imports.forbidden[]`（source+targets）、`release.evidence_path`/`require[]`、`secret_scan.enabled`（default true）+ `config_path`。配置加载时对 semver、非空字符串、条件枚举做合法性检查。空配置文件使用默认值（无 forbidden 规则、无 baseline 要求）。

## 9. 错误模型
公共错误变量：`ErrConfigInvalid`/`ErrConfigMissing`/`ErrEvidenceInvalid`/`ErrEvidenceMissing`/`ErrBaselineMismatch`/`ErrImportViolation`/`ErrGomodDirty` + trust 专用：`ErrIdentityMismatch`/`ErrTemplateResidue`/`ErrReleaseDrift`/`ErrFactoryGateBlocked`/`ErrSecretLeak`/`ErrFleetPartialFail`。消息格式 `"xlibgate: <check>: <detail>"`，`%w` 包装保留错误链。CheckResult 含 Name/Status/Details(Violation{File,Line,Message})/DurationMs。

## 10. 日志规范
主要可观测载体（短生命周期 CLI，不集成运行时 exporter）。5 个结构化日志事件：`xlibgate.check.started`（info，含 check name）、`xlibgate.check.completed`（info，含 status 和 duration_ms）、`xlibgate.check.failed`（warn，含 violation 详情）、`xlibgate.check.error`（error，含 error message）、`xlibgate.config.loaded`（info，含文件路径）。覆盖 Constitution §6.2 操作耗时与错误计数需求。

## 11. Metrics
不启动 HTTP metrics 端点，通过 CI 系统对结构化日志解析等效聚合：`foundationx_xlibgate_check_duration_seconds`（histogram，label check_name/status）、`foundationx_xlibgate_check_total`（counter）、`foundationx_xlibgate_check_errors_total`（counter）。来源日志的 duration_ms 和事件计数。

## 12. Tracing
不启动 tracing exporter。执行流程通过父子日志事件的 `check_name`/`timestamp` 关联字段重建调用链，等效 span 语义。逻辑 span：`check_all`（根）→ `check_imports`/`check_gomod`/`check_baseline`/`check_release`/`check_secret_scan` + 8 个 trust span（identity/template/release/maturity/boundary/testkit/secret/fleet）。

## 13. Reliability
check all 中子检查独立 goroutine 运行（errgroup/WaitGroup），任一失败/出错不影响其余独立执行（BR-006）。某子检查 error 时跳过该子检查标记 error，继续其余，最终 exit 2。error 优先级高于 fail（同时存在时 exit 2）。子检查超时标记为 error。默认不重试，可配置 `retry: {max_attempts: N, backoff: "constant"}`。evidence 文件超大（>100MB）正常解析（内存 < 2x）。

## 14. Security
secret 扫描集成 gitleaks（BR-005，外部命令调用，gitleaks 不可用时明确报错 exit 2）。配置文件只含规则定义不含密钥。错误消息只含文件路径和行号，不含源代码。trust secret-redaction 扫描 release/evidence 文档中的 API keys/passwords/tokens/DSN，脱敏输出（不输出密钥原文）；检测私有端点（loopback/10.x/172.16-31.x/192.168.x），开发上下文豁免（test/testdata/_test.go/dev-only 示例/README 本地章节）。CLI 参数 + YAML schema 校验。

## 15. Performance SLO
全量门禁 50 模块 < 30s；import 扫描 < 10s；go.mod 检查 < 5s；baseline 检查 < 5s；JSON 报告生成 < 100ms；内存 < 100MB。trust：identity < 2s，template-residue 50 模块 < 15s，release-consistency < 3s，maturity < 1s，import-boundary < 10s，testkit-prod-import < 5s，secret-redaction < 10s，fleet-status 20 模块 < 60s。

## 16. 测试标准
单元测试（§15.2，覆盖 import 违规/testkitx 边界/gomod diff/baseline mismatch/evidence 缺失/config 解析/exit code/JSON 格式/secret 扫描命中 + trust 16 场景）+ Given/When/Then 用例（TC-001~TC-030 + TC-021a/021b）+ Benchmark（§15.4）+ 集成测试（`check all` 完整 CI 流程、自检、CI artifact 输出）。trust maturity 必须验证 release=false 阻塞、open blocker 阻塞、单百分比拒绝。覆盖率 >= 80%。

## 17. Chaos
SPEC 未定义独立 chaos 注入维度。等效韧性由 §13 Reliability 覆盖：子检查独立执行不互相阻断、超时标记 error、gitleaks 不可用降级、并发实例无状态冲突、fleet-status 部分模块扫描失败仍生成完整 index.json。

## 18. Contract
CLI 命令契约（§8.1）：`check imports/gomod/baseline/release/all`、`l2 validate-manifest/plan/check-contracts/check-evidence/release-check`、`trust identity/template-residue/release-consistency/maturity/import-boundary/testkit-prod-import/secret-redaction/fleet-status`、`version`。Exit code 0/1/2。JSON 输出含 `status`/`timestamp`/`checks[]`/`summary`。trust 统一 per-check JSON schema：`check`/`repo`/`status`/`severity`/`findings`/`reason_code`（10 种枚举）/`evidence`。

## 19. CI Gate
通用 gate：`go build`/`go test -race`/覆盖率 >= 80%/`go vet`/`golangci-lint`/`go mod tidy --exit-code`/`gitleaks detect --no-git`/benchmark。专属 gate：自检 `xlibgate check all --config xlibgate.yaml`、不依赖 Foundation 运行时（`go list -deps` 零命中 ZoneCNH/kernel 等）。Trust gate：identity/template-residue/release-consistency/maturity/import-boundary/testkit-prod-import/secret-redaction/fleet-status 各自的 reason_code 阻塞条件。

## 20. Release Gate
DoD：CLI 帮助文档完整、所有 check 子命令有示例、exit code 文档化、JSON 输出格式文档化、CHANGELOG/README 更新、单元覆盖率 >= 80%、-race 通过、Benchmark 无 > 10% 回退、go vet/golangci-lint 无警告、Secret 扫描通过、自检通过、所有 FR/Edge Cases 有测试、trust 子命令全部实现并通过 TC-014~029、trust 统一 JSON schema 符合 §9.3.1、fleet-status 可对 20 模块正确聚合。

## 21. Versioning
CLI 命令结构变更/JSON 字段新增/配置 schema 新增可选字段/新增检查子命令 = minor。exit code 语义变更/JSON 字段重命名删除/配置字段删除重命名 = major。新增字段向后兼容（旧解析器忽略未知字段）；删除字段在 MINOR 标 deprecated，MAJOR 移除并带过渡 alias/迁移脚本。当前 v1.0.0（SPEC v1.1.2 含 v2 Trust Alignment）。

## 22. 兼容性策略
`check all` 默认不自动包含新增子命令（避免破坏现有 CI 预期），引导用户更新 CI 配置启用。新增配置字段带默认值避免旧配置报错。Trust reason_code 枚举稳定，新增在发布说明标注。JSON 输出 `checks[].status` 枚举值在 MarshalJSON 中校验，非法值 panic（编程错误）。

## 23. Failover
非在线服务，无服务级 failover。失败模式：子检查 fail（exit 1）/error（exit 2）。check all 中子检查 error 降级为汇总 exit 2，其余继续。gitleaks 不可用明确报错不静默放行。fleet-status 部分模块扫描失败仍生成完整 index.json（含 status=error 条目），exit 1。fleet-status 投影漂移（release=false/open blocker 但 factory=true）强制 factory=false。

## 24. Backpressure
无流式/在线 backpressure。全量扫描为批处理。资源约束：evidence 文件 >100MB 正常解析（内存 < 2x）、并发多实例独立无状态冲突、trust secret-redaction 跟踪符号链接限制深度 max 3 层防循环、fleet-status 模块数 != 20 时仍生成 index.json（含 warning）。

## 25. 审计要求
fleet-status 生成 `.foundationx/status/index.json`，含 20 模块各自身份/发布/成熟度/边界/阻断项/证据索引状态，是舰队级信任审计核心产物。release-consistency 七源比对（.repo-contract.yaml versions/go.mod/VERSION/CHANGELOG/git tag/release manifest/GitHub release）。maturity 11 维工厂级判定全部审计。trust 统一 JSON 输出的 `evidence` 字段（projection: release/factory/open_blockers）供仲裁审计。per-check JSON 含 reason_code 机器可读。

## 26. 熵减规则
- BR-010：仅 xlib-standard 可含 5 条模板身份短语，下游仓库含任一即 TEMPLATE_RESIDUE（精确字符串匹配）
- maturity 拒绝单个百分比替代 11 维明细（FACTORY_GATE_BLOCKED）
- JSON 输出 status 枚举稳定（pass/fail/error），不允许空字符串
- reason_code 枚举稳定（10 种），机器可读

## 27. AI Constraints
- AI 不得为 check all 默认启用新增子命令（避免破坏 CI 预期）
- 不得将 release=false 或 open blocker 投影为 factory pass（FR-015/019 强制 factory=false）
- 不得接受单个百分比值作为 maturity 判定通过
- 不得静默接受 evidence schema 不匹配（必须 ErrEvidenceInvalid exit 2）

## 28. Forbidden Patterns
- 自研 secret 扫描器（必须用 gitleaks，BR-005）
- 硬编码 import 规则或 Go baseline（BR-002/003）
- check all 跳过部分检查（BR-006）
- 错误消息泄露源代码内容
- 下游仓库包含模板身份短语（BR-010）

## 29. Production Ready Checklist
- [x] check 子命令 FR-001~006（AC-001~009，✅）
- [x] l2 子命令 FR-007~011（AC-010~014，✅）
- [ ] trust 子命令 FR-012~019（AC-015~022，登记 ❌，TASK-XLIBGATE-011~018 待落任务文档）
- [ ] BR-010 模板身份短语（登记 ❌）
- [x] BR-001~009 行为约束（✅）
- [ ] NFR-011~018 trust benchmark 证据（登记 ❌）
- [x] NFR-007~008/010 覆盖率/无密钥/无运行时依赖（✅）
- [ ] /home/xlibgate 最新 CI/release evidence 归档（缺口登记）

## 30. Roadmap
- v1.0.0/v1.0.1 初始 check 子命令 + 结构评分修复（2026-06-07~12）
- v1.0.2 l2 子命令组（FR-007~011）
- v1.1.0~v1.1.2 v2 Trust Alignment（FR-012~019，BR-010，per-check JSON，projection drift/blocker-aware factory gate）（2026-06-14）
- 待评估（OQ）：增量扫描、多配置合并、基础/高级插件机制、import 正则匹配、远程 evidence URL
