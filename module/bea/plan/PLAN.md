# bea 实施计划

## 目标

将 `/home/workspace/bea` 推进为生产级独立 C/S 宏观模块，满足：

- 子模块独立服务化（NIPA/GDPbyIndustry/Regional/ITA/IIP/IntlServTrade/FixedAssets/InputOutput/MNE/UnderlyingGDPbyIndustry）
- 共享基座复用
- `domain_macro` 统一出域语义
- 七介质链路闭合（`taos + kafka + postgres + Redis + oss + nats + clickhouse`）
- 自动分析闭环（采集→清洗→计算→可视化→报告）

## 8 周阶段计划

| 阶段 | 周期 | 关键交付 | 验证重点 |
| ---- | ---- | -------- | -------- |
| Phase 1 | 第 1-2 周 | API Key/采集框架、NIPA 全量历史拉取、限流框架 | 首次全量成功、限流与错误熔断生效 |
| Phase 2 | 第 3-4 周 | 接入 GDPbyIndustry、Regional；基础指标体系 | 指标计算正确、区域与行业模块可用 |
| Phase 3 | 第 5-6 周 | 接入 ITA、IIP、IntlServTrade；外部均衡模块 | 国际收支与头寸分析链路可用 |
| Phase 4 | 第 7-8 周 | 增量同步、质检、仪表盘、报告、告警 | 发布日历触发、质检闭环、自动报告 |

## 任务拆分

| Task | 范围 | 依赖 |
| ---- | ---- | ---- |
| TASK-BEA-001 | 双服务骨架、配置映射、边界门禁 | Phase 1 |
| TASK-BEA-CLIENT-001 | 数据集目录枚举、参数驱动采集、限流与退避 | TASK-BEA-001 |
| TASK-BEA-CLIENT-002 | Raw-First、`domain_macro` 映射、no-lookahead 输入约束 | TASK-BEA-CLIENT-001 |
| TASK-BEA-SERVER-001 | 消费与多存储编排、Kafka 事件、缓存与锁 | TASK-BEA-CLIENT-001 |
| TASK-BEA-SERVER-002 | 查询/API、增量/全量/Re-sync 作业编排 | TASK-BEA-SERVER-001 |
| TASK-BEA-ANALYSIS-001 | 指标计算、模块化分析、跨源一致性校验 | TASK-BEA-SERVER-002 |
| TASK-BEA-REPORT-001 | 仪表盘、PDF 报告、异常告警 | TASK-BEA-ANALYSIS-001 |

## 持续运营

| 项 | 周期 | 说明 |
| -- | ---- | ---- |
| 发布日历同步 | 按日 | GDP 季度三次估算、PCE 月末发布、地区年度发布 |
| 修订追踪 | 按周 | 关键指标 revision diff 监控 |
| 全量对账 | 每月 | 关键数据集一致性回扫 |
| 口径审计 | 每季度 | 元数据与统计口径变更审计 |

## 完成判定

仅当 `matrix/TRACEABILITY.md` 中 BR/AC/TC 完成状态与 runtime 证据一致，且边界门禁、质量校验、自动报告链路全部通过，才可声明模块达到生产目标。
