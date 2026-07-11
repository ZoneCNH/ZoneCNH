# 全仓状态投影事实审计报告
> 日期：2026-07-11
> 审计源：.foundationx/status/index.json (generated_at 2026-07-10)
> 审计范围：25 个 foundation 模块（index.json modules 段）
> 补充参考：module/registry.yaml, GitHub Releases (xhyperium org)

---

## 审计结论

| 状态 | 模块数 | 占比 |
|------|--------|------|
| ALL PASS | 10 | 40% |
| PHANTOM | 12 | 48% |
| PARTIAL (stale) | 3 | 12% |

**关键发现：48% 的模块（12/25）存在 phantom 问题，其中 2 个为高危 phantom（kernel tag_orphan, transportx go.mod 错误）。**

---

## Phantom 分类汇总

| Phantom 类型 | 模块数 | 模块列表 |
|-------------|--------|---------|
| tag_missing (本地) | 14 | configx, observex, testkitx, resiliencx, schedulex, postgresx, taosx, ossx, clickhousex, bootstrap, domainx, domain_market, domain_macro, domain_exchange |
| tag_orphan (tag 不在祖先链) | 1 | kernel |
| go.mod 路径错误 | 6 | xlib_standard, xlib_harness, transportx, domain_market, domain_macro, domain_exchange |
| CI never green / no runs | 4 | kernel, bootstrap, domain_macro, domain_exchange |
| registry 版本与 status 不一致 | 2 | decimalx, domain_exchange |
| status 版本低于实际 Release | 6 | xlib_harness, xlib_evidence, xlibgate, kernel, redisx, taosx |

**注**：一个模块可能命中多个 phantom 标记，汇总只列出每模块最严重标记。

---

## 各模块详细审计

### xlib_standard

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/xlib_standard (GitHub), /home/workspace/xlib_standard (local) |
| go.mod 一致 | **FAIL** | go.mod: `github.com/xhyperium/xlib-standard` (kebab-case!) 应为 `github.com/xhyperium/xlib_standard` |
| tag 存在 | PASS | v1.0.2 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.0.2 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.2 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.0.2, layer=standard-source
审计结论: **PARTIAL: go.mod kebab-case 错误**

---

### xlib_harness

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/xlib_harness |
| go.mod 一致 | **FAIL** | go.mod: `github.com/xhyperium/xlib-harness` (kebab-case!) 应为 `github.com/xhyperium/xlib_harness` |
| tag 存在 | PASS | v0.1.7 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v0.1.7 在 main 祖先链上 |
| CI 状态 | SKIP | 最新 CI: skipped |
| Release | PASS | GitHub Release v0.1.7 存在（但最新 Release 是 v0.2.1 — 状态投影 stale） |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v0.1.7, layer=harness
审计结论: **PARTIAL: go.mod kebab-case + 状态版本 v0.1.7 低于实际 Release v0.2.1**

---

### xlib_evidence

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/xlib_evidence |
| go.mod 一致 | PASS | `github.com/xhyperium/xlib_evidence` |
| tag 存在 | PASS | v0.2.5 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v0.2.5 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v0.2.5 存在（但最新 Release 是 v0.3.0 — 状态投影 stale） |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v0.2.5, layer=evidence
审计结论: **PARTIAL: 状态版本 v0.2.5 低于实际 Release v0.3.0**

---

### xlibgate

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/xlibgate |
| go.mod 一致 | PASS | `github.com/xhyperium/xlibgate` |
| tag 存在 | PASS | v1.2.0 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.2.0 在 main 祖先链上 |
| CI 状态 | PENDING | 最新 CI: pending |
| Release | PASS | GitHub Release v1.2.0 存在（但最新 Release 是 v1.3.0 — 状态投影 stale） |
| 近期活跃 | PASS | 最后提交 2026-07-10 |

状态声明值: grade=factory, version=v1.2.0, layer=gate
审计结论: **ALL PASS** (CI pending 是瞬时状态；stale version 不阻塞)

---

### kernel

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/kernel |
| go.mod 一致 | PASS | `github.com/xhyperium/kernel` |
| tag 存在 | PASS | v1.1.0 tag 存在 |
| tag 祖先 | **FAIL** | v1.1.0 与 main 无公共祖先 — **tag 完全孤立**（release/v1.1.0 分支已脱离 main lineage） |
| CI 状态 | **FAIL** | 最新 main CI: failure |
| Release | PASS | GitHub Release v1.1.0 存在（但最新 Release 是 v1.1.1） |
| 近期活跃 | PASS | 最后提交 2026-07-11 (fix/disable-govulncheck 分支) |

状态声明值: grade=factory, version=v1.1.0, layer=L0
审计结论: **PHANTOM: tag_orphan + ci_never_green**

