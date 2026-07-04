# module/binance REVIEW v3.0 执行方案（20 轮 agent team 独立复现）

> **版本**: v3.0（执行方案层，补全 REVIEW-PROMPT-20260702.md 未落地的 v3.0 增量）
> **生成日期**: 2026-07-04
> **前序方案**: `report/binance/REVIEW-PROMPT-20260702.md`（文件头标注 v2.0.0，1271 行，16 Part × 15 评分维度 × 11 已知陷阱）
> **执行方式**: agent team 20 轮独立并行审查（4 波 × 5 轮），YAML 结构化输出
> **审查对象**: `module/binance/`（spec hub）+ `/home/workspace/binance/`（runtime 仓）
> **输出**: `report/binance/REVIEW-20260704.md`（主报告）+ `REVIEW-20260704-ROUNDS.md`（20 轮明细附录）

---

## 0. v3.0 增量与前序方案差异说明

`[COMPUTED, HIGH]` 前序提交 `d7129e3c`（"新增REVIEW-PROMPT v3.0审查方案（20轮独立复现协议）"）的 commit message 声称升级到 v3.0（1383 行，含 Part 16 新发现核验、20 轮独立复现协议、统一 YAML 输出模板、16 维度评分矩阵），但**实际文件 `REVIEW-PROMPT-20260702.md` 仍是 v2.0.0**（1271 行，文件头标注 `Version: v2.0.0`，内容止于 Part 15，无 Part 16、无 20 轮协议、无 YAML 模板）。

**判定**：commit message 与文件内容不符——v3.0 增量未落地。本执行方案文档补全这些增量，不改动原 v2.0 方案文件（surgical change）。此差异本身作为审查发现 R0-1 记入主报告。

| v3.0 承诺项                                                | 前序文件状态    | 本方案补全位置 |
| ---------------------------------------------------------- | --------------- | -------------- |
| Part 16「DEEP-ANALYSIS-20260704 新发现核验」               | ❌ 缺失         | §3             |
| 20 轮独立复现协议                                          | ❌ 缺失         | §4             |
| 统一 YAML 输出模板                                         | ❌ 缺失         | §5             |
| 16 维度评分矩阵（新增 P.新发现核验完整性）                 | ❌ 仍为 15 维度 | §6             |
| 基线锚点更新（runtime@14a30b9, ZoneCNH@cb7161cc→d7129e3c） | ⚠️ 部分更新     | §1             |

---

## 1. 双仓基线锚点

| 仓                          | 锚点                                         | 说明                                                                                              |
| --------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| ZoneCNH（spec hub）         | `main@d7129e3c`                              | "新增REVIEW-PROMPT v3.0审查方案"提交；本审查 feature 分支 `docs/binance-review-20260704` 由此创建 |
| binance（runtime）          | `origin/main@14a30b9`                        | "fix(server): 规范regexp与错误链包装 (#414)"；DEEP-ANALYSIS-20260704 同锚点                       |
| DEEP-ANALYSIS-20260704 报告 | 合并于 `b35b158e`，十轮自审修正于 `cb7161cc` | 本审查 Part 16 独立复现其 N1-N7 与 3 处修正                                                       |

**独立复现纪律**：每轮 agent 必须以本锚点为准，禁止转述 DEEP-ANALYSIS-20260704 或其他 reviewer 结论；所有"已确认"结论必须本会话重新 grep/read 核验，标注 `[COMPUTED]`。

---

## 2. 审查范围与制品盘点

spec hub 制品（`module/binance/`）：spec/{SPEC,client/SPEC,server/SPEC,ACCEPTANCE,FEATURES,NAMING,CONTRIBUTING}.md、matrix/{TRACEABILITY,client/TRACEABILITY,server/TRACEABILITY}.md、design/{DESIGN,DEEP-ANALYSIS,ADR-001~005,CONFIG-SCHEMA,PERSISTENCE-WIRING,RUNTIME-MAPPING,ARCHITECTURE-DRIFT-WATCHLIST,TIER-DESIGN-DETAILS,STRUCTURAL-SCORING}.md、gate/{RULES,STANDARD,BOUNDARY-GATES,SECURITY,OBSERVABILITY,OPERATIONS}.md、tasks/{ROOT×7,client×18,server×18}、plan/{PLAN,client/PLAN,server/PLAN}.md、goal/goal.md、prompt/、evidence/（2026-06-26~07-03）、README.md、CHANGELOG.md、STANDARD.md、SECURITY.md、TRACEABILITY.md、todo.md、ci-workflow.yaml。

