# ZoneCNH 25 模块完整修复与生产重新认证计划 —— 最终修复计划文档结构

> <!-- 从 07-11.md 与 07-11-analysis.md 提取 -->
> 版本：v1.0-plan-structure
> 日期：2026-07-11
> 目标：将 25 模块从"版本、CI、Evidence 与实现事实不一致"修复为可验证、可发布、可被真实消费者采用的生产级模块。
> 基准报告：`report/07-11.md`（原计划）、`report/07-11-analysis.md`（深度分析）、`report/foundation-production-readiness-deep-analysis-20260711.md`（深度审计）

---

## 文档导航图

<!-- 意图：提供全文档的章节依赖关系图，帮助读者理解阅读顺序和章节间引用 -->
<!-- 内容：Mermaid DAG 或表格，标注每章的前置阅读章节 -->

---

## 第零章：执行摘要

<!-- 意图：一句话概括目标，展示关键数字，列出与原计划的核心差异，为决策者提供一分钟全景 -->
<!-- 内容来源：07-11.md §0 §9、07-11-analysis.md §1 §2 -->

### 0.1 一句话目标

<!-- 一句话描述本计划的最终交付目标 -->

### 0.2 关键数字

<!-- 从分析报告提取：
  - 模块总数：25（07-11.md §7.2）
  - 波次数：W0-W6，压缩为 4 Phase（07-11-analysis.md §2.1 修正后）
  - 总预估时间：60-75 天（07-11-analysis.md §2.1）
  - 并行人数：待填充
  - CONDITIONAL 模块数：7（foundation-production-readiness 审计 §3.2）
  - NO-GO 模块数：18（同上）
  - GO 模块数：0（同上）
-->

### 0.3 与原计划的核心差异

<!-- 逐条列出与原计划（07-11.md）的关键差异：
  - 时间线：30 天 → 60-75 天（07-11-analysis.md §2.1）
  - 修复顺序：优先修"判断系统"（07-11.md §11）
  - 波次重映射：W0-W6 原文 → Phase 0-4 压缩版（本报告 §二章）
  - 新增 governance 矛盾裁决（07-11-analysis.md §2.2）
  - 新增 P0 修复实施追踪（07-11-analysis.md §九）
-->

---

## 第一章：修复全景

<!-- 意图：给出全 25 模块的当前状态和修复波次总览，让读者在深入细节前建立全局认知 -->

### 1.1 当前状态评估

<!-- 意图：按模块等级（标准/L0/L1/存储/契约/L2.5）分类展示当前裁决 -->
<!-- 内容来源：foundation-production-readiness-deep-analysis-20260711.md §3.2 -->

#### 1.1.1 总表

<!-- 表格：Module | Layer | Code/Test Status | Release Baseline | Verdict | Top Blocker
     每行数据来自 foundation-production-readiness 审计 §3.1 -->

#### 1.1.2 CONDITIONAL 模块 (7)

<!-- 列表：包含 configx、observex、resiliencx、schedulex、postgresx、decimalx、domainx -->
<!-- 注：这些模块已有可消费版本但当前 HEAD 不可发布 -->

#### 1.1.3 NO-GO 模块 (18)

<!-- 列表：按层级分组，标注最高阻断原因 -->

#### 1.1.4 系统性红线汇总

<!-- 内容来源：foundation-production-readiness 审计 §4
  - 成熟度事实层过度声明（§4.1）
  - 6 个 Go module identity 不一致（§4.2）
  - Go baseline 三源冲突（§4.3）
  - 发布血缘普遍失真（§4.4）
  - CI 假绿（§4.5）
  - 分支保护与 Release evidence 未闭合（§4.6）
-->

### 1.2 修复波次总览

<!-- 意图：从原计划 W0-W6 压缩映射到 Phase 0-4，给出每阶段的时间窗口和核心产出 -->
<!-- 内容来源：07-11.md §2.1 + 07-11-analysis.md §2.1 修正 -->

| Phase | 原波次映射 | 时间窗口     | 核心产出                           | 涉及模块数 |
| ----- | ---------- | ------------ | ---------------------------------- | ---------- |
| 0     | W0         | Day 1-2      | 事实冻结与治理审计                 | 25         |
| 1     | W1-W2      | Day 3-21     | 控制平面修复 + 三 canary 验证      | 7          |
| 2     | W3         | Day 22-45    | L1 与 Assembly 基础修复            | 7          |
| 3     | W4-W5      | Day 46-60    | 存储、领域与传输修复               | 13         |
| 4     | W6         | Day 61-75    | 全舰队认证与收尾                   | 25         |

### 1.3 全局执行规范

<!-- 意图：定义所有阶段共同遵守的分支、PR、发布约束，确保一致性 -->
<!-- 内容来源：07-11.md §1 -->

