# contracts 文档同步目标

## 目标
把 `module/contracts` 的文档基线收敛到 `/home/contracts/pkg/contracts` 当前导出面，确保规格、追溯、任务和说明都只描述运行时真实存在的类型、端口和 wire contract。

## 终态

- `README.md`、`SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`CHANGELOG.md` 同步为同一真相面
- 只保留当前存在的 export、method、field、reject code 和 alias
- 删除 `stable period`、Topic constants、`v1.0.1`、旧 DTO 名称、旧 provider 方法名、双向流 ingestion 等历史叙事
- 任务编号固定为 `TASK-CONTRACTS-000` 到 `TASK-CONTRACTS-005`
- 文档层面不引入新的运行时依赖或实现代码

## 当前事实

- 基础信封：`Event`、`Command`、`Query`
- 标记接口：`DTO`、`Port`
- 错误注册：`ErrorCode`
- P0 DTO：`RegimeSnapshot`、`RegimeCard`、`DecisionCard`
- P1 DTO：`SignalIntent`
- 端口：`MarketDataProvider`、`MacroDataProvider`、`DecisionCardProvider`、`SignalFactoryProvider`
- 采集契约：`MarketDataService.Ingest(IngestRequest) (IngestResult, error)`
- 兼容投影：`RegimeSnapshotEvent`、`RegimeCardEvent`、`DecisionCardEvent`、`MarketRegimePort`、`MacroRegimePort`、`RegimeEnginePort`

## 成功标准

- 每份文档都能在 `pkg/contracts` 中找到对应导出
- 不再出现已删除或旧命名 API
- 追溯、特性和任务编号互相一致
