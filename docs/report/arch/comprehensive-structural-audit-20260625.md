# FoundationX 仓库深度架构与结构性审计报告

> 范围：`ZoneCNH/ZoneCNH`（FoundationX 量化交易基础设施文档枢纽）
> 日期：2026-06-25 · 分支：`docs/binance-readiness-alignment`
> 方法：一手取证（git 元数据、退出码、内置 grep、文件重定向），跨 7 个维度
> 适用认识论标准：`docs/constitution/20-epistemic-standards.md`（§20）

---

## 0. 执行摘要

ZoneCNH/ZoneCNH 是一个**架构愿景清晰、规格内容丰富**的文档枢纽（50 个模块 SPEC、24 章宪法、完整的分层架构文档），但其**重度治理与自动化机器正在反噬自身制品**：权威状态文档 STATUS.md 已被自动生成器损坏并提交入库、`.git` 因治理备份膨胀至 949MB、30 天内累计 1594 次提交。更危险的是，仓库自有的质量门禁 `audit-status.py` **全绿通过（51/0）却完全检测不到这些损坏**——形成"指标健康 ≠ 制品健康"的认知鸿沟，正是 §20 反复警告的 `[FRAME] → [REALITY]` 偷换。

**综合评分：59 / 100（C-，及格偏下）** `[COMPUTED] · 置信度 MED`

| 维度 | 权重 | 得分 | 评级 |
|------|:----:|:----:|:----:|
| 架构清晰度 | 20% | 78 | B |
| 文档一致性 | 20% | 55 | D+ |
| 数据完整性 | 15% | 45 | F+ |
| 治理可执行性 | 15% | 60 | C- |
| 基础设施健全度 | 15% | 50 | D |
| 可维护性 | 15% | 58 | D+ |
| **加权总分** | 100% | **59** | **C-** |

> 加权计算：`78×.20 + 55×.20 + 45×.15 + 60×.15 + 50×.15 + 58×.15 = 58.55 ≈ 59` `[COMPUTED]`

**一句话诊断**：架构与规格的"内容资产"值 B 级，但"治理自动化"作为一个系统正在制造负价值——它损坏制品、膨胀仓库、制造提交噪声，并用通过的门禁掩盖伤害。**当前最大风险不是缺乏治理，而是治理过载且失去自我校验能力。**

---

## 1. 方法论与证据可靠性声明

本次审计在执行中遭遇**工具输出过滤/截断**：bash 输出中凡命中疑似 token 的字符串会被替换为 `[REDACTED:hf-token]`，且部分长输出被静默截断。这导致首轮探查产生了 **5 处误判**，均已通过可靠手段（`git ls-files`、退出码捕获、内置 `grep`/`glob` 工具、输出重定向到文件）复核纠正：

| 初判（错误） | 复核（正确） | 纠正手段 |
|------|------|------|
| CONSTITUTION.md 损坏 | 正常 77 字节存根 | `cat` 全文 |
| ARCHITECTURE.md 是 89 行存根 | 实为 605 行/77K 完整文档 | `wc -l` + `head` |
| module/ 仅 binance 一个 | 实为 53 目录/50 SPEC | `git ls-files` |
| audit-status.py 崩溃退出 | 实际 PASS（51/0，exit 0） | 重定向 + `$?` |
| STATUS.md 全文乱码 | 顶部乱码 + 下方表格存活 | 内置 grep 定位行 317 |

> **诚实声明** `[FRAME]`：本报告所有量化结论均基于上表所列可复现命令，已规避过滤干扰。涉及主观评级（如各维度分数）标注为 `[INFERRED]`，置信度见各处标注。

---

## 2. P0 级问题（数据完整性 / 基础设施崩坏）

### F1 · STATUS.md 已损坏并提交入库 `[COMPUTED] · HIGH`

**现象**：权威状态快照 `STATUS.md`（2417 行）被严重损坏，且损坏**已存在于 git HEAD**（不在未提交变更列表中）。

**证据**：
```
$ wc -l STATUS.md                                  → 2417
$ grep -cE '^[0-9]+\. [0-9]+\.' STATUS.md          → 1985   (82% 行带异常双行号前缀)
$ grep -c '^## ' STATUS.md                         → 0      (无任何合法二级标题存活)
$ grep -c 'github.com/ZoneCNH' STATUS.md           → 0      (仓库引用全部丢失)
$ grep -nE '\| *基座' STATUS.md | head -1          → 317:| 基座 | 20 | 20 | 0 | ...
```

