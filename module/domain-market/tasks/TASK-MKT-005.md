# TASK-MKT-005

> derivative validate：衍生品指标校验

---

```yaml
task_id: TASK-MKT-005
module: domain-market
version: v1.0.0
spec_ref:
  - "module/domain-market/SPEC.md#FR-MKT-007"
fr_ref: FR-MKT-005
ac_ref: AC-MKT-005
tc_ref: TC-MKT-005
acceptance_criteria:
  - "AC-MKT-005: 衍生品指标具备来源与时间语义"
status: pending
priority: P1
estimated_effort: "1.5h"
depends_on:
  - TASK-MKT-001
  - TASK-MKT-003
```

---

## 目标

Funding、OpenInterest、LongShortRatio 必须有明确时间语义与数据来源。

## 验收标准

- [ ] AC-MKT-005: 衍生品指标具备来源与时间语义
- [ ] Funding.Validate: Rate 合法，Timestamp 必填，Quality 完整
- [ ] OpenInterest.Validate: Value 非负，Timestamp 必填，Quality 完整
- [ ] LongShortRatio.Validate: LongRatio 在 [0,1] 范围，Timestamp 必填，Quality 完整
- [ ] 所有衍生品指标的 decimal 字段合法，来源质量标签完整

## 实现要点

- 为 Funding/OpenInterest/LongShortRatio 各实现 `Validate() error`
- 时间必填校验：Timestamp zero value 拒绝
- MarketDataQuality 字段必须非零值
- LongShortRatio.LongRatio 应在 [0, 1] 范围内
- OpenInterest.Value 非负

## 测试要求

- TC-MKT-005: derivative data cases
  - Funding Rate 合法/非法场景
  - OpenInterest Value 零值/负值场景
  - LongShortRatio 超出 [0,1] 场景
  - Timestamp 为零值返回错误
  - Quality 字段缺失返回错误
