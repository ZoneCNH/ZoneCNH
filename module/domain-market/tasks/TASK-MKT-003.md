# TASK-MKT-003

> quality gate fail-closed：市场数据质量门禁

---

```yaml
task_id: TASK-MKT-003
module: domain-market
version: v1.0.0
spec_ref:
  - "module/domain-market/SPEC.md#FR-MKT-008"
  - "module/domain-market/SPEC.md#FR-MKT-009"
  - "module/domain-market/SPEC.md#FR-MKT-011"
  - "module/domain-market/SPEC.md#FR-MKT-012"
fr_ref: FR-MKT-003
ac_ref: AC-MKT-003
tc_ref: TC-MKT-003
acceptance_criteria:
  - "AC-MKT-003: quality gate fail-closed"
status: pending
priority: P0
estimated_effort: "2h"
depends_on:
  - TASK-MKT-002
```

---

## 目标

MarketDataQuality 必须 fail-closed，拒绝 dirty、stale、time-invalid 数据进入策略层。

## 验收标准

- [ ] AC-MKT-003: quality gate fail-closed
- [ ] MarketEventEnvelope.Validate: EventTime/ReceivedAt/Symbol/Venue 必填
- [ ] stale data 超过 threshold 被 fail-closed 拒绝
- [ ] future data (EventTime 晚于 ReceivedAt 超容忍窗口) 被拒绝
- [ ] MarketDataQuality.DegradeReason 暴露降级原因
- [ ] 策略层只能消费 MarketEventEnvelope，不直接消费 Bar/Tick

## 实现要点

- 实现 `MarketEventEnvelope.Validate() error`
- stale threshold 和 future tolerance 从 SPEC §11 Config Schema 读取
- fail-closed 默认策略：非法数据、时序错误、质量不达标均返回错误
- DegradeReason + metrics 暴露，不可靠数据不静默进入策略
- 考虑 ValidateStrict/ValidateLegacy 分层（SPEC §19）

## 测试要求

- TC-MKT-003: dirty/stale/time-invalid cases
  - stale data 被拒绝（stale_threshold_sec=30 场景）
  - future data 超容忍窗口被拒绝（future_tolerance_sec=5 场景）
  - MarketEventEnvelope 缺少必填字段返回错误
  - DegradeReason 正确设置
