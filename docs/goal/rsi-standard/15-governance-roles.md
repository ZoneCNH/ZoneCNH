<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 15. 治理角色与责任分离

## 15.1 必要角色

| 角色 | 职责 |
|---|---|
| Board / 高层风险委员会 | 批准 R4/R5 项目、风险偏好、暂停机制 |
| RSI Safety Officer | 拥有安全否决权 |
| Release Authority | 批准部署和权限变更 |
| Independent Evaluator | 独立评估能力和风险 |
| Red Team | 对抗测试、欺骗测试、越权测试 |
| Security Officer | 权重、密钥、网络、供应链安全 |
| Incident Commander | 安全事件响应 |
| Model Owner | 负责模型生命周期证据 |
| Data Steward | 负责数据来源、许可、污染控制 |
| Audit Lead | 负责审计证据与合规报告 |

## 15.2 权力分离

以下职责不得由同一主体同时承担：

| 职责 A | 职责 B |
|---|---|
| 开发 RSI 系统 | 批准部署 RSI 系统 |
| 生成评测结果 | 审核评测完整性 |
| 修改评测器 | 使用评测器放行模型 |
| 管理生产密钥 | 运行自修改代理 |
| 训练后继系统 | 独立评估后继系统 |
| 设定风险阈值 | 判断自己是否超过阈值 |

---