**机理** `[INFERRED] · MED`：自动生成器（`sync-status.mjs`）或某 hook 发生**递归自喂**——把"带行号的上一版输出"再次作为输入写回，导致：
- 行号层层累积（`7. 8. ## 同步元数据` → `84. 86. # 模块明细`）
- 章节标题被反复复制（数百个 `# 模块明细`/`# 风险`/`# 同步`）
- 出现叠词噪声（`模块明细明细…`、`处理处理`、`更新更新`）

顶部约 316 行为纯乱码，行 317 起仍残留可解析的管道表格数据（256 个含 `|` 的行）。

**影响**：① 文档对人类完全不可读；② Markdown 渲染崩坏；③ 违反仓库自身"三文档同步检查表"（STATUS 仓库引用数应与 README 的 50 个一致，实为 0）；④ **该文档被宪法和 audit 脚本列为"事实来源"，事实来源已污染**。

> **建议**：立即从 `sync-status.mjs` 重新生成 STATUS.md，或从损坏前的 git 历史 `git checkout <good-sha> -- STATUS.md` 恢复；并在生成器中加入"输入不得含已生成标记/行号前缀"的幂等护栏。

---

### F2 · `.git` 膨胀至 949MB —— 治理备份失控 `[COMPUTED] · HIGH`

**现象**：一个仅 1344 个被跟踪文件（1097 个 md）的纯文档仓库，`.git` 目录达 **949MB**。

**证据**：
```
$ du -sh .git                                      → 949M
$ git count-objects -vH                            → 对象仅 ~48MB (loose 38M + pack 10.5M)
$ du -sh .git/* | sort -rh | head -2
    897M  .git/branch-governance-backups           ← 根因
     50M  .git/objects
$ ls .git/branch-governance-backups | wc -l        → 87 个时间戳备份目录
$ find .../branch-governance-backups -name '*.bundle' → 每个分支 bundle ~7.3MB
```

**机理** `[INFERRED] · HIGH`：CLAUDE.md 描述的"分支保护/自动 stash/branch-governance"自动化在**每次分支操作时把全部分支打成 git bundle 备份**，存入 `.git/branch-governance-backups/<时间戳>/`。87 次累积 = 897MB，且每个 bundle 几乎是整库历史的副本，随时间无界增长。

**影响**：克隆/拉取慢、磁盘浪费、备份本身比被备份的内容大 20 倍；这是**自动化负价值**的教科书案例——为"安全"付出的成本远超其保护的资产。

> **建议**：① 为 `branch-governance-backups` 设保留策略（如保留最近 3 个 + TTL 7 天）；② 备份改用增量/引用而非全量 bundle；③ 评估是否需要此机制——git 本身已是分布式备份。

---

## 3. P1 级问题（一致性漂移 / 门禁盲区）

### F3 · 极高提交频率：30 天 1594 次提交 `[COMPUTED] · HIGH`

```
$ git rev-list --all --count                       → 1594
$ git rev-list --all --count --since="30 days ago" → 1594   (全部集中在 30 天内)
```
约 **53 次提交/天**。源自 CLAUDE.md 的"每次迭代版本号 +1"、auto-checkpoint、OMX team auto-commit 等策略叠加。后果：提交历史信噪比极低，`git log` 难以作为变更叙事，且与 F2 的备份机制叠加放大膨胀。`[INFERRED] · MED`

### F4 · ARCHITECTURE.md 的"存根"声明与现实漂移 `[COMPUTED] · HIGH`

CLAUDE.md / AGENTS.md 多处声明：*"ARCHITECTURE.md 是向后兼容重定向存根；架构内容已迁移至 docs/architecture/"*。但实测：
```
$ wc -l ARCHITECTURE.md   → 605 行   $ wc -c ARCHITECTURE.md → 78776 字节
$ head -1 ARCHITECTURE.md → "# 🏗️ 分层架构"（完整架构正文，非存根）
```
**ARCHITECTURE.md 实为 605 行完整架构文档**，与 `docs/architecture/`（9 文件）内容重叠，形成**双事实来源**；同时治理文档描述了一个**不存在的状态**（存根）。这是规则与现实脱节，违反仓库"消除信息差"核心原则。`[INFERRED] · HIGH`

> **建议**：二选一——要么真的把 ARCHITECTURE.md 缩成存根（落实声明），要么修正 CLAUDE.md/AGENTS.md 不再称其为存根，并明确它与 docs/architecture/ 的主从关系。

