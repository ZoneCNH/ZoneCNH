# assembly 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: `patches/assembly/assembly.go`
Runtime: `github.com/ZoneCNH/runtime-patches/assembly`

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | TC ID(s) | Task | Verification | Status |
| ----- | ----------- | -------- | ---- | ------------ | ------ |
| FR-ASM-001 | ServerDeps — 收集所有依赖（Feed/Validator/Idempotency/Dispatcher/Config）用于构造 ingest server | TC-ASM-001 | TASK-ASM-001 | `go test ./... -run TestServerDeps` | ✅ |
| FR-ASM-002 | Validate — 检查所有必需依赖非 nil，返回聚合错误（errors.Join） | TC-ASM-002 | TASK-ASM-002 | `go test ./... -run TestServerDepsValidate` | ✅ |
| FR-ASM-003 | Assemble — 按序应用中间件链到各依赖，返回组装后的 ServerDeps | TC-ASM-003 | TASK-ASM-003 | `go test ./... -run TestAssemble` | ✅ |
| FR-ASM-004 | Build — 组装 deps + 构造 server 一步完成，委托 Assemble + constructor | TC-ASM-004 | TASK-ASM-004 | `go test ./... -run TestBuild` | ✅ |
| FR-ASM-005 | NopMiddleware — 透传所有依赖不变，实现 ValidatorMiddleware + IdempotencyMiddleware + DispatchMiddleware | TC-ASM-005 | TASK-ASM-005 | `go test ./... -run TestNopMiddleware` | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
| ----- | ---- | -------- | ---- | ------------ | ------ |
| BR-ASM-001 | 中间件链顺序保持：先注册的先应用（WrapValidator/WrapIdempotency/WrapDispatcher 按 middleware slice 顺序） | TC-ASM-003 | TASK-ASM-006 | ordered middleware test | ✅ |
| BR-ASM-002 | nil middleware 安全跳过，不 panic 不修改链 | TC-ASM-003 | TASK-ASM-007 | nil middleware test | ✅ |
| BR-ASM-003 | ServerDeps.Validate 失败时 Assemble 返回 wrapped error，不继续组装 | TC-ASM-002 | TASK-ASM-008 | validation failure test | ✅ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Verification | Status |
| ------ | -------- | ----------- | ---- | ------------ | ------ |
| NFR-ASM-001 | 编译安全 | NopMiddleware 编译期通过接口合规断言（`var _ ValidatorMiddleware = (*NopMiddleware)(nil)` 等 3 个） | TASK-ASM-009 | `go build ./...` | ✅ |
| NFR-ASM-002 | 依赖边界 | 仅依赖 `runtime-patches/binance` + `runtime-patches/binancex`，不引入外部框架 | TASK-ASM-010 | `go list -deps` | ✅ |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-ASM-001 | FR-ASM-001 | `go test ./... -run TestServerDeps` |
| TC-ASM-002 | FR-ASM-002, BR-ASM-003 | `go test ./... -run TestServerDepsValidate` |
| TC-ASM-003 | FR-ASM-003, BR-ASM-001, BR-ASM-002 | `go test ./... -run TestAssemble` |
| TC-ASM-004 | FR-ASM-004 | `go test ./... -run TestBuild` |
| TC-ASM-005 | FR-ASM-005 | `go test ./... -run TestNopMiddleware` |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-ASM-001 | FR-ASM-001 | ServerDeps 含全部 5 个依赖字段，类型正确 | TC-ASM-001 | ✅ |
| AC-ASM-002 | FR-ASM-002, BR-ASM-003 | Validate 对 nil Feed/Validator/Idempotency/Dispatcher 返回聚合 error | TC-ASM-002 | ✅ |
| AC-ASM-003 | FR-ASM-003, BR-ASM-001, BR-ASM-002 | Assemble 按序应用中间件，nil 中间件跳过 | TC-ASM-003 | ✅ |
| AC-ASM-004 | FR-ASM-004 | Build 委托 Assemble + constructor，失败时返回错误 | TC-ASM-004 | ✅ |
| AC-ASM-005 | FR-ASM-005, NFR-ASM-001 | NopMiddleware 编译期满足 3 个 Middleware 接口 | TC-ASM-005 | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 5 | 5 | 100% |
| BR (业务规则) | 3 | 3 | 100% |


| NFR (非功能需求) | 2 | 2 | 100% |
| AC (验收标准) | 5 | 5 | 100% |
| TC (测试用例) | 5 | 5 | 100% |
| **合计** | **20** | **20** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 `patches/assembly/assembly.go` 提取 FR/BR/NFR，创建完整 §1-§7 追溯矩阵 |
