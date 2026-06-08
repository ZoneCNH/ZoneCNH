# xlib-standard 本地结构分析快照

本文件是 `github.com/ZoneCNH/xlib-standard@93753b30` 的本地结构分析快照，**不是**可执行规格。

- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c`（remote tag `v0.6.5`）
- Analysis-Version: v3.0.0
- Upstream: [github.com/ZoneCNH/xlib-standard](https://github.com/ZoneCNH/xlib-standard)
- 本仓库角色: `ZoneCNH/ZoneCNH` 文档枢纽，仅保存本地分析、追溯锚点和边界说明，不承载实现源码。

## 1. 子分析索引

| 子分析 | 覆盖职责 | 主要内容 |
|--------|----------|----------|
| [`analysis/rules.md`](analysis/rules.md) | Standard Source + Debt Governance | 规则源、BR/RULE 编号、技术债规则、规则权威顺序 |
| [`analysis/template.md`](analysis/template.md) | Go Reference Template + Generator | 公共 API、ErrorKind、metrics、HealthCheck、模板渲染与目录边界 |
| [`analysis/runtime.md`](analysis/runtime.md) | Harness + goalcli + Evidence Runtime | gate 分类、goalcli 契约、Evidence Ledger、Release Manifest、测试样板 |
| [`analysis/governance.md`](analysis/governance.md) | 仓库治理 + 采纳状态机 + 远端治理 | 消费者、采纳状态、仓库治理、远端证据边界、TRUTH 同义引用表 |

## 2. 快照事实层级


规格按事实强度分层：

| 层级 | 来源 | 用法 |
|------|------|------|
| Current Standard | `docs/standard/**`、根级 `docs/*.md` | 当前可执行规范和门禁事实。 |
| Domain Supplement | `docs/testing/**`、`docs/l2/**`、`docs/evidence/**` | 下游、L2、测试和证据补充。 |
| Historical Plan | `.worktree/*.md`、`docs/v0.6.0/**`、Downloads | 迁移目标、历史审查、未落地设计和冲突证据。 |
| Runtime Proof | release/evidence、ledger、CI artifact、remote ruleset proof | 只有真实产物可证明执行状态或远端状态。 |

禁止把弱事实升级为强事实：

- `registered` ≠ `adopted`
- `baseline_scanned` ≠ `implemented`
- `dry_run_ready` ≠ `executed`
- `artifact_exists` ≠ `usable`
- `CHECK_STATUS=passed` ≠ release-ready evidence
- downstream sync plan ≠ downstream adoption proof

## 3. 问题（Problem）

### 3.1 痛点

1. **身份漂移**：旧名 `baselib-template` 和 `foundationx` 导致 README、docs、.agent 出现身份混乱
2. **规则散文化**：419 条规则存在于 13856 行散文（goal-patch.md）中，不可机器读、不可自动验证
3. **伪完成风险**：登记态（registered）、dry-run、patch-only 被误判为 adopted，导致虚假完成声明
4. **配置分散**：`.agent/`、`.xlib/`、`.config/` 三套配置路径并存，下游无法确定权威来源
5. **Gate 缺失**：本地 hooks 不是服务器强制机制，GitHub 服务端 branch protection/ruleset 未配置

### 3.2 量化现状

- 规则总数：419 条（P0=119, P1=244, P2=56）
- 规则机器化率：87%（363/419 active）
- 治理能力评分：8.5/10（缺 GitHub 服务端保护）
- 下游采纳状态：全部 `not_adopted`，evidence_state 为 `not_run`
- L2 适配器：全部停留在 L2-T0/T1

---

## 4. 目标（Goals）

### 4.1 P0 目标（必须达成）

- **G-P0-1 唯一主身份**：xlib-standard 是唯一主身份，承担 6 类职责（ADR-20260602-001）
- **G-P0-2 规则机器化**：419 条规则全部机器化为 registry.yaml，P0=100% 有 enforcer（ADR-20260603-002/004/005）
- **G-P0-3 证据驱动完成**：没有 Evidence 不允许 DONE，完成声明必须使用 `DONE with evidence:` 格式
- **G-P0-4 Proof-based adoption**：登记态 ≠ adopted，只有 downstream repo 自身生成的 proof-based adoption 才能进入 registry
- **G-P0-5 配置统一**：v1.0.0 前将配置拓扑收敛到 `.config/`（18 个命名空间）
- **G-P0-6 三层硬约束**：本地 hooks + CI gate + GitHub Ruleset 三重强制

### 4.2 P1 目标（应当达成）

- **G-P1-7 Goal Runtime v3.1.1**：28 个 PR 执行包全部落地，Goal Kernel + Harness Runtime + Extensions 架构
- **G-P1-8 L2 测试工厂**：15 个 L2 适配器全部达到 L2-T2 级别
- **G-P1-9 Debt Governance**：7 类技术债治理规则全部纳入 Gate
- **G-P1-10 自动化**：Issue → Goal → Task → Branch → Commit → PR → Version → Release → Issue Close 全链路

---

## 6. 消费者（Consumers）

| 消费者 | 领域 / 层级 | 消费方式 | 采纳状态 |
|--------|-------------|----------|----------|
| kernel | 基座 / L0 | 生成模板 + 标准继承 | not_adopted |
| configx | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| observex | 基座 / L1（横切） | 生成模板 + 标准继承 | not_adopted |
| testkitx | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| resiliencx | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| schedulex | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| redisx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| kafkax | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| natsx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| postgresx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| taosx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| ossx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| clickhousex | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |

> 注：L0/L1/L2 是**基座领域内部**的依赖层级编号（详见 §16.1、ARCHITECTURE.md），不与"基座/数据域/分析域/决策域/执行域/入口"领域命名冲突。L2 适配器共 7 个。
>
> docs/l2/ 目录下有 15 个执行计划文件，覆盖上述 7 个 L2 适配器 + xlib-standard 自身 + testkitx + xlibgate + xgo-market-data + xgo-macro-data + engines + xgo runtime system gate。

| 消费者 | 领域 / 层级 | 消费方式 | 采纳状态 |
|--------|------|----------|----------|
| xgo-market-data | 数据域（私有） | 标准继承 | consumer-only |
| xgo-macro-data | 数据域（私有） | 标准继承 | consumer-only |
| x.go | 入口（私有） | 标准继承（consumer-only） | consumer-only |

---

## 4. 关键数字与职责分布

> **详细规格**：本节为摘要表，每个 FR 的完整 WHEN/THEN 行为规格见 [`FR-DETAIL.md`](./FR-DETAIL.md)。

### 7.1 标准源（Standard Source）

| FR | 名称 | 优先级 |
|----|------|--------|
| FR-001 | 定义 419 条 RULE-\* 规则，机器化为 registry.yaml | P0 |
| FR-002 | 定义 7 类技术债治理规则 | P0 |
| FR-003 | 定义 10 条 Git 治理规则并接入执行链 | P0 |
| FR-004 | 定义模块依赖层级模型 | P0 |
| FR-005 | 定义 8 个仓库治理 REQ | P0 |
| FR-006 | 定义采纳状态机入口约束 | P0 |
| FR-007 | 定义 15 条基本真理（同义表见 `analysis/governance.md`） | P0 |
| FR-008 | 定义 9 个正式 ADR | P0 |

### 7.2 Go 参考模板（Go Reference Template）

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-009 | 公共 API 模板 | P0 | 模板渲染生成完整公共 API，go vet 通过 |
| FR-010 | 9 种 ErrorKind | P0 | IsKind 可识别 9 种错误，WrapError 穿透匹配 |
| FR-011 | 9 个最小 metrics | P0 | 操作触发指标递增，Prometheus 返回 9 个指标 |
| FR-012 | HealthCheck JSON schema | P0 | HealthCheck 返回符合 schema 的 JSON |
| FR-013 | 配置显式传入 | P0 | 禁止隐式读取 secret-store-path，Sanitize 屏蔽 |
| FR-014 | 配置 Validate 和 Sanitize | P0 | Validate 返回 ErrorKindValidation，Sanitize 返回脱敏副本 |

### 7.3 Generator

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-015 | render\_template.sh 渲染 | P0 | 3 个占位符全部替换，目录结构完整 |
| FR-016 | 渲染范围全覆盖 | P0 | 覆盖 6 类文件，缺失则非零退出码 |
| FR-017 | Repository Governance Pack | P0 | \-\-enable-governance 生成完整治理文件集 |
| FR-018 | make integration | P0 | 临时渲染 3 个下游库，编译通过 gate 全过 |
| FR-019 | Docker Toolchain Runtime 模板继承 | P1 | Docker 模板继承，工具链版本一致 |

### 7.4 Harness

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-020 | 66 个 gate 条目 | P0 | harness.yaml 44+10+6+6 条目，MVA 为 alias |
| FR-021 | 4 个 Context Profiles | P0 | context-lite/release 等 Profile 定义 |
| FR-022 | P0 Gate 失败阻断发布 | P0 | 任一 P0 failed 则阻断 git tag |
| FR-023 | Gate 结果归档为 Evidence | P0 | 结果写入 ledger.jsonl |
| FR-024 | Release Scorecard | P0 | goalcli score 返回 0\~10.0 分 |
| FR-025 | Debt Governance Gate | P0 | make debt 返回 debt score，<9.8 阻断 |

### 7.5 Evidence Runtime

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-026 | Evidence Ledger | P0 | JSONL append-only ledger，篡改检测 |
| FR-027 | Release Manifest | P0 | make evidence 生成 latest.json 20+ 字段 |
| FR-028 | DONE with evidence 格式 | P0 | 完成声明必须使用 DONE with evidence: 格式 |
| FR-029 | 禁止无证据的 tests pass | P0 | tests pass 必须附带完整命令输出 |
| FR-030 | 禁止 skipped gate 记为 passed | P0 | skipped 不得记为 passed |
| FR-031 | 禁止 dirty workspace release | P0 | git status 有变更则阻断 release |
| FR-032 | 禁止删除失败 Evidence | P0 | append-only 策略阻止删除 |

### 7.6 Debt Governance Runtime

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-033 | ARCH 类技术债规则 | P0 | 5 条架构规则验证 |
| FR-034 | DEP 类技术债规则 | P0 | 10 条依赖规则验证 |
| FR-035 | DOMAIN 类技术债规则 | P0 | 2 条领域规则验证 |
| FR-036 | DOCS 类技术债规则 | P0 | 5 条文档规则验证 |
| FR-037 | TEST 类技术债规则 | P0 | 6 条测试规则验证 |
| FR-038 | IMPL 类技术债规则 | P0 | PANIC\_RUNTIME 等规则验证 |
| FR-039 | SEC 类技术债规则 | P0 | 安全合规规则验证 |

### 7.7 Goal Runtime v3.1.1

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-040 | Goal Kernel（8 个核心对象） | P0 | Goal/Spec/Design/Plan/Task/Test/Evidence/Review |
| FR-041 | Harness Runtime | P0 | Mode Router + Gate/Command Registry + Blocking Policy |
| FR-042 | goalcli 唯一执行面 | P0 | 拒绝第二套并列执行面 |
| FR-043 | 6 个 MVA Gate | P0 | G12\~G16 按序执行，失败阻断后续 |
| FR-044 | 4-Plane 架构 | P0 | Spec→Execution→Proof→Automation 四层 |
| FR-045 | 10 个 REQ-PROOF | P0 | Proof Runtime 逐项验证 |
| FR-046 | 28 个 PR 执行包 | P1 | 5 Phase 有序排列，Phase N 未完则 N+1 不得开始 |

### 7.8 仓库治理协议

| FR | 名称 | 优先级 | 说明 |
|----|------|--------|------|
| FR-047 | 5 层执行链 | P0 | 标准源→生成器→hooks→CI→ruleset 逐层生效 |
| FR-048 | 禁止 main 开发 | P0 | 三重阻断（pre-commit + pre-push + main-guard） |
| FR-049 | 必须使用 git worktree | P0 | worktree-guard 验证当前目录是 worktree |
| FR-050 | 采纳状态机（8 状态） | P0 | 8 个合法枚举值 |
| FR-051 | 6 个禁止状态转换 | P0 | 禁止 registered→adopted 等 6 种跳跃 |
| FR-052 | 下游同步治理（20 PR） | P1 | 标准变更按依赖顺序同步下游 |

---

## 5. 冲突总览

详见 `CONFLICT-LEDGER.md` 与 `SNAPSHOT-BOUNDARY.md`。本快照把冲突分为两类：

| 类型 | 文件 | 范围 |
|------|------|------|
| 同一 SSOT 内部硬冲突 | `CONFLICT-LEDGER.md` | 身份、默认下游、执行面、生成器策略、证据语义等 |
| 分析快照 vs 现实边界 | `SNAPSHOT-BOUNDARY.md` | strict-config、adoption proof、远端治理、release-ready、路径可移植等 |

## 6. 追溯口径

FR 来源锚定 52/52；其中行级 49、file 1（FR-008）、validator-output 2（FR-041, FR-046）。**不得**把“来源锚定完整”读作“语义验证完整”。

TC 使用 `xlib-TC-001..xlib-TC-017` 命名空间，禁止在跨模块文档中裸用 `TC-NNN`。
