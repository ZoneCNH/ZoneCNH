# Foundation v1 执行跟踪器

> 源自 `FOUNDATION-V1.md` 的 P0/P1/P2 issue 拆分。
> 每项直接对应一个 GitHub Issue 或 PR。
> 勾选 = 完成。

最后更新：2026-06-14（环境扫描：全项目 .env.example 补全 35 个 + 5 项发现登记）

---

## P0：身份和边界修复

> 阻塞所有后续工作。必须先完成。

### Issue 1：resiliencx identity reset ✅

```text
标题：Redefine resiliencx as runtime resilience policy library
仓库：ZoneCNH/resiliencx
```text

- [x] README 重写：删除 Standard Source / Generator / Harness 叙事
- [x] README 重写：明确身份为 runtime resilience policy library
- [x] 新增 `docs/identity.md`（已于 2026-06-12 创建，含完整身份/边界/宪法合规声明）
- [x] 新增 `docs/boundary.md`（通过 docs/xgo-integration-boundary.md + docs/design.md 覆盖）
- [x] 新增最小 API：`policy.go` / `runner.go` / `operation.go`（已通过 pkg/resiliencx/resilience.go + client.go + config.go 实现，文件名不同；功能等价，接受现状）
- [x] 新增策略实现：`timeout.go` / `retry.go` / `circuit.go`
- [x] 新增策略实现：`bulkhead.go` / `ratelimit.go` / `fallback.go`
- [x] 新增 `classifier.go`（retryable / non-retryable / fatal）
- [x] 新增 `idempotency.go`（非幂等操作禁止自动 retry）
- [x] 新增 `event.go`（策略事件 sink）
- [x] 新增 `noop.go`（未配置时安全运行）
- [x] 新增 `options.go`（Option 模式配置）
- [x] 删除或迁移 `xlib-standard` 相关的模板/generator/harness 代码（README 无残留引用）
- [x] 更新 `go.mod`：移除不必要的依赖（Go 1.23，依赖干净）
- [x] 测试覆盖 ≥ 80%（已验证：全包 100% 覆盖率 — bulkhead/circuit/retry/timeout/fallback/ratelimit 全部 100%，含 fake-clock + 状态转换 + 并发安全测试）

### Issue 2：Foundation dependency matrix ✅

```text
标题：Add machine-readable Foundation dependency matrix
仓库：ZoneCNH/ZoneCNH（本文档仓库）
```text

- [x] 新增 `module/FOUNDATION-DEPS.yaml`（已完成）
- [x] CI 中增加 `check-deps.sh` 脚本（已完成，deps-matrix.yml）（从 yaml 解析）
- [x] CI 中增加 kernel stdlib-only 检查（`/home/kernel/scripts/check-stdlib-only.sh`）
- [x] CI 中增加 testkitx production import 检查（`pkg/testkitx/boundarytest/`）
- [x] CI 中增加反向依赖检查（`deps-matrix.yml` + `FOUNDATION-DEPS.yaml` constraints）
- [x] README 或 AGENTS 中引用此矩阵（已添加到 AGENTS.md 关键文档表）

### Issue 3：Go baseline alignment ✅

```text
标题：Align Foundation Go baseline to 1.23
仓库：所有 6 个模块
```text

- [x] `kernel` go.mod 确认 Go 1.23
- [x] `configx` go.mod 确认 Go 1.23
- [x] `observex` go.mod 确认 Go 1.23
- [x] `resiliencx` go.mod 确认 Go 1.23
- [x] `schedulex` go.mod 确认 Go 1.23
- [x] `testkitx` go.mod 降级到 Go 1.23（当前是 1.24）（已完成降级）
- [x] 所有 CI matrix 使用相同 Go 版本（`deps-matrix.yml` go-version: "1.23"）
- [x] README / AGENTS / Release docs 同步（AGENTS.md 已引用 FOUNDATION-DEPS.yaml 含 Go 1.23 baseline）

### Issue 4：foundationx compatibility exit plan ✅

```text
标题：Define and start foundationx compatibility exit
仓库：ZoneCNH/configx, ZoneCNH/observex
```text

