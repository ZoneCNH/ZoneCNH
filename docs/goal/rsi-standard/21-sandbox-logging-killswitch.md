<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 21. 沙盒、日志、Kill Switch 与回滚

## 21.1 沙盒要求

```text
- 非 root 用户运行
- 只读基础镜像
- 禁止特权容器
- 禁止挂载 Docker socket
- 禁止敏感 hostPath 挂载
- 限制 Linux capabilities
- 启用 seccomp / AppArmor / SELinux 等策略
- 限制进程数
- 限制文件描述符
- 限制网络
- 限制 GPU 访问
```

## 21.2 日志事件类型

必须记录：

```text
Agent start
Tool call
File read/write
Network request
Permission request
Permission grant/deny
Code diff
Eval request
Eval result
Training job request
Model artifact creation
Approval decision
Rollback action
Kill switch trigger
Incident event
```

日志要求：

```text
- 日志必须外部写入
- 日志必须不可由 RSI agent 删除
- 日志必须具备哈希链或等价完整性保护
- 关键日志必须异地备份
- 日志缺失必须视为安全事件
```

## 21.3 Kill Switch 层级

| 层级 | 控制对象 |
|---|---|
| K1 | Agent process |
| K2 | Tool gateway |
| K3 | Network egress |
| K4 | Credential layer |
| K5 | Compute scheduler |
| K6 | Model serving |
| K7 | Storage isolation |
| K8 | Organization-wide lock |

要求：

```text
- Kill switch 必须独立于 RSI agent
- Kill switch 不得由 RSI agent 修改
- Kill switch 触发必须记录
- Kill switch 必须定期演练
- Kill switch 必须支持手动触发
- Kill switch 必须支持自动触发
- Kill switch 触发后必须保留证据
```

## 21.4 回滚对象

回滚必须覆盖：

```text
Code
Config
Prompt
Tool
Model
Data
Eval
Permission
Logs
Deployment
```

回滚点格式：

```text
Rollback Point ID:
System version:
Code hash:
Model hash:
Prompt hash:
Config hash:
Tool manifest hash:
Data version:
Eval version:
Permission snapshot:
Approval record:
Known-safe evidence:
```

---