runtime 制品（`/home/workspace/binance`）：cmd/{binance-client,binance-server,binance-smoke}、internal/{client,server,wire}、pkg/{binancecfg,binancex}、migrations/、.github/workflows/（12 个）。

---

## 3. Part 16：DEEP-ANALYSIS-20260704 新发现独立复现【v3.0 新增】

> 前序报告 `report/binance/DEEP-ANALYSIS-20260704.md` 提出 N1-N7 七项新缺口 + 3 处自审修正。本 Part 要求 agent **独立复现**，不得转述。

### 3.1 N1-N7 缺口独立核验矩阵

| #   | 类别         | 一句话                                                                                 | 独立复现命令                                                                                                                                                                    | 预期（若仍成立）                           |
| --- | ------------ | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ | --------------------------------------- |
| N1  | 编译阻断     | `storageAssembly` 缺 `runtime` 字段致 origin/main 编译失败                             | `cd /home/workspace/binance && git stash -u && git checkout origin/main && go build ./... 2>&1                                                                                  | grep storageAssembly; git checkout -`      | `storage.go:313: unknown field runtime` |
| N2  | 消息投递     | client 发布 5 段 subject vs server 订阅 4 段，NATS `*` 精确匹配 1 token 致结构性不匹配 | `grep -n "binance.market" /home/workspace/binance/internal/client/publisher/publisher.go; grep -rn "FilterSubject\|Subjects" /home/workspace/binance/internal/server/consumer/` | client 5 段 `.*.*.v1` vs server 4 段 `*.*` |
| N3  | 数据可靠性   | `MarkDurable()` 先于 `storage.persist()`，落库失败后重投被当重复 Ack                   | `grep -n "MarkDurable\|persist" /home/workspace/binance/internal/server/ingest.go`                                                                                              | MarkDurable 调用先于 persist               |
| N4  | 运行时产品线 | runtime 只 `NewSpotConnector`，UM/CM/Options 未启动                                    | `grep -n "NewSpotConnector\|NewUM\|NewCM\|NewOptions" /home/workspace/binance/internal/client/runtime.go`                                                                       | 仅 Spot                                    |
| N5  | 可观测性口径 | OLAP 数据源实为进程内存 10min 窗口                                                     | `grep -n "memory\|window\|10" /home/workspace/binance/internal/server/assembly/olap_source.go`                                                                                  | 内存窗口                                   |
| N6  | 存储覆盖     | TaosWriter 仅支持 trade/tick/bar，funding_rate/mark_price 返回 ErrUnsupportedEventType | `grep -n "ErrUnsupportedEventType\|case " /home/workspace/binance/internal/server/storage/taos_writer.go`                                                                       | 不支持 funding/mark                        |
| N7  | 运维覆盖     | Retention 硬编码 `ProductLine:"spot"`                                                  | `grep -n "ProductLine" /home/workspace/binance/internal/server/assembly/storage.go`                                                                                             | 仅 spot                                    |

### 3.2 三处自审修正独立核验

| 修正项 | 前序原判 → 修正后判定                                                     | 独立复现方法                                                                                                                                                                                                |
| ------ | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| 修正①  | N2 从"待验证风险"→"已确认缺陷"（NATS `*` 语义）                           | 验证 NATS 通配符语义：`*` 匹配 1 token，`>` 匹配多段；4 段 pattern 结构性无法匹配 5 段 subject                                                                                                              |
| 修正②  | token 命名"漂移"→文档覆盖缺口（API_TOKEN 与 ADMIN_TOKEN 是不同令牌）      | `grep -rn "API_TOKEN\|ADMIN_TOKEN" /home/workspace/binance/pkg/binancecfg/config.go /home/workspace/binance/internal/server/api/query.go`；确认二者独立 + `grep -c admin module/binance/gate/SECURITY.md`=0 |
| 修正③  | release_closeable 矛盾从"跨文档不一致"→"TRACEABILITY.md 文件内部自相矛盾" | 读 `module/binance/matrix/TRACEABILITY.md`：顶部 L8 `release_closeable: YES` vs L96 `PRG-006                                                                                                                | Partial`，按 L84 公式（需全 PASS）推导应=NO |

