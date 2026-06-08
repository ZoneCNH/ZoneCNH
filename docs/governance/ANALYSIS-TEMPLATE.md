# 分析快照模板（ANALYSIS-TEMPLATE）

本模板适用于"上游仓库的本地分析快照"类目录，**不是**可执行规格模板（spec 模板见 `SPEC-TEMPLATE.md`）。

## 使用场景

- 目录定位为"上游仓库在本仓库的分析快照"；
- 本仓库无对应实现工具链（make / 测试 runtime / 发布 artifact）；
- 不在本仓库声明 CI gate / Release DoD / 裁决标准。

## 目录骨架

```text
module/<module>/
├── README.md              # 目录索引（强制）
├── ANALYSIS.md            # 分析入口（强制）
├── INDEX.md               # 上游 SSOT 索引（强制）
├── SNAPSHOT-BOUNDARY.md   # 快照 vs 现实边界（强制）
├── CONFLICT-LEDGER.md     # 同 SSOT 内部冲突（可选）
├── TRACEABILITY.md        # 章节级追溯（可选）
├── COVERAGE-MANIFEST.md   # 输入文件清单（可选）
├── FR-DETAIL.md           # FR 详细规格（可选）
├── REMOTE-EVIDENCE.md     # 远端 pinned 证据（可选）
└── analysis/              # 子分析（可选）
    └── <topic>.md
```

## 强制元信息块

每份分析文件顶部必须包含：

```markdown
- Snapshot-Date: YYYY-MM-DD
- Upstream-Commit: `<sha40>` (<tag>)
- Analysis-Version: vX.Y.Z
- Parent: ../ANALYSIS.md      # 仅 analysis/*.md 需要
```

## ANALYSIS.md 必备章节

1. 子分析索引
2. 快照事实层级
3. 问题（Problem）摘要
4. 目标（Goals）摘要
5. Non-goals
6. 消费者（Consumers）
7. 关键数字与职责分布
8. 冲突总览
9. 追溯口径

## analysis/<topic>.md 必备章节

1. 分析边界
2. 覆盖职责（FR 摘要）
3. 主题正文
4. 边界场景 / 失败语义（可选）
5. 与其他子分析的交叉引用
6. TC / EC 命名空间（可选）
7. 附录或同义引用表（可选）

## 禁止事项

- 禁止在本仓库声明 release-ready / adopted / remote-enabled 状态；
- 禁止使用"本规格"措辞（应使用"本分析" / "上游规格"）；
- 禁止使用旧编号体系（如孤儿 ### 7.x / ### 22.x）；
- 禁止跨子分析使用裸 TC-NNN（应使用 `<module>-TC-NNN`）。
