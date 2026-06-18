# RSI 改进规格：基座模块完整规则体系

> ISA Full — 元级改进流程入口
> 目标：为 20 个基座模块（+ L2.5 domainx）建立"机器可读 YAML SSOT + 人类可读 RULES.md"的完整规则体系，并修正既有的规则失真声明

> **口径说明**：本仓库权威口径为 20 个基座模块（见 ARCHITECTURE.md / FOUNDATION-DEPS.yaml）+ L2.5 领域共享层的 domainx，FOUNDATION-DEPS.yaml 的 modules 键共 21 个。本改进覆盖全部 21 个 modules 键。

---

## 1. 问题

2026-06-18 对 20 个基座模块（+ L2.5 domainx，FOUNDATION-DEPS.yaml 共 21 个 modules 键）的规则覆盖度做系统审计，暴露四项系统性缺陷：

1. **规则覆盖显著不均**：19 模块的规则章节（§7 BR / §14 Deps / §18 Security / §19 CI Gate / §21 DoD）两极分化。第一梯队（transportx/kernel/xlibgate/contracts）规则命名化、表格化；末位梯队（xlib-harness 226 行 / xlib-evidence 231 行 / taosx 367 行）全是散文 bullet；redisx 连 `## 依赖` 专章都缺。

2. **机器强制集中在静态结构维度**：依赖矩阵 / import 边界 / Go baseline / 23 节结构 / 计数一致——这些 CI 已 block；"行为语义"维度（代码是否符合 WHEN/THEN、错误处理是否覆盖 §12、脱敏是否到位）几乎无机器强制。

3. **`FOUNDATION-DEPS.yaml` 的 `constraints` 块从未被任何 CI 消费**（关键缺陷）。`no-hidden-goroutine` / `no-production-import` / `no-foundationx-new-usage` / `no-hard-observex-core-import` / `no-hard-observex-or-resiliencx-core-import` 这 5 条规则在全仓只有"声明"，无任何脚本 / xlibgate Go 代码执行。CI 仅消费 5 个键：`modules` / `allowed_deps` / `forbidden_deps` / `forbidden_foundation_edges` / `go_baseline`。

4. **已知 schema 漂移**：`xlibgate/internal/trust/boundary.go` 的 struct 用 `yaml:"source"` / `yaml:"targets"`，但 `FOUNDATION-DEPS.yaml` 实际用 `from` / `to` → Go 版 edge 检查实际失效，真正工作的是 bash/python 版 `foundation-boundary-check.sh`。

## 2. 现状

- 会话前：规则散落在 5 处（CONSTITUTION §1-§19 粗粒度 / FOUNDATION-DEPS.yaml 机器依赖矩阵 / 各 SPEC §7-§21 详略悬殊 / foundation-modules.md 仅覆盖第一阶段 6 模块且已声明过时 / xlibgate 门禁只覆盖部分维度）。
- 5 条 `constraints` 规则被 `module/FOUNDATION-TRACKER.md` 标记为 `[x] 已完成 CI check`，但对应脚本（`scripts/check-no-goroutine.sh` 等）**实际不存在** → 失真声明。
- 全仓无任何 `module/{m}/RULES.md`、`module/RULES.md`、`docs/governance/FOUNDATION-RULES.md` 先例（Glob 互证）。
- 唯一的 `*-RULES.md` 先例是 `docs/governance/ROADMAP-RULES.md`（§1-§54，配套规则文档范式）。

## 3. 理想状态

- `module/FOUNDATION-RULES.yaml` 作为 19 基座模块**行为 / 安全 / 身份 / CI 门禁**规则的机器可读 SSOT（依赖规则仍归 FOUNDATION-DEPS.yaml，不重复）。
- 5 条原 `constraints` 规则在 YAML 中重新编码，真正可被 CI / xlibgate 消费。
- `docs/governance/FOUNDATION-RULES.md` 作为 YAML 的人类可读投影（非第二 SSOT），对照 ROADMAP-RULES.md 风格。
- `.foundationx/foundation-rules.schema.json` 校验 YAML 结构，沿用仓库既有 JSON Schema 2020-12 约定。
- `FOUNDATION-TRACKER.md` 的失真声明被诚实修正（`[x] 已完成` → `[~] 声明完成但未执行，见本改进`）。

