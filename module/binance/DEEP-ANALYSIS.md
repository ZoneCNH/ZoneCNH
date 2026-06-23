> [ARCHIVED 2026-06-22] 本文档为 v2.0.0 重构前的深度分析（2026-06-21），已被 SPEC v3.5.0 + TRACEABILITY v3.5.0 覆盖。
>
> **本文档现在是归档索引**。原始内容已按主题拆分为 3 个归档文件。

# module/binance 深度架构分析（归档索引）

> 分析日期：2026-06-21
> 分析范围：当前 SPEC v1.0.1 + 实际代码状态 → 目标全栈架构（redisx + kafkax + natsx + postgresx + taosx + ossx + Gin）
> 状态：**已归档** — 分布式约束与代码实态审计已迁移为指针，剩余内容拆分为专题归档文件。

---

## 内容迁移映射

| 原始章节 | 迁移目标 | 状态 |
|---------|---------|:---:|
| §0 分布式架构约束 | `module/binance/SPEC.md` §4.1 Runtime Distributed Architecture Constraints | ✅ 已迁移 |
| §1-§2 架构评估与目标设计 + 附录A | [`DEEP-ANALYSIS-ARCHIVE-architecture.md`](./DEEP-ANALYSIS-ARCHIVE-architecture.md) | 📦 归档 |
| §3 六模块集成详案 | [`DEEP-ANALYSIS-ARCHIVE-integration.md`](./DEEP-ANALYSIS-ARCHIVE-integration.md) | 📦 归档 |
| §4-§11 API/数据流/配置/部署/路线图/风险 + 附录B | [`DEEP-ANALYSIS-ARCHIVE-operations.md`](./DEEP-ANALYSIS-ARCHIVE-operations.md) | 📦 归档 |
| §12 当前代码实态审计 | `docs/migrations/binance-v2-upgrade.md` | ✅ 已迁移 |

---

## 活跃文档入口

- **规格（权威 SSOT）**：`module/binance/SPEC.md` v3.5.0
- **追溯矩阵**：`module/binance/TRACEABILITY.md` v3.5.0
- **分布式约束**：`module/binance/SPEC.md` §4.1
- **Runtime 映射**：`module/binance/RUNTIME-MAPPING.md`
- **边界门禁**：`module/binance/BOUNDARY-GATES.md`
- **治理规则**：`module/binance/RULES.md`
- **数据生命周期**：`module/binance/DATA-LIFECYCLE.md`
- **迁移记录**：`docs/migrations/binance-v2-upgrade.md`、`docs/migrations/remove-binance-market.md`
- **治理归档报告**：`docs/report/binance/INDEX.md`

---

## GateGuard / Branch Governance 已知边界

以下为 2026-06-22 深度分析修复过程中遇到的开发流程边界情况，已文档化：

| # | 场景 | 影响 | 缓解 |
|---|------|------|------|
| G1 | **Fact-Forcing Gate 拦截文档批量修复**：Edit 工具在 GateGuard 活跃时可能因误判回滚合法变更。 | 同类 session 反复 Edit/回滚/重试，消耗 token。 | 纯文档修复场景建议评估 `ECC_GATEGUARD=off`；二进制/合约变更保持 GateGuard on。 |
| G2 | **Auto-stash 打断工作流**：OMC 自动切换分支时的 stash 可能导致 restore 顺序错乱。 | 需额外 backup → restore 步骤。 | auto-stash TTL 3 天；`git stash list` 定期清理；Workspace GC 在 SessionStart 自动扫描。 |
| G3 | **Branch governance 自动切 main**：Stop hook 自动切回 main 可能丢失未提交改动。 | 工作区改动未 save 时可能丢代码。 | 分支保护规则禁止未合并删除；SessionEnd 验证 `git log origin/main..HEAD --oneline`。 |

以上边界不影响 `module/binance` 的模块规格治理。GateGuard 配置属于仓库 OMC harness 层，详见 `CLAUDE.md` → "分支纪律" 与 "工作区 GC" 章节。

[COMPUTED, HIGH] 当前 branch-governance 已知边界：Stop hook 切 main 前验证未合并提交、`WORKTREE_GC_CLEAN=1` 跳过 dirty worktree、僵尸 worktree 仅告警不自动清理。纯文档 batch-edit 场景未触发过数据丢失。
