> ⚠️ **归档警告（v2.0.0）**：本 Task 基于旧架构（gRPC / SQLite spool / 同进程 ACK），已被 v2.0.0 分布式架构取代。
> Status: Archived
> - CLIENT-008 → 替换为 `TASK-BINANCE-CLIENT-014-natsx-publisher.md`
> - CLIENT-009 → 删除（natsx JetStream 持久化替代 spool + checkpoint）
> - SERVER-001 → 替换为 `TASK-BINANCE-SERVER-010-natsx-consumer.md`
> - SERVER-004 → 删除（natsx ManualAck 替代 gRPC ACK）
>
> 保留本文件仅供历史参考，不得作为新实现输入。

# TASK-BINANCE-SERVER-004 Ingest ACK

## Objective

Generate ACK/reject responses that allow client checkpoint progression.

## Scope

ACK logic covers:

- accepted events
- duplicates
- rejects
- retry hints
- stream restart compatibility

## Deliverables

- ACK model
- reject model
- ACK builder
- tests with client checkpoint fixtures

## Acceptance Criteria

- accepted event returns durable ACK.
- duplicate already accepted event returns idempotent ACK or equivalent accepted status.
- terminal reject is clearly classified.
- retryable reject is clearly classified.
- client can determine whether checkpoint may advance.
- ACK never claims durable acceptance before acceptance boundary is satisfied.

## Dependencies

- SERVER-003 idempotency
- CLIENT-009 checkpoint semantics