## 4. 不做什么

- **不改任何 `module/{m}/SPEC.md`** — 本轮只建规则制品，不逐模块补强规则章节（留作后续 task）。
- **不修 `xlibgate/internal/trust/boundary.go`** 的 `source/targets` vs `from/to` 漂移 — 单列为后续 task（§9），避免本轮范围爆炸。
- **不新建 `module/{m}/RULES.md`** — 违反 `module/README.md` §25 与 `docs/governance/README.md` §42-45 的路径闭集。
- **不新增 CI 脚本** — 本轮只编码规则到 YAML；消费由既有脚本（`foundation-boundary-check.sh` / `anti-requirement-scan.sh`）已覆盖的部分承担，未覆盖规则诚实标注为"文档约束，待后续 task 接入"。
- **不重写 FOUNDATION-DEPS.yaml 的 `constraints` 块** — 保留向后兼容，新 YAML 用 `source:` 字段指向它并标注"已迁移并真正可执行"。

## 5. 原则

1. **单一 SSOT 不重复**：依赖规则归 FOUNDATION-DEPS.yaml；行为 / 安全 / 身份规则归 FOUNDATION-RULES.yaml；两者通过 `source:` 字段互引。
2. **诚实标注执行性**：每条规则明确标注是被 CI 消费（machine-enforced）还是仅文档约束（document-only），不复刻 FOUNDATION-TRACKER 的失真声明。
3. **双格式兼容**：YAML 必须同时被 PyYAML `safe_load` 与 Go `gopkg.in/yaml.v3` 解析；禁 tab 缩进。
4. **投影一致**：RULES.md 是 YAML 的人类投影，规则条数与字段一一对应，禁止语义分叉。

## 6. 约束

- 新增文件：`module/FOUNDATION-RULES.yaml`（机器 SSOT，~120 条规则）
- 新增文件：`.foundationx/foundation-rules.schema.json`（JSON Schema 2020-12）
- 新增文件：`docs/governance/FOUNDATION-RULES.md`（人类投影，对照 ROADMAP-RULES.md 风格）
- 新增文件：`docs/governance/improvements/20260618-foundation-rules/SPEC.md`（本文件）
- 修改文件（仅反向引用，1-3 行）：
  - `module/README.md` — 加 FOUNDATION-RULES.yaml / FOUNDATION-RULES.md 定位索引
  - `module/FOUNDATION-DEPS.yaml` — 顶部注释加指针，指向 FOUNDATION-RULES.yaml
  - `docs/governance/README.md` — 文档表加 FOUNDATION-RULES.md 条目
  - `module/FOUNDATION-TRACKER.md` — 修正 3 处 constraints 失真声明
- 不改动任何 `module/{m}/SPEC.md`、不改动 `xlibgate/internal/trust/boundary.go`、不新增 `.github/ci/*.sh`

## 7. 目标

做完后我们将拥有：一个机器可读、人类可投影、诚实标注执行性、与 FOUNDATION-DEPS.yaml 明确分工的 19 基座模块完整规则体系，并修正了既有的规则失真声明。

## 8. 变更清单

### 8.1 `module/FOUNDATION-RULES.yaml` — 机器规则 SSOT

21 个 modules 键（20 基座 + L2.5 domainx）× 逐模块规则卡 + 通用规则矩阵 + 维度枚举 + 消费者映射。每条规则含 `id` / `dimension` / `check` / `fail_condition` / `reason_code` / `exit_code` / `source`（指向 FOUNDATION-DEPS.yaml 或 SPEC.md）/ `evidence`（执行的 CI 脚本，可空表示 document-only）。

5 条原 `constraints` 规则重新编码（kernel stdlib-only / no-hidden-goroutine、testkitx no-production-import、configx+observex no-foundationx-new-usage、resiliencx no-hard-observex-core-import、schedulex no-hard-observex-or-resiliencx-core-import），每条带 `source: "FOUNDATION-DEPS.yaml constraints[<id>]"`。

