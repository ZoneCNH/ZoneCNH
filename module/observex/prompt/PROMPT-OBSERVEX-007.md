# TASK-OBSERVEX-007 开发 Prompt

> 实现 health JSON schema 输出，包含 ready/live/message/components
>
> 上游 Task：[TASK-OBSERVEX-007.md](../tasks/TASK-OBSERVEX-007.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 设计方案：[DESIGN.md](../DESIGN.md)
> 权威 Spec：[SPEC.md](../SPEC.md)

---

## 任务

实现 health JSON schema 输出，包含 ready/live/message/components

## 关联需求
| 类型 | 编号 | AC | TC | 出处 | 说明 |
|------|------|----|----|------|------|
| FR | FR-007 | AC-007 | TC-006, TC-006a | SPEC.md §7 | — |
## 依赖

- 上游 Task：TASK-OBSERVEX-000
- 优先级：P1

## 文件清单

以下文件允许修改：
- `health.go`
- `health_test.go`

## 验收标准

以下验收标准必须全部满足：
- JSON 输出符合 schema
- ready/live/message/components 字段

## 实现要点

见 [TASK-OBSERVEX-007.md](../tasks/TASK-OBSERVEX-007.md) 的 `Implementation Notes` 和 `Implementation Plan` 章节。

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -race ./...` | 无 data race |
| `go vet ./...` | 无警告 |

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
2. 更新 TASK-OBSERVEX-007 状态为 completed
3. 如有证据产物，写入 `docs/evidence/` 目录
