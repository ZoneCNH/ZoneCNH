# `module/xlib-standard/` 结构性深度分析与打分

- 报告日期：2026-06-08 06:02 +08:00
- 分析范围：`module/xlib-standard/` 下 8 个工件（SPEC.md 1627 行、TRACEABILITY.md、CONFLICT-LEDGER.md、COVERAGE-MANIFEST.md、FR-DETAIL.md、REMOTE-EVIDENCE.md、REVIEW-VERDICT.md、README.md）
- 上游 commit：`93753b30e6d01fb4a9b096acaa0d7d53a2fb231c`（v0.6.5，pinned 2026-06-08 04:59 +08:00）
- 分析角度：spec 治理 / 单一职责 / 编号系统 / 追溯严密度 / 事实自洽 / 可执行性 / 生命周期 / 冗余 / 与 ARCHITECTURE+CONSTITUTION 对齐
- 综合分：**4.7 / 10**

---

## 一、致命级（P0，影响整个体系定位）

### 1. 角色错配 — 本仓库的"分析快照"被写成了"可执行主规格"

- README 第 3 行明确自我定位："**本目录角色：上游规格的本地分析快照，不是上游 SSOT**"。
- 但 SPEC 同时宣称 `Status: Review`、`Spec-Version: v2.0.1`、四级 DoD、37 项 No-Go、生命周期升级路径、CI Gate、Release DoD。
- 矛盾后果：本仓库根本没有 `make`、`goalcli`、`scripts/render_template.sh`、`harness.yaml`、`latest.json`，但 SPEC 把这些当作验收锚点。SPEC §2.2 明确承认"不能单独证明远端、发布或下游仓库的当前状态"——等于自我宣告"可执行 spec"是仪式化的。
- 建议：要么降级为 `ANALYSIS.md`（与 archive/DEEP-ANALYSIS.md 对齐），要么把 SPEC 迁到上游仓库；本仓库只保留索引、追溯锚点与冲突账本。

### 2. God Spec — 单一规格承担六类职责

- §2 自承"6 类职责一身"：Standard Source + Go Reference Template + Generator + Harness + Evidence Runtime + Debt Governance Runtime。
- 6 个相互独立的可交付物被强行塞进 SPEC-TEMPLATE 23 节单文件，导致：
  - FR 数膨胀到 52，§7 被切成 7.1–7.8 八个子表；
  - §11 数据模型混合 Goal Kernel(8) + Harness(14) + Evidence + Adoption + Manifest + 配置拓扑 6 套对象；
  - §23 一节塞进 5.5 层小节（§23.7.5.5）；
- 治本：按职责拆成至少 4 个独立 spec：`xlib-rules`（标准源/规则注册表）、`xlib-template`（生成器+Go 模板）、`goalcli-runtime`（Harness+CLI 契约）、`evidence-runtime`（Evidence + Debt Governance）。

---

## 二、严重级（P1，结构债已被自我承认但未消解）

### 3. 编号系统四套同义并存

SPEC §9.1 已显式承认结构债 S4/S11，但只是用"对外/内部"约定打补丁：

| 体系               | 数量 | 用途          |
| ------------------ | ---- | ------------- |
| BR-001..007        | 7    | 对外引用      |
| IR-001..007        | 7    | 内部分类      |
| TRUTH-001..015     | 15   | 治理真理      |
| RULE-CORE-001..00x | ?    | enforcer 源码 |

加上 RULE 前缀（10 类）、AC（T/I/G/R 4 簇 17 项）、NG（37 项）、TC（17 项）、EC（10+6 项）、OQ（8 项）、R（11 项）、FR（52 项），全文活跃编号空间 **15 套以上**，跨节互引时已出现"BR ↔ IR ↔ TRUTH ↔ RULE-CORE 四向手工映射"——任何一处漂移都需要四处同步，治理成本 O(n²)。

### 4. 自承认"可执行 spec"实际不可执行

- §2.1 列出 6 条"禁止把弱事实升级为强事实"，但 SPEC 自身就是把"分析快照"伪装成"可执行规格"——它是该规则的最大违反者。
- §2.2 明确事实边界，相当于在 spec 顶部主动放弃 release-ready / remote / downstream 三大裁决能力。
- §23.4 仍然写出 37 项 No-Go + manifest 字段（NG-01..NG-37），但 §11.6 的 `latest.json` 在本仓库根本不存在；NG 验证命令清一色 `make ...` / `goalcli ...`，全部位于上游仓库。
- 等于"SPEC 拒绝裁决，但仍维护着裁决标准"，对读者造成误导。

