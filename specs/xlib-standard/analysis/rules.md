# xlib-standard 子分析：规则源与 Debt Governance

本文件是本地分析，不是可执行规格。覆盖 Standard Source 与 Debt Governance 两类职责。

## 1. 角色边界

- 上游 SSOT 位于 `docs/standard/**`、根级 `docs/*.md` 与 registry/enforcer 源。
- 本快照只记录结构、编号和来源锚点，不声明本仓库可以执行这些规则。
- 对外规则编号保留 `BR-NNN`；enforcer 源码引用保留 `RULE-CORE-NNN`；旧内部分类编号已废弃。

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

## 9. 业务规则（Business Rules）

### 9.1 核心铁律（Iron Rules，7 条；亦记为 BR-001..BR-007）

> **编号别名（消解结构债 S4 / S11）**：`BR-NNN` 为对外引用的业务规则编号；`RULE-CORE-NNN` 仅保留给 enforcer / registry.yaml 源码引用。旧内部分类编号已废弃；`TRUTH-NNN` 只作为本文件一处同义引用表，不再作为独立编号空间跨节引用。

| BR | RULE-CORE | 规则 |
|----|-----------|------|
| BR-001 | RULE-CORE-001 | 没有证据，不允许 DONE |
| BR-002 | RULE-CORE-002 | Goal 必须从真实上下文开始 |
| BR-003 | RULE-CORE-003 | 需求必须可验证 |
| BR-004 | RULE-CORE-004 | 所有变更必须可追踪 |
| BR-005 | RULE-CORE-005 | Harness 是机器裁判 |
| BR-006 | RULE-CORE-006 | Self-improving 是强制环节 |
| BR-007 | — | 登记态 ≠ adopted |

> 旧内部分类编号已废弃；对外只使用 `BR-NNN`，源码引用只使用 `RULE-CORE-NNN`。

### 9.2 规则前缀体系（RULE Taxonomy）

419 条规则按前缀分类：

| 前缀 | 类别 | 示例 |
|------|------|------|
| RULE-CORE | 核心铁律 | RULE-CORE-001（没有证据不允许 DONE） |
| RULE-HARNESS | Harness 执行 | RULE-HARNESS-003（P0 Gate 失败阻断发布） |
| RULE-EVIDENCE | Evidence 协议 | RULE-EVIDENCE-001（DONE with evidence 格式） |
| RULE-SEC | 安全规则 | XS-CORE-008（日志脱敏） |
| RULE-DEP | 依赖规则 | RULE-DEP-001（依赖方向） |
| RULE-IMPL | 实现规则 | RULE-IMPL-001（模块边界） |
| RULE-TEST | 测试规则 | RULE-TEST-001（覆盖率） |
| RULE-DOCS | 文档规则 | RULE-DOCS-001（ADR 必需） |
| RULE-ARCH | 架构规则 | RULE-ARCH-001（层级治理） |
| RULE-DOMAIN | 领域规则 | RULE-DOMAIN-001（禁止业务术语） |

### 9.3 RULE 前缀 ↔ FR 映射（消解结构债 S7）

> 419 条 RULE-* 按前缀汇总到 FR 覆盖区段。本表为**块级**映射，行级 RULE→FR→TC 映射由 `registry.yaml` + `goalcli trace-coverage` 维护，行级缺口由上游 trace coverage 规则处理（详见 `TRACEABILITY.md` §"块级追溯缺口声明"）。

