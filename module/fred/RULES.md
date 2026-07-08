# FRED 模块规则规范

<!-- Spec-Version: v1.1.0 -->
<!-- Last-Updated: 2026-07-08 -->
<!-- Authority: CONSTITUTION.md §1-§14 + module/fred/spec/SPEC.md -->

---

## §1 模块边界规则

### §1.1 服务隔离

- `fred-client`（采集服务）与 `fred-server`（持久化/查询服务）**必须**作为独立进程运行；禁止合并为单一进程。
- 跨服务通信**只允许**通过 NATS（ingest envelope）+ NATS（control plane）；禁止直接函数调用、共享内存、同进程 goroutine。

### §1.2 存储职责分层

| 存储 | 职责 | 可重建层 |
|------|------|----------|
| OSS | raw-first 原始归档（由 `fred-client` 写入） | 否（唯一原始副本） |
| Postgres | metadata/checkpoint/幂等键 | 否（权威来源） |
| TDengine | observation 时序读写 | 否（但可从 OSS 重放） |
| Redis | cache/lock/rate bucket | ✅ 可从 Postgres/TDengine 重建 |
| ClickHouse | 分析读模型 | ✅ 可从 Postgres/TDengine 重建 |
| Kafka | durable business event（`fred-server` 发布） | 否（顺序保证） |
| NATS | ingest handoff + control plane（transient） | ✅ 可从 OSS 重放 |

### §1.3 依赖方向

- `macro_data`（下游）**禁止**依赖 `fred` 的任何内部包；仅通过 `domain_macro` 接口消费。
- `ms_brain` **禁止**直接访问 fred Postgres/TDengine 表；只通过 fred Query API（domain_macro 契约）消费。
- `fred` **禁止**依赖 `macro_data` 内部包（单向依赖，参见 `module/FOUNDATION-DEPS.yaml`）。

---

## §2 采集规则

### §2.1 端点矩阵完整性

`fred-client` **必须**覆盖 FRED v1 全端点矩阵（六族）：
- Series（series/observations/search/updates）
- Release（releases/dates/series/sources）
- Category（categories/children/related/series/tags）
- Tag（tags/related_tags/series）
- Source（sources/releases）
- Update-feed（series/updates, 增量滚动）

### §2.2 覆盖率分母规则

- 覆盖率计算**分母必须**是 `spec/SERIES-CATALOG.md` 中的 **FRED-native 序列**（不含外部路由序列）。
- 外部路由序列（`source_component` 字段标记）**不计入** FRED API 采集覆盖率，但可计入总覆盖审计。
- 全量覆盖审计 Admin 端点输出格式：`{total_fred_native, covered, missing, external_routed}`。

### §2.3 raw-first 原则

1. 先写入 OSS raw 路径（含 `content_hash`）。
2. OSS 写入成功后，才允许发布 NATS ingest envelope。
3. 违反顺序视为 bug，测试必须验证。

OSS 路径格式：
```
{provider}/{endpoint}/{YYYY-MM-DD}/{job_id}/{content_hash}.json.gz
```

### §2.4 增量同步规则

- 增量采集**必须**携带 `realtime_start/realtime_end` 两个时间戳（vintage 时间序列支持）。
- 增量回拉窗口：最近 3 个月（覆盖 FRED 修订数据）。
- 增量游标存储在 Postgres checkpoint 表（`series_id + endpoint + vintage`）。

---

## §3 数据契约规则

### §3.1 禁止输出 Provider DTO

- `pkg/fredx` 的 FRED API 原始响应类型**禁止**作为跨模块契约或 NATS envelope 负载。
- 出域数据模型**必须**转换为 `domain_macro` 标准类型（MacroSeries/MacroObservation 等）。

### §3.2 时间可见性语义（no-lookahead）

所有时序数据**必须**填充四个时间戳字段：

| 字段 | 含义 |
|------|------|
| `observed_at` | 数据所属时间点（观测期）|
| `released_at` | FRED 官方公布时间 |
| `available_at` | 本系统可见时间（`released_at` 对齐）|
| `vintage_at` | 数据版本基准时间（`realtime_start`）|

- `IsVisibleAt(t)` 函数：`t >= available_at` 为可见，否则视为未来数据（no-lookahead 保证）。

### §3.3 Series ID 命名规则

详见 `spec/SERIES-NAMING.md`（SSOT）。摘要：

- FRED-native 序列：使用 FRED 官方 `series_id`（全大写，如 `CPIAUCSL`）。
- 外部路由序列：携带 `source_component` 字段（如 `"source_component": "ecb.sdmx"`），禁止使用非官方别名。
- **禁止**使用非官方别名（如 `WDTGAL`、`VXVCLS`、`JPNASSETS`）。

---

## §4 幂等性规则

### §4.1 五元组幂等键

所有写入操作以如下五元组为幂等键：
```
(series_id, vintage_at, observed_at, endpoint, job_id)
```

- 相同五元组的写入**必须**幂等（多次写入结果一致，不产生重复副作用）。
- Postgres idempotency 表为幂等键权威来源。

