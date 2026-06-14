# TASK-NATSX-004 实现 Prompt

## 任务

AddStream/AddConsumer：创建、幂等、冲突配置、drain

## 规格引用

module/natsx/SPEC.md#FR-006, module/natsx/SPEC.md#FR-007, module/natsx/SPEC.md#BR-005

## 验收标准

AC-006: AddStream 创建或幂等返回已有 stream; AC-007: AddConsumer 创建或幂等返回已有 consumer

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
