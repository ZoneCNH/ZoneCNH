# Gate 体系

> 管线和状态机定义见 [03-pipeline.md](03-pipeline.md)。

本文档定义 Goal 驱动交付体系的 **Gate 体系（G0-G11）**。

---

## 1. Gate 类型

| 类型 | 说明 |
|------|------|
| Semantic Gate | 需要 Agent/Reviewer 语义判断 |
| Executable Gate | 可以通过命令、脚本、CI 自动判断 |
| Hybrid Gate | 先脚本检查，再人工或 Agent 解释风险 |

## 2. Gate 结构

```yaml
gate_id:
  name:
  type: semantic | executable | hybrid
  blocking: true | false
  scope:
  inputs:
  checks:
  pass_criteria:
  fail_criteria:
  outputs:
  owner:
```

## 3. 必备 Gates

| Gate | 名称 | 类型 | 检查内容 |
|------|------|------|----------|
| G0 | Context Gate | Hybrid | 上下文恢复完整 |
| G1 | Goal Gate | Semantic | Goal 符合 SMART 标准 |
| G2 | Spec Gate | Semantic | Spec 完整且可测试 |
| G3 | Design Gate | Semantic | Design 可映射到模块 |
| G4 | Plan Gate | Semantic | Plan 体现依赖顺序 |
| G5 | Task Gate | Executable | Task 原子化且有 DoD |
| G6 | Implementation Gate | Executable | 实现未越界 |
| G7 | Test Gate | Executable | 测试通过 |
| G8 | Evidence Gate | Executable | Evidence 完整 |
| G9 | Review Gate | Semantic | Review 通过 |
| G10 | Release Gate | Hybrid | Release 就绪 |
| G11 | Retrospective Gate | Semantic | 复盘完成 |

## 4. Gate 结果

```text
PASS           — 通过
PASS_WITH_RISK — 通过但有风险，需进入 Risk Register
FAIL           — 不通过，需修复
BLOCKED        — 被阻塞，需解决依赖
```
