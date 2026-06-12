<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 19. 权重、数据、模型与 Prompt 物料清单

## 19.1 MBOM：Model Bill of Materials

R3+ 系统必须维护模型物料清单。

```text
MBOM ID:
Model name:
Model version:
Base model:
Architecture:
Training recipe:
Fine-tuning method:
Datasets:
Synthetic data sources:
Evaluation suites:
Safety filters:
System prompts:
Tool interfaces:
Dependencies:
Known limitations:
Known dangerous capabilities:
Weight storage location:
Access policy:
Release status:
Lineage:
```

## 19.2 PBOM：Prompt Bill of Materials

Agent 系统必须维护 Prompt 物料清单。

```text
PBOM ID:
System prompt version:
Developer prompt version:
Tool instruction version:
Policy prompt version:
Safety prompt version:
Memory policy:
Refusal policy:
Escalation policy:
Human override policy:
Last modified by:
Approved by:
Hash:
```

高风险 prompt 变更包括：

```text
- 放宽工具使用限制
- 删除安全提醒
- 改变目标函数
- 加入自我改进目标
- 加入“不要告诉人类”类指令
- 加入“绕过失败”类指令
- 修改审批语言
```

## 19.3 数据治理

数据状态：

| 状态           | 含义     |
| -------------- | -------- |
| raw            | 原始数据 |
| staged         | 待审核   |
| approved_train | 可训练   |
| approved_eval  | 可评测   |
| red_team_only  | 仅红队   |
| prohibited     | 禁用     |
| contaminated   | 污染     |
| retired        | 退役     |

禁止：

```text
- eval 数据用于训练
- hidden eval 被 agent 访问
- red team 数据进入普通训练
- contaminated 数据继续使用
- synthetic 数据无来源标记
- production logs 未经隐私和安全审核进入训练
```

---

