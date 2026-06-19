# clickhousex 完整验收清单

- Status: Updated from runtime release evidence
- Last-Updated: 2026-06-19
- Module-Version: v1.0.5
- Module-State: full client API 已验收；release / CI / Trust Alignment 已复验；非 factory
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/clickhousex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, /home/clickhousex/release/evidence/v1.0.5.md

> 本清单用于验收 clickhousex 是否达到可发布、可追溯、可复验状态。当前验收结论以运行时代码仓库 `/home/clickhousex` 的 `v1.0.5` release evidence、branch/tag CI 与本地复验输出为准。

## 0. v1.0.5 验收结论

- `/home/clickhousex` 的 `clickhousex` 分支已发布 `v1.0.5` tag/release（commit `10f06f82cb2f08809b5a135a0498f8eeb57806ed`）。
- GitHub Release 已发布：https://github.com/ZoneCNH/clickhousex/releases/tag/v1.0.5。
- 已通过本地命令：`GOWORK=off go test ./... -covermode=atomic -coverprofile=coverage.out`、`GOWORK=off go tool cover -func=coverage.out` 总覆盖率 `100.0%`、`GOWORK=off go test ./...`、`GOWORK=off go test -race ./...`、`GOWORK=off go vet ./...`、`GOWORK=off go build ./...`、`GOWORK=off golangci-lint run ./...` 与 `git diff --check`。
- 已对齐版本元数据：`VERSION`、`.repo-contract.yaml`、`pkg/clickhousex/version.go`、`CHANGELOG.md` 与 `release/manifest/latest.json` 均登记 `v1.0.5`。
- 已通过远端 GitHub Actions：branch run `27804922589` 的 quality、lint、integration、secret-scan 与 trust-alignment 均 success；tag run `27804934712` 的 quality、lint、integration、secret-scan、trust-alignment 与 release-check 均 success。
- 已通过 Trust Alignment：`xlibgate trust identity --repo .`、`xlibgate trust template-residue --repo .`、`xlibgate trust secret-redaction --repo . --path release/evidence` 均通过。
- 已确认无 `configx` 依赖。
- 对外客户端 API 已验收：`New`、`Close`、`CloseContext`、`Ping`、`Health`、`HealthCheck`、`Exec`、`Query`、`Rows`、`Rows.ColumnTypes`、`InsertBatch`、retry、metrics、tracing、logger 与错误映射。
- v1.0.5 不再保留 Exec/Query/InsertBatch/Rows/tracing/metrics 实现缺口；剩余缺口为外部 ClickHouse live/soak、正式 benchmark/profile 与 factory 归档证据，BLK-003 保持 open。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/clickhousex/FEATURES.md && test -f module/clickhousex/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- README.md module/README.md module/clickhousex/FEATURES.md module/clickhousex/ACCEPTANCE.md | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/clickhousex && GOWORK=off go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/clickhousex && GOWORK=off go test -race ./... | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/clickhousex && GOWORK=off go vet ./... | 无 vet 问题 |
| 编译检查 | cd /home/clickhousex && GOWORK=off go build ./... | 所有包编译通过 |
| Lint 检查 | cd /home/clickhousex && GOWORK=off golangci-lint run ./... | 零 lint issue |
| 覆盖率证据 | cd /home/clickhousex && GOWORK=off go test ./... -covermode=atomic -coverprofile=coverage.out && GOWORK=off go tool cover -func=coverage.out | 总覆盖率 100.0% |
| 版本元数据一致性 | cd /home/clickhousex && test "$(cat VERSION)" = "v1.0.5" && rg -n "v1.0.5" .repo-contract.yaml pkg/clickhousex/version.go CHANGELOG.md release/manifest/latest.json | runtime 版本源、契约、CHANGELOG 与 release manifest 均指向 v1.0.5 |
| 依赖边界 | cd /home/clickhousex && GOWORK=off go list -deps ./... | 输出不包含 `configx` |
| API 边界 | cd /home/clickhousex && rg -n "func \\(c \\*Client\\) (Exec|Query|InsertBatch|Ping|Close|CloseContext)|func \\(c \\*Client\\) Health|func \\(c \\*Client\\) HealthCheck|type Rows interface|func \\(.*ColumnTypes" pkg/clickhousex | 完整客户端 API 可定位，且与 FEATURES.md 登记一致 |
| Trust Alignment | cd /home/clickhousex && GOWORK=off xlibgate trust identity --repo . && GOWORK=off xlibgate trust template-residue --repo . && GOWORK=off xlibgate trust secret-redaction --repo . --path release/evidence | identity/template-residue/secret-redaction 均 pass |
| GitHub Actions branch gate | gh run view 27804922589 --repo ZoneCNH/clickhousex --json conclusion,status,jobs | branch run completed success；quality/lint/integration/secret-scan/trust-alignment success |
| GitHub Actions tag gate | gh run view 27804934712 --repo ZoneCNH/clickhousex --json conclusion,status,jobs | tag run completed success；quality/lint/integration/secret-scan/trust-alignment/release-check success |
| Release 对账 | gh release view v1.0.5 --repo ZoneCNH/clickhousex --json tagName,targetCommitish,publishedAt | tagName=v1.0.5，targetCommitish=10f06f82cb2f08809b5a135a0498f8eeb57806ed |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | NewClient 合法配置返回 Client, nil 错误 | 通过：`New`、`Config` 默认值/校验、native connector option adapter 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-002 | FR-001 | NewClient 空 DSN 返回配置错误 | 通过：空/非法配置、DSN sanitize 与错误包装已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-003 | FR-002 | Exec 正常 SQL 返回 nil | 通过：`Client.Exec` 成功路径、参数传递、metrics/tracing/logger 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-004 | FR-002 | Exec 语法错误返回包装后的 ClickHouse 错误 | 通过：driver error wrapping、operation detail 与 fallback 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-005 | FR-003, FR-007 | Query 有结果返回可迭代 Rows | 通过：`Client.Query`、`Rows.Next`、`Scan` 与 `Close` 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-006 | FR-003 | Query 无结果返回空 Rows 且 nil 错误 | 通过：空结果和 query setup cancellation 分支已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-007 | FR-004 | InsertBatch 正常写入返回 nil | 通过：native `PrepareBatch`/`Append`/`Send` path 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-008 | FR-004 | InsertBatch 空 rows 返回 nil | 通过：空 rows no-op 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-009 | FR-004 | InsertBatch 空 cols 返回 ErrEmptyColumns | 通过：空列校验已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-010 | FR-004 | InsertBatch 列数不匹配返回 ErrColumnCountMismatch | 通过：列数不匹配并含行号的错误路径已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-011 | FR-004, BR-010 | InsertBatch 表不存在返回 ErrTableNotFound，不自动建表 | 通过：native batch prepare error 映射覆盖；实现不自动建表 | TRACEABILITY.md, v1.0.5 evidence |
| AC-012 | FR-007 | Scan 列数不匹配返回 ErrColumnCountMismatch | 通过：scan 目标数量校验已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-013 | FR-007, BR-011 | Scan Nullable 列到非指针类型返回 ErrTypeMismatch | 通过：Nullable 非指针目标错误和指针路径已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-014 | FR-007, FR-008 | ColumnTypes 返回列名、ClickHouse 类型、Nullable 标志 | 通过：`Rows.ColumnTypes` 与 native row adapter 元数据转换已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-015 | FR-006, BR-009 | Close 幂等，多次调用不 panic | 通过：`Close` 与 `CloseContext` 重复调用、等待、取消和 deadline 分支已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-016 | FR-005 | Health 连接正常返回 Ready=true, Live=true | 通过：fake-driver/local healthy 状态已覆盖；外部 live 实例复验仍列为剩余缺口 | TRACEABILITY.md, v1.0.5 evidence |
| AC-017 | FR-005 | Health 连接异常返回 Ready=false, Live=false | 通过：closed、nil context、canceled、deadline 与 driver error 状态已覆盖；外部 live 异常演练仍列为剩余缺口 | TRACEABILITY.md, v1.0.5 evidence |
| AC-018 | BR-001 | 连接池默认 size=10, max=100，Config 可覆盖 | 通过：默认值、覆盖配置和非法配置校验已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-019 | BR-002 | 批量写入使用 ClickHouse 原生 batch insert 协议 | 通过：`InsertBatch` 使用 native batch adapter，不拼接 values SQL | TRACEABILITY.md, v1.0.5 evidence |
| AC-020 | BR-003 | SQL 参数使用占位符绑定，非字符串拼接 | 通过：`Exec`/`Query` 将 args 传递给 driver 调用；参数传递测试覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-021 | BR-004 | 连接断开后自动重试 3 次，超过后返回 ErrConnectionLost | 通过：默认 `RetryConfig`、retryable failures、wait cancellation 和 delay clamping 已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-022 | BR-005 | Health() 多次调用结果一致，无副作用 | 通过：多状态重复调用与关闭后健康状态已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-023 | BR-006 | ctx 取消/超时时操作中断并返回 ctx.Err() | 通过：`Exec`、`Query`、`InsertBatch`、`Ping`、`HealthCheck`、`CloseContext` context 分支已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-024 | BR-007 | 错误消息格式为 "clickhousex: <operation>: <detail>" | 通过：错误格式、fallback、wrapping、driver 错误映射与表不存在错误映射已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-025 | BR-008 | metrics 包含 table 标签或 query 标签 | 通过：query/write/pool 指标、operation/table/query 标签与 Noop metrics 分支已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| AC-026 | BR-012 | Decimal 类型映射到 decimal.Decimal，无精度丢失 | 通过：Decimal 目标类型校验和精度保护路径已覆盖 | TRACEABILITY.md, v1.0.5 evidence |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-002, FR-003, FR-004, FR-007, BR-003 | InsertBatch 写入后 Query 返回对应结果 | 通过：fake-driver 单元测试覆盖 insert/query/rows/args 主链路；branch/tag integration job success；外部长跑 live 仍列为剩余缺口 | TRACEABILITY.md, v1.0.5 evidence |
| TC-002 | FR-002, BR-004 | ClickHouse 临时不可达时 Exec 返回 ErrConnectionLost，恢复后自动重连 | 通过：retryable connection failure、重试次数、错误映射和恢复成功路径已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| TC-003 | FR-004, BR-002 | 100000 行 InsertBatch 使用 batch insert 协议且满足性能目标 | 部分通过：native batch 协议和列校验已覆盖；100000 行 <1s 正式 benchmark 尚未归档 | TRACEABILITY.md, v1.0.5 evidence |
| TC-004 | FR-007, FR-008, BR-011 | Nullable(Int32) NULL 行 Scan 到 *int32 为 nil | 通过：Nullable 指针语义、非指针错误与 ColumnTypes 元数据已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| TC-005 | FR-001 | DSN 缺失或格式非法时创建失败且不建立连接 | 通过：Config validate、DSN sanitize 与 native connector 初始化分支已覆盖 | TRACEABILITY.md, v1.0.5 evidence |
| TC-006 | FR-005, BR-005 | Health 正常和失败状态均正确 | 通过：healthy、closed、nil context、canceled、deadline 与 driver error 已覆盖；外部 live/soak 仍列为剩余缺口 | TRACEABILITY.md, v1.0.5 evidence |
| TC-007 | FR-006, BR-009 | client 已关闭后再次 Close 返回 nil 且不 panic | 通过：`Close` / `CloseContext` 幂等、等待与取消分支已覆盖 | TRACEABILITY.md, v1.0.5 evidence |

