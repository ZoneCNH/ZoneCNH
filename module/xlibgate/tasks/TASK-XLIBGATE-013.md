# TASK-XLIBGATE-013

> trust release-consistency 实现

---

```yaml
task_id: TASK-XLIBGATE-013
module: xlibgate
scope: "实现 trust release-consistency 命令：七源版本一致性校验（.repo-contract.yaml / go.mod / VERSION / CHANGELOG / git tag / release manifest / GitHub release）"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-014"
  - "module/xlibgate/SPEC.md#TC-018"
  - "module/xlibgate/SPEC.md#TC-019"
files:
  - "cmd/trust_release.go"
  - "scanner/trust/release.go"
acceptance_criteria:
  - "AC-013: 七源一致 → exit 0, reason_code=\"\""
  - "AC-013: 版本不一致 → exit 1, reason_code=RELEASE_DRIFT"
  - "AC-013: VERSION 或 CHANGELOG 缺失 → exit 1, reason_code=RELEASE_DRIFT"
  - "AC-013: --offline 默认模式读取本地 manifest/tag 投影"
  - "AC-013: --online 模式查询 GitHub API，release 不存在 → RELEASE_DRIFT"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "3h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                    | Acceptance Criteria |
| ----------- | ---------------------------------------------- | ------------------- |
| FR-014      | trust release-consistency：七源版本一致性      | 4 个 WHEN 路径      |
| TC-018      | release-consistency offline pass               | 七源一致 → exit 0   |
| TC-019      | release-consistency fail                       | VERSION vs CHANGELOG 不一致 → exit 1 |

## Non-scope

- 不修改 VERSION/CHANGELOG 文件
- 不做语义化版本比较（仅字符串比对）

## Implementation Notes

- 离线模式读取 `release/manifest/latest.json` 和 `git tag` 本地投影
- 在线模式通过 GitHub Releases API 查询
- GitHub API 调用需处理速率限制（403）

## Test Plan

| Test Case | Type | Description                           |
| --------- | ---- | ------------------------------------- |
| TC-018    | Unit | 七源一致 → pass                       |
| TC-019    | Unit | VERSION vs CHANGELOG 不一致 → RELEASE_DRIFT |
| —         | Unit | VERSION 缺失 → RELEASE_DRIFT          |
| —         | Unit | CHANGELOG 缺失 → RELEASE_DRIFT        |