### 5. 附录被强制吸入 §22/§23 — lint 反模式

- REVIEW-VERDICT 显式：lint 禁止 24+ 顶层小节、禁止 `### 24.x`。
- 后果：原附录 A/B/D 全部"并入" §23（注释直白写着"原 §附录 A，2026-06-08 并入 §23"），§23 变成 5 层嵌套的杂项垃圾桶（§23.7.5.4 / §23.7.5.5）。
- lint 形状门禁把"信息组织"当成"形状合规"，逼出 anti-pattern。这条 lint 规则需要为长 spec 增加附录例外，或让 SPEC-TEMPLATE 显式承认附录区。

### 6. 追溯表"100% 覆盖"措辞误导

- TRACEABILITY 顶部声明 `FR 来源覆盖 100% (52/52)`，但表内自承：
  - FR 行级锚点 **49/52**（FR-008 是 file，FR-041/046 是 validator-output）；
  - 5 条 FR 无 TC（FR-001/002/005/046/052），由 gate-level evidence 替代；
  - traceability-check.sh 仍标黄。
- "100% 来源覆盖" + "49/52 行级" + "5 个 FR 无 TC" 三种数字同时存在，外部读者极易把"来源 100%"误读为"语义验证 100%"。CONFLICT-LEDGER 第 19 条（1000-pass）已识别同类风险，但同样的 100% 数字仍在标题处被强调。

---

## 三、设计级（P2，可在保持当前架构的前提下改进）

### 7. 跨节重复定义

| 重复内容                                       | 出现位置                    |
| ---------------------------------------------- | --------------------------- |
| 7 项 xlibgate 硬性失败                         | §13.3、§14.2.1              |
| 必经发布 Gate Chain                            | §21.2、§23.6.1              |
| DONE with evidence 模板                        | §23.2、§23.7.5.5            |
| Manifest 字段 ↔ NG ↔ EvidenceEntry truth_state | §11.5、§11.6、§23.4         |
| 9 条架构原则（无解释）                         | §23.7.4.3 vs §2/§9 散落表述 |
| 6 个禁止状态转换                               | §9.6、§11.7、FR-051         |

### 8. NFR / Config Schema 章节空洞

- §8 NFR 自标"具体阈值待 v1.0.0-rc.1 前压测确认"——结构补齐但无数据。
- §12 Config Schema 自标"自身不暴露生产业务配置，下游模块自定 Schema"——实际只有 5 条声明，没有 schema。
- 这两节在 SPEC-TEMPLATE 中是结构必要项，被用形式占位填充，是 lint 通过 / 实质内容缺失的典型。

### 9. 13 个 consumer 全部 `not_adopted`

- §6 列出 kernel/configx/observex/testkitx/resiliencx/schedulex/redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex 全部 not_adopted，xgo-* 全部 consumer-only。
- 一个"标准源 + 模板 + Harness + Evidence Runtime"在没有任何下游真实采纳的状态下定义自身，是空中楼阁——FR-052（20 PR 下游同步）、FR-018（make integration 渲染 3 个下游）、§22 迁移路径都依赖于一个尚未存在的下游事实基。
- R-009 已记录"13 个下游库全部 not_adopted"为 high risk，但未影响 SPEC Approved 前置条件勾选。

### 10. TC 命名空间裸用

- §17.5 表中 TC-001..017 是"xlib-standard 命名空间"，备注要求下游"必须加模块前缀（如 redisx-TC-001）"。
- 但本 SPEC §14 EC 表的"对应 TC"列、§17.5 自身、TRACEABILITY 里全部用裸 `TC-NNN`，下游模块直接复制粘贴会立即冲突。建议本 SPEC 自己也用 `xlib-TC-001..017`。

### 11. 版本双轨

- `Spec-Version: v2.0.1`（spec 自己的版本）
- `Version: v0.6.x（目标 v1.0.0-rc.1）`（被建模仓库的版本）
- 两个 version 字段并列在元信息中，多次混写（"v0.6.x"、"v1.0.0"、"v2.0.1"），spec 顶部 §1 表已经在同一格内出现两个语义不同的"版本"。

### 12. CONFLICT-LEDGER 22 项中至少 12 项不是 SPEC 内部冲突

