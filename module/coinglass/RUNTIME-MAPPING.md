# module/coinglass RUNTIME MAPPING

## 1. Purpose

将 `module/coinglass` 规格映射到推荐的 runtime 仓库结构。结构以 [`module/binance/RUNTIME-MAPPING.md`](../binance/RUNTIME-MAPPING.md) 为基线，叠加聚合数据源特异目录（4 channel + scheduler + venue map）。

文档路径：`module/coinglass/`
Runtime 仓库：`github.com/ZoneCNH/coinglass`

## 2. Recommended Runtime Tree

```text
github.com/ZoneCNH/coinglass/
  go.mod

  cmd/
    coinglass-client/main.go
    coinglass-server/main.go

  internal/
    client/
      app/
      config/
      channels/             # 4 channel parser（聚合数据源特异）
        funding_rate.go
        open_interest.go
        liquidation.go
        long_short_ratio.go
      scheduler/            # quota-aware polling scheduler（聚合数据源特异）
      venue_map/            # Coinglass venue → canonical exchange 映射表
      normalize/
      mapper/
      idempotency/
      spool/
      checkpoint/
      sender/
      admin/
      observability/

    server/
      app/
      config/
      ingest/
      validation/           # 含 coinglass source_metadata 校验
      idempotency/
      ack/
      dispatch/
      admin/
      observability/

  pkg/
    config/
    observability/
    version/

  test/
    contract/
    integration/            # 含 quota-tight 与 polling-overlap 场景
    fixtures/
```

## 3. 与 binance 的差异

| 差异点 | binance | coinglass |
|--------|---------|-----------|
| 采集模式 | WebSocket push | REST polling（无 WebSocket） |
| 子目录单元 | 4 connector（per product line） | 4 channels + scheduler + venue_map |
| Auth | API key + secret | API key only |
| Idempotency key | 5 维 | 4 channel 各自维度，含 window_start |
| Server validation | product_line/instrument 校验 | + aggregator/venue/channel/window 校验 |
| Idempotency TTL | 24h | 7 天（覆盖回溯窗口） |

## 4. Forbidden Runtime Imports

继承 binance §7，并新增：
- 禁止引入任何 WebSocket 客户端库（Coinglass 无 WebSocket 需求；引入会增加无关依赖与攻击面）
- 禁止 dashboard / UI 渲染库

## 5. Allowed External Dependencies

继承 binance §8。Coinglass 特异：
- `github.com/go-resty/resty/v2` 或同类 — HTTP client（含 retry、quota 感知）
- 不需要 SQLite 之外的 storage（spool 与 binance 一致使用 SQLite）

## 6. Runtime Acceptance

继承 binance §10，新增：
- 4 channel 在 30 req/min quota 内稳定运行
- venue map 测试覆盖率 100%
- polling 重叠窗口不重复 dispatch
- COINGLASS_API_KEY 在所有 artifact 零出现
