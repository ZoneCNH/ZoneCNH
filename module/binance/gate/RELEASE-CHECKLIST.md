# Binance 发布前 Checklist

> **职责**：本文件只负责发布前门禁判定，不描述开发路径、也不展开执行细节。

> **版本**：v1.1.0
> **最后更新**：2026-07-10
> **适用范围**：所有 binance runtime 版本发布（patch / minor / major）
> **关联文件**：`gate/BOUNDARY-GATES.md`、`spec/SPEC.md §21（Release Gate）`、`spec/ACCEPTANCE.md §5`

> [COMPUTED, HIGH] 2026-07-10 审计基线为 `b20f6d44f8b246149c7a9f9c06a4dc27bc7b49ef`，其上的 feature worktree 尚未形成不可变 RC；canonical 规格状态为 13 Done / 52 Partial / 0 Drifted / 0 Pending，spec/runtime 均为 NO。external-gates 的 NATS/Kafka/TDengine/Redis/API 五项仍为 `BLOCKED/NOT_RUN`，因此本 checklist 不得标记 release-closeable。

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
| E5 | Options/legacy scope | [FRAME, HIGH] 当前四线目标必须包含 Options order book 并通过对应 evidence；若负责人批准缩小 profile，必须先同步 Goal/Spec/AC/Matrix，并记录 legacy alias sunset 日期/owner |

---

## §5 Canary 验证（强烈建议，非硬阻断）

| # | 检查项 | 操作 | 通过标准 |
|---|--------|------|----------|
| D1 | Canary drill PASS | `bash scripts/run-canary-drill.sh` | `PASS: canary deployment drill 完成`；evidence 归档至 `release/evidence/binance/<date>/canary-drill.log` |
| D2 | /readyz + error-rate + consumer-lag | canary gate 3/3 PASS | evidence log 中 `All canary gate checks PASS` |

---

## §6 发布交接序列

| 阶段 | 必须证明 | 责任边界 |
| --- | --- | --- |
| Freeze | main clean、feature 已合入、唯一不可变 RC SHA | 模块负责人提供只读证据，不在本文记录工作站路径 |
| Validate | 版本一致性、引用完整性、build/vet/test/race/boundary 全部绑定 RC | CI/SRE 保存原始退出码与日志 |
| Authorize | tag、artifact digest、SBOM、人工批准和变更单相互可追溯 | 获授权负责人签署；agent 不代签或发布 |
| Handoff | 生成符合 [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml) 的 `zonecnh.deploy-contract.v1` 请求 | 真实执行只进入 `sre/deploy` 平面 |
| Verify | runner evidence、external readback、canary、rollback 与观察窗均绑定同一 RC | 缺项保持 `release_closeable=NO` |

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
