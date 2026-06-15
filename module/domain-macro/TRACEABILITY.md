# domain-macro Traceability Matrix

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-macro` |
| 目标版本 | v1.0.0 |
| 状态 | Ready |
| 最后更新 | 2026-06-15 |

## 覆盖矩阵

| 需求 | 验收标准 | 测试证据 | 任务 | 状态 |
| --- | --- | --- | --- | --- |
| FR-MAC-001 | AC-MAC-001: 三类时间字段含义稳定 | TC-MAC-001 time invariant tests | TASK-MAC-001 | Planned |
| FR-MAC-002 | AC-MAC-002: revision/preliminary/source 可审计 | TC-MAC-002 metadata tests | TASK-MAC-002 | Planned |
| FR-MAC-003 | AC-MAC-003: IsVisibleAt fail-closed | TC-MAC-003 visibility table tests | TASK-MAC-003 | Planned |
| FR-MAC-004 | AC-MAC-004: AsOf 仅返回可见数据并 copy-on-write | TC-MAC-004 information set tests | TASK-MAC-004 | Planned |
| FR-MAC-005 | AC-MAC-005: RevisionVersion 非负且排序确定 | TC-MAC-005 revision ordering | TASK-MAC-005 | Planned |
| FR-MAC-006 | AC-MAC-006: MacroState/MacroRegimeCard validate 稳定 | TC-MAC-006 enum validation | TASK-MAC-006 | Planned |
| FR-MAC-007 | AC-MAC-007: 精度 ADR 与迁移测试完成 | TC-MAC-007 decimal/adoption scan | TASK-MAC-007 | Planned |

## 缺口

实际测试证据需在 `domain-macro` 仓库回填；本文件记录 v1.0.0 no-lookahead 与精度边界追溯基线。
