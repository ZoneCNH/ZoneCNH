> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](09-security.md) · [↑ 目录](README.md) · [下一节 →](11-code-review.md)

---

## 第十条：变更管理

### 10.1 变更分类

| 分类   | 定义                         | 审批要求                        |
| ------ | ---------------------------- | ------------------------------- |
| PATCH  | Bug 修复、文档更新、测试补充 | 1 人审批                        |
| MINOR  | 新增功能、新增接口方法       | 1 人审批 + SPEC 更新            |
| MAJOR  | 接口签名变更、DTO 结构变更   | 2 人审批 + 迁移方案 + 版本 bump |

### 10.2 Breaking Change 定义

以下变更视为 breaking change：

- 删除或重命名公共接口方法
- 修改公共接口方法签名
- 删除或重命名公共结构体字段
- 修改公共结构体字段类型
- 删除公共常量或错误变量
- 修改事件 Topic 名称
- 修改配置 schema 的必填字段

### 10.3 Breaking Change 流程

```text
0. 产出 ADR（架构决策记录，归 module/{模块}/ADR-NNN-*.md 或 module/ADR-NNN-*.md）记录 breaking change 决策与替代方案
1. 在 SPEC.md 中标记为 DEPRECATED
2. 提供迁移指南
3. 保留至少一个 MINOR 版本周期
4. 下一个 MAJOR 版本中移除
```

> MAJOR 变更必须关联 ADR；ADR 模板见 `module/ADR-TEMPLATE.md`，归属规则见模板内说明。

### 10.4 版本号规则

遵循 Semantic Versioning：

```text
v<MAJOR>.<MINOR>.<PATCH>

v0.x.x  — 初始开发，API 不稳定
v1.0.0  — 首个稳定 API 承诺
```

#### 10.4.1 版本号分层

模块存在两个独立版本号，语义不同，不可互相推导：

| 版本字段 | 含义 | 反映 |
| --- | --- | --- |
| `Spec-Version` | 规格契约版本 | FR/BR/NFR/AC/TC 接口契约演进 |
| `Runtime-Version` | runtime 实现版本 | runtime 仓代码实现成熟度 |

> [COMPUTED, HIGH] spec 版本与 runtime 版本独立：spec 可先于 runtime 演进（契约先行），runtime 也可滞后实现。二者脱节是正常状态，不构成违规。禁止用 spec 版本号暗示 runtime 成熟度，反之亦然。

#### 10.4.2 Spec-Version bump 触发器

Spec-Version **只反映接口契约演进**，不反映文档治理动作：

| 变更类型 | bump 级别 |
| --- | --- |
| FR/BR/NFR 接口/契约变更（新增 FR、修改 AC 语义、新增 AC/TC 锚点） | MINOR |
| 命名收敛 / subject/topic/key 重命名（影响 runtime 契约） | MINOR |
| product_line / event_type 等枚举变更 | MAJOR |
| 治理体系重构（如废弃 TRACEABILITY、版本字段名收敛） | MAJOR |

**无需 bump 的变更**（文档治理类，仅更新 `Last-Updated`）：

- 状态字段修正 / 文档错字 / 链接修复
- 追溯矩阵状态标注（Pending → PASS、L1/L2 标注）
- 文档同步 / 版本号统一 / issue 闭环报告
- 讨论稿 / CHANGELOG / 漂移清单内容更新
- 治理规则文案调整（不改变规则语义）

> [COMPUTED, HIGH] 2026-06-23 binance v3.1.0/v3.3.0 把文档治理当契约 bump 导致 spec 版本通胀（v3.3.0 vs runtime v0.1.0 脱节）。本规则收紧后，spec 版本只反映契约演进，文档治理变更不触发 bump。

#### 10.4.3 版本字段名统一

模块治理文档版本字段名统一为：

- `Spec-Version`：仅模块 SPEC.md（含子规格 SPEC.md）
- `Module-Version`：所有其他治理文档（TRACEABILITY / ACCEPTANCE / FEATURES / RULES / NAMING 等），必须 == 模块 root SPEC 的 `Spec-Version`
- `Runtime-Version`：仅 SPEC.md 的 runtime 版本

**禁止** `Doc-Version` / `Matrix-Version` / `Version` 等异名字段。模块可定义 `RULES.md` R3 引用本节，补充模块特有细节（如子规格对称要求），但 bump 触发器主体以本节为准。

#### 10.4.4 强制约束

- 版本号只能升不能降
- bump 必须是 PR 最后一个 commit
- PR 描述必须显式声明 bump 级别 + 触发理由（契约变更）或"无需 bump（文档治理）"
- 仓库 release manifest 版本（`release/manifest/latest.json`）独立于模块 spec 版本，其 bump 触发器见仓库 `CLAUDE.md`

---

