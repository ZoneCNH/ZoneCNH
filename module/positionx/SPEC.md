# positionx 完整规格

> 执行域 · 仓位管理器。实时仓位追踪、PnL 计算、敞口监控、多账户持仓核对。

最后更新：2026-06-14

---

## 1. Metadata

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 执行域 · 仓位管理
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/positionx](https://github.com/ZoneCNH/positionx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |
| 2026-06-14 | v0.1.0-draft | FR-008 Module Identity (README H1 + go.mod 校验) | ZoneCNH |

## 2. Summary

`positionx` 是执行域的仓位管理器，负责跨交易所、跨账户的实时仓位追踪、PnL 计算、风险敞口监控和持仓核对。它接收执行引擎的成交事件（fill events），更新仓位状态，并向 riskx 和 observex 输出仓位快照。

---

## 3. Problem

多交易所、多账户交易场景中，仓位信息分散在各交易所的 API 和本地数据库中：

- 无统一仓位视图，跨交易所净敞口无法实时计算
- 成交事件到仓位更新的延迟导致风控判断滞后
- 仓位核对依赖定时轮询，结算时才发现差异
- PnL 计算口径不统一（已实现 vs 未实现、含手续费 vs 不含）
- 缺乏仓位历史变更审计轨迹

---

## 4. Goals

- 统一仓位视图：跨交易所、跨账户的净持仓
- 实时仓位更新：fill event → position update（< 10ms）
- 多维度 PnL：已实现/未实现、绝对值/百分比、含/不含手续费
- 仓位核对：交易所 API 持仓 vs 本地计算的差异报告
- 仓位快照：定时生成并推送至 observex 和 riskx
- 审计追踪：每次仓位变更记录原因（fill/transfer/adjustment）

---

## 5. Non-goals

- 不做交易所 API 对接（→ market-data）
- 不做风控决策（→ riskx）
- 不做订单管理（→ orderx）
- 不做会计系统（不含税务计算）
- 不做杠杆/保证金计算（独立于仓位管理）

---

## 6. Consumers

| 消费者       | 使用方式                            |
| ------------ | ----------------------------------- |
| riskx        | 消费仓位快照进行风控检查             |
| orderx       | 查询持仓量进行下单校验               |
| observex     | 消费仓位 metrics（PnL, exposure）   |
| backtestx    | 回放仓位历史进行回测                 |
| strategyx    | 查询持仓以判断再平衡信号            |

---

## 7. Functional Requirements

### FR-001: Position Update

WHEN 接收到 FillEvent（成交事件）
THEN 更新对应 symbol、account、exchange 的仓位
AND 更新耗时 < 10ms（p95）
AND 记录变更原因和来源 fill_id

### FR-002: Position Query

WHEN 查询 Position(symbol, account, exchange)
THEN 返回最新仓位：longQty, shortQty, netQty, avgPrice, lastUpdateTime
WHEN 查询参数为空
THEN 返回所有仓位的聚合视图（按 symbol 汇总跨交易所净持仓）

### FR-003: PnL Calculation

WHEN 计算 PnL(symbol, account)
THEN 返回 realizedPnl, unrealizedPnl, totalPnl
AND unrealizedPnl 基于最新市价 (markPrice) 计算
AND 支持含/不含手续费两种口径
WHEN markPrice 不可用
THEN 使用最近成交价作为替代并标注 stale=true

### FR-004: Exposure

WHEN 查询 Exposure(account)
THEN 返回 totalExposure（所有仓位 |netQty * markPrice| 之和）
AND 返回 byExchange, bySymbol 的敞口明细
AND 计算 netDelta（多空净敞口）

### FR-005: Reconciliation

WHEN 触发 PositionReconciliation(account, exchange)
THEN 从交易所 API 拉取当前持仓 → 与本地仓位对比
AND 差异超过 threshold 时 emit reconciliation_alert
AND 差异明细写入 audit log

### FR-006: Snapshot

WHEN 定时 Snapshot 触发
THEN 生成当前所有仓位的只读快照
AND 快照通过 observex 推送给订阅方
AND 快照间隔可配置（默认 1s）

### FR-007: Position History

WHEN 查询 PositionHistory(symbol, account, start, end)
THEN 返回该时间段内的仓位变更事件列表
AND 每条记录包含：timestamp, fill_id, deltaQty, price, reason

---

### FR-008: Module Identity

WHEN downstream consumer reads `positionx` `README.md`
THEN the H1 heading MUST be `# positionx`
AND MUST NOT be `# xlib-standard`

WHEN module documentation references the `positionx` Go module path
THEN it MUST use `github.com/ZoneCNH/positionx`
AND MUST NOT use `github.com/ZoneCNH/xlib-standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/positionx`



## 8. Business Rules

| 编号   | 规则                                   | 违反后果 |
| ------ | -------------------------------------- | -------- |
| BR-001 | 同一 fill_id 不可重复更新仓位          | 拒绝重复 + emit warning |
| BR-002 | long 和 short 不可同时非零              | 交易系统保证（净持仓模式） |
| BR-003 | 仓位核对差异 > 5% 必须人工确认          | 告警升级为 critical |
| BR-004 | 快照不可变（创建后不能修改）           | 合规要求 |
| BR-005 | markPrice 来源优先：最新成交 > 买一 > 上次 mark | 标注数据质量 |

---

## 9. Interface Contract

```go
type PositionManager interface {
    Update(ctx context.Context, fill FillEvent) (*Position, error)
    Get(ctx context.Context, symbol string, account string, exchange string) (*Position, error)
    GetAll(ctx context.Context, account string) ([]Position, error)
    GetExposure(ctx context.Context, account string) (*Exposure, error)
    Reconcile(ctx context.Context, account string, exchange string) (*ReconciliationReport, error)
    Snapshot(ctx context.Context) (*PositionSnapshot, error)
    History(ctx context.Context, req HistoryRequest) ([]PositionChange, error)
}

type PnLCalculator interface {
    Realized(ctx context.Context, position Position) (decimal.Decimal, error)
    Unrealized(ctx context.Context, position Position, markPrice decimal.Decimal) (decimal.Decimal, error)
}
```

---

## 10. Data Model

| 模型                 | 字段 |
| -------------------- | ---- |
| Position             | symbol, account, exchange, longQty, shortQty, netQty, avgPrice, markPrice, lastUpdateTime |
| FillEvent            | fillId, symbol, account, exchange, side, qty, price, fee, timestamp |
| Exposure             | totalExposure, byExchange[], bySymbol[], netDelta |
| PnL                  | realized, unrealized, total, withFee, withoutFee |
| ReconciliationReport | match:bool, diffQty, diffPct, exchangePositions[], localPositions[] |
| PositionChange       | timestamp, fillId, deltaQty, price, reason |

---

## 11. Config Schema

```yaml
positionx:
  snapshot_interval: 1s
  reconciliation_interval: 5m
  reconciliation_threshold_pct: 0.01
  mark_price_source: last_trade  # last_trade / best_bid / external
  max_positions_per_account: 1000
```

---

## 12. Error Handling

| 错误                   | 处理方式                         |
| ---------------------- | -------------------------------- |
| FillEvent symbol 不存在 | 创建新仓位记录                   |
| 重复 fill_id           | 拒绝 + warning log               |
| 交易所 API 不可达       | reconciliation 跳过此次 + alert  |
| markPrice 不可用        | 使用上次 markPrice + stale 标记  |

---

## 13. Edge Cases

| 场景                       | 预期行为                               |
| -------------------------- | -------------------------------------- |
| 同一 symbol 多账户持仓      | 分账户独立管理，聚合查询时合并         |
| 市价剧烈波动时 snapshot     | 快照是瞬时值，不保证跨账户原子性       |
| 仓位从非零变为零            | 保留零仓位记录并标记 closed            |
| 交易所不支持查询持仓        | reconciliation 模式标记为 unsupported  |

---

## 14. Directory Structure

```text
positionx/
├── go.mod
├── go.sum
├── README.md
├── position.go       # PositionManager 接口和实现
├── pnl.go            # PnL 计算
├── exposure.go       # 敞口计算
├── reconcile.go      # 仓位核对
├── snapshot.go       # 快照管理
├── history.go        # 历史变更
├── errors.go         # 错误定义
├── internal/
│   └── store/        # 仓位存储（内存默认）
└── example_test.go
```

---

## 15. Dependencies

| 可以依赖                             | 禁止依赖                     |
| ------------------------------------ | ---------------------------- |
| kernel, configx, observex, contracts | 风控决策逻辑（→ riskx）      |
| domainx (decimal)                    | 订单管理逻辑（→ orderx）     |
| stdlib                               | 交易所 SDK                   |

---

## 16. Testing

| 测试场景            | 验证点                               |
| ------------------- | ------------------------------------ |
| Fill 更新仓位        | netQty 和 avgPrice 正确计算           |
| 多笔 Fill 相同 symbol | 仓位正确累加                         |
| 重复 fill_id         | 拒绝重复更新                         |
| PnL 计算             | realized/unrealized 分口径正确       |
| 仓位核对              | match/diff 逻辑正确                  |

---

## 17. Performance Budget

| 操作              | 目标     |
| ----------------- | -------- |
| Position Update   | < 10ms   |
| Snapshot (1K positions) | < 50ms |
| PnL Calculation   | < 1ms    |
| Reconciliation    | < 5s     |

---

## 18. Observability

| 信号   | 指标                                    |
| ------ | --------------------------------------- |
| Metric | positionx.positions.total              |
| Metric | positionx.exposure.by_symbol           |
| Metric | positionx.pnl.realized / unrealized    |
| Metric | positionx.reconciliation.diff_pct      |
| Trace  | fill_id → position update → snapshot   |

---

## 19. Security

| 要求               | 实现方式                       |
| ------------------ | ------------------------------ |
| 仓位数据敏感       | 日志不输出完整仓位明细         |
| API key 不落盘     | 通过 configx 注入，不持久化   |

---

## 20. CI Gate

| Gate   | 命令                                   | 阻塞条件       |
| ------ | -------------------------------------- | -------------- |
| 编译   | `go build ./...`                       | 编译失败       |
| 测试   | `go test ./... -race -count=1`         | 测试失败       |
| 覆盖率 | `go test -coverprofile=...`            | < 80%          |
| vet    | `go vet ./...`                         | vet 错误       |
| secret | `gitleaks detect --no-git`             | 泄露 secret    |

---

## 21. Upgrade Compatibility

| 变更类型             | 版本升级 |
| -------------------- | -------- |
| 新增 Position 字段   | minor    |
| PositionManager 接口变更 | major |
| 新增 PnL 计算口径    | minor    |

---

## 22. Release DoD

- [ ] PositionManager 接口完整实现
- [ ] PnL 计算所有口径验证
- [ ] 仓位核对逻辑通过
- [ ] 覆盖率 ≥ 80%
- [ ] CHANGELOG.md 已更新

---

## 23. Open Questions

- 是否需要支持组合保证金（portfolio margin）？
- 是否需要支持跨交易所净额结算视角？
- markPrice 是否应接入独立的价格预言机？
