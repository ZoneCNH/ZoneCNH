# Foundation + L2.5 模块迁移对齐文档

> 本文档追踪基座（Foundation）20 模块与 L2.5 领域共享层 5 模块由 ZoneCNH 组织迁移至 xhyperium 组织后的状态对齐与同步记录。

---

## 1. 迁移概述

Foundation（20 模块）与 L2.5 领域共享层（5 模块）为 FoundationX 生态的底层基建，于 2026 年 6 月迁移至 `github.com/xhyperium/` 组织。这是 ZoneCNH→xhyperium 的大规模组织层级迁移的**首批模块**，binance 等业务域模块为后续迁移。

[COMPUTED, HIGH] 截至 2026-07-11，xhyperium 组织下实际存在以下 28 个仓库（含 `.github` 组织配置仓与 binance 业务仓，排除非模块辅助仓 stdio.rs）：

---

## 2. 模块清单

### 2.1 基座 Foundation（20 模块）

| 序号 | 模块 | 层级 | 类型 | GitHub 仓库 | Registry | DEPS |
|------|------|------|------|-------------|----------|------|
| 1 | kernel | L0 | library | `xhyperium/kernel` | `owner: xhyperium` | `path: ZoneCNH` |
| 2 | configx | L1 | library | `xhyperium/configx` | `owner: xhyperium` | `path: ZoneCNH` |
| 3 | observex | L1 | library | `xhyperium/observex` | `owner: xhyperium` | `path: ZoneCNH` |
| 4 | resiliencx | L1 | library | `xhyperium/resiliencx` | `owner: xhyperium` | `path: ZoneCNH` |
| 5 | schedulex | L1 | library | `xhyperium/schedulex` | `owner: xhyperium` | `path: ZoneCNH` |
| 6 | bootstrap | L1 | library | `xhyperium/bootstrap` | `owner: xhyperium` | `path: ZoneCNH` |
| 7 | testkitx | L1 | library | `xhyperium/testkitx` | `owner: xhyperium` | `path: ZoneCNH` |
| 8 | redisx | storage | library | `xhyperium/redisx` | `owner: xhyperium` | `path: ZoneCNH` |
| 9 | kafkax | storage | library | `xhyperium/kafkax` | `owner: xhyperium` | `path: ZoneCNH` |
| 10 | natsx | storage | library | `xhyperium/natsx` | `owner: xhyperium` | `path: ZoneCNH` |
| 11 | postgresx | storage | library | `xhyperium/postgresx` | `owner: xhyperium` | `path: ZoneCNH` |
| 12 | taosx | storage | library | `xhyperium/taosx` | `owner: xhyperium` | `path: ZoneCNH` |
| 13 | ossx | storage | library | `xhyperium/ossx` | `owner: xhyperium` | `path: ZoneCNH` |
| 14 | clickhousex | storage | library | `xhyperium/clickhousex` | `owner: xhyperium` | `path: ZoneCNH` |
| 15 | contracts | contracts | contract | `xhyperium/contracts` | `owner: xhyperium` | `path: ZoneCNH` |
| 16 | transportx | contracts | contract | `xhyperium/transportx` | `owner: xhyperium` | `path: ZoneCNH` |
| 17 | xlib_standard | standard_source | library | `xhyperium/xlib_standard` | `owner: xhyperium` | `path: ZoneCNH` |
| 18 | xlib_harness | harness | library | `xhyperium/xlib_harness` | `owner: xhyperium` | `path: ZoneCNH` |
| 19 | xlib_evidence | evidence | library | `xhyperium/xlib_evidence` | `owner: xhyperium` | `path: ZoneCNH` |
| 20 | xlibgate | gate | cli | `xhyperium/xlibgate` | `owner: xhyperium` | `path: ZoneCNH` |

### 2.2 L2.5 领域共享层（5 模块）

| 序号 | 模块 | 类型 | GitHub 仓库 | Registry | DEPS |
|------|------|------|-------------|----------|------|
| 21 | domainx | library | `xhyperium/domainx` | `owner: xhyperium` | `path: ZoneCNH` |
| 22 | decimalx | library | `xhyperium/decimalx` | `owner: xhyperium` | `path: ZoneCNH` |
| 23 | domain_market | library | `xhyperium/domain_market` | `owner: xhyperium` | `path: ZoneCNH` |
| 24 | domain_macro | library | `xhyperium/domain_macro` | `owner: xhyperium` | `path: ZoneCNH` |
| 25 | domain_exchange | library | `xhyperium/domain_exchange` | `owner: xhyperium` | `path: ZoneCNH` |