#### 1.3.1 分支与工作区

<!-- 规则：/home/workspace/{module} 只 clean main checkout；
          每个工作包独立 worktree；
          分支从 origin/main 创建；
          release/preflight 强制 GOWORK=off 等 -->

#### 1.3.2 PR 规范

<!-- 每 PR 一个可回滚目标、强制输出 9 项（Goal ID、scope、API diff、AC/TC、machine results、class results、Evidence、SemVer、rollback） -->

#### 1.3.3 工作包状态

<!-- 状态机：BLOCKED → READY → IN_PROGRESS → VERIFIED → RELEASED → QUALIFIED -->

#### 1.3.4 Release Tuple

<!-- 18 项 release tuple 完整列表，来源：07-11.md §0 final ruling -->

---

## 第二章：阶段路线图

<!-- 意图：按 5 个 Phase 详细展开，每节包含目标、进入/退出条件、活动清单、关键路径节点和风险标记 -->

### 2.0 Phase 0 — 事实冻结与治理审计

#### 2.0.1 目标

<!-- 冻结所有虚假声明；输出 25 仓 inventory；建立可验证的事实基线 -->

#### 2.0.2 进入条件

<!-- 计划批准即可进入 -->

#### 2.0.3 活动清单

<!-- 从 07-11-analysis.md §九 P0 修复建议提取：
  1. 全仓 status projection 事实审计（P0-5）
  2. domain_macro 标为 missing、禁止新 factory 声明
  3. 输出 25 仓 identity/version/tag/required-check inventory
  4. 冻结 Go 1.26.5 目标与 module profile schema
  5. goalcli 归属裁决（P0-1）
  6. transportx go module major path 裁决（P0-2）
  7. contracts git tag lineage 审计与版本裁决（P0-3）
-->

#### 2.0.4 退出条件

<!-- - 所有 NO-GO 模块的 factory/release claim 不再虚报
  - 25 仓 inventory 可验证、无矛盾
  - 三条治理矛盾全部裁决完成
  - Go baseline SSOT 单一事实
  - 无新的 factory 声明在证据未闭环时产生 -->

#### 2.0.5 关键路径节点

<!-- - Day 1: inventory 生成
  - Day 2: 三条裁决完成、状态冻结 -->

#### 2.0.6 风险标记

<!-- - 裁决依赖模块 owner 反馈
  - domain_macro 治理信任崩塌的连锁影响（07-11-analysis.md §2.4） -->

---

### 2.1 Phase 1 — 控制平面与 Canary 验证

#### 2.1.1 目标

<!-- 修复标准四仓（xlib_standard/xlibgate/xlib_evidence/xlib_harness）的职责边界与可运行性；
     建立三类 canary（kernel/decimalx/redisx）验证控制平面正确性；
     产出 stable 标准发布 -->

#### 2.1.2 进入条件

<!-- - Phase 0 退出条件全部满足
  - Go baseline SSOT 共识
  - 标准四仓 identity inventory 完成 -->

#### 2.1.3 活动清单

<!-- 按 07-11.md §3 展开，分两个子阶段：

  子阶段 1A — xlib_standard MVC 冻结（Day 3-7，来源：07-11-analysis.md §八 optimization priority 1）：
    - XLS-001: 冻结 ownership manifest
    - XLS-003: 建立 standard bundle schema（先 freeze schema/policy/reason-code，不等完整 bundle）
    - XLS-002: 裁决 goalcli 归属（三仓无残留）

  子阶段 1B — 标准四仓完整修复（Day 8-14）：
    - xlib_standard: XLS-001 至 XLS-008
    - xlib_harness: XLH-001 至 XLH-008 + XLH-009（goalcli 吸收）
    - xlib_evidence: XLE-001 至 XLE-008
    - xlibgate: XLG-001 至 XLG-008

  子阶段 1C — 三 Canary 验证（Day 15-21）：
    - CANARY-L0: kernel pure module 全链
    - CANARY-DOMAIN: decimalx deterministic finance values
    - CANARY-L2: redisx real external integration
    - canary 加权通过策略：2/3 + RCA（07-11-analysis.md §八） -->

#### 2.1.4 退出条件

<!-- - 标准四仓 release gate 可重放、evidence 完整
  - 三 canary 全部 clean-room Release 或 2/3+RCA 通过
  - xlib_standard v2.0.0 stable 发布 -->

#### 2.1.5 关键路径节点

<!-- - Day 5: MVC freeze → downstream unlocked
  - Day 14: standard v2 RC → canary 启动
  - Day 21: canary 全部通过 → Phase 2 unlocked -->

#### 2.1.6 风险标记

<!-- - xlib_standard v2 RC 是全局单点瓶颈（07-11-analysis.md §四）
  - redisx 是最不稳定的 canary（external integration 未建立）
  - Docker/K8s 禁令下 fault/soak 可行方案是否就绪（07-11-analysis.md §2.3） -->

