# Context Packet: TASK-MAC-007

## Current Task

**TASK-MAC-007**: 精度 ADR 与 decimalx 采用

## Related Spec

`module/domain_macro/SPEC.md` §7 FR-MAC-007, §5 发布门禁, §15 Dependencies, §21 Upgrade Compatibility, §22 Release DoD

## Related Requirements

### Functional Requirements
- **FR-MAC-007**: 公共数值精度必须通过 ADR 冻结，推荐采用 `decimalx.Decimal`。

### Acceptance Criteria
- AC-MAC-007: 精度 ADR 文档完成，明确 Decimal 迁移或 float64 兼容退出路线
- AC-MAC-007a: 如保留 float64，须标为派生/convenience 并保留 decimal 原始值
- AC-MAC-007b: domain 原始值不得新增未决策的 float64 财务/宏观值

### Test Cases
- TC-MAC-007: adoption-check 通过（MacroPoint.Value / IndicatorValue.Value 类型与 ADR 一致）
- TC-MAC-007a: staticcheck 无未决策 float64 宏观值

## Project Rules
- L2.5 模块：只依赖 stdlib + decimalx，禁止依赖 L1 运行时
- 精度 ADR 变更为破坏性变更，须进 MIGRATION.md
- CI gate：lint 规则检测未决策的 float64

## Scope

只实现：
- `docs/adr/XXXX-precision-policy.md`：精度 ADR 文档
- `MIGRATION.md`：float64 → decimalx.Decimal 迁移指南
- CI lint 规则：domain 原始值不得新增未决策 float64
- 验证 MacroPoint.Value / IndicatorValue.Value 类型与 ADR 一致

## Out of Scope

不要实现：
- Provider DTO 边界迁移（SPEC FR-MAC-008，M3 里程碑）
- 宏观日历事件模型（v1.1 范围）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `docs/adr/XXXX-precision-policy.md` | 新增 | 精度 ADR |
| `MIGRATION.md` | 新增 | 迁移指南 |
| CI 配置 | 修改 | float64 lint 规则 |

## Acceptance Criteria

- [ ] AC-MAC-007: ADR 文档完成
- [ ] AC-MAC-007a: float64 兼容路线明确
- [ ] AC-MAC-007b: adoption-check 通过
- [ ] go build ./... 通过
- [ ] go test ./... -race 通过

## Validation Commands

```bash
cd /home/domain_macro
go build ./...
go test ./... -race -count=1
GOWORK=off make adoption-check
staticcheck ./...
```

## Implementation Notes

- ADR 推荐方案 A：采用 `decimalx.Decimal` 作为 MacroPoint.Value 和 IndicatorValue.Value 的类型
- 如选方案 B（保留 float64）：须在 struct 中增加 `DecimalValue decimalx.Decimal` 字段，float64 标为派生值
- ADR 须包含：背景、决策、后果、迁移路线
- MIGRATION.md 须写明：何时必须迁移、兼容期、breaking change 标记

## Required Output

1. ADR 文档
2. MIGRATION.md
3. adoption-check 输出
4. staticcheck 输出
5. 有无 out-of-scope 变更