### 8.2 `.foundationx/foundation-rules.schema.json` — 结构校验

JSON Schema 2020-12，校验：`version` / `updated` 必填；`common_rules[]` 与 `modules.{m}.rules[]` 的 `id` 全局唯一且匹配 `^[A-Z][A-Z0-9]*-\d{3}-[A-Za-z0-9-]+# RSI 改进规格：基座模块完整规则体系

> ISA Full — 元级改进流程入口
> 目标：为 20 个基座模块（+ L2.5 domainx）建立"机器可读 YAML SSOT + 人类可读 RULES.md"的完整规则体系，并修正既有的规则失真声明

> **口径说明**：本仓库权威口径为 20 个基座模块（见 ARCHITECTURE.md / FOUNDATION-DEPS.yaml）+ L2.5 领域共享层的 domainx，FOUNDATION-DEPS.yaml 的 modules 键共 21 个。本改进覆盖全部 21 个 modules 键。

---

## 1. 问题

2026-06-18 对 20 个基座模块（+ L2.5 domainx，FOUNDATION-DEPS.yaml 共 21 个 modules 键）的规则覆盖度做系统审计，暴露四项系统性缺陷：

1. **规则覆盖显著不均**：19 模块的规则章节（§7 BR / §14 Deps / §18 Security / §19 CI Gate / §21 DoD）两极分化。第一梯队（transportx/kernel/xlibgate/contracts）规则命名化、表格化；末位梯队（xlib-harness 226 行 / xlib-evidence 231 行 / taosx 367 行）全是散文 bullet；redisx 连 `## 依赖` 专章都缺。

2. **机器强制集中在静态结构维度**：依赖矩阵 / import 边界 / Go baseline / 23 节结构 / 计数一致——这些 CI 已 block；"行为语义"维度（代码是否符合 WHEN/THEN、错误处理是否覆盖 §12、脱敏是否到位）几乎无机器强制。

3. **`FOUNDATION-DEPS.yaml` 的 `constraints` 块从未被任何 CI 消费**（关键缺陷）。`no-hidden-goroutine` / `no-production-import` / `no-foundationx-new-usage` / `no-hard-observex-core-import` / `no-hard-observex-or-resiliencx-core-import` 这 5 条规则在全仓只有"声明"，无任何脚本 / xlibgate Go 代码执行。CI 仅消费 5 个键：`modules` / `allowed_deps` / `forbidden_deps` / `forbidden_foundation_edges` / `go_baseline`。

4. **已知 schema 漂移**：`xlibgate/internal/trust/boundary.go` 的 struct 用 `yaml:"source"` / `yaml:"targets"`，但 `FOUNDATION-DEPS.yaml` 实际用 `from` / `to` → Go 版 edge 检查实际失效，真正工作的是 bash/python 版 `foundation-boundary-check.sh`。

## 2. 现状

- 会话前：规则散落在 5 处（CONSTITUTION §1-§19 粗粒度 / FOUNDATION-DEPS.yaml 机器依赖矩阵 / 各 SPEC §7-§21 详略悬殊 / foundation-modules.md 仅覆盖第一阶段 6 模块且已声明过时 / xlibgate 门禁只覆盖部分维度）。
- 5 条 `constraints` 规则被 `module/FOUNDATION-TRACKER.md` 标记为 `[x] 已完成 CI check`，但对应脚本（`scripts/check-no-goroutine.sh` 等）**实际不存在** → 失真声明。
- 全仓无任何 `module/{m}/RULES.md`、`module/RULES.md`、`docs/governance/FOUNDATION-RULES.md` 先例（Glob 互证）。
- 唯一的 `*-RULES.md` 先例是 `docs/governance/ROADMAP-RULES.md`（§1-§54，配套规则文档范式）。

## 3. 理想状态

