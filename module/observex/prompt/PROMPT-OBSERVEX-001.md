# TASK-OBSERVEX-001 开发 Prompt

> 定义 Logger、Meter、Tracer、Exporter 接口及 Field、Attr、Span 类型
>
> 上游 Task：[TASK-OBSERVEX-001.md](../tasks/TASK-OBSERVEX-001.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 设计方案：[DESIGN.md](../DESIGN.md)
> 权威 Spec：[SPEC.md](../SPEC.md)

---

## 任务

定义 Logger、Meter、Tracer、Exporter 接口及 Field、Attr、Span 类型

## 关联需求
| 类型   | 编号   | AC      | TC           | 出处   | 说明   |
| ------ | ------ | ------- | ------------ | ------ | ------ |
| §      | §9.1   | SPEC.md | 见 SPEC §9.1 |        |        |
| §      | §9.2   | SPEC.md | 见 SPEC §9.2 |        |        |
| §      | §9.3   | SPEC.md | 见 SPEC §9.3 |        |        |
| §      | §9.4   | SPEC.md | 见 SPEC §9.4 |        |        |
## 依赖

- 上游 Task：TASK-OBSERVEX-000
- 优先级：P0

## 文件清单

以下文件允许修改：
- `logger/logger.go`
- `meter/meter.go`
- `tracer/tracer.go`
- `exporter/exporter.go`

## 验收标准

以下验收标准必须全部满足：
- Logger 接口 6 方法
- Meter 接口 3 方法
- Tracer+Span 接口完整
- Exporter 接口 4 方法
- go build 通过

## 实现要点

见 [TASK-OBSERVEX-001.md](../tasks/TASK-OBSERVEX-001.md) 的 `Implementation Notes` 和 `Implementation Plan` 章节。

## 验证命令

| 命令                  | 判定标准     |
| --------------------- | ------------ |
| `go build ./...`      | 编译通过     |
| `go test -race ./...` | 无 data race |
| `go vet ./...`        | 无警告       |

## 禁止事项

- 不要在实现中引入 SPEC 未定义的接口或类型
- 不要跳过 label policy 检查（Meter 相关 Task）
- 不要跳过 redaction（Logger 输出相关 Task）
- 不要跨子包直接访问内部状态
- 不要硬编码 exporter 端点或凭证

## 证据回填

完成后提交以下产物：
- 测试输出：`go test -v -race ./...` 完整输出
- 覆盖率报告：`go test -coverprofile=.coverage/cover.out ./... && go tool cover -func=.coverage/cover.out`
- 文件变更清单：`git diff --stat HEAD`
- 如有 Benchmark：`go test -bench=. -benchmem ./...` 结果

## 完成后

1. 运行全部验证命令确认通过
2. 更新 TASK-OBSERVEX-001 状态为 completed
3. 如有证据产物，写入 `docs/evidence/` 目录