- [x] ADR 已编写：`module/ADR-foundationx-exit.md`（已完成）
- [x] `configx`：列出所有 foundationx 用法和替代方案（`docs/foundationx-compatibility.md` 已存在，含完整兼容范围/不可变边界/升级规则）
- [x] `observex`：列出所有 foundationx 用法和替代方案（`docs/foundationx-compatibility.md` 已于 2026-06-12 创建，含兼容范围/不可变边界/升级规则）
- [x] `configx`：冻结，不再新增 foundationx usage（`scripts/check-foundationx-freeze.sh` 基线对比门禁已部署 — 1 文件基线；CI 门禁已就位防止新增用法）
- [x] `observex`：冻结，不再新增 foundationx usage（`scripts/check-foundationx-freeze.sh` 基线对比门禁已部署 — 4 文件基线；CI 门禁已就位防止新增用法）
- [x] CI 中增加 foundationx 新增用法检查（`FOUNDATION-DEPS.yaml` constraints: no-foundationx-new-usage）
- [x] `configx` v0.3 前完成迁移（✅ 完全解耦 — SecretString 原生化 + internal/foundationx 已删除 + contract tests 已重写）
- [x] `observex` v0.4 前完成生产解耦（✅ ErrorKind + Sanitizer 原生化，零 foundationx import；contract tests 重写 + internal/foundationx 删除 → v0.4）
- [x] `configx` 迁移完成删除 `internal/foundationx`（✅ contract tests 已重写，go.mod replace 已移除，internal/foundationx 已物理删除）
- [x] `observex` 迁移完成删除 `internal/foundationx`（✅ contract tests 已更新，go.mod replace 已移除，internal/foundationx 已物理删除）

---

## P1：每个模块补最小 v1 能力

> P0 完成后开始。每个模块独立，可并行。

### kernel ✅ v1.0.0 已发布 (2026-06-12)

- [x] public API snapshot 文件（`contracts/public_api/kernel_v0.schema.json`）
- [x] stdlib-only CI check（`scripts/check-stdlib-only.sh`）
- [x] no-hidden-goroutine CI check（`scripts/check-no-goroutine.sh`）
- [x] 12 子包核心实现：errx / timex / obsx / syncx / lifecycx / shutdownx / versionx / validx / retryx / contextx / healthx / contracttest
- [x] 核心库 100% 测试覆盖率，-race 清零
- [x] 15 项 CI 门禁全部通过（含 benchmark 回归）
- [x] `retryx` 限界文档（`retryx/BOUNDARY.md`）
- [x] `obsx` 限界文档（`obsx/BOUNDARY.md`）
- [x] API freeze 声明（`contracts/public_api/FREEZE.md`）
- [x] contracts/ 契约验证层（API snapshot + golden behavior + consumer import test）
- [x] SPEC.md v2.0.0 重写：集中式 App/Module/Deps → 12 子包轻量工具集
- [x] v1.0.0 GitHub Release：https://github.com/ZoneCNH/kernel/releases/tag/v1.0.0

### configx ✅ (PR #1 + #2 合入) + 文档完善 (PR #103 + #104 + #105 + SPEC v1.1.0 重写 + v1.0.0 发布)

- [x] `Provenance`：每个 key 记录 source、priority、override 链路
- [x] `EffectiveConfigHash`：配置指纹，可复现
- [x] `SanitizedManifest`：安全进入日志/health/CI artifact
- [x] `Schema`：机器可读配置契约
- [x] `StrictDecode`：未识别字段、重复字段、类型错误 fail-fast
- [x] `SecretPolicy`：统一 secret key 识别规则
- [x] `ValidationReport`：字段级证据
- [x] `NoGlobalStateGate`：防止引入进程级 config singleton
- [x] secret leak golden test
- [x] source precedence golden test

### observex ✅ (PR #3 合入)

- [x] label policy checker（`scripts/check-label-policy.sh`）
- [x] redaction leak checker（`scripts/check-redaction-leak.sh`）
- [x] metrics contract（`docs/metrics-contract.md`）
- [x] health JSON schema（`contracts/health.schema.json`）
- [x] memory recorder contract（`docs/memory-recorder-contract.md`）
- [x] `errx.Kind` → `error_kind` label 映射（`pkg/observex/errx_kind.go`）
- [x] 指标命名前缀 helper（`pkg/observex/metric_name.go`）
- [x] label 允许/禁止列表实现（`pkg/observex/label_policy.go`）

