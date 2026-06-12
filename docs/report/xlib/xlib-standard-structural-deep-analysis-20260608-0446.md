# `module/xlib-standard/` 结构性问题深度分析（v3）

- 报告日期：2026-06-08 04:46 (+08:00)
- 报告作者：Copilot CLI（Claude Opus 4.7）
- 分析对象：`module/xlib-standard/`
- 对照基线：`docs/governance/SPEC-TEMPLATE.md`、`module/README.md`、`docs/governance/LIFECYCLE.md`、`docs/governance/DEFINITION-OF-READY.md`、`docs/governance/TRACEABILITY.md`、`CONSTITUTION.md`、`ARCHITECTURE.md`
- 自动化证据：`bash .github/ci/spec-lint.sh`、`spec-drift-guard.sh`、`traceability-check.sh`、`status-consistency-check.sh`
- 方法：模板节序对照 + 编号体系闭环扫描 + CI lint 实际运行 + 跨文档状态一致性核对 + 与前两版报告差异对比
- **综合评分：6.8 / 10（中高，较 v2 6.1 → +0.7）**
- 上一轮关键改善：
  - 23 节框架已对齐（§1..§23 全到位，spec-lint **23/23 sections ✅**）；
  - `MODULE-SPEC.md` / `DEEP-ANALYSIS.md` 已归档；
  - `TRACEABILITY.md` 引入 FR 行级表 + 块级缺口声明 + NG-33 自动巡检；
  - `CONFLICT-LEDGER.md`、`COVERAGE-MANIFEST.md` 均标注 `Aligned-With SPEC.md v2.0.1`。
- 仍然存在的核心矛盾：**Status 已声明 `Approved` 且 `Approved-By` 自评 9.66/10，但发布门禁前置条件 (commit/tree sha 未固定、追溯 73% 块级、5 个 FR 无 TC、README 状态滞后) 全部未达成 — 治理一致性是当前最大的结构债**。

---

## 0. 工件清单与角色

| 文件                       | 行数 | 自我声明                   | 实际角色                                        | 备注                                      |
| -------------------------- | ---: | -------------------------- | ----------------------------------------------- | ----------------------------------------- |
| `README.md`                | 56   | —                          | 目录索引 + 阅读规则 + 上游引用                  | **Status 描述滞后于 SPEC**（见 S1）       |
| `SPEC.md`                  | 2013 | `Status: Approved, v2.0.1` | 主规格 · 52 FR · 104 WHEN/THEN · 23 节 + 6 附录 | 节框架达标，治理一致性存疑                |
| `TRACEABILITY.md`          | 148  | `Aligned-With v2.0.1`      | 章节级 + FR 行级矩阵                            | 73% FR 仍为块级（自报）                   |
| `CONFLICT-LEDGER.md`       | 180  | `Aligned-With v2.0.1`      | 22 条历史取舍                                   | 引用稳定                                  |
| `COVERAGE-MANIFEST.md`     | 201  | `Aligned-With v2.0.1`      | 154 输入文件清单（占位符路径）                  | **commit/tree sha 未固定**（自报 OQ-008） |
| `archive/MODULE-SPEC.md`   | 450  | 已归档                     | 历史 20 节稿                                    | 不再随主规格更新 ✅                        |
| `archive/DEEP-ANALYSIS.md` | 538  | 已归档                     | 181 文件旧口径                                  | 不再随主规格更新 ✅                        |

---

## 1. CI 自动化证据（baseline）

| 检查                          | 结果                                             | 关键告警                                                                                                                                  |
| ----------------------------- | ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `spec-lint.sh`                | ⚠️ 通过有警告                                    | `xlib-standard` 存在 fuzzy word `可能`；脚本报 `Section 4 Non-goals is empty`（实际系前置 `## 使用边界` 节扰乱脚本节计数 — 仍是结构缺陷） |
| `spec-drift-guard.sh`         | ✅ 通过                                           | —                                                                                                                                         |
| `traceability-check.sh`       | ⚠️ `xlib-standard: 5 requirements with empty TC` | 52/52 FR 已追溯到来源，但 5 条 FR 无对应 TC，与 §16.5 自述"P0 TC 只是样板，其余由 harness 间接证明"互证                                   |
| `status-consistency-check.sh` | ✅ 静默                                           | —                                                                                                                                         |

