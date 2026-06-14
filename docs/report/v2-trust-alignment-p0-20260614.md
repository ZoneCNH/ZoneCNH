# v2 Trust Alignment — P0 修复报告

## 执行元数据

- 执行日期：2026-06-14
- 工作分支：`docs/v2-trust-alignment-p0-20260614`
- 输入文档：`.worktree/v2.md`、`docs/report/v2-foundation-optimization-100-scan-20260614.md`
- 修复范围：本仓库（ZoneCNH/ZoneCNH）事实源对齐（P0）
- 修复状态：✅ 完成

## 背景

`.worktree/v2.md` 对 FoundationX 17 个基座模块进行了深度分析，结论是：**基座已从"搭建期"进入"可信化期"，下一轮迭代的主题不是功能扩张，而是消灭表格、README、tag、release、manifest 之间的不一致。**

`docs/report/v2-foundation-optimization-100-scan-20260614.md`（100 轮扫描）将此细化为 P0-P4 四级优先级，其中 P0 为"冻结事实源，修复本仓库漂移"。

## P0 修复清单

### ✅ 1. 旧 Foundation 文档加历史横幅

| 文件 | 问题 | 修复 |
|------|------|------|
| `module/FOUNDATION-SPEC.md` | 仍声称"第一阶段只固化 6 个基础模块"为当前状态 | 添加范围说明横幅，指向 `module/README.md` 作为当前 SSOT |
| `module/foundation-modules.md` | 仍声称"第一阶段 6 个基础模块"为当前状态 | 添加范围说明横幅，指向 `module/README.md` 和 `FOUNDATION-DEPS.yaml` |
| `module/FOUNDATION-V1.md` | 范围说明写"17 个模块"，缺少 xlib-harness/xlib-evidence/domainx | 更新为"20 个模块"，补齐缺失模块 |

### ✅ 2. STATUS.md 多维成熟度

在基座组件明细表后新增**多维成熟度展开表**，将单一 100% 百分比拆解为 8 个维度：

| 维度 | 含义 |
|------|------|
| SPEC | 规格完成 |
| IMPL | 实现完成 |
| RELEASE | tag/release/manifest 一致 |
| LIVE INT | 真实服务集成（非 mock） |
| EXT CI | 外部 CI artifact |
| ADOPT | 下游模块真实采用 |
| SOAK | 生产或类生产长时间运行 |
| FACTORY | factory_grade_allowed（最高综合等级） |

每维度以 ✅/⚠️/❌/?/N/A 标注，`?` 表示需跨仓库验证。

### ✅ 3. 跨文档一致性验证

验证了 5 个核心文档的一致性：

| 检查项 | README | ARCHITECTURE | STATUS | module/README | DEPS | 结论 |
|--------|:------:|:------------:|:------:|:-------------:|:----:|:----:|
| 20 模块数量 | ✅ | ✅ | ✅ | ✅ | ✅ | 一致 |
| xlib-standard 职责（无 generator/harness/evidence） | ✅ | ✅ | ✅ | ✅ | ✅ | 一致 |
| xlib-harness 存在 | ✅ | ✅ | ✅ | ✅ | ✅ | 一致 |
| xlib-evidence 存在 | ✅ | ✅ | ✅ | ✅ | ✅ | 一致 |
| domainx 存在 | ✅ | ✅ | ✅ | ✅ | ✅ | 一致 |
| 禁止短语"五类职责"在非 xlib-standard 文档 | — | — | — | — | — | 清洁 |

### ✅ 4. FOUNDATION-DEPS.yaml 验证

`module/FOUNDATION-DEPS.yaml` 已包含全部 20 个模块，层级正确：
- L0: kernel (stdlib-only)
- L1: configx, observex, resiliencx, schedulex, testkitx
- standard-source: xlib-standard
- harness: xlib-harness
- evidence: xlib-evidence
- gate: xlibgate
- storage: redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex
- contracts: contracts, transportx
- domain-shared: domainx

依赖矩阵、禁止依赖、特殊约束均已覆盖 20 个模块。

## 未修复项（P1-P4，需跨仓库或后续迭代）

### P1：跨仓库身份修复

`.worktree/v2.md` 识别的下游仓库 README 身份漂移需要在实际代码仓库中修复：

| 仓库 | 问题 | 优先级 |
|------|------|--------|
| contracts | README H1 仍是 xlib-standard | 🔴 P0 |
| transportx | README H1 仍是 xlib-standard | 🔴 P0 |
| redisx | README 残留标准源模板叙事 | 🟡 P1 |
| kafkax | README 残留模板生成叙事 | 🟡 P1 |
| clickhousex | 公开 no releases published | 🔴 P0 |

### P2：xlibgate 可信化门禁扩展

`module/xlibgate/SPEC.md` 已有 check/l2 基线。需新增：
- `check identity`
- `check template-residue`
- `check release-consistency --offline`
- `check maturity --factory`
- `check import-boundary`
- `check testkit-prod-import`
- `check secret-redaction`
- `fleet status`

### P3：生成型公开投影

建议从手工维护的 README/ARCHITECTURE/STATUS 状态表迁移到机器生成：
```
module/*/SPEC.md + FOUNDATION-DEPS.yaml + .foundationx/repo-contract.json
    → xlibgate fleet status
    → .foundationx/status/index.json
    → README.md / ARCHITECTURE.md / STATUS.md generated blocks
```

### P4：跨仓库发布与生产硬化

- natsx：正式四源 98+ arbiter + 生产 TLS gate
- postgresx：release history decision + production soak
- L2 adapter 统一硬化矩阵（bad credential、TLS、restart、pool exhaustion、secret redaction）

## 验收

### 本轮 P0 验收

- [x] 旧 Foundation 文档（FOUNDATION-SPEC.md、foundation-modules.md、FOUNDATION-V1.md）均有历史横幅
- [x] 所有历史文档指向 `module/README.md` 作为当前 SSOT
- [x] STATUS.md 基座表有多维成熟度展开视图
- [x] 5 个核心文档（README、ARCHITECTURE、STATUS、module/README、DEPS）20 模块数量一致
- [x] xlib-standard 在所有文档中不再被描述为 generator/harness/evidence 合体
- [x] xlib-harness、xlib-evidence、domainx 在所有文档中存在
- [x] FOUNDATION-DEPS.yaml 覆盖全部 20 模块

### 全局验收（跨仓库，待后续迭代）

参见 `docs/report/v2-foundation-optimization-100-scan-20260614.md` 第 326-336 行的最终验收标准。

## 变更文件

| 文件 | 变更类型 |
|------|----------|
| `module/FOUNDATION-SPEC.md` | 添加历史范围横幅 |
| `module/foundation-modules.md` | 添加历史范围横幅 |
| `module/FOUNDATION-V1.md` | 修复模块数量（17→20）并补齐缺失模块名 |
| `STATUS.md` | 新增基座多维成熟度展开表 |
| `docs/report/v2-trust-alignment-p0-20260614.md` | 新增（本报告） |

## 下一步

1. **立即**：提交本 PR，合并 P0 修复
2. **短期**：对 contracts/transportx/redisx/kafkax 发起跨仓库身份修复 PR
3. **中期**：扩展 xlibgate 可信化门禁（P1-P2）
4. **长期**：生成型投影 + L2 生产硬化（P3-P4）

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
