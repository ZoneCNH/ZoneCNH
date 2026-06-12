# taosx 追溯矩阵

Last-Updated: 2026-06-12
Source: `module/taosx/SPEC.md`, `/home/taosx/pkg/taosx`

本矩阵追踪中心规格与 `/home/taosx` 当前实现之间的契约关系。`taosx` 当前定位为 TDengine L2 存储适配器契约，不是内置真实 TDengine 驱动、连接池、STMT 或自动重试的平台模块。

## 功能需求追溯

| ID | Spec 需求 | 实现/证据 | 状态 |
| --- | --- | --- | --- |
| FR-001 | `Config.Normalize` 补齐默认名称、驱动模式和零值超时时间。 | `/home/taosx/pkg/taosx/config.go`, `/home/taosx/pkg/taosx/config_test.go`, `/home/taosx/contracts/config.schema.json` | ✅ 已实现 |
| FR-002 | `Config.Validate` 拒绝缺失名称、endpoint、database、非法 driver mode、负 timeout、负 max retries。 | `/home/taosx/pkg/taosx/config.go`, `/home/taosx/pkg/taosx/config_test.go`, `/home/taosx/contracts/contracts_test.go` | ✅ 已实现 |
| FR-003 | `New` 校验 context、配置和 options，默认驱动显式不可用。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/options.go`, `/home/taosx/pkg/taosx/client_test.go`, `/home/taosx/README.md` | ✅ 已实现 |
| FR-004 | `Exec` 校验非空 SQL statement 并委托驱动。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/sql.go`, `/home/taosx/pkg/taosx/client_test.go` | ✅ 已实现 |
| FR-005 | `Query` 校验非空查询并返回驱动提供的 `Rows`。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/sql.go`, `/home/taosx/pkg/taosx/fake.go`, `/home/taosx/pkg/taosx/client_test.go` | ✅ 已实现 |
| FR-006 | `WriteBatch` 校验 database、table、timestamp、fields 和 points；空 batch 是 validation error。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/batch.go`, `/home/taosx/pkg/taosx/write_test.go` | ✅ 已实现 |
| FR-007 | `SchemalessWrite` 校验 lines、协议和精度。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/schemaless.go`, `/home/taosx/pkg/taosx/write_test.go`, `/home/taosx/contracts/schemaless_failure_contract.md` | ✅ 已实现 |
| FR-008 | `Health` 调用 `Driver.Health(ctx) error` 并映射为 `HealthStatus`；默认不可用驱动 degraded。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/health.go`, `/home/taosx/pkg/taosx/health_test.go`, `/home/taosx/contracts/health.schema.json` | ✅ 已实现 |
| FR-009 | `Close` 幂等并接受 context；关闭后业务操作返回 closed 错误。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/client_test.go` | ✅ 已实现 |
| FR-010 | metrics 端口可选，默认 no-op，注入后记录 `taosx_client_*` 指标。 | `/home/taosx/pkg/taosx/metrics.go`, `/home/taosx/pkg/taosx/options.go`, `/home/taosx/pkg/taosx/client_test.go`, `/home/taosx/contracts/metrics.contract.yaml` | ✅ 已实现 |

## 行为约束追溯

| ID | 约束 | 证据 | 状态 |
| --- | --- | --- | --- |
| BR-001 | 直接 foundation 依赖只允许 `kernel`，不得声明直接依赖 `configx`、`observex`、`resiliencx`。 | `module/FOUNDATION-DEPS.yaml` (`taosx: [kernel]`), `/home/taosx/go.mod` | ✅ 已锁定 |
| BR-002 | 所有外部操作接受 `context.Context`。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/contracts/public_api.snapshot` | ✅ 已实现 |
| BR-003 | 错误分类使用 `taosx.<Operation>` 且输出脱敏。 | `/home/taosx/pkg/taosx/errors.go`, `/home/taosx/pkg/taosx/config.go`, `/home/taosx/docs/errors.md` | ✅ 已实现 |
| BR-004 | `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试。 | `/home/taosx/pkg/taosx/config.go`, `/home/taosx/pkg/taosx/client.go`, `/home/taosx/docs/api.md`, `/home/taosx/docs/config.md` | ✅ 已锁定 |
| BR-005 | 默认驱动必须显式不可用，避免零配置被误认为真实 TDengine 连接。 | `/home/taosx/pkg/taosx/options.go`, `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/client_test.go` | ✅ 已实现 |
| BR-006 | 原始 SQL 只做空值校验，不声明注入防护。 | `/home/taosx/pkg/taosx/sql.go`, `/home/taosx/docs/api.md` | ✅ 已锁定 |

## 已知缺口 / 后续范围

- 尚未接入真实 TDengine driver；这是当前非目标，不应被中心文档描述为已完成能力。
- `MaxRetries` 仍是配置契约字段，核心 client 不自动重试；未来如实现 retry，必须新增需求、测试和依赖边界说明。
- 真实 TDengine 集成测试、性能压测、连接池策略、STMT 写入和业务级时序模型属于后续版本范围。
