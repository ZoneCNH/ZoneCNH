# ADR-008: 命名 snake_case 统一

> 状态：Accepted
> 日期：2026-06-25
> 决策者：ZoneCNH
> 关联：CLAUDE.md, AGENTS.md, PR #845

---

## 背景

module/ 下目录曾存在三种命名风格：snake_case（4）、kebab-case（20）、x-suffix（22）。CLAUDE.md 明确"所有 ZoneCNH 仓库统一 snake_case，禁止 kebab-case"，但实现与规则脱节。

---

## 决策

通过 PR #845 完成 snake_case 统一：

1. 消除全部 20 个 kebab-case 目录
2. snake_case（如 `market_regime`）+ 无分隔符小写（如 `kernel`）+ x-suffix Foundation 风格（如 `riskx`）均为合法
3. 例外仅 `x.go` 与 `binance.rs`

---

## 替代方案

### 方案 A：全部 x-suffix

- 优点：Foundation 风格统一
- 缺点：`market_data` 等非 Foundation 模块不适用
- 未选择：过度统一

---

## 后果

### 正面影响

- kebab-case = 0，3 天无回潮
- 治理规则与实现一致
- 新贡献者命名无歧义

### 负面影响

- 历史文档需更新引用

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| 回潮 | 低 | 低 | CI spec-lint 检查 |

---

## 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| PR #845 | kebab 清零 | ✅ |
| 持续 | 无回潮 | ✅ 3 天 |

---

## 参考

- PR #845
- CLAUDE.md §仓库命名规则
