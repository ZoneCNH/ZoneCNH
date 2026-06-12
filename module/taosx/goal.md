# taosx 发布版本 1.0 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `taosx`                                        |
| 发布版本     | 1.0.0                                          |
| 所属层级     | 存储扩展层 / TDengine TAOS 时序数据            |
| 稳定级别     | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态     | 1.0 发布基线文档                               |
| 发布日期基准 | 2026-06-09                                     |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`taosx` 的 Goal 是提供 TDengine/TAOS 的统一时序数据访问能力，覆盖超级表/子表/标签模型、批量写入、时间窗口查询、聚合、降采样、设备维度查询、写入缓冲、生命周期策略、错误映射和可观测。它面向 IoT、设备采集、监控指标等高频时序场景。

### 1.1 为什么需要这个模块

- 时序数据与普通 CRUD 模型不同，需要围绕时间、指标、标签和设备建模。
- 高频写入必须批量化、缓冲和可观测，否则容易造成写入抖动和数据丢失。
- 超级表、子表、标签等 TAOS 概念需要标准封装，避免业务重复建模。
- 时间窗口聚合和降采样需要统一查询模板。

### 1.2 1.0 要解决的问题

- 统一时序模型：metric、timestamp、value、tags、deviceId。
- 统一超级表和子表管理。
- 统一批量写入、缓冲、flush、失败重试。
- 统一时间窗口、聚合、降采样查询。
- 统一写入延迟、失败、吞吐和查询观测。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 TimeSeriesWriter、TimeSeriesQuery、TableModelManager。
- MUST 支持批量写入和 flush 策略。
- MUST 支持超级表、子表、标签的声明式模型。
- MUST 支持按时间范围、设备、标签、窗口聚合查询。
- MUST 明确不承载强事务和普通关系型 CRUD。

## 3. 核心场景

| 场景         | 说明                         | 1.0 期望结果                   |
| ------------ | ---------------------------- | ------------------------------ |
| 设备数据写入 | 设备每秒上报温度、压力、电量 | 批量写入到对应子表，失败可重试 |
| 监控指标查询 | 查询过去 1 小时平均温度      | 时间窗口聚合返回统一结果       |
| 降采样       | 原始秒级数据生成分钟级聚合   | 按规则执行聚合写入或查询降采样 |
| 设备定位     | 按标签查询某区域设备指标     | 标签查询统一生成安全 SQL       |

## 4. 能力范围

| 能力域   | 1.0 必须具备的能力                             | 验收方式               |
| -------- | ---------------------------------------------- | ---------------------- |
| 时序模型 | MetricPoint、DeviceTag、TimeRange、Aggregation | 模型测试通过           |
| 表模型   | 超级表、子表、标签、列类型、版本               | DDL 生成和校验测试通过 |
| 批量写入 | buffer、batch、flush、重试、失败记录           | 高频写入测试通过       |
| 查询     | 时间范围、标签过滤、窗口聚合、limit            | 查询集成测试通过       |
| 降采样   | avg/max/min/sum/count、窗口粒度                | 聚合测试通过           |
| 生命周期 | 保留策略、冷热策略接口                         | 策略校验测试通过       |
| 观测     | 写入吞吐、flush 延迟、查询耗时、失败           | 观测测试通过           |

## 5. 职责边界

### 5.1 模块内职责

- 提供 TAOS 时序数据标准访问层。
- 提供表模型、批量写入和查询聚合能力。
- 提供错误映射和可观测接入。
- 提供测试样例和基准场景。

### 5.2 明确非目标

- 不替代 PostgreSQL 的事务型存储。
- 不承载复杂多表事务。
- 不把时序查询伪装成通用 ORM。
- 不负责设备业务模型本身。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                 |
| -------- | ---------------------------------------------------- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx。         |
| 下游依赖 | IoT、监控、设备数据服务可使用 taosx。                |
| 分层约束 | taosx 只暴露时序语义，不依赖设备业务域对象。         |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约              | 定位         | 1.0 稳定承诺                    |
| ----------------- | ------------ | ------------------------------- |
| TimeSeriesWriter  | 时序写入入口 | write/writeBatch/flush 语义稳定 |
| TimeSeriesQuery   | 时序查询入口 | 时间范围和聚合语义稳定          |
| TableModelManager | 表模型管理   | 超级表/子表声明语义稳定         |
| MetricPoint       | 数据点模型   | 核心字段稳定                    |
| TagFilter         | 标签过滤模型 | 过滤语义稳定                    |

### 7.2 1.0 逻辑接口基线

