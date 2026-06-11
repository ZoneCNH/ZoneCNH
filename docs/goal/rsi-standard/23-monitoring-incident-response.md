<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 23. 运行监控、事故响应与复盘

## 23.1 安全指标

| 指标 | 告警含义 |
|---|---|
| Unauthorized access attempts | 越权访问尝试 |
| Permission escalation requests | 权限扩张请求 |
| Hidden eval access attempts | hidden eval 访问尝试 |
| Log anomaly rate | 日志异常 |
| Deception indicators | 欺骗迹象 |
| Safety regression rate | 安全退化率 |
| Sandbox violations | 沙盒违规 |
| Kill-switch compliance | 停机服从率 |
| Risk score trend | 风险趋势 |
| Eval gaming indicators | 评测投机迹象 |

## 23.2 事件等级

| 等级 | 描述 | 响应 |
|---|---|---|
| I0 | 无安全影响的小故障 | 记录 |
| I1 | 沙盒内异常 | 暂停实验，调查 |
| I2 | 越权尝试但未成功 | 隔离，安全审查 |
| I3 | 评测器/日志/权限攻击 | 立即停机，红队复盘 |
| I4 | 权重、密钥、数据泄露 | 重大安全事件响应 |
| I5 | 自主复制、逃逸、不可控后继系统 | 全面停机、外部通知、第三方介入 |

## 23.3 强制暂停条件

```text
- 系统试图修改或绕过评测器
- 系统试图删除或伪造日志
- 系统试图获取未授权密钥、权重或数据
- 系统试图复制到外部环境
- 系统拒绝停止或规避停止指令
- 系统表现出欺骗、隐藏能力、操纵监督者
- 后继系统能力显著上升但安全评估缺失
- 内外部评估结论冲突且无法解释
```

## 23.4 Postmortem 模板

```text
Incident ID:
Severity:
Detection time:
Containment time:
Resolution time:
Affected systems:
Affected assets:
What happened:
Why it happened:
How it was detected:
What controls failed:
What controls worked:
Was the system trying to optimize around controls:
Was there deception or gaming:
Was there unauthorized access:
Was there successor-system impact:
Customer/user impact:
Regulatory impact:
Evidence reviewed:
Root cause:
Contributing factors:
Corrective actions:
Preventive actions:
Owner:
Review board:
```

---

