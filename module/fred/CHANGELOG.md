# Changelog — fred

> 版本事实源：`spec/SPEC.md` Spec-Version · Release 事实源：GitHub Release

## [Unreleased]

- 模块尚未发布，CHANGELOG 待首次 release 时填充。
- 文档：新增 `spec/SERIES-CATALOG.md`，将 `.beads/1.md` 的 12 类 90 序列系统化纳入 `fred` 采集范围，建立 P0/P1/P2 优先级分层与 §5.2 初始包差异对账（OPEN-010）。
- 文档：`spec/SPEC.md` §5.4 引用权威系列目录，§9.3 引用外部路由接口；§23 新增 OPEN-010；`README.md` 文档索引与“核心指标包”补指向与别名统一说明。
- 文档：`spec/SERIES-CATALOG.md` 追加 §9 endpoint→领域覆盖映射（支撑 BR-010 跨入口对账）与 §10 FR-016 可度量覆盖审计目标表。
- 文档：将目录接入管线——`spec/client/SPEC.md` FR-C001 引用 P0/P1/P2；`matrix/TRACEABILITY.md` G-SC-008/FR-016 标注审计目标全集；`plan/PLAN.md` 阶段 2 与 `tasks/client/TASK-FRED-CLIENT-001` 明确 P0→P1→P2 采集顺序。
- 文档：新增 `spec/SERIES-API.md`，定义 `source_component` 路由接口、authority registry、错误码与外部路由集成测试用例（IT-ROUTING-001..006）；`spec/ACCEPTANCE.md` 注册 V-017 / TC-011；`matrix/TRACEABILITY.md` 仪表盘更新 TC=11、合计=47。
- 文档：`spec/SERIES-CATALOG.md` 补入 `DFEDTARU`（§3.4 货币政策）与 `NROU`（§3.2 就业），更新序列表总数为 90；`design/RUNTIME-MAPPING.md` 新增 §5 系列目录、外部路由与派生序列运行时映射；`gate/BOUNDARY-GATES.md` 新增 BG-013；`spec/FEATURES.md` 新增系列目录与外部路由能力投影；`spec/server/SPEC.md`/`plan/server/PLAN.md`/`tasks/server/TASK-FRED-SERVER-002` 接入外部路由 API 行为。
