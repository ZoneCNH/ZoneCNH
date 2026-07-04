# TASK-BINANCE-WL-006 下游消费方 SDK（缓存 + NATS 订阅 + 容灾降级）

## Metadata

```yaml
TASK-BINANCE-WL-006:
  module: binance
  scope: "下游消费方 SDK：HTTP 拉取 + 3h TTL 缓存 + NATS 订阅 + 容灾降级"
  spec_ref:
    - "module/binance/spec/SPEC.md#FR-049"
    - "module/binance/spec/SPEC.md#BR-009"
  files:
    - "pkg/whitelistclient/client.go"
    - "pkg/whitelistclient/client_test.go"
    - "pkg/whitelistclient/cache.go"
    - "pkg/whitelistclient/cache_test.go"
  acceptance_criteria:
    - "AC-001: 首次启动全量拉取 GET /internal/whitelist，写入内存+落盘缓存"
    - "AC-001: 定时刷新每 3h + ±10min 随机抖动"
    - "AC-001: NATS 订阅 binance.whitelist.version，收到通知立即增量刷新"
    - "AC-001: 增量刷新带 since_version，合并 diff 到本地缓存"
    - "AC-001: 服务端不可达时使用本地缓存，记录 cache age"
    - "AC-001: cache age 3h~24h 仅上报监控；>24h 高优先级告警，默认 fail open"
    - "AC-001: 多实例各自独立刷新，无需分布式锁"
    - "AC-001: 进程重启后从落盘缓存恢复，避免空窗"
  depends_on:
    - "TASK-BINANCE-WL-004"
    - "TASK-BINANCE-WL-005"
  estimated_effort: "6h"
  priority: P2
  status: pending
```

## Objective

为策略/行情/风控等下游服务提供统一的白名单消费 SDK。封装 HTTP 拉取、本地缓存、NATS 订阅、容灾降级，下游只需 `client.GetWhitelist()` 即可获取当前生效白名单。

## Scope

- `pkg/whitelistclient/cache.go`：`Cache` 结构
  - 内存 map + 落盘文件（JSON），进程重启恢复
  - `Get(marketType, symbol) (WhitelistEntry, bool)`
  - `ApplyFull(resp WhitelistResponse)` / `ApplyIncremental(resp WhitelistResponse)`
  - `Age() time.Duration`（缓存年龄）
  - `Version() int64`（本地版本号）
- `pkg/whitelistclient/client.go`：`Client` 结构
  - `New(serverURL, natsURL, opts) *Client`
  - `GetWhitelist(marketType) ([]WhitelistEntry, error)`：读缓存（不阻塞）
  - `Start(ctx)`：启动定时刷新 + NATS 订阅
  - `Stop()`：优雅关闭
  - 容灾降级逻辑：分级容忍（3h~24h 监控、>24h 告警 fail open）
- `client_test.go` + `cache_test.go`：覆盖全量/增量/容灾/重启恢复

## Design Reference

- `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.7
- 现有：`pkg/binancecfg/`（SDK 包结构参考）

## Dependencies

- TASK-BINANCE-WL-004（API 可用）
- TASK-BINANCE-WL-005（NATS 推送可用）