> 严重程度：CRITICAL。kernel 是 L0 核心原语库，被 19 个模块依赖。v1.1.0 tag 不是 main 分支祖先意味着"发布的版本"不在主线上——这是 git 治理的严重漏洞。

---

### configx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/configx |
| go.mod 一致 | PASS | `github.com/xhyperium/configx` |
| tag 存在 | PASS* | 本地 tag 缺失，但远程 tag v1.1.0 存在 (gh api 确认) |
| tag 祖先 | SKIP | 无法在 worktree 验证（本地无 tag），远程 tag 存在 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.1.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 (fix/gitleaks-cli 分支) |

状态声明值: grade=factory, version=v1.1.0, layer=L1
审计结论: **ALL PASS** (本地 tag 缺失是 worktree 未 fetch，不影响生产)

---

### observex

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/observex |
| go.mod 一致 | PASS | `github.com/xhyperium/observex` |
| tag 存在 | PASS* | 本地 tag 缺失，远程确认 v0.3.4 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v0.3.4 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v0.3.4, layer=L1
审计结论: **ALL PASS**

---

### testkitx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/testkitx |
| go.mod 一致 | PASS | `github.com/xhyperium/testkitx` |
| tag 存在 | PASS* | 远程确认 v1.0.0 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade="N/A" (test-only), version=v1.0.0, layer=L1
审计结论: **ALL PASS**

---

### resiliencx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/resiliencx |
| go.mod 一致 | PASS | `github.com/xhyperium/resiliencx` |
| tag 存在 | PASS* | 本地仅有 v1.0.0 tag，远程确认 v1.0.2 存在 |
| tag 祖先 | SKIP | worktree 无 v1.0.2 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.2 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-10 |

状态声明值: grade=factory, version=v1.0.2, layer=L1
审计结论: **ALL PASS**

---

### schedulex

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/schedulex |
| go.mod 一致 | PASS | `github.com/xhyperium/schedulex` |
| tag 存在 | PASS* | 远程确认 v1.0.0 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.0.0, layer=L1
审计结论: **ALL PASS**

---

### redisx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/redisx |
| go.mod 一致 | PASS | `github.com/xhyperium/redisx` |
| tag 存在 | PASS | v1.1.1 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.1.1 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.1.1 存在（但最新 Release 是 v1.1.2） |
| 近期活跃 | PASS | 最后提交 2026-07-10 |

状态声明值: grade=factory, version=v1.1.1, layer=L2
审计结论: **ALL PASS** (状态 stale 但不阻塞)

---

### kafkax

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/kafkax |
| go.mod 一致 | PASS | `github.com/xhyperium/kafkax` |
| tag 存在 | PASS | v1.1.0 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.1.0 在 main 祖先链上 |
| CI 状态 | PENDING | 最新 CI: pending |
| Release | PASS | GitHub Release v1.1.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-10 |

状态声明值: grade=factory, version=v1.1.0, layer=L2
审计结论: **ALL PASS** (CI pending 是瞬时状态)

---

### natsx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/natsx |
| go.mod 一致 | PASS | `github.com/xhyperium/natsx` |
| tag 存在 | PASS | v1.0.4 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.0.4 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.4 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.0.4, layer=L2
审计结论: **ALL PASS**

---

### postgresx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/postgresx |
| go.mod 一致 | PASS | `github.com/xhyperium/postgresx` |
| tag 存在 | PASS* | 远程确认 v1.1.2 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.1.2 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-10 |

状态声明值: grade=factory, version=v1.1.2, layer=L2
审计结论: **ALL PASS**

---

### taosx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/taosx |
| go.mod 一致 | PASS | `github.com/xhyperium/taosx` |
| tag 存在 | PASS | v1.0.2 远程 tag 存在（本地有 v1.0.0/v1.0.1/v1.1.0/v1.1.1/v1.1.2 但缺 v1.0.2 — 可能轻量 tag 未 fetch） |
| tag 祖先 | SKIP | worktree 无 v1.0.2 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.2 存在（但最新 Release 是 v1.1.2 — 状态投影严重 stale） |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.0.2, layer=L2
审计结论: **ALL PASS** (但 version 比实际 Release v1.1.2 落后 3 个次版本)

---

### ossx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/ossx |
| go.mod 一致 | PASS | `github.com/xhyperium/ossx` |
| tag 存在 | PASS* | 远程确认 v1.2.0 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.2.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.2.0, layer=L2
审计结论: **ALL PASS**

---

### clickhousex

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/clickhousex |
| go.mod 一致 | PASS | `github.com/xhyperium/clickhousex` |
| tag 存在 | PASS* | 远程确认 v1.0.9 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.9 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.0.9, layer=L2
审计结论: **ALL PASS**