这是 v3 报告与 v2 最大差异：v2 凭目视判断，v3 用脚本得出**两条硬性 CI 告警**，可在 PR 中直接复现。

---

## 2. 结构性问题清单（按严重度）

### S1【严重】跨文档 Status / 元数据漂移

**事实**：

| 来源                                                                    | 字段              | 值                                                  |
| ----------------------------------------------------------------------- | ----------------- | --------------------------------------------------- |
| `SPEC.md:5`                                                             | `Status`          | `Approved`                                          |
| `SPEC.md:8`                                                             | `Approved-By`     | `spec-review agent（第三轮终审，独立评分 9.66/10）` |
| `SPEC.md:10`                                                            | `Approved-Commit` | `d7a60ef（后续补 N-1 修复 commit）`                 |
| `README.md:17`                                                          | 自述              | `v2.0.1, Status: Review`                            |
| `TRACEABILITY.md:3` / `CONFLICT-LEDGER.md:3` / `COVERAGE-MANIFEST.md:3` | `Aligned-With`    | `SPEC.md v2.0.1`                                    |

**问题维度**：

1. **README 与 SPEC 双向漂移**：同一仓库目录的"目录页"声明 `Status: Review`，主体 SPEC 已是 `Approved`。任何外部读者按 README 入手会得出错误的生命周期判断。
2. **`Approved-By` 是同一管线内的 sub-agent 自评**，非独立人工 reviewer，违反 `LIFECYCLE.md` Approved 状态语义（应由 `Owner` 或外部审查者签字）。
3. **`Approved-Commit` 字面承认"后续补 N-1 修复 commit"** — Approved 状态不应携带"待补提交"的 footnote，否则 Approved 的契约（提交可追溯到唯一 commit）失效。

**影响**：发布前置条件失真；下游模块无法把 `xlib-standard@Approved` 当作可消费基线。

**评分扣点**：−1.2

---

### S2【严重】Approved 与 Release-Ready 前置条件互相矛盾

SPEC.md 自身记录的发布阻断项（OQ + R + NG）与 `Status: Approved` 不兼容：

| 编号                    | 自述状态                                                        | 触达 Approved 的合理性                               |
| ----------------------- | --------------------------------------------------------------- | ---------------------------------------------------- |
| OQ-008 / R-011          | `COVERAGE-MANIFEST.md` commit/tree sha **未固定**，存在漂移风险 | 不可接受：Approved 必须可复现                        |
| OQ-007                  | P1 活跃覆盖 81.3% < 90%，需再索引 26 条 P1 规则                 | 不可接受：覆盖率低于自定义阈值                       |
| NG-33                   | TRACEABILITY 行级缺口超阈值即阻断发布；当前 **73% FR 为块级**   | 自相矛盾：当前状态本应触发 NG-33                     |
| NG-34                   | COVERAGE-MANIFEST commit/tree 未固定即阻断发布                  | 自相矛盾：同上                                       |
| `traceability-check.sh` | 5 个 FR 无 TC                                                   | 与 §16.5 / FR-026 / FR-032 evidence-binding 要求冲突 |

**结论**：SPEC 同时声明"已 Approved"和"若进入 release 则 NG-33/NG-34/NG-35 都会失败"，是治理上的逻辑冲突。

**评分扣点**：−1.0

---

### S3【高】23 节框架达标但**外挂节**破坏模板纯洁性

SPEC.md 的 H2 层级实际结构：

```text
## 使用边界          ← 模板外（line 19）
## 1. 元信息
## 2. 概述
…
## 23. 待解决问题
## 附录 A. 风险
## 附录 B. 未来考虑
## 附录 C. 文档清单
## 附录 D. 部署与发布细节
## 附录 E. 关键数字与映射
## 附录 F. 整理交付自检
```text

