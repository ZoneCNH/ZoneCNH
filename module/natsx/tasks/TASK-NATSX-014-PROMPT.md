# TASK-NATSX-014 实现 Prompt

## 任务

发布就绪：README、CHANGELOG、CI gate 集成、测试覆盖率

## 规格引用

module/natsx/SPEC.md#20-ci-gate, module/natsx/SPEC.md#22-release-dod

## 验收标准

§20: CI gate 全绿（build/test/vet/lint/secret scan）; §22: 测试覆盖率 >= 80%，benchmark 无 >10% 回退; §22: README 含快速开始 + API 概览，CHANGELOG 记录 v1.0.0

## 文件

go.mod, README.md, CHANGELOG.md, example_test.go, integration_test.go

## 验证

NFR-005 verified via TC-014

## 优先级

P2

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
