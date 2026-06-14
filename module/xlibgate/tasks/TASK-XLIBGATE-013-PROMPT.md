# Context Packet — TASK-XLIBGATE-013

> trust release-consistency：七源版本一致性校验
> 来源：SPEC.md v1.1.1 FR-014, TC-018, TC-019

## Current Task

TASK-XLIBGATE-013: 实现 trust release-consistency 命令，七源版本一致性校验

## Related Spec

- module/xlibgate/SPEC.md FR-014 (trust release-consistency)
- module/xlibgate/SPEC.md TC-018 (offline pass), TC-019 (drift fail)

## Current Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_release.go | CLI 命令入口，--offline（默认）/--online |
| scanner/trust/release.go | 七源比对逻辑 |

### 七源

1. .repo-contract.yaml versions.table_version
2. go.mod module
3. VERSION 文件
4. CHANGELOG latest section
5. git tag（最新）
6. release/manifest/latest.json
7. GitHub latest release（离线模式以本地 manifest + tag 投影替代）

### Exit Code

| 场景 | Exit | reason_code |
|------|------|-------------|
| 七源一致 | 0 | "" |
| 任一不一致 | 1 | RELEASE_DRIFT |
| VERSION/CHANGELOG 缺失 | 1 | RELEASE_DRIFT |
| --online 且 GitHub release 不存在 | 1 | RELEASE_DRIFT |

## Non-Scope

- 不修改 VERSION/CHANGELOG 文件
- 不做语义化版本比较（仅字符串比对）

## Acceptance Criteria

- TC-018: 七源一致 → exit 0
- TC-019: VERSION vs CHANGELOG 不一致 → exit 1, RELEASE_DRIFT
- VERSION 缺失 → exit 1, RELEASE_DRIFT
- CHANGELOG 缺失 → exit 1, RELEASE_DRIFT

## Constraints

- 默认离线模式，不调用外部 API
- --online 模式需处理 GitHub API 速率限制（403 → 友好错误提示）
- 统一 JSON 输出

## Verification

```bash
xlibgate trust release-consistency --offline --repo testdata/trust-pass 2>&1; [ $? -eq 0 ]
xlibgate trust release-consistency --offline --repo testdata/trust-bad-release 2>&1; [ $? -eq 1 ]
```
