# TASK-NATSX-002 实现 Prompt

## 任务

Request-Reply 模式：responder、timeout、ctx cancel

## 前置依赖

TASK-NATSX-001

## 规格引用

module/natsx/SPEC.md#FR-003, module/natsx/SPEC.md#BR-003

## 验收标准

AC-003: Request 有 responder 时返回响应数据; AC-003: Request 无 responder 时超时返回错误; AC-003: Request ctx 取消时返回 ctx.Err()

## 文件

client.go, client_test.go

## 验证

FR-003 verified via TC-002

## 优先级

P0

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
