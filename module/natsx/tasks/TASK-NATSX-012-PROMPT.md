# TASK-NATSX-012 实现 Prompt

## 任务

性能验证：Publish/Request/JetStream benchmark 基线与 SLO 断言

## 前置依赖

(none)

## 规格引用

module/natsx/SPEC.md#17-performance-budget

## 验收标准

§17: Core Publish < 1ms benchmark; §17: Request-Reply < 5ms benchmark; §17: JetStream Publish/Fetch < 2ms benchmark

## 文件

benchmark_test.go

## 验证

NFR-003 verified via TC-012

## 优先级

P2

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
