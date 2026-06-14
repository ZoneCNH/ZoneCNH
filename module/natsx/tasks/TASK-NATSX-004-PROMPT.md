# TASK-NATSX-004 实现 Prompt

## 任务

AddStream/AddConsumer：创建、幂等、冲突配置、drain

## 前置依赖

TASK-NATSX-003

## 规格引用

module/natsx/SPEC.md#FR-006, module/natsx/SPEC.md#FR-007, module/natsx/SPEC.md#BR-005

## 验收标准

AC-006: AddStream 创建不存在的 stream 返回 nil; AC-006: AddStream 重复调用且配置兼容返回 nil（幂等）; AC-006: AddStream 重复调用且配置冲突返回 ErrStreamExists; AC-007: AddConsumer 创建不存在的 consumer 返回 nil; AC-007: AddConsumer 重复调用且配置兼容返回 nil（幂等）; AC-007: AddConsumer 重复调用且配置冲突返回 ErrConsumerExists

## 文件

jetstream.go, options.go, internal/reconnect/backoff.go, jetstream_test.go

## 验证

FR-006 verified via TC-003; FR-007 verified via TC-003

## 优先级

P0

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
