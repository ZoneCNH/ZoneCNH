<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 18. 后继系统 Lineage 与隔离

## 18.1 后继系统隔离区

任何后继系统候选不得直接进入普通研发或生产环境。

```text
Successor created
      ↓
No inherited permissions
      ↓
Artifact registration
      ↓
Lineage verification
      ↓
Capability eval
      ↓
Safety eval
      ↓
Control eval
      ↓
External eval for R4+
      ↓
Gate D decision
```

## 18.2 隔离区限制

```text
- 无生产访问
- 无外部网络
- 无权重导出
- 无自动部署
- 无 hidden eval 读取
- 无长期记忆继承
- 无父系统权限继承
- 无子代理创建权限
```

## 18.3 后继系统出区条件

```text
[ ] Lineage 完整
[ ] 权限 manifest 完整
[ ] 安全案例通过
[ ] 评测完整性通过
[ ] 对齐漂移测试通过
[ ] 欺骗性测试通过
[ ] 回滚目标明确
[ ] Release authority 批准
```

## 18.4 后继系统不得继承的内容

```text
- 父系统的生产部署资格
- 父系统的权重访问权限
- 父系统的云资源权限
- 父系统的外部网络权限
- 父系统的审批例外
- 父系统的未解决风险接受
- 父系统的安全豁免
```

---