- 大量条目（#5 strict-config、#7 adoption、#11 L2 readiness、#12 远端、#13 v1.0.0、#16 154 vs 181、#17 gate 口径、#19 1000-pass、#20 整理 vs 交付、#21 条款 vs 规则、#22 路径）本质是"分析快照 vs 上游现实"差距 + "事实强度等级"约束。
- 这些应放进分析报告或 README"事实边界"段，而不是 spec 的冲突账本。冲突账本应只保留"同一个 SSOT 内部说法之间"的硬冲突，否则被吸到一起会让"22 个冲突已 Resolved"听起来像设计问题已解决，实际是定义边界。

### 13. REMOTE-EVIDENCE 与仓库定位冲突

- README 强调"本仓库不代表上游 SSOT"，但 REMOTE-EVIDENCE.md 用 `gh api` 拉取上游 GitHub branch protection / ruleset / release object，闭合 OQ-001。
- 这是上游仓库的远端治理事实，混在"分析快照"目录下使读者难以判断"OQ-001 在哪个仓库被闭合"。建议在 REMOTE-EVIDENCE.md 顶部明确：本文件是上游仓库的远端证据收集，本目录只是其镜像存档，更新时间戳与上游脱钩需要重新拉取。

---

## 四、量化打分（10 分制）

| 维度                                | 分数         | 说明                                                                       |
| ----------------------------------- | -----------: | -------------------------------------------------------------------------- |
| 结构完整性（23 节、lint 通过）      | 8.0          | 形式合规，REVIEW-VERDICT 已签 APPROVED_FOR_STRUCTURE                       |
| 角色定位清晰度                      | **3.0**      | spec / 分析快照 / 上游 SSOT 三者混淆                                       |
| 单一职责                            | **3.0**      | 6 类职责堆叠                                                               |
| 编号系统一致性                      | 4.0          | 4 套同义 + 15+ 编号空间，靠手工对齐                                        |
| 追溯严密度                          | 6.0          | 100% 来源 ≠ 行级 ≠ TC，措辞口径不齐                                        |
| 事实 / 证据自洽                     | 5.0          | §2.1/2.2 自我承认放弃裁决能力                                              |
| 可执行性（本仓库内可验证）          | **2.0**      | 验证命令几乎全在上游仓库                                                   |
| 生命周期治理                        | 5.0          | 4 项前置条件全勾选仍停 Review                                              |
| 冗余 / 同义控制                     | 4.0          | 至少 6 处跨节重复                                                          |
| 与 ARCHITECTURE / CONSTITUTION 对齐 | 6.5          | §16.1 已对齐五领域，但部分 L0/L1/L2 旧编号仍残留                           |
| **加权综合**                        | **4.7 / 10** | 结构形式合格，但角色错配 + 职责堆叠 + 自我宣告不可执行使实际治理价值打对折 |

---

## 五、最高优先级修复建议

1. **拆分角色**：`SPEC.md` → `ANALYSIS.md`（分析快照）+ `INDEX.md`（上游 SSOT 链接）；真正的可执行 SPEC 迁回上游仓库 `docs/standard/`。
2. **拆 God Spec**：按 6 类职责拆出 4 个独立 spec，每个 ≤ 600 行。
3. **统一编号空间**：废弃 IR 与 RULE-CORE 中的一套；TRUTH 退化为 BR 的同义引用表，不作为独立空间。
4. **修复"100% 覆盖"措辞**：TRACEABILITY 顶部改为 "FR 来源锚定 52/52；其中行级 49、file 1、validator-output 2"。
5. **§23 附录区显式化**：在 SPEC-TEMPLATE 增加"附录子节"约定或放宽 24+ lint 规则；停止把附录硬塞进 §22/§23。
6. **TC 自加前缀**：本 spec 自己改用 `xlib-TC-001..017`。
7. **CONFLICT-LEDGER 减负**：把"分析快照 vs 现实"类条目搬到 README"事实边界"段，账本只保留硬冲突。

---

## 六、结论

结构形式上是仓库内最完整、最严谨的 spec 工件之一；但作为"本仓库的可执行规格"，其底层定位与本仓库（文档枢纽 + 分析索引）不匹配，导致它的"严谨性"大量花在维护一个本仓库无法证明的事实模型上。

综合分 **4.7 / 10**：结构形式合格，但角色错配 + 职责堆叠 + 自我宣告不可执行使实际治理价值打对折。

---

Reviewer: copilot-cli (Claude Opus 4.7)
Timestamp: 2026-06-08T06:02:50+08:00
