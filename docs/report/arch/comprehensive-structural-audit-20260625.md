# FoundationX 仓库深度架构与结构性审计报告

> 范围：`ZoneCNH/ZoneCNH`（FoundationX 量化交易基础设施文档枢纽）
> 审计基线：分支 `docs/binance-readiness-alignment` · 钉住 HEAD `1e8c07eb` @ 2026-06-25 03:04
> 方法：一手取证（`git ls-files` / `git show` / 退出码 / 内置 glob·grep·view / 输出重定向）
> 适用认识论标准：`docs/constitution/20-epistemic-standards.md`（§20）

---

## 0. 执行摘要

ZoneCNH/ZoneCNH 的**内容资产是健康且扎实的**：50 个模块 SPEC、24 章宪法、9 篇架构文档 + ADR，三大核心文档（STATUS / README / ARCHITECTURE）经逐一核验**均结构完好、提交历史干净**。仓库自带的审计门禁 `audit-status.py` 全绿通过（51/0）。

真正的结构性张力**不在制品质量，而在交付节奏与治理重量**：本次审计的 ~30 分钟窗口内，仓库被并行自动化**提交了约 8 次**（02:40→03:04，约每 3 分钟一次），README/STATUS/binance 等文件在我观测期间持续变动，导致静态快照难以稳定锁定。与此同时，`.git` 本地目录因治理备份累积到 949MB（其中 897MB 为本地 bundle 备份，**不影响克隆**），三平台 agent 配置已出现 26/20/13 的不对称漂移。

**综合评分：70 / 100（C+，中等偏上）** `[COMPUTED] · 置信度 MED`

| 维度           | 权重 |  得分  |  评级  |
| -------------- | :--: | :----: | :----: |
| 架构清晰度     | 20%  |   82   |   B    |
| 文档一致性     | 20%  |   75   |   B-   |
| 数据完整性     | 15%  |   76   |   B-   |
| 治理可执行性   | 15%  |   60   |   C-   |
| 基础设施健全度 | 15%  |   58   |   D+   |
| 可维护性       | 15%  |   60   |   C-   |
| **加权总分**   | 100% | **70** | **C+** |

> 加权：`82×.20+75×.20+76×.15+60×.15+58×.15+60×.15 = 69.5 ≈ 70` `[COMPUTED]`

**一句话诊断**：制品健康（B 级内容），但被一套**重度且高频自变更的治理自动化**所承载——它带来扎实的规格资产与自愈能力，同时也带来极高的提交噪声、本地存储囤积与跨平台配置漂移。**最大风险不是制品缺陷，而是"系统的可观测性与可推理性"被高频并发突变和过度工程稀释。**

---

## 1. 方法论与可靠性声明（必读）

本次审计在执行中遭遇**两类干扰**，导致初轮探查产生多处误判，全部已用可靠手段复核纠正。按 §20 要求如实披露：

**干扰 A — 工具输出异常**：部分 bash/grep 输出被替换为 `[REDACTED:hf-token]` 或被静默截断，早期甚至返回过与实际不符的文件内容。
**干扰 B — 并发突变**：仓库在审计期间被并行 agent 持续提交（见 §2.1），同一文件的早晚两次读数可能跨越了提交边界。

| 初判（已撤回）               | 复核结论（当前真相）                 | 复核手段                                    |
| ---------------------------- | ------------------------------------ | ------------------------------------------- |
| STATUS.md 损坏 2417 行并入库 | **全部提交历史均为 503 行干净版**    | `git show <sha>:STATUS.md` 逐版本迭代       |
| README.md 1009 行 / 双 H1    | **210 行 / 单 H1，会话前即稳定**     | `view` + `git show HEAD:README.md \| wc -l` |
| `.git` 949MB = 仓库膨胀      | 可克隆对象仅 ~48MB；897MB 为本地备份 | `git count-objects -vH`                     |
| audit-status.py 崩溃         | PASS 51/0，exit 0                    | 重定向 + `$?`                               |
| module/ 仅 binance           | 53 目录 / 50 SPEC                    | `git ls-files` + `glob`                     |
| agents 三平台各 15 对称      | 26 / 20 / 13 不对称                  | `glob` 计数                                 |

