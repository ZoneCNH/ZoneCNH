# TASK-XLIBGATE-019

> trust 集成测试 + 文档

---

```yaml
task_id: TASK-XLIBGATE-019
module: xlibgate
scope: "Trust 子命令组集成测试、README trust 章节、CHANGELOG 更新"
spec_ref:
  - "module/xlibgate/spec/SPEC.md#16.5 集成测试"
  - "module/xlibgate/spec/SPEC.md#22 Release DoD"
files:
  - "README.md"
  - "CHANGELOG.md"
acceptance_criteria:
  - "AC-019: 所有 trust 子命令集成测试通过"
  - "AC-019: TC-014~TC-029 全部有对应测试"
  - "AC-019: README.md 包含 trust 命令参考和快速开始"
  - "AC-019: CHANGELOG.md 记录 trust 子命令组发布"
depends_on:
  - "TASK-XLIBGATE-011"
  - "TASK-XLIBGATE-012"
  - "TASK-XLIBGATE-013"
  - "TASK-XLIBGATE-014"
  - "TASK-XLIBGATE-015"
  - "TASK-XLIBGATE-016"
  - "TASK-XLIBGATE-017"
  - "TASK-XLIBGATE-018"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description                              |
| ----------- | ---------------------------------------- |
| §16.5       | 集成测试                                 |
| §22         | Release DoD                              |

## Non-scope

- 不实现新的 trust 检查逻辑
- 不修改 check/l2 文档

## Deliverables

| 文件          | 内容                                       |
| ------------- | ------------------------------------------ |
| README.md     | trust 命令参考（8 子命令 + --help 输出）   |
| CHANGELOG.md  | v0.3.0 发布记录（trust 子命令组）          |

## Milestone

```bash
xlibgate trust fleet-status --repos-root testdata/foundation-root --output /tmp/index.json
# → exit 0, index.json 含 20 模块状态

go test -race -count=1 ./...
# → 全部通过

go tool cover -func=.coverage/cover.out | grep total
# → ≥ 80%
```