---

### 2.2 Phase 2 — L1 与 Assembly 基础修复

#### 2.2.1 目标

<!-- 修复 L0/L1/Assembly/Test 模块的 P0 实现错误、版本一致性和 CI；
     使近生产模块重新达到可认证状态 -->

#### 2.2.2 进入条件

<!-- - Phase 1 退出条件全部满足
  - xlib_standard stable 可用
  - xlibgate 可验证 L1 模块 -->

#### 2.2.3 活动清单

<!-- 按 07-11.md §4 展开：

  kernel（L0）：
    - KRN-001: 边界 ADR
    - KRN-002: v1 兼容 deprecation
    - KRN-003: Go/CI/security 基线
    - KRN-004: 100% 核心验证
    - KRN-005: API/benchmark
    - KRN-006: consumer canary

  configx（L1）：
    - CFG-001: 收敛公共面
    - CFG-002: precedence property
    - CFG-003: strict decode
    - CFG-004: secret zero-leak
    - CFG-005: watcher state machine
    - CFG-006/007/008: security/RemoteSource/CI

  observex（L1）：
    - OBS-001: 版本/历史事实修复
    - OBS-002: provider-neutral gate
    - OBS-003: redaction contract
    - OBS-004 至 OBS-008

  resiliencx（L1, CRITICAL）：
    - RES-001: 冻结错误语义与 model（先写失败 regression tests）
    - RES-002 至 RES-005: retry/bulkhead/ratelimit/circuit P0 修复
    - RES-006 至 RES-009: compose/kernel/soak/版本 reset

  schedulex（L1）：
    - SCH-001: 文档/API 事实修复
    - SCH-002 至 SCH-008

  bootstrap（Assembly, CRITICAL）：
    - BST-001: 重分类 Assembly
    - BST-002: 事务式构造
    - BST-003: Hook 回滚
    - BST-004: Config 生效
    - BST-005: 生命周期状态机
    - BST-006: foundationx 退出
    - BST-007 至 BST-009: store wiring/CI/consumer smoke

  testkitx（L1 test-only）：
    - TST-001: 版本事实 reset
    - TST-002: test-only import gate
    - TST-003 至 TST-008 -->

#### 2.2.4 退出条件

<!-- - kernel v1.2.0 发布，全下游编译成功
  - resiliencx v2.0.0-rc1 六策略 model/race/leak/soak 全部通过
  - bootstrap v0.3.0 事务式构造、7 adapter 基础通过
  - 所有模块 main 标 unreleased、release tuple 一致 -->

#### 2.2.5 关键路径节点

<!-- - Day 30: kernel + configx/schedulex 重新认证完成
  - Day 37: resiliencx 六策略重写完成
  - Day 45: bootstrap 事务式构造完成，依赖全部 7 storage（跨越 W3/W4） -->

#### 2.2.6 风险标记

<!-- - resiliencx 是重建而非修复，6 策略全部需要重写（07-11-analysis.md §三 CRITICAL）
  - bootstrap 7 adapter partial failure matrix（3^7=2187）不可能穷举
  - bootstrap 需要 W4 的 storage 模块可用才能完成完整验证，存在跨阶段依赖 -->

---

### 2.3 Phase 3 — 存储、领域与传输

#### 2.3.1 目标

<!-- 建立 7 个 storage adapter 的真实验证层级（PR/Nightly/Release）；
     完成 L2.5 领域模块的语义纯化、SSOT 合并和接口拆分；
     实现 contracts/v1 和 transportx request/reply core -->

#### 2.3.2 进入条件

<!-- - Phase 2 退出条件全部满足
  - 标准控制平面 stable
  - kernel/configx/observex/schedulex 可消费 -->

#### 2.3.3 活动清单

<!-- 按 07-11.md §5 §6 展开：

  存储子阶段（light/heavy pool，来源：07-11-analysis.md §2.5 待定义）：

  Light pool（可并行）：
    - postgresx: PGX-001 至 PGX-008
    - ossx: OSS-001 至 OSS-009
    - clickhousex: CHX-001 至 CHX-008

  Heavy pool（互斥 soak）：
    - redisx: RDX-001 至 RDX-009
    - kafkax: KFK-001 至 KFK-008
    - natsx: NTS-001 至 NTS-008
    - taosx: TAO-001 至 TAO-008

  领域子阶段：

  decimalx：
    - DEC-001 至 DEC-009

  domainx：
    - DMN-001 至 DMN-008

  domain_market（CRITICAL）：
    - MKT-001 至 MKT-010

  domain_macro（CRITICAL）：
    - MAC-001 至 MAC-010（注意：MAC-003 repo 创建需治理审批 + 人工会话显式授权）

  domain_exchange（CRITICAL）：
    - EXC-001 至 EXC-010

  传输子阶段：

  contracts：
    - CTR-001 至 CTR-008

  transportx：
    - TRN-001 至 TRN-009 -->

