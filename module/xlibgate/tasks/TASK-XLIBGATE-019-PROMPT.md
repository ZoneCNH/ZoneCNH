# Context Packet — TASK-XLIBGATE-019

> trust 集成测试 + 文档
> 来源：SPEC.md v1.1.1 §16.5, §22

## Current Task

TASK-XLIBGATE-019: trust 子命令组集成测试、README trust 章节、CHANGELOG

## Related Spec

- module/xlibgate/SPEC.md §16.5 集成测试
- module/xlibgate/SPEC.md §22 Release DoD
- module/xlibgate/SPEC.md TC-014~TC-029

## Scope

| Deliverable | Description |
|-------------|-------------|
| README.md | trust 命令参考（8 子命令 + --help 输出 + 快速开始） |
| CHANGELOG.md | 新增 trust 子命令组发布记录 |

### 集成测试

- 端到端 CLI 调用：`xlibgate trust fleet-status --repos-root testdata/foundation-root`
- 验证 index.json 结构和内容
- 验证所有 8 子命令可独立运行
- TC-014~TC-029 全部通过

### 覆盖率要求

- `go test -race -count=1 ./...` 全部通过
- `go tool cover -func=.coverage/cover.out` → ≥ 80%

## Non-Scope

- 不实现新的 trust 检查逻辑
- 不修改 check/l2 文档

## Acceptance Criteria

- 所有 trust 子命令集成测试通过
- TC-014~TC-029 全部有对应测试
- README.md 包含 trust 命令参考
- CHANGELOG.md 记录 trust 子命令组发布

## Constraints

- 集成测试使用 `//go:build integration` 标签
- README 遵循项目文档风格
- 不依赖 Foundation 运行时模块

## Validation

```bash
go test -race -count=1 ./...
go tool cover -func=.coverage/cover.out | grep total | awk '{print $3}'
xlibgate trust fleet-status --repos-root testdata/foundation-root --output /tmp/index.json
```
