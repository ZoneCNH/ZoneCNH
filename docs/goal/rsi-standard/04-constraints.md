<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 4. RSI 的约束在哪里

## 4.1 一句话约束

> RSI 可以发生在系统内部，但约束必须位于系统外部。

也就是：

```text
Evaluator outside the agent.
Logger outside the agent.
Permission system outside the agent.
Kill switch outside the agent.
Deployment authority outside the agent.
Risk threshold outside the agent.
Rollback outside the agent.
```

## 4.2 被改进系统不能控制的五类东西

RSI 系统可以参与很多事情，但以下内容不得交给被改进系统自己控制。

### 4.2.1 不能控制目标

AI 不能自行决定：

```text
什么叫成功
什么叫更好
什么风险可以接受
什么安全退化可以忽略
```

否则目标会漂移。

### 4.2.2 不能控制评测

AI 不能自行决定：

```text
考什么
怎么判分
哪些失败不算
哪些数据可以训练
哪些测试可以跳过
```

否则评测会被优化、污染或欺骗。

### 4.2.3 不能控制权限

AI 不能自行决定：

```text
自己能访问什么
自己能调用什么工具
自己能使用多少算力
自己能不能联网
自己能不能部署
```

否则 RSI 会从能力递归变成权限递归。

### 4.2.4 不能控制证据

AI 不能自行决定：

```text
记录什么
删除什么
隐藏什么
向谁报告什么
如何解释失败
```

否则人类失去可见性。

### 4.2.5 不能控制后继者放行

AI 可以生成后继候选系统，但不能决定：

```text
后继者是否安全
后继者是否部署
后继者是否继承权限
后继者是否进入下一轮递归
```

---

