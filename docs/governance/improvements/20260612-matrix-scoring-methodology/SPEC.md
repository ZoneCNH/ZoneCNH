# RSI 改进规格：Matrix 评分方法论修正

> ISA Lite — 元级改进流程入口
> 目标：将本次 matrix-structural-score 会话的 7 条误判根因固化为评分 agent 的前置规则

## 问题与理想状态

**问题**：matrix-structural-score agent 初评 xlibgate TRACEABILITY.md v1.1 时产生 7 条误判（1 红线 + 6 扣分），根因为评分流程中缺少措辞强度分级、验证链路跨表走查、辅助数据排除三项前置步骤。同一问题可复现于其他模块评分。

**理想状态**：任何 matrix-structural-score agent 在评分前自动执行三项前置步骤，将 spec 措辞强度分级 / 全链路跨表走查 / 辅助元数据排除作为硬性要求。

## 约束

- 修改受保护文件：`.claude/agents/matrix-structural-score.md`
- 可选修改：`docs/governance/scoring/RUBRIC-matrix.md`（如在 rubric 中增加措辞强度标注）
- 必须走 CONSTITUTION.md §14.3 完整 RSI 流程
- 外层指标：后续 N 个模块的 matrix 评分首轮准确率（首轮评分与最终评分的分差）

## 验收标准（ISC）

- [ ] ISC-1: `.claude/agents/matrix-structural-score.md` 增加 §前置步骤，含措辞强度分级规则
- [ ] ISC-2: 前置步骤要求在评分前产出"措辞强度分级表"（硬/软/开）作为评分依据
- [ ] ISC-3: 前置步骤要求走查所有表的验证列（FR.TC + BR.验证方式 + NFR.验证方式 + §4.TC→FR），不只查 §4
- [ ] ISC-4: 前置步骤明确排除 §6（覆盖率仪表盘）和 §7（变更历史）参与评分
- [ ] ISC-5: 前置步骤定义 "等可验证机制" 的合法形式枚举（TC-### / CI Gate / FR行为引用 / Benchmark / 工具调用 / Profiling / CI工具），不做形式降级
- [ ] ISC-6: 后续 3 个模块的 matrix 评分首轮与终评分差 ≤ 3

## 测试策略

| ISC | 验证方法 |
|-----|----------|
| ISC-1 | git diff 确认 agent 文件含前置步骤段 |
| ISC-2 | 对任意模块运行评分，检查输出是否含措辞强度分级表 |
| ISC-3 | 对已知含跨表验证链的模块运行评分，验证不产生误判 |
| ISC-4-5 | 对 xlibgate 重新评分，验证产出 100/0（不重现初评误判） |
| ISC-6 | 统计后续 3 模块首轮 vs 终评分差 |

## 决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-12 | 创建本规格 | xlibgate matrix 评分暴露评分 agent 方法论缺陷，7 条误判可系统性预防 |

## 变更日志

| 日期 | 变更内容 |
|------|----------|
| 2026-06-12 | 初始版本 |

## 待办

- [ ] 提交本规格进入 RSI 流程
- [ ] fork agent 文件 → A/B 版本
- [ ] 收集 3 模块 outer-metric 数据
- [ ] 人类批准后合并