问题：

- **`## 使用边界` 是没有节号的 H2 前置节**，直接干扰 `spec-lint.sh` 的位置计数（脚本报 "Section 4 Non-goals is empty" 即为该错位扰乱所致）。应改为 `### 0.x 使用边界` 嵌入 §1 或 §2 之内，或移至 README。
- **6 个附录共 ~280 行**，其中：
  - §A 风险与模板 §19 Security / §23 Open Questions 边界含糊；
  - §B 未来考虑 与 §21 Upgrade Compatibility 内容重复；
  - §D 部署细节 与 §22 Release DoD 重复（§D.1 "发布流程" vs §22.3 "发布前 Gate Chain"）；
  - §F "整理交付自检" 是 review-time checklist，本应放进 PR description 或 archive。
- **CONSTITUTION.md 第 4 条要求 23 节结构**，未授权附录形式扩展；本规格对外宣称模板对齐，对内通过附录绕开。

**评分扣点**：−0.5

---

### S4【高】Traceability 体系编号未闭合：缺 BR/AC 链

通过实测：

| 编号体系    | 数量                | 出现位置                                                                    |
| ----------- | ------------------: | --------------------------------------------------------------------------- |
| `FR-NNN`    | 52                  | §7.1..§7.8 平铺                                                             |
| `WHEN/THEN` | 104 行              | 每 FR ≥ 2 条 ✅                                                              |
| `BR-NNN`    | **0**               | §8 用 `IR-001..007` + `TRUTH-001..015` + `RULE-CORE-001..` 三套同义编号代替 |
| `AC-NNN`    | **0**               | §22 DoD 用四级表代替，无可被 traceability matrix 引用的 AC 标识             |
| `TC-NNN`    | 17 (TC-001..TC-017) | §16.5 仅覆盖 P0 样板                                                        |
| `EC-NNN`    | 10                  | §13.1 OK ✅                                                                  |
| `NG-NN`     | 37                  | §22.4 ✅                                                                     |
| `OQ-NNN`    | 8                   | §23 ✅                                                                       |
| `R-NNN`     | 11                  | §A ✅                                                                        |

**结构性后果**：

- `docs/governance/TRACEABILITY.md`（仓库根级方法论文档）要求 **FR ↔ BR ↔ AC ↔ TC** 四向闭环，本 SPEC 仅闭合 FR ↔ TC（且 5 条 FR 无 TC）。
- §8.1 自述"IR ↔ TRUTH 别名约定（消解结构债 S11）"承认存在双轨编号 — 这恰恰说明编号体系仍未真正归一，只是用"别名约定"绕过。
- 下游模块如果按本 SPEC 当作模板复用 TC-001..TC-017 编号，会与本仓库 TC 命名空间冲突（§16.5 提到下游"继承 TC-001..TC-017 作为基础合规集"，未定义 namespace 前缀）。

**评分扣点**：−0.8

---

### S5【中】Layer / 领域命名跳出 ARCHITECTURE.md 模型

`SPEC.md` §1 与 §15.1 自创 **"门禁（Foundation Gate，位于所有领域之上）"**，而 `ARCHITECTURE.md` 已固化的领域是：

```text
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
横切：observex / alertx
```text

未定义"门禁"层。FR-004 也借此引入 `门禁 → 基座 L0 → ...` 八元链，但其他 16 个模块 SPEC 均按 5 领域命名（已通过 `spec-drift-guard` 校验）。

**建议**：要么把 `xlib-standard` 显式归入"基座/横切"，要么在 `ARCHITECTURE.md` 中正式新增"门禁"层并同步更新所有图与表。当前只在本模块单方面新建词项 = 域语义漂移。

**评分扣点**：−0.4

---

### S6【中】COVERAGE-MANIFEST 缺乏跨机复现根

