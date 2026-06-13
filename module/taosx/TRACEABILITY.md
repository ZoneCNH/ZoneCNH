# taosx 追溯矩阵

Last-Updated: 2026-06-13
Source: `module/taosx/SPEC.md`, `/home/taosx/pkg/taosx`

本矩阵追踪中心规格与 `/home/taosx` 当前实现之间的契约关系。`taosx` v1.0.0 定位为 TDengine L2 存储适配器契约：公共核心 API 保持驱动注入边界，官方 `taosWS` WebSocket driver 通过显式 opt-in 集成测试验证；核心包仍不是内置连接池、STMT 或自动重试的平台模块。

## 功能需求追溯

| ID | Spec 需求 | 实现/证据 | 状态 |
| --- | --- | --- | --- |
| FR-001 | `Config.Normalize` 补齐默认名称、驱动模式和零值超时时间。 | `/home/taosx/pkg/taosx/config.go`, `/home/taosx/pkg/taosx/config_test.go`, `/home/taosx/contracts/config.schema.json` | Done |
| FR-002 | `Config.Validate` 拒绝缺失名称、endpoint、database、非法 driver mode、负 timeout、负 max retries。 | `/home/taosx/pkg/taosx/config.go`, `/home/taosx/pkg/taosx/config_test.go`, `/home/taosx/contracts/contracts_test.go` | Done |
| FR-003 | `New` 校验 context、配置和 options，默认驱动显式不可用。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/options.go`, `/home/taosx/pkg/taosx/client_test.go`, `/home/taosx/README.md` | Done |
| FR-004 | `Exec` 校验非空 SQL statement 并委托驱动。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/sql.go`, `/home/taosx/pkg/taosx/client_test.go` | Done |
| FR-005 | `Query` 校验非空查询并返回驱动提供的 `Rows`。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/sql.go`, `/home/taosx/pkg/taosx/fake.go`, `/home/taosx/pkg/taosx/client_test.go` | Done |
| FR-006 | `WriteBatch` 校验 database、table、timestamp、fields 和 points；空 batch 是 validation error。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/batch.go`, `/home/taosx/pkg/taosx/write_test.go` | Done |
| FR-007 | `SchemalessWrite` 校验 lines、协议和精度。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/schemaless.go`, `/home/taosx/pkg/taosx/write_test.go`, `/home/taosx/contracts/schemaless_failure_contract.md` | Done |
| FR-008 | `Health` 调用 `Driver.Health(ctx) error` 并映射为 `HealthStatus`；默认不可用驱动 degraded。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/health.go`, `/home/taosx/pkg/taosx/health_test.go`, `/home/taosx/contracts/health.schema.json` | Done |
| FR-009 | `Close` 幂等并接受 context；关闭后业务操作返回 closed 错误。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/client_test.go` | Done |
| FR-010 | metrics 端口可选，默认 no-op，注入后记录 `taosx_client_*` 指标。 | `/home/taosx/pkg/taosx/metrics.go`, `/home/taosx/pkg/taosx/options.go`, `/home/taosx/pkg/taosx/client_test.go`, `/home/taosx/contracts/metrics.contract.yaml` | Done |
| FR-011 | 官方 `taosWS` WebSocket 集成测试必须显式 opt-in、环境变量配置且凭据脱敏。 | `/home/taosx/pkg/taosx/integration_tdengine_test.go`, `/home/taosx/docs/testing.md`, `/home/taosx/go.mod` | Done |

## 行为约束追溯

| ID | 约束 | 证据 | 状态 |
| --- | --- | --- | --- |
| BR-001 | 直接 foundation 依赖只允许 `kernel`，不得声明直接依赖 `configx`、`observex`、`resiliencx`。 | `module/FOUNDATION-DEPS.yaml` (`taosx: [kernel]`), `/home/taosx/go.mod` | Done |
| BR-002 | 所有外部操作接受 `context.Context`。 | `/home/taosx/pkg/taosx/client.go`, `/home/taosx/contracts/public_api.snapshot` | Done |
| BR-003 | 错误分类使用 `taosx.<Operation>` 且输出脱敏。 | `/home/taosx/pkg/taosx/errors.go`, `/home/taosx/pkg/taosx/config.go`, `/home/taosx/docs/errors.md` | Done |
| BR-004 | `MaxRetries` 是配置契约保留字段，不代表核心 client 自动重试。 | `/home/taosx/pkg/taosx/config.go`, `/home/taosx/pkg/taosx/client.go`, `/home/taosx/docs/api.md`, `/home/taosx/docs/config.md` | Done |
| BR-005 | 默认驱动必须显式不可用，避免零配置被误认为真实 TDengine 连接。 | `/home/taosx/pkg/taosx/options.go`, `/home/taosx/pkg/taosx/client.go`, `/home/taosx/pkg/taosx/client_test.go` | Done |
| BR-006 | 原始 SQL 只做空值校验，不声明注入防护。 | `/home/taosx/pkg/taosx/sql.go`, `/home/taosx/docs/api.md` | Done |
| BR-007 | 真实集成测试不得进入默认测试路径，且失败输出不得包含 DSN、用户名或密码。 | `/home/taosx/pkg/taosx/integration_tdengine_test.go`, `/home/taosx/docs/testing.md` | Done |

## 已知缺口 / 后续范围

- `MaxRetries` 仍是配置契约字段，核心 client 不自动重试；未来如实现 retry，必须新增需求、测试和依赖边界说明。
- 连接池策略、STMT 写入、性能压测和业务级时序模型仍属后续版本范围。
- 真实 TDengine 集成测试依赖本地 dev 环境，不进入默认 `go test ./...`；发布前必须显式运行 `integration` tag。
