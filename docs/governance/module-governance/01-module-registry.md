# 01 模块统一注册表 — Module Registry

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 产物：[`module/registry.yaml`](../../../module/registry.yaml)

> 本专题定义模块统一注册表 `module/registry.yaml` 的 schema、登记规则与三 SSOT 引用关系，闭合"无统一 registry"缺口。

---

## §1 缺口与目标

**缺口**：新增模块时无单一权威注册表需登记；身份/状态信息分散在 `module/README.md`（人工索引）、`docs/constitution/appendix.md`（条款清单）、`module/FOUNDATION-DEPS.yaml`（依赖矩阵）、`.foundationx/status/index.json`（成熟度投影）四处，无 CI 校验一致性，模块计数口径漂移（19/20/21）。

**目标**：建立 `module/registry.yaml` 作为**模块身份与治理状态**的单一 SSOT，覆盖全域模块，引用而非重复依赖矩阵与成熟度事实。

---

## §2 registry.yaml schema

### §2.1 顶层结构

```yaml
schema_version: module-registry/v1
updated: YYYY-MM-DD
modules:
  <module_name>:
    # 身份字段（治理事实）
    repo: github.com/ZoneCNH/<module_name>
    local_path: /home/workspace/<module_name>
    domain: <foundation | l2_5 | data | analytics | decision | execution | entry | crosscut>
    layer: <L0 | L1 | storage | contracts | l2_5 | standard_source | harness | evidence | gate | business>
    arch_type: <library | cs_module | independent_process | cli | contract>
    lifecycle: <proposed | active | maintained | deprecated | archived>
    owner: ZoneCNH  # 或团队/个人；过渡期默认 ZoneCNH
    registered: YYYY-MM-DD

    # 引用字段（指向其他 SSOT）
    spec_ref: module/<module_name>/SPEC.md
    deps_ref: module/FOUNDATION-DEPS.yaml  # 仅当模块在 DEPS 中登记
    maturity_ref: .foundationx/status/index.json#<module_name>  # 仅当在 status 中登记

    # 投影字段（mirror，非 SSOT）
    spec_version: vX.Y.Z  # mirror from SPEC.md Metadata Spec-Version
```

### §2.2 字段定义

| 字段 | 类型 | 必填 | 语义 | 性质 |
| --- | --- | --- | --- | --- |
| `repo` | string | 是 | GitHub 仓库全名 | 治理事实 |
| `local_path` | string | 是 | 本地工作目录（`/home/workspace/{module}`） | 治理事实 |
| `domain` | enum | 是 | 所属域（见 §2.3） | 治理事实 |
| `layer` | enum | 是 | 架构层（见 §2.4） | 治理事实 |
| `arch_type` | enum | 是 | 架构类型（见 §2.5） | 治理事实 |
| `lifecycle` | enum | 是 | 模块生命周期状态（见 [02](02-module-lifecycle.md)） | 治理事实 |
| `owner` | string | 是 | 负责人（见 [03](03-module-ownership.md)） | 治理事实 |
| `registered` | date | 是 | 登记日期 | 治理事实 |
| `spec_ref` | path | 是 | SPEC.md 相对路径 | 引用 |
| `deps_ref` | path | 否 | FOUNDATION-DEPS.yaml（若登记） | 引用 |
| `maturity_ref` | path | 否 | .foundationx/status 条目（若登记） | 引用 |
| `spec_version` | string | 否 | SPEC.md Spec-Version 镜像 | 投影 |

### §2.3 domain 枚举

| 值 | 含义 | 对应宪法/架构 |
| --- | --- | --- |
| `foundation` | 基座层 | §3.3 基座内层级表 |
| `l2_5` | L2.5 领域共享层 | 附录 L2.5 v1.0.0 |
| `data` | 数据域 | 02-domain-layers 数据域 |
| `analytics` | 分析域 | 02-domain-layers 分析域 |
| `decision` | 决策域 | 02-domain-layers 决策域 |
| `execution` | 执行域 | 02-domain-layers 执行域 |
| `entry` | 入口 | 02-domain-layers 入口（composer） |
| `crosscut` | 横切 | 02-domain-layers 横切（alertx 等） |

