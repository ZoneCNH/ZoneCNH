# TASK-NATSX-007 实现 Prompt

## 任务

NatsMessageEnvelope：traceId/messageId/schemaVersion/header 双向映射

## 规格引用

module/natsx/SPEC.md#module/natsx/SPEC.md#9-interface-contract

## 验收标准

§9: traceId/messageId/schemaVersion Header→Envelope 正确映射; §9: 已有上游 Header 不被丢弃，冲突以 Envelope 为准

## 文件

msg.go, msg_test.go

## 验证

NFR-007 verified via TC-007

## 优先级

P1

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
