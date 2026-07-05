# TASK-BINANCE-WL-004 Whitelist Service API（全量 + 增量）

## Metadata

```yaml
TASK-BINANCE-WL-004:
  module: binance
  scope: "GET /internal/whitelist 全量+增量查询 + POST /internal/whitelist/refresh 管理端"
  spec_ref:
    - "module/binance/spec/SPEC.md#FR-047"
    - "module/binance/spec/SPEC.md#BR-009"
  files:
    - "internal/server/api/whitelist_handler.go"
    - "internal/server/api/whitelist_handler_test.go"
    - "internal/server/whitelist/service.go"
    - "internal/server/whitelist/service_test.go"
  acceptance_criteria:
    - "AC-001: GET /internal/whitelist 无 since_version 返回全量（full=true）"
    - "AC-001: GET /internal/whitelist?since_version=N 返回增量（full=false, items=变更, removed=移除）"
    - "AC-001: since_version == current_version 返回 200 + 空 items + 空 removed（不使用 304）"
    - "AC-001: market_type 过滤参数生效（spot/um_perp/cm_perp/options）"
    - "AC-001: 响应携带 base_asset/quote_asset/exchange_status/tier 冗余字段"
    - "AC-001: POST /internal/whitelist/refresh 需鉴权，触发 SyncJob.Run"
  depends_on:
    - "TASK-BINANCE-WL-003"
  estimated_effort: "4h"
  priority: P1
  status: pending
```

## Objective

为下游消费方提供白名单查询 HTTP 接口。全量 + 增量统一 200 响应（不使用 304），管理端手动触发同步。

## Scope

- `internal/server/whitelist/service.go`：`WhitelistService`
  - `GetFull(ctx, marketType) (WhitelistResponse, error)`
  - `GetIncremental(ctx, sinceVersion, marketType) (WhitelistResponse, error)`
  - `Refresh(ctx) error`（委托 `SyncJob.Run`）
- `internal/server/api/whitelist_handler.go`：Gin handler
  - `GET /internal/whitelist`：解析 query → 调 service → JSON 响应
  - `POST /internal/whitelist/refresh`：Bearer token 鉴权 → 调 `Refresh`
- `whitelist_handler_test.go` + `service_test.go`：覆盖全量/增量/无变化/过滤/鉴权

## Design Reference

- `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` §5.5
- 现有：`internal/server/server.go` Gin 路由注册模式

## Dependencies

- TASK-BINANCE-WL-003（SyncJob 提供数据 + Refresh 入口）