> **诚实声明** `[FRAME]`：本报告**只采信用可靠工具在钉住 HEAD 上复核过的结论**。凡早期单次读数、无法在当前提交历史复现者，一律不作为事实陈述。主观评级标 `[INFERRED]` 并限定置信度。

---

## 2. 核心结构性发现

### 2.1 〔P1〕极高提交频率 + 并发突变 —— 系统可推理性被稀释 `[COMPUTED] · HIGH`

**这是最显著、最可复现的结构性特征。**

```
$ git rev-list --all --count --since='30 days ago'   → 1596   (约 53 次/天)
$ git rev-list --all --count --since='1 day ago'     → 28
$ git log --since='2026-06-25 02:34' --format='%h %ci %s'   # 本会话窗口
  1e8c07eb 03:04 ...        6d956eab 03:01 实证推进记录 — mainnet 四线 LIVE-PASS
  8d172a25 02:57 beads 闭环  a3805eca 02:47 binance 生产就绪修复执行记录
  bc635fdb 02:44 G0 闭合     098cc762 02:41 binance 生产就绪评估 + 架构分析报告
  258f45c5 02:40 ...         5c5ca8be 02:40 C7 新增 6 个规范文档
```

**观测**：审计 ~30 分钟内 HEAD 前移 **8 次**，其中 098cc762 是**另一个 agent 并行产出的架构分析报告**（与本报告同写入 `docs/report/arch/`）。README、STATUS、binance 全套文档在窗口内被重写/再生。

**影响** `[INFERRED] · HIGH`：

- `git log` 信噪比极低，提交历史无法承担"变更叙事"职能；
- 任何**静态审查/评分/快照**都可能捕获瞬时不一致状态（本次审计亲历）；
- "事实层"（STATUS/STATUS json/manifest）随高频投影刷新，人难以确认"此刻的真相"。

> **这不是单点缺陷，而是运行模式的固有代价。** 对 AI 驱动的高速文档仓库，高频提交是特性；但缺乏**提交聚合**与**稳定可引用基线（如带签名的 daily snapshot tag）**，会让协作者与审查者持续处于"追逐移动目标"状态。

> **建议**：① 引入提交聚合窗口（CLAUDE.md 已有"批处理"约定，但实际 28 次/天说明未落地）；② 提供每日/每阶段稳定快照 tag 供引用；③ 自动提交统一前缀（如 `chore(auto):`）以便 `git log` 过滤噪声。

---

### 2.2 〔P2〕`.git` 本地目录囤积 897MB 治理备份 `[COMPUTED] · HIGH`

```
$ du -sh .git                                  → 949M
$ du -sh .git/branch-governance-backups        → 897M   (87 个时间戳目录)
$ git count-objects -vH | grep size            → size 38.19 MiB / size-pack 10.56 MiB
```

**关键判别**：897MB 是 `branch-governance-backups/<时间戳>/*.bundle` 形式的**本地备份**，位于 `.git` 内部但**不属于 git 对象库、不随 push/clone 传播**。**因此新克隆仅约 48MB，协作者侧健康。**

**性质** `[INFERRED] · HIGH`：这是**本地磁盘卫生问题**，非仓库膨胀灾难。根因是 CLAUDE.md 描述的"分支保护/自动 bundle 备份"在每次分支操作时打全量 bundle（每个 ~7.3MB），87 次累积、无界增长。属于**过度谨慎自动化的负价值**：备份体积是被保护内容的近 20 倍，而 git 本身已是分布式备份。

> **建议**：为 `branch-governance-backups` 设保留策略（最近 N 个 + TTL 7 天）、改增量/引用式备份，并评估该机制必要性。

---

### 2.3 〔P2〕三平台 agent 配置已漂移失同步 `[COMPUTED] · HIGH`

```
glob .claude/agents/*  → 26 个    glob .codex/agents/*  → 20 个    glob .copilot/agents/* → 13 个
```

四源体系（Claude/Codex/Copilot/rules）要求三平台 agent **功能等价**，文档亦如此宣称。但实测数量为 **26 / 20 / 13**，严重不对称——说明"三处手工维护同一角色集"的 DRY 负担**已实际失败**，三套配置正在分叉。`.copilot` 缺失最多（仅 13），可能导致 Copilot 平台触发管线时部分角色缺位。`[INFERRED] · HIGH`

> **建议**：以单一来源（如 `agents/*.yaml`）生成三平台配置，而非三处手写；或在 CI 增加"三平台 agent 集合一致性"校验。