- 已知问题：占位符路径 `<upstream:commit>` / `<upstream:tree>` 留空 → 任何 PR / CI / 下游审查都无法在不同机器上证明输入文件集合一致；
- 自述（COVERAGE-MANIFEST.md §可复现边界）：*"本清单证明输入文件集合数量和路径稳定，不证明这些源文件内容在未来时间点保持不变"* — 等于显式承认证据强度不够；
- 与 NG-34 / NG-33 冲突（见 S2）。

**建议**：在 Approved 前必须执行 `goalcli coverage-pin-check` 并把 commit/tree sha + 154 个 sha256 落地到 manifest。

**评分扣点**：−0.4

---

### S7【中】FR 与 RULE-* 体系映射缺失

SPEC §2 反复声明"419 条 RULE-* 规则"是整个标准的事实总量，但：

- FR-001 用一条 FR 覆盖"419 条规则全部有条目"，未在任何地方建立 **RULE-* → FR / TC** 的反向映射；
- §8.2 列出 10 类 RULE 前缀，但每类的 RULE 数量、负责的 FR 区段全部未表；
- 后果：技术债治理（FR-033..039）声称按 7 类执行，但无法回答"DEP 类的具体 6 条规则各自被哪条 FR / TC 验证"。

**建议**：在 §8 或附录新增 `RULE-ID ↔ FR-ID ↔ TC-ID` 三向矩阵（哪怕先块级，按前缀汇总也可）。

**评分扣点**：−0.3

---

### S8【低】Fuzzy words 与措辞失准

`spec-lint.sh` 检出 `可能`（fuzzy word）。规格文档应使用 MUST / SHOULD / MAY 或中文"必须 / 应当 / 可"，禁用"可能 / 大概 / 通常"等弱化措辞。该错误虽小，但 CI 已经把它标出，是 Approved 状态不应残留的纯文本债。

**评分扣点**：−0.1

---

### S9【低】§16.5 TC 命名空间未隔离下游

§16.5 "TC ↔ FR 追溯矩阵（核心 P0）" 仅 17 条样板，但同时声明 **下游模块"沿用并扩展"** TC-001..TC-017。未要求下游加前缀（如 `redisx-TC-001`），将来汇总仓库级测试矩阵时会冲突。

**评分扣点**：−0.1

---

## 3. 与前两版报告的差异（演进检视）

| 维度                 | v1 (03:41)       | v2 (晚些时候)   | v3 (本报告)                            | 走向     |
| -------------------- | ---------------- | --------------- | -------------------------------------- | -------- |
| 23 节框架            | ❌ 模板严重错位   | ⚠️ 部分对齐     | ✅ spec-lint 23/23                      | ↑        |
| Archive 治理         | ❌ 历史稿混入主线 | ✅ 已归档        | ✅ 保持                                 | ↑        |
| FR 行级追溯          | 0%               | 块级 100%       | 27% 行级 + 73% 块级（已显式缺口声明）  | ↑        |
| Status 一致性        | n/a              | Draft           | **Approved 但 README/COVERAGE 不一致** | ↓        |
| BR/AC 编号           | 缺               | 缺              | 仍缺                                   | →        |
| Coverage commit sha  | 未提             | 自报缺口        | 自报 OQ-008 + R-011 但仍未固定         | →        |
| spec-lint 告警       | 未测             | 未测            | 2 项（fuzzy + 节计数错位）             | 首次量化 |
| Traceability TC 覆盖 | 未测             | 未测            | 5 条 FR 无 TC                          | 首次量化 |

**评分曲线**：5.1 → 6.1 → **6.8**（结构骨架收敛，但治理一致性变成新的瓶颈）。

---

## 4. 评分明细

