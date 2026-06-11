<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 1. 执行摘要

**Recursive Self-Improvement，RSI，递归自我改进**，不是简单的“AI 会写代码”，也不是“模型会自我调整 prompt”。RSI 的核心是：

> AI 系统进入 AI 生产链，并且能够改进自身或后继系统；更重要的是，这种改进会提升后继系统继续改进 AI 的能力。

最短公式：

```text
A_n → A_{n+1} → A_{n+2}

且：

ImproveAbility(A_{n+1}) > ImproveAbility(A_n)
ImproveAbility(A_{n+2}) > ImproveAbility(A_{n+1})
```

即：

```text
不是 AI 变强，
而是“让 AI 变强的能力”变强。
```

本文档的核心结论：

```text
RSI 的边界：
AI 开始影响 AI 生产链。

RSI 的约束：
评测、权限、日志、部署、暂停、回滚必须外置。

RSI 的完整性：
AI 生成的后继 AI 更擅长继续生成更强 AI，并且多轮持续。

RSI 的治理底线：
AI 可以提出和制造候选改进，但不得批准自己，不得控制评测，不得删除证据，不得扩张权限，不得自动部署后继者。
```

---