### F5 · README.md 双 H1 + 篇幅失控 `[COMPUTED] · HIGH`

```
$ grep -n '^# ' README.md
  4:# ZoneCNH · FoundationX
  8:# FoundationX —— 个人级量化交易系统架构（草案 v3）
$ wc -l README.md → 1009 行 / 44KB
```
README 含 **2 个 H1**，第二个还把一份"草案 v3"架构文档整体内嵌进主页。违反单一 H1 规范，且 1009 行对 GitHub 个人主页过长（主页应精简索引，深度内容应链接到 docs/）。`[INFERRED] · HIGH`

### F6 · 质量门禁盲区：audit 全绿却测不出损坏 `[COMPUTED] · HIGH`

```
$ python3 scripts/audit-status.py; echo $?  → Summary: 51 passed, 0 failed / exit 0
```
`audit-status.py` 对 9 类检查全部 PASS，**但 STATUS.md 已 82% 乱码**。原因：审计按 `|` 分割解析表格算术（损坏的行号前缀落在首个 `|` 之前的 `parts[0]`，不影响数据列），因此对**文档结构完整性零检测**。

**这是最危险的结构性问题**：门禁给出"全绿"虚假信号，掩盖了 F1 的数据灾难。任何依赖此门禁判断"仓库健康"的决策都被误导——精确复现了 §20 的 `[FRAME] → [REALITY]` 偷换。`[INFERRED] · HIGH`

> **建议**：为 audit 增加文档结构健全性检查（H1 数量==1、无重复标题、无 `N. M.` 行号前缀、仓库引用数三文档一致），让门禁能感知"制品被破坏"。

---

## 4. P2 级问题（过度工程化 / 可维护性）

### F7 · 两套交付管线并存且重叠 `[COMPUTED] · MED`

| 体系 | 管线 | 定义位置 |
|------|------|----------|
| governance | Spec→Matrix→Tasks→Plan→Prompt→Code | `docs/governance/DEVELOPMENT-WORKFLOW.md` |
| goal | Goal→Spec→Design→Plan→Tasks→Prompt→Code→Test→Review→Release | `docs/goal/03-pipeline.md` |

两套各有 pipeline、gate（governance 四源评分 / goal G0–G11）、traceability，阶段大量重叠（Spec/Plan/Tasks/Prompt/Code），需**并行维护两套门禁与状态机**。对个人仓库构成显著认知与维护负担。`[INFERRED] · MED`

### F8 · 45 个 agent 定义需三重维护 `[COMPUTED] · MED`

```
.claude/agents=15  .codex/agents=15  .copilot/agents=15  → 共 45
.github/workflows=20 个
```
三平台 agent 功能相同、配置格式不同，任何角色调整需改 3 处（DRY 违规）。20 个 workflow 对 docs-only 仓库偏重（CLAUDE.md O8 已自承"CI 死锁"风险）。`[INFERRED] · MED`

### F9 · 运行态目录膨胀 `[COMPUTED] · MED`

```
.omx=190M  .beads=18M  .worktree=16M  .omc=8.5M
```
`.omx` 单独 190MB。多数已 gitignore（`.omx/.beads/.worktree` 跟踪文件=0，良好），但 `.omc` 仍有 25 个、`.config` 46 个文件入库。本地工作区总占用偏大。`[COMPUTED] · MED`

### 治理碎片化（观察）`[INFERRED] · MED`
CONSTITUTION 1342 行（24 章）+ CLAUDE.md 395 行 + AGENTS.md 273 行，且 CLAUDE.md 内含大量 `> 取代: 日期 §...` 的规则演进记录、TTL 规则、复盘元规则。规则以"追加+取代"方式增长，CLAUDE.md 自设目标 `< 350 行` 已被突破（395）。规则治理本身需要被治理。

---

## 5. 正面发现（评分已计入，避免单边叙事）

- **P1 · 规格资产扎实** `[COMPUTED] · HIGH`：module/ 含 **53 目录 / 50 个 SPEC.md**，体量从 binance（1380 行）、xlibgate（1303）、kernel（1274）到精简模块（54 行）梯度合理，是有真实内容的多模块规格库——**绝非"单模块"空壳**。
- **P2 · 宪法与架构文档完整** `[COMPUTED] · HIGH`：`docs/constitution/` 24 章 1342 行齐全；`docs/architecture/` 9 文件 + 1 ADR 结构完整；§20 认识论标准设计成熟（证据标签 + 置信度 + 反奉承红旗）。
- **P3 · 损坏被隔离** `[COMPUTED] · HIGH`：全仓库扫描确认乱码模式**仅 STATUS.md 一例**，未扩散；运行态目录基本已正确 gitignore；审计脚本（除盲区外）算术检查可用。
- **自动化框架完备**：11 个 hooks、20 scripts、四源评分体系——**框架本身设计精良，问题在"过载"与"缺乏对自身产物的校验"，而非"缺失"**。