#### 2.3.4 退出条件

<!-- - 7 storage 建立支持版本矩阵、fault、风险触发 soak、真实 adoption
  - domain_market 基础设施污染迁出完毕
  - domain_macro 建立真实仓库、no-lookahead core 通过
  - domain_exchange v1.1 小接口层可供消费
  - contracts/transportx 有真实下游兼容验证 -->

#### 2.3.5 关键路径节点

<!-- - Day 50: 4 个假 integration 全部 fail-closed
  - Day 55: domainx Clock/ID 显式化 + domain_market 纯化
  - Day 60: domain_exchange v1.1 + transportx request/reply -->

#### 2.3.6 风险标记

<!-- - domain_macro 从零创建需治理审批，审批延迟 = 全局延迟
  - domain_exchange 13→8 接口拆分，所有下游 adapter 逐一迁移
  - domain_market Payload interface{} 替换影响全部消费者
  - 4 storage heavy pool（redisx/kafkax/natsx/taosx）的真实 backend evidence 积累是最耗时部分 -->

---

### 2.4 Phase 4 — 全舰队认证与收尾

#### 2.4.1 目标

<!-- 25 仓逐一重新认证；每仓独立 clean-room Release；
     Fleet status 完全由 remote Evidence 推导 -->
     <!-- 内容来源：07-11.md §7 §8 -->

#### 2.4.2 进入条件

<!-- - Phase 3 退出条件全部满足
  - 所有前置模块已有 stable release -->

#### 2.4.3 活动清单

<!-- 1. 按 release train 顺序：控制面 → L0 → L1 → domain → storage → exchange → assembly
  2. 每个模块执行 §1.3.4 release tuple 全部 18 项
  3. 联合验证矩阵全项通过（07-11.md §7.2） -->

#### 2.4.4 退出条件

<!-- - 25 模块 release tuple 全部闭合
  - 未过门禁者保持 blocked，不为数量放行
  - Fleet status 完全由 Evidence 推导，手工 factory=true 被 gate 拒绝 -->

#### 2.4.5 风险标记

<!-- - 部分模块的 live/fault/soak 需要真实生产环境
  - 消费者迁移可能落后于模块发布 -->

---

## 第三章：工作包索引

<!-- 意图：按模块展开所有工作包，标注优先级、依赖和并行可行性，补全覆盖缺口 -->

### 3.1 工作包清单

<!-- 每个模块一个子节，包含：
  - 模块概述（层级、当前裁决、最高阻断）
  - P0 工作包表格：ID | 任务 | 依赖 | 可并行 | 预计人天
  - P1 工作包表格
  - P2 工作包表格
  - 交叉引用：关联的 BASE-* 工作包

  模块列表：
    标准四仓：xlib_standard / xlib_harness / xlib_evidence / xlibgate
    L0: kernel
    L1: configx / observex / resiliencx / schedulex / testkitx
    Assembly: bootstrap
    存储: redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
    契约: contracts / transportx
    L2.5: decimalx / domainx / domain_market / domain_macro / domain_exchange
  -->

### 3.2 全局 BASE-* 工作包展开

<!-- 意图：为 07-11-analysis.md §六 发现的覆盖缺口补充专用工作包 -->

#### 3.2.1 BASE-003 文件缺失矩阵

<!-- 列出缺 SECURITY/CONTRIBUTING/CODEOWNERS 的 10+ 模块的专用 BASE-003 工作包 -->
<!-- 来源：07-11-analysis.md §六 "缺 SECURITY/CONTRIBUTING/CODEOWNERS 的模块（10+）" -->

#### 3.2.2 BASE-005 供应链审计补充工作包

<!-- 为 5 个有 latest tag Actions / curl-pipe / disabled security 的模块创建专用工作包 -->
<!-- 来源：07-11-analysis.md §六 "BASE-005 供应链审计覆盖不足" -->

### 3.3 分析报告覆盖缺口补充

<!-- 意图：列出 07-11-analysis.md §七 "缺失章节"中发现的工作包缺口，追加补充工作包

  1. 全局回滚策略 → 新增 GO-ROLLBACK-001
  2. BASE 推广 Runbook → 新增 GO-BASE-002
  3. 人员分工与并行窗口 → 新增 GO-PEOPLE-003
  4. Fleet Status Dashboard → 新增 GO-DASH-004
  5. configx + 下游集成验证 → 联合验证矩阵补充
  6. resiliencx + kernel 边界验证 → 联合验证矩阵补充
-->

---

## 第四章：P0 修复实施追踪

