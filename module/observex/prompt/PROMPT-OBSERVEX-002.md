# TASK-OBSERVEX-002 开发 Prompt

> 实现 Logger 接口，支持结构化日志输出、level 过滤、With 不变性、并发安全
>
> 上游 Task：[TASK-OBSERVEX-002.md](../tasks/TASK-OBSERVEX-002.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 设计方案：[DESIGN.md](../DESIGN.md)
> 权威 Spec：[SPEC.md](../SPEC.md)

---

## 任务

实现 Logger 接口，支持结构化日志输出、level 过滤、With 不变性、并发安全

## 关联需求
| 类型 | 编号 | AC | TC | 出处 | 说明 |
|------|------|----|----|------|------|
| FR | FR-001 | AC-001, AC-008, AC-012 | TC-001 | SPEC.md §7 | — |
| BR | BR-001 | AC-001, AC-008, AC-012 | TC-001 | SPEC.md §8 | — |
| BR | BR-005 | AC-001, AC-008, AC-012 | TC-001 | SPEC.md §8 | — |
## 依赖

- 上游 Task：TASK-OBSERVEX-001
- 优先级：P0

## 文件清单

以下文件允许修改：
- `logger/logger.go`
- `logger/impl.go`
- `logger/logger_test.go`

## 验收标准

以下验收标准必须全部满足：
- Info/Warn/Error 输出结构化日志
- Debug level=info 时不输出
- With 返回新实例
- 并发无 data race

## 实现要点

见 [TASK-OBSERVEX-002.md](../tasks/TASK-OBSERVEX-002.md) 的 `Implementation Notes` 和 `Implementation Plan` 章节。

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
2. 更新 TASK-OBSERVEX-002 状态为 completed
3. 如有证据产物，写入 `docs/evidence/` 目录
