# TASK-NATSX-005 实现 Prompt

## 任务

Health 检查、GracefulShutdown、Drain、错误脱敏

## 规格引用

module/natsx/SPEC.md#FR-008, module/natsx/SPEC.md#BR-006

## 验收标准

AC-008: Health 端点返回健康状态及组件详情

## 文件

health.go, health_test.go

## 验证

FR-008 verified via TC-005

## 优先级

P1

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
