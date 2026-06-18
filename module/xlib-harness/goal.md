# xlib-harness Goal

- 当前发布版本：v0.1.1
- 代码验收基线：/home/xlib-harness@335eef9
- 验收日期：2026-06-18

## 发布定位

xlib-harness 是 Foundation 模块的生成器与门禁执行器。从 xlib-standard 拆分而来，独立承担 Generator 和 Harness Gate 两类执行职责。

## 边界

- **拥有**：模块骨架生成、spec-lint 门禁、boundary 检查、traceability 闭合检查
- **不拥有**：标准定义（xlib-standard）、证据收集与报告（xlib-evidence）、CI 管线流程（xlibgate）

## 契约

| 契约 | 消费者 | 说明 |
|------|--------|------|
| `generate` | 模块开发者 | 从模板生成新模块骨架 |
| `check` | CI 管线 | 对单个模块执行合规门禁 |

## 测试证据

- `generate` 生成后立即 `check` 自举验证
- 每个 check 独立单元测试
- 门禁 profile 全覆盖（full / spec / boundary）

## DoD

- [x] 6 FR 全部实现并通过 SPEC.md FR-001..006 的 WHEN/THEN 验证
- [x] generate → check 自举闭环可跑通
- [x] 测试覆盖率 >= 80%
