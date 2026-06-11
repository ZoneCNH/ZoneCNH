<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 9. RSI 的完整性判定公式

## 9.1 基本公式

```text
普通改进：
A_n 在任务 X 上更强。

RSI：
A_n 产生 A_{n+1}，
且 A_{n+1} 比 A_n 更擅长产生 A_{n+2}。
```

## 9.2 完整 RSI 公式

```text
完整 RSI =
自主改进能力
× 后继系统生成能力
× 改进能力可继承
× 多轮闭环
× 人类不再是核心研发瓶颈
```

## 9.3 风险函数

```text
Risk(n+1) = Risk(n)
          + Capability_Delta(n)
          + Autonomy_Delta(n)
          + Access_Delta(n)
          + Opacity_Delta(n)
          + Misuse_Delta(n)
          - Control_Delta(n)
          - Evaluation_Confidence(n)
```

原则：

```text
能力提升本身不是禁止项；
能力提升但控制没有同步提升，是风险项；
能力提升但评估置信度下降，是重大风险项；
能力提升但安全退化不可解释，是停止项。
```

---