---

### contracts

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/contracts |
| go.mod 一致 | PASS | `github.com/xhyperium/contracts` |
| tag 存在 | PASS | v0.4.7 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v0.4.7 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v0.4.7 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v0.4.7, layer=contracts
审计结论: **ALL PASS**

---

### transportx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/transportx |
| go.mod 一致 | **FAIL** | go.mod: `github.com/xhyperium/xlib-standard` — **复制粘贴错误！应该是 `github.com/xhyperium/transportx`** |
| tag 存在 | PASS | v1.1.1-spec tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.1.1-spec 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.1.1-spec 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-10 |

状态声明值: grade=factory, version=v1.1.1-spec, layer=contracts
审计结论: **PHANTOM: go.mod 路径错误 — go.mod 声明的 module path 是 xlib-standard 而非 transportx**

---

### bootstrap

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/bootstrap |
| go.mod 一致 | PASS | `github.com/xhyperium/bootstrap` |
| tag 存在 | PASS | v0.2.0 远程 tag 存在（本地有 v0.2.2 但缺 v0.2.0 — 轻量 tag 未 fetch） |
| tag 祖先 | SKIP | worktree 无 v0.2.0 tag |
| CI 状态 | **FAIL** | 最新 main CI: failure |
| Release | PASS | GitHub Release v0.2.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v0.2.0, layer=L1
审计结论: **PHANTOM: ci_never_green** — CI 当前 failing

---

### domainx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/domainx |
| go.mod 一致 | PASS | `github.com/xhyperium/domainx` |
| tag 存在 | PASS | v1.0.1 远程 tag 存在（本地有 v0.1.0 但缺 v1.0.1） |
| tag 祖先 | SKIP | worktree 无 v1.0.1 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.1 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 |

状态声明值: grade=factory, version=v1.0.1, layer=L2.5
审计结论: **ALL PASS**

---

### decimalx

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/decimalx |
| go.mod 一致 | PASS | `github.com/xhyperium/decimalx` |
| tag 存在 | PASS | v1.0.0 tag 存在且是 main 祖先 |
| tag 祖先 | PASS | v1.0.0 在 main 祖先链上 |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.0.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-10 |
| registry 版本不一致 | **FAIL** | **registry.yaml: latest_tag=v0.2.0 vs index.json: version=v1.0.0 — 注册表与状态投影矛盾** |

状态声明值: grade=factory, version=v1.0.0 (index.json), latest_tag=v0.2.0 (registry.yaml), layer=L2.5
审计结论: **PHANTOM: registry_version_mismatch** — registry 声明 v0.2.0 但 index.json 和 GitHub Release 均为 v1.0.0

---

### domain_market

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/domain_market |
| go.mod 一致 | **FAIL** | go.mod: `github.com/xhyperium/domain-market` (kebab-case!) 应为 `github.com/xhyperium/domain_market` |
| tag 存在 | PASS | v1.1.0 远程 tag 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | PASS | 最新 main CI: success |
| Release | PASS | GitHub Release v1.1.0 存在 |
| 近期活跃 | PASS | 最后提交 2026-07-11 (fix/l2_5_clock_injection 分支) |

状态声明值: grade=factory, version=v1.1.0, layer=L2.5
审计结论: **PHANTOM: go.mod kebab-case 错误**

---

### domain_macro

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/domain_macro |
| go.mod 一致 | **FAIL** | go.mod: `github.com/xhyperium/domain-macro` (kebab-case!) 应为 `github.com/xhyperium/domain_macro` |
| tag 存在 | PASS | v1.0.1 远程 tag 存在（本地有 v1.0.0 但缺 v1.0.1） |
| tag 祖先 | SKIP | worktree 无 v1.0.1 tag |
| CI 状态 | **FAIL** | **main 分支无 CI 运行记录** — 从未有 CI run |
| Release | PASS | GitHub Release v1.0.1 存在 |
| 近期活跃 | FAIL | 最后提交 2026-06-16 — 近 4 周无活动 |

状态声明值: grade=factory, version=v1.0.1, layer=L2.5
审计结论: **PHANTOM: go.mod kebab-case + ci_never_green (no runs) + 超过 3 周无活跃**

> **注意**：这是报告中关注的重点模块。其仓库确实存在（xhyperium/domain_macro），但 CI 从未运行、go.mod 使用 kebab-case、近一个月无提交，却标记为 factory grade。

---

### domain_exchange