```text
MetricPoint
  metric
  timestamp
  value
  deviceId
  tags
  fields

TimeSeriesWriter
  write(point): WriteResult
  writeBatch(points): BatchWriteResult
  flush(): FlushResult

TimeSeriesQuery
  range(metric, timeRange, filters): List<MetricPoint>
  aggregate(metric, timeRange, window, aggregation, filters): List<AggregatePoint>

TableModel
  superTable
  columns
  tags
  childTableStrategy

TagFilter
  eq(tag, value): TagFilter
  neq(tag, value): TagFilter
  in(tag, values): TagFilter
  and(filters): TagFilter
  or(filters): TagFilter
```

## 8. 配置契约

| 配置项                             | 含义             | 默认值 / 要求         | 稳定性 |
| ---------------------------------- | ---------------- | --------------------- | ------ |
| foundationx.taos.enabled           | 是否启用 taosx   | false，由业务显式启用 | Stable |
| foundationx.taos.url               | TAOS 连接地址    | 必须配置              | Stable |
| foundationx.taos.database          | 数据库名         | 必须配置              | Stable |
| foundationx.taos.batch.size        | 批量写入大小     | 1000                  | Stable |
| foundationx.taos.flush.interval    | 自动 flush 间隔  | 1s                    | Stable |
| foundationx.taos.write.timeout     | 写入超时         | 3s                    | Stable |
| foundationx.taos.query.timeout     | 查询超时         | 5s                    | Stable |
| foundationx.taos.retention.default | 默认数据保留策略 | 业务显式配置          | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 写入失败日志包含 metric、batchSize、timeRange、errorCode。
- MUST 查询慢日志包含 metric、timeRange、window、durationMs。

### 9.2 指标

| 指标名                               | 类型    | 标签                    | 说明           |
| ------------------------------------ | ------- | ----------------------- | -------------- |
| foundationx_taos_write_points_total  | Counter | metric,status           | 写入数据点数量 |
| foundationx_taos_write_batches_total | Counter | metric,status           | 写入批次数     |
| foundationx_taos_write_duration_ms   | Timer   | metric,status           | 写入耗时       |
| foundationx_taos_query_total         | Counter | metric,operation,status | 查询次数       |
| foundationx_taos_query_duration_ms   | Timer   | metric,operation,status | 查询耗时       |
| foundationx_taos_buffer_size         | Gauge   | metric                  | 写入缓冲大小   |
| foundationx_taos_errors_total        | Counter | operation,errorCode     | 错误数         |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 标注 db.system=taos、metric、operation、points.count 或 time.range。
- SHOULD 对 flush 周期输出诊断事件。

## 10. 错误模型与失败策略

| 错误类别               | 典型原因                 | 1.0 处理策略                           |
| ---------------------- | ------------------------ | -------------------------------------- |
| TAOS_CONNECTION_FAILED | 连接失败、认证失败       | 启动或健康检查失败                     |
| TAOS_WRITE_FAILED      | 批量写入失败、部分失败   | 按批次结果返回并支持重试               |
| TAOS_QUERY_TIMEOUT     | 查询超时                 | 取消查询并返回超时错误                 |
| TAOS_SCHEMA_MISMATCH   | 数据点字段与表模型不匹配 | 拒绝写入并输出模型错误                 |
| TAOS_BUFFER_OVERFLOW   | 写入缓冲超过上限         | 按策略阻塞、丢弃或失败，生产需显式配置 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持 TLS 连接和认证配置。
- MUST 参数化或安全构造查询，避免标签过滤注入。
- MUST 控制查询时间范围上限，防止大范围扫描拖垮系统。

## 12. 测试证据要求

| 测试类型     | 必须覆盖内容                                   | 发布门禁  |
| ------------ | ---------------------------------------------- | --------- |
| 单元测试     | MetricPoint、TagFilter、窗口聚合参数、DDL 生成 | MUST 通过 |
| 集成测试     | 真实 TAOS 写入、批量写入、查询、聚合           | MUST 通过 |
| 高频写入测试 | buffer、flush、失败重试、背压                  | MUST 通过 |
| 故障测试     | 连接失败、部分写入失败、查询超时               | MUST 通过 |
| 观测测试     | 写入/查询指标和慢查询日志                      | MUST 通过 |

## 13. 1.0 发布验收清单

- 数据模型体现时序语义而非普通 CRUD。
- 高频写入有批量和缓冲策略。
- 查询必须有时间范围，避免无界扫描。
- 写入失败可定位到 metric 和批次。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持边缘缓存和断点补写。
- 支持更多降采样任务与 schedulex 集成。
- 支持时序 schema 演进工具。
