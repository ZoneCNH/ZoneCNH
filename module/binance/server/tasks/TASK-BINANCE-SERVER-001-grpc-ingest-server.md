> ⚠️ **归档警告（v2.0.0）**：本 Task 基于旧架构（gRPC / SQLite spool / 同进程 ACK），已被 v2.0.0 分布式架构取代。
> - CLIENT-008 → 替换为 `TASK-BINANCE-CLIENT-014-natsx-publisher.md`
> - CLIENT-009 → 删除（natsx JetStream 持久化替代 spool + checkpoint）
> - SERVER-001 → 替换为 `TASK-BINANCE-SERVER-010-natsx-consumer.md`
> - SERVER-004 → 删除（natsx ManualAck 替代 gRPC ACK）
>
> 保留本文件仅供历史参考，不得作为新实现输入。

# TASK-BINANCE-SERVER-001 gRPC Ingest Server

## Objective

Implement the Binance-specific server side of the contracts-defined `MarketDataService`.

## Scope

The server accepts gRPC ingest streams from `module/binance/client`.

## Deliverables

- gRPC server skeleton
- stream lifecycle handler
- request receive loop
- graceful shutdown behavior
- stream tests

## Acceptance Criteria

- server implements generated gRPC interface.
- server accepts `IngestRequest` stream.
- server returns `IngestAck` stream.
- server records stream id and metadata.
- server does not import client internals.
- server does not connect to Binance exchange endpoints.

## Dependencies

- `module/contracts`