### §2.4 layer 枚举

| 值 | 含义 |
| --- | --- |
| `L0` | kernel stdlib 层 |
| `L1` | 运行时基座（configx/observex/resiliencx/schedulex/bootstrap） |
| `storage` | 存储扩展（redisx/kafkax 等） |
| `contracts` | 跨域契约（contracts/transportx） |
| `l2_5` | L2.5 领域共享 |
| `standard_source` | 标准源（xlib_standard） |
| `harness` | 生成器/脚手架（xlib_harness） |
| `evidence` | 证据运行时（xlib_evidence） |
| `gate` | 机器门禁（xlibgate） |
| `business` | 业务域模块（数据/分析/决策/执行域内） |

### §2.5 arch_type 枚举

| 值 | 含义 | 模板 |
| --- | --- | --- |
| `library` | Go 库模块 | `module/_template/` |
| `cs_module` | C/S 进程模块（采集器） | `module/data_cs_module/` |
| `independent_process` | 独立进程模块（分析/聚合） | `module/data_independent_process/` |
| `cli` | CLI 工具 | 无固定模板 |
| `contract` | 契约定义模块（contracts） | 无固定模板 |

---

## §3 三 SSOT 引用关系

```
┌─────────────────────┐
│  module/registry    │ 身份 + 治理状态
│  registry.yaml      │ (repo/domain/layer/arch_type/lifecycle/owner)
└────────┬────────────┘
         │ deps_ref            │ maturity_ref
         ▼                     ▼
┌─────────────────────┐  ┌──────────────────────────┐
│ FOUNDATION-DEPS     │  │ .foundationx/status      │
│ allowed/forbidden/  │  │ version/spec/impl/       │
│ constraints/edges   │  │ release/factory (机器事实)│
└─────────────────────┘  └──────────────────────────┘
```

**引用规则【硬】**（同总纲 §3.1）：
- registry 不重复登记依赖边 → 查依赖去 FOUNDATION-DEPS
- registry 不重复登记 version/release/factory → 查成熟度去 .foundationx/status
- registry 的 `spec_version` 是投影，版本 SSOT 在 SPEC.md

---

## §4 登记变更规则

### §4.1 新增模块登记【硬】

新模块通过准入流程（[06](06-module-onboarding.md)）后，须在 registry.yaml 新增条目：

1. `lifecycle` 初始设为 `proposed`
2. `registered` 设为登记日期
3. `owner` 设为准入 ADR 决策者（或 ZoneCNH 过渡默认）
4. `spec_ref` 指向已创建的 `module/{module}/SPEC.md`（至少 Draft）
5. `deps_ref` / `maturity_ref` 暂不填（待 DEPS 扩展 / 首次 release 后补）

### §4.2 模块状态变更同步【硬】

模块 lifecycle 变更时（见 [02](02-module-lifecycle.md)），同 PR 内更新 registry.yaml：

| lifecycle 变更 | 触发条件 | 同步义务 |
| --- | --- | --- |
| proposed → active | 准入毕业（[06](06-module-onboarding.md) §6） | registry + SPEC Status 同步 |
| active → maintained | 稳定运行后主动标记 | registry 同步 |
| → deprecated | 退役 ADR Accepted（[07](07-module-decommission.md)） | registry + SPEC Status→Deprecated |
| → archived | 退役完成 | registry + 代码仓 archive |

### §4.3 字段值变更【硬】

`domain` / `layer` / `arch_type` 变更（如模块重命名、域迁移）须：
1. 提 ADR（退役/重命名类，见 [07](07-module-decommission.md)）
2. 同 PR 更新 registry.yaml + SPEC.md Metadata + module/README.md 投影

---

## §5 与投影文档的关系

registry.yaml 是**身份与治理状态 SSOT**；以下文档是其投影，须与 registry 一致：

| 投影文档 | 投影内容 | 一致性要求 |
| --- | --- | --- |
| `module/README.md` | 模块清单、分层索引 | 【软】逐步对齐；新增模块须同步 |
| `docs/constitution/appendix.md` | 条款级模块清单 | 【软】宪法附录，重大变更时同步 |
| `README.md`（根） | 公开项目清单 | 【软】公开投影，重大变更时同步 |
| `STATUS.md` | 成熟度多维表 | 【软】引用 maturity_ref，不重复 |
| `module/{module}/SPEC.md` Metadata | Layer/Owner/Status | 【硬】SPEC Metadata 须与 registry 一致 |