---

## 4. 20 轮独立复现协议【v3.0 新增】

1. **固定基线快照**：所有轮次以 §1 锚点为准，审查期间若 `git log HEAD..origin/main` 非空需在 YAML 标注漂移
2. **禁止假设其他 reviewer 结论**：每轮 agent 独立 grep/read，不得引用"上一轮发现"
3. **统一 YAML 输出**：按 §5 模板，供汇总方机械解析与去重
4. **独立复现 ≠ 重复转述**：前序报告/DEEP-ANALYSIS 的结论必须本会话重新验证，标注 `[COMPUTED]` + 实际命令输出
5. **反奉承红旗**：100% Done / 满分 / "全 PASS" 项需额外质疑（R4）
6. **不知道时第一行写 `我不知道。`**，置信度 UNKNOWN
7. **失败不删除**：grep 无命中也是有效证据，标注实际输出

---

## 5. YAML 结构化输出模板【v3.0 新增】

```yaml
round: <N> # 1-20
wave: <W> # 1-4
dimension: <维度名>
reviewer: <agent label>
anchor:
  zonecnh: d7129e3c
  runtime: 14a30b9
  drift: <git log HEAD..origin/main --oneline | wc -l, 0=无漂移>
coverage:
  parts_covered: [Part1, ...]
  traps_verified: [T0-1, T7-1, ...]
  files_read: [path, ...]
  commands_run: [cmd, ...]
findings:
  - id: R<N>-F<序号>
    severity: P0|P1|P2|P3|INFO
    category: <编译|路由|状态分裂|计数|版本|安全|证据|边界|...>
    title: <一句话>
    evidence: <file:line 或命令输出原文>
    description: <详细>
    recommendation: <修复建议>
    epistemic:
      {
        label: KNOWN|COMPUTED|INFERRED|FRAME|GUESS,
        confidence: HIGH|MED|LOW|VERY_LOW|UNKNOWN,
      }
traps: # 本轮验证的陷阱，无则省略
  T0-1: { status: CONFIRMED|REFUTED|CHANGED, evidence: <...> }
new_findings: # N1-N7 核验，仅轮12 填，无则省略
  N1: { status: CONFIRMED|REFUTED|CHANGED, evidence: <...> }
score:
  dimension_scores: { A: <0-100>, B: <...>, ... }
  deductions: [{ dim: A, points: <N>, reason: <...> }]
gaps: <本轮未覆盖/建议下轮补的，无则 none>
rules_broke: NONE|<列出违反规则>
```

---

## 6. 16 维度评分矩阵【v3.0 扩展】

在 v2.0 的 A-O 15 维度基础上新增 **P. 新发现核验完整性**（满分 100）：

| 维度                    | 满分 | 说明                                   |
| ----------------------- | ---- | -------------------------------------- |
| A. Spec 结构完整性      | 100  | 23 节 + 子模块 + NAMING + 行数门禁     |
| B. 追溯矩阵闭合         | 100  | §1-§7 + R1 跨表走查 + 仪表盘自动统计   |
| C. Design 架构质量      | 100  | DESIGN + ADR×5 + DRIFT-WATCHLIST       |
| D. Runtime 代码质量     | 100  | 编译 + 测试 + 覆盖率 + 规范            |
| E. Client/Server 边界   | 100  | 边界违规 + 死代码 + panic              |
| F. 测试与验证           | 100  | 覆盖率 + race + 安全扫描               |
| G. CI/CD 管线           | 100  | 12 workflow + runner + 门禁            |
| H. 安全与合规           | 100  | gitleaks + govulncheck + CSRF + 凭证   |
| I. 可观测性             | 100  | metrics/logs/traces + SLO              |
| J. 生产就绪 (L3)        | 100  | PRG-001~007 + 双口径                   |
| K. 文档一致性           | 100  | 版本 + Runtime-Version + FR总数 + 链接 |
| L. 运行时缺口覆盖       | 100  | 58 缺口 + 漏洞链 + MVP                 |
| M. EXCHANGEINFO 分级    | 100  | Tier/Priority 零支撑                   |
| N. 双口径治理           | 100  | 规格48Done vs 运行时58Fixed 正交性     |
| O. 证据可信度           | 100  | PRG证据 + GAP-E引用 + 免责声明         |
| **P. 新发现核验完整性** | 100  | **N1-N7 独立复现 + 3 修正核验**        |
| **加权综合**            | 100  | 16 维度等权平均                        |

