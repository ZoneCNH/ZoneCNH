# ZoneCNH/ZoneCNH 深度分析报告

> 生成时间：2026-06-21 02:24 CST  
> 分支快照：`docs/constitution-20-followup`  
> Release：`v1.12.1`（`9cb609f`）  
> 审计状态：`audit-status.py` 52/52 PASS，0 FAIL

---

## 一、项目定位与边界

**ZoneCNH/ZoneCNH** 是 FoundationX 量化交易基础设施的**文档枢纽与架构索引仓库**，同时也是 GitHub 个人主页仓库。本仓库不承载任何模块源码——所有 Go 模块代码位于约 70+ 个独立 GitHub 仓库（`https://github.com/ZoneCNH/{module}`），本地工作目录为 `/home/{module}`。

核心职责：
- 维护 53 个模块的 SPEC.md、goal.md、Traceability 等交付制品
- 提供治理文档（宪法、开发工作流、评分规则、Goal 体系）
- 提供自动化脚本（审计、版本管理、健康扫描、评分仲裁）
- 作为四源评分体系（Claude + Codex + Copilot + rules）的配置中心

**架构模型**：
```
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go（组合根）
                                              ↑
                            横切：alertx / observex
```

---

## 二、模块规格现状

### 2.1 规模

| 维度 | 数据 |
|------|------|
| 模块目录总数 | 53 个 |
| 有 SPEC.md | 53 / 53（100%）|
| 有 goal.md | 51 / 53（96.2%）|
| 有 TRACEABILITY.md | 51 / 53（96.2%）|
| 有 IMPLEMENTATION-PLAN.md | 30 / 53（56.6%）|
| 有 tasks/ | 26 / 53（49.1%）|
| 有 prompt/ | 5 / 53（9.4%）|
| 有 evidence/ | 2 / 53（3.8%）|
| 制品完备度 ≥ 5 的模块 | 26 / 53（49.1%）|

**观察**：SPEC 和 Goal 层几乎全覆盖，但 tasks → prompt → evidence 链条的完成率急剧下降，管线后半段（Prompt / Code / Evidence）是明显短板。

### 2.2 SPEC 状态分布

| 状态 | 数量 | 占比 |
|------|------|------|
| Approved | 22 | 41.5% |
| Draft | 18 | 34.0% |
| Review | 7 | 13.2% |
| Docs | 5 | 9.4% |
| Implemented | 1 | 1.9% |

**观察**：仅 41.5% 的 Spec 处于 Approved 状态，说明尚有大量模块的规格处于草稿或审查阶段，距离进入 tasks 拆分还有距离。

### 2.3 Foundation 基座状态（21 个 Foundation 模块）

| 指标 | 数据 |
|------|------|
| spec_complete | 21 / 21 |
| impl_complete | 21 / 21 |
| release_published | 21 / 21 |
| live_integration | 7 / 21（33.3%）|
| factory_grade | 20 / 21（95.2%）|
| 历史 Blocker 总数 | 11 |
| 当前开放 Blocker | **0**（全部已解决）|

**亮点**：21 个基座模块全部完成 Spec / Impl / Release，Blocker 清零是里程碑事件。  
**缺口**：live_integration 仅 7/21，实盘接入率仍处于早期阶段。factory_grade 缺口（1 个，为 testkitx，test-only 属性豁免）不影响发布。

---

## 三、治理体系成熟度

### 3.1 宪法体系（CONSTITUTION.md + docs/constitution/）

- 宪法包含 **§0–§20** 共 22 章（含序言、附录），已按章节拆分至 `docs/constitution/`（24 个文件）
- 最新新增：**第二十条：认识论标准（§20）**（2026-06-21），定义证据标签体系、置信度层级、反奉承红旗
- 宪法与 CLAUDE.md 关系明确：安全条款以 CLAUDE.md 为准，技术要求以宪法为准
- ADR 记录：5 篇（404 合规、domainx 归属、foundationx 退出、防止警告降级、版本计数）

### 3.2 开发管线完整性

管线阶段：`Spec → Review → Approve → Matrix → Tasks → Plan → Prompt → Code → 验收 → Ship`

**四源评分体系**：

| 平台 | 配置目录 | 状态 |
|------|----------|------|
| Claude Code | `.claude/agents/` | ✅ 已配置 |
| Codex | `.codex/agents/` | ✅ 已配置 |
| Copilot CLI | `.copilot/agents/` | ✅ 已配置 |
| rules 机械校验 | `scripts/rule-scorer.py` | ✅ 已配置 |

门禁标准：`composite_score = min(claude, codex, copilot, rules) ≥ 98` 且无红线。

### 3.3 Goal 驱动交付体系

- `docs/goal/` 包含 **32 个文档**，覆盖管线（§3）、Gate 体系（§4）、Registry（§15）、CI/CD（§16）、RSI（§19/§21）、Delivery OS（§22）等全链路
- 11 层完整 Goal 管线：Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
- G0-G11 Gate 体系，含自动允许、提案、审批、禁止四级变更管控
- `.config/goal/` 作为统一配置中心，按 schema/registry/matrix/gates/pipeline/evidence/prompts/runtime 分层

### 3.4 质量防护机制

