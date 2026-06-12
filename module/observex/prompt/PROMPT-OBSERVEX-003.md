# TASK-OBSERVEX-003 开发 Prompt

> 实现 Meter 接口（Counter/Histogram/Gauge），集成 label policy 检查
>
> 上游 Task：[TASK-OBSERVEX-003.md](../tasks/TASK-OBSERVEX-003.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 设计方案：[DESIGN.md](../DESIGN.md)
> 权威 Spec：[SPEC.md](../SPEC.md)

---

## 任务

实现 Meter 接口（Counter/Histogram/Gauge），集成 label policy 检查

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-002 | SPEC.md $ | 
| FR | FR-006 | SPEC.md $ | 
| BR | BR-002 | SPEC.md $ | 
| BR | BR-006 | SPEC.md $ | 

## 依赖

- 上游 Task：TASK-001
- 优先级：P0

## 文件清单

见 [TASK-OBSERVEX-003.md](../tasks/TASK-OBSERVEX-003.md) 的 `files` 字段。

## 验收标准

见 [TASK-OBSERVEX-003.md](../tasks/TASK-OBSERVEX-003.md) 的 `acceptance_criteria` 字段。

## 实现要点

见 [TASK-OBSERVEX-003.md](../tasks/TASK-OBSERVEX-003.md) 的 `Implementation Notes` 和 `Implementation Plan` 章节。

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

## 完成后

1. 运行全部验证命令确认通过
2. 更新 TASK-OBSERVEX-003 状态为 completed
3. 如有证据产物，写入 `docs/evidence/` 目录
