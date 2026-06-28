# TASK-BCFG-001 Config Loading & Env Parsing

## Objective

实现 `LoadConfig()` 和 `parseDurationEnv()`/`parseIntEnv()` 辅助函数，覆盖全部 13 个 `FOUNDATIONX_BINANCE_*` 环境变量的类型化读取与安全解析。

## Scope

- `LoadConfig()`: 读取 13 个 env var，未设置回退 `DefaultConfig()`
- `parseDurationEnv()`: 安全解析 duration 字符串，非法值记录 warn log
- `parseIntEnv()`: 安全解析 int 字符串，非法值记录 warn log
- 非法值绝不 panic 或 os.Exit

## Covers

- FR-BCFG-001 (LoadConfig)
- FR-BCFG-006 (parseDurationEnv/parseIntEnv)
- BR-BCFG-001 (env-only config source)
- BR-BCFG-002 (graceful fallback on invalid)
- BR-BCFG-004 (separation from cmd/)

## Deliverables

- `config.go` 中 `LoadConfig()` 完整 13 字段映射
- `config_test.go` 中 env var 覆盖测试（含非法值不回退）
- 每个 env var 有对应的单元测试用例

## Acceptance Criteria

1. 全部 13 个 env var 正确读取并映射到 Config 字段
2. 未设置 env var 时使用 DefaultConfig 对应值
3. 非法 duration 字符串 → warn log + 使用默认值
4. 非法 int 字符串 → warn log + 使用默认值
5. 不读取文件、配置中心或密钥管理服务

## Dependencies

- stdlib (os, strconv, time, log/slog, fmt)