| RULE 前缀 | 主要覆盖 FR | 覆盖说明 |
|-----------|-------------|----------|
| RULE-CORE | FR-001 / FR-007（BR-001..BR-007） | 7 条铁律 / 基本真理同义表见 `analysis/governance.md` |
| RULE-HARNESS | FR-020..FR-025 | 66 个 gate 条目、Profile、Scorecard、Debt Gate |
| RULE-EVIDENCE | FR-026..FR-032 | Evidence Ledger、Manifest、DONE 格式、4 项禁止 |
| RULE-DEP | FR-004 / FR-015..FR-019 | 依赖方向、模板渲染依赖、Docker 工具链 |
| RULE-IMPL | FR-009..FR-014 / FR-040..FR-046 | Go 参考模板、Goal Runtime |
| RULE-TEST | FR-020 / §16（xlib-TC-001..017） | 测试分层、覆盖率、race gate |
| RULE-DOCS | FR-008 / §C 文档清单 | ADR、文档入口 |
| RULE-ARCH | FR-004 / §16 | 层级治理 |
| RULE-DOMAIN | FR-005 / FR-047..FR-052 | 仓库治理、采纳状态机、下游同步 |
| RULE-SEC | §20 / FR-013 / FR-014 | 配置脱敏、secret policy、日志脱敏 |

### 9.4 规则权威顺序

```text
iron-rules.md > registry.yaml > *-rules.md > ADR-* > .worktree/goal-patch.md
```


### 9.6 采纳状态机禁止转换（6 个）

从 `main.md` 和 `goal.md` 提取的 6 个禁止状态转换：

| # | 禁止转换 | 原因 |
|---|----------|------|
| 1 | registered → adopted | 登记态不等于已采纳，必须经过 proof-based adoption |
| 2 | dry_run → adopted | dry-run 只验证流程，不证明落地 |
| 3 | patch_only → adopted | patch-only 不等于 proof-based adoption |
| 4 | not_run → adopted | 未运行禁止直接 adopted |
| 5 | gate_outputs_missing → proof_based_adoption | 缺少 gate 输出不能声称 proof-based（条件状态：evidence_state=partial 时的中间态） |
| 6 | baseline_scanned → adopted | 基线扫描不等于采纳完成（条件状态：adoption_status=registered 时的扫描态） |

核心铁律：`registered != adopted`、`patch_only != proof_based_adoption`、`gate_outputs_missing != proof_based_adoption`。

### 9.7 关键约束

1. **依赖方向**：L3 → L2 → L1 → L0 → stdlib，不可反向（L.md, ADR-20260604-001）
2. **L3 私有边界**：L3 业务系统不公开、不开源，公开库不得包含业务语义（ADR-20260604-001）
3. **配置显式传入**：不得隐式读取 ``<secret-store-path>``（docs/config.md）
4. **日志脱敏**：不得输出 secret/token/password/private key/连接凭据（docs/standard/xlib-standard.md XS-CORE-008）
5. **单一执行面**：cmd/goalcli 是唯一机器执行面，拒绝第二套并列执行面（ADR-20260603-001）
6. **证据不可删**：禁止删除失败 Evidence（docs/standard/evidence-protocol.md EP-012）

---

### 20.1 P0 安全规则

| 规则 | 来源 |
|------|------|
| 不得隐式读取 ``<secret-store-path>`` | XS-CORE-016 |
| 不得将密钥内容写入源码/README/测试日志/manifest/PR/Evidence | XS-CORE-017 |
| 日志不得输出 secret/token/password/private key/连接凭据 | XS-CORE-008 |
| Claude review 仅限本地执行，不使用 repo API key | ARA-002 |
| Claude 审查脚本禁用工具访问，禁止 push/branch/close/settings 操作 | ARA-003 |
| 第三方 Action 必须固定为 40 位 commit SHA | docs/supply-chain.md |
| Docker image build context 不得包含 Git metadata 或 Agent 运行态 | DTS-003 |
| 未列入 contract 的私密变量不得默认传入容器 | DTS-005 |

## 5. Debt Governance 分析结论

7 类技术债治理（ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC）应视为上游 gate 与 registry 的分析对象。本仓库不得把 debt-scan、release-final 或 latest manifest 结果声明为已执行，除非 `REMOTE-EVIDENCE.md` 或上游 artifact 给出独立证据。