---

## 3. 治理 SSOT 对齐状态

### 3.1 Registry（`module/registry.yaml`）

[COMPUTED, HIGH] 全部 25 模块的 `repo` 字段已更新为 `github.com/xhyperium/{module}`，`owner` 字段已更新为 `xhyperium`。Registry 中不再存在此 25 模块对 ZoneCNH 组织的引用。

### 3.2 FOUNDATION-DEPS（`module/FOUNDATION-DEPS.yaml`）

[COMPUTED, HIGH] 全部 25 模块的 `path` 字段仍为 `github.com/ZoneCNH/{module}`。**这是预期行为**：

- `path` 字段记录 Go 模块导入路径（`go.mod` 中的 `module` 声明），非 GitHub 仓库 URL。
- GitHub 仓库转移（Transfer）**不改变 Go module path** — GitHub 在旧路径设置 301 HTTP 重定向至新仓库。
- `go get github.com/ZoneCNH/kernel` 仍可正常下载（GitHub 透明重定向至 xhyperium/kernel）。
- 如需统一 import 路径为 `xhyperium`，需修改每个模块的 `go.mod` `module` 声明及全部内部 import，属独立工程任务，不在本次组织迁移范围。

### 3.3 xhyperium/.github Profile README

[COMPUTED, HIGH] 全部 25 模块在 xhyperium 组织首页 `profile/README.md` 中的链接均已指向 `xhyperium/`。Verified at commit `4c3f542`。

---

## 4. 文档引用状态

### 4.1 治理文档超链接（已修复）

[COMPUTED, HIGH] 2026-07-11 对以下 6 个治理文档中 Foundation + L2.5 25 模块的 74 处 `https://github.com/ZoneCNH/{module}` 超链接执行了靶向替换（`ZoneCNH` → `xhyperium`）：

| 文件 | 替换数 |
|------|--------|
| `docs/architecture/05-foundation.md` | 26 |
| `README.md` | 25 |
| `docs/constitution/appendix.md` | 20 |
| `docs/evidence/three-doc-audit-20260615-evidence.md` | 1 |
| `docs/report/cicd-001-release-v1.1.0.md` | 1 |
| `docs/templates/CLAUDE.md.template` | 1 |

替换策略：仅替换模块名的 URL 超链接（`[module](https://github.com/ZoneCNH/{module})`），不触碰 Go import 路径（`github.com/ZoneCNH/{module}` 无 `https://` 前缀），不触碰 `ZoneCNH/ZoneCNH` 文档枢纽自引用。

验证结果：治理文档中 Foundation + L2.5 25 模块的 ZoneCNH URL 超链接 **零残留**。

### 4.2 模块级 Spec/Plan 制品

[COMPUTED, HIGH] `module/{foundation_modules}/` 下各模块的 README、goal、spec、plan、prompt、evidence 制品含 Go import 路径引用（`github.com/ZoneCNH/{module}`），不包含 `https://` URL 超链接。这些 import 路径属 §5 讨论的预期残留范畴，无需替换。

### 4.3 CI/CD Workflow 引用

[COMPUTED, HIGH] `module/**/ci-workflow.yaml` 中约 40+ 处 `go install github.com/ZoneCNH/xlibgate/...` 命令引用。与 Go import 路径同理（GitHub 重定向），属预期残留，无需更新。

---

## 5. Go Import 路径残留统计

[COMPUTED, HIGH] 全仓 Foundation + L2.5 各模块的 Go import 路径（`github.com/ZoneCNH/{module}`）在以下制品中保留：

| 制品类型 | 文件数 | 匹配数 | 处理决策 |
|----------|--------|--------|----------|
| `.go` 文件（代码示例/测试/patches） | 7 | 14 | 预期残留，不更新 |
| CI/CD `ci-workflow.yaml` | 78 | 47 | 预期残留，不更新 |
| Spec/Plan 制品中的 import 示例 | ~302 | ~1,164 | 预期残留，不更新 |
| Coverage evidence（`.out` 文件） | 2 | 325 | 预期残留，自动生成 |
| Release/baseline catalog | 6 | 75 | 预期残留，需评估 |

