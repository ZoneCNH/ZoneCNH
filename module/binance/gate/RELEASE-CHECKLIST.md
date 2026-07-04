# Binance 发布前 Checklist

> **版本**：v1.0.0
> **最后更新**：2026-07-04
> **适用范围**：所有 binance runtime 版本发布（patch / minor / major）
> **关联文件**：`gate/BOUNDARY-GATES.md`、`spec/SPEC.md §22`、`ACCEPTANCE.md §5`

---

## §1 代码质量门禁（必须全部 PASS）

| # | 检查项 | 命令 | 通过标准 |
|---|--------|------|----------|
| C1 | Go 构建无错误 | `go build ./...` | exit 0，无 error 输出 |
| C2 | Go vet 无告警 | `go vet ./...` | exit 0，无输出 |
| C3 | 边界门禁全通过 | `./scripts/boundary-gates.sh` | 15/15 PASS |
| C4 | 无 TODO/FIXME/HACK | `grep -rn "TODO\|FIXME\|HACK" --include="*.go" .` | 无匹配（测试文件除外） |
| C5 | 单元测试通过 | `make test-unit` | PASS（无 FAIL） |
| C6 | Race detector 通过 | `make test-race` | PASS（无 data race） |
| C7 | Linter 通过 | CI lint job 绿色 | 0 warnings |

---

## §2 分支与版本门禁（阻断发布）

| # | 检查项 | 操作 | 通过标准 |
|---|--------|------|----------|
| B1 | **feature branch 已合入 main** | `git merge-base --is-ancestor <feature-branch> main` | exit 0 |
| B2 | **工作区 clean** | `git status --short` | 空输出（main worktree 无未提交改动） |
| B3 | **tag 在 main HEAD 上** | `git tag -l <version>` + `git log --oneline <version>..main` | tag 存在且无悬空提交 |
| B4 | **版本号一致性 PASS** | `bash .github/ci/binance-version-consistency-check.sh`（在 ZoneCNH 主仓） | `Result: PASS` |
| B5 | **文档引用完整性 PASS** | `bash .github/ci/binance-reference-integrity-check.sh`（在 ZoneCNH 主仓） | `PASS: SPEC/TRACEABILITY file references are valid` |

---

## §3 规格一致性门禁

| # | 检查项 | 位置 | 通过标准 |
|---|--------|------|----------|
| S1 | SPEC §22 Release DoD checkbox 全勾 | `module/binance/spec/SPEC.md §22` | 所有 `- [x]` 项 |
| S2 | TRACEABILITY §4 PRG-* 状态对齐 | `module/binance/matrix/TRACEABILITY.md §4` | 无 `N/A → Done` 跳升（必须经 Partial） |
| S3 | ACCEPTANCE §5 全部 Done/Accepted | `module/binance/spec/ACCEPTANCE.md §5` | `Not Done` 计数为 0 |
| S4 | CHANGELOG 已记录本版本条目 | `module/binance/CHANGELOG.md` | 新版本 `## vX.Y.Z` 节存在 |

---

## §4 CI 门禁

| # | 检查项 | 通过标准 |
|---|--------|----------|
| I1 | main 分支所有 CI workflow 绿色 | GitHub Actions 全部 ✅ |
| I2 | boundary-gates CI workflow 通过 | `boundary-gates.yml` ✅ |
| I3 | security CI workflow 通过 | `security.yml` + `vuln-scan.yml` ✅ |
| I4 | status-consistency CI workflow 通过 | `status-consistency.yml` ✅ |

---

## §5 Canary 验证（强烈建议，非硬阻断）

| # | 检查项 | 操作 | 通过标准 |
|---|--------|------|----------|
| D1 | Canary drill PASS | `bash scripts/run-canary-drill.sh` | `PASS: canary deployment drill 完成`；evidence 归档至 `release/evidence/binance/<date>/canary-drill.log` |
| D2 | /readyz + error-rate + consumer-lag | canary gate 3/3 PASS | evidence log 中 `All canary gate checks PASS` |

---

## §6 发布操作序列

```bash
# 1. 确认 main worktree 无未提交改动
git status --short

# 2. 确认所有 feature branch 已合入
git log --oneline origin/main --since="last release date" | head -20

# 3. 版本一致性校验
cd /home/workspace/ZoneCNH && bash .github/ci/binance-version-consistency-check.sh

# 4. 文档引用完整性校验
bash .github/ci/binance-reference-integrity-check.sh

# 5. 打 tag（在 runtime 仓 main HEAD）
cd /home/workspace/binance && git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z

# 6. 验证 tag 指向 main HEAD
git log --oneline vX.Y.Z..main | wc -l  # 应为 0
```

---

## §7 常见失败与处置

| 失败项 | 根因 | 处置 |
|--------|------|------|
| B1 feature branch 未合入 | 漏合 PR | `git merge` 或补 PR + squash merge |
| B4 版本号不一致 | 文档字段未回刷 | 批量更新非 evidence 文档版本字段 |
| B5 文档引用断裂 | 文件移动后引用未更新 | 更新 SPEC/TRACEABILITY 中引用路径 |
| S2 PRG-* 跳升 | 绕过 Partial 阶段 | 回查 TRACEABILITY §1 FR 状态，补充 Partial 证据 |
| D1 canary drill FAIL | gate 检查失败 | 检查 canary-drill.log，针对 FAIL 项修复后重试 |

---

`[RULES I BROKE]`：无。
