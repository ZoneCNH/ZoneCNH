# 模块治理专题索引

本目录是 [`MODULE-GOVERNANCE.md`](../MODULE-GOVERNANCE.md) 总纲的八专题展开。总纲定义效力层级、三 SSOT 边界与修订流程；本目录各专题定义具体规则。

## 八专题文档

| 编号 | 文档 | 治理域 | 关键产物 |
| --- | --- | --- | --- |
| 01 | [01-module-registry.md](01-module-registry.md) | 模块统一注册表 | `module/registry.yaml` schema 与登记规则 |
| 02 | [02-module-lifecycle.md](02-module-lifecycle.md) | 模块生命周期 | 五态状态机：proposed→active→maintained→deprecated→archived |
| 03 | [03-module-ownership.md](03-module-ownership.md) | 模块负责人 | owner 字段 + CODEOWNERS 细分规则 |
| 04 | [04-module-release-ledger.md](04-module-release-ledger.md) | 模块发布账本 | 模块级 release 追踪字段 |
| 05 | [05-module-health.md](05-module-health.md) | 模块健康度 | 四维健康度模型与阈值 |
| 06 | [06-module-onboarding.md](06-module-onboarding.md) | 新模块准入 | 准入五步流程 + 奥卡姆剃刀操作化 |
| 07 | [07-module-decommission.md](07-module-decommission.md) | 模块退役/迁移 | 退役七步流程 + archive/delete 决策 |
| 08 | [08-business-domain-deps.md](08-business-domain-deps.md) | 业务域依赖矩阵 | FOUNDATION-DEPS 扩展规划（后续工作） |

## 模板

| 模板 | 用途 |
| --- | --- |
| [templates/ADR-MODULE-ONBOARDING.md](templates/ADR-MODULE-ONBOARDING.md) | 准入 ADR 模板 |
| [templates/ADR-MODULE-DECOMMISSION.md](templates/ADR-MODULE-DECOMMISSION.md) | 退役 ADR 模板 |

## 阅读顺序

- **首次阅读**：总纲 → 子模块治理（若涉及 C/S 架构）→ 01（注册表）→ 02（生命周期）→ 其余按需
- **新增 C/S 模块**：总纲 §子模块治理 → 06（准入）→ 01（注册登记 + submodules 字段）→ 02（lifecycle=proposed）→ 03（owner）
- **新增模块**：06（准入）→ 01（注册登记）→ 02（lifecycle=proposed）→ 03（owner）
- **退役模块**：07（退役）→ 02（lifecycle=deprecated→archived）→ 01（registry 归档）
- **查询模块状态**：01（registry schema）→ 02（lifecycle 语义）→ 05（健康度）

## 路径边界

- 模块治理总纲与专题规则放在 `docs/governance/module-governance/`。
- 机器可读注册表放在 `module/registry.yaml`（与 `module/FOUNDATION-DEPS.yaml` 并列）。
- 模块级单模块规则（如 `module/binance/RULES.md`）是本体系的模块级投影，不放在本目录。
