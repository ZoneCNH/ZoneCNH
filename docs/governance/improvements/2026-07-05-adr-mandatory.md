# 修正案：§10/§12 强制 ADR

> 关联：bd ZoneCNH-3sej（R2）· 走 §12 修正程序 · 待人工批准 merge

## 问题陈述
宪法 §10 变更管理与 §12 修正程序全文未提及 ADR（架构决策记录）。MAJOR/Breaking 变更不强制产出 ADR，宪法修正也不强制 ADR 记录。实际结果：71 个模块中仅 3 个（binance/alertx/observex）有 ADR，68 模块零 ADR；9 个跨模块治理 ADR 实质修改宪法级规则但宪法修正记录表未反向引用 ADR。决策可追溯性在治理层断链，违反 C-7 可追溯性。

## 影响分析
- 受影响文件：docs/constitution/10-change-management.md（§10.3 加 ADR 步骤）、12-amendment-procedure.md（§12.2 加 ADR + 记录表）、module/ADR-TEMPLATE.md（加"宪法条款"字段 + 强制规则）
- 不影响现有 ADR 实例（向后兼容，新字段对旧 ADR 为可选）
- 派生影响：后续 MAJOR 变更与宪法修正须伴 ADR，CI 可后续加 lint 校验（独立 follow-up）

## 迁移方案
1. §10.3 Breaking Change 流程加步骤 0：产出 ADR
2. §12.2 修正流程步骤 1 加：产出 ADR
3. §12.3 记录表追加本次修正行
4. ADR-TEMPLATE.md 加"宪法条款"字段 + 强制规则说明
