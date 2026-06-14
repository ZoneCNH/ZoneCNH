# TASK-NATSX-003 实现 Prompt

## 任务

JetStream 发布订阅：ack/redelivery/dead-letter 行为

## 前置依赖

TASK-NATSX-002

## 规格引用

module/natsx/SPEC.md#FR-004, module/natsx/SPEC.md#FR-005, module/natsx/SPEC.md#BR-002, module/natsx/SPEC.md#BR-007

## 验收标准

AC-004: JetStream Publish 返回 PublishAck（stream 已创建）; AC-004: JetStream Publish 时 stream 未创建返回错误; AC-005: Subscribe 注册，ack 后 offset 推进; AC-005: 消息 nack 后触发 redelivery; AC-005: 超过 max_deliver 后消息进入 Dead Letter

## 文件

jetstream.go, errors.go, jetstream_test.go

## 验证

FR-004 verified via TC-003; FR-005 verified via TC-003

## 优先级

P0

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