## 4. 覆盖闭合验收

| 覆盖对象 | 验收结论 |
| --- | --- |
| FR-001..FR-008 | 通过：完整客户端 API 已由 v1.0.5 运行时代码、单元测试、fake-driver 覆盖和 release evidence 闭合 |
| BR-001..BR-012 | 通过：配置、原生 batch、参数绑定、retry、context、错误、metrics/tracing/logger、Nullable/Decimal 均有证据 |
| NFR-001..NFR-007 | 待补：正式 benchmark/profile 证据尚未归档；不阻塞 v1.0.5 client API release，factory 前必须补齐 |
| NFR-008..NFR-018 | 通过：coverage/build/race/vet/lint/secret/trust/dependency/CI/release/observability 证据已闭合；外部 live 仅作为剩余缺口登记 |

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/clickhousex 通过 go test、go test -race、go vet、go build、golangci-lint、覆盖率门槛、Trust Alignment 与 branch/tag CI。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据；GitHub Actions integration job 已通过，外部 ClickHouse live/soak 仍作为剩余缺口登记。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码；branch/tag secret-scan 与 xlibgate secret-redaction 均通过。
- [x] 版本号、发布标签、CHANGELOG、release manifest、GitHub Release 与本目录状态一致。
- [ ] 外部 ClickHouse live/soak、正式 benchmark/profile 与 factory 归档证据仍待补齐；BLK-003 保持 open。

## 6. 当前缺口登记

- `v1.0.5` 已闭合完整客户端 API、测试覆盖率、CI、Trust Alignment 与 GitHub Release 证据，不再保留 `Exec`、`Query`、`InsertBatch`、`Rows`、metrics 或 tracing 的实现缺口。
- 外部 ClickHouse live/soak、正式 benchmark/profile 与 factory 归档证据仍待补齐。
- BLK-003 / factory 状态保持 open；进入 factory 前必须补充正式 benchmark/profile 和外部 live/soak 证据。
- 远端 CI 有非阻塞 runner 注释：Node.js 20 deprecation 与 setup-go cache warning；不影响 branch/tag job success。