<!-- 意图：为 07-11-analysis.md §九 的 10 条 P0 修复提供可操作的状态追踪模板 -->
<!-- 来源：07-11-analysis.md §九 P0 修复建议 -->

### 4.1 P0 修复总表

<!-- 表格：P0-序号 | 修复描述 | 负责人 | 目标日期 | 相关制品 | 状态

  | # | 修复描述 | 负责人 | 目标日期 | 相关制品 | 状态 |
  |---|---------|--------|---------|---------|------|
  | 1 | 裁决 goalcli 最终归属 | TBD | Phase 0 | OWNERSHIP-GOALCLI.yaml, XLH-009, 21 agent prompt | PENDING |
  | 2 | 裁决 transportx go module major path | TBD | Phase 0 | TRN-001 补充, go.mod retract | PENDING |
  | 3 | 执行 contracts git tag lineage 审计 | TBD | Phase 0 | contracts-lineage-audit.sh, CTR-001 | PENDING |
  | 4 | 明确 bare-metal fault/soak 方案 | TBD | Phase 1 | eBPF controller (xlib_standard/fixture/fault/) | PENDING |
  | 5 | 全仓 status projection 事实审计 | TBD | Phase 0 | W0 inventory, .foundationx/status/index.json | PENDING |
  | 6 | 定义 xlib_standard MVC（最小可行合约） | TBD | Phase 1 | XLS-003, bundle manifest | PENDING |
  | 7 | 为 10+ 模块创建 BASE-003 专用工作包 | TBD | Phase 0 | §3.2.1 | PENDING |
  | 8 | 30 天窗口扩展至 45-60 天 | TBD | 全局 | 本报告二章 Phase 映射 | PENDING |
  | 9 | 定义 W4 light/heavy pool 分类表 | TBD | Phase 0 | §2.3.3 存储子阶段 | PENDING |
  | 10 | 新增回滚策略 + BASE 推广 Runbook | TBD | Phase 0 | §第六章 + §8.1 | PENDING |
-->

### 4.2 每条 P0 的详细追踪模板

<!-- 每条包含：
  - 修复对象
  - 负责人
  - 目标截止日期
  - 前置依赖
  - 实施步骤（checklist）
  - 验收条件
  - 风险
  - 状态（PENDING / IN_PROGRESS / DONE / BLOCKED）
  - 最后更新日期
-->

---

## 第五章：依赖与关键路径

### 5.1 全局依赖 DAG

<!-- 意图：用可视化文本图表达 25 模块的精确依赖关系 -->
<!-- 内容来源：07-11.md §7.1（精确依赖顺序）+
             foundation-production-readiness 审计 §5.1（机械依赖图）+

  采用 Mermaid 或 ASCII art DAG，标注：
  - 每个模块的层级
  - 依赖箭头方向
  - 关键路径节点高亮
-->

### 5.2 关键路径标注

<!-- 意图：标注决定整体修复时间线的关键路径 -->
<!-- 内容来源：07-11-analysis.md §四 单点阻塞瀑布

  关键路径：
  xlib_standard RC → gate/evidence/harness → 3 canaries → standard stable → L1 → storage → domain → fleet

  关键路径节点：
  - xlib_standard MVC（Day 5 — 解除下游阻塞）
  - xlib_standard v2 RC（Day 14 — canary 启动）
  - 三 canary 全通过（Day 21 — stable 发布）
  - resiliencx P0 修复（Day 37 — L1 完成）
  - bootstrap 完整验证（Day 45 — Assembly 完成）
  - storage heavy pool（Day 60 — Phase 3 完成）
-->

### 5.3 可并行工作包组

<!-- 意图：列出可以同步推进的工作包组合及其约束 -->
<!-- 内容来源：07-11.md §2.2 并行原则

  Phase 1：
    - 标准四仓 ownership + schema freeze 可并行（MVC 后）
    - 三 canary 可并行（但必须等 RC 完成）

  Phase 2：
    - configx/observex/schedulex 可并行
    - kernel → resiliencx 串行约束
    - bootstrap 等待 L1 与 storage contract 稳定

  Phase 3：
    - Light pool (postgresx/ossx/clickhousex) 可并行
    - Heavy pool 同一时间只运行一个 soak
    - domainx → domain_market/domain_macro → domain_exchange 串行约束
    - contracts/transportx 与领域映射协调发布
-->

### 5.4 单点阻塞与缓解策略

