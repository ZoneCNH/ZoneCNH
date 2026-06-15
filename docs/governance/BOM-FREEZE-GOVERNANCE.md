# BOM 与 Freeze Governance 归档决策

## 决策

BOM 与 freeze-governance 不能只停留在规划文本中；一旦它们被用于发布、factory-grade、API freeze 或跨模块采用声明，就必须有 repo-local 可追溯产物。当前边界如下：

| 主题 | 决策 | Repo-local 产物 | 不再新增的产物 |
| ---- | ---- | --------------- | -------------- |
| Foundation BOM | 已经是 repo-local 产物，继续复用现有文件。 | `foundation-bom.yaml`，来源为 `.foundationx/status/index.json` 与 `.foundationx/blockers.json`。 | 不复制第二份 Foundation BOM。 |
| Freeze governance | 作为治理边界留在 repo-local 文档中；只有已有证据支持的 freeze 才能写成完成态。 | 本文件、`module/FOUNDATION-DEPS.yaml` 的 freeze gate、相关模块/合约仓库中的 freeze 声明。 | 不把尚未落地的 API freeze、release gate 或 SBOM/provenance 写成已完成事实。 |
| 未来 SBOM / provenance | 暂保持规划项，直到有生成脚本、CI gate 或发布证据。 | 后续应接入 `release/manifest/latest.json` 或 release evidence。 | 不在当前仓库手写静态 SBOM/provenance 断言。 |

## 依据

| 证据 | 含义 |
| ---- | ---- |
| `foundation-bom.yaml` | 已存在 Foundation BOM 投影，含模块、release model、blocker 与 factory-grade allowed 状态。 |
| `.foundationx/status/index.json` / `.foundationx/blockers.json` | README 与 STATUS 声明的机器事实层，约束公开 release/factory 投影。 |
| `README.md` / `STATUS.md` | 公开说明 L2.5 v1.0.0 仍是文档/目标执行基线，不是 API freeze、CI release gate、tag 或 GitHub Release。 |
| `module/FOUNDATION-DEPS.yaml` | 已记录 `freeze_gate`，说明 foundationx 新增依赖 gate 是当前可执行 freeze 边界。 |
| `module/FOUNDATION-TRACKER.md` | 记录 configx/observex freeze、API freeze 文件与 CI gate 目标。 |
| `docs/governance/README.md` | 确认治理规则、模板、rubric 与门禁协议应放在 `docs/governance/`。 |

## 操作规则

1. 修改 `foundation-bom.yaml` 前，必须先确认 `.foundationx/status/index.json` 与 `.foundationx/blockers.json` 的事实层是否同步；该文件属于版本触发清单，变更时遵循版本 bump 协议。
2. Freeze 声明只能使用两种状态：
   - **已落地**：存在 repo-local 文件、脚本、CI gate 或模块仓库证据。
   - **规划中**：缺少上述证据时，只能写入计划或 blocker，不得写成 release/factory 完成态。
3. 新增模块级 API freeze 时，优先落在对应模块或合约产物中；本仓库只保存跨模块治理规则与索引。
4. 新增 SBOM/provenance 时，必须是脚本或 CI 可再生成的 release evidence；不得手写不可验证的静态结论。

## 结论

- BOM：保留为 repo-local artifact，复用并维护 `foundation-bom.yaml`。
- Freeze governance：保留为 repo-local governance artifact，本文件定义声明边界；具体 freeze 证据按模块或合约产物落地。
- 尚无执行证据的 SBOM/provenance/release-gate 想法：保持 planning-only，直到生成路径和验证门禁存在。
