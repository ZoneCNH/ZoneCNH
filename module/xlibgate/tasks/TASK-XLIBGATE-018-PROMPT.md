# Context Packet — TASK-XLIBGATE-018

> trust fleet-status：20 模块舰队状态聚合
> 来源：SPEC.md v1.1.1 FR-019, TC-028, TC-029

## Current Task

TASK-XLIBGATE-018: 实现 trust fleet-status 命令，聚合 20 模块舰队状态

## Related Spec

- module/xlibgate/SPEC.md FR-019 (trust fleet-status)
- module/xlibgate/SPEC.md TC-028 (all pass), TC-029 (partial fail)

## Current Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_fleet.go | CLI 命令入口，--repos-root, --output, --summary-only |
| scanner/trust/fleet.go | 模块遍历 + 聚合逻辑 |

### 聚合流程

1. 遍历 `--repos-root` 下的模块目录
2. 对每个模块内联检查 identity/release/maturity/boundaries
3. 不存在 `.repo-contract.yaml` 的模块标记 status=error
4. 生成 `.foundationx/status/index.json`

### index.json 每模块字段

`identity`, `release`, `maturity`, `boundaries`, `blockers`, `evidence-index`

### Exit Code

| 场景 | Exit |
|------|------|
| 20 模块全成功 | 0 |
| 部分模块失败 | 1（仍生成完整 index.json） |
| 模块数 != 20 | 1（含 warning） |

## Non-Scope

- 不嵌套调用 CLI（fleet-status 内联聚合，不 invoke 子命令）
- 不推送 index.json 到远程

## Acceptance Criteria

- TC-028: 20 模块全成功 → exit 0, 生成 index.json
- TC-029: 2 模块 error → exit 1, 仍生成 index.json
- --summary-only → 仅输出摘要 JSON
- .foundationx/status/ 不存在 → 自动创建

## Constraints

- 不依赖外部 API（纯本地文件系统操作）
- index.json 为合法 JSON
- 统一 JSON 输出

## Verification

```bash
xlibgate trust fleet-status --repos-root testdata/foundation-root --output /tmp/index.json 2>&1; [ $? -eq 0 ]
cat /tmp/index.json | jq '.modules | length'  # 应为 20
```
