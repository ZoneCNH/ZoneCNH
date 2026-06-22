# 当前项目架构控制面分析报告

日期：2026-06-20
范围：`/home/ZoneCNH` 当前工作区只读分析
结论：需要优化，但不需要推翻当前架构
状态更新：2026-06-20 已先完成模块命名漂移首轮收敛

## 总结

当前项目的核心分层和治理原则是清晰的。主要问题不是业务架构方向错误，而是架构控制面漂移：状态源不一致、仓库边界开始模糊、模块规模扩张带来治理成本。模块命名漂移已完成首轮收敛，后续风险是旧名回流。

建议优先优化控制面，不要急着重构运行时或合并业务模块。

## 置信度

高。证据来自根治理文档、架构文档、状态文件和目录结构。

限制：本次没有进入 `/home/{module}` 的独立模块仓库逐个检查源码、import graph、测试和 tag 状态，因此本报告不是模块内部实现质量审计。

## 证据

### 项目边界

- `CONSTITUTION.md` 声明本仓库只保存公开架构、spec、索引，不应嵌入模块源码或 vendor 实现。
- `README.md`、`ARCHITECTURE.md`、`module/README.md` 共同表明本仓库更像 FoundationX 的治理、规格、架构、状态控制面，而不是单一应用仓库。
- 模块代码的本地工作目录约定为 `/home/{module}`，本仓库只引用这些路径。

### 架构分层

- `ARCHITECTURE.md` 将依赖拓扑、业务流和运行时组装分开描述。
- `x.go` 是组合根，负责 wiring 和 lifecycle。
- `contracts` 承载跨模块契约。
- `transportx` 只承载传输抽象。
- `bootstrap` 不承载业务语义、listener、contract 或 provider 实现。

这些边界是合理的，不是当前主要风险。

### 工作区状态

当前主工作区处于 dirty `main`：

- `main` 落后 `origin/main` 14 个提交。
- 多个核心文档和状态文件已修改。
- `docs/report/` 下已有未跟踪报告文件。

这与分支纪律冲突：禁止在 `main` 上直接开发，也禁止把未提交改动堆在 `main` 上。

### 状态源漂移

文档声明状态应来自：

- `.foundationx/status/index.json`
- `.foundationx/blockers.json`

但实际存在冲突：

- `.foundationx/status/index.json` 的部分模块字段显示 `release: true`、`factory: true`。
- 同一对象的 note 又说明 release/factory 应为 false。
- `.foundationx/blockers.json` 仍显示 open blockers。
- `README.md`、`STATUS.md`、`module/README.md` 对 L2.5、Foundation、factory、release 的表达并不完全一致。

这会让公开文档变成不可信投影。

### 模块命名漂移（已首轮收敛）

2026-06-20 后续修正已将公开口径收敛为：

| 历史别名 | Canonical 模块 | 当前处理 |
| --- | --- | --- |
| `risk-engine` | `riskx` | 旧名仅保留为历史别名；当前状态、依赖和发布口径均以 `riskx` 为准 |
| `order-engine` | `orderx` | 旧名仅保留为历史别名；当前状态、依赖和发布口径均以 `orderx` 为准 |
| `portfolio-engine` | `positionx` | 旧名仅保留为历史别名；当前状态、依赖和发布口径均以 `positionx` 为准 |
| `backtest-engine` | `backtestx` | 旧名仅保留为历史别名；当前状态、依赖和发布口径均以 `backtestx` 为准 |

已同步的对齐面包括 `README.md`、`ARCHITECTURE.md`、`STATUS.md`、`DATAFLOW.md`、`ROADMAP.md`、`GLOSSARY.md`、`CONSTITUTION.md`、`AGENTS.md`、`CLAUDE.md`、`module/README.md`、`module/FOUNDATION-DEPS.yaml`、`docs/production-standards/` 和相关 `module/*/SPEC.md` / `goal.md`。旧名只应出现在历史别名说明、历史报告快照，或 `module/{backtest-engine,risk-engine,order-engine,portfolio-engine}/` 历史占位目录。

### 仓库边界漂移

`patches/` 是一个 Go module，并包含可复制到模块仓库的 runtime patch bundle。

这可能是合理的临时交付桥，但需要明确生命周期。否则它会和“本仓库不收纳模块源码”的规则冲突。

### 模块规模压力

`module/` 下排除模板后有 53 个模块目录。状态面还出现 75 个组件视角。与此同时，宪法有明确的 Occam 和模块扩张约束。

这说明当前不宜继续新增模块。更合适的动作是收敛身份、状态和一条可验收纵向闭环。

## 架构问题分级

### P0：当前工作区不适合直接优化

dirty `main` 会让任何架构优化都难以审查、回滚和归因。

先处理分支和工作区，再改文档或代码。

### P1：状态 SSOT 没有真正闭合

现在存在多个事实源：

- JSON 状态
- blocker 文件
- README 投影
- STATUS 投影
- module README 投影
- 架构表格

这些投影没有强校验，导致状态互相打架。

### 已处理：模块 canonical identity 首轮收敛

旧 engine 名称和新 `x` 名称已在公开索引、状态表、依赖图、数据流和相关 SPEC 中完成首轮收敛。保留历史仓库可以，但后续修改必须继续明确：

- 哪个是 canonical name
- 哪个是 legacy alias
- 哪个只是历史兼容路径
- 哪个仍参与当前 release/factory 状态

### P2：`patches/` 边界不清

如果 `patches/` 是生成产物，应标记为临时产物或交付桥。
如果它是正式实现，应迁移到对应模块仓库。
不要让控制面仓库长期承担实现仓库职责。

### P2：模块数量已经带来治理成本

现在最危险的不是少模块，而是模块太多但状态、验收没有闭合；命名已先行收敛，但需要校验防回退。

继续新增模块会放大 drift。

## 不建议优化的部分

不建议重做这些核心分层：

- `x.go` 作为组合根
- `contracts` 和 `transportx` 分离
- `bootstrap` 不承载业务语义
- `riskx` 与 `resiliencx` 职责分离
- L2.5 共享语义层

这些约束解决的是依赖方向和运行时职责问题，当前证据看是有价值的。

## 建议优化顺序

1. 先恢复安全工作流：不要在 dirty `main` 上继续编辑。
2. 建立最小状态一致性校验：以 `.foundationx/status/index.json` 和 `.foundationx/blockers.json` 为输入，检查 README、STATUS、ARCHITECTURE、module README 的投影冲突。
3. 为 canonical module name 和 legacy alias 表增加回退校验。
4. 统一 release、factory、live、blocker 的含义。
5. 明确 `patches/` 生命周期。
6. 暂停新增模块，优先闭合 L2.5 到数据、策略、执行的一条纵向验收链路。

## 最小可执行优化

第一步不需要新框架，也不需要新管线。

只需要一个只读一致性检查：

- 读取 `.foundationx/status/index.json`
- 读取 `.foundationx/blockers.json`
- 扫描 `README.md`、`STATUS.md`、`ARCHITECTURE.md`、`DATAFLOW.md`、`ROADMAP.md`、`GLOSSARY.md`、`module/README.md`、`module/FOUNDATION-DEPS.yaml`
- 报告 release/factory/live/blocker/name alias 的冲突

如果这个检查无法通过，就不要继续手工更新公开状态表。

## 结论

需要优化。
优化对象是控制面一致性，不是核心架构重构。
模块身份已先行收敛；下一步收敛事实源，再谈更大的架构调整。
