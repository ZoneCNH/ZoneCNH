# xlib-standard 结构性问题深度分析与评分

分析对象：`module/xlib-standard/`
分析时间：2026-06-08
结论状态：`Changes requested`
结构健康分：**68/100**

## 评分口径

| 维度                 | 分值 | 得分 | 主要依据                                                                                                   |
| -------------------- | ---: | ---: | ---------------------------------------------------------------------------------------------------------- |
| 文档骨架与渲染完整性 | 25   | 16   | 23 个一级编号章节已对齐，但存在错误代码围栏、陈旧小节编号和陈旧行数统计。                                  |
| 状态与事实权威一致性 | 20   | 12   | `SPEC.md`、`README.md`、`REMOTE-EVIDENCE.md` 和 `REVIEW-VERDICT.md` 对远端治理与评审状态的说法不完全一致。 |
| 追溯证据质量         | 25   | 15   | 154 输入范围和 FR 矩阵已经建立，但“100% line-level coverage”混入文件存在、目录存在和委托校验。             |
| 可复现与审计封装     | 15   | 14   | commit/tree、文件清单和 sha 前缀较完整；缺口在外部下载包、原始远端 API 证据和完整 source pack。            |
| 可维护性与分层边界   | 15   | 11   | 当前包把规范、发布状态、PR 包清单、目标运行时和审计账本压进同一主规格，维护成本偏高。                      |

总体判断：`module/xlib-standard/` 已经不是早期松散草案，材料量、冲突账本和远端证据都比较充分；但它的结构性风险集中在“可渲染性、状态单一权威、追溯声明精度”三件事上。只要这些问题未修复，不宜把当前包标成 `Approved`。

## 主要结构性问题

### P0-1 Markdown 围栏闭合方式错误，影响渲染和机器校验

证据：

- `module/xlib-standard/SPEC.md` 多处把闭合围栏写成带 info string 的形式，例如第 798/800 行成对出现 `text` 围栏，第 857/928 行从 `gotemplate` 开始但用 `text` 闭合，第 942/952、980/989、1013/1036、1594/1604、2049/2059 行也有同类问题。
- `module/xlib-standard/COVERAGE-MANIFEST.md` 第 228/383 行也使用了带 `text` 的闭合围栏。

影响：

- CommonMark 规则下，闭合围栏不能带 info string。渲染器可能把后续章节、表格和编号继续吞进代码块。
- 任何基于 Markdown AST 的章节计数、表格检查、追溯提取和 lint 结果都可能不可信。

修复建议：

- 将所有闭合围栏统一改成裸三反引号。
- 在结构 lint 中加入“围栏闭合必须无 info string”的硬规则。
- 修复后重新跑章节计数、表格解析和追溯矩阵检查。

### P0-2 追溯矩阵把不同粒度的证据混称为 line-level coverage

证据：

- `module/xlib-standard/README.md` 第 17-21 行把 `TRACEABILITY.md` 描述为 52 条 FR 的 100% 行级覆盖。
- `module/xlib-standard/TRACEABILITY.md` 第 13-16 行又声明它只是 clause-level source matrix，不是每条规则的 proof ledger。
- `TRACEABILITY.md` 第 103 行的 FR-008 证据是 `docs/adr/ADR-*.md` 和“10 个文件存在”。
- `TRACEABILITY.md` 第 136 行的 FR-041 证据是 `.worktree/goal/` 目录与目标文件列表。
- `TRACEABILITY.md` 第 141 行的 FR-046 证据是目录内 PR pack 数量与一个示例行，且把逐文件锚委托给 `goalcli pr-pack-check`。
- `module/xlib-standard/REVIEW-VERDICT.md` 第 45-46 行仍把“line coverage claim false / not 100% line-level”列为 P0。

影响：

- 当前矩阵能证明“每条 FR 有来源或来源集合”，但不能按现有措辞证明“每条 FR 都有可审计行级锚点”。
- 评审者无法区分行锚、文件存在、目录成员关系、生成脚本输出和外部校验器之间的证据强度。

修复建议：

