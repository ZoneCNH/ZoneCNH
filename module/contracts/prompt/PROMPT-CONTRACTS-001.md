# TASK-CONTRACTS-001 开发 Prompt

- 上游 Task：[tasks/](../tasks/)
- 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
- 权威 Spec：[SPEC.md](../SPEC.md)

## 任务

维护 contracts 跨域接口契约：Event/Command/Query 基础封装、DTO/Port 标记、Ingest 契约、RegimeCard/DecisionCard 投影。

## 关联需求

FR-001~008（Event/Command/DTO/Port/Ingest/RegimeCard/MarketDataProvider/文档同步）。
BR-001~010（仅定义契约/不实现业务逻辑/依赖边界/canonical code 稳定性）。

## 实现要点

1. contracts 仅定义共享契约，不实现业务逻辑
2. DTO 字段 + JSON tag 约定
3. IngestRequest/IngestResult/IngestAck/IngestReject 接口
4. 文档与 runtime truth 一致（SPEC/TRACEABILITY/ACCEPTANCE 同步）
