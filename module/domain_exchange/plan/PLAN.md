# domain_exchange v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `domain_exchange` |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | `decimalx`、`domain_market`、`domainx` 之后 |
| 最后更新 | 2026-06-16 |

## 里程碑

| 里程碑 | 内容 | 退出条件 | 任务 |
| --- | --- | --- | --- |
| M0 SPI Freeze | 冻结 Exchange vs domainx/domain_market 边界，拆分 SPI 能力接口 | ADR/SPEC Approved，7 个能力接口 + Exchange 组合接口编译通过 | TASK-EXC-001 |
| M1 核心接口 | Place/Cancel/Query request 与 idempotency 语义；ExchangeError 分类与 retry 语义 | request validation 测试通过，error table tests 完成 | TASK-EXC-002, TASK-EXC-003 |
| M2 验证资产 | VenueCapability、RateLimitPolicy、VenueProfile 静态声明；domainx/domain_market 类型边界验证 | capability tests 通过，boundary scan 通过，无重复类型定义 | TASK-EXC-004, TASK-EXC-006, TASK-EXC-007 |
| M3 Adapter Smoke | Registry 线程安全、fake exchange 注入、并发测试 | race/concurrency 测试通过，fake exchange 覆盖成功/拒单/限频/partial fill/stream close | TASK-EXC-005 |
| M4 发布 | docs、CI gate、MIGRATION.md、release manifest | tag v1.0.0 前门禁全部通过 | — |

### M0 SPI Freeze

**目标**：确定 Exchange SPI 与 domainx/domain_market 的边界，冻结接口拆分方案。

**任务**：TASK-EXC-001（spi-segmentation）

**交付物**：
- `exchange.go`：7 个能力接口 + Exchange 组合接口
- `venue.go`：Venue、Capability、VenueProfile 类型
- `exchange_test.go`：编译期检查

**退出条件**：
- `go build ./...` 通过
- 7 个能力接口方法签名与 SPEC §9 一致
- ADR 记录接口拆分决策

**风险**：接口签名与下游不匹配 → 对照 SPEC §9 验证

---

### M1 核心接口

**目标**：实现请求类型与错误分类，确保 idempotency 和 retry 语义完整。

**任务**：TASK-EXC-002（place/cancel/query request）+ TASK-EXC-003（error classification）

**交付物**：
- `request.go`：PlaceOrderRequest、CancelOrderRequest、QueryOrderRequest + Validate()
- `errors.go`：ExchangeError 类型体系 + IsRetryable/RetryAfter/IsIdempotentSafe
- `request_test.go`、`errors_test.go`

**退出条件**：
- PlaceOrderRequest.Validate() 拒绝空 ClientID
- 错误可分类为 retryable / non-retryable / auth / rate limit
- errors.Is/As 可识别所有 typed error

**风险**：Validate 规则与实际交易所约束不一致 → 参照 SPEC §13

---

### M2 验证资产

**目标**：确保 capability 可静态声明、类型边界正确、无重复 SSOT。

**任务**：TASK-EXC-004（capability/profile/rate-limit）+ TASK-EXC-006（market-reader boundary）+ TASK-EXC-007（domainx adoption）

**交付物**：
- `capability.go`：Capability 常量 + RateLimitPolicy
- `config.go`：VenueProfile YAML 加载
- `boundary_test.go`：domain_market 类型边界验证
- `alias.go`（如需）：deprecated alias
- `adoption_test.go`：domainx 类型采纳验证

**退出条件**：
- VenueProfile 可从 YAML 配置加载
- 不支持的 capability 返回 ErrUnsupportedCapability
- MarketReader 返回 domain_market 类型，无本地重复
- Order/ExecutionReport 返回 domainx 类型，无本地重复

**风险**：domainx/domain_market 接口变更 → 依赖 v1.0.0 稳定版

---

### M3 Adapter Smoke

**目标**：Registry 并发安全，fake exchange 可注入，下游可 smoke。

**任务**：TASK-EXC-005（registry thread-safe + fake exchange）

**交付物**：
- `registry.go`：线程安全 Registry
- `fake/exchange.go`：fake exchange（脚本化响应、延迟、错误、乱序 stream、partial fill）
- `registry_test.go`：并发测试 + deterministic 测试

**退出条件**：
- `go test -race ./...` 通过
- 重复注册返回错误
- 列表排序 deterministic
- fake exchange 覆盖成功、拒单、限频、partial fill、stream close

**风险**：并发竞争条件遗漏 → `go test -race -count=100`

---

### M4 发布

**目标**：完成发布前所有门禁，tag v1.0.0。

**交付物**：
- CHANGELOG.md
- MIGRATION.md（deprecated alias 迁移路径）
- release manifest
- CI gate 全部通过

**退出条件**：
- SPEC Approved
- 所有 FR 实现并测试
- CI gate 通过：`go test ./...`、`go test -race ./...`、`staticcheck ./...`、`govulncheck ./...`
- Version 更新为 v1.0.0
- CHANGELOG.md、MIGRATION.md、release manifest 齐全

---

## PR 类别

| 类别 | 目的 | 里程碑 |
| --- | --- | --- |
| docs-v1-contract | 明确 SPI、边界、能力、错误和迁移路线 | M0 |
| api-v1-freeze | 拆分 Exchange interface，冻结 request/error/capability | M0-M1 |
| invariant-tests | 覆盖 idempotency、retry、rate limit、registry 并发 | M1-M3 |
| ci-release-gates | 加入 boundary scan、race、staticcheck、govulncheck | M3-M4 |
| release-v1.0.0 | 发布 tag、release notes 与 manifest | M4 |

## 任务依赖图

```text
TASK-EXC-001 (SPI Freeze)
  ├── TASK-EXC-002 (Request + Idempotency)
  │     └── TASK-EXC-007 (domainx Adoption)
  ├── TASK-EXC-003 (Error Classification)
  │     └── TASK-EXC-004 (Capability + Profile)
  │           └── TASK-EXC-005 (Registry + Fake Exchange)
  └── TASK-EXC-006 (MarketReader Boundary)
```
