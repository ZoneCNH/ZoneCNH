# clickhousex 完整实现清单

- Status: Updated from runtime release evidence
- Last-Updated: 2026-06-19
- Module-Version: v1.0.7
- Module-State: full client API 已发布；live soak / benchmark / profile / release / CI / Trust Alignment 已复验；非 factory
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/clickhousex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/, /home/clickhousex/release/evidence/v1.0.7.md

> 本清单用于约束 clickhousex 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档，并以运行时代码仓库 `/home/clickhousex` 的 `v1.0.7` release evidence 对齐当前状态。

## 0. v1.0.7 验证结论

- `/home/clickhousex` 的 `clickhousex` 分支已发布 `v1.0.7` tag/release（commit `920af61c3727abcaadd6c81abba75600626a9ab1`）。
- GitHub Release 已发布：https://github.com/ZoneCNH/clickhousex/releases/tag/v1.0.7。
- 版本元数据已对齐：`VERSION`、`.repo-contract.yaml`、`pkg/clickhousex/version.go`、`CHANGELOG.md` 与 `release/manifest/latest.json` 均登记 `v1.0.7`。
- 本地复验已通过：`GOWORK=off go test ./... -covermode=atomic -coverprofile=coverage.out`、`GOWORK=off go tool cover -func=coverage.out` 总覆盖率 `100.0%`、`GOWORK=off go test ./...`、`GOWORK=off go test -race ./...`、`GOWORK=off go vet ./...`、`GOWORK=off go build ./...`、`GOWORK=off golangci-lint run ./...` 与 `git diff --check`。
- GitHub Actions 已完成远端复验：branch run `27807110998` 的 quality、lint、integration、secret-scan 与 trust-alignment 均 success；tag run `27807120921` 的 quality、lint、integration、secret-scan、trust-alignment 与 release-check 均 success。
- Trust Alignment 已复验：`xlibgate trust identity --repo .`、`xlibgate trust template-residue --repo .`、`xlibgate trust secret-redaction --repo . --path release/evidence` 均通过。
- 依赖边界已复验：`GOWORK=off go list -deps ./... | rg '(^|/)configx($|/)'` 无匹配。
- 真实 ClickHouse 集成测试已通过：使用 `sre/secrets/env/dev.md` 的本地 shell 投影 `/home/ZoneCNH/sre/secrets/env/clickhousex.env` 注入运行时变量，执行 `CLICKHOUSEX_RUN_INTEGRATION=1 GOWORK=off go test -count=1 -run TestClickHouseLiveIntegration -v ./pkg/clickhousex`，覆盖 `New`、`Ping`、`HealthCheck`、`Exec`、`InsertBatch`、`Query`、`Rows.ColumnTypes`、`Rows.Scan` 与 cleanup。
- 真实 ClickHouse live soak 已通过：执行 `CLICKHOUSEX_RUN_INTEGRATION=1 CLICKHOUSEX_RUN_SOAK=1 CLICKHOUSEX_SOAK_DURATION=60s CLICKHOUSEX_SOAK_INTERVAL=100ms GOWORK=off go test -count=1 -run TestClickHouseLiveSoak -v ./pkg/clickhousex`，结果 `duration=1m0s`、`iterations=350`、`interval=100ms`。
- Benchmark/profile 已归档：`GOWORK=off go test -run '^$' -bench . -benchmem -cpuprofile /tmp/clickhousex-v1.0.7.cpu.pprof -memprofile /tmp/clickhousex-v1.0.7.mem.pprof ./pkg/clickhousex` 通过，生成 CPU/mem profile；基准结果包括 `BenchmarkClientExec-16` `1521 ns/op`、`BenchmarkClientQueryRowsScan-16` `1992 ns/op`、`BenchmarkClientInsertBatch-16` `4323 ns/op`、`BenchmarkClientHealthCheck-16` `813.5 ns/op`。
- 对外客户端能力已发布：`New`、`Close`、`CloseContext`、`Ping`、`Health`、`HealthCheck`、`Exec`、`Query`、`Rows`、`Rows.ColumnTypes`、`InsertBatch`、retry、metrics、tracing、logger 与错误映射。
- 本版本闭合完整客户端 API、100.0% 覆盖率门禁、真实 ClickHouse live 集成、60s live soak、正式 benchmark/profile 与发布证据；生产时长多小时 soak 与外部消费方 rollout 仍作为 BLK-003 / factory 前缺口保留。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | ClickHouse 连接、批写、查询、迁移、TTL 与健康检查适配 |
| 文档目录 | module/clickhousex |
| 运行时代码目录 | /home/clickhousex |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块；禁止直接依赖 configx |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | NewClient：创建 ClickHouse 客户端，连接池初始化，DSN 校验 | AC-001, AC-002 / TC-005 / TASK-CLICKHOUSEX-001 | 通过：`Config` 默认值/校验、DSN sanitize、`New` 与 native connector option adapter 已由单元测试和覆盖率证据闭合 | TRACEABILITY.md, v1.0.7 evidence |
| FR-002 | Exec：执行 DDL/DML，支持 context 取消、连接断开恢复 | AC-003, AC-004, AC-023 / TC-001, TC-002 / TASK-CLICKHOUSEX-002 | 通过：`Client.Exec` 支持 context、参数绑定、retry、metrics/tracing/logger 与错误包装；fake-driver 单测覆盖成功、语法错误、取消和连接故障分支 | TRACEABILITY.md, v1.0.7 evidence |
| FR-003 | Query：执行 OLAP 查询，返回可迭代 Rows，空结果无错误 | AC-005, AC-006 / TC-001 / TASK-CLICKHOUSEX-003 | 通过：`Client.Query` 返回 `Rows`；空结果、query setup cancellation、错误包装、metrics/tracing/logger 与 retry 分支已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| FR-004 | InsertBatch：原生 batch insert 协议批量写入，列校验，表存在检查 | AC-007, AC-008, AC-009, AC-010, AC-011 / TC-001, TC-003 / TASK-CLICKHOUSEX-004 | 通过：`Client.InsertBatch` 使用 native `PrepareBatch`/`Append`/`Send` 路径；空 rows、空列、列数不匹配、表名校验与表不存在错误映射已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| FR-005 | Health：连接池健康检查，返回 Ready/Live/Message | AC-016, AC-017, AC-022 / TC-006 / TASK-CLICKHOUSEX-005 | 通过：`Ping`、`Health`、`HealthCheck` 覆盖 healthy、closed、nil context、canceled、deadline 与错误状态；v1.0.7 真实 live 集成测试已覆盖 Ready/Live 正常链路 | TRACEABILITY.md, v1.0.7 evidence |
| FR-006 | Close：关闭连接池，幂等，等待进行中查询 | AC-015 / TC-007 / TASK-CLICKHOUSEX-005 | 通过：`Close` 与 `CloseContext` 幂等、等待、cancel/deadline 分支均覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| FR-007 | Rows.Next/Scan/Close：结果集迭代、行扫描、类型映射 | AC-005, AC-012, AC-013, AC-014 / TC-001, TC-004 / TASK-CLICKHOUSEX-003 | 通过：`Rows.Next`、`Scan`、`Close`、`Err`、列数校验、Nullable 指针约束与 Decimal 精度类型校验已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| FR-008 | Rows.ColumnTypes：返回列名、ClickHouse 类型、Nullable 标志 | AC-014 / TC-004 / TASK-CLICKHOUSEX-003 | 通过：`Rows.ColumnTypes` 与 native row adapter 的列名、类型、Nullable 元数据转换已覆盖 | TRACEABILITY.md, v1.0.7 evidence |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | 连接池大小默认 10，最大 100，通过 Config 配置 | AC-018 / TASK-CLICKHOUSEX-001 | 通过：默认值、覆盖配置和非法配置校验已覆盖；native option adapter 编译/单测闭合 | TRACEABILITY.md, v1.0.7 evidence |
| BR-002 | 批量写入使用原生 batch insert 协议，不使用拼接 SQL | AC-019, TC-003 / TASK-CLICKHOUSEX-004 | 通过：`InsertBatch` 走 native batch adapter，不拼接 value SQL | TRACEABILITY.md, v1.0.7 evidence |
| BR-003 | Exec / Query 的 args 使用参数化绑定，禁止 SQL 拼接 | AC-020, TC-001 / TASK-CLICKHOUSEX-002 | 通过：`Exec`/`Query` 将 args 传递给 driver 调用；单测覆盖参数传递 | TRACEABILITY.md, v1.0.7 evidence |
| BR-004 | 连接断开后自动重试 3 次（指数退避），超过后返回 ErrConnectionLost | AC-021, TC-002 / TASK-CLICKHOUSEX-002 | 通过：`RetryConfig` 默认 3 次，retryable connection failures、wait cancellation 与 retry-delay clamping 已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| BR-005 | Health() 必须是幂等的、无副作用的 | AC-022, TC-006 / TASK-CLICKHOUSEX-005 | 通过：多状态重复调用与关闭后健康状态已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| BR-006 | 所有操作必须接受 context.Context，支持取消和超时 | AC-023 / TASK-CLICKHOUSEX-002 | 通过：`Exec`、`Query`、`InsertBatch`、`Ping`、`HealthCheck`、`CloseContext` 均接受或传播 context；取消/超时分支已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| BR-007 | 错误消息格式："clickhousex: <operation>: <detail>" | AC-024 / TASK-CLICKHOUSEX-002 | 通过：错误格式、fallback、wrapping、driver 错误映射与表不存在错误映射已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| BR-008 | 可观测指标必须包含 table 标签（写入操作）或 query 标签（查询操作） | AC-025 / TASK-CLICKHOUSEX-006 | 通过：query/write/pool counter、histogram、gauge 与 operation/table/query 标签路径已覆盖；NoopMetrics 保持默认无副作用 | TRACEABILITY.md, v1.0.7 evidence |
| BR-009 | Close() 必须是幂等的，多次调用不 panic | AC-015, TC-007 / TASK-CLICKHOUSEX-005 | 通过：重复 `Close` 与 `CloseContext` 已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| BR-010 | InsertBatch 不自动建表，表不存在时返回明确错误 | AC-011 / TASK-CLICKHOUSEX-004 | 通过：native batch prepare error 映射为表不存在类错误；实现不执行自动建表 | TRACEABILITY.md, v1.0.7 evidence |
| BR-011 | ClickHouse Nullable 类型映射到 Go 指针类型 | AC-013, TC-004 / TASK-CLICKHOUSEX-003 | 通过：Nullable 列扫描到非指针类型返回类型错误；指针目标路径覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| BR-012 | ClickHouse Decimal 类型映射到 shopspring/decimal 或 apd.Decimal | AC-026 / TASK-CLICKHOUSEX-003 | 通过：Decimal 目标类型校验和精度保护路径已覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-001 | 单次 Exec 性能 | < 10ms / Benchmark BenchmarkExec / TASK-CLICKHOUSEX-002 | 通过：v1.0.7 已归档 `BenchmarkClientExec-16`，结果 `1521 ns/op`、`848 B/op`、`8 allocs/op` | TRACEABILITY.md, v1.0.7 evidence |
| NFR-002 | InsertBatch 10000 行性能 | < 1s / Benchmark BenchmarkInsertBatch / TASK-CLICKHOUSEX-004 | 部分通过：v1.0.7 已归档 client batch benchmark `BenchmarkClientInsertBatch-16`，结果 `4323 ns/op`、`800 B/op`、`12 allocs/op`；生产规模数据分布仍由 factory 前 rollout/soak 补充 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-003 | InsertBatch 100000 行性能 | < 10s / Benchmark BenchmarkInsertBatchLarge / TASK-CLICKHOUSEX-004 | 待补：v1.0.7 已补正式 batch benchmark，但 100000 行真实规模基准仍未单独归档；factory 前继续保留 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-004 | 单次 OLAP 查询性能 | < 100ms / Benchmark BenchmarkQuery / TASK-CLICKHOUSEX-003 | 通过：v1.0.7 已归档 `BenchmarkClientQueryRowsScan-16`，结果 `1992 ns/op`、`984 B/op`、`15 allocs/op` | TRACEABILITY.md, v1.0.7 evidence |
| NFR-005 | 复杂聚合查询性能 | < 1s / Benchmark BenchmarkAggQuery / TASK-CLICKHOUSEX-003 | 待补：v1.0.7 已补基础 query/rows benchmark；复杂聚合查询基准仍需以生产数据分布或专用 bench 补充 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-006 | 连接池获取连接性能 | < 1ms / Benchmark BenchmarkPoolAcquire / TASK-CLICKHOUSEX-001 | 部分通过：v1.0.7 已归档 `BenchmarkClientHealthCheck-16`，结果 `813.5 ns/op`、`336 B/op`、`2 allocs/op`；独立 pool acquire benchmark 未单列 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-007 | 常驻内存（空闲） | < 5MB / Profiling go test -memprofile / TASK-CLICKHOUSEX-007 | 通过：v1.0.7 已生成 `/tmp/clickhousex-v1.0.7.cpu.pprof` 与 `/tmp/clickhousex-v1.0.7.mem.pprof`，release evidence 记录 profile gate | TRACEABILITY.md, v1.0.7 evidence |
| NFR-008 | 单元测试覆盖率 | >= 80% / go tool cover -func / TASK-CLICKHOUSEX-007 | 通过：`go tool cover -func=coverage.out` total `100.0%` | TRACEABILITY.md, v1.0.7 evidence |
| NFR-009 | 编译通过 | 零错误 / go build ./... / TASK-CLICKHOUSEX-007 | 通过：`GOWORK=off go build ./...` | TRACEABILITY.md, v1.0.7 evidence |
| NFR-010 | race 检测通过 | 零 data race / go test -race ./... / TASK-CLICKHOUSEX-007 | 通过：`GOWORK=off go test -race ./...` | TRACEABILITY.md, v1.0.7 evidence |
| NFR-011 | vet 检查通过 | 零警告 / go vet ./... / TASK-CLICKHOUSEX-007 | 通过：`GOWORK=off go vet ./...` | TRACEABILITY.md, v1.0.7 evidence |
| NFR-012 | lint 检查通过 | 零错误 / golangci-lint run / TASK-CLICKHOUSEX-007 | 通过：`GOWORK=off golangci-lint run ./...` 零 issues | TRACEABILITY.md, v1.0.7 evidence |
| NFR-013 | Secret 扫描通过 | 零命中 / TASK-CLICKHOUSEX-007 | 通过：branch run `27807110998` 与 tag run `27807120921` 的 secret-scan 均 success；xlibgate secret-redaction 通过 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-014 | DSN 不泄露到日志 | 密码用 *** 替代 / TASK-CLICKHOUSEX-001 | 通过：sanitize 分支和 logger 路径覆盖；公开 release evidence 无敏感配置 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-015 | 无直接依赖 configx | `go list -deps ./...` 输出不包含 configx / TASK-CLICKHOUSEX-007 | 通过：依赖查询无 `configx` 匹配 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-016 | metrics 指标输出正确 | histogram/counter/gauge 类型正确 / TASK-CLICKHOUSEX-006 | 通过：query/write/pool metrics 与 Noop metrics 分支覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-017 | tracing span 传播正确 | exec/query/insert_batch span / TASK-CLICKHOUSEX-006 | 通过：`Tracer` span 创建、结束与错误记录路径覆盖 | TRACEABILITY.md, v1.0.7 evidence |
| NFR-018 | 集成测试 ClickHouse 不可达时 skip | go test -tags=integration / TASK-CLICKHOUSEX-007 | 通过：branch run `27807110998` 与 tag run `27807120921` 的 integration job 均 success；本地使用 dev 配置投影完成真实 ClickHouse live 集成测试与 60s live soak | TRACEABILITY.md, v1.0.7 evidence |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-CLICKHOUSEX-001 | 配置、默认值、DSN sanitize、client 初始化 | module/clickhousex/tasks/TASK-CLICKHOUSEX-001.md | 通过：配置和 native option adapter 已覆盖 | tasks/TASK-CLICKHOUSEX-001.md, v1.0.7 evidence |
| TASK-CLICKHOUSEX-002 | Exec、retry、context、错误映射 | module/clickhousex/tasks/TASK-CLICKHOUSEX-002.md | 通过：`Client.Exec` 与 retry/error/context 分支已覆盖 | tasks/TASK-CLICKHOUSEX-002.md, v1.0.7 evidence |
| TASK-CLICKHOUSEX-003 | Query、Rows、Scan、ColumnTypes、类型映射 | module/clickhousex/tasks/TASK-CLICKHOUSEX-003.md | 通过：`Client.Query`、`Rows` 与 Nullable/Decimal 校验已覆盖 | tasks/TASK-CLICKHOUSEX-003.md, v1.0.7 evidence |
| TASK-CLICKHOUSEX-004 | InsertBatch 原生批写协议 | module/clickhousex/tasks/TASK-CLICKHOUSEX-004.md | 通过：native batch path、列校验、表名校验与错误映射已覆盖 | tasks/TASK-CLICKHOUSEX-004.md, v1.0.7 evidence |
| TASK-CLICKHOUSEX-005 | Health、Close、CloseContext | module/clickhousex/tasks/TASK-CLICKHOUSEX-005.md | 通过：健康状态、幂等关闭和等待/取消分支已覆盖 | tasks/TASK-CLICKHOUSEX-005.md, v1.0.7 evidence |
| TASK-CLICKHOUSEX-006 | metrics、tracing、logger | module/clickhousex/tasks/TASK-CLICKHOUSEX-006.md | 通过：业务操作观测路径和 noop 默认路径已覆盖 | tasks/TASK-CLICKHOUSEX-006.md, v1.0.7 evidence |
| TASK-CLICKHOUSEX-007 | 质量门禁、覆盖率、CI、release evidence | module/clickhousex/tasks/TASK-CLICKHOUSEX-007.md | 通过：本地质量命令、真实 live 集成测试、60s live soak、benchmark/profile、branch/tag CI、Trust Alignment 与 GitHub Release 已闭合；生产时长多小时 soak 与外部消费方 rollout 作为 factory 前缺口 | tasks/TASK-CLICKHOUSEX-007.md, v1.0.7 evidence |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/clickhousex/goal.md |
| SPEC.md | 存在 | module/clickhousex/SPEC.md |
| TRACEABILITY.md | 存在 | module/clickhousex/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/clickhousex/IMPLEMENTATION-PLAN.md |
| tasks/ | 7 个 Markdown 文件 | module/clickhousex/tasks |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [x] 所有 BR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 发布质量 NFR（coverage/build/race/vet/lint/secret/trust/dependency/CI/release）均有可复验证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖，也不直接依赖 `configx`。
- [x] 运行时代码仓库 /home/clickhousex 的 lint、typecheck、test、race、coverage、Actions 与 Trust Alignment 验证证据已归档。
- [x] 发布说明、版本标签与本目录登记状态一致。
- [ ] 生产时长多小时 soak、外部消费方 rollout 与 factory 证据仍待补齐；BLK-003 保持 open。
