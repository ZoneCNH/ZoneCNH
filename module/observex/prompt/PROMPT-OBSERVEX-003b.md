# TASK-OBSERVEX-003b 开发 Prompt

> 实现 label policy 检查：AllowedLabels 允许通过，ForbiddenLabels 拒绝并返回错误
>
> 上游 Task：[TASK-OBSERVEX-003b.md](../tasks/TASK-OBSERVEX-003b.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 设计方案：[DESIGN.md](../DESIGN.md)
> 权威 Spec：[SPEC.md](../SPEC.md)

---

## 任务

实现 label policy 检查器，在每次指标 Add/Record/Set 前检查 label 合规性。

## 关联需求

| 类型 | 编号 | AC | TC | 出处 | 说明 |
|------|------|----|----|------|------|
| FR | FR-006 | AC-006 | TC-002, TC-015 | SPEC.md §7 | Label Policy 合规检查 |

## 依赖

- 上游 Task：TASK-OBSERVEX-002
- 优先级：P0

## 文件清单

以下文件允许修改：
- `label_policy.go`
- `label_policy_test.go`

## 验收标准

以下验收标准必须全部满足：
- AllowedLabels 中的 label 允许通过
- ForbiddenLabels 中的 label 返回 ErrLabelForbidden
- label policy 并发调用安全

## 实现要点

见 [TASK-OBSERVEX-003b.md](../tasks/TASK-OBSERVEX-003b.md) 的 `Implementation Notes` 和 `Implementation Plan` 章节。

## 验证命令

| 命令                  | 判定标准     |
| --------------------- | ------------ |
| `go build ./...`      | 编译通过     |
| `go test -race ./...` | 无 data race |
| `go vet ./...`        | 无警告       |

## 禁止事项

- 不要在实现中引入 SPEC 未定义的接口或类型
- 不要跳过 label policy 检查
- 不要跨子包直接访问内部状态
- 不要硬编码 label 列表（从 SPEC §9.5 常量定义读取）

## 证据回填

完成后提交以下产物：
- 测试输出：`go test -v -race ./...` 完整输出
- 覆盖率报告：`go test -coverprofile=.coverage/cover.out ./... && go tool cover -func=.coverage/cover.out`
- 文件变更清单：`git diff --stat HEAD`
- 如有 Benchmark：`go test -bench=. -benchmem ./...` 结果

## 完成后

1. 运行全部验证命令确认通过
2. 更新 TASK-OBSERVEX-003b 状态为 completed
3. 如有证据产物，写入 `docs/evidence/` 目录
