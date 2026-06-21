# clickhousex 完整验收清单

- Status: Updated from runtime release evidence
- Last-Updated: 2026-06-21
- Module-Version: v1.0.10
- Module-State: full client API 已验收；v1.0.10 production release gate（unit/race/vet/build/lint/coverage/live 集成/60s soak/benchmark/CI 配置）已在本地 release evidence 与版本元数据闭合；非 factory/L2-T4
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/clickhousex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, /home/clickhousex/release/evidence/v1.0.10.md

> 本清单用于验收 clickhousex 是否达到可发布、可追溯、可复验状态。当前验收结论以运行时代码仓库 `/home/clickhousex` 的 `v1.0.10` release evidence、版本元数据与本地复验输出为准。v1.0.10 为生产门禁强化发布，客户端 API 与 AC/TC 覆盖范围与 v1.0.7 一致；远端 push、GitHub Release 与 v1.0.10 Actions 需后续触发，本清单不将其作为已完成证据。

## 0. v1.0.10 验收结论

- `/home/clickhousex` 的 `factory-grade-clickhousex` 分支完成 `v1.0.10` 生产门禁强化（commit `9356c77`）；版本元数据、release manifest 与 release evidence 已对齐到 `v1.0.10`。
- 本轮未执行远端 push 或 GitHub Release 创建；公开 release URL、v1.0.10 远端 Actions run 与 PR 编号不作为本次证据。
- 已通过本地命令：`make release-check`（含 `go build ./...`、unit test、race、100.0% coverage、vet、contract/chaos/adoption/benchmark/release-check gates）、`make lint` 与 `git diff --check`。
- 已对齐版本元数据与 release manifest：`VERSION`、`.repo-contract.yaml`、`pkg/clickhousex/version.go`、`CHANGELOG.md` 与 `release/manifest/latest.json` 均登记 `v1.0.10`。
- CI/CD 已配置：`.github/workflows/ci.yml` 覆盖 `make test-coverage` 与 `make release-check`，`.github/workflows/factory-grade.yml` 覆盖 `make release-check`；`Makefile` 保留 `factory-check` 作为 factory/L2-T4 gate。
- 公开 release evidence 保持密钥脱敏；使用 dev 配置时仅通过本地 shell 投影注入变量，文档不记录敏感值。
- 已确认无 `configx` 依赖。
- 已使用 `sre/secrets/env/dev.md` 的本地 shell 投影 `/home/ZoneCNH/sre/secrets/env/clickhousex.env` 完成真实 ClickHouse live 集成测试：`CLICKHOUSEX_RUN_INTEGRATION=1 GOWORK=off go test -count=1 -run TestClickHouseLiveIntegration -v ./pkg/clickhousex` 通过，覆盖 `New`、`Ping`、`HealthCheck`、`Exec`、`InsertBatch`、`Query`、`Rows` 元数据与扫描/cleanup。
- 已使用同一 dev 配置投影完成真实 ClickHouse live soak：`CLICKHOUSEX_RUN_INTEGRATION=1 CLICKHOUSEX_RUN_SOAK=1 CLICKHOUSEX_SOAK_DURATION=60s CLICKHOUSEX_SOAK_INTERVAL=100ms GOWORK=off go test -count=1 -run TestClickHouseLiveSoak -v ./pkg/clickhousex` 通过，结果 `duration=1m0s`、`iterations=329`、`interval=100ms`。
- Benchmark 已完成：`make release-check` benchmark 阶段通过，基准结果包括 `BenchmarkClientExec` 约 `4156 ns/op`、`BenchmarkClientQueryRowsScan` 约 `5632 ns/op`、`BenchmarkClientInsertBatch` 约 `6155 ns/op`、`BenchmarkClientHealthCheck` 约 `1538 ns/op`。
- 对外客户端 API 已验收：`New`、`Close`、`CloseContext`、`Ping`、`Health`、`HealthCheck`、`Exec`、`Query`、`Rows`、`Rows.ColumnTypes`、`InsertBatch`、retry、metrics、tracing、logger 与错误映射。
- 本版本闭合完整客户端 API、100.0% 覆盖率门禁、真实 ClickHouse live 集成、60s live soak、benchmark、CI/CD 配置与版本元数据/release evidence；生产时长多小时 soak、外部消费方 rollout 与 factory archive 仍作为 factory/L2-T4 缺口保留（`make factory-check` 当前预期不通过：actual L2-T3, expected L2-T4）。

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
| 真实 ClickHouse live 集成 | cd /home/clickhousex && set -a && . /home/ZoneCNH/sre/secrets/env/clickhousex.env && set +a && CLICKHOUSEX_RUN_INTEGRATION=1 GOWORK=off go test -count=1 -run TestClickHouseLiveIntegration -v ./pkg/clickhousex | 使用 `sre/secrets/env/dev.md` 的本地投影注入变量；`TestClickHouseLiveIntegration` PASS，覆盖 `New`、`Ping`、`HealthCheck`、`Exec`、`InsertBatch`、`Query`、`Rows` 元数据与扫描/cleanup |
| 版本元数据一致性 | cd /home/clickhousex && test "$(cat VERSION)" = "v1.0.10" && rg -n "v1.0.10" .repo-contract.yaml pkg/clickhousex/version.go CHANGELOG.md release/manifest/latest.json | runtime 版本源、契约、CHANGELOG 与 release manifest 均指向 v1.0.10 |
| 依赖边界 | cd /home/clickhousex && GOWORK=off go list -deps ./... | 输出不包含 `configx` |
| API 边界 | cd /home/clickhousex && rg -n "func \\(c \\*Client\\) (Exec|Query|InsertBatch|Ping|Close|CloseContext)|func \\(c \\*Client\\) Health|func \\(c \\*Client\\) HealthCheck|type Rows interface|func \\(.*ColumnTypes" pkg/clickhousex | 完整客户端 API 可定位，且与 FEATURES.md 登记一致 |
| CI Trust Alignment 配置 | cd /home/clickhousex && rg -n "trust-alignment|xlibgate trust identity|xlibgate trust template-residue|xlibgate trust secret-redaction" .github/workflows/ci.yml | workflow 已配置 identity/template-residue/secret-redaction；远端 v1.0.10 Actions 待 push 后触发 |
| 真实 ClickHouse live soak | cd /home/clickhousex && set -a && . /home/ZoneCNH/sre/secrets/env/clickhousex.env && set +a && CLICKHOUSEX_RUN_INTEGRATION=1 CLICKHOUSEX_RUN_SOAK=1 CLICKHOUSEX_SOAK_DURATION=60s CLICKHOUSEX_SOAK_INTERVAL=100ms GOWORK=off go test -count=1 -run TestClickHouseLiveSoak -v ./pkg/clickhousex | 使用 `sre/secrets/env/dev.md` 的本地投影注入变量；`TestClickHouseLiveSoak` PASS，结果 `duration=1m0s`、`iterations=329`、`interval=100ms` |
| Benchmark | cd /home/clickhousex && make release-check | benchmark stage PASS；Exec 约 `4156 ns/op`、QueryRowsScan 约 `5632 ns/op`、InsertBatch 约 `6155 ns/op`、HealthCheck 约 `1538 ns/op` |
| CI/CD 工作流配置 | cd /home/clickhousex && test -f .github/workflows/ci.yml && test -f .github/workflows/factory-grade.yml && rg -n "test-coverage|release-check|factory-check" Makefile .github/workflows | release、coverage 与 factory gates 可定位；远端 v1.0.10 Actions 待 push 后触发 |
| 本地 Release 对账 | cd /home/clickhousex && rg -n "v1.0.10" .repo-contract.yaml VERSION pkg/clickhousex/version.go CHANGELOG.md release/manifest/latest.json | 版本元数据、CHANGELOG 与 release manifest 均指向 v1.0.10 |
| Factory L2-T4 gate | cd /home/clickhousex && make factory-check | 预期未通过：actual L2-T3, expected L2-T4；缺口为多小时 soak、外部 rollout 与 factory archive |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | NewClient 合法配置返回 Client, nil 错误 | 通过：`New`、`Config` 默认值/校验、native connector option adapter 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-002 | FR-001 | NewClient 空 DSN 返回配置错误 | 通过：空/非法配置、DSN sanitize 与错误包装已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-003 | FR-002 | Exec 正常 SQL 返回 nil | 通过：`Client.Exec` 成功路径、参数传递、metrics/tracing/logger 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-004 | FR-002 | Exec 语法错误返回包装后的 ClickHouse 错误 | 通过：driver error wrapping、operation detail 与 fallback 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-005 | FR-003, FR-007 | Query 有结果返回可迭代 Rows | 通过：`Client.Query`、`Rows.Next`、`Scan` 与 `Close` 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-006 | FR-003 | Query 无结果返回空 Rows 且 nil 错误 | 通过：空结果和 query setup cancellation 分支已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-007 | FR-004 | InsertBatch 正常写入返回 nil | 通过：native `PrepareBatch`/`Append`/`Send` path 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-008 | FR-004 | InsertBatch 空 rows 返回 nil | 通过：空 rows no-op 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-009 | FR-004 | InsertBatch 空 cols 返回 ErrEmptyColumns | 通过：空列校验已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-010 | FR-004 | InsertBatch 列数不匹配返回 ErrColumnCountMismatch | 通过：列数不匹配并含行号的错误路径已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-011 | FR-004, BR-010 | InsertBatch 表不存在返回 ErrTableNotFound，不自动建表 | 通过：native batch prepare error 映射覆盖；实现不自动建表 | TRACEABILITY.md, v1.0.10 evidence |
| AC-012 | FR-007 | Scan 列数不匹配返回 ErrColumnCountMismatch | 通过：scan 目标数量校验已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-013 | FR-007, BR-011 | Scan Nullable 列到非指针类型返回 ErrTypeMismatch | 通过：Nullable 非指针目标错误和指针路径已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-014 | FR-007, FR-008 | ColumnTypes 返回列名、ClickHouse 类型、Nullable 标志 | 通过：`Rows.ColumnTypes` 与 native row adapter 元数据转换已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-015 | FR-006, BR-009 | Close 幂等，多次调用不 panic | 通过：`Close` 与 `CloseContext` 重复调用、等待、取消和 deadline 分支已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-016 | FR-005 | Health 连接正常返回 Ready=true, Live=true | 通过：fake-driver/local healthy 状态和真实 live 实例均已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-017 | FR-005 | Health 连接异常返回 Ready=false, Live=false | 通过：closed、nil context、canceled、deadline 与 driver error 状态已覆盖；live 异常演练仍由本地替身覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-018 | BR-001 | 连接池默认 size=10, max=100，Config 可覆盖 | 通过：默认值、覆盖配置和非法配置校验已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-019 | BR-002 | 批量写入使用 ClickHouse 原生 batch insert 协议 | 通过：`InsertBatch` 使用 native batch adapter，不拼接 values SQL | TRACEABILITY.md, v1.0.10 evidence |
| AC-020 | BR-003 | SQL 参数使用占位符绑定，非字符串拼接 | 通过：`Exec`/`Query` 将 args 传递给 driver 调用；参数传递测试覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-021 | BR-004 | 连接断开后自动重试 3 次，超过后返回 ErrConnectionLost | 通过：默认 `RetryConfig`、retryable failures、wait cancellation 和 delay clamping 已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-022 | BR-005 | Health() 多次调用结果一致，无副作用 | 通过：多状态重复调用与关闭后健康状态已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-023 | BR-006 | ctx 取消/超时时操作中断并返回 ctx.Err() | 通过：`Exec`、`Query`、`InsertBatch`、`Ping`、`HealthCheck`、`CloseContext` context 分支已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-024 | BR-007 | 错误消息格式为 "clickhousex: <operation>: <detail>" | 通过：错误格式、fallback、wrapping、driver 错误映射与表不存在错误映射已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-025 | BR-008 | metrics 包含 table 标签或 query 标签 | 通过：query/write/pool 指标、operation/table/query 标签与 Noop metrics 分支已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| AC-026 | BR-012 | Decimal 类型映射到 decimal.Decimal，无精度丢失 | 通过：Decimal 目标类型校验和精度保护路径已覆盖 | TRACEABILITY.md, v1.0.10 evidence |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-002, FR-003, FR-004, FR-007, BR-003 | InsertBatch 写入后 Query 返回对应结果 | 通过：fake-driver 单元测试覆盖 insert/query/rows/args 主链路；真实 live 集成测试已补充 `New`/`Exec`/`InsertBatch`/`Query`/`Rows` 主链路 | TRACEABILITY.md, v1.0.10 evidence |
| TC-002 | FR-002, BR-004 | ClickHouse 临时不可达时 Exec 返回 ErrConnectionLost，恢复后自动重连 | 通过：retryable connection failure、重试次数、错误映射和恢复成功路径已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| TC-003 | FR-004, BR-002 | 100000 行 InsertBatch 使用 batch insert 协议且满足性能目标 | 部分通过：native batch 协议和列校验已覆盖；v1.0.10 已归档 `BenchmarkClientInsertBatch` 约 `6155 ns/op`；100000 行真实规模/生产数据分布仍需生产时长 soak 或 rollout 证据 | TRACEABILITY.md, v1.0.10 evidence |
| TC-004 | FR-007, FR-008, BR-011 | Nullable(Int32) NULL 行 Scan 到 *int32 为 nil | 通过：Nullable 指针语义、非指针错误与 ColumnTypes 元数据已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| TC-005 | FR-001 | DSN 缺失或格式非法时创建失败且不建立连接 | 通过：Config validate、DSN sanitize 与 native connector 初始化分支已覆盖 | TRACEABILITY.md, v1.0.10 evidence |
| TC-006 | FR-005, BR-005 | Health 正常和失败状态均正确 | 通过：healthy、closed、nil context、canceled、deadline 与 driver error 已覆盖；真实 live 正常链路与 60s live soak 已补充，生产时长多小时 soak 仍为 factory 前缺口 | TRACEABILITY.md, v1.0.10 evidence |
| TC-007 | FR-006, BR-009 | client 已关闭后再次 Close 返回 nil 且不 panic | 通过：`Close` / `CloseContext` 幂等、等待与取消分支已覆盖 | TRACEABILITY.md, v1.0.10 evidence |

