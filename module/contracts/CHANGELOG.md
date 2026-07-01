# CHANGELOG

本文只记录 `module/contracts` 的文档事实同步，不是发布日志。

## 2026-06-21

- 将 `module/contracts` 文档基线同步到 `/home/workspace/contracts/pkg/contracts` 的当前导出面。
- 更新 `README.md`、`SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md` 和任务拆分，覆盖当前 P0/P1 DTO、provider ports、兼容投影和 unary ingestion wire contract。
- 删除 `stable period`、Topic constants、`v1.0.1`、旧 DTO 名称、旧 provider 方法名与双向流 ingestion 叙事。

## 2026-06-22

- 将 `RejectCode` 的 canonical 事实回收为 runtime truth：`AllRejectCodes()` 现在记录为 10 项，并将 `RejectUnsupportedChannel` 视为 canonical 列表的一部分。
- 回填 `README.md`、`SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`goal.md` 与任务文件中的旧术语。