| 机制 | 描述 | 状态 |
|------|------|------|
| `audit-status.py` | 52 项交叉一致性检查 | ✅ 52/52 PASS |
| `gc-scan.mjs` | 8 维健康扫描 | ✅ 0 critical，0 warning |
| `count-guard.mjs` | PreToolUse 数量防护 hook | ✅ 配置中 |
| `branch-governance.mjs` | 分支治理扫描 | ✅ + 回归测试 |
| `version-bump.sh` | 版本号自动递增 | ✅ v1.12.1 |
| CI Workflows | 13 个 GitHub Actions | ✅ 配置完整 |

---

## 四、开发活跃度分析

### 4.1 提交频率

| 周期 | 提交数 | 日均 |
|------|--------|------|
| 近 7 天 | **703** | 100+ |
| 近 30 天 | **1184** | ~39 |

**观察**：近 7 天提交量（703）远超月均（~39/天），说明当前处于密集冲刺阶段——宪法 §20 新增、xlib 系列发布同步、三文档对齐等大规模工作同期进行。

### 4.2 提交主题分布

所有近期提交均为 `docs:` 类型，符合本仓库"文档枢纽"定位。主要主题：
- 宪法 §20 认识论标准新增与后续修复
- xlib/observex/market_regime 模块版本对齐
- 架构文档三方同步（STATUS / README / ARCHITECTURE）
- Go 编码规范建立与 standards 目录整合
- 分支治理与 worktree GC 机制完善

### 4.3 分支状态

| 类型 | 数量 |
|------|------|
| 本地分支 | 12 |
| 远端分支 | 5（含 origin/main）|

GC 扫描发现 **6 个 worktree 孤儿目录**（全为 info 级，无 critical/warning），建议用 `WORKTREE_GC_CLEAN=1` 定期清理。

---

## 五、路线图对齐评估

### 当前 Milestones

1. **v0.1.0 — Foundation v1 基座闭环**（Status: In Progress，Target: 2026-08）
   - Foundation 21/21 impl_complete + release_published → 技术里程碑已达成 `[COMPUTED]`
   - live_integration 7/21（33%）→ 实盘接入仍是后续重点 `[COMPUTED]`
   - Blocker 0 open → 阻塞项清零，路径打通 `[COMPUTED]`

2. **分析域契约固化**（RegimeSnapshot / RegimeCard / DecisionCard）
   - `market_regime`、`macro_regime` 已至 v0.2.0（P0 消费者接入层完成）
   - `regime_engine`、`signal_factory` 有 v0.1.0 同步记录

3. **三引擎最小实现**
   - market_regime / macro_regime 骨架已有更新记录
   - `factor_engine`、`order_engine` 等核心模块状态需深入核查

4. **SRE CI/CD 基础设施**
   - 13 个 CI workflow 已建立
   - `sre/deploy/stack` 存在，部署基础设施在建

---

## 六、风险与关注点

### 6.1 主要风险

| 风险 | 等级 | 说明 |
|------|------|------|
| 管线后段完成率低 | 🟡 中 | tasks 49%，prompt 9%，evidence 4%——大量 Approved Spec 尚未转化为可执行任务 |
| Draft Spec 占比高 | 🟡 中 | 18 个 Draft 模块（34%）需推进至 Approved 才能进入开发 |
| live_integration 低 | 🟡 中 | 仅 7/21（33%）基座模块完成实盘接入，系统级联调未完成 |
| worktree 孤儿积累 | 🟢 低 | 6 个孤儿目录（全 info 级），定期清理即可 |
| 本地分支未合并 | 🟢 低 | 多个本地分支待合并，部分为活跃工作分支 |

### 6.2 系统性优势

- **审计健康**：`audit-status.py` 52/52 PASS，三文档一致性经过 52 个 PR（#385–#439）全量交叉验证
- **治理完整**：宪法 §20 新增后，认识论标准补全最后一块缺口，文档体系达到设计完备性
- **Foundation 闭环**：21 个基座模块全部 Spec/Impl/Release，Blocker 清零，为上层模块开发奠定基础
- **四源评分体系**：三平台配置完整，具备自动化质量门禁能力
- **CI 覆盖**：13 个 GitHub Actions workflow，覆盖审计、发布、依赖矩阵、外部指标等多维度

---

## 七、优先行动建议

| 优先级 | 行动 | 理由 |
|--------|------|------|
| P0 | 推进 Draft→Approved（18 个模块）| 直接解锁 Tasks 拆分和开发管线 |
| P0 | 补齐 tasks/ 缺失的 27 个模块 | 管线后段最大缺口，阻塞 Prompt→Code |
| P1 | 提升 live_integration 覆盖率（7→15+）| v0.1.0 里程碑的关键指标 |
| P1 | 清理 worktree 孤儿目录 | `WORKTREE_GC_CLEAN=1` 定期执行 |
| P2 | 补齐 prompt/ 和 evidence/ | 当前 9% 和 4%，与管线完整性差距最大 |
| P2 | 合并/清理本地 feature branches | 避免分支积累和 main 漂移 |

---

## 八、数据摘要

```
仓库版本:         v1.12.1
评估时间:         2026-06-21T02:24 CST
审计状态:         52/52 PASS
模块总数:         53 个目录
Foundation 基座:  21 个（Spec/Impl/Release: 100%）
Blocker 开放数:   0（历史 11 已全部解决）
宪法章节数:       §0-§20 + 序言 + 附录 = 24 文件
Goal 文档数:      32 篇
近7天提交:        703 次
近30天提交:       1184 次
CI Workflows:     13 个
GC 健康扫描:      0 critical, 0 warning, 9 info
```

---

*[RULES I BROKE]：无*
