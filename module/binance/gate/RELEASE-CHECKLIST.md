# Binance 发布前 Checklist

> **职责**：本文件只负责发布前门禁判定，不描述开发路径、也不展开执行细节。

> **版本**：v1.1.0
> **最后更新**：2026-07-10
> **适用范围**：所有 binance runtime 版本发布（patch / minor / major）
> **关联文件**：`gate/BOUNDARY-GATES.md`、`spec/SPEC.md §21（Release Gate）`、`spec/ACCEPTANCE.md §5`

> [COMPUTED, HIGH] 当前 implementation commit：`3f6366728b635c32d73565874965d40c20a92caf`。本地代码门禁已 PASS；`release/evidence/binance/20260710/external-gates.tsv` 的 NATS/Kafka/TDengine/Redis/API 五项仍为 `BLOCKED/NOT_RUN`，packet validator 为 11 blockers，因此本 checklist 不得标记 runtime release-closeable。

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

> B3 通过只表示 tag 指向目标 commit；它不替代 external-gates。正式发布还必须验证同一 commit 的 NATS/Kafka/TDengine/Redis/API evidence、部署 preflight 和 rollback packet。

---

## §3 规格一致性门禁

| # | 检查项 | 位置 | 通过标准 |
|---|--------|------|----------|
| S1 | SPEC Release Gate / Release DoD 全勾 | `module/binance/spec/SPEC.md §21（Release Gate）` + `ACCEPTANCE.md §5` | 所有 `- [x]` 项 / §5 全 Done |
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

## §4.1 外部证据门禁（runtime release hard block）

| # | 检查项 | 通过标准 |
|---|--------|----------|
| E1 | NATS PubAck/ManualAck | 同一 bundle 有真实 JetStream publish duplicate、Ack、Nak/MaxDeliver 日志；local unit 不替代 |
| E2 | Kafka fanout | 配置 broker/topic/ACL 摘要与 producer→consumer roundtrip 日志；缺凭证为 `BLOCKED` |
| E3 | Durable storage/query | TDengine write/read、Redis hot-cache TTL/key、API latest/range read-back 全部 PASS；ClickHouse 阻断必须原样保留 |
| E4 | Release provenance | `head.log`、tag SHA、CI URL、release notes、preflight 和 rollback evidence 指向同一 commit |
| E5 | Options/legacy scope | release packet 明确 options order book Phase 2 excluded 与 legacy alias sunset 日期/owner |

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
