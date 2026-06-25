# 04 模块发布账本 — Module Release Ledger

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`VERSIONING.md`](../VERSIONING.md)（文档全局版本）、[`docs/constitution/10-change-management.md`](../../constitution/10-change-management.md) §10.4 版本字段、[`.foundationx/status/index.json`](../../../.foundationx/status/index.json)

> 本专题定义模块级 release 追踪字段与账本维护规则，闭合"无模块级 release 账本、VERSIONING.md 只管文档全局版本"缺口。

---

## §1 缺口与目标

**缺口**：版本号散落三处（SPEC Metadata `Version`、.foundationx/status `version`、STATUS.md 人工表）且口径不一；无单一模块发布账本（哪些模块发过哪些 tag/release、发布日期、release notes）；VERSIONING.md 定义文档全局版本，不覆盖模块代码仓库独立发布。

**目标**：在 registry.yaml 定义模块级 release 投影字段，引用 .foundationx/status 成熟度事实，不重复；定义账本维护规则。

---

## §2 release 账本字段

### §2.1 registry.yaml release 字段（投影）【硬】

registry.yaml 每模块可选 `release` 投影块：

```yaml
<module_name>:
  # ... 身份与治理状态字段 ...
  release:
    latest_tag: vX.Y.Z          # 投影，mirror from GitHub Release
    release_date: YYYY-MM-DD    # 投影，mirror from GitHub Release
    release_notes_ref: https://github.com/ZoneCNH/<module>/releases/tag/vX.Y.Z
    cadence: <stable | irregular | on-demand | eol>
```

### §2.2 字段定义

| 字段 | 类型 | 必填 | 语义 | 性质 |
| --- | --- | --- | --- | --- |
| `latest_tag` | string | 否 | 最新 release tag | 投影（mirror GitHub Release） |
| `release_date` | date | 否 | 最新 release 发布日期 | 投影 |
| `release_notes_ref` | url | 否 | release notes 链接 | 投影 |
| `cadence` | enum | 否 | 发布节奏 | 治理评估 |

### §2.3 cadence 枚举

| 值 | 含义 |
| --- | --- |
| `stable` | 有规律发布周期（如随 BOM freeze） |
| `irregular` | 不定期发布 |
| `on-demand` | 按需发布（如采集器随交易所变更） |
| `eol` | 已停止发布（deprecated/archived 模块） |

---

## §3 与 VERSIONING.md 的边界

| 文档 | 管辖 | 版本号语义 |
| --- | --- | --- |
| `VERSIONING.md` | **文档体系**全局版本（本仓库 ZoneCNH/ZoneCNH） | SemVer + git tag；一次发布一个版本号 |
| 本专题 | **模块代码仓库**独立发布（github.com/ZoneCNH/{module}） | 遵循宪法 §10.4 Spec-Version/Runtime-Version 分层 |

**规则【硬】**：本仓库（ZoneCNH/ZoneCNH）的文档版本走 VERSIONING.md；各模块代码仓库的 release 走本专题（registry.yaml release 投影 + 模块仓自身 release 流程）。两者独立，不互推。

---

## §4 与 .foundationx/status 的关系

### §4.1 引用规则【硬】

- registry.yaml `release.latest_tag` / `release_date` 是投影，SSOT 在 `.foundationx/status/index.json` 的 `version` 字段
- registry.yaml **不重复**登记 release/factory 等成熟度事实；查成熟度去 .foundationx/status
- 若模块不在 .foundationx/status 中（业务域模块），registry.yaml release 块可独立维护（人工填 GitHub Release 链接）

### §4.2 一致性【硬】

registry.yaml `latest_tag` 须与 .foundationx/status `version` 一致（若该模块在 status 中登记）。不一致时以 .foundationx/status 为准（机器事实 > 人工投影）。

---

## §5 账本维护规则

### §5.1 何时更新【硬】

模块发布新 release 时，同 PR 或紧随 PR 更新 registry.yaml `release` 块：

1. `latest_tag` / `release_date` 更新为新 release 值
2. `release_notes_ref` 指向新 release 链接
3. 若在 .foundationx/status 中登记，确认 status 同步更新（xlibgate fleet-status 生成）

### §5.2 谁负责更新【软】

- 模块 owner（[03](03-module-ownership.md)）负责维护 release 块
- owner 缺位时由治理审计兜底

### §5.3 CI 可校验项【开】

后续 CI 校验（registry-lint，后续工作）可检查：
- `latest_tag` 格式合规（`vX.Y.Z` SemVer）
- `release_date` 不晚于当天
- `release_notes_ref` URL 可达（软校验）

---

## §6 跨模块 release 协调

### §6.1 BOM freeze 时序【软】

跨模块 release 须遵循 [`BOM-FREEZE-GOVERNANCE.md`](../BOM-FREEZE-GOVERNANCE.md) 的 freeze 时序：

1. 基座层先 release（kernel → L1 → storage → contracts）
2. L2.5 层 release（依赖基座）
3. 业务域层 release（依赖 L2.5 + 基座）
4. BOM freeze：统一版本基线

### §6.2 依赖 release 阻塞【硬】

若模块 A 依赖模块 B，B 未发布所需版本时，A 不可发布依赖该版本的 release。FOUNDATION-DEPS.yaml 的 allowed_deps 隐含 release 时序约束。

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义模块 release 账本字段、VERSIONING/status 边界、维护规则与 BOM 协调 | ZoneCNH |
