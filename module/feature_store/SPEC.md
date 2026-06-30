# feature_store 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-30
- Layer: 分析域 · 特征存储
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `module/factor_engine`, `module/domain_market`, `module/factor_eval`

> 本文件发布 feature_store 文档基线。运行时实现为 Pending。

---

## 1. 摘要

`feature_store` 是分析域的特征存储与版本管理模块。接收 `factor_engine` 输出的 `FactorOutput`，提供特征版本化存储、回测时点查询（point-in-time correct）和特征血缘追踪。它是因子计算与因子评估之间的持久化桥梁。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | Feature 存储接口、特征版本管理、回测时点查询、特征血缘追踪（lineage）、TTL 过期策略 |
| Depends on | `module/factor_engine`（FactorOutput 输入）、`module/domain_market`（canonical 类型）、`module/decimalx` |
| Consumed by | `module/factor_eval`（特征评估）、`module/signal_factory`（信号生成）、`module/backtestx`（回测特征查询） |
| Excludes | 因子计算（→ factor_engine）、因子评估（→ factor_eval）、数据库实现（→ postgresx/taosx/clickhousex）、策略逻辑 |

## 3. 术语

| 术语 | 定义 |
| --- | --- |
| Feature | 一个带时间戳和版本的因子值，由 factor_engine 产生 |
| Point-in-Time (PIT) | 回测时只使用该时点之前已知的特征值，杜绝未来信息泄漏 |
| FeatureVersion | 同一 feature_name 在同一 instrument_key 上的不可变版本序列 |
| Lineage | 特征血缘：记录特征的计算来源、输入数据范围、因子版本和计算时间 |
| TTL | Time-to-Live：特征值的自动过期时间，超期特征不参与查询 |

## 4. 功能需求

### FR-001: Feature 写入

WHEN factor_engine 输出 FactorOutput
THEN feature_store 必须接收并持久化
AND 写入包含：factor_name、value、timestamp、instrument_key、product_line、event_type、compute_metadata
AND 同 factor_name + instrument_key + timestamp 的重复写入必须幂等（返回已有 version）

### FR-002: 版本管理

WHEN 同一 factor_name + instrument_key 收到新值
THEN 生成新的单调递增 version 号
AND 旧版本保留（不覆盖），按 TTL 过期
AND 版本号在 factor_name + instrument_key 范围内单调递增

### FR-003: Point-in-Time 查询

WHEN 回测请求 `GetFeaturesAt(instrument_key, timestamp)`
THEN 返回该时点之前所有已生效的 feature 最新版本
AND 不返回 timestamp 之后的特征值（杜绝 lookahead）
AND 不返回已过 TTL 的特征值

### FR-004: 特征血缘

WHEN 特征写入
THEN 记录血缘元数据：source_factor、input_data_range、factor_version、compute_time
AND `GetLineage(factor_name, instrument_key)` 返回完整血缘链

### FR-005: TTL 过期

WHEN 特征超过配置的 TTL
THEN 标记为 expired，不参与 PIT 查询
AND 物理删除由后台 GC 任务异步执行
AND GC 不得阻塞读写

### FR-006: 批量查询

WHEN 回测请求 `GetFeatureMatrix(instrument_keys[], timestamp)`
THEN 返回多个 instrument 在同一时点的特征矩阵
AND 缺失值标记为 NaN（不填充零）

### FR-007: Module Identity

WHEN 下游模块引用 feature_store
THEN Go module path 必须为 `github.com/ZoneCNH/feature_store`
AND README H1 必须为 `# feature_store`

## 5. 行为约束

| ID | 规则 | 违反后果 |
| --- | --- | --- |
| BR-001 | PIT 查询不得返回未来数据 | 回测结果无效，回测验证失败 |
| BR-002 | 同一 factor_name+instrument_key+timestamp 幂等写入 | 重复写入返回已有 version |
| BR-003 | 特征写入不可变（不 update，只 append new version） | 版本链完整性保证 |
| BR-004 | TTL 过期特征不参与查询 | PIT 查询自动过滤 |

## 6. 非功能需求

| ID | 需求 | 目标 |
| --- | --- | --- |
| NFR-001 | 单条写入延迟 | < 1ms |
| NFR-002 | PIT 查询延迟（1000 特征） | < 10ms |
| NFR-003 | 特征矩阵查询（100 instrument × 50 feature） | < 100ms |
| NFR-004 | 测试覆盖率 | >= 80% |

## 7. 接口契约

```go
// FeatureStore 特征存储接口
type FeatureStore interface {
    Write(ctx context.Context, output FactorOutput) (version int64, err error)
    GetFeaturesAt(ctx context.Context, key InstrumentKey, ts time.Time) ([]Feature, error)
    GetFeatureMatrix(ctx context.Context, keys []InstrumentKey, ts time.Time) ([][]float64, error)
    GetLineage(ctx context.Context, factorName string, key InstrumentKey) ([]LineageEntry, error)
}

type Feature struct {
    FactorName    string
    Value         float64
    Version       int64
    Timestamp     time.Time
    InstrumentKey InstrumentKey
    TTL           time.Time
}

type LineageEntry struct {
    FactorName    string
    Version       int64
    InputRange    TimeRange
    FactorVersion string
    ComputeTime   time.Time
}
```

## 8. 数据模型

| 模型 | 字段 |
| --- | --- |
| Feature | factor_name, value, version, timestamp, instrument_key, ttl |
| FeatureVersion | feature_name, instrument_key, version, value, timestamp, lineage |
| LineageEntry | factor_name, version, input_range, factor_version, compute_time |
| FeatureMatrix | instrument_keys[], factor_names[], values[][]float64, timestamp |

## 9. 配置模式

```yaml
feature_store:
  default_ttl: 720h  # 30 days
  gc_interval: 1h
  gc_batch_size: 10000
  pit_default_lookback: 8760h  # 1 year
  storage:
    backend: postgresx  # postgresx | taosx | clickhousex
```

## 10. 错误处理

| 错误 | 处理方式 |
| --- | --- |
| ErrDuplicateWrite | 返回已有 version，不报错 |
| ErrStorageUnavailable | 重试 3 次 → 告警 |
| ErrTTLExpired | 查询自动跳过，不报错 |
| ErrNoData | 返回空列表，不报错 |

## 11. 边界情况

| 场景 | 预期行为 |
| --- | --- |
| PIT 查询时间早于第一条特征 | 返回空 |
| 同一 timestamp 多次写入 | 幂等，返回同一 version |
| GC 进行中查询 | 不阻塞，过期数据可能短暂可见 |
| 特征矩阵中部分 instrument 无数据 | NaN 填充 |

## 12-23. 略（结构同 factor_engine SPEC §12-§23）

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始文档基线：FeatureStore 接口、PIT 查询、版本管理、特征血缘 | ZoneCNH |
