> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](17-ai-assisted-delivery.md) · [↑ 目录](README.md) · [下一节 →](19-cri.md)

---

## 第十八条：制品完成层级

### 18.1 四级 Done

| 层级   | 名称         | 含义     | 验证方式   |
| ------ | ------------ | -------- | ---------- |
| L1     | Code Done    | 代码写完 | 编译通过   |
| L2     | Test Done    | 测试通过 | 全量测试绿 |
| L3     | Release Done | 功能上线 | 部署成功   |
| L4     | Goal Done    | 目标达成 | 指标验证   |

### 18.2 Done 规则

- Code Done ≠ Test Done ≠ Release Done ≠ Goal Done
- PR 合并至少需要 Test Done
- 功能完成需要 Goal Done
- 不得将 Code Done 宣告为功能完成

### 18.3 Goal 验证

每个 Goal 必须定义可观测的成功指标。上线后必须回看指标，验证 Goal 是否真正达成。

### 18.4 实现细节

本条款的详细 DoD 清单见 `docs/governance/DEFINITION-OF-DONE.md`。

---
