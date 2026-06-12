# TASK-KERNEL-011 开发 Prompt

> 上游 Task：[TASK-KERNEL-011.md](./tasks/TASK-KERNEL-011.md)
> healthx 子包：健康检查状态与聚合

---

## 任务

实现 `kernel/healthx` 子包。提供健康检查状态值类型和聚合规则，依赖 timex 子包。

## 文件清单

### 1. `healthx/healthx.go`

- `HealthStatusValue`：`"healthy"` / `"degraded"` / `"unhealthy"`
- `HealthStatus` 结构体：Name + Status + Message + CheckedAt + LatencyMs + Metadata
- `HealthChecker` 接口：`Name() string` / `Check(ctx) HealthStatus`
- `NewHealthStatus(name, status, message, checkedAt, latencyMs) HealthStatus`
- `HealthStatus.WithMetadata(key, value) HealthStatus`：不可变模式
- `HealthStatus.IsHealthy() bool`
- `Aggregate(name, statuses...) HealthStatus`：优先级 unhealthy > degraded > healthy
- `AggregateWithClock(name, clock, statuses...) HealthStatus`：clock=nil 回退 RealClock

### 2. `healthx/healthx_test.go`

覆盖：构造/IsHealthy、Aggregate 全 healthy/degraded/unhealthy/mixed、空 statuses、WithMetadata 不可变、Metadata nil JSON → {}、AggregateWithClock。

### 3. `healthx/example_test.go`

展示 HealthChecker 实现、Aggregate 多服务聚合。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-005 | FR-003 | Aggregate 测试 | 优先级聚合正确 |
| AC-HEALTHX-06 | BR-007 | Metadata nil JSON | 序列化为 {} |

## 禁止事项

- 不要依赖非 stdlib 包（除 timex）
- 不要在 HealthChecker.Check 中产生副作用
- Metadata 不要存储敏感信息

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-011/`：
1. `go test -race -count=1 ./healthx/...` 输出
2. Aggregate 各组合覆盖证据
3. JSON 序列化验证

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./healthx/...` | 编译通过，零错误 |
| `go test -race -count=1 ./healthx/...` | 全部测试通过，无 race |
| `go vet ./healthx/...` | 无警告 |

## 完成后

1. 运行 `go vet ./healthx/...` 确认无警告
2. 验证 Metadata nil → {} 的 MarshalJSON
3. 更新 TASK-KERNEL-011 状态为 completed
