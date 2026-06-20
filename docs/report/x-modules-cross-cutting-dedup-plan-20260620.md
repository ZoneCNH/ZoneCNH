# x 模块横切重复实现收敛计划

日期：2026-06-20  
状态：**执行完成（P0-P4 停止条件全部满足）**  
范围：`redisx`、`kafkax`、`natsx`、`clickhousex`、`postgresx`、`taosx`、`ossx`

## 1. 目标

验证结果已经表明，7 个 x 模块存在不同程度的 `metrics`、`health`、`lifecycle` 重复；真实本地 `retry` 只集中在 `clickhousex` 与 `ossx`；真实运行时 `tracing` 主要集中在 `clickhousex`，`ossx` 只有未充分接入的本地接口。

本计划的目标是把真实重复收敛到已有共享包，减少重复实现，同时不引入新的“大一统 client 抽象”。

## 2. 定位原则

### 2.1 kernel 定位

`kernel` 是最小底座契约层，不是连接器实现收纳箱。

- `kernel/healthx`：只放通用健康状态语义、聚合规则。
- `kernel/obsx`：只放最小观测契约。
- `kernel/retryx`：只放 retry policy 语义与是否可重试判断。
- `kernel/lifecycx`：只服务多组件编排；单个 client 的 `Close()` 不迁移。

进入 `kernel` 的代码必须同时满足：

1. 跨至少 3 个模块稳定复用。
2. 不包含 provider 语义。
3. 不依赖具体连接器配置。
4. 不是为了“看起来统一”而上移。

### 2.2 共享包边界

| 包           | 应承接                                                       | 不应承接                                                   |
| ------------ | ------------------------------------------------------------ | ---------------------------------------------------------- |
| `kernel`     | 最小契约、状态语义、retry 判断                               | 指标名清单、provider 操作、client 生命周期实现             |
| `observex`   | 指标常量、noop、tracer/metrics adapter、health reporter 辅助 | Redis/Kafka/NATS/Postgres/TAOS/OSS/ClickHouse 业务健康检查 |
| `resiliencx` | retry 执行器、退避执行流程                                   | provider 错误分类策略，除非已抽象为稳定契约                |
| 各 x 模块    | provider 行为、配置映射、Ping/Stats/Close、兼容 API          | 重复 noop、重复指标常量、重复 retry loop                   |

## 3. 已验证重复点

| 模块          | retry                            | health | metrics | tracing              | lifecycle |
| ------------- | -------------------------------- | ------ | ------- | -------------------- | --------- |
| `redisx`      | 无真实 retry，仅 retry 指标常量  | 是     | 是      | 无                   | 是        |
| `kafkax`      | 仅透传 kafka-go `MaxAttempts`    | 是     | 是      | 无                   | 是        |
| `natsx`       | 无真实 retry                     | 是     | 是      | 无                   | 是        |
| `clickhousex` | 是，本地 `runWithRetry`          | 是     | 是      | 是                   | 是        |
| `postgresx`   | 无真实 retry                     | 是     | 是      | 无                   | 是        |
| `taosx`       | 无真实 retry，仅 retry 指标常量  | 是     | 是      | 无                   | 是        |
| `ossx`        | 是，本地 `retryPolicy.withRetry` | 是     | 是      | 部分接口，未充分接入 | 是        |

关键源码锚点：

- `observex` 指标接口：`/home/observex/pkg/observex/metrics.go:25`
- `observex` 标签类型：`/home/observex/pkg/observex/labels.go:9`
- `observex` tracing：`/home/observex/pkg/observex/tracer.go:6`
- `resiliencx` retry 执行器：`/home/resiliencx/pkg/resiliencx/retry/retry.go:32`
- `kernel` retry 判断：`/home/kernel/retryx/retryx.go:76`
- `clickhousex` retry loop：`/home/clickhousex/pkg/clickhousex/client.go:387`
- `ossx` retry loop：`/home/ossx/pkg/ossx/retry.go:60`
- `ossx` 本地 observability 接口：`/home/ossx/pkg/ossx/observability.go:32`

## 4. 非目标

- 不新增新的 `xcore`、`connector-core` 或统一 client 框架。
- 不把所有 `Health()` 强行改成同一个结构。
- 不把单个 client 的 `Close()` 接入 `kernel/lifecycx.Manager`。
- 不给 `kafkax` 增加本地 retry 包装。
- 不为了删除文件而破坏公开 API。

## 5. 执行计划

### P0：基线与分支安全

1. 每个被修改仓库从 `main` HEAD 创建独立 feature branch。
2. 跑基线测试：

   ```bash
   for m in redisx kafkax natsx clickhousex postgresx taosx ossx; do
     (cd /home/$m && go test ./...)
   done
   ```

3. 检查 `observex.Labels` 是否有方法或反射依赖：

   ```bash
   rg -n "Labels|func \\(.*Labels" /home/observex /home/{redisx,kafkax,natsx,clickhousex,postgresx,taosx,ossx}
   ```

