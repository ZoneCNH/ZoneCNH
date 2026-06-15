# TASK-MKT-006

> provider contract：DataProvider 返回纯领域模型

---

```yaml
task_id: TASK-MKT-006
module: domain-market
version: v1.0.0
spec_ref:
  - "module/domain-market/SPEC.md#FR-MKT-010"
  - "module/domain-market/SPEC.md#FR-MKT-013"
fr_ref: FR-MKT-006
ac_ref: AC-MKT-006
tc_ref: TC-MKT-006
acceptance_criteria:
  - "AC-MKT-006: provider contract 不泄漏 transport/vendor DTO"
status: pending
priority: P0
estimated_effort: "2h"
depends_on:
  - TASK-MKT-002
```

---

## 目标

DataProvider contract 必须返回领域模型，不暴露 HTTP/WS/DB/vendor DTO。

## 验收标准

- [ ] AC-MKT-006: provider contract 不泄漏 transport/vendor DTO
- [ ] DataProvider 接口方法签名仅返回领域值对象
- [ ] HistoricalBarsRequest.Validate 实现
- [ ] domain struct 不含 json/db/yaml/kafka tag
- [ ] 静态边界扫描无 transport 泄漏

## 实现要点

- DataProvider 接口：LatestQuote、LatestBar、HistoricalBars
- HistoricalBarsRequest struct + Validate
- 返回类型严格为 Quote/Bar/[]Bar，不含 vendor DTO
- 确保所有 domain struct 无 transport/persistence tag
- Fake provider 实现（供测试复用）

## 测试要求

- TC-MKT-006: static boundary scan
  - lint: domain struct 禁止 json/db/yaml/kafka tag
  - DataProvider 接口签名不含 vendor 类型
  - HistoricalBarsRequest.Start > End 返回错误
  - Fake provider 构造与调用测试