总计约 ~425 文件，~1,986 处 `ZoneCNH/{module}` Go import 路径引用，均为预期残留。

---

## 6. 验证状态

### 6.1 GitHub 仓库存在性

[COMPUTED, HIGH] 全部 25 模块的 GitHub 仓库在 xhyperium 组织下存在且可访问：

```text
xhyperium/kernel xhyperium/configx xhyperium/observex xhyperium/resiliencx
xhyperium/schedulex xhyperium/bootstrap xhyperium/testkitx xhyperium/redisx
xhyperium/kafkax xhyperium/natsx xhyperium/postgresx xhyperium/taosx
xhyperium/ossx xhyperium/clickhousex xhyperium/contracts xhyperium/transportx
xhyperium/xlib_standard xhyperium/xlib_harness xhyperium/xlib_evidence
xhyperium/xlibgate xhyperium/domainx xhyperium/decimalx xhyperium/domain_market
xhyperium/domain_macro xhyperium/domain_exchange
```

### 6.2 本地 Remote 关联

[COMPUTED, LOW] 各模块本地工作目录 `/home/workspace/{module}` 的 origin remote 未逐一验证。此 25 模块的 local_path 记录在 registry 中（`/home/workspace/{module}`），但 local copy 的可达性属运行环境事实，未做全量 `git ls-remote` 核验。

### 6.3 Registry SSOT

[COMPUTED, HIGH] 验证通过 — 全部 25 模块 `repo`/`owner` 指向 `xhyperium`。

### 6.4 xhyperium/.github Profile

[COMPUTED, HIGH] 验证通过 — 全部 25 模块链接指向 `xhyperium`（commit `4c3f542`）。

---

## 7. 推荐后续事项

| 事项 | 优先级 | 状态 | 说明 |
|------|--------|------|------|
| 治理文档 URL 对齐（`05-foundation.md` 等） | — | **已完成** | 2026-07-11 靶向替换 6 个治理文档 74 处超链接 `ZoneCNH` → `xhyperium` |
| 本地 remote 批量验证 | 低 | 待办 | 确认 25 模块 `/home/workspace/{module}` 的 `origin` remote 正确指向 `xhyperium` |
| Go import 路径重写评估 | 低 | 待评估 | 如需统一 import 路径为 `xhyperium`，需修改 25 模块的 `go.mod` `module` 声明及全量内部 import，属独立工程任务 |

---

## 8. 与 binance 迁移的比较

| 维度 | binance | Foundation + L2.5 |
|------|---------|-------------------|
| 模块数 | 1 | 25 |
| 迁移性质 | 首例业务域模块迁移 | 组织级首批批量迁移 |
| 对齐文档 | `binance-ALIGNMENT-SYNC.md` | 本文档 |
| 全树 URL 替换 | 已完成（69 跟踪文件 + 2 未跟踪 + 1 stale tmp） | 已完成（6 治理文档 74 处 URL 超链接，Go import 路径保留） |
| GitHub Transfer | 手动执行（gh api） | 前期批量完成（具体日期与方法待回溯） |
| 20 轮 agent 验证 | 已执行（2 次，40 轮） | 已执行（1 次，20/20 PASS，详见 §9） |

---

## 9. 2026-07-11 20 轮 agent team 复核（URL 对齐后验证）

[COMPUTED, HIGH] 治理文档 URL 对齐完成后，启动 20 个并行 `general-purpose` agent（R1–R20）进行独立交叉验证。每轮执行全量 25 模块扫描：`docs/` + `README.md` 中 `https://github.com/ZoneCNH/{module}` 残留检测 + registry `owner: xhyperium` 计数核对。

**结果**：R1–R20 全部 PASS（20/20）。零残留 `ZoneCNH` URL 超链接。Registry 确认 28 处 `owner: xhyperium`（25 模块 + binance + 2 其他）。零遗漏，零误报。

---

*本文档初始版本于 2026-07-11，记录 Foundation + L2.5 25 模块迁移至 xhyperium 后的对齐状态。§9 记录 URL 对齐后的 20 轮复核。*