<!-- 意图：识别全局依赖中的单点阻塞，提供缓解方案 -->
<!-- 内容来源：07-11-analysis.md §四 §八

  | 阻塞节点 | 阻塞影响 | 缓解策略 |
  |---------|---------|---------|
  | xlib_standard v2.0.0 RC | 全局冻结 | MVC 解耦：schema/policy 先 freeze，下游可提前启动（节省 5-7 天）|
  | 任一 canary 失败 | standard stable 延迟 | 加权通过策略：2/3 + RCA，不必全绿 |
  | bootstrap 完整验证 | 需 7 个 storage | 先做 3 个 light pool adapter，其余用 mock/fake |
  | domain_macro 治理审批 | 仓库创建延迟 | 审批前可完成 SPEC/ADR/设计，仓库创建后直接实现 |
-->

---

## 第六章：风险矩阵

### 6.1 风险热力图

<!-- 意图：按模块和概率-影响二维矩阵展示风险分布 -->
<!-- 内容来源：07-11-analysis.md §三（CRITICAL/HIGH/LOW 分类） -->

#### 6.1.1 CRITICAL 风险模块（5 个）

<!-- 表格：Module | Probability | Impact | Drivers

  resiliencx（6 策略全部重写）
  bootstrap（事务式构造 + 7 adapter matrix）
  domain_market（基础设施迁出 + Payload 替换）
  domain_exchange（13→8 接口拆分 + 下游迁移）
  domain_macro（仓库不存在 + 从零创建 + 治理信任崩塌）
-->

#### 6.1.2 HIGH 风险模块（4 个）

<!-- transportx / xlib_standard / natsx / kafkax -->

#### 6.1.3 LOW 风险模块（6 个）

<!-- kernel / decimalx / configx / schedulex / observex / testkitx -->

### 6.2 高影响-高概率事件缓解方案

<!-- 意图：为每个 CRITICAL 和 HIGH 风险定义具体缓解措施 -->

<!-- 内容：
  1. xlib_standard RC 失败 → MVC 解耦 + 上一 stable 验证候选 + 回退到前一个 stable
  2. resiliencx P0 重写超出预估 → 先写 model test + 按策略拆分独立 PR + 保留旧 API 兼容
  3. bootstrap 7 adapter matrix 无法全部验证 → 分类：3 core adapter PR gate / 其余 nightly
  4. domain_macro 仓库授权延迟 → Spec/ADR/Design 在审批前完成
  5. storage heavy pool soak 冲突 → 一次只跑一个重型 soak + 定时窗口 + eBPF 替代 Docker
-->

### 6.3 回滚决策树

<!-- 意图：定义故障场景下的回滚路径 -->

<!-- 内容来源：07-11-analysis.md §七 缺失章节 "全局回滚策略"

  决策树节点：
  - Phase 内部修复失败 → 保留 worktree、redact summary、回 Sol
  - 标准模块 v2.0.0 发布后发现问题 → advisory + v2.0.1 patch + retract v2.0.0
  - Canary 验证失败（< 2/3）→ RCA、修复、重跑
  - 模块认证失败 → 保持 blocked，不降级标准
  - 证据冲突 → 以可重放 evidence 为准，暂停宣称
-->

---

## 第七章：验证与质量门禁

### 7.1 每阶段退出 Check

<!-- 意图：定义每个 Phase 结束时必须验证的条件 -->
<!-- 来源：07-11.md 各模块 §退出标准 + 07-11-analysis.md §七 -->

<!-- 格式：
  Phase 0 退出 Check：
    □ 25 仓 inventory 无矛盾
    □ 三条治理矛盾裁决完成
    □ Go baseline SSOT 收敛
    □ 无新虚假 factory 声明
    ...

  Phase 1 退出 Check：
    ...

  以此类推到 Phase 4
-->

### 7.2 联合验证矩阵

<!-- 意图：列出所有跨模块联合验证项及其必需证据 -->
<!-- 内容来源：07-11.md §7.2 + 07-11-analysis.md §七 缺失补充

  | Joint Verification | Modules | Must Prove | Status |
  |-------------------|---------|------------|--------|
  | CANARY-L0 | standard+harness+gate+evidence+kernel | pure module 全链 | TBD |
  | CANARY-DOMAIN | decimalx+domainx | deterministic finance values | TBD |
  | CANARY-L2 | redisx+observex+bootstrap | real external integration + assembly rollback | TBD |
  | OBS-CONFORMANCE | observex+external adapter fixture | vendor-neutral SPI | TBD |
  | RESILIENCX-KERNEL | resiliencx+kernel | 策略迁移正确性 | TBD |
  | CONFIGX-INTEGRATION | configx+bootstrap | 配置中枢边界行为 | TBD |
  | EXCHANGE-CONFORMANCE | domain_exchange+≥3 venue adapters | capability migration | TBD |
  | MARKET-CONTRACT | domain_market+contracts+market_data | canonical fact 与 wire mapping | TBD |
  | MACRO-NOLOOKAHEAD | domain_macro+macro_data+macro_regime | AsOf/vintage 无前视 | TBD |
  | TRANSPORT-CONTRACT | transportx+HTTP adapter+contracts | request/reply/codec/middleware | TBD |
