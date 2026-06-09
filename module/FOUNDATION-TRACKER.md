# Foundation v1 执行跟踪器

> 源自 `FOUNDATION-V1.md` 的 P0/P1/P2 issue 拆分。
> 每项直接对应一个 GitHub Issue 或 PR。
> 勾选 = 完成。

最后更新：2026-06-09

---

## P0：身份和边界修复

> 阻塞所有后续工作。必须先完成。

### Issue 1：resiliencx identity reset ✅

```text
标题：Redefine resiliencx as runtime resilience policy library
仓库：ZoneCNH/resiliencx
```text

- [ ] README 重写：删除 Standard Source / Generator / Harness 叙事
- [ ] README 重写：明确身份为 runtime resilience policy library
- [ ] 新增 `docs/identity.md`
- [ ] 新增 `docs/boundary.md`（与 xlib-standard 的边界）
- [ ] 新增最小 API：`policy.go` / `runner.go` / `operation.go`
- [ ] 新增策略实现：`timeout.go` / `retry.go` / `circuit.go`
- [ ] 新增策略实现：`bulkhead.go` / `ratelimit.go` / `fallback.go`
- [ ] 新增 `classifier.go`（retryable / non-retryable / fatal）
- [ ] 新增 `idempotency.go`（非幂等操作禁止自动 retry）
- [ ] 新增 `event.go`（策略事件 sink）
- [ ] 新增 `noop.go`（未配置时安全运行）
- [ ] 新增 `options.go`（Option 模式配置）
- [ ] 删除或迁移 `xlib-standard` 相关的模板/generator/harness 代码
- [ ] 更新 `go.mod`：移除不必要的依赖
- [ ] 测试覆盖 ≥ 80%

### Issue 2：Foundation dependency matrix ✅

```text
标题：Add machine-readable Foundation dependency matrix
仓库：ZoneCNH/ZoneCNH（本文档仓库）
```text

- [x] 新增 `module/FOUNDATION-DEPS.yaml`（已完成）
- [x] CI 中增加 `check-deps.sh` 脚本（已完成，deps-matrix.yml）（从 yaml 解析）
- [ ] CI 中增加 kernel stdlib-only 检查
- [ ] CI 中增加 testkitx production import 检查
- [ ] CI 中增加反向依赖检查
- [ ] README 或 AGENTS 中引用此矩阵

### Issue 3：Go baseline alignment ✅

```text
标题：Align Foundation Go baseline to 1.23
仓库：所有 6 个模块
```text

- [ ] `kernel` go.mod 确认 Go 1.23
- [ ] `configx` go.mod 确认 Go 1.23
- [ ] `observex` go.mod 确认 Go 1.23
- [ ] `resiliencx` go.mod 确认 Go 1.23
- [ ] `schedulex` go.mod 确认 Go 1.23
- [ ] `testkitx` go.mod 降级到 Go 1.23（当前是 1.24）
- [ ] 所有 CI matrix 使用相同 Go 版本
- [ ] README / AGENTS / Release docs 同步

### Issue 4：foundationx compatibility exit plan ✅

```text
标题：Define and start foundationx compatibility exit
仓库：ZoneCNH/configx, ZoneCNH/observex
```text

- [x] ADR 已编写：`module/ADR-foundationx-exit.md`（已完成）
- [ ] `configx`：列出所有 foundationx 用法和替代方案
- [ ] `observex`：列出所有 foundationx 用法和替代方案
- [ ] `configx`：冻结，不再新增 foundationx usage
- [ ] `observex`：冻结，不再新增 foundationx usage
- [ ] CI 中增加 foundationx 新增用法检查
- [ ] `configx` v0.3 前完成迁移
- [ ] `observex` v0.4 前完成迁移
- [ ] 迁移完成后删除 `internal/foundationx`

---

## P1：每个模块补最小 v1 能力

> P0 完成后开始。每个模块独立，可并行。

### kernel ✅ (PR #9 合入)

- [x] public API snapshot 文件（`contracts/public_api/kernel_v0.schema.json`）
- [x] primitive admission gate（`scripts/check-admission.sh` + `contracts/admitted_packages.txt`）
- [x] stdlib-only CI check（`scripts/check-stdlib-only.sh`）
- [x] no-hidden-goroutine CI check（`scripts/check-no-goroutine.sh`）
- [x] `retryx` 限界文档（`pkg/retryx/BOUNDARY.md`）
- [x] `obsx` 限界文档（`pkg/obsx/BOUNDARY.md`）
- [x] API freeze 声明（`contracts/public_api/FREEZE.md`）

### configx ✅ (PR #1 + #2 合入)

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

### testkitx ⬜

- [ ] production import boundary scanner 稳定 API
- [ ] fake clock 确定性示例
- [ ] golden update guard（`TESTKITX_UPDATE_GOLDEN=1` 控制）
- [ ] release manifest fixture
- [ ] goroutine leak checker 加固
- [ ] 统一 assert API（`assertx` 包）
- [ ] 统一 fixture loader
- [ ] 统一 contract hash helper

### resiliencx ✅ (PR #15 + #16 合入)

> Issue 1（身份修复）已完成

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
- [ ] fake-clock 测试
- [ ] circuit breaker 状态转换测试
- [ ] bulkhead 并发安全测试
- [ ] 策略链集成测试

### schedulex ⬜

- [ ] DST/timezone golden test
- [ ] misfire contract test（skip/run_once/catch_up）
- [ ] overlap contract test（skip/queue_one/allow）
- [ ] lock interface contract（`Locker` 接口行为规范）
- [ ] event sink schema（`JobEvent` 结构规范）
- [ ] shutdown leak test
- [ ] shutdown race test
- [ ] trigger determinism test（相同 clock → 相同 next time）
- [ ] 和 resiliencx 的集成示例（job wrapper pattern）

---

## P2：Foundation example 闭环

> P1 核心能力完成后开始。

### Issue：foundation-example vertical smoke ⬜

```text
标题：Add foundation-example vertical smoke
仓库：新建 ZoneCNH/foundation-example 或放在 docs/example/
```text

- [ ] demo app 启动和关闭
- [ ] configx 加载 env + yaml + override
- [ ] observex 注入 memory logger/metrics/tracer
- [ ] kernel lifecycx 管理 start/stop
- [ ] resiliencx 包裹 fake external API
- [ ] schedulex 每 1s 调度一次 job（fake clock）
- [ ] testkitx fake clock + golden + boundary + leak
- [ ] release manifest 生成
- [ ] 所有 `make` target 可运行
- [ ] CI 全绿

---

## 进度汇总

| 优先级 | Issue 数 | 完成 | 进度 |
|---|---|---|---|
| P0 | 4 | 4 | ████ |
| P1 | 6 模块 | 4（kernel/configx/observex/resiliencx） | ███░ |
| P2 | 1 | 0 | ░░░░ |
| **总计** | **11** | **8** | **████** |

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
```text
