> ⚠️ **归档警告（v2.0.0）**：本 Task 基于旧架构（gRPC / SQLite spool / 同进程 ACK），已被 v2.0.0 分布式架构取代。
> - CLIENT-008 → 替换为 `TASK-BINANCE-CLIENT-014-natsx-publisher.md`
> - CLIENT-009 → 删除（natsx JetStream 持久化替代 spool + checkpoint）
> - SERVER-001 → 替换为 `TASK-BINANCE-SERVER-010-natsx-consumer.md`
> - SERVER-004 → 删除（natsx ManualAck 替代 gRPC ACK）
>
> 保留本文件仅供历史参考，不得作为新实现输入。

# TASK-BINANCE-CLIENT-008 gRPC Sender

## Objective

Send canonical events from client to server through contracts-defined gRPC streaming.

## Scope

Implement the client side of `MarketDataService.Ingest`.

## Deliverables

- gRPC sender
- stream lifecycle management
- reconnect/retry behavior
- ACK/reject handling
- sender tests with mock server

## Acceptance Criteria

- sender uses generated contracts client.
- sender does not import server internals.
- sender supports bidirectional streaming ACK when available.
- sender can resume from spool after reconnect.
- sender does not advance checkpoint before server durable ACK.
- reject responses are classified as retryable or terminal.

## Dependencies

- CLIENT-007 mapper
- CLIENT-009 spool/checkpoint
- SERVER-001/SERVER-004 contract semantics
