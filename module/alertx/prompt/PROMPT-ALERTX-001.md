# TASK-ALERTX-001 开发 Prompt

> 建立 alertx 仓骨架 + 对接 contracts alert 契约 + 基础 errors/options

- 上游 Task：[TASK-ALERTX-001.md](../tasks/TASK-ALERTX-001.md)
- 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
- 权威 Spec：[SPEC.md](../SPEC.md)
- 架构基线：[ADR-001-foundations.md](../ADR-001-foundations.md)

## 任务

在 `/home/workspace/alertx`（新建仓）建立独立进程骨架，对接 contracts v1.6.0 alert 契约。

## 关联需求

| 类型 | 编号 | AC | TC | 出处 |
| --- | --- | --- | --- | --- |
| §8 接口契约 | §8 | — | — | SPEC §8 |
| §9 数据模型 | §9 | — | — | SPEC §9 |
| §11 错误处理 | §11 | — | — | SPEC §11 |
| §13 目录结构 | §13 | — | — | SPEC §13 |

## 依赖

- 上游：无（首个 task）
- contracts：`/home/workspace/contracts/pkg/contracts/alert.go`（feat/contracts-alert-types 分支，AlertEvent/AlertRule/Severity/AlertStatus/AlertSink/AlertRuleStore）

## 实现要点

1. `go.mod`：`module github.com/ZoneCNH/alertx`，`go 1.23`，require contracts（本地 `replace github.com/ZoneCNH/contracts => /home/workspace/contracts`）
2. `pkg/alertx/version.go`：`ModuleName` + `Version = "v1.0.0"`（CI 从此读版本）
3. `pkg/alertx/errors.go`：sentinel errors（ErrRuleInvalid/ErrChannelUnknown/ErrSuppressWindowZero/ErrNotifyFailed/ErrRuleLoadFailed/ErrStoreUnavailable），消息格式 `"alertx: <op>: <detail>"`（CONSTITUTION §8.2）
4. `pkg/alertx/options.go`：Engine 配置选项（functional options 模式）
5. 目录骨架：`cmd/alertx/` + `pkg/alertx/` + `internal/{config,channel,subscribe,store}/` + `contracts/` + `examples/` + `testkit/` + `scripts/` + `release/`

## 验证

```bash
cd /home/workspace/alertx && GOWORK=off go build ./... && GOWORK=off go vet ./... && gofmt -l pkg/alertx/
```

## 编码规范

- go-coding-standards §2：包全小写单单词（alertx）、文件 snake_case
- §4 错误：sentinel + `%w`、消息全小写不以标点结尾
- §3 注释：所有导出声明注释，注释以被声明名开头