- 在 `TRACEABILITY.md` 增加 `anchor_type`：`line`、`file`、`directory`、`validator-output`、`external`。
- 只有 `line` 才计入 line-level coverage；其他类型应单独统计。
- 对委托给 `goalcli` 的 FR 附上命令输出、输入清单和失败阈值。
- README 中把“100% 行级覆盖”改成更精确的分层覆盖声明，直到所有 FR 都具备行级锚点。

### P1-3 状态权威分裂，读者无法判断当前是否已满足批准前提

证据：

- `SPEC.md` 第 5-18 行显示版本 `v2.0.1`、状态 `Review`，并写明远端证据与 FR 覆盖已关闭，但独立评审者尚未签署。
- `SPEC.md` 第 103-114 行仍说 GitHub branch protection / ruleset 未配置，治理分数因此停在 8.5/10。
- `SPEC.md` 第 1854-1861 行又把 `OQ-001` 标为已由 `REMOTE-EVIDENCE.md` 关闭。
- `REMOTE-EVIDENCE.md` 显示分支保护、ruleset、CI、release tag 和 required reviews 已有远端证据。
- `REVIEW-VERDICT.md` 第 6-7 行的结论仍是 `CHANGES_REQUESTED`。

影响：

- 同一包内同时存在“远端治理缺失”和“远端治理已关闭”的叙述。
- `README.md` 把当前 artifacts 标成权威入口，但评审 verdict 还停在 changes requested，导致入口文件与评审文件冲突。

修复建议：

- 设一个单一状态表作为权威，例如 `REVIEW-VERDICT.md` 或新增 `STATUS.md`。
- `SPEC.md` 只引用该状态表，不内嵌容易过期的远端治理结论。
- 每次远端证据刷新后同步更新 pain points、open questions、review verdict 和 README 摘要。

### P1-4 主规格明显膨胀，并出现模板编号漂移

证据：

- `docs/governance/SPEC-TEMPLATE.md` 和相邻规格 `module/kernel/SPEC.md`、`module/configx/SPEC.md`、`module/xlibgate/SPEC.md` 都保持约 500-600 行。
- `module/xlib-standard/SPEC.md` 当前约 2061 行，是相邻规格的 3-4 倍。
- `SPEC.md` 第 1889-1893 行在 `### 23.4` 下出现 `#### 28.4.1`。
- `SPEC.md` 第 1957-1961 行在 `### 23.5` 下出现 `#### 28.5.1`。
- `SPEC.md` 第 1965-1966 行仍写主 artifacts 合计 2,598 行、`SPEC.md` 2013 行，与当前文件行数不一致。
- `SPEC.md` 第 1878 行已经把 spec bloat 列为风险，并建议拆分 PR packs 与 goalcli 命令列表。

影响：

- 模板骨架虽然表面上仍有 23 个编号章节，但内部小节编号从旧模板或旧生成物泄漏出来。
- 主规格承载太多一次性发布状态和执行清单，后续每次远端状态、PR 包或命令数量变化都会污染规范主体。

修复建议：

- 保留 `SPEC.md` 作为稳定规范与验收准则。
- 将 PR pack 清单、goalcli 命令覆盖、release gate 和 key figures 移到独立运行账本。
- 增加 lint：禁止 `#### 28.` 这类越界小节出现在第 23 章；禁止陈旧 line-count/key-figure 文本。

### P1-5 规范性内容和发布执行状态混在一起

证据：

- `SPEC.md` 第 963-976 行列出 goalcli P0/P1/P2 命令，并记录还有 5 个命令待实现。
- `SPEC.md` 第 1052-1058 行把 Proof Runtime 四平面完成度写成 88-92%，还记录 PR 未完全提交。
- `SPEC.md` 第 1624-1780 行维护 37 条 No-Go 阻断项。

影响：

- 这些内容更像 release readiness dashboard，而不是长期稳定的标准规格。
- 执行状态会快速过期，导致 `SPEC.md` 需要频繁重写，也会让“规范要求”和“当前实现进度”互相污染。

修复建议：

- 把稳定要求留在 `SPEC.md`。
- 把 No-Go 阻断、命令实现状态、PR pack 状态迁移到 `RELEASE-GATE.md` 或 `IMPLEMENTATION-STATUS.md`。
- 让 `TRACEABILITY.md` 追踪规范条款，不追踪临时执行状态。

