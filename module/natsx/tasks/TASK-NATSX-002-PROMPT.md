# TASK-NATSX-002 实现 Prompt

## 任务

Request-Reply 模式：responder、timeout、ctx cancel

## 规格引用

module/natsx/SPEC.md#FR-003,module/natsx/SPEC.md#BR-003,

## 验收标准

AC-003: Request 在超时内收到 Response;

## 文件

client.go, client_test.go

## 验证

FR-003 verified via TC-002;

## 优先级

P0

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