| 维度 (权重)                    | 满分     | 得分    | 扣点理由                              |
| ------------------------------ | -------: | ------: | ------------------------------------- |
| 23 节模板对齐 (20%)            | 2.0      | 1.5     | S3 外挂节扰乱 lint                    |
| 编号体系闭环 FR/BR/AC/TC (15%) | 1.5      | 0.7     | S4 缺 BR/AC，5 FR 无 TC               |
| Traceability 链完整性 (15%)    | 1.5      | 1.0     | 行级 27%；S7 RULE↔FR 未映射           |
| 跨文档一致性 (15%)             | 1.5      | 0.4     | S1 README↔SPEC 漂移                   |
| 生命周期治理 (15%)             | 1.5      | 0.5     | S2 Approved 与 NG 互斥                |
| CI 自动化通过率 (10%)          | 1.0      | 0.7     | spec-lint 2 警告，traceability 1 警告 |
| 架构归位 (5%)                  | 0.5      | 0.3     | S5 自创 "门禁" 层                     |
| 可复现性 (5%)                  | 0.5      | 0.2     | S6 commit/tree sha 缺                 |
| **合计**                       | **10.0** | **6.8** | —                                     |

---

## 5. 改进建议（按 ROI 排序）

| 优先级   | 动作                                                                                                                                        | 预期收益                              | 工作量   |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | -------- |
| P0       | 把 `Status` 暂时回退到 `Review`（或同步刷新 README/TRACEABILITY/COVERAGE 三处 + 补独立 reviewer 签字 + 固定 `Approved-Commit`），消除 S1/S2 | 治理一致性恢复，发布门禁链可信        | 0.5 day  |
| P0       | 把 "使用边界" 并入 §2，把 §附录 D 合入 §22，§附录 A 合入 §23，§附录 F 移至 PR description，消除 S3                                          | spec-lint 节计数恢复正确              | 0.5 day  |
| P0       | 引入 `BR-NNN` / `AC-NNN` 编号（最简：把 §8.1 IR-001..007 重命名为 BR；把 §22.1 DoD 四级各拆 1 个 AC），消除 S4 一半                         | 闭合 FR↔BR↔AC↔TC 四向矩阵             | 0.5 day  |
| P1       | 补齐 5 条无 TC FR 的 TC 行；或在 §16.5 显式注明这 5 条由 harness gate 覆盖并指明 gate ID                                                    | `traceability-check.sh` 转 ✅          | 1 day    |
| P1       | 运行 `goalcli coverage-pin-check`，把 154 个文件的 sha256 + 上游 commit/tree sha 写入 COVERAGE-MANIFEST                                     | 关闭 OQ-008 / R-011 / NG-34，使可复现 | 0.5 day  |
| P1       | 把 §1 / §15.1 的 "门禁" 改写为 "横切层（Foundation Gate），位于基座之上"或在 ARCHITECTURE.md 正式增列                                       | 与全仓 17 个 SPEC 用语统一            | 0.3 day  |
| P2       | 新增 §8.x 或附录 G：`RULE-* ↔ FR ↔ TC` 三向汇总表（先按前缀块级，逐步细化）                                                                 | 解释 419/52/17 三个数量级的关系       | 1 day    |
| P2       | 在 §16.5 注明 TC 编号下游必须加前缀（`<module>-TC-NNN`）                                                                                    | 防止下游汇总冲突                      | 5 min    |
| P3       | 用 `必须 / 应当 / 可` 替换全文 `可能 / 通常 / 一般`                                                                                         | spec-lint fuzzy 0                     | 10 min   |

---

## 6. Go/No-Go 判断

- **Approved 状态：No-Go**（需先消除 S1/S2/S6）。
- **若降级为 Review 状态：Go**（骨架已成型，可继续走 spec-review → approve → matrix 管线）。

---

## 7. 引用

- `module/xlib-standard/{README,SPEC,TRACEABILITY,CONFLICT-LEDGER,COVERAGE-MANIFEST}.md`
- `module/{SPEC-TEMPLATE,README,LIFECYCLE,TRACEABILITY,DEFINITION-OF-READY,DEFINITION-OF-DONE}.md`
- `CONSTITUTION.md` §4 / `ARCHITECTURE.md` 领域模型
- `.github/ci/{spec-lint,spec-drift-guard,traceability-check,status-consistency-check}.sh`（实际运行，证据见 §1）
- 前两版报告：`docs/report/xlib-standard-structural-issues-20260608-0341.md`、`docs/report/xlib-standard-specs-structural-review-20260608.md`
