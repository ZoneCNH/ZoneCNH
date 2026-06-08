# 19. Self-improving 复利机制

> 本文档从原 `17-maturity-and-improvement.md` 拆分而来，聚焦于 Self-improving 复利闭环、Patch 系统、多团队协作和体系演进记录。成熟度模型（L0-L5）已拆分至 [18-maturity.md](18-maturity.md)。

---

## 1. Self-improving 机制

### 核心理念

> **Retrospective 不是总结会，而是复利资产生成器。**

每次执行结束后，体系本身应该变得更好。

### 复利闭环

```text
Goal 执行完成
  ↓
Retrospective
  ↓
识别改进点
  ↓
生成 Patch（Prompt / Harness / Rule）
  ↓
验证 Patch
  ↓
合并 Patch
  ↓
下一轮 Goal 执行（使用改进后的体系）
```

### Patch 类型

| 类型 | 说明 | 示例 |
|------|------|------|
| Prompt Patch | 改进 Prompt 模板 | 增加"不允许一次性加载全部数据"约束 |
| Harness Patch | 改进 Gate 或 CI | 增加"CSV 文件必须 UTF-8 编码"自动检查 |
| Rule Patch | 改进工作流规则 | 增加"大数据量导出必须异步"规则 |

### Retrospective 标准输出

```markdown
# Retrospective: GOAL-20260601-001

## What Worked
- Spec 完整，没有遗漏需求
- Matrix 帮助发现了 2 个遗漏的边界条件

## What Failed
- Prompt 没有指定内存约束，导致 AI 生成了全量加载代码
- 测试没有覆盖大数据量场景

## Root Causes
- Prompt 模板缺少"性能约束"字段
- 测试模板缺少"性能测试"类别

## New Rules
- 所有涉及数据处理的 Task，Prompt 必须包含内存约束
- 所有导出类功能，测试必须包含大数据量场景

## Prompt Patch
PATCH-PROMPT-20260601-001:
  在 Prompt 模板的 Constraints 部分增加：
  - "如果涉及数据处理，必须指定内存约束"
  - "如果涉及文件生成，必须指定文件大小上限"

## Harness Patch
PATCH-HARNESS-20260601-001:
  在 G7 Test Gate 增加检查：
  - "导出类功能必须有大数据量测试"

## Next Goal
- 优化导出性能（基于本轮发现的内存问题）
```

### Patch 生命周期

```text
Proposed → Verified → Accepted → Applied → Effective
                                          ↓
                                    Ineffective → Reverted
```

### Patch 验证规则

```text
1. Patch 必须有明确的触发条件
2. Patch 必须有可验证的效果
3. Patch 必须有回滚方案
4. Patch 不得破坏现有流程
5. Patch 必须经过至少一轮实际执行验证
```

---

## 2. 多团队协作

### 跨团队 Goal

```text
Parent Goal: 完成订单系统重构
  ├── Team A Goal: 订单查询服务独立
  ├── Team B Goal: 订单创建服务独立
  └── Team C Goal: 订单通知服务独立
```

### 接口契约

```text
Team A 定义接口 → Team B/C 评审 → ADR 记录 → 各自独立开发 → 集成测试
```

### Registry 共享

```text
各团队共享同一个 Registry，但各自维护自己的 Task 和 Evidence。
公共接口变更必须通过 Human Approval Gate。
```

---

## 3. 体系演进记录

建议在仓库中维护一份体系演进日志：

```markdown
# Goal 体系演进日志

## v1.0 (2026-06-01)
- 初始版本：Goal → Spec → Matrix → Tasks → Plan → Prompt → Code
- 7 层工作流
- 7 道质量门禁

## v1.1 (2026-06-15)
- 增加 Lite Mode（L0/L1 变更）
- 增加 Evidence 协议
- Patch: Prompt 模板增加内存约束字段

## v1.2 (2026-07-01)
- 增加 Agent Worktree 协议
- 增加 Registry 系统
- Patch: G7 Test Gate 增加性能测试检查
```
