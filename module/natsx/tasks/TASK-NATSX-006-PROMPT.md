# TASK-NATSX-006 实现 Prompt

## 任务

SubjectBuilder：domain.resource.action.v{version} 构造与解析

## 规格引用

module/natsx/SPEC.md#9-interface-contract

## 验收标准

§9: Build 产出合法 subject 字符串; §9: Parse 还原 domain/resource/action/version; §9: 非法 token 拒绝并返回错误

## 文件

subject.go, subject_test.go

## 验证

NFR-006 verified via TC-006

## 优先级

P1

## 约束

- 禁止跨模块引用
- 禁止在错误/日志中打印凭证、token、消息内容
- 所有网络操作接收 context.Context
- 实现文件与测试文件在同一 task 中交付