---

### 2.4 〔P2〕治理体系对当前规模偏重 `[COMPUTED] · MED`

| 体系            | 规模                                          | 证据                                  |
| --------------- | --------------------------------------------- | ------------------------------------- |
| 宪法            | 24 章 / 1342 行                               | `cat docs/constitution/*.md \| wc -l` |
| governance 管线 | Spec→Matrix→Tasks→Plan→Prompt→Code + 48 文件  | `docs/governance/`                    |
| goal 管线       | Goal→Spec→Design→…→Release + G0-G11 + 67 文件 | `docs/goal/`                          |
| agent 定义      | 59 个（26+20+13）                             | glob                                  |
| CI workflow     | 13 个                                         | glob                                  |
| 行为准则        | CLAUDE.md 395 行 + AGENTS.md 273 行           | `wc -l`                               |

**两套交付管线并存**（governance 与 goal）阶段大量重叠（Spec/Plan/Tasks/Prompt/Code），各自维护 pipeline、gate、traceability。CLAUDE.md 自设"< 350 行"目标已被突破（395 行），且含大量 `> 取代: 日期` 的规则演进层积。

**判断** `[INFERRED] · MED`：体系设计本身成熟（§20 认识论标准尤为先进），但对一个个人主导的文档仓库，**双管线 + 59 agent + 1342 行宪法**构成显著认知与维护开销。这是"治理重量 vs 实际吞吐"的权衡问题，非缺陷；但叠加 §2.1 的高频突变，会放大维护成本。

> **建议**：明确 governance 与 goal 的主从或合并；执行 CLAUDE.md 自定的"季度规则瘦身"。

---

### 2.5 〔P3〕质量门禁存在结构性盲区 `[COMPUTED] · MED`

```
$ python3 scripts/audit-status.py; echo $?   → 51 passed, 0 failed / exit 0
```

`audit-status.py` 校验的是**表格算术一致性**（域计数、版本计数、仓库引用数交叉核对）等 9 类检查，但**不校验文档结构完整性**（H1 数量、是否有重复标题、是否有异常行号前缀、Markdown 是否可渲染）。

**风险** `[INFERRED] · MED`：本次审计早期观测到的"瞬时损坏状态"（无论其确切来源）说明**生成管线在某些时刻可能产出畸形输出**。当前 audit 无法感知此类结构性破坏——若畸形输出被提交，门禁仍会全绿。这正是 §20 警示的 `[FRAME] → [REALITY]` 鸿沟的潜在入口：**指标绿 ≠ 文档可读**。

> **建议**：为 audit 增补"文档结构健全性"检查（单 H1、无重复连续标题、无 `N. M.` 行号前缀、三文档仓库引用数一致），把"制品被破坏"纳入门禁可见域。

---

### 2.6 〔P3〕运行态目录本地膨胀 `[COMPUTED] · MED`

```
.omx=190M   .beads=18M   .worktree=16M   .omc=8.5M
```

`.omx` 单独 190MB。多数已正确 gitignore（`.omx/.beads/.worktree` 被跟踪文件数为 0），属本地工作区卫生，不影响仓库；但 `.omc`（25 文件）、`.config`（46 文件）仍入库，需确认是否应纳入版本控制。`[COMPUTED] · MED`

---

## 3. 正面发现（评分已计入）

- **〔HIGH〕规格资产扎实**：`module/` 含 **53 目录 / 50 个 SPEC.md**，体量梯度合理（binance 1380、xlibgate 1303、kernel 1274 … 至精简模块 54 行）。**绝非"单模块"空壳**，是有真实内容的多模块规格库。`git ls-files 'module/*/SPEC.md' | wc -l`
- **〔HIGH〕核心文档健康且历史干净**：STATUS.md（503 行）、README.md（210 行单 H1）、ARCHITECTURE.md（605 行架构枢纽，显式跳转 docs/architecture/）经逐一核验结构完好；STATUS.md **全部提交历史**均为干净版本。
- **〔HIGH〕治理与架构文档完整**：`docs/constitution/` 24 章齐全、`docs/architecture/` 9 文件 + ADR、§20 认识论标准（证据标签 + 置信度 + 反奉承红旗）设计成熟。
- **〔MED〕自愈能力**：审计期间观测到瞬时不一致状态被并行自动化快速收敛——表明生成/投影管线具备自我修复倾向（虽也是高频突变的来源）。
- **〔MED〕审计可用**：`audit-status.py` 可运行且通过算术一致性检查；CI/hooks/scripts 框架完备。

