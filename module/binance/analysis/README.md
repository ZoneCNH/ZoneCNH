# module/binance/analysis — 深度分析归档

> 本目录存放 binance 模块的深度分析文档、架构评估报告与归档索引。
> 参见 R5【硬】归档物理隔离规则。

## 文件清单

| 文件 | 用途 |
|---|---|
| `DEEP-ANALYSIS.md` | 深度分析归档索引（迁移映射 + 活跃文档入口） |
| `DEEP-ANALYSIS-INDEX.md` | 快速跳转索引（主题→文件映射） |
| `DEEP-ANALYSIS-ARCHIVE-architecture.md` | §0-§2 + 附录A：分布式约束、架构评估、目标设计 |
| `DEEP-ANALYSIS-ARCHIVE-integration.md` | §3：六模块集成详案（natsx/redisx/postgresx/taosx/kafkax/ossx） |
| `DEEP-ANALYSIS-ARCHIVE-operations.md` | §4-§11 + 附录B：API/数据流/配置/部署/路线图/风险 |
| `A10-FR024-HOT-RELOAD-EVAL.md` | FR-024 全量 Config Hot Reload 评估报告 |

## 归档原因

DEEP-ANALYSIS 系列为 v2.0.0 重构前（2026-06-21）的深度分析，已被 SPEC v3.5.0+ 覆盖。原始内容于 2026-06-22 拆分为 3 个专题归档文件，保留以供架构决策追溯。

A10-FR024-HOT-RELOAD-EVAL.md 为 Plan007 A10 的 FR-024 评估结论——全量 hot reload 不推荐，维持 Partial（symbol catalog reload 已够）。

## 活跃文档入口

日常开发请查阅模块根目录下的活跃文档：
- `../SPEC.md` — 根规格
- `../TRACEABILITY.md` — 追溯矩阵
- `../RUNTIME-MAPPING.md` — 运行时映射
- `../server/PERSISTENCE-WIRING.md` — 存储装配契约