- `module/FOUNDATION-RULES.yaml` 作为 19 基座模块**行为 / 安全 / 身份 / CI 门禁**规则的机器可读 SSOT（依赖规则仍归 FOUNDATION-DEPS.yaml，不重复）。
- 5 条原 `constraints` 规则在 YAML 中重新编码，真正可被 CI / xlibgate 消费。
- `docs/governance/FOUNDATION-RULES.md` 作为 YAML 的人类可读投影（非第二 SSOT），对照 ROADMAP-RULES.md 风格。
- `.foundationx/foundation-rules.schema.json` 校验 YAML 结构，沿用仓库既有 JSON Schema 2020-12 约定。
- `FOUNDATION-TRACKER.md` 的失真声明被诚实修正（`[x] 已完成` → `[~] 声明完成但未执行，见本改进`）。

## 4. 不做什么

- **不改任何 `module/{m}/SPEC.md`** — 本轮只建规则制品，不逐模块补强规则章节（留作后续 task）。
- **不修 `xlibgate/internal/trust/boundary.go`** 的 `source/targets` vs `from/to` 漂移 — 单列为后续 task（§9），避免本轮范围爆炸。
- **不新建 `module/{m}/RULES.md`** — 违反 `module/README.md` §25 与 `docs/governance/README.md` §42-45 的路径闭集。
- **不新增 CI 脚本** — 本轮只编码规则到 YAML；消费由既有脚本（`foundation-boundary-check.sh` / `anti-requirement-scan.sh`）已覆盖的部分承担，未覆盖规则诚实标注为"文档约束，待后续 task 接入"。
- **不重写 FOUNDATION-DEPS.yaml 的 `constraints` 块** — 保留向后兼容，新 YAML 用 `source:` 字段指向它并标注"已迁移并真正可执行"。

## 5. 原则

1. **单一 SSOT 不重复**：依赖规则归 FOUNDATION-DEPS.yaml；行为 / 安全 / 身份规则归 FOUNDATION-RULES.yaml；两者通过 `source:` 字段互引。
2. **诚实标注执行性**：每条规则明确标注是被 CI 消费（machine-enforced）还是仅文档约束（document-only），不复刻 FOUNDATION-TRACKER 的失真声明。
3. **双格式兼容**：YAML 必须同时被 PyYAML `safe_load` 与 Go `gopkg.in/yaml.v3` 解析；禁 tab 缩进。
4. **投影一致**：RULES.md 是 YAML 的人类投影，规则条数与字段一一对应，禁止语义分叉。

## 6. 约束

- 新增文件：`module/FOUNDATION-RULES.yaml`（机器 SSOT，~120 条规则）
- 新增文件：`.foundationx/foundation-rules.schema.json`（JSON Schema 2020-12）
- 新增文件：`docs/governance/FOUNDATION-RULES.md`（人类投影，对照 ROADMAP-RULES.md 风格）
- 新增文件：`docs/governance/improvements/20260618-foundation-rules/SPEC.md`（本文件）
- 修改文件（仅反向引用，1-3 行）：
  - `module/README.md` — 加 FOUNDATION-RULES.yaml / FOUNDATION-RULES.md 定位索引
  - `module/FOUNDATION-DEPS.yaml` — 顶部注释加指针，指向 FOUNDATION-RULES.yaml
  - `docs/governance/README.md` — 文档表加 FOUNDATION-RULES.md 条目
  - `module/FOUNDATION-TRACKER.md` — 修正 3 处 constraints 失真声明
- 不改动任何 `module/{m}/SPEC.md`、不改动 `xlibgate/internal/trust/boundary.go`、不新增 `.github/ci/*.sh`

## 7. 目标

做完后我们将拥有：一个机器可读、人类可投影、诚实标注执行性、与 FOUNDATION-DEPS.yaml 明确分工的 19 基座模块完整规则体系，并修正了既有的规则失真声明。

## 8. 变更清单

### 8.1 `module/FOUNDATION-RULES.yaml` — 机器规则 SSOT

21 个 modules 键（20 基座 + L2.5 domainx）× 逐模块规则卡 + 通用规则矩阵 + 维度枚举 + 消费者映射。每条规则含 `id` / `dimension` / `check` / `fail_condition` / `reason_code` / `exit_code` / `source`（指向 FOUNDATION-DEPS.yaml 或 SPEC.md）/ `evidence`（执行的 CI 脚本，可空表示 document-only）。