---

## 4. 评分理由明细

| 维度           | 得分 | 主要扣分                                                    | 主要加分                                  |
| -------------- | :--: | ----------------------------------------------------------- | ----------------------------------------- |
| 架构清晰度     |  82  | ARCHITECTURE/docs 存在内容重叠、"存根"措辞略不符            | 分层模型清晰、9 原则成体系、文档完整      |
| 文档一致性     |  75  | agent 配置 26/20/13 漂移、治理措辞与现实小幅脱节            | 三核心文档干净自洽、提交历史干净          |
| 数据完整性     |  76  | audit 结构盲区(2.5)、生成管线存在产出畸形的可能             | 提交历史干净、审计算术全绿                |
| 治理可执行性   |  60  | 双管线重叠、门禁盲区、规则层积                              | 体系完整、§20 标准先进                    |
| 基础设施健全度 |  58  | 本地 .git 囤积 897MB(2.2)、极高 churn(2.1)、运行态膨胀(2.6) | 可克隆仓库健康(~48MB)、gitignore 基本正确 |
| 可维护性       |  60  | 高频突变损害可推理性、agent 漂移、治理重量                  | 工具框架精良、自愈能力                    |

---

## 5. 优先级修复建议

**近期（P1-P2，影响可推理性与本地卫生）**

1. **收敛提交节奏**：落实提交聚合（当前 28 次/天与 CLAUDE.md"批处理"约定不符）；自动提交统一前缀以便过滤；提供每日稳定快照 tag。
2. **清理 .git 本地备份**：为 `branch-governance-backups` 设 TTL + 数量上限，改增量备份；评估该机制必要性。
3. **agent 配置 DRY**：单一来源生成三平台配置，CI 增加三平台 agent 集合一致性校验，修复 26/20/13 漂移。

**中期（P2-P3，降低治理重量与门禁盲区）** 4. **修门禁盲区**：audit-status.py 增补文档结构健全性检查，让"绿色"覆盖"制品未被破坏"。5. **统一双管线**：明确 governance 与 goal 的主从或合并，消除重复 gate/traceability 维护。6. **规则瘦身**：执行 CLAUDE.md 自定的季度瘦身，归档已内化规则，回到 < 350 行目标。7. **运行态入库审查**：确认 `.omc`/`.config` 入库文件是否应版本化。

---

## 6. 附录 · 关键可复现命令（钉住 HEAD 1e8c07eb）

```bash
# 并发突变 / churn
git rev-list --all --count --since='30 days ago'          # 1596
git rev-list --all --count --since='1 day ago'            # 28
git log --since='2026-06-25 02:34' --format='%h %ci %s'   # 会话窗口 8 提交

# .git 本地囤积 vs 可克隆健康
du -sh .git .git/branch-governance-backups                # 949M / 897M
git count-objects -vH | grep -E 'size:|size-pack:'        # ~48MB 对象

# 核心文档健康（逐版本验证 STATUS 历史干净）
wc -l STATUS.md README.md ARCHITECTURE.md                 # 503 / 210 / 605
for s in $(git log -6 --format=%h -- STATUS.md); do \
  echo "$s $(git show $s:STATUS.md|grep -cE '^[0-9]+\. [0-9]+\.')"; done   # 全 0

# 资产与配置计数（用 glob/git 避免输出过滤）
git ls-files 'module/*/SPEC.md' | wc -l                   # 50
ls .claude/agents .codex/agents .copilot/agents | ...     # 26 / 20 / 13
python3 scripts/audit-status.py; echo $?                  # 51 passed / 0
```

---

_[RULES I BROKE]：无。本报告按 §20 标注证据标签与置信度；§1 主动、完整披露了审计中的 6 处误判（含早期对 STATUS.md/README 的错误读数）并逐一复核撤回；所有事实陈述均基于钉住 HEAD `1e8c07eb` 上可复现的命令；明确区分了"本地 .git 囤积"与"可克隆仓库健康"，未将本地卫生问题夸大为仓库膨胀；未编造引用；主观评级均标 `[INFERRED]` 且置信度不超过证据支持水平。_