### §4.2 Checkpoint 状态机

Postgres checkpoint 状态机严格遵循：
```
Created → InProgress → Completed
               ↓
            Failed（可重试）
```

- **禁止**跳过 `InProgress` 直接进入 `Completed`。
- `InProgress` 超时后由 watchdog 重置为 `Created`（而非直接 `Failed`）。

---

## §5 存储写入顺序

`fred-server` ingest pipeline **必须**按以下顺序执行写入：

```
1. Postgres checkpoint: Created → InProgress
2. Postgres metadata 写入（幂等）
3. TDengine observation 写入
4. Redis cache 更新
5. ClickHouse 写入
6. Kafka durable event 发布
7. Postgres checkpoint: InProgress → Completed
```

- 任何步骤失败时**禁止**继续下一步（仅允许在 NATS 重试机制内重新消费）。
- Kafka event 发布必须在 Postgres checkpoint 成功推进到 `Completed` 之前；若 Kafka 失败，视为整体失败。

---

## §6 可观测性规则

### §6.1 必填结构化日志字段

所有采集/写入操作的日志**必须**包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `job_id` | string | 采集批次 ID |
| `series_id` | string | FRED series_id |
| `request_id` | string | HTTP/NATS 请求 ID |
| `endpoint` | string | FRED API 端点族 |

### §6.2 缺失配置 fail-fast

- 服务启动时如缺少**必要配置键**，**必须**立即 fail-fast 退出，日志输出具体缺失键名。
- 禁止使用隐式默认值屏蔽缺配置场景。

### §6.3 健康检查端点

- `/health`：进程级存活。
- `/readiness`：依赖存储（Postgres/TDengine/Redis/NATS）全部就绪后返回 200。
- `/version`：返回 Go 模块版本 + git sha。

---

## §7 边界门禁规则

### §7.1 强制边界

`scripts/boundary-gates.sh` **必须**检查以下规则，CI 中任何失败即 block PR：

| Gate | 规则 |
|------|------|
| G1 | 禁止 `fred` 包 import `macro_data` 内部包 |
| G2 | 禁止 `pkg/fredx` 导出 FRED 原始 DTO 类型到外部模块 |
| G3 | 禁止 `fred-client` 直接访问 Postgres/TDengine（只允许 `fred-server`）|
| G4 | 禁止 `fred-server` 发布 NATS ingest envelope（只允许 `fred-client`）|
| G5 | 禁止在源码中硬编码 API key / secret |

---

## §8 Series Catalog 规则

### §8.1 SERIES-CATALOG.md 权威地位

`spec/SERIES-CATALOG.md` 是 fred 模块采集序列的唯一权威来源（SSOT）。

- 所有新增序列**必须**先更新 SERIES-CATALOG，不允许采集未登记序列。
- 序列优先级（P0/P1/P2）变更**必须**经 PR 合入 SERIES-CATALOG 后才可修改采集调度配置。
- 外部路由序列（非 FRED-native）**必须**在 catalog 中标明 `source_component` 字段。

### §8.2 OPEN-CAT-1 覆盖缺口

当前已知未登记序列（见 `OPEN-CAT-1`）：

- `WTREGEN`（外汇储备/再投资，WDTGAL 的实际映射）
- `VIXCLS`（CBOE VIX 收盘价，VXVCLS 的实际映射）

修复方式：在 SERIES-CATALOG 添加对应条目，标注 `source_component` 字段（若非 FRED-native）。

---

## §9 版本管理规则

### §9.1 Spec 版本

- `spec/SPEC.md` 中 `Spec-Version` 字段是唯一版本权威来源。
- 版本号变更必须触发 `module/registry.yaml` 中 `spec_version` 同步更新。
- Patch：别名/链接/格式修复；Minor：新增 FR 或 API 变更；Major：接口契约重构。

### §9.2 向后兼容

- FRED API v1 端点变更由 `pkg/fredx` 版本管理，不直接影响 domain_macro 契约。
- `domain_macro` 接口变更走 `contracts` 仓库 ADR 流程，不在此模块单独决策。

---

## §10 CI/CD 规则

### §10.1 必须通过的 CI Gate

| Gate | 命令 | 类型 |
|------|------|------|
| 单元测试 | `go test ./... -count=1` | 每次 PR |
| 竞态检测 | `go test -race ./... -count=1` | 每次 PR |
| 静态分析 | `go vet ./...` | 每次 PR |
| 边界门禁 | `bash scripts/boundary-gates.sh` | 每次 PR |
| 集成测试 | `go test -tags integration ./internal/integration/...` | 合并到 main |

### §10.2 CI-gated 测试命名约定

- 集成测试文件名后缀：`_integration_test.go`
- Build tag：`//go:build integration`
- 集成测试**禁止**在单元测试 CI 中运行（避免外部依赖）

---

> 本文件由 `docs/report/fred/05-fred-rules-proposal.md` 提炼，经 `feat/fred-analysis-reports` 分支 P0 修复后首次正式发布。
> 变更须经 `feat/fred-*` 分支 PR 合入 main，并同步 `module/registry.yaml`。