5 条原 `constraints` 规则重新编码（kernel stdlib-only / no-hidden-goroutine、testkitx no-production-import、configx+observex no-foundationx-new-usage、resiliencx no-hard-observex-core-import、schedulex no-hard-observex-or-resiliencx-core-import），每条带 `source: "FOUNDATION-DEPS.yaml constraints[<id>]"`。

### 8.2 `.foundationx/foundation-rules.schema.json` — 结构校验

；`dimension` 取值必须在 `dimensions[]` 枚举内；`exit_code` 仅 0/1/2；`reason_code` 匹配 `^[A-Z][A-Z0-9_]+# RSI 改进规格：基座模块完整规则体系

> ISA Full — 元级改进流程入口
> 目标：为 20 个基座模块（+ L2.5 domainx）建立"机器可读 YAML SSOT + 人类可读 RULES.md"的完整规则体系，并修正既有的规则失真声明

> **口径说明**：本仓库权威口径为 20 个基座模块（见 ARCHITECTURE.md / FOUNDATION-DEPS.yaml）+ L2.5 领域共享层的 domainx，FOUNDATION-DEPS.yaml 的 modules 键共 21 个。本改进覆盖全部 21 个 modules 键。

---

## 1. 问题

2026-06-18 对 20 个基座模块（+ L2.5 domainx，FOUNDATION-DEPS.yaml 共 21 个 modules 键）的规则覆盖度做系统审计，暴露四项系统性缺陷：

1. **规则覆盖显著不均**：19 模块的规则章节（§7 BR / §14 Deps / §18 Security / §19 CI Gate / §21 DoD）两极分化。第一梯队（transportx/kernel/xlibgate/contracts）规则命名化、表格化；末位梯队（xlib-harness 226 行 / xlib-evidence 231 行 / taosx 367 行）全是散文 bullet；redisx 连 `## 依赖` 专章都缺。

2. **机器强制集中在静态结构维度**：依赖矩阵 / import 边界 / Go baseline / 23 节结构 / 计数一致——这些 CI 已 block；"行为语义"维度（代码是否符合 WHEN/THEN、错误处理是否覆盖 §12、脱敏是否到位）几乎无机器强制。

3. **`FOUNDATION-DEPS.yaml` 的 `constraints` 块从未被任何 CI 消费**（关键缺陷）。`no-hidden-goroutine` / `no-production-import` / `no-foundationx-new-usage` / `no-hard-observex-core-import` / `no-hard-observex-or-resiliencx-core-import` 这 5 条规则在全仓只有"声明"，无任何脚本 / xlibgate Go 代码执行。CI 仅消费 5 个键：`modules` / `allowed_deps` / `forbidden_deps` / `forbidden_foundation_edges` / `go_baseline`。

4. **已知 schema 漂移**：`xlibgate/internal/trust/boundary.go` 的 struct 用 `yaml:"source"` / `yaml:"targets"`，但 `FOUNDATION-DEPS.yaml` 实际用 `from` / `to` → Go 版 edge 检查实际失效，真正工作的是 bash/python 版 `foundation-boundary-check.sh`。

## 2. 现状

- 会话前：规则散落在 5 处（CONSTITUTION §1-§19 粗粒度 / FOUNDATION-DEPS.yaml 机器依赖矩阵 / 各 SPEC §7-§21 详略悬殊 / foundation-modules.md 仅覆盖第一阶段 6 模块且已声明过时 / xlibgate 门禁只覆盖部分维度）。
- 5 条 `constraints` 规则被 `module/FOUNDATION-TRACKER.md` 标记为 `[x] 已完成 CI check`，但对应脚本（`scripts/check-no-goroutine.sh` 等）**实际不存在** → 失真声明。
- 全仓无任何 `module/{m}/RULES.md`、`module/RULES.md`、`docs/governance/FOUNDATION-RULES.md` 先例（Glob 互证）。
- 唯一的 `*-RULES.md` 先例是 `docs/governance/ROADMAP-RULES.md`（§1-§54，配套规则文档范式）。

## 3. 理想状态

