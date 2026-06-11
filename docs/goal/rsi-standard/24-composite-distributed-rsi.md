<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 24. 组合型与分布式 RSI

## 24.1 组合型 RSI

现实中完整 RSI 未必是单个模型完成，而可能由多个 AI 组件组合形成：

```text
Research Agent
+ Coding Agent
+ Eval Agent
+ Data Agent
+ Training Orchestrator
+ Model Selector
+ Successor Model
= AI R&D 闭环
```

单独看每个组件可能不完整，组合后可能形成完整 RSI。

## 24.2 组合型 RSI 成立条件

```text
1. 至少一个 AI 组件能提出改进
2. 至少一个 AI 组件能实施改进
3. 至少一个 AI 组件能评估改进
4. 改进能进入后继 AI 系统
5. 后继系统能继续使用这些组件
```

这些功能不需要在同一个模型里。

## 24.3 分布式 RSI 的额外控制

必须控制：

```text
组件间通信
权限继承
任务委托
共享记忆
共享 artifact
审批链
跨 agent 日志
子代理创建
评测代理与被测代理隔离
```

判定应针对整个 AI-enabled R&D system，而不是单个模型。

---

