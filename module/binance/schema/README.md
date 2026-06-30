# module/binance schema

模块级数据/API/契约 schema。跨模块 schema SSOT 见 `docs/goal/schema/`。

## 当前状态

模块级 schema 定义分布在以下位置：

- **配置 schema**：`design/CONFIG-SCHEMA.md`（Binance 配置参数表，含 Client/Server/Security 分节）
- **命名 schema**：`spec/NAMING.md`（4 产品线 × 6 事件类型对称矩阵、InstrumentKey identity 维度、subject/topic/path 规则）
- **数据模型 schema**：`spec/client/SPEC.md` §10（CatalogEntry / NormalizedEvent / PublishRecord / PublishState）、`spec/server/SPEC.md` §10（MarketFactEnvelope / ProcessingResult / RejectReason）
- **runtime 迁移 schema**：`/home/binance/migrations/`（TDengine DDL、PostgreSQL DDL、ClickHouse DDL）

本目录作为模块级 schema 的入口索引，具体 schema 定义见上述权威文件。

## 与 `docs/goal/schema/` 的关系

`docs/goal/schema/` 定义 Goal 体系通用 schema（goal.schema.yaml、evidence.schema.yaml、matrix.schema.yaml 等）。本目录为 binance 模块专用 schema 入口索引。