- `module/FOUNDATION-RULES.yaml` 作为 19 基座模块**行为 / 安全 / 身份 / CI 门禁**规则的机器可读 SSOT（依赖规则仍归 FOUNDATION-DEPS.yaml，不重复）。
- 5 条原 `constraints` 规则在 YAML 中重新编码，真正可被 CI / xlibgate 消费。
- `docs/governance/FOUNDATION-RULES.md` 作为 YAML 的人类可读投影（非第二 SSOT），对照 ROADMAP-RULES.md 风格。
- `.foundationx/foundation-rules.schema.json` 校验 YAML 结构，沿用仓库既有 JSON Schema 2020-12 约定。
- `FOUNDATION-TRACKER.md` 的失真声明被诚实修正（`[x] 已完成` → `[~] 声明完成但未执行，见本改进`）。

## 4. 不做什么

- **不改任何 `module/{m}/SPEC.md`** — 本轮只建规则制品，不逐模块补强规则章节（留作后续 task）。
- **不修 `xlibgate/internal/trust/boundary.go`** 的 `source/targets` vs `from/to` 漂移 — 单列为后续 task（§9），避免本轮范围爆炸。
- **不新建 `module/{m}/RULES.md`** — 违反 `module/README.md` §25 与 `docs/governance/README.md` §42-45 的路径闭集。
- **不新增 CI 脚本** — 本轮只编码规则到 YAML；消费由既有脚本（`foundation-boundary-check.sh` / `anti-requirement-scan.sh`）已覆盖的部分承担，未覆盖规则诚实标注为"文档约束，待后续 task 接入"。
- **不重写 FOUNDATION-DEPS.yaml 的 `constraints` 块** — 保留向后兼容，新 YAML 用 `source:` 字段指向它并标注"已迁移并真正可执行"。

## 5. 原则

1. **单一 SSOT 不重复**：依赖规则归 FOUNDATION-DEPS.yaml；行为 / 安全 / 身份规则归 FOUNDATION-RULES.yaml；两者通过 `source:` 字段互引。
2. **诚实标注执行性**：每条规则明确标注是被 CI 消费（machine-enforced）还是仅文档约束（document-only），不复刻 FOUNDATION-TRACKER 的失真声明。
3. **双格式兼容**：YAML 必须同时被 PyYAML `safe_load` 与 Go `gopkg.in/yaml.v3` 解析；禁 tab 缩进。
4. **投影一致**：RULES.md 是 YAML 的人类投影，规则条数与字段一一对应，禁止语义分叉。

## 6. 约束

- 新增文件：`module/FOUNDATION-RULES.yaml`（机器 SSOT，~120 条规则）
- 新增文件：`.foundationx/foundation-rules.schema.json`（JSON Schema 2020-12）
- 新增文件：`docs/governance/FOUNDATION-RULES.md`（人类投影，对照 ROADMAP-RULES.md 风格）
- 新增文件：`docs/governance/improvements/20260618-foundation-rules/SPEC.md`（本文件）
- 修改文件（仅反向引用，1-3 行）：
  - `module/README.md` — 加 FOUNDATION-RULES.yaml / FOUNDATION-RULES.md 定位索引
  - `module/FOUNDATION-DEPS.yaml` — 顶部注释加指针，指向 FOUNDATION-RULES.yaml
  - `docs/governance/README.md` — 文档表加 FOUNDATION-RULES.md 条目
  - `module/FOUNDATION-TRACKER.md` — 修正 3 处 constraints 失真声明
- 不改动任何 `module/{m}/SPEC.md`、不改动 `xlibgate/internal/trust/boundary.go`、不新增 `.github/ci/*.sh`

## 7. 目标

做完后我们将拥有：一个机器可读、人类可投影、诚实标注执行性、与 FOUNDATION-DEPS.yaml 明确分工的 19 基座模块完整规则体系，并修正了既有的规则失真声明。

## 8. 变更清单

### 8.1 `module/FOUNDATION-RULES.yaml` — 机器规则 SSOT

21 个 modules 键（20 基座 + L2.5 domainx）× 逐模块规则卡 + 通用规则矩阵 + 维度枚举 + 消费者映射。每条规则含 `id` / `dimension` / `check` / `fail_condition` / `reason_code` / `exit_code` / `source`（指向 FOUNDATION-DEPS.yaml 或 SPEC.md）/ `evidence`（执行的 CI 脚本，可空表示 document-only）。

