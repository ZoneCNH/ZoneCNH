# xlib-standard 快照边界

本文件定义本地快照的可用范围，不是可执行规格。

## 包含

- 上游固定提交 `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` 的标准目录索引。
- 52 个 FR 的本地拆分与来源定位。
- 分析子文件、覆盖清单、远端证据边界和冲突账本。

## 不包含

- 对上游仓库当前 HEAD 的实时证明。
- 对下游仓库已经采纳标准的证明。
- 对远端 branch protection、ruleset、CI run 或 release artifact 的实时证明。
- 对语义完整性的逐条审计结论。

## 更新条件

修改输入范围、上游固定提交、FR 数量或证据口径时，必须同步更新 `README.md`、`ANALYSIS.md`、`FR-DETAIL.md`、`TRACEABILITY.md`、`INDEX.md` 和本文件。
