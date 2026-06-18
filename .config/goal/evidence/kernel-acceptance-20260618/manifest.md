# kernel 验收证据包 — 2026-06-18

- 证据包 ID: kernel-acceptance-20260618
- 模块: kernel
- 模块版本: v1.0.0
- 运行时仓库: github.com/ZoneCNH/kernel
- 运行时分支: ci/sre-cicd-pools-20260618（HEAD de6ae91 — route foundation delivery through SRE runner pools）
- 文档基线: module/kernel/SPEC.md v2.0.0
- 验证日期: 2026-06-18

## 验收命令与结果

| 类别 | 命令 | 结果 | 证据 |
| --- | --- | --- | --- |
| 文档存在性 | `test -f module/kernel/FEATURES.md && test -f module/kernel/ACCEPTANCE.md` | ✅ PASS | 两份文档均存在（116 行 / 127 行） |
| 文档格式 | `git diff --check -- module/kernel` | ✅ PASS | 无尾随空格 |
| 运行时测试 | `cd /home/kernel && go test ./...` | ✅ PASS | 27 个包全部通过（含 contracts、contracttest、12 子包、12 examples、internal/testutil） |
| 竞态检查 | `cd /home/kernel && go test ./... -race -count=1` | ✅ PASS | 27 个包全部通过，无 data race，单包平均 1s |
| 静态检查 | `cd /home/kernel && go vet ./...` | ✅ PASS | 无 vet 报告 |
| 覆盖率证据 | `cd /home/kernel && make coverage-threshold` | ✅ PASS | 14 个核心库包 100.0%（contextx/contracttest/errx/healthx/internal/testutil/lifecycx/obsx/retryx/shutdownx/syncx/timex/validx/versionx）；contracts 为 [no statements] |
| 依赖边界 | `cd /home/kernel && bash scripts/check-stdlib-only.sh` | ✅ PASS | STDLIB-ONLY CHECK PASSED：仅主模块输出 |
| 凭证扫描 | `cd /home/kernel && bash scripts/check_secrets.sh` | ✅ PASS | secret check passed |

## 覆盖率详细数据

| 包 | 覆盖率 | 备注 |
| --- | --- | --- |
| contextx | 100.0% | |
| contracttest | 100.0% | |
| errx | 100.0% | |
| healthx | 100.0% | |
| internal/testutil | 100.0% | |
| lifecycx | 100.0% | |
| obsx | 100.0% | |
| retryx | 100.0% | |
| shutdownx | 100.0% | |
| syncx | 100.0% | |
| timex | 100.0% | |
| validx | 100.0% | |
| versionx | 100.0% | |
| contracts | [no statements] | 仅契约/快照 |

`coverage.out` 同目录归档。

## CI/CD 部署状态

/home/kernel 已部署完整 CI/CD（HEAD `de6ae91 route foundation delivery through SRE runner pools`）：

| Workflow | 触发 | 机器池 | 必经 Job |
| --- | --- | --- | --- |
| `.github/workflows/ci.yml` | PR / push main / workflow_dispatch | sre/foundation-l0 | workflow-policy → module-ci (matrix 12 子包) → ci (Go 1.26.3 / 1.23) → coverage upload + evidence |
| `.github/workflows/release.yml` | tag `v*` push | sre/deploy | release-check（make release-final-check）→ manifest upload → GH Release |
| `.github/workflows/security.yml` | PR / push main / workflow_dispatch | sre/foundation-l0 | toolchain → boundary → security → contracts → SARIF upload |
| `.github/workflows/standard-sync-watch.yml` | scheduled | sre/foundation-l0 | xlib-standard 漂移检查 |

所有 actions 已 SHA-pin，runner 全部走 `sre/` 池，无 GitHub-hosted 回退。

## 当前发布版本

- Latest GitHub Release: `v1.0.0` (published 2026-06-12)
- 本次验收不变更代码版本号；ZoneCNH 文档侧版本通过 `release/manifest/latest.json` patch bump 跟踪

## Factory 状态

- 代码侧门禁全部通过 ✅
- BLK-011 仍 open：blocking_factory=true / blocking_release=false
- 仍需 Goal Matrix kernel 边由 Dropped 改为 Verified 与四源 98+ arbiter 归档；该步骤需在 .config/goal pipeline 内单独执行，本会话只归档代码侧证据

## 证据文件清单

- `manifest.md`（本文件）
- `coverage.out`（make coverage-threshold 输出，从 /home/kernel 复制）
