# module/contracts

`module/contracts` 是 contracts 领域的契约 SSOT（single source of truth）。

它只描述跨模块、跨运行时可复用的稳定接口，不承载业务逻辑、持久化实现或传输实现。

## 角色定位

| 视角 | 说明 |
| --- | --- |
| Consumer | 依赖本目录中的接口、DTO、topic 常量和兼容性约束的上层模块与运行时仓库。 |
| Producer | 维护契约定义的人或流水线，负责发布版本、兼容性说明和变更记录。 |
| Stable period | 当前 `v1.x` 期间默认保持向后兼容；仅允许非破坏性增量变更。破坏性变更需进入下一个 semver-major。 |

## 目录内容

- `SPEC.md`：契约规格与版本边界
- `FEATURES.md`：功能与约束总览
- `ACCEPTANCE.md`：验收门禁与测试登记
- `TRACEABILITY.md`：需求、测试、证据追溯矩阵
- `goal.md`：目标与完成定义
- `CHANGELOG.md`：面向发布的变更记录

## 使用约定

- 只依赖这里已经冻结并文档化的导出契约。
- 新增字段、常量或行为时，优先保持兼容，并同步更新 SPEC、TRACEABILITY、ACCEPTANCE 与 CHANGELOG。
- 任何破坏性修改都必须先提升版本策略，再调整消费者。

## 参考

- `SPEC.md`
- `FEATURES.md`
- `ACCEPTANCE.md`
- `TRACEABILITY.md`
- `goal.md`
- `CHANGELOG.md`