-->

### 7.3 自动化 Gate 定义

<!-- 意图：定义各层级模块的自动化门禁规则 -->
<!-- 来源：07-11.md §1.4 BASE work packages

  Gate 类型：
  - identity gate: repo ID、module path、package 一致
  - Go baseline gate: go 1.26.0、toolchain go1.26.5
  - repo-profile gate: 必备文件齐全
  - CI gate: 生成式 workflow、self-hosted、required checks
  - supply-chain gate: Actions SHA、无 latest/curl-pipe
  - API/SemVer gate: apidiff、breaking 自动 MAJOR
  - Evidence gate: commit/tree/run/digest/result/asset 全量验证
  - Release gate: candidate SHA final check 后才创建稳定 tag
  - Adoption gate: go get @tag + 至少一个消费者

  每类 gate 标注：
  - 适用模块层级
  - fail 行为（exit 1/2）
  - reason code
  - 跳过条件（不允许无声跳过）
-->

---

## 第八章：资源与基础设施

### 8.1 CI Runner 需求

<!-- 意图：定义 4 类 Runner pool 的性能、安全与网络要求 -->
<!-- 内容来源：07-11.md + 07-11-analysis.md §2.5（W4 light/heavy pool）

  4 类 Pool：
  | Pool Class | 适用模块 | 核心要求 | 数量 |
  |-----------|---------|---------|------|
  | sre/contracts | L0/pure-library | ephemeral、rootless、无网络出站 | 2 |
  | sre/compute | L1 primitives | race-enabled、coverage collection | 2 |
  | sre/storage-light | postgresx/ossx/clickhousex | 各自本地 service、无容器 | 3 |
  | sre/storage-heavy | redisx/kafkax/natsx/taosx | systemd、netns、iptables、ebpf | 4 |
-->

### 8.2 外部服务清单

<!-- 意图：列出所有需要的外部服务及其版本要求 -->
<!-- 来源：07-11.md §5 各模块 requirements

  | 服务 | 模块 | 版本要求 | 部署方式 | 权限要求 |
  |------|------|---------|---------|---------|
  | Redis | redisx | ≥7.2 | systemd unit + netns | root (netns/iptables) |
  | Kafka | kafkax | ≥3.6 (KRaft) | systemd unit + netns | root |
  | NATS | natsx | ≥2.10 | systemd unit + netns | root |
  | PostgreSQL | postgresx | 17 + N-1 | systemd unit | root |
  | TDengine | taosx | ≥3.x | systemd unit + netns | root |
  | ClickHouse | clickhousex | ≥24.x | systemd unit | root |
  | Aliyun OSS | ossx | live endpoint | credentials (Secret) | key/secret |
-->

### 8.3 eBPF 环境准备

<!-- 意图：描述 bare-metal fault injection 的 eBPF 方案 -->
<!-- 内容来源：07-11-analysis.md §P0-4 实施细节

  - eBPF Controller 包结构（fault/packdrop/connrst/ioerr/latency）
  - 编译依赖：cilium/ebpf + bpf2go + clang + kernel headers
  - CI Runner 前置条件：kernel ≥5.15 + BTF + bpf syscall 权限
  - 与 netns Controller 的对比矩阵（Bash vs Go-native vs eBPF）
-->

### 8.4 Bare-metal Fault Injection 验证

<!-- 意图：在 AGENTS.md 禁止 Docker/K8s 的前提下，验证所有 storage adapter 的 fault injection 方案

  - 三级隔离方案：systemd service unit + network namespace + iptables/nftables
  - FaultScenario 测试框架（RunScenario + RunSoak）
  - 跨 adapter 复用 fault fixture（xlib_standard/fixture/fault/）
  - CI 跳过策略：本地开发自动 skip，CI+root 必须执行
-->

---

## 第九章：治理检查清单

### 9.1 Release Tuple 完成矩阵

<!-- 意图：每个模块的 18 项 release tuple 逐项追踪 -->
<!-- 来源：07-11.md §12 完成检查清单

  矩阵：Module × 18 items × Status(PASS/FAIL/PENDING/N-A)

  18 Items:
  1. 模块职责与非目标冻结
  2. repo/module/package identity 一致
  3. Go/toolchain/runner 标准一致
  4. main 仅表示 unreleased；release tuple 一致
  5. 必备 repo profile 文件齐全
  6. generated CI 无手工削弱
  7. required security 全阻断
  8. API/schema/SemVer 机器裁决
  9. unit/race/coverage/property/fuzz 满足 profile
  10. class-specific integration/model/conformance 通过
  11. required integration 不可 skip
  12. Evidence 绑定 commit/tree/run/service/assets
  13. candidate final check 在 stable tag 前完成
  14. GitHub Release assets 完整且 digest 验证
  15. `go get @tag` 成功
  16. downstream adoption 通过
  17. live/fault/soak 满足适用 profile
  18. Fleet qualification 由证据推导
  19. rollback/quarantine/revoke 路径可执行