### 双口径评分

| 口径             | 得分              | 含义                                         |
| ---------------- | ----------------- | -------------------------------------------- |
| 规格口径综合分   |                   | FR 功能面闭合度                              |
| 运行时口径综合分 |                   | 生产部署实际健康度（受 N1-N7 + 58 缺口影响） |
| **发布判定分**   | min(规格, 运行时) | 保守取低值                                   |

---

## 6. 20 轮编排分配表

### Wave 1（轮 1-5）：制品完整性层

| 轮  | 维度           | 对应 Part | 独立复现陷阱   | 核心审查项                                                                              |
| --- | -------------- | --------- | -------------- | --------------------------------------------------------------------------------------- |
| R1  | Spec Hub       | Part1     | T1-1           | 23节完整性+子模块SPEC+FEATURES/ACCEPTANCE+NAMING+行数门禁+双口径声明+CHANGELOG版本      |
| R2  | 追溯矩阵       | Part2     | T2-1           | TRACEABILITY §1-§7+追溯链闭合+子模块对齐+§6仪表盘自动统计+GAP-E引用回填                 |
| R3  | 架构设计       | Part3     | -              | DESIGN+ADR-001~005+DRIFT-WATCHLIST D1-D11+Runtime架构+EXCHANGEINFO分级零支撑            |
| R4  | 计划任务Prompt | Part4-5   | T4-1           | PLAN §1-§8+Task覆盖+Task计数矛盾(39vs47)+Plan-Task一致性+Prompt目录                     |
| R5  | 文档一致性     | Part8     | T8-1/T8-2/T8-3 | 14文档版本一致性+Runtime-Version分裂+FR总数+链接有效性+SECURITY/CONTRIBUTING缺失+BR缩减 |

### Wave 2（轮 6-10）：运行时与发布层

| 轮  | 维度           | 对应 Part | 独立复现陷阱 | 核心审查项                                                                                    |
| --- | -------------- | --------- | ------------ | --------------------------------------------------------------------------------------------- |
| R6  | 代码质量       | Part6     | -            | go build/vet/test/race+覆盖率80%+gitleaks/govulncheck+boundary-gates+单文件行数+GAP-E抽样源码 |
| R7  | 发布就绪       | Part7     | T7-1/T7-2    | PRG-001~007+PRG-006矛盾+release_closeable六源交叉+tag/Release/DEPLOY+双口径判定+L3            |
| R8  | 证据体系       | Part9     | T9-1         | Evidence目录+PRG证据闭环+TEST-ANALYSIS免责声明+GAP-E引用断链                                  |
| R9  | 治理合规       | Part10    | T10-1        | CONSTITUTION §0/4/10/14/20+管线S0-S11+registry.yaml+FOUNDATION-DEPS+ci-workflow               |
| R10 | 运行时缺口矩阵 | Part11    | -            | 58缺口总览+P0源码验证+15漏洞链抽样+MVP路径+双口径正交性                                       |

### Wave 3（轮 11-15）：对抗性与新发现层