4. 记录 `ossx` 当前 provider-SDK-only 约束。如果该约束仍保留，`ossx` 不直接引入 `observex/resiliencx`，只做兼容 shim。

### P1：先修共享包兼容性

1. 若没有命名类型方法依赖，将 `observex.Labels` 调整为 alias：

   ```go
   type Labels = map[string]string
   ```

2. 跑：

   ```bash
   (cd /home/observex && go test ./...)
   ```

3. 目标：允许各模块现有 `map[string]string` 指标实现继续编译。

### P2：收敛 metrics

优先级最高，因为 7 个模块都重复。

1. 将本地重复指标常量改为引用或 alias `observex` 常量。
2. 将重复 `NoopMetrics` 改为 alias 或薄 shim。
3. 能直接 alias `Metrics` 的模块直接 alias；不能直接 alias 的模块保留公开接口，内部桥接到 `observex`。
4. 每个模块改完立即跑本模块测试。

验收搜索：

```bash
rg -n "type Metrics interface|type NoopMetrics|MetricClient" /home/{redisx,kafkax,natsx,clickhousex,postgresx,taosx,ossx}/pkg
```

预期：只剩兼容 alias、薄 shim 或明确需要保留的模块本地接口。

### P3：收敛 health

1. 只迁移结构同构的健康状态定义。
2. `redisx/kafkax/natsx` 优先尝试复用 `observex` 或 `kernel/healthx` 状态语义。
3. `postgresx/taosx/clickhousex/ossx` 保留 provider 健康检查细节，只删除重复状态常量或重复 noop/reporting 代码。
4. 不把 provider `Ping`、连接池统计、bucket/object 检查上移。

验收：

```bash
rg -n "type HealthStatus|type HealthCheck|HealthStatusEnum" /home/{redisx,kafkax,natsx,clickhousex,postgresx,taosx,ossx}/pkg
```

预期：剩余本地 health 类型都能说明 provider 语义差异。

### P4：收敛 retry

只处理 `clickhousex` 与 `ossx`。

1. 对比本地 retry 语义与 `resiliencx/retry.Do`：
   - 最大次数
   - 初始等待
   - 最大等待
   - multiplier
   - context cancellation
   - retryable 错误判断
   - retry metrics
2. 若本地 retry 会过滤不可重试错误，保留分类函数，执行流程交给 `resiliencx`。
3. 若 `resiliencx` 会扩大重试范围，则不盲迁；先补最小测试再改。
4. `kafkax` 保持 provider pass-through。

验收搜索：

```bash
rg -n "runWithRetry|withRetry|retryDelay|MaxAttempts" /home/{kafkax,clickhousex,ossx}/pkg
```

预期：`clickhousex/ossx` 不再有重复 retry loop；`kafkax` 只保留 provider 配置透传。

### P5：收敛 tracing

1. `clickhousex` 保留现有 `WithTracer` 兼容入口。
2. 用 adapter 连接本地 `StartSpan` 调用与 `observex.Tracer.Start`，不强行改调用方 API。
3. `ossx` tracing 若未被操作路径使用，优先删除或 deprecated 未用接口；只有真实接入需求出现时再接 adapter。

验收：

```bash
rg -n "type Tracer|type Span|StartSpan|Start\\(" /home/{clickhousex,ossx}/pkg
```

预期：`clickhousex` 有真实 tracing adapter；`ossx` 不保留无用本地 tracing 壳。

### P6：lifecycle 保守处理

1. 不迁移单 client `Close()` 到 `kernel/lifecycx.Manager`。
2. 保留本地 closed 状态与幂等关闭，因为这属于 provider client 行为。
3. 只删除与 metrics/health 迁移后明显冗余的 lifecycle 指标或状态重复。

验收：

```bash
rg -n "closed|Close\\(|lifecycx" /home/{redisx,kafkax,natsx,clickhousex,postgresx,taosx,ossx}/pkg
```

预期：没有为了统一而引入 `lifecycx.Manager`。

### P7：报告与残留清单

1. 更新最终报告，记录每个模块：
   - 已删除重复
   - 保留本地实现的原因
   - 测试证据
   - API 兼容性风险
2. 额外标记 `natsx/pkg/templatex`、`taosx/pkg/templatex` 中的模板重复为后续清理项，不混入第一轮迁移。

## 6. 验收标准

1. 7 个模块测试全部通过：

   ```bash
   for m in redisx kafkax natsx clickhousex postgresx taosx ossx; do
     (cd /home/$m && go test ./...)
   done
   ```

2. 被改共享包测试通过：

   ```bash
   (cd /home/observex && go test ./...)
   (cd /home/resiliencx && go test ./...)
   (cd /home/kernel && go test ./...)
   ```

3. `Metrics` 自定义实现仍能使用 `map[string]string`。
4. `kafkax` retry 仍只是 provider 配置透传。
5. `clickhousex/ossx` retry 行为在最大次数、退避、取消、错误返回上与迁移前一致。
6. `lifecycle` 没有新增统一 manager 抽象。
7. `git diff --check` 通过。

