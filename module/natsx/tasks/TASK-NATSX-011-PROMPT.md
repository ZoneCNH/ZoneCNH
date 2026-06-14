# TASK-NATSX-011 实现 Prompt

## 任务

安全注入：凭证环境变量、TLS 配置、日志脱敏、live integration

## 前置依赖

(none)

## 规格引用

module/natsx/SPEC.md#19-security, module/natsx/SPEC.md#BR-008

## 验收标准

§19: FOUNDATIONX_NATS_TOKEN/USERNAME/PASSWORD/NKEY 安全加载; §19: TLS ca-file 可配置，配置错误不泄露凭据; §19: live integration 测试通过且输出不含凭据

## 文件

config.go, live_integration_test.go

## 验证

NFR-001 verified via TC-011; NFR-002 verified via TC-011

## 优先级

P1

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
