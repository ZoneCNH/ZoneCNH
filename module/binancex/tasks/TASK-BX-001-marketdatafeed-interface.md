# TASK-BX-001 MarketDataFeed Interface

## Objective

定义交易所无关的 `MarketDataFeed` 接口，含全部 6 个方法和编译期接口合规检查。

## Scope

- `MarketDataFeed` 接口定义（Connect/Close/Subscribe/Unsubscribe/Events/Errors）
- Events() 返回 `<-chan FeedEvent`（只读）
- Errors() 返回 `<-chan error`（只读）
- 接口设计支持 mock 实现

## Covers

- FR-BX-001 (MarketDataFeed)
- BR-BX-001 (exchange-agnostic contract)
- BR-BX-002 (read-only channels)
- BR-BX-004 (transport/ingest separation)

## Deliverables

- `adapter.go` 中 `MarketDataFeed` 接口完整定义
- 编译期接口文档注释

## Acceptance Criteria

1. MarketDataFeed 含 6 个方法签名
2. Events() 返回 `<-chan FeedEvent`（只读，消费者不可关闭）
3. Errors() 返回 `<-chan error`（只读）
4. 接口可用于 mock 实现（无需真实 WebSocket）
5. 接口不依赖任何具体交易所 SDK 类型

## Dependencies

- `runtime-patches/domain-market` (canonical types)