### P2-6 可复现证据还没有完全封装成便携 source pack

证据：

- `COVERAGE-MANIFEST.md` 第 13-16 行说明 external Downloads 是本地外部规划文档，不属于当前 git tracking。
- `COVERAGE-MANIFEST.md` 第 53-55 行明确说当前清单不是 portable source bundle。
- `COVERAGE-MANIFEST.md` 第 362-382 行列出了外部下载文件 sha 前缀，但不是完整 source archive。
- `CONFLICT-LEDGER.md` 第 21-22 条也把 clause-level trace 与 portable source bundle 作为边界问题记录。

影响：

- 本机可以复核输入集合，但独立评审者未必能在另一台机器上重建同样的 154 输入环境。
- 远端 API 证据有时间性；如果没有原始 JSON 和采集命令输出，后续只能相信摘要。

修复建议：

- 为 154 输入生成完整 source pack manifest：相对路径、完整 sha256、来源类型、采集时间、是否 git-tracked。
- 将 `gh api` 的原始 JSON 或规范化摘要纳入 `REMOTE-EVIDENCE.md` 的附录或独立 evidence bundle。
- 把 external Downloads 的来源 URL、采集时间和完整 hash 补齐。

### P2-7 结构校验工具没有覆盖当前暴露出的不变量

证据：

- `REVIEW-VERDICT.md` 第 28-31 行指出 spec-lint 只检查到 23 个编号章节，没有抓到额外顶层 H2。
- `REVIEW-VERDICT.md` 第 55 行再次指出 spec-lint 不禁止 extra H2。
- 当前扫描显示，围栏闭合错误、`28.x` 小节漂移、陈旧 key figures 和追溯粒度混称也没有被自动阻断。

影响：

- 现有校验更像格式抽样，不足以守住这个规格包真正依赖的结构契约。
- 后续生成或人工编辑仍可能反复引入同类结构漂移。

修复建议：

- 将以下规则纳入 CI 或本地 lint：Markdown 围栏合法性、23 章编号、越界小节编号、陈旧行数、trace anchor type、review verdict 与 README 摘要一致性。
- lint 失败时禁止把包状态推进到 `Approved`。

## 保留的正向结构

- `README.md` 已经把本目录界定为 local analysis snapshot，而非上游 SSOT。
- `COVERAGE-MANIFEST.md` 固定了 154 个输入与上游 commit/tree。
- `REMOTE-EVIDENCE.md` 单独收敛远端 API、CI、release 和 branch protection 证据。
- `CONFLICT-LEDGER.md` 明确记录了本地文件无法证明远端状态、1000-pass 不能证明语义正确、source pack 仍不便携等边界。
- 主规格目前仍可识别 23 个编号章节，说明骨架没有完全失控。

## 建议修复顺序

1. 先修复所有 Markdown 围栏闭合错误，并用 AST 或 markdownlint 复验。
2. 建立单一状态权威，统一 `README.md`、`SPEC.md`、`REMOTE-EVIDENCE.md`、`REVIEW-VERDICT.md` 的结论。
3. 重构 `TRACEABILITY.md` 的证据粒度，把 line-level、file-level、directory-level 和 validator-output 分开计数。
4. 从 `SPEC.md` 拆出 release dashboard、No-Go 阻断、goalcli 命令覆盖和 PR pack 清单。
5. 发布便携 evidence/source pack，补齐外部下载与远端 API 原始证据。
6. 扩展 lint 规则，再生成新的 independent review verdict。

## 通过标准

当前包达到以下条件后，结构健康分可提升到 85 分以上：

- `SPEC.md` 和 `COVERAGE-MANIFEST.md` 不再存在错误闭合围栏。
- `SPEC.md` 不再出现 `28.x` 这类越界小节编号，也不再包含陈旧行数统计。
- 所有状态结论只从一个权威状态表派生。
- `TRACEABILITY.md` 的 52 条 FR 都有明确 evidence type，且 README 不再把非行级证据计入 line-level coverage。
- 外部下载与远端证据可由独立评审者在干净环境中重放。
- `REVIEW-VERDICT.md` 从 `CHANGES_REQUESTED` 更新为与当前证据一致的结论。