| 轮  | 维度              | 对应 Part            | 独立复现陷阱             | 核心审查项                                                                                     |
| --- | ----------------- | -------------------- | ------------------------ | ---------------------------------------------------------------------------------------------- |
| R11 | 对抗性反审查      | Part12               | 全陷阱总表               | Spec/Matrix/Code反审查+11陷阱总表+反向验收Code→Spec+4转换损耗点                                |
| R12 | N1-N7新发现核验   | Part16               | N1-N7+3修正              | 独立复现7项新缺口+3处自审修正，禁止转述DEEP-ANALYSIS结论                                       |
| R13 | 陷阱T0/T1/T2复现  | Part0.1/1.7/2.5      | T0-1/T1-1/T2-1           | Runtime-Version四处+CHANGELOG v3.9.7 vs SPEC v3.9.6+evidence GAP-E引用                         |
| R14 | 陷阱T7/T8复现     | Part7.2/8.2/8.6/8.7  | T7-1/T7-2/T8-1/T8-2/T8-3 | PRG-006矛盾+shallow clone无tag+Runtime-Version分裂+根SECURITY/CONTRIBUTING+BR缩减9→5           |
| R15 | 陷阱T9/T10+一致性 | Part9.3/10.3+CLAUDE5 | T9-1/T10-1               | TEST-ANALYSIS免责+registry.yaml+模块内部一致性5.1-5.4(TRACEABILITY §1vs§6/附录版本/DoD/跨文件) |

### Wave 4（轮 16-20）：遗漏检查与汇总层

| 轮  | 维度              | 对应 Part           | 独立复现陷阱 | 核心审查项                                                                       |
| --- | ----------------- | ------------------- | ------------ | -------------------------------------------------------------------------------- |
| R16 | 数量验证门禁      | CLAUDE数量门禁      | -            | STATUS/README/ARCHITECTURE三文档同步+组件数+版本数+CountGuard+audit-status.py    |
| R17 | 认识论标准§20     | CONSTITUTION§20     | -            | 证据标签[KNOWN]/[COMPUTED]/[INFERRED]使用+置信度+反奉承红旗+FRAME→REALITY误用    |
| R18 | CHANGELOG版本追溯 | Part1.7+8.1深化     | T1-1深化     | Module-Version vs Spec-Version vs Runtime-Version vs tag vs Release 五源全量对齐 |
| R19 | evidence时效性    | Part9深化           | -            | 2026-06-26~07-03日期目录+PRG证据时效+过期证据+缺失证据+07-01目录缺失             |
| R20 | 全量遗漏检查      | completeness critic | 全覆盖核验   | 16 Part全覆盖+11陷阱全验证+N1-N7全核验+20轮新角度+未覆盖维度补扫                 |

---

## 7. 汇总与报告

汇总方（Lead）收集 20 份 YAML 后：

1. **去重合并**：相同 finding 按 `file:line + category` 去重，保留最高 severity
2. **陷阱交叉投票**：每陷阱 ≥2 轮验证，多数判定（CONFIRMED/REFUTED/CHANGED）
3. **N1-N7 投票**：每项 ≥1 轮独立复现，标注实际命令输出
4. **评分聚合**：16 维度取各轮中位数，双口径分别计算
5. **输出**：`REVIEW-20260704.md`（主报告，按 v2.0 方案 15 节结构 + §16 新发现核验）+ `REVIEW-20260704-ROUNDS.md`（20 轮 YAML 明细）

---

## 8. 审查原则（继承 v2.0 + v3.0 增强）

1. 消除信息差：验证前确认基线，禁止凭记忆假设
2. 发现问题即标注：不先分类再等指令
3. 跨表走查：遍历 TRACEABILITY §1-§5
4. 证据驱动：每判定绑定 file:line/命令输出
5. 反奉承：100% Done/满分需额外质疑
6. 双口径分离：规格 vs 运行时独立评分，发布取低值
7. 已知陷阱优先：T0-1~T10-1 共 11 项须逐一独立复现
8. **【v3.0】独立复现**：禁止转述前序报告结论，必须本会话重新验证
9. **【v3.0】YAML 输出**：统一模板供机械解析
10. **【v3.0】遗漏检查**：R20 completeness critic 兜底全覆盖

---

**[RULES I BROKE]**：NONE — 本方案为规划文档，证据标签用于基线确认事实（commit message 与文件不符已 `[COMPUTED]` 核验：`git show d7129e3c` commit message 称 v3.0/1383行，`wc -l REVIEW-PROMPT-20260702.md`=1271，`head -3` 文件头=`v2.0.0`）。
