# 修正案：§13.1 显式定位 goal 文档

> 关联：bd ZoneCNH-3sej（R1）· 走 §12 修正程序 · 待人工批准 merge

## 问题陈述
§13.1 效力层级未列出 docs/goal/ 文档，但 LIFECYCLE.md / DEFINITION-OF-READY.md / DEFINITION-OF-DONE.md / STRUCTURAL-SCORING.md 均投影声明指向 docs/goal/05-layer-standards.md、06-dod.md 作为 canonical SSOT。这制造了"效力层级之外的权威源"——当 goal 文档与 governance 冲突时，§13.1 无法裁决。

已知落地矛盾：Spec 状态六态（LIFECYCLE.md）vs 四态（docs/goal/05-layer-standards.md §1），spec-lint 仍按六态校验，靠"双重定义以 Goal Gate 为准"声明缓解，但实现层未对齐。

## 影响分析
- 受影响文件：docs/constitution/13-supreme-clause.md（§13.1 层级表 + 说明段）
- 不涉及 SPEC / ARCHITECTURE / FOUNDATION-DEPS 变更（仅效力层级声明）
- 派生影响：R1 修复后，Spec 六态/四态矛盾的裁决路径明确化（以 goal 四态为 canonical，LIFECYCLE 六态为投影），后续 spec-lint 对齐工作可据此推进（独立 follow-up）

## 迁移方案
在 §13.1 效力层级中，于"本宪法"与"模块规格"之间插入"交付管线 canonical 规范 (docs/goal/)"层，并追加 canonical 源说明段。goal 文档修订走 §12 程序。
