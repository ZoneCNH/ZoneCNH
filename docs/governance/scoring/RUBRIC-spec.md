# Spec 评分 Rubric

> 评分对象：`module/{module}/SPEC.md`
> 总分：100；维度详见下表。

参考 `.claude/agents/spec-structural-score.md` 和 `.codex/agents/spec-structural-score.toml` 的完整算法定义。本文件作为三平台共享 rubric 引用源。

## 维度（满分 100）

| 维度 | 满分 | 检查重点 |
|------|------|----------|
| 23 节结构与元数据 | 15 | 章节齐全、关键章节非空、Metadata 完整且状态合法 |
| 清晰性与范围边界 | 12 | Summary、Problem、Goals、Non-goals、Consumers 是否具体 |
| FR/BR 行为规格 | 15 | FR 的 WHEN/THEN、BR 的违反后果、编号连续唯一 |
| 追溯链闭合 | 15 | FR → AC → TC 是否闭合，BR/NFR 是否有验证方式 |
| 接口/数据/配置/错误契约 | 13 | Interface、Data Model、Config、State、Error Handling |
| 边界场景/安全/可观测/性能 | 12 | Edge Cases、安全边界、观测项、性能预算 |
| 测试/CI/Release DoD | 10 | Testing Strategy、CI Gate、Release DoD |
| 治理/生命周期/依赖/变更 | 8 | Constitution、Lifecycle、Dependencies、Compatibility、Rollout |

## 阶段特定红线

- 23 节缺失或空壳。
- Metadata 关键字段缺失。
- FR 缺 WHEN/THEN 或 AC/TC 映射。
- Blocking Open Questions 存在。
- Non-goals < 3 或 Edge Cases < 5。
- Breaking Change 缺迁移/回滚说明。

## 通过门禁

机器评分 `composite_score = min(四源评分)` 且 `composite_score >= 98`、无红线、无 LLM 低置信度、LLM 分差与 rules 异构分歧在阈值内。`Status: Approved` 由 arbiter pass 后自动翻转；`spec-review` 仅作为评分证据和对抗性参考，不构成独立 gate。
