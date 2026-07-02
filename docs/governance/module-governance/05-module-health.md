# 05 模块健康度 — Module Health

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`STRUCTURAL-SCORING.md`](../STRUCTURAL-SCORING.md)（制品级评分）、[`STATUS.md`](../../../STATUS.md)（域级红绿灯）、[`.foundationx/status/index.json`](../../../.foundationx/status/index.json)

> 本专题定义模块级聚合健康度四维模型与阈值触发规则，闭合"无模块级健康度、现有评分是制品级"缺口。

---

## §1 缺口与目标

**缺口**：现有评分（STRUCTURAL-SCORING 98 分门禁）作用于**制品**（spec/code/test/plan）；STATUS.md 域级红绿灯是人工叙述；无模块级聚合健康度指标，无"健康度低于阈值触发何种治理动作"的规则。

**目标**：定义四维模块健康度模型，聚合现有信号，定义红黄绿阈值与触发动作。**不重复**制品级评分，只做模块级聚合。

---

## §2 四维健康度模型

| 维度 | 输入信号 | 计算方式 |
| --- | --- | --- |
| `spec_health` | SPEC Status、spec drift、Spec-Version 与 Runtime-Version 一致性 | SPEC Approved/Implemented + 无 drift = 绿 |
| `impl_health` | 覆盖率（§5 门禁）、CI pass/失败率、open blockers | 覆盖率达标 + CI 绿 + 无 blocker = 绿 |
| `release_health` | release 与 .foundationx/status 一致、release cadence、registry release 投影准确 | 一致 + cadence=stable = 绿 |
| `dependency_health` | FOUNDATION-DEPS 合规、反向依赖数、owner 活跃度 | 无依赖违规 + owner 活跃 = 绿 |

---

## §3 每维输入信号详解

### §3.1 spec_health

| 信号 | 来源 | 绿 | 黄 | 红 |
| --- | --- | --- | --- | --- |
| SPEC Status | `module/{m}/spec/SPEC.md` Metadata | Approved/Implemented/Changed | Draft/Review | Deprecated（非 archived 模块） |
| spec drift | SPEC-DRIFT-PROTOCOL 检查 | 无 drift | 轻微 drift | 严重 drift |
| 版本一致性 | SPEC Spec-Version vs .foundationx status version | 一致 | — | 不一致 |

### §3.2 impl_health

| 信号 | 来源 | 绿 | 黄 | 红 |
| --- | --- | --- | --- | --- |
| 覆盖率 | 模块仓 CI（§5 门禁 L0=100%/其他≥80%） | 达标 | 70-80% | <70% |
| CI 状态 | 模块仓 main 分支 CI | pass | flaky | fail |
| open blockers | `.foundationx/blockers.json` | 0 | 1-2 | ≥3 或 CRITICAL |

### §3.3 release_health

| 信号 | 来源 | 绿 | 黄 | 红 |
| --- | --- | --- | --- | --- |
| release 一致性 | registry release 投影 vs .foundationx status | 一致 | — | 不一致 |
| cadence | registry release.cadence | stable/on-demand | irregular | eol（非 archived） |

### §3.4 dependency_health

| 信号 | 来源 | 绿 | 黄 | 红 |
| --- | --- | --- | --- | --- |
| DEPS 合规 | FOUNDATION-DEPS + xlibgate import 检查 | 无违规 | — | 有违规 |
| 反向依赖数 | FOUNDATION-DEPS reverse deps | 合理范围 | 偏高 | 过高（单点依赖） |
| owner 活跃度 | registry owner + 最近 commit/review | 活跃 | 低活跃 | 缺位（[03](03-module-ownership.md) §4.3） |

---

## §4 聚合规则与阈值

### §4.1 模块健康度聚合【硬】

模块整体健康度 = 四维中最差值：

| 整体 | 条件 |
| --- | --- |
| 🟢 绿 | 四维全绿 |
| 🟡 黄 | 任一维黄，无红 |
| 🔴 红 | 任一维红 |

### §4.2 域健康度聚合【软】

域健康度 = 域内模块健康度的多数：

| 域 | 绿 | 黄 | 红 |
| --- | --- | --- | --- |
| 🟢 | 全部模块绿 | — | — |
| 🟡 | 有黄无红 | — | — |
| 🔴 | 有红 | — | — |

> 域健康度替代 STATUS.md 现有人工叙述，作为投影来源。

---

## §5 阈值触发的治理动作

| 健康度 | 触发动作 | 时效 |
| --- | --- | --- |
| 🔴 红 | 阻断该模块 factory_grade（.foundationx/status factory=false）；触发 remediation PR；owner 须响应 | 即时 |
| 🟡 黄 | 季度治理评审；在 STATUS.md / registry 标注 | 季度 |
| 🟢 绿 | 正常，无动作 | — |

### §5.1 红区 remediation 流程【硬】

1. 健康度转红 → 治理审计创建 `fix/{module}-health-{维度}` 分支
2. 诊断根因（覆盖率低/CI fail/blocker/依赖违规/owner 缺位）
3. 修复 → PR 附修复前后健康度对比
4. 健康度转绿后关闭 remediation

### §5.2 连续红区升级【硬】

模块连续 2 个评审周期（季度）处于红区 → 升级处理：
- 若根因为 owner 缺位：owner 回退组织兜底（[03](03-module-ownership.md) §4.3）
- 若根因为技术债过重：考虑 deprecated 退役评估（[07](07-module-decommission.md)）

---

## §6 数据来源与禁止编造

### §6.1 数据来源【硬】

健康度信号须来自以下来源，**禁止人工编造**：

- SPEC Status / spec drift → `module/{m}/spec/SPEC.md` + spec-lint
- 覆盖率 / CI → 模块仓 CI（引用，不内嵌）
- open blockers → `.foundationx/blockers.json`
- release 一致性 → registry.yaml + .foundationx/status 对比
- DEPS 合规 → FOUNDATION-DEPS.yaml + xlibgate
- owner 活跃度 → git 历史 + registry owner

### §6.2 与制品级评分的关系【硬】

本健康度**不替代** STRUCTURAL-SCORING 制品级评分：
- 制品级评分管单次 Spec→Code 交付的质量（98 分门禁）
- 模块健康度管模块跨多次交付的累积状态
- 制品评分失败 → 影响 impl_health（CI fail 信号）；但健康度不反向影响制品评分

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义四维健康度模型、阈值触发规则与数据来源约束 | ZoneCNH |