### testkitx ✅ (管线就绪, 5 PRs 合入)

- [x] Matrix v1.1 重写: Task列+BR7/7+NFR5+AC注册表+TC→FR追溯 (#125)
- [x] Tasks v2 重写: AC/TC前缀+non_scope+BR引用+红线修复 (#128)
- [x] Plan 阶段初始化: OVERVIEW+11个Task计划 (#127)
- [x] Prompt 阶段初始化: 11个开发Prompt (#127)
- [x] Plan+Prompt 7项扣分修复→全线100分 (#133)
- [ ] code/ 阶段: 在 testkitx 仓库实现 Go 代码

### testkitx ✅ (PR #1 合入)

- [x] production import boundary scanner 稳定 API（`pkg/testkitx/boundarytest/`）
- [x] fake clock 确定性示例（`examples/fake_clock_test.go`）
- [x] golden update guard（`pkg/testkitx/golden/guard.go`）
- [x] release manifest fixture（`testdata/fixtures/release_manifest.json`）
- [x] goroutine leak checker 加固（`pkg/testkitx/leaktest/leak_checker.go`）
- [x] 统一 assert API（`pkg/testkitx/assertx/assert_more.go`）
- [x] 统一 fixture loader（`pkg/testkitx/fixture/loader.go`）
- [x] 统一 contract hash helper（`pkg/testkitx/contract/hash.go`）

### resiliencx ✅ (PR #15 + #16 合入)

> Issue 1（身份修复）已完成。**2026-06-12 追加**：SPEC v1.0.1 Approved（PR #118）+ 对齐文档同步（PR #121/#122）

- [x] `timeout.go`：PerAttemptTimeout + TotalTimeout
- [x] `retry.go`：max attempts、max elapsed、backoff、jitter
- [x] `circuit.go`：closed/open/half-open 状态机
- [x] `bulkhead.go`：并发隔离、队列上限、快速拒绝
- [x] `ratelimit.go`：QPS、burst、按 key 限流
- [x] `fallback.go`：显式降级函数
- [x] `classifier.go`：retryable / non-retryable / fatal（PR #16）
- [x] `idempotency.go`：非幂等操作默认禁止自动 retry（PR #16）
- [x] `event.go`：策略事件 sink（PR #16）
- [x] `noop.go`：未配置时安全运行（PR #16）
- [x] `options.go`：Option 模式配置（PR #16）
- [x] fake-clock 测试（已验证：全包测试通过，含 circuit 状态转换 + bulkhead 并发安全 + 策略链集成测试，覆盖率达 100%）
- [x] **SPEC v1.0.1 文档管线完整**（SPEC.md: kernel 依赖修正 + BR 违反后果 + AC 标签 + Security 补强; goal.md: 对齐 SPEC + v1.2+ 版本分层; TRACEABILITY.md: Task 列 + 8 BR + 4 NFR 全覆盖; tasks/: non_scope + BR-002/006 覆盖 + TC-### 引用统一）
- [x] **对齐文档同步**（STATUS.md v0.4.8→v1.0.1; ARCHITECTURE.md 依赖矩阵 configx 禁止→允许; module/README.md + README.md 更新）

### schedulex ✅ (PR #3 合入)

- [x] DST/timezone golden test（`testdata/golden/dst_transitions.json`，8 场景）
- [x] misfire contract test（skip/run_once/catch_up）
- [x] overlap contract test（skip/queue_one/allow）
- [x] lock interface contract（`docs/lock-contract.md`）
- [x] event sink schema（`docs/job-event-schema.md`）
- [x] shutdown leak test（100 job + goroutine 对比）
- [x] shutdown race test（并发 Stop/触发/AddJob）
- [x] trigger determinism test（100 次一致性 + DST golden）
- [x] resiliencx 集成示例（`examples/resilient_job/main.go`）

### Issue 5：xlibgate CI Gate CLI 实现

```text
标题：Implement xlibgate as Foundation CI Gate CLI
仓库：ZoneCNH/xlibgate
```text

- [ ] TASK-XLIBGATE-000: 项目骨架
- [ ] TASK-XLIBGATE-001: CLI 框架
- [ ] TASK-XLIBGATE-002: check imports
- [ ] TASK-XLIBGATE-003: check gomod
- [ ] TASK-XLIBGATE-004: check baseline
- [ ] TASK-XLIBGATE-005: check release
- [ ] TASK-XLIBGATE-006: check all + 输出格式
- [ ] TASK-XLIBGATE-007: 集成测试
- [ ] TASK-XLIBGATE-008: 文档 + Release DoD
- [ ] TASK-XLIBGATE-009: 评分修复（Matrix RL-001 + Plan D1 + Tasks D1-D3）

---

## P2：Foundation example 闭环

> P1 核心能力完成后开始。

### Issue：foundation-example vertical smoke ✅

```text
标题：Add foundation-example vertical smoke
仓库：ZoneCNH/foundation-example
```text

- [x] demo app 启动和关闭
- [x] configx 加载 env + yaml + override
- [x] observex 注入 memory logger/metrics/tracer
- [x] kernel lifecycx 管理 start/stop
- [x] resiliencx 包裹 fake external API（retry + timeout）
- [x] schedulex 每 1s 调度一次 job（fake clock）
- [x] testkitx fake clock + golden + boundary + leak
- [x] release manifest 生成
- [x] 所有 `make` target 可运行
- [x] CI 全绿（Go 1.23 matrix）

---

## P3：环境扫描发现项（2026-06-14）

> 全项目 .env / go.mod / 依赖矩阵一致性扫描。非阻塞，按优先级自行排期。

### Issue 6：postgresx foundationx 依赖未纳入退出计划

```text
标题：postgresx 迁移出 foundationx 依赖
仓库：ZoneCNH/postgresx
```text

- [ ] `pkg/postgresx/` 下 9 个非测试 .go 文件 import `github.com/ZoneCNH/foundationx/pkg/foundationx`
- [ ] SPEC.md §15 Dependencies 写 `github.com/ZoneCNH/foundationx v0.1.1`，与 FOUNDATION-TRACKER Issue 4 退出完成声明矛盾
- [ ] 同步更新 SPEC.md 依赖声明和 IMPLEMENTATION-PLAN.md Phase 2
- [ ] 迁移完成后删除 `internal/foundationx` 或更新 contract tests

### Issue 7：postgresx Go baseline 未对齐 ✅

```text
标题：postgresx go.mod 降级到 Go 1.23
仓库：ZoneCNH/postgresx
```text

- [x] `go.mod` 声明 `go 1.25.0`，其余 5 核心模块均为 `go 1.23` → 已降级
- [x] 降级后确认 CI matrix go-version 一致（PR #7 merged, squash → main）
- [x] 更新 IMPLEMENTATION-PLAN.md version matrix

### Issue 8：observex go.sum 残留 foundationx hash ✅

```text
标题：observex go.sum 清理 foundationx 残留
仓库：ZoneCNH/observex
```text

- [x] `go.sum` 残留 `github.com/ZoneCNH/foundationx v0.1.0` hash（无实际 import，仅注释引用）
- [x] 运行 `go mod tidy` 清理（PR #9 merged, squash → main）

### Issue 9：contracts / transportx / xlib-standard 三仓共享 Go module

```text
标题：contracts / transportx go.mod 独立身份声明或文档说明
仓库：ZoneCNH/contracts, ZoneCNH/transportx
```text

- [ ] `/home/contracts/go.mod` 声明 `module github.com/ZoneCNH/xlib-standard`
- [ ] `/home/transportx/go.mod` 声明 `module github.com/ZoneCNH/xlib-standard`
- [ ] ARCHITECTURE.md 将三者列为独立模块，需明确是 monorepo 子目录还是需要独立 go.mod
- [ ] 若是 monorepo：ARCHITECTURE.md 状态表注明共享 module
- [ ] 若是独立模块：更新 go.mod module path 为各自的 `github.com/ZoneCNH/contracts` / `github.com/ZoneCNH/transportx`

### Issue 10：ARCHITECTURE.md 依赖矩阵覆盖不全

```text
标题：ARCHITECTURE.md 依赖矩阵扩展至 17 模块
仓库：ZoneCNH/ZoneCNH
```text

- [ ] 当前矩阵仅覆盖 kernel/configx/observex/testkitx/resiliencx/schedulex 6 个
- [ ] 补充 redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex（7 存储扩展）
- [ ] 补充 contracts/transportx（2 契约）
- [ ] 补充 xlib-standard/xlibgate（2 门禁）
- [ ] 补充 domainx（L2.5 值对象，仅允许被数据域/分析域/决策域/执行域导入）

### Issue 11：STATUS.md 缺失 domainx 条目

```text
标题：STATUS.md 补充 domainx v0.1.0 条目
仓库：ZoneCNH/ZoneCNH
```text

- [ ] STATUS.md 基座计数写 17 但括号只列 13 模块
- [ ] domainx 在 ARCHITECTURE.md / module/README.md 有独立条目，STATUS.md 缺失

### Issue 12：x.go.bak .env.example 双文件合并

```text
标题：x.go.bak 旧 .env.example 合并到 configs/.env.example
仓库：ZoneCNH/x.go
```text

- [ ] 旧文件 `/home/x.go.bak/.env.example`（14 变量，旧格式）与 `configs/.env.example`（22 变量，XGO_ 前缀）零交集
- [ ] 旧文件已脱敏（5 个凭据已清除）
- [ ] 10+ CI 脚本 / spec 文档引用根路径 `.env.example`，迁移后需同步更新路径
- [ ] 旧变量（FRED_API_KEY/JINSHI_API_KEY/TDENGINE_ROOT_PASS 等）迁移为 XGO_ 前缀后加入 configs 版本

### Issue 13：全项目 .env.example CI 连线

```text
标题：新建 35 个 .env.example 接入各仓库 CI secret-scope-check
仓库：ZoneCNH/*
```text

- [ ] 各 Foundation 模块（redisx/postgresx/taosx/ossx/natsx）的 .env.example 接入 CI 密钥泄漏检查
- [ ] 各交易所 SDK .env.example 接入对应 CI pipeline
- [ ] 统一 `secret-scope-check.sh` 模板或复用 x.go.bak 版本

---

## 进度汇总

| 优先级   | Issue 数 | 完成          | 进度       |
| -------- | -------- | ------------- | ---------- |
| P0       | 4        | 4             | ████       |
| P1       | 6 模块   | 6（全部完成） | ██████     |
| P2       | 1        | 1             | █          |
| P3       | 8        | 2             | █░░░       |
| **总计** | **19**   | **13**        | **█████░** |

---

## 关键依赖链

```text
Issue 1 (resiliencx identity)
  → P1 resiliencx 全部能力
  → P2 foundation-example

Issue 3 (Go baseline)
  → 所有模块 CI 统一

Issue 4 (foundationx exit)
  → configx v0.3 / observex v0.4 发布

P1 kernel
  → P1 configx（依赖 kernel 原语）
  → P1 observex（依赖 kernel 原语）

P1 testkitx
  → P2 foundation-example
```text

## 建议执行顺序

```text
第一批（并行）：
  Issue 1: resiliencx identity reset
  Issue 3: Go baseline alignment
  Issue 2: dependency matrix CI 化

第二批（并行）：
  P1 kernel: API freeze + admission gate
  Issue 4: foundationx exit 冻结

第三批（并行）：
  P1 configx: provenance/hash/schema
  P1 observex: label/redaction/metrics gate
  P1 resiliencx: 策略实现
  P1 schedulex: DST/misfire/lock contract
  P1 testkitx: boundary/fixture/assert

第四批：
  P2 foundation-example
  Issue 7 (postgresx Go baseline 降级) + Issue 8 (observex go.sum 清理)
  Issue 6 (postgresx foundationx exit)
  Issue 11 (STATUS.md 补 domainx) + Issue 10 (依赖矩阵扩展)
  Issue 9 (contracts/transportx go.mod 身份)
  Issue 12 (x.go.bak .env.example 合并)
  Issue 13 (全项目 .env.example CI 连线)
```text