## 4. 覆盖闭合验收

| 覆盖对象 | 验收结论 |
| --- | --- |
| FR-001..FR-008 | 通过：完整客户端 API 已由 v1.0.10 运行时代码、单元测试、fake-driver 覆盖和 release evidence 闭合 |
| BR-001..BR-012 | 通过：配置、原生 batch、参数绑定、retry、context、错误、metrics/tracing/logger、Nullable/Decimal 均有证据 |
| NFR-001..NFR-007 | 部分通过：v1.0.10 已归档 release-check benchmark，Exec、QueryRowsScan、InsertBatch client path 与 HealthCheck 基准已闭合；100000 行真实规模、复杂聚合、独立 pool acquire benchmark 与长期 profiling 仍为 factory 前补充项 |
| NFR-008..NFR-018 | 通过：coverage/build/race/vet/lint/secret/dependency/CI 配置/local release evidence/observability 证据已闭合；本地真实 ClickHouse live 集成与 60s soak 证据已闭合，远端 Actions/Release 待 push 后触发，生产时长多小时 soak 仍为 factory 前缺口 |

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/clickhousex 通过 `make release-check`、`make lint`、`git diff --check`、覆盖率门槛、版本元数据与 release evidence 对账。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据；本地真实 ClickHouse live 集成测试与 60s live soak 均已通过，生产时长多小时 soak 仍作为 factory 前缺口登记。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码；公开 release evidence 保持密钥脱敏，dev 配置只作本地投影。
- [x] 版本号、CHANGELOG、release manifest 与本目录状态一致。
- [x] 版本元数据、release evidence 与本目录登记状态一致。
- [ ] 远端 push、GitHub Release 与 v1.0.10 Actions 尚未执行；完成后需补充远端 run/release evidence。
- [ ] 生产时长多小时 soak、外部消费方 rollout 与 factory 归档证据仍待补齐。

## 6. 当前缺口登记

- `v1.0.10` 闭合完整客户端 API、100.0% coverage、CI/CD 配置、版本元数据、真实 ClickHouse live 集成、60s soak 与 benchmark；不再保留 `Exec`、`Query`、`InsertBatch`、`Rows`、metrics 或 tracing 的实现缺口。
- 远端 push、GitHub Release 与 v1.0.10 Actions 尚未执行；完成后再补远端 run/release evidence。
- 生产时长多小时 soak、外部消费方 rollout 与 factory 归档证据仍待补齐。
- 真实 ClickHouse live 集成测试与 60s soak 已使用 dev 配置投影通过；公开文档不记录敏感值。
- BLK-003 已 resolved（v1.0.1 Release 发布时关闭）；进入 factory/L2-T4 前必须补充生产时长多小时 soak、外部消费方 rollout、factory archive 和剩余大规模/复杂查询性能证据。
