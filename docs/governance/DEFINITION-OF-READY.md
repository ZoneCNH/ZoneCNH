# Definition of Ready

> **投影声明**（2026-07-03 P2.3）：分层 DoR/DoD 的 canonical SSOT 是 `docs/goal/06-dod.md`（12 层完整定义）。本文件定义 Spec→Code 快速通道的 Spec 层 DoR 检查清单和 CI 机器门禁实现（spec-lint.sh 集成）。Spec DoR 的权威定义见 `06-dod.md §2`。
>
> 一个 spec 可以进入开发的前置条件。

最后更新：2026-07-03

---

## 检查清单

一个 spec 可以进入开发，必须满足以下所有条件：

### 清晰性

- [ ] Summary 一句话能说清模块职责
- [ ] 无模糊词（"快速"、"简单"、"好看"等），或已有量化说明
- [ ] Goals 明确且可衡量

### 范围

- [ ] Goals 明确列出
- [ ] Non-goals 明确列出
- [ ] Consumers 明确列出（谁会用这个模块）

### 功能

- [ ] 每个 Functional Requirement 有编号（FR-xxx）
- [ ] 每个 FR 使用 WHEN/THEN 格式
- [ ] 覆盖正常路径和失败路径
- [ ] Business Rules 有编号（BR-xxx）

### 数据

- [ ] 数据模型已定义（类型、字段、默认值）
- [ ] 公共错误已定义
- [ ] 配置 schema 已定义

### 边界

- [ ] Edge Cases 已列出
- [ ] 空值/零值处理已说明
- [ ] 并发场景已说明
- [ ] 超时/取消场景已说明

### 安全

- [ ] 安全要求已列出
- [ ] 敏感数据处理已说明

### 测试

- [ ] 每个核心 FR 有对应 TC
- [ ] 每个 AC 可验证
- [ ] 测试策略已说明

### 开发

- [ ] 目录结构已定义
- [ ] 依赖约束已定义
- [ ] CI Gate 已定义
- [ ] Performance Budget 已定义
- [ ] 没有 Blocking 级 Open Questions

### 交叉检查

- [ ] 相关 Technical Spec 已存在（ARCHITECTURE.md）
- [ ] 不与其他 spec 冲突
- [ ] 符合 CONSTITUTION.md 的设计原则

---

## 机器门禁（Approved 升级前必检）

> 2026-06-22 新增（见 `report/architecture-structural-analysis-20260622-v2.md` §5.2 P0-2）
> 2026-06-22 扩展：Status 校验改为"抽取主态关键词"，兼容历史描述性次态

`.github/ci/spec-lint.sh` 在 Status 主态为 `Approved` 时强制执行以下 ERROR 级检查（违反阻断 CI）：

- **AC 必填**：SPEC.md 必须包含至少一条 `AC-` 编号（任何形式：`AC-001` / `AC-XXX-001` / `AC-MD-001`），否则报 `Status='...' (主态=Approved) 但 SPEC 不含任何 AC`
- 已有 Status 合法性检查（六态关键词必须出现在 Status 行内）
- 已有 23 节模板序检查（§1..§23 + Appendix）
- 已有 Spec-Version / Last-Updated 字段校验
- 已有 FR 编号连续性检查

### Status 合法值

合法 Status 必须**包含**以下六个主态关键词之一：
- `Draft` — 草稿
- `Review` — 评审中
- `Approved` — 已批准，可进入开发（触发 AC 必填门禁）
- `Implemented` — 已实现
- `Changed` — 已变更（破坏性变更标记）
- `Deprecated` — 已废弃

主态可与描述性后缀组合，常见形式：
- `Spec Approved / Tasks Pending` — 规格层就绪、实施层未启动（用于 Review 模块向 Approved 过渡）
- `Docs Baseline Approved / Runtime Pending` — 文档基线已批准、运行时未启动
- `Approved (Docs Baseline Synced / Runtime Truth Verified)` — 文档与 runtime 双向同步
- `Approved (contract-corrected)` — 历史 contract 修正后批准
- `Implemented Locally` — 本地实现版本

**判定规则**：spec-lint 按 `Approved → Review → Draft → Implemented → Changed → Deprecated` 顺序抽取首个匹配关键词作为 `status_main`，用于 AC 必填判断。

### 升级到 Approved 的可机器验证条件

- AC count ≥ 1
- FR count ≥ 1
- TC 至少在 §16/§19 章节出现（推荐但非阻断）
- 23 节模板完整或采用简化版（contracts / xlib_standard 等元契约模块）

Draft / Review 状态允许 AC 缺失，作为过渡窗口；推进到 Approved 主态前必须补齐。

---

## 判断标准

```text
如果一个需求不能被测试，它还不是合格需求。
如果一个需求没有边界，它会被 AI 自由发挥。
如果一个需求没有 Non-goals，AI 很容易做多。
如果一个 spec 有 Blocking Open Questions，它还不能进入开发。
```text

---

## 例外

以下情况可以降低标准：

- **Bug 修复**：只需 FR + AC + TC
- **文档更新**：无需 FR/AC/TC
- **重构**：只需 AC（行为不变）+ TC（现有测试通过）
