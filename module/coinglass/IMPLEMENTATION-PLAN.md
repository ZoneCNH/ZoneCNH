# module/coinglass IMPLEMENTATION PLAN

## 1. Goal

Deliver `module/coinglass` v1.0.0 as Coinglass aggregated derivatives data C/S module。硬切替换旧 passive `coinglass` SDK，统一进入 ZoneCNH 数据域 · 行情管线，并引入 polling 重叠窗口的 idempotency 机制 + venue 名称规范化。

## 2. Required Preflight Decisions

1. 旧 passive SDK 在 active code 中清除
2. `module/coinglass/client` 与 `server` 文档就绪
3. canonical domain 由 `module/domain-market` 拥有；derivatives_aggregate 事件类型通过 `source_metadata.aggregator` 标注（domain-market v1.1 评估是否引入 first-class type）
4. wire contract 由 `module/contracts` §8.4 拥有
5. downstream dispatch 经 `module/market-data` 中转
6. delivery 语义：at-least-once + idempotent acceptance + ACK-driven checkpoint + window-overlap-tolerant idempotency
7. venue 名称在 client 层规范化为 canonical exchange 值
8. quota-aware scheduler 按 channel 优先级分配 API quota

### Phase 0: Upstream Contract Closure Gate

| Gate | 验证项 | 状态 |
|------|--------|:---:|
| G0-1 | contracts §8.4 全部 wire types | ✅ |
| G0-2 | domain-market 通过 `source_metadata.aggregator` 表达聚合源 | ✅（过渡期方案） |
| G0-3 | market-data DownstreamDispatchPort 接受含 aggregator 标注的事件 | ✅（源不敏感） |
| G0-4 | binance C/S Module 模板已稳定 | ✅ |
| G0-5 | coinglass 旧 SDK 清单整理 | 🔧 PR-000 |
| G0-6 | BOUNDARY-GATES（继承 binance）可执行 | ✅ |

## 3. Recommended PR Sequence

```text
PR-000  legacy coinglass SDK cleanup
PR-001  module/coinglass root
PR-002  module/coinglass/client SPEC + tasks
PR-003  module/coinglass/server SPEC + tasks
PR-004  domain-market aggregator 字段验证（无新增 first-class type）
PR-005  contracts dependency 验证
PR-006  transportx dependency 验证
PR-007  runtime implementation（github.com/ZoneCNH/coinglass 改造）
```

本仓库 PR-001/002/003 合并执行（阶段 A 单 PR）。

## 4. PR-000 Legacy SDK Cleanup

Scope: 标注旧 SDK Deprecated；移除 active doc 引用；CHANGELOG 保留迁移记录。

## 5. PR-001 Root Module（本 PR）

Scope: `goal.md / README.md / SPEC.md / IMPLEMENTATION-PLAN.md / TRACEABILITY.md / BOUNDARY-GATES.md / RUNTIME-MAPPING.md`

Acceptance:
- root SPEC 定义聚合数据特异性（4 channel + venue normalization + window overlap）
- product_line 语义为 `derivatives_aggregate`
- 无 storage/query/strategy 所有权

## 6. PR-002 Client Docs（本 PR）

Scope: `client/SPEC.md` + 后续 task spec

Acceptance:
- 4 channel parser 定义清晰
- venue map 覆盖至少 13 项已知 venue
- quota-aware scheduler 设计完整
- idempotency key 包含 window_start

## 7. PR-003 Server Docs（本 PR）

Scope: `server/SPEC.md` + 后续 task spec

Acceptance:
- coinglass source metadata 校验
- venue 不在 canonical 列表 → unsupported_channel reject + 告警
- idempotency TTL 7 天覆盖典型回溯窗口

## 8. PR-004 ~ PR-007（后续）

| PR | 范围 |
|----|------|
| PR-004 | domain-market aggregator 字段使用约定验证 |
| PR-005 | contracts dependency stub |
| PR-006 | transportx dependency stub |
| PR-007 | github.com/ZoneCNH/coinglass runtime 改造（含 4 channel + scheduler + venue map） |

Runtime 序列：generated contracts → domain mapping → server mock → client venue map → scheduler → 4 channel parser → mapper → spool/checkpoint → gRPC sender → server ingest → coinglass validation → idempotency → downstream dispatch → admin（quota status + poll schedule） → integration tests（含 quota 紧张场景）→ boundary gates + API key leakage gate.

## 9. Done Definition

`module/coinglass` v1.0.0 完成标准：

- [ ] 文档自洽
- [ ] task 有 AC
- [ ] 边界 CI 强制
- [ ] 4 channel polling 在 quota 内稳定运行
- [ ] window-overlap idempotency 测试通过
- [ ] venue map 完整且 unmapped venue 触发告警
- [ ] COINGLASS_API_KEY 零泄露
- [ ] integration test 演示 4 channel → server → downstream port 数据流
