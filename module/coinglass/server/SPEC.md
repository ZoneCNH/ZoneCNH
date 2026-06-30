# module/coinglass/server SPEC

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 数据域 · Coinglass 聚合数据接入层
- Module-Version: v0.1.0-spec
- Repository: [github.com/ZoneCNH/coinglass](https://github.com/ZoneCNH/coinglass)（server/ 子目录）
- Pattern: 继承 [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) 范式

---

## 1. Summary

`module/coinglass/server` 是 Coinglass 聚合数据的 gRPC ingest server。接收 client 流，校验聚合事件 metadata，幂等去重（含 polling 重叠窗口维度），ACK，下游分发。

## 2. Inherited Behavior

以下内容**完全继承** [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) 范式：

- §3-§6 通用问题陈述与目标
- §7 FR-001 ~ FR-008 通用 server 行为
- §8 BR-001 ~ BR-006 通用业务规则
- §9-21 通用 interface / data / config / error / edge / dependencies / testing / performance / observability / security / upgrade

## 3. Coinglass-Specific Customization

### 3.1 Source Metadata Validation

server validation 阶段额外检查：

| 字段 | 必填条件 | 失败 reject |
|------|----------|------------|
| `aggregator` | 始终必填，且必须为 `coinglass` | terminal_validation |
| `coinglass_venue` | 始终必填，且必须 ∈ canonical exchange 列表 | unsupported_channel |
| `coinglass_channel` | 始终必填，∈ {funding_rate / open_interest / liquidation / long_short_ratio} | terminal_validation |
| `window_start` / `window_end` | 始终必填 | terminal_validation |
| `interval` | channel=long_short_ratio 时必填 | terminal_validation |

特别说明：`coinglass_venue` 不在已知列表 → `unsupported_channel`（不是 `terminal_validation`），表明 client 端 venue map 需更新，向 admin 上报告警。

### 3.2 Idempotency Key Validation

server 校验幂等键必须包含相应窗口维度：

| channel | 必含 key 维度 |
|---------|--------------|
| funding_rate | `period_start` |
| open_interest | `snapshot_time` |
| liquidation | `liquidation_id` |
| long_short_ratio | `interval + window_start` |

缺失 → `contract_violation` reject。

### 3.3 Window Overlap Tolerance

相邻 poll 因 polling 间隔与 Coinglass 窗口对齐导致的重叠是预期行为。server 通过 idempotency key 自然 dedup，不需特殊处理。

### 3.4 Idempotency Store

继承 binance：Redis 为主，in-memory 为开发/测试。Coinglass 特异：TTL 调整到 7 天（覆盖典型回溯窗口）。

### 3.5 Downstream Dispatch

dispatch 给 `module/market_data` 的事件保留：
- `aggregator=coinglass` 标注，下游可基于此与直采事件区分
- 完整 window 维度，便于因子计算

### 3.6 Error Codes

错误码使用 `CGS-` 前缀，详见父规格 §12。

## 4. Test Matrix Delta

新增（编号续接 binance server TC-015）：

| TC 编号 | 场景 | 预期 |
|---------|------|------|
| TC-016 | 缺失 coinglass_venue | terminal_validation reject |
| TC-017 | 未知 coinglass_venue（不在 canonical 列表） | unsupported_channel reject + 告警 |
| TC-018 | LSR 事件缺失 interval | terminal_validation reject |
| TC-019 | 相同 venue/symbol/period_start 的 funding_rate 二次到达 | idempotent ACK，不重复 dispatch |
| TC-020 | 不同 period_start 的 funding_rate（重叠窗口） | 两次 accept，dispatch 两次 |

## 5. Release DoD Delta

继承 binance server §22，新增：

- [ ] Coinglass source metadata 全部校验实现并通过 TC-016 ~ TC-018
- [ ] 4 channel idempotency key 校验通过 TC-019/020
- [ ] Idempotency TTL 调整为 7 天
- [ ] dispatch 携带 aggregator=coinglass 与完整 window 维度
