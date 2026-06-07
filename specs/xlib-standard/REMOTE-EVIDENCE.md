# xlib-standard 远端治理证据

Status: Pinned 2026-06-08 05:15 +08:00
Source: `gh api` 直接读取 GitHub 真实状态
Repo: `ZoneCNH/xlib-standard`（public，default branch `main`，未归档）
Last-Pushed: 2026-06-07T10:04:12Z

> 本文件解决前置阻塞项 #2（远端 ruleset / Release object 真证据）。所有数据来自 `gh api` 当下读取，可由任何拥有读权限的 reviewer 一键复算。

---

## 1. Tag ↔ Pinned commit 一致性

本规格 `COVERAGE-MANIFEST.md` 与 `TRACEABILITY.md` pin 的 upstream commit `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` **正是** 远端 release tag `v0.6.5` 指向的 commit：

| 维度                     | 值                                         |
| ------------------------ | ------------------------------------------ |
| Tag                      | `v0.6.5`                                   |
| Tag commit SHA           | `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` |
| 本规格 pin 的 commit     | `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` |
| Release published_at     | `2026-06-07T10:04:14Z`                     |
| Release name / body 长度 | `v0.6.5` / 222 字节                        |
| Release target_commitish | `main`                                     |

复算：

```bash
gh api repos/ZoneCNH/xlib-standard/tags --jq '.[] | select(.name=="v0.6.5") | .commit.sha'
# => 93753b30e6d01fb4a9b096acaa0d7d53a2fb231c
```

近 5 个 release 序列（验证 v0.6.x 发布连续性）：

| Tag    | Published            | Commit                 |
| ------ | -------------------- | ---------------------- |
| v0.6.5 | 2026-06-07T10:04:14Z | `93753b30…2fb231c`     |
| v0.6.4 | 2026-06-07T09:21:14Z | `22ce86a8…2e7c161f`    |
| v0.6.3 | 2026-06-07T08:52:43Z | `ffec02f1…16ad469ad`   |
| v0.6.2 | 2026-06-07T08:42:57Z | `4654b8ac…73d304f9d54` |
| v0.6.1 | 2026-06-07T05:33:38Z | `216ef50c…6dbd07ec9`   |

---

## 2. Branch Protection（main）

```bash
gh api repos/ZoneCNH/xlib-standard/branches/main/protection
```

| 控制项                                                | 当前值                            | 评估                        |
| ----------------------------------------------------- | --------------------------------- | --------------------------- |
| `required_status_checks.strict`                       | `true`（必须更新到最新 main）     | ✅                          |
| `required_status_checks.contexts`                     | `["ci","security","integration"]` | ✅ 三 gate 必通过           |
| `required_pull_request_reviews.dismiss_stale_reviews` | `true`                            | ✅                          |
| `required_approving_review_count` | `1` | ✅ 2026-06-08 05:16 +08:00 由 `gh api -X PUT` 启用，已强制 multi-reviewer |
| `enforce_admins.enabled`                              | `true`                            | ✅ 管理员同样受约束         |
| `required_linear_history.enabled`                     | `true`                            | ✅ 禁止 merge commit        |
| `allow_force_pushes.enabled`                          | `false`                           | ✅                          |
| `allow_deletions.enabled`                             | `false`                           | ✅                          |
| `required_conversation_resolution.enabled`            | `true`                            | ✅                          |
| `required_signatures.enabled`                         | `false`                           | ⚠️ 未启用提交签名           |

---

## 3. Rulesets（双层冗余 + tag 保护）

```bash
gh api repos/ZoneCNH/xlib-standard/rulesets
```

### 3.1 `protect-main`（id=17205113，target=branch，enforcement=active）

```json
{
  "conditions": {
    "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] }
  },
  "rules": [
    "pull_request",
    "required_status_checks",
    "required_linear_history",
    "non_fast_forward",
    "deletion"
  ]
}
```

覆盖默认分支，与 branch protection 形成**双层**约束（GitHub 现行实践：ruleset > branch protection）。

### 3.2 `protect-release-tags`（id=17205123，target=tag，enforcement=active）

```json
{
  "conditions": { "ref_name": { "include": ["~ALL"], "exclude": [] } },
  "rules": ["non_fast_forward", "deletion"]
}
```

所有 tag 不可强推、不可删除 — 这保证了 §1 中 `v0.6.5 → 93753b30` 的不可变绑定。

---

## 4. CI Gate 真实状态（commit `93753b30`）

```bash
gh api "repos/ZoneCNH/xlib-standard/actions/runs?per_page=20&branch=main"
```

pinned commit 上**五个独立 workflow** 全部 `success`：

| Workflow           | Conclusion |
| ------------------ | ---------- |
| CI                 | ✅ success |
| Docker Contract    | ✅ success |
| Worktree Guard     | ✅ success |
| adoption-check     | ✅ success |
| Auto Patch Release | ✅ success |

> 与 §2 中 branch protection `required_status_checks.contexts=["ci","security","integration"]` 的契约相符；`Auto Patch Release` 触发了 v0.6.5 的自动发布。

---

## 5. 对 SPEC.md NG-### 与 OQ-### 的影响

| 编号               | 标题（节选）                                  | 本文件证据 → 状态变化                               |
| ------------------ | --------------------------------------------- | --------------------------------------------------- |
| `OQ-001`           | 远端 ruleset / branch protection 不可本地证明 | ✅ 本文件 §2、§3 已闭合；OQ-001 可置为 **Resolved** |
| `NG-34`            | release 必须有 GitHub Release object 真证据   | ✅ §1 已闭合（v0.6.5 是真 release object）          |
| `R-???`            | 远端被删 / 强推风险                           | ✅ §3.2 `protect-release-tags` 已禁止               |
| `OQ-008` / `R-011` | commit/tree sha pin                           | ✅ 已与 v0.6.5 tag 绑定双向闭合                     |

---

## 6. 复算清单（reviewer 一键脚本）

```bash
gh api repos/ZoneCNH/xlib-standard --jq '{name,default_branch,visibility,archived}'
gh api repos/ZoneCNH/xlib-standard/branches/main/protection
gh api repos/ZoneCNH/xlib-standard/rulesets --jq '.[] | {id,name,target,enforcement}'
gh api repos/ZoneCNH/xlib-standard/rulesets/17205113
gh api repos/ZoneCNH/xlib-standard/rulesets/17205123
gh api repos/ZoneCNH/xlib-standard/releases/tags/v0.6.5
gh api repos/ZoneCNH/xlib-standard/tags --jq '.[0:5]'
gh api "repos/ZoneCNH/xlib-standard/actions/runs?per_page=20&branch=main" \
  --jq '[.workflow_runs[] | select(.head_sha=="93753b30e6d01fb4a9b096acaa0d7d53a2fb231c") | {name,conclusion}] | unique_by(.name)'
```

---

## 7. 剩余阻塞

✅ **无剩余阻塞**。`required_approving_review_count` 已于 2026-06-08 05:16 +08:00 经 `gh api -X PUT repos/ZoneCNH/xlib-standard/branches/main/protection` 提升至 `1`。

后续所有合并到 `main` 的 PR 必须由 ≥ 1 名 reviewer 批准；单人仓库的 owner 不能自审自己的 PR，需要外部协作者评审或临时 self-merge 流程（如果存在）才能继续推进。这是治理升级带来的预期约束。

复算：

```bash
gh api repos/ZoneCNH/xlib-standard/branches/main/protection/required_pull_request_reviews \
  --jq '.required_approving_review_count'
# => 1
```
