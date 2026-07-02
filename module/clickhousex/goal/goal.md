# clickhousex 发布版本 1.0 Goal 定位与实现标准

| 字段         | 内容                                           |
| ------------ | ---------------------------------------------- |
| 模块名       | `clickhousex`                                  |
| 发布版本     | 1.1.0                                          |
| 所属层级     | 存储扩展层 / ClickHouse OLAP 分析存储          |
| 稳定级别     | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态     | v1.0.1 规格基线（完整 SPEC + TRACEABILITY §1-§7 + 7 Tasks，覆盖率 100%） |
| 发布日期基准 | 2026-06-14                                     |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`clickhousex` 的 Goal 是提供 ClickHouse 的统一 OLAP 数据访问能力，覆盖高吞吐批量写入、分析型查询、分区/排序键/物化视图建模规范、时间窗口聚合、TopN、冷热数据策略、慢查询观测和错误映射。它面向日志分析、行为分析、指标分析和报表场景，不承载 OLTP 事务。

### 1.1 为什么需要这个模块

- ClickHouse 常被用于大规模分析，但如果建模和写入方式不统一，容易出现小批量写入过多、查询扫描过大等问题。
- 业务需要明确区分 PostgreSQL 的事务存储和 ClickHouse 的分析存储。
- 分析 SQL 往往复杂，需要 sqlId、查询成本和慢查询观测。
- 批量导入失败需要明确部分失败、重试和数据重复策略。

### 1.2 1.0 要解决的问题

- 统一批量写入和导入策略。
- 统一 OLAP 查询执行、参数绑定和结果映射。
- 统一表建模规范：分区、排序键、主键、物化视图。
- 统一聚合、时间窗口、TopN 查询辅助。
- 统一慢查询、扫描行数、写入吞吐和错误观测。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 ClickHouseWriter、ClickHouseQuery、TableModelAdvisor 基础能力。
- MUST 以批量写入为默认模式，不鼓励单行高频写入。
- MUST 为查询提供 sqlId、超时、扫描限制和参数绑定。
- MUST 输出慢查询、扫描行数、结果行数、写入批次和失败指标。
- MUST 明确不支持强事务 OLTP 场景。

## 3. 核心场景

| 场景      | 说明                   | 1.0 期望结果                       |
| --------- | ---------------------- | ---------------------------------- |
| 日志导入  | 批量写入应用日志或事件 | 按批次写入并记录吞吐和失败         |
| 报表查询  | 按天统计用户行为       | 时间范围和聚合查询可控             |
| TopN 分析 | 查询访问量最高接口     | 提供 TopN 查询辅助和扫描限制       |
| 物化视图  | 高频报表需要预聚合     | 建模规范指导分区、排序键和视图设计 |

## 4. 能力范围

| 能力域   | 1.0 必须具备的能力                        | 验收方式         |
| -------- | ----------------------------------------- | ---------------- |
| 批量写入 | buffer、batch、flush、异步写入、失败处理  | 写入集成测试通过 |
| 查询执行 | 参数绑定、sqlId、超时、结果映射、行数限制 | 查询测试通过     |
| 建模规范 | 分区键、排序键、物化视图、TTL             | 建模检查测试通过 |
| 聚合辅助 | 时间窗口、group by、TopN、percentile      | 查询模板测试通过 |
| 冷热策略 | TTL、分区清理、归档接口                   | 策略测试通过     |
| 观测     | 慢查询、扫描行数、写入吞吐、错误          | 观测测试通过     |

## 5. 职责边界

### 5.1 模块内职责

- 提供 ClickHouse 批量写入和分析查询封装。
- 提供 OLAP 建模建议和检查能力。
- 提供错误映射、超时控制和观测接入。
- 提供典型日志/事件/指标分析样例。

### 5.2 明确非目标

- 不替代 PostgreSQL 的事务型读写。
- 不支持强一致事务和高频点查业务主路径。
- 不替代 BI 平台。
- 不负责具体业务指标定义。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束                                                       |
| -------- | ---------------------------------------------------------- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx。               |
| 下游依赖 | 日志分析、指标分析、报表、行为分析服务可使用 clickhousex。 |
| 分层约束 | clickhousex 不依赖业务报表模型；只提供通用 OLAP 能力。     |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。       |

## 7. 对外契约

### 7.1 公开能力面

| 契约                     | 定位           | 1.0 稳定承诺                    |
| ------------------------ | -------------- | ------------------------------- |
| ClickHouseWriter         | 批量写入入口   | writeBatch/flush 语义稳定       |
| ClickHouseQuery          | 查询入口       | query/queryPage/stream 语义稳定 |
| OlapQueryOptions         | 查询约束       | timeout/maxRows/sqlId 语义稳定  |
| TableModelSpec           | 表建模声明     | 分区/排序/TTL 字段稳定          |
| ClickHouseSerializer SPI | 写入编码扩展点 | 编码语义稳定                    |