-->

### 9.2 BASE 工作包完成矩阵

<!-- 意图：9 个 BASE-* 工作包在每个模块的完成状态 -->
<!-- 来源：07-11.md §1.4

  矩阵：Module × BASE-001 to BASE-009 × Status

  特别标注 07-11-analysis.md §六 发现的覆盖缺口：
  - "BASE-\* 全通过" 而无分解的 8 个模块
  - 无 BASE-003 专用工作包的 10+ 模块
  - BASE-005 供应链覆盖不足的 5 个模块
-->

---

## 附录

### 附录 A — 全仓状态投影审计结果

<!-- 意图：详细记录 .foundationx/status/index.json 的审计发现 -->
<!-- 来源：foundation-production-readiness 审计 §4.1（成熟度事实层过度声明）+
          08-11-analysis.md §2.4（domain_macro 治理信任崩塌）

  - 当前 status projection 与事实对比表
  - 字段级真值矩阵
  - 修正指令
-->

### 附录 B — BASE-003 文件缺失矩阵

<!-- 意图：列出所有模块的 repo profile 文件缺失情况 -->
<!-- 来源：07-11-analysis.md §六

  表格：Module × README/LICENSE/SECURITY/CHANGELOG/CONTRIBUTING/CODEOWNERS/profile
  标注：✓ 存在 / ✗ 缺失 / △ 内容不完整
-->

### 附录 C — 版本一致性裁决表

<!-- 意图：逐模块裁决六源版本不一致问题 -->
<!-- 来源：foundation-production-readiness 审计 §4.4（发布血缘与版本身份普遍失真）

  表格：Module | Tag | GitHub Release | VERSION file | Source Version | Repo-contract | Manifest | Verdict

  特别关注：
  - domainx: Version v1.0.0 vs tag v1.0.1 vs history diverged
  - domain_macro: v1.0.1 released but main reverted to float64
  - contracts: v1.5.0 tag-only, Latest Release v0.4.7
  - transportx: go.mod = xlib-standard, tag = v1.1.1-spec
  - clickhousex: v1.0.9 vs ghost v1.0.10
-->

### 附录 D — Go Module Identity 修复路径

<!-- 意图：6 个 go.mod identity 不一致的修复路径 -->
<!-- 来源：foundation-production-readiness 审计 §4.2

  | 模块 | 当前 go.mod | 目标 go.mod | 修复路径 | 消费者影响 |
  |------|-----------|-----------|---------|----------|
  | xlib_standard | xlib-standard | xlib_standard | keep, update FOUNDATION-DEPS | 无 |
  | xlib_harness | xlib-harness | xlib_harness | keep, update FOUNDATION-DEPS | 无 |
  | transportx | xlib-standard | transportx | rename, retract old tags | 无 (production_import_allowed=false) |
  | domain_market | domain-market | domain_market | rename, /v2 if existing v1 consumers | 需裁决 |
  | domain_macro | domain-macro | domain_macro | rename | 需裁决 |
  | domain_exchange | domain-exchange | domain_exchange | rename, /v2 if existing v1 consumers | 需裁决 |
-->

### 附录 E — Goal → Retro 管线快速通道

<!-- 意图：描述 Goal 驱动交付管线在此次修复中的角色 -->
<!-- 来源：AGENTS.md §Goal 驱动交付体系

  - 修复工作如何映射到 G0-G11 管线
  - 哪些模块使用完整管线（新功能），哪些使用快速通道（纯修复）
  - 四源评分在此次修复中的适用性
-->

### 附录 F — 分析报告溯源索引

<!-- 意图：标注本文档中各数据点的原始来源报告 -->

<!-- 表格：Data Point | Source Report | Section | Line
  所有与 07-11.md、07-11-analysis.md、foundation-production-readiness 审计中
  对应的数据点溯源
-->

---

## 修订历史

| 版本 | 日期 | 作者   | 变更说明 |
| ---- | ---- | ------ | -------- |
| v1.0 | 2026-07-11 | planner | 初始计划结构框架 |

---

<!-- 注释约定：
  - `<!-- 来源：07-11.md §X.Y -->` 标注从原计划提取的段落
  - `<!-- 来源：07-11-analysis.md §X -->` 标注从分析报告提取的段落
  - `<!-- 来源：foundation-production-readiness §X -->` 标注从深度审计提取的段落
  - `<!-- 意图：... -->` 标注每节的设计意图（面向写作者）
  - `[COMPUTED, HIGH]` 等标签保留作为证据等级标注
-->
