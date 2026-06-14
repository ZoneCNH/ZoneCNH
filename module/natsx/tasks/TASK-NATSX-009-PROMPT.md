# TASK-NATSX-009 实现 Prompt

## 任务

可观测集成：foundationx_nats_* 指标、连接事件日志、错误脱敏

## 规格引用

module/natsx/SPEC.md#18-observability

## 验收标准

§18: foundationx_nats_publish_total 等 counter 正确 emit; §18: foundationx_nats_connection_state gauge 反映连接状态; §18: 错误/日志不含 payload/credential 内容

## 文件

natsx.go, metrics_test.go

## 验证

NFR-009 verified via TC-009

## 优先级

P1

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