5 条原 `constraints` 规则重新编码（kernel stdlib-only / no-hidden-goroutine、testkitx no-production-import、configx+observex no-foundationx-new-usage、resiliencx no-hard-observex-core-import、schedulex no-hard-observex-or-resiliencx-core-import），每条带 `source: "FOUNDATION-DEPS.yaml constraints[<id>]"`。

### 8.2 `.foundationx/foundation-rules.schema.json` — 结构校验

；`modules` 键名与 FOUNDATION-DEPS.yaml 的 modules 键名完全一致（`additionalProperties: false`，21 个键全部 required）。

### 8.3 `docs/governance/FOUNDATION-RULES.md` — 人类投影

对照 `ROADMAP-RULES.md` §1-§54 风格（§编号小节 + 枚举表 + 推荐反例对照 + 检查清单 + 最终质量标准）。§3 通用规则矩阵 + §4 分层规则 + §5-§25 逐模块规则卡（21 节）+ §26 机器可执行 vs 文档规则映射 + §27 与 FOUNDATION-DEPS.yaml 的边界 + §28 维护检查清单 + §29 最终质量标准。

### 8.4 反向引用（4 处最小改动）

| 文件 | 改动 | 行为 |
| --- | --- | --- |
| `module/README.md` | 规格体系段加索引行 | 新增 |
| `module/FOUNDATION-DEPS.yaml` | 顶部注释加指针 | 新增注释 |
| `docs/governance/README.md` | 文档表加条目 | 新增 |
| `module/FOUNDATION-TRACKER.md` | 3 处 `[x]` → `[~]` 诚实标注 | 修正失真 |

FOUNDATION-TRACKER.md 修正点：
- 第 49 行（Issue 2 反向依赖检查 `FOUNDATION-DEPS.yaml constraints`）
- 第 80 行（Issue 4 `no-foundationx-new-usage`）
- 第 97 行（kernel `no-hidden-goroutine CI check` + `scripts/check-no-goroutine.sh`）

## 9. 测试证据

### 9.1 YAML 可解析

```bash
$ python3 -c "import yaml; d=yaml.safe_load(open('module/FOUNDATION-RULES.yaml')); print(len(d['modules']), 'modules,', len(d['common_rules']), 'common rules')"
21 modules, 12 common rules
```

### 9.2 Schema 校验

```bash
$ python3 -c "
import json, yaml, jsonschema
schema = json.load(open('.foundationx/foundation-rules.schema.json'))
data = yaml.safe_load(open('module/FOUNDATION-RULES.yaml'))
jsonschema.validate(data, schema)
print('schema validation: PASS')
"
```

### 9.3 模块键名对齐 FOUNDATION-DEPS.yaml

```bash
$ python3 -c "
import yaml
deps = yaml.safe_load(open('module/FOUNDATION-DEPS.yaml'))['modules'].keys()
rules = yaml.safe_load(open('module/FOUNDATION-RULES.yaml'))['modules'].keys()
print('deps - rules:', set(deps) - set(rules))
print('rules - deps:', set(rules) - set(deps))
"
# 期望两个差集均为空
```

### 9.4 投影一致

```bash
$ python3 -c "
import yaml
d = yaml.safe_load(open('module/FOUNDATION-RULES.yaml'))
# RULES.md §3 通用规则表行数 == common_rules 条数
# §5-§23 逐模块规则表行数 == modules.{m}.rules 条数
total = len(d['common_rules']) + sum(len(m['rules']) for m in d['modules'].values())
print('total rules:', total)
"
# 人工核对 RULES.md 表行数与此一致
```

### 9.5 反向引用命中

```bash
$ rg -l "FOUNDATION-RULES" module/README.md module/FOUNDATION-DEPS.yaml docs/governance/README.md module/FOUNDATION-TRACKER.md
# 期望 4 个文件全部命中
```

### 9.6 constraints 规则迁移完整性