### 7.2 1.0 逻辑接口基线

```text
ClickHouseWriter
  writeBatch(table, rows, options): BatchWriteResult
  flush(): FlushResult

ClickHouseQuery
  query(sqlId, sql, params, options): List<T>
  stream(sqlId, sql, params, handler, options): QueryResult

OlapQueryOptions
  timeout
  maxRows
  maxBytesScanned
  requireTimeRange

TableModelSpec
  table
  engine
  partitionBy
  orderBy
  ttl
  materializedViews

ClickHouseSerializer SPI
  encode(row): byte[]
  decode(bytes): Row
```

## 8. 配置契约

| 配置项                                      | 含义                 | 默认值 / 要求         | 稳定性 |
| ------------------------------------------- | -------------------- | --------------------- | ------ |
| foundationx.clickhouse.enabled              | 是否启用 clickhousex | false，由业务显式启用 | Stable |
| foundationx.clickhouse.url                  | 连接地址             | 必须配置              | Stable |
| foundationx.clickhouse.database             | 数据库名             | 必须配置              | Stable |
| foundationx.clickhouse.batch.size           | 批量写入大小         | 5000                  | Stable |
| foundationx.clickhouse.flush.interval       | flush 间隔           | 1s                    | Stable |
| foundationx.clickhouse.query.timeout        | 查询超时             | 10s                   | Stable |
| foundationx.clickhouse.query.max-rows       | 最大返回行数         | 10000                 | Stable |
| foundationx.clickhouse.slow-query-threshold | 慢查询阈值           | 1s                    | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 慢查询日志包含 sqlId、durationMs、rowsRead、bytesRead、rowsReturned。
- MUST 写入失败日志包含 table、batchSize、errorCode。

### 9.2 指标

| 指标名                                     | 类型    | 标签                | 说明       |
| ------------------------------------------ | ------- | ------------------- | ---------- |
| foundationx_clickhouse_write_rows_total    | Counter | table,status        | 写入行数   |
| foundationx_clickhouse_write_batches_total | Counter | table,status        | 写入批次数 |
| foundationx_clickhouse_write_duration_ms   | Timer   | table,status        | 写入耗时   |
| foundationx_clickhouse_query_total         | Counter | sqlId,status        | 查询次数   |
| foundationx_clickhouse_query_duration_ms   | Timer   | sqlId,status        | 查询耗时   |
| foundationx_clickhouse_query_rows_read     | Counter | sqlId               | 扫描行数   |
| foundationx_clickhouse_errors_total        | Counter | operation,errorCode | 错误数     |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 标注 db.system=clickhouse、sqlId、table、rowsRead、bytesRead。
- SHOULD 对批量 flush 输出诊断事件。

## 10. 错误模型与失败策略

| 错误类别                     | 典型原因               | 1.0 处理策略                  |
| ---------------------------- | ---------------------- | ----------------------------- |
| CLICKHOUSE_CONNECTION_FAILED | 连接失败、认证失败     | 启动/健康检查失败或按策略处理 |
| CLICKHOUSE_WRITE_FAILED      | 批量写入失败           | 返回批次失败并支持重试        |
| CLICKHOUSE_QUERY_TIMEOUT     | 查询超时               | 取消查询并返回超时错误        |
| CLICKHOUSE_QUERY_TOO_LARGE   | 无时间范围或扫描过大   | 拒绝执行或要求显式 override   |
| CLICKHOUSE_SCHEMA_MISMATCH   | 写入字段与表结构不匹配 | 拒绝写入并输出表模型错误      |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持 TLS 连接和认证配置。
- MUST 对查询参数化，避免用户输入拼接 SQL。
- MUST 默认限制查询时间范围、最大行数和超时。
- SHOULD 使用只读账号执行分析查询。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容                                | 发布门禁      |
| -------- | ------------------------------------------- | ------------- |
| 单元测试 | 查询 options、建模 spec、错误映射、批量切分 | MUST 通过     |
| 集成测试 | 真实 ClickHouse 写入、查询、聚合            | MUST 通过     |
| 性能基准 | 批量写入吞吐和查询超时回归                  | MUST 建立基线 |
| 故障测试 | 连接失败、写入失败、查询过大、超时          | MUST 通过     |
| 观测测试 | 慢查询日志、扫描行数、写入指标              | MUST 通过     |

## 13. 1.0 发布验收清单

- 默认写入模式为批量。
- 查询必须可设置 sqlId、超时、最大结果和扫描约束。
- 模块文档明确 OLAP/OLTP 边界。
- 慢查询和大扫描可观测。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持异步导入队列和背压。
- 提供更多分析模板。
- 支持与 kafkax 的日志/事件导入管道样例。
