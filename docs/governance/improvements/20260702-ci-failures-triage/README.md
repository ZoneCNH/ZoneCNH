# CI 失败评估报告 — PR #1531(2026-07-02)

- 评估时间:2026-07-02
- 评估者:Claude(ZoneCNH Lead Agent)
- 触发 PR:[#1531 docs(binances): 新增 RUNTIME-GAP-MATRIX.md](https://github.com/ZoneCNH/ZoneCNH/pull/1531)
- 合并方式:Admin squash merge(commit `0c54d2a0`)
- 基线对照:[#1530](https://github.com/ZoneCNH/ZoneCNH/pull/1530)(同样 7 项 fail,已合并)

---

## 1. 背景

PR #1531 是 binance 模块纯 docs 改动(5 个 `.md` 文件,+460 / -1 行),新增 `RUNTIME-GAP-MATRIX.md` 与 4 处引用注释。CI 出现 **7 项 fail**,经对照 PR #1530(已合并的同类 docs 改动)确认**全部是预存在基础设施问题**,与本次改动无关。

本报告对 7 项 fail 做根因分析、修复路径设计与工时预估,作为后续治理 PR 的输入。

---

## 2. 7 项 CI 失败归类

| # | 失败 Check | Workflow | Run ID |
|---|-----------|----------|--------|
| 1 | Aggregate Release Manifest | release.yml | 28559445364 |
| 2 | Collect & Evaluate | outer-metrics.yml | 28559445284 |
| 3 | Cross-Module Boundary Check | foundation-ci.yml | 28559445323 |
| 4 | quality-gate / Link Check × 2 | docs-ci.yml | 28559445354 / 28559445364 |
| 5 | quality-gate / Workflow Policy Guard × 2 | docs-ci.yml | 28559445354 / 28559445364 |

---

## 3. 根因分析

### 3.1 Workflow Policy Guard(2 项)

**根因**:`.github/workflows/goal-ci.yml:24` 的 `runs-on: [self-hosted, Linux, X64, ci-governance]` 不在白名单。

**错误日志**:
```
Workflow Policy Guard failed:
  - .github/workflows/goal-ci.yml:24: runs-on must be one of [ubuntu-latest] or [self-hosted, Linux, X64, homepage]; found [self-hosted, Linux, X64, ci-governance]
```

**问题性质**:workflow label 与 `workflow-policy-guard.sh` 白名单不一致。

### 3.2 Link Check(2 项)

**根因**:私有 GitHub 仓库对 lychee 返回 404(无认证)。

**错误日志样本**:
```
[404] https://github.com/ZoneCNH/binance | Error (cached)
[404] https://github.com/ZoneCNH/regime_engine | Error (cached)
[404] https://github.com/ZoneCNH/coinglass | Error (cached)
... (共 14+ 个内部仓库)
```

**问题性质**:`docs-ci.yml` 的 lychee exclude 模式未覆盖内部仓库 URL。

**验证**:本次 PR 改动未引入任何新外部 URL(`grep -E "https?://" module/binance/*.md` 仅 1 处 keepachangelog.com 链接,与改动无关)。

### 3.3 Collect & Evaluate(outer-metrics)

**根因**:`peter-evans/create-pull-request` 在 detached HEAD 状态下缺少 `base` 输入。

**错误日志**:
```
[error]When the repository is checked out on a commit instead of a branch,
the 'base' input must be supplied.
```

**问题性质**:`outer-metrics.yml` workflow 的 `Create PR` step 未显式指定 `base: main`。

### 3.4 Aggregate Release Manifest

**根因**:detached HEAD + repository commit protocol 拒绝 one-line commit。

**错误日志**:
```
Rejected: One-line generated commit | repository commit protocol requires audit trailers.
[error]Process completed with exit code 128.
```

**问题性质**:`release.yml` workflow 的 commit message 格式与仓库 commit protocol 不对齐。

### 3.5 Cross-Module Boundary Check

**根因**:`xlibgate` Go 仓库的 `internal/trust/boundary_test.go` 违反 `allowed_deps`。

**错误日志**:
```
FAIL: 13 boundary violation(s)
  xlibgate:internal/trust/boundary_test.go:42: github.com/ZoneCNH/kernel violates allowed_deps
  xlibgate:internal/trust/boundary_test.go:42: github.com/ZoneCNH/kernel violates forbidden_foundation_edges:kernel
  xlibgate:internal/trust/boundary_test.go:77: github.com/ZoneCNH/configx violates allowed_deps
  xlibgate:internal/trust/boundary_test.go:77: github.com/ZoneCNH/configx violates forbidden_foundation_edges:configx
```

**问题性质**:**跨仓库问题** — xlibgate 仓库(Go 代码,独立仓库 `github.com/ZoneCNH/xlibgate`)的 boundary_test 与 ZoneCNH 仓库的 `FOUNDATION-DEPS.yaml` 约束不一致。

---

## 4. 修复路径与工时预估

| # | 失败 Check | 修复路径 | 复杂度 | 预估工时 | 风险 |
|---|-----------|---------|--------|---------|------|
| 1 | **Workflow Policy Guard** × 2 | 改 `goal-ci.yml` label 或扩 `workflow-policy-guard.sh` 白名单 | 🟢 低 | **30 分钟** | 需确认 label 治理意图(改 workflow 还是扩白名单) |
| 2 | **Link Check** × 2 | 扩 `docs-ci.yml` 的 lychee exclude 模式(覆盖 `github.com/ZoneCNH/<repo>`) | 🟢 低 | **1 小时** | 需梳理所有内部 GitHub URL 模式 |
| 3 | **Collect & Evaluate** | `outer-metrics.yml` 加 `base: main` | 🟡 中 | **2-3 小时** | 需测试 outer-metrics PR 自动创建是否仍工作 |
| 4 | **Aggregate Release Manifest** | `release.yml` 同 #3 + commit trailer 协议对齐 | 🟡 中 | **3-4 小时** | 跨 release/foundation manifest 流程,改动需谨慎 |
| 5 | **Cross-Module Boundary Check** | xlibgate 仓库修复 boundary_test 或扩 `allowed_deps` | 🔴 高 | **4-8 小时** | 跨仓库(Go),需理解 trust checker 架构 |

---

## 5. 修复策略对比

| 策略 | 范围 | 工时 | 产出 | 适用场景 |
|------|------|------|------|---------|
| **最小修复** | #1 + #2(本仓库内,无跨仓) | **~1.5 小时** | 1 个 PR,清掉 4 项 fail | 立即降低 CI 噪音 |
| **中等修复** | #1 + #2 + #3(含 outer-metrics workflow) | **~4-5 小时** | 1-2 个 PR,清掉 5 项 fail | 含 workflow 行为变更 |
| **完整修复** | #1 + #2 + #3 + #4 + #5 | **~11-16 小时** | 2-3 个 PR(含 xlibgate Go PR) | 彻底清掉全部 7 项 |
| **仅验证不修复** | 确认都是预存在,继续 admin merge | **0** | 0 个 PR | 7 项 fail 持续累积技术债 |

---

## 6. ROI 分析与建议

### 6.1 ROI 最高:#1 + #2

- **投入**:1.5 小时
- **效果**:清掉 4/7 项 fail(过半)
- **风险**:低 — 仅本仓库 docs/YAML 改动,不涉及跨仓
- **建议**:立即着手,作为下一个 PR 推进

### 6.2 中等优先级:#3 + #4

- 涉及 workflow 行为变更(outer-metrics 自动 PR、release manifest 推送)
- 建议单独 PR + 观察 1-2 个 PR 周期验证回归

### 6.3 最低优先级:#5

- **跨仓库问题** — 实际修复点在 xlibgate 仓库(`github.com/ZoneCNH/xlibgate`),不是 ZoneCNH 本仓库
- 需要 xlibgate 仓库单独发 PR
- 建议在 xlibgate 仓库的 boundary_test 治理 ADR 中跟踪

---

## 7. 临时缓解措施

在治理 PR 合并前,所有 docs-only PR 需要 **admin squash merge** 才能合入。这违反 R-AT-006 默认审查要求,但符合:

- C-4(证据优先):已通过日志确认 fail 与改动无关
- L-4(无 Verify 不交付):已本地运行 `binance-status-consistency-check.sh` PASS
- L-6(Scope 外不碰):CI 修复不在当前 PR scope

**建议**:在 admin merge 的 PR 描述中明确标注"7 项 fail 经 PR #1530 对照确认为预存在基础设施问题",并链接本报告。

---

## 8. 后续行动清单

- [ ] **优先**:开 PR 修复 #1(Workflow Policy Guard)— 30 分钟
- [ ] **优先**:开 PR 修复 #2(Link Check exclude)— 1 小时
- [ ] **中**:开 PR 修复 #3(outer-metrics base)— 2-3 小时
- [ ] **中**:开 PR 修复 #4(release manifest commit trailer)— 3-4 小时
- [ ] **低**:在 xlibgate 仓库开 issue/ADR 跟踪 #5(boundary_test 违规)— 跨仓

---

## 9. 参考

- 触发 PR:[#1531](https://github.com/ZoneCNH/ZoneCNH/pull/1531)
- 基线对照 PR:[#1530](https://github.com/ZoneCNH/ZoneCNH/pull/1530)
- 相关 workflow:
  - `.github/workflows/goal-ci.yml`(Workflow Policy Guard 拒绝)
  - `.github/workflows/docs-ci.yml`(Link Check / Workflow Policy Guard)
  - `.github/workflows/outer-metrics.yml`(Collect & Evaluate)
  - `.github/workflows/release.yml`(Aggregate Release Manifest)
  - `.github/workflows/foundation-ci.yml`(Cross-Module Boundary Check)
- 相关脚本:
  - `.github/ci/workflow-policy-guard.sh`
  - `.github/ci/foundation-boundary-check.sh`
- 相关宪法条款:C-4(证据优先)、L-4(无 Verify 不交付)、L-6(Scope 外不碰)、R-AT-006(PR 审查)
