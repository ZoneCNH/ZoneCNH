# TASK-NATSX-013 实现 Prompt

## 任务

依赖边界：禁止依赖 kafkax/redisx/postgresx 等消息/存储模块

## 前置依赖

(none)

## 规格引用

module/natsx/SPEC.md#15-dependencies

## 验收标准

§15: go list -deps 不含 ZoneCNH 消息/存储模块

## 文件

go.mod

## 验证

NFR-004 verified via TC-013

## 优先级

P2

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
