> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](06-observability.md) · [↑ 目录](README.md) · [下一节 →](08-error-handling.md)

---

## 第七条：命名规范

### 7.1 Go 命名

| 元素      | 规范                                          | 示例                                       |
| --------- | --------------------------------------------- | ------------------------------------------ |
| 包名      | 小写单词，无下划线                            | `redisx`, `configx`                        |
| 接口      | 方法名动词或名词                              | `Client`, `Locker`, `Provider`             |
| 结构体    | PascalCase                                    | `MarketSnapshot`, `StreamConfig`           |
| 函数/方法 | PascalCase (exported), camelCase (unexported) | `NewClient`, `parseConfig`                 |
| 常量      | PascalCase 或 UPPER_SNAKE                     | `TopicMarketData`                          |
| 错误      | `errors.New("module: description")`           | `errors.New("redisx: connection refused")` |

### 7.2 模块命名

| 模式            | 说明          | 示例                               |
| --------------- | ------------- | ---------------------------------- |
| `<name>x`       | 基座扩展模块  | `redisx`, `kafkax`, `configx`      |
| `domain-<name>` | L2.5 领域模型 | `domain_market`, `domain_exchange` |
| `<name>-engine` | 分析引擎（决策/执行域已淘汰此格式） | `factor_engine`（决策/执行域旧名 `risk_engine`/`order_engine`/`portfolio_engine`/`backtest_engine` 已于 2026-06-22 重命名为 `riskx`/`orderx`/`positionx`/`backtestx`） |
| `<exchange>`    | 数据域采集器  | `binance`, `okx`                   |

### 7.3 文件命名

| 类型     | 规范               | 示例                           |
| -------- | ------------------ | ------------------------------ |
| Go 源码  | snake_case         | `client.go`, `health_check.go` |
| 测试文件 | `<source>_test.go` | `client_test.go`               |
| 规格文档 | `SPEC.md`          | `module/redisx/spec/SPEC.md`        |
| 变更日志 | `CHANGELOG.md`     | 每个模块根目录                 |

### 7.4 数据域跨层命名

| 层面 | 规范 | macro_data 示例 |
| --- | --- | --- |
| 模块 / 仓库 / 路径 / 公开文档链接 | snake_case | `macro_data` |
| JSON / YAML / 配置 / Goal registry / 接收侧字段 | snake_case | `macro_data`, `series_code`, `available_at` |
| Go 导出类型 / 接口 / 常量名 | PascalCase | `MacroDataProvider`, `TopicMacroData` |
| Topic literal / 事件通道值 | dot.case | `macro.data` |

规则：

- 模块、仓库、目录和公开文档链接统一使用 **snake_case**（与 CLAUDE.md §仓库命名规则（全局强制）一致；禁止 kebab-case、PascalCase、camelCase）。
- `macro_data` 是宏观数据域在 JSON/YAML/config/registry/receiver 字段中的 canonical token；字段名使用 `series_code`、`observed_at`、`released_at`、`available_at`、`revision_version`、`is_preliminary`、`idempotency_key`、`ordering_key`。
- Go 类型和导出标识保留 PascalCase；不得为了对齐 snake_case 而重命名 `MacroDataProvider`、`TopicMacroData` 等 Go symbol。
- Topic 字符串保留 dot.case；`macro.data` 不得替换为 `macro_data`。
- 禁止在文档、配置和注册表中新增 `macroData`、`macrodata`、`Macrodata`、`macro-data` 等漂移写法。

---
