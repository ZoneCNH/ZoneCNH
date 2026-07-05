# Binance 模块分析报告 — 执行摘要

> **分析日期**：2026-07-05
> **代码仓库**：`/home/workspace/binance`（`github.com/ZoneCNH/binance`）
> **规格仓库**：`/home/workspace/ZoneCNH/module/binance/`
> **分析方法**：4 agent team 并行分析 + 交叉验证（关键发现已逐条人工验证）
> **报告目录**：`report/binance/`

## 项目定位

Binance 交易所**行情数据采集 C/S 模块**（主功能），外加一个并存的**交易侧 VenueAdapter**（`pkg/binancex`）。Client 进程连接 Binance WS 采集行情 → NATS → Server 进程验收/幂等/分发/存储。交易适配器提供 Spot 下单/撤单/查询能力。

| 维度             | 数据                                                                                          |
| ---------------- | --------------------------------------------------------------------------------------------- |
| 源文件（非测试） | 119 个                                                                                        |
| 测试文件         | 143 个                                                                                        |
| 测试函数         | 1898 个                                                                                       |
| 代码总行数       | ~68,000 行（含测试）                                                                          |
| Go 版本          | 1.25.0 / toolchain go1.26.4                                                                   |
| 外部直接依赖     | 10 个（含 binance SDK、gorilla/websocket、gin、nats、taos driver 等）                         |
| ZoneCNH 基座依赖 | 15 个（bootstrap/configx/contracts/decimalx/domain-\*/kafkax/natsx/ossx/postgresx/redisx 等） |

## 核心结论

### 交易适配器（pkg/binancex）

| 功能             | 状态        | 备注                                            |
| ---------------- | ----------- | ----------------------------------------------- |
| 现货下单         | ✅ 已实现   | LIMIT/MARKET/STOP-LIMIT，支持 TIF/ClientOrderID |
| 合约下单         | ❌ 未实现   | 仅行情侧有合约 K线，交易侧无合约下单            |
| 撤单             | ✅ 已实现   | 单笔 + 批量                                     |
| 查询订单         | ✅ 已实现   | 按 orderId / clientOrderID                      |
| 查询余额         | ✅ 已实现   | 过滤零余额                                      |
| 查询持仓         | ⚠️ 占位     | 固定返回空切片                                  |
| WebSocket 成交流 | ✅ 已实现   | User Data Stream + listenKey 续期               |
| 签名认证         | ✅ SDK 内置 | HMAC-SHA256 由 binance-connector-go 承担        |

### 行情采集（internal/client）

| 功能               | 状态                                        |
| ------------------ | ------------------------------------------- |
| K线行情            | ✅ WS + REST 翻页，四产品线                 |
| 深度/订单簿        | ✅ 快照 + diff，全量档位                    |
| WebSocket 实时推送 | ✅ 组合流 + 心跳 + 重连 + 背压              |
| 数据存储           | ✅ TDengine + ClickHouse + OSS + PostgreSQL |
| 限频/节流          | ⚠️ 已实现未接线                             |
| 幂等性             | ✅ client + server 双层                     |
| 白名单             | ✅ 全量/增量同步                            |
| 死信/重放          | ✅ JSONL + replay                           |
| 热重载             | ✅ 不重启刷新符号                           |

### 关键风险（按严重度排序）

| #   | 严重度  | 问题                                           | 位置                                  |
| --- | ------- | ---------------------------------------------- | ------------------------------------- |
| 1   | 🔴 严重 | SubmitOrder 无任何客户端下单量/价格校验        | `adapter.go:135-172`                  |
| 2   | 🟠 高   | ThrottleManager 已实现但从未在真实请求路径调用 | `throttle.go` + `runtime.go:229`      |
| 3   | 🟠 高   | WeightGate/RetryBudget/ClockSkew 全部未接线    | `controlplane_binding.go:32`          |
| 4   | 🟠 高   | StreamExecutions 阻塞读不响应 ctx 取消         | `adapter.go:317-340`                  |
| 5   | 🟠 高   | decimalx.MustFromString 在生产路径 panic       | `adapter.go:109,386,415,461` 等 10 处 |
| 6   | 🟡 中   | 429 不读 Retry-After 头；418 完全未处理        | `history_rest.go:226`                 |
| 7   | 🟡 中   | ListExecutions 静默吞掉单品种错误              | `adapter.go:259-264`                  |
| 8   | 🟡 中   | WebSocket 重连退避无 jitter                    | `spot.go:372-378`                     |

### 测试结果

| 维度                  | 结果                                    |
| --------------------- | --------------------------------------- |
| `go vet ./...`        | ✅ 零告警                               |
| `pkg/binancex` 单测   | ✅ 101 个测试全过，覆盖率 **100%**      |
| `pkg/binancecfg`      | ✅ 68 个测试全过                        |
| `internal/client`     | ✅ 全过（43.6s）                        |
| `internal/server`     | ✅ 全过                                 |
| race 检测（核心包）   | ✅ 无数据竞争                           |
| depth 测试（115 个）  | ✅ 全过                                 |
| security 测试（9 个） | ✅ 全过                                 |
| chaos 测试（12 个）   | ✅ 全过                                 |
| e2e 测试              | ❌ 1 个失败（测试逻辑缺陷，非生产 bug） |
| soak 测试             | ⚠️ 超时（无 skip 守卫，环境限制）       |

## 报告索引

| 文件                                           | 内容                                               |
| ---------------------------------------------- | -------------------------------------------------- |
| [01-structure.md](01-structure.md)             | 代码结构：模块划分、依赖关系、对外接口             |
| [02-features.md](02-features.md)               | 功能点清单（17 项逐项确认）                        |
| [03-static-analysis.md](03-static-analysis.md) | 静态分析：异常处理、边界条件、限频、密钥安全、并发 |
| [04-test-report.md](04-test-report.md)         | 测试执行报告与用例设计                             |

## 交叉验证声明

本报告所有关键发现均经人工逐条验证：

- SubmitOrder 无校验 → `rg` 确认零匹配
- ThrottleManager 未接线 → `rg "\.Allow\("` 在非测试代码零命中
- 418 未处理 → `rg "418"` 仅命中测试数据字符串
- GetPositions 空实现 → 源码确认 `return []domain.Position{}, nil`
- MustFromString 生产路径 → 确认 10 处调用
- 测试结果 → 实际执行 `go test` 命令确认
