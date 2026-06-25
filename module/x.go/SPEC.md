# x.go 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-26
- Layer: 横切 · 治理/工具 CLI
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/x.go](https://github.com/ZoneCNH/x.go)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/xlib_standard`, `module/xlib_harness`, `module/bootstrap`, `module/composer`

> 占位规格（Draft）。x.go 是治理/工具 CLI（goalcli + templatex），属横切层。命名例外（§7.2：含点号）。运行时 Composition Root 职责已由 composer 承担，x.go 不参与运行时组装。完整 23 节规格待进入 Spec→Code 管线时补齐。

---

## 1. 摘要

`module/x.go` 是治理与工具 CLI，提供 goalcli（Goal 驱动交付工作流命令行）与 templatex（模板生成与管理）能力。x.go 是开发期工具，不参与运行时进程组装——运行时 Composition Root 职责由 composer 承担。

```text
开发者命令行
  ↓
module/x.go (goalcli + templatex)
  ↓
模板生成 / Goal 工作流 / 治理脚本执行
```

---

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | goalcli 命令行（Goal 驱动交付工作流）、templatex 模板生成与管理、治理脚本入口 |
| Depends on | `module/xlib_standard`（标准事实源）、`module/xlib_harness`（生成器/门禁）、基座层 |
| Consumed by | 开发者（命令行工具）、CI（治理脚本调用） |
| Excludes | 运行时进程组装（→ composer）、业务语义（x.go 是工具，非业务模块）、Composition Root（→ bootstrap/composer） |

> 角色定位：[`module/README.md`](../README.md) §1 声明"x.go 组合根不再作为 module/ 下的模块规格维护"；本规格为治理完整性占位，记录其工具角色。

> 命名例外：[`CONSTITUTION.md` §7.2](../../docs/constitution/07-naming-conventions.md) 与 AGENTS.md 均将 x.go 列为命名例外（含点号，非 snake_case）。

---

## 3. 核心组件（占位）

| 组件 | 职责 |
| --- | --- |
| goalcli | Goal 驱动交付工作流命令行（preflight/validate/gate/release/ci） |
| templatex | 模板生成、脚手架、spec-lint 等治理工具 |

---

## Open Questions

- [ ] x.go 作为治理 CLI，是否需要完整的 23 节业务规格，还是工具文档（README/man page）更合适？
- [ ] goalcli 与 templatex 是否应拆为独立模块？
- [ ] x.go 与 xlib_harness 的职责边界（xlib_harness=生成器/门禁、x.go=CLI 入口）？
