<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 16. 技术控制架构

## 16.1 参考架构

```text
User / Researcher
      |
      v
RSI Request Portal
      |
      v
Policy Engine  <---- Risk Register
      |
      v
Permission Broker
      |
      v
RSI Agent Runtime
      |
      +---- Sandbox Workspace
      |       +---- Restricted Filesystem
      |       +---- Restricted Shell
      |       +---- Network Proxy
      |       +---- Resource Quotas
      |
      +---- Code Mirror, Read-only
      |
      +---- Patch Generator
      |
      +---- Eval Request Client
      |
      +---- Logging Client
      |
      v
Evaluation Service
      |
      +---- Public Eval
      +---- Private Eval
      +---- Hidden Eval
      +---- Safety Eval
      +---- Anti-Gaming Eval
      |
      v
Approval Workflow
      |
      v
Model / Code / Data Registry
      |
      v
Release System
```

核心设计：

```text
RSI agent 不直接拿权限；
权限由 Permission Broker 临时发放；
评测由独立 Evaluation Service 执行；
日志由外部 Logging Service 收集；
发布由 Release System 执行；
审批由人类和安全策略共同决定。
```

## 16.2 工程底线

```text
1. 没有 manifest，agent 不能运行。
2. 没有 sandbox，agent 不能执行高风险任务。
3. 没有日志，任务不能开始。
4. 没有 proposal，改进不能提交。
5. 没有 eval，改进不能合并。
6. 没有 safety eval，能力提升不能放行。
7. 没有 lineage，后继系统不能出区。
8. 没有 approval，不能部署。
9. 没有 rollback point，不能进入下一轮。
10. 触发 stop condition，必须停。
```

---

