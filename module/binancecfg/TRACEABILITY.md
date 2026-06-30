# binancecfg 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: `patches/binancecfg/config.go`
Runtime: `github.com/ZoneCNH/runtime-patches/binancecfg`

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | TC ID(s) | Task | Verification | Status |
| ----- | ----------- | -------- | ---- | ------------ | ------ |
| FR-BCFG-001 | LoadConfig — 从 `FOUNDATIONX_BINANCE_*` 环境变量读取类型化配置，未设置字段回退到 DefaultConfig | TC-BCFG-001 | TASK-BCFG-001 | `go test ./... -run TestLoadConfig` | ✅ |
| FR-BCFG-002 | DefaultConfig — 返回生产安全默认值，所有 duration 使用保守值 | TC-BCFG-002 | TASK-BCFG-002 | `go test ./... -run TestDefaultConfig` | ✅ |
| FR-BCFG-003 | Validate — 校验 Config 字段合法性，拒绝零值/负值，委托 binancex.FeedConfig.Validate | TC-BCFG-003 | TASK-BCFG-003 | `go test ./... -run TestValidate` | ✅ |
| FR-BCFG-004 | ServerConfig 转换 — Config → binance.ServerConfig 映射 5 个字段 | TC-BCFG-004 | TASK-BCFG-004 | `go test ./... -run TestServerConfig` | ✅ |
| FR-BCFG-005 | FeedConfig 转换 — Config → binancex.FeedConfig 映射 9 个字段 | TC-BCFG-005 | TASK-BCFG-005 | `go test ./... -run TestFeedConfig` | ✅ |
| FR-BCFG-006 | parseDurationEnv / parseIntEnv — 安全解析环境变量，非法值记录 warn 日志并使用默认值 | TC-BCFG-006 | TASK-BCFG-006 | `go test ./... -run TestParseEnv` | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
| ----- | ---- | -------- | ---- | ------------ | ------ |
| BR-BCFG-001 | 所有配置仅来自 `FOUNDATIONX_BINANCE_*` 环境变量 + DefaultConfig 回退，不读取文件或配置中心 | TC-BCFG-001 | TASK-BCFG-007 | env var coverage test | ✅ |
| BR-BCFG-002 | 非法环境变量值记录 structured log warning 并使用默认值，绝不 panic 或 os.Exit | TC-BCFG-006 | TASK-BCFG-008 | invalid env test | ✅ |
| BR-BCFG-003 | Validate 拒绝 MaxStreams <= 0、DrainTimeout <= 0、ShutdownTimeout <= 0 | TC-BCFG-003 | TASK-BCFG-009 | validation edge case test | ✅ |
| BR-BCFG-004 | binancecfg 与 cmd/ 分离：配置加载可独立测试和复用 | TC-BCFG-001 | TASK-BCFG-007 | package boundary check | ✅ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Verification | Status |
| ------ | -------- | ----------- | ---- | ------------ | ------ |
| NFR-BCFG-001 | 可测试性 | 不依赖外部系统，所有函数接受显式参数或环境变量，可纯单元测试 | TASK-BCFG-010 | `go test ./... -count=1` | ✅ |
| NFR-BCFG-002 | 依赖边界 | 仅依赖 stdlib + `runtime-patches/binance` + `runtime-patches/binancex`，不引入第三方库 | TASK-BCFG-011 | `go list -deps` | ✅ |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-BCFG-001 | FR-BCFG-001, BR-BCFG-001, BR-BCFG-004 | `go test ./... -run TestLoadConfig` |
| TC-BCFG-002 | FR-BCFG-002 | `go test ./... -run TestDefaultConfig` |
| TC-BCFG-003 | FR-BCFG-003, BR-BCFG-003 | `go test ./... -run TestValidate` |
| TC-BCFG-004 | FR-BCFG-004 | `go test ./... -run TestServerConfig` |
| TC-BCFG-005 | FR-BCFG-005 | `go test ./... -run TestFeedConfig` |
| TC-BCFG-006 | FR-BCFG-006, BR-BCFG-002 | `go test ./... -run TestParseEnv` |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-BCFG-001 | FR-BCFG-001 | LoadConfig 所有 13 个 env var 正确映射，未设置时使用 DefaultConfig 值 | TC-BCFG-001 | ✅ |
| AC-BCFG-002 | FR-BCFG-002 | DefaultConfig 返回非零值，WS endpoint 指向 wss://stream.binance.com:9443/ws | TC-BCFG-002 | ✅ |
| AC-BCFG-003 | FR-BCFG-003 | Validate 拒绝 MaxStreams=0、DrainTimeout=0、ShutdownTimeout=0；委托 FeedConfig.Validate | TC-BCFG-003 | ✅ |
| AC-BCFG-004 | FR-BCFG-004~005 | ServerConfig() 和 FeedConfig() 字段一一映射无遗漏 | TC-BCFG-004, TC-BCFG-005 | ✅ |
| AC-BCFG-005 | FR-BCFG-006, BR-BCFG-002 | 非法 duration/int env 值不 panic，记录 warn log | TC-BCFG-006 | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 6 | 6 | 100% |
| BR (业务规则) | 4 | 4 | 100% |


| NFR (非功能需求) | 2 | 2 | 100% |
| AC (验收标准) | 5 | 5 | 100% |
| TC (测试用例) | 6 | 6 | 100% |
| **合计** | **23** | **23** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 `patches/binancecfg/config.go` 提取 FR/BR/NFR，创建完整 §1-§7 追溯矩阵 |