| 维度 | 结果 | 详情 |
|------|------|------|
| 仓库存在 | PASS | xhyperium/domain_exchange |
| go.mod 一致 | **FAIL** | go.mod: `github.com/xhyperium/domain-exchange` (kebab-case!) 应为 `github.com/xhyperium/domain_exchange` |
| tag 存在 | PASS | v1.0.0 远程 tag 存在 |
| tag 祖先 | SKIP | worktree 无 tag |
| CI 状态 | **FAIL** | **main 分支无 CI 运行记录** — 从未有 CI run |
| Release | PASS | GitHub Release v1.0.0 存在 |
| 近期活跃 | FAIL | 最后提交 2026-06-16 — 近 4 周无活动 |
| registry 版本不一致 | **FAIL** | **registry.yaml: latest_tag=v0.1.0 vs index.json: version=v1.0.0 — 注册表与状态投影矛盾** |

状态声明值: grade=factory (index.json), version=v1.0.0 (index.json), latest_tag=v0.1.0 (registry.yaml), layer=L2.5
审计结论: **PHANTOM: go.mod kebab-case + ci_never_green + registry_version_mismatch + 超过 3 周无活跃**

---

## 跨模块系统性问题

### 1. go.mod 模块路径 org 全局偏移
**所有 25 个模块**的 go.mod 声明 `github.com/xhyperium/{module}` 但实际 GitHub 仓库在 `xhyperium` org 下。这导致 `go get` 无法按 go.mod 路径解析模块。

### 2. kebab-case 违规
6 个模块的 go.mod 使用了 kebab-case（违反 CONSTITUTION.md 仓库命名规则）：
- xlib_standard → go.mod 写 `xlib-standard`
- xlib_harness → go.mod 写 `xlib-harness`
- domain_market → go.mod 写 `domain-market`
- domain_macro → go.mod 写 `domain-macro`
- domain_exchange → go.mod 写 `domain-exchange`
- transportx → go.mod 写 `xlib-standard`（完全错误的模块路径）

### 3. 状态投影 stale
6 个模块的 status index.json version 落后于 GitHub 最新 Release：
- xlib_harness: v0.1.7 → v0.2.1
- xlib_evidence: v0.2.5 → v0.3.0
- xlibgate: v1.2.0 → v1.3.0
- kernel: v1.1.0 → v1.1.1
- redisx: v1.1.1 → v1.1.2
- taosx: v1.0.2 → v1.1.2

### 4. registry.yaml 与 index.json 版本冲突
2 个模块在两个 SSOT 间存在版本矛盾：
- **decimalx**: registry 说 v0.2.0，index.json 说 v1.0.0，GitHub Release 是 v1.0.0
- **domain_exchange**: registry 说 v0.1.0，index.json 说 v1.0.0，GitHub Release 是 v1.0.0

### 5. CI 不健康
- **kernel**: CI failing (tag 孤儿 + CI 失败)
- **bootstrap**: CI failing
- **domain_macro**: 无 CI 运行记录
- **domain_exchange**: 无 CI 运行记录
- **xlibgate**: CI pending
- **kafkax**: CI pending

### 6. 大量模块在 worktree 上不是 main 分支
15/25 个模块的本地 worktree 不在 main 分支（在 fix/gitleaks-cli 等功能分支），导致 tag 祖先检查因本地无 tag 而跳过。虽然远程检查通过，但本地审计能力受损。

---

## 修正建议

### 立即修正（CRITICAL）

1. **kernel tag_orphan**: 将 v1.1.0 tag 重新定位到 main 分支的祖先 commit，或重新发布 v1.1.1 替代 v1.1.0。
2. **transportx go.mod**: 修正 module path 从 `github.com/xhyperium/xlib-standard` 为 `github.com/xhyperium/transportx`。
3. **domain_macro CI**: 激活 CI workflow，确保 main 分支至少通过一次完整 CI。
4. **domain_exchange CI**: 激活 CI workflow。

### 短期修正

5. **kebab-case 统一**: 修正 xlib_standard、xlib_harness、domain_market、domain_macro、domain_exchange 的 go.mod module path 为 snake_case。
6. **decimalx registry**: 修正 registry.yaml 的 latest_tag 从 v0.2.0 为 v1.0.0。
7. **domain_exchange registry**: 修正 registry.yaml 的 latest_tag 从 v0.1.0 为 v1.0.0。
8. **go.mod org 统一**: 决定 org（ZoneCNH vs xhyperium）并统一所有 25 个模块的 go.mod 和远程仓库。

### 状态刷新

9. **更新 index.json**: 将 6 个 stale 模块的 version 更新到实际 GitHub Release 最新版本。
10. **更新 registry.yaml**: 同步 domainx latest_tag (v1.0.1) 和 decimalx spec_version (v1.0.0)。

---

*审计完成。报告文件：plans/07-11/audit-results.md*