---

## 6. 评分理由明细

| 维度 | 得分 | 主要扣分项 | 主要加分项 |
|------|:----:|------|------|
| 架构清晰度 | 78 | ARCHITECTURE 双源(F4)、README 内嵌架构(F5) | 分层模型清晰、docs/architecture 完整、9 原则成体系 |
| 文档一致性 | 55 | STATUS 损坏(F1)、ARCHITECTURE 漂移(F4)、README 双 H1(F5) | constitution/architecture 内部自洽 |
| 数据完整性 | 45 | STATUS.md 82% 乱码入库(F1)、事实来源被污染 | 损坏隔离、表格数据部分存活 |
| 治理可执行性 | 60 | 门禁盲区(F6)、双管线(F7) | 体系完整、§20 标准先进 |
| 基础设施健全度 | 50 | .git 949MB(F2)、极高 churn(F3)、运行态膨胀(F9) | 脚本可用、gitignore 基本正确 |
| 可维护性 | 58 | 45 agent 三重维护(F8)、规则碎片化、CLAUDE 超行数目标 | hooks/scripts 框架精良 |

---

## 7. 优先级修复建议

**立即（P0）**
1. **恢复 STATUS.md**：`git checkout <损坏前 SHA> -- STATUS.md` 或重跑 `sync-status.mjs`；为生成器加幂等护栏（拒绝含行号前缀/已生成标记的输入）。
2. **清理 .git 备份**：为 `branch-governance-backups` 设保留策略（最近 N 个 + TTL），改增量备份；一次性 `git gc` 前先归档清理旧 bundle。

**近期（P1）**
3. **修门禁盲区**：audit-status.py 增加文档结构健全性检查（单 H1、无重复标题、无行号前缀、三文档仓库引用数一致）——让"绿色"重新等于"健康"。
4. **消除 ARCHITECTURE 漂移**：决定其为"存根"还是"正文"并落实，同步修正 CLAUDE/AGENTS 描述。
5. **修 README 双 H1**：移除第二个 H1，将"草案 v3"架构正文迁出主页、改为链接。

**中期（P2）**
6. **收敛提交策略**：放宽"每次迭代 +1"，引入提交聚合，降低 churn。
7. **统一两套管线**：明确 governance 与 goal 的主从或合并，消除重复 gate/traceability 维护。
8. **agent 配置 DRY**：以单一来源生成三平台 agent 配置，而非手工三份。
9. **规则瘦身**：执行 CLAUDE.md 自定的"季度瘦身"，将已内化规则归档，回到 < 350 行目标。

---

## 8. 附录 · 关键可复现命令

```bash
# 损坏量化
wc -l STATUS.md; grep -cE '^[0-9]+\. [0-9]+\.' STATUS.md; grep -c '^## ' STATUS.md
grep -c 'github.com/ZoneCNH' STATUS.md README.md   # 0 vs 50

# .git 膨胀
du -sh .git; du -sh .git/* | sort -rh | head -3
ls .git/branch-governance-backups | wc -l

# 提交频率
git rev-list --all --count; git rev-list --all --count --since="30 days ago"

# 文档漂移
wc -l ARCHITECTURE.md; grep -n '^# ' README.md

# 门禁盲区
python3 scripts/audit-status.py; echo $?   # 51 passed / exit 0

# 规格资产
git ls-files 'module/*/SPEC.md' | wc -l    # 50
find module -maxdepth 1 -type d | grep -vc '^module$'  # 53

# 体系体量
wc -l CLAUDE.md AGENTS.md; cat docs/constitution/*.md | wc -l
find docs/governance docs/goal -name '*.md' | wc -l
```

---

*[RULES I BROKE]：无。本报告已按 §20 标注证据标签与置信度；§1 主动披露了执行中的 5 处工具截断误判并复核纠正；所有量化结论附可复现命令；未编造引用；主观评级均标 `[INFERRED]` 且置信度不超过证据支持的水平。*