> 投影文档的全量对齐是后续工作；本次仅建立 registry.yaml SSOT，不强制一次性改写全部投影。

---

## §6 模块计数口径

### §6.1 计数口径钉死【硬】

消除 19/20/21 漂移，统一口径：

| 口径 | 数值 | 定义 | 权威来源 |
| --- | --- | --- | --- |
| 基座模块 | 20 | FOUNDATION-DEPS.yaml `modules` 段中 layer≠L2.5 的模块数（不含 domainx） | FOUNDATION-DEPS.yaml |
| DEPS modules 段 | 21 | FOUNDATION-DEPS.yaml `modules` 段全部条目（20 基座 + domainx） | FOUNDATION-DEPS.yaml |
| .foundationx/status | 21 | fleet-status 登记数（20 基座 + domainx；不含其余 4 个 L2.5） | .foundationx/status/index.json `total_modules` |
| L2.5 模块 | 5 | decimalx + domainx + domain_market + domain_macro + domain_exchange | registry.yaml `domain=l2_5` |
| 基座+L2.5 | 25 | 20 基座 + 5 L2.5 | registry.yaml |
| 全域模块 | registry.yaml 条目数 | 基座+L2.5+业务域+入口+横切（含 archived） | registry.yaml |

> **历史漂移根因**：根 README 曾写"19 个基座"和"20-module projection"；repo-contract.json `module_count: 20`；STATUS.md `total_modules: 21`。根因是"基座"定义不一致（是否含 domainx）与"projection"口径混淆。本表一次性钉死：基座=20（不含 domainx），domainx 归 L2.5。

### §6.2 domainx 归属裁定【硬】

`domainx` 同时出现在 FOUNDATION-DEPS.yaml `modules` 段（layer=L2.5）和 L2.5 v1.0.0 收口边界。裁定：

- **registry.yaml**：`domain: l2_5`，`layer: l2_5`（L2.5 领域共享层）
- **FOUNDATION-DEPS.yaml**：保留在 `modules` 段（依赖治理需要，作为 L2.5 的依赖锚点；DEPS modules 段=21 含 domainx）
- **.foundationx/status**：保留（layer=L2.5；total_modules=21 含 domainx）
- **计数**：domainx 计入 L2.5（domain=l2_5），**不计入基座 20**。基座 20 = DEPS modules 段 21 减去 domainx。

### §6.3 Layer 字段权威值钉死【硬】

已知不一致：`flowx` SPEC 标「执行域」但属分析域；`riskx` SPEC 标「决策域」但属执行域。registry.yaml 的 `domain` 字段为权威值，SPEC.md Metadata 须对齐：

| 模块 | registry domain（权威） | 原始 SPEC Layer | 对齐状态 |
| --- | --- | --- | --- |
| flowx | analytics | 执行域·工作流引擎 | ✅ 已对齐为「分析域·工作流引擎」(2026-06-26) |
| riskx | execution | 决策域·风控引擎 | ✅ 已对齐为「执行域·风控引擎」(2026-06-26) |
| backtestx | decision | 分析域·回测引擎 | ✅ 已对齐为「决策域·回测引擎」(2026-06-26) |
| market_data | data | L3 行情摄取与分发 | ✅ 已对齐为「数据域·行情摄取与分发」(2026-06-26) |
| macro_data | data | L3 宏观摄取与分发 | ✅ 已对齐为「数据域·宏观摄取与分发」(2026-06-26) |
| orderx | execution | 执行域·订单引擎 | ✅ 原本一致 |
| positionx | execution | 执行域·仓位管理 | ✅ 原本一致 |

> SPEC Metadata 对齐已完成（2026-06-26）。registry.yaml 的 domain 字段为权威值。

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义 registry.yaml schema、三 SSOT 引用、登记规则、计数口径与 domainx 裁定 | ZoneCNH |
