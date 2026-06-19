# Foundation Production Standards

## Layer Model

- L0 Foundation
- L1 Runtime
- L2 Infra
- L3 Reliability
- L4 Observability
- L5 Contracts
- L6 Transport

## Dependency Rules

- 禁止循环依赖
- 禁止 infra leakage
- 禁止 runtime leakage
- 所有模块必须显式声明 dependency

## Entropy Rules

禁止：
- util dumping
- uncontrolled abstraction
- hidden runtime state
- dynamic architecture mutation

## AI Constraints

AI 不允许：
- 创建未注册模块
- 修改 contracts without review
- 创建动态结构
- 绕过 governance

## Production Constitution

所有模块必须：

- 可观测
- 可审计
- 可恢复
- 可回放
- 可升级
- 可验证