# TASK-ALERTX-007 开发 Prompt

> 健康导出 + 自观测指标 + 进程入口 + Dockerfile

- 上游 Task：[TASK-ALERTX-007.md](../tasks/TASK-ALERTX-007.md) | Spec：[SPEC.md#FR-006](../SPEC.md) [#17](../SPEC.md)

## 任务

实现 health.JSON（对齐 observex schema）、自观测指标 `foundationx_alertx_*`、cmd/alertx 独立进程入口（signal + graceful shutdown）、Dockerfile。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-006 | AC-006 | TC-018 |
| BR | BR-007 | AC-014 | TC-018 |
| EC | EC-010 | AC-015 | TC-017 |

## 依赖

- 上游：TASK-005（通知）+ TASK-006（订阅），本 task 组装为可运行进程
- observex：HealthStatus schema（ready/live/message/components）

## 实现要点

1. `pkg/alertx/health.go`：health.JSON
   - 输出 `{"ready":bool,"live":bool,"message":string,"components":[...]}`（对齐 observex）
   - 渠道不可达 → component live=false，整体 ready=false，不 panic（FR-006）
2. `pkg/alertx/labels.go`：自观测指标命名 `foundationx_alertx_<measure>`
   - alerts_fired/dedup_suppressed/notify_failed/rules_loaded/evaluations/alerts_dropped/reload_failed（counter/gauge）
   - 命名校验（BR-007/metrics-contract-check）
3. `cmd/alertx/main.go`：独立进程入口
   - 加载配置 → 初始化 Engine（订阅+评估+去重+通知）→ health server（health_port）
   - signal handling：SIGTERM → graceful shutdown（flush 通知，关闭 AlertStore，退出）（EC-010/TC-017）
4. `Dockerfile`：多阶段构建（builder → 最小运行镜像）

## 验证

```bash
cd /home/alertx && GOWORK=off go build ./cmd/alertx && GOWORK=off go test ./... -run TestHealth -v
docker build -t alertx:v1.0.0 . # 验证 Dockerfile
```

## 关键测试

- `TestHealth_JSONSchema`：四字段正确；渠道不可达 live=false 不 panic
- `TestHealth_Uninitialized`：未初始化 ready=false
- `TestMain_GracefulShutdown`：集成测试，SIGTERM → flush + 干净退出（EC-010）
- `TestMetrics_Naming`：所有指标符合 foundationx_alertx_\<measure\>（BR-007）