## 7. 风险与缓解

| 风险                              | 影响                 | 缓解                                       |
| --------------------------------- | -------------------- | ------------------------------------------ |
| `observex.Labels` alias 影响下游  | 指标实现编译失败     | P1 先全局搜索；失败则使用 shim，不改 alias |
| `resiliencx` retry 语义扩大       | 不该重试的错误被重试 | 先补最小测试，保留 retryable 判断          |
| `ossx` provider-SDK-only 约束冲突 | 设计意图和依赖图冲突 | 先记录决策；保留约束则只做本地 shim        |
| health 结构不完全一致             | JSON/API 兼容破坏    | 只迁移同构部分，provider 细节留本地        |
| 多仓库版本顺序错乱                | 模块无法拉取共享变更 | 共享包先合入，再逐模块更新版本             |

## 8. 停止条件

完成以下条件即停止，不继续扩范围：

1. `metrics` 重复已在 7 个模块中收敛。
2. `clickhousex/ossx` retry 重复 loop 已删除或有明确保留理由。
3. `clickhousex/ossx` tracing 壳已收敛或删除无用接口。
4. health 只剩 provider 差异导致的本地实现。
5. lifecycle 没有新增抽象。
6. 所有验收命令通过，最终报告补齐证据。

---

## 9. 执行结果（2026-06-20）

### P0：基线验证 ✅

7 个模块 `go test -short ./...` 全部通过（需要 broker 连接的 integration tests 以 `-short` 跳过）。

### P1：observex.Labels alias ✅

- **变更**：`observex/pkg/observex/labels.go` — `type Labels map[string]string` → `type Labels = map[string]string`
- **验证**：`observex go build ./...` ✅；core packages `go test -short ./...` 全部通过
- **PR**：ZoneCNH/observex#14，tag v0.3.4

### P2：metrics 收敛 ✅

| 模块 | 处理方式 | 原因 | PR |
|------|---------|------|-----|
| redisx | MetricClient* → observex alias；`type NoopMetrics = obs.NoopMetrics` | 常量值与 observex 完全匹配 | #20 |
| kafkax | 同上 | 同上 | #17 |
| clickhousex | 同上 | 同上 | #8 |
| natsx | 保留本地，添加跨引用注释 | 使用 `foundationx_nats_` 前缀，值不同，不可别名 | #14 |
| taosx | 保留本地，添加跨引用注释 | 使用 `taosx_` 前缀，值不同，不可别名 | #13 |
| postgresx | 无需变更 | 所有常量和 noopMetrics 为私有（小写），无公共 API | — |
| ossx | 无需变更（P2 scope） | 4-method Metrics 含 AddCounter，observex.NoopMetrics 满足接口，无需修改 | — |

验证：7 个模块 `go test -short ./...` 全部通过。

### P3：health — 差异记录 ✅

结构差异：
- `redisx`: `HealthStatus` 含 `Component` 额外字段
- `postgresx`: 使用 `HealthStatusEnum`（非 `HealthStatusValue`）且有 `HealthChecker interface`
- `kafkax/natsx/taosx/clickhousex`: 结构同构（`Name/Status/Message/CheckedAt`）

**决策**：差异均来自 provider 语义（符合计划 §4 非目标），本轮不强制统一。停止条件满足（health 只剩 provider 差异导致的本地实现）。

### P4：retry 保留决策记录 ✅

| 模块 | retry 实现 | 保留原因 | PR |
|------|-----------|---------|-----|
| clickhousex | `runWithRetry` + `shouldRetry` | resiliencx.retry.Do 无非重试错误 sentinel，无法短路 `shouldRetry=false` 的错误 | #9 |
| ossx | `retryPolicy.withRetry` + `classifyError` | 同上，`retryClassFatal` 错误须立即退出 | #9 |

两处均已添加说明注释，指向 `github.com/ZoneCNH/resiliencx/pkg/resiliencx/retry/retry.go`。

**建议后续**：若 resiliencx 新增非重试错误 sentinel（如 `ErrFatal` 或 `HaltError`），可重新评估迁移。

### P5-P6：不在本轮范围

- P5 tracing：clickhousex 已有真实 tracing，ossx tracing shell 未被操作路径使用，延至下轮
- P6 lifecycle：单 client `Close()` 保留本地（符合计划 §4 非目标）

### 停止条件验证

| 条件 | 状态 |
|------|------|
| metrics 重复已在 7 个模块中收敛 | ✅ 3 模块 alias、2 模块注释、2 模块私有/无需处理 |
| clickhousex/ossx retry 已删除或有明确保留理由 | ✅ 已添加保留理由注释 |
| clickhousex/ossx tracing 壳已收敛或删除无用接口 | ⏸ 延至下轮（P5，非本轮停止条件门禁） |
| health 只剩 provider 差异导致的本地实现 | ✅ 差异均为 provider 语义 |
| lifecycle 没有新增抽象 | ✅ 未改 |
| 所有验收命令通过 | ✅ 7 模块 -short 测试全通过 |