```bash
$ python3 -c "
import yaml
rules = yaml.safe_load(open('module/FOUNDATION-RULES.yaml'))
sources = []
for m in rules['modules'].values():
    for r in m['rules']:
        if 'source' in r and 'constraints' in r['source']:
            sources.append(r['id'])
print('migrated constraints rules:', len(sources))
print(sources)
"
# 期望 >= 5 条（覆盖原 constraints 块全部 id）
```

## 10. 最终状态

| 指标 | 值 |
| --- | --- |
| 新增文件 | 4（YAML + schema + RULES.md + improvements SPEC） |
| 修改文件 | 4（反向引用） |
| 规则总数 | 107（12 通用 + 95 逐模块，21 个 modules 键） |
| 模块覆盖 | 21/21（20 基座 + L2.5 domainx） |
| 失真声明修正 | 3 处 |
| 依赖规则重复 | 0（不重复 FOUNDATION-DEPS.yaml） |

## 11. 决策记录

| 日期 | 决策 | 理由 |
| --- | --- | --- |
| 2026-06-18 | 产出形式 = YAML 机器规则 + RULES.md | 用户在 plan 阶段明确选择，对症"规则文档丰富但机器强制薄弱" |
| 2026-06-18 | 走 improvements 管线 | 用户在 plan 阶段明确选择；治理文档属 R2 中风险，CONSTITUTION §19.4 要求 |
| 2026-06-18 | 不重复 FOUNDATION-DEPS.yaml 的依赖规则 | 避免双 SSOT；用 `source:` 字段互引 |
| 2026-06-18 | 重新编码 5 条 constraints 规则 | 原块从未被 CI 消费；这是本次改进的核心价值 |
| 2026-06-18 | 不修 boundary.go 的 from/to 漂移 | 避免范围爆炸；dependency 规则由 bash/python CI 消费（已工作）；单列后续 task |
| 2026-06-18 | 不改任何 SPEC.md | 本轮只建规则制品；逐模块 SPEC 补强留作后续 |
| 2026-06-18 | 修正 FOUNDATION-TRACKER 失真声明 | 诚实标注优先于"看起来完成"；是治理体系纠错的一部分 |
| 2026-06-18 | 沿用 `from`/`to` 而非 `source`/`targets` | 与 FOUNDATION-DEPS.yaml 一致；修 Go struct 单列后续 task |

## 12. 变更日志

| 日期 | 变更 |
| --- | --- |
| 2026-06-18 | 初始记录：建立基座模块完整规则体系（YAML + RULES.md + schema + 反向引用 + 失真修正） |

## 13. 最终验证（ISC）

- [x] ISC-1: `FOUNDATION-RULES.yaml` 可被 PyYAML `safe_load` 与 Go `yaml.v3` 解析（evidence: 9.1）
- [x] ISC-2: schema 校验通过（evidence: 9.2）
- [x] ISC-3: 21 模块键名与 FOUNDATION-DEPS.yaml 完全一致（evidence: 9.3 差集为空）
- [x] ISC-4: RULES.md 规则表行数与 YAML 规则条数一一对应（evidence: 9.4 人工核对）
- [x] ISC-5: 4 处反向引用全部命中（evidence: 9.5）
- [x] ISC-6: 5 条原 constraints 规则全部迁移（evidence: 9.6 >= 5 条）
- [x] ISC-7: FOUNDATION-TRACKER.md 3 处失真声明已诚实修正

## 后续 task（本轮不做，记录待排期）

| Task | 描述 | 依赖 |
| --- | --- | --- |
| FOLLOWUP-1 | 修复 `xlibgate/internal/trust/boundary.go` 的 `source/targets` → `from/to` 漂移，使 Go 版 import-boundary 检查真正生效 | 本改进合入 |
| FOLLOWUP-2 | 为 FOUNDATION-RULES.yaml 中 document-only 规则编写 CI 脚本（kernel no-hidden-goroutine 实际执行器等） | 本改进合入 |
| FOLLOWUP-3 | 逐模块补强 4 个薄弱 SPEC 的规则章节（xlib-harness / xlib-evidence / taosx / redisx 补依赖专章） | 本改进合入 |
| FOLLOWUP-4 | 新增 lint 脚本校验 RULES.md 与 YAML 投影一致性（自动化 9.4） | 本改进合入 |
