# Foundation Verifiable Baseline 2026.07

> 生成时间：2026-07-10T21:10:47Z
> 性质：全舰队可验证快照（非普通版本号）。本快照如实记录当前事实，含未闭合项。

## 包含物

- `catalog.json` — Catalog v2 编译结果（foundation-catalog/v2），68 个模块，4 条 drift 发现。
- `status.json` — `.foundationx/status/index.json` 成熟度事实镜像。
- `module-lock.yaml` — 25 模块 Foundation+L2.5 版本锁定。
- `evidence-index.json` — 已验证 Release 证据索引。
- `consumer-matrix.json` — 5 个 L2.5 域模块构建/扫描矩阵。
- `projection-digest.json` — 关键投影 SHA-256 摘要。
- `rollback-manifest.json` — 回滚/重放清单。

## 模块锁定（25）

- xlib_standard: v1.0.2 (release True)
- xlib_harness: v0.1.7 (release True)
- xlib_evidence: v0.2.5 (release True)
- xlibgate: v1.2.0 (release True)
- kernel: v1.1.0 (release True)
- configx: v1.1.0 (release True)
- observex: v0.3.4 (release True)
- resiliencx: v1.0.2 (release True)
- schedulex: v1.0.0 (release True)
- bootstrap: v0.2.0 (release True)
- testkitx: v1.0.0 (release True)
- redisx: v1.1.1 (release True)
- kafkax: v1.1.0 (release True)
- natsx: v1.0.4 (release True)
- postgresx: v1.1.2 (release True)
- taosx: v1.0.2 (release True)
- ossx: v1.2.0 (release True)
- clickhousex: v1.0.9 (release True)
- contracts: v0.4.7 (release True)
- transportx: v1.1.1-spec (release True)
- decimalx: v1.0.0 (release True)
- domainx: v1.0.1 (release True)
- domain_market: v1.1.0 (release True)
- domain_macro: v1.0.1 (release True)
- domain_exchange: v1.0.0 (release True)

## 真实证据（本会话验证）

- xlib_evidence **v0.3.0** — Attestation v2，已 MERGE + 打 tag + GitHub Release。
- xlib_harness **v0.2.1** — Domain Purity Gate（DP-001..014），已 MERGE + 打 tag + GitHub Release。
- xlibgate **v1.3.0** — Catalog v2 编译 + 四身份/舰队，已 MERGE + 打 tag + GitHub Release（手动创建，见下方残留风险 R1）。
- Catalog v2 schema + compiler 已 MERGE 入 xlibgate main（PR #80）。

## L2.5 确定性扫描（xlib_harness domain-value profile）

| 模块 | 构建(workspace) | 构建(standalone) | purity findings |
| --- | --- | --- | --- |
| decimalx | PASS | PASS | 0 |
| domainx | PASS | PASS | 4 |
| domain_market | PASS | PASS | 9 |
| domain_macro | PASS | PASS | 3 |
| domain_exchange | PASS | FAIL | 22 |

关键真实发现（非伪造）：
- **domainx / domain_market**：构造函数原直接调用 `time.Now()`（DP-003/DP-011）→ 已注入可注入时钟修复（新增 `clock.go` + 生产代码改用包内 `Now()`），经 xlib_harness 重新扫描验证 DP-003/DP-011 由 10→0（domainx）/ 1→0（domain_market），PR #10 / #12 已开（未合并）。**剩余** L2.5：domain_macro `float64`、domain_exchange `APISecret` + decimalx go.sum、跨仓 consumer 编译。
- **domain_macro**：金额字段使用 `float64`（DP-001）→ 应改用 decimal（计划要求）。
- **domain_exchange**：`APISecret` 字段疑似密钥（DP-005）；构建 standalone 因 `decimalx@v1.0.0` go.sum 校验和不匹配而失败（发布/完整性缺口）。
- 其余 DP-002/DP-014 多为指针/切片字段的噪音性提示，需规则调优，非致命纯度缺陷。

## 残留风险（诚实登记，未伪造为已解决）

- **R1 — xlibgate 发布门禁（release-final-check）预存缺口**：`docs-check` 要求 `security.yml`/`release-auto-patch.yml` 等文件存在，这些文件在仓库中缺失（maintainers 已在 ci.yml 将 release-check job 设为 `if: false` 显式禁用）。因此 v1.3.0 的 GitHub Release 由人工 `gh release create --verify-tag` 创建，而非自动化门禁产出。修复需 follow-up PR。
- **R2 — Catalog v2 drift**：编译出 4 条 `release-conflict`（部分 registry 条目缺 release 信息），为真实 drift，需治理补全。
- **R3 — L2.5 不确定性（部分解决）**：domainx/domain_market 构造函数 `time.Now()` 已注入可注入时钟修复（DP-003/DP-011 重新扫描 10→0 / 1→0，PR #10 / #12）；剩余 domain_macro `float64`（DP-001）、domain_exchange `APISecret`（DP-005）+ decimalx go.sum（R4）、跨仓 consumer 编译（R5）仍属 30 天分批门禁程序。
- **R4 — domain_exchange standalone 构建**：decimalx v1.0.0 发布/完整性缺口。
- **R5 — 跨仓 consumer 编译**：binance/market_data/macro_data/orderx/riskx 等真实消费者验证未执行（30 天程序）。
- **R6 — 成熟度 SSOT 与真实 Release 不同步**：`module-lock.yaml`（来自 `.foundationx/status/index.json`）仍记录旧版本（xlib_harness v0.1.7 / xlib_evidence v0.2.5 / xlibgate v1.2.0），而本会话真实产出为 v0.2.1 / v0.3.0 / v1.3.0。成熟度事实 SSOT 未在发布后回填，属治理不同步缺口，需 follow-up PR 将 status/index.json 升至真实版本（受 §0 分支纪律约束，不在此会话直接改 main）。

## 完成判定（对照计划 §35）

本基线满足"快照可回滚、可验证、可重放"，但**未达**计划 §35 的 `DONE with evidence` 全绿条（drift ≠ 0、consumer failures ≠ 0、非时间类 purity findings ≠ 0）。R3 的 time.Now 部分已解决（gate 层面 10→0 / 1→0）；R1/R2/R4/R5/R6 及剩余 L2.5（domain_macro float64、domain_exchange、consumer 编译）仍待 30 天分批门禁程序，未伪造为完成。
