# TASK-NATSX-001 实现 Prompt

## 任务

Publish/Subscribe 基础接口：subject 校验、handler 注册、连接错误处理

## 规格引用

module/natsx/SPEC.md#FR-001,module/natsx/SPEC.md#FR-002,module/natsx/SPEC.md#BR-001,module/natsx/SPEC.md#BR-004,module/natsx/SPEC.md#BR-009,

## 验收标准

AC-001: Publish 到合法 subject 被 handler 消费;AC-002: Subscribe 注册 handler 并接收消息;

## 文件

client.go, subscription.go, msg.go, errors.go, client_test.go

## 验证

FR-001 verified via TC-001;FR-002 verified via TC-001;

## 优先级

P0

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
