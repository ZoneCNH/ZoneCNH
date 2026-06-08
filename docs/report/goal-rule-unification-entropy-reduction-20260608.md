# docs/goal 内部规则统一与熵减分析报告

日期：2026-06-08

范围：`docs/goal/`、`.config/goal/`、`docs/goal/tools/`

## 结论

`docs/goal/` 当前的结构性混乱不是规则不够，而是同一概念被多套轴线重复定义：阶段、状态、Gate、Artifact、Registry、CI profile 混在一起。继续补文档只会增熵，应该先做规则内核，把所有规则收敛到少数唯一来源。

推荐目标结构：

```text
Rule Kernel -> Owner Docs -> Runtime Config -> Tools -> Examples
```

即核心枚举和路径只有一个地方定义，文档引用它，配置遵守它，脚本校验它，示例不能创造新规则。

## 当前主要熵源

### 1. Phase 和 State 混用

- `docs/goal/README.md` 讲 11 层流程。
- `docs/goal/03-pipeline.md` 写 13 个 pipeline state。
- `.config/goal/pipeline/state.yaml` 又出现 `SPEC_DRAFTING`、`MATRIX_READY`、`PROMPT_READY`、`CODE_GENERATED` 等另一套状态。

结果是无法稳定判断 `Prompt` 到底是阶段、状态、Artifact，还是 Gate 的前置条件。

### 2. Gate 命名空间泄漏

- `docs/goal/04-gates.md` 明确 G0-G11 是唯一 Gate 序列。
- 但 CI/CD、人审、模块 profile 容易演化出新的门禁编号。

正确做法：G0-G11 是唯一 Gate；CI、人审、模块约束只能是某个 Gate 下的 check 或 profile。

### 3. Matrix / Evidence 横切制品被阶段化

- Matrix 是横切制品，但在配置和状态里容易变成主流程节点。
- Evidence 有时绑定 AC，有时绑定 Test。
- Evidence 路径存在 flat 与 nested 两种说法。

这会导致追溯链无法稳定验证。

### 4. Registry 边界不清

- `docs/goal/README.md` 说 Registry 有 6 个文件。
- `docs/goal/15-registry.md` 又说 7 个子系统，并把 matrix、gates、pipeline、evidence、prompts 一起纳入描述。

建议 Registry 只管业务对象索引：goal、task、issue、release、risk、decision。Matrix、Gate、Pipeline、Evidence 是旁路系统，不属于 Registry 文件数。

### 5. 工具编码旧规则

- `docs/goal/tools/gate-check.sh` 默认找 `.config/goal/matrix.yaml`，但实际矩阵在 `.config/goal/matrix/matrix.yaml`。
- Matrix 状态实际使用 `Verified`，脚本却统计 `Done|Implemented|Tested`。

这说明工具不是规则执行者，而是另一个规则来源。

## 统一模型

保留 5 个概念轴，强制一事一轴：

```text
Phase    = 人类交付层级
State    = 机器状态机
Gate     = 阻塞性通过条件
Artifact = 可追溯制品
Status   = 对象自身状态
```

### 建议规则内核

```yaml
phases:
  - GOAL
  - SPEC
  - DESIGN
  - PLAN
  - TASKS
  - PROMPT
  - CODE
  - TEST
  - REVIEW
  - RELEASE
  - RETROSPECTIVE

pipeline_states:
  - INIT
  - CONTEXT_READY
  - GOAL_READY
  - SPEC_READY
  - DESIGN_READY
  - PLAN_READY
  - TASKS_READY
  - EXECUTING
  - VERIFYING
  - REVIEWING
  - RELEASING
  - RETROSPECTING
  - DONE

gate_ids:
  - G0
  - G1
  - G2
  - G3
  - G4
  - G5
  - G6
  - G7
  - G8
  - G9
  - G10
  - G11

matrix:
  path: .config/goal/matrix/matrix.yaml
  status:
    - Unmapped
    - Mapped
    - Linked
    - Verified
    - Drifted
    - Stale

evidence:
  path_pattern: .config/goal/evidence/EVID-*.md
  id_format: EVID-AC-{SPEC}-{AC_NUM}-{NNN}
```

不要强行让 11 个 Phase 和 13 个 State 一一对应。它们不是同一层东西。

运行态可以这样表达：

```yaml
current_phase: PROMPT
pipeline_state: EXECUTING
phase_status: READY
gates_passed: [G0, G1, G2, G3, G4, G5]
artifacts_ready: [matrix, prompt]
```

这样 `PROMPT_READY` 不需要成为顶层 state，它只是 `current_phase + phase_status` 的组合。

## 文档归属

| 文件 | 只能负责 |
|------|----------|
| `README.md` | 总览、入口、索引 |
| `03-pipeline.md` | Phase、pipeline state、状态转换 |
| `04-gates.md` | G0-G11，且唯一 Gate 命名空间 |
| `05-layer-standards.md` | 每层输入、输出、DoR、DoD |
| `07-id-system.md` | ID grammar，不定义流程 |
| `09-traceability.md` | Matrix schema、覆盖率、漂移规则 |
| `15-registry.md` | Registry 对象文件，不纳入 matrix/gates/pipeline |
| `16-ci-cd.md` | CI check 映射，不新增 Gate |
| `.config/goal/*` | 运行数据，不创造新枚举 |
| `tools/*` | 读取规则内核并执行校验 |

## 熵减执行顺序

1. 冻结规则新增
   - 先不继续补新 Gate、新状态、新路径。
   - 把所有 `State`、`Gate`、`Status`、`ID`、`Path`、`Schema` 定义点列出来。

2. 建立 Rule Kernel
   - 新建核心规则文件，例如 `docs/goal/00-rule-kernel.md` 或 `.config/goal/schema/rules.yaml`。
   - 建议 YAML 为机器权威，Markdown 解释它。

3. 合并状态机
   - `03-pipeline.md` 只保留一套 pipeline state。
   - `.config/goal/pipeline/state.yaml` 删除独立状态枚举，改为 `pipeline_state + current_phase + phase_status`。

4. 收敛 Gate
   - `G0-G11` 保持唯一。
   - `CI-G*`、`H-G*`、`XG-*` 全部降级为 `checks` 或 `profiles`。

5. 统一 Evidence / Matrix
   - Matrix 路径统一为 `.config/goal/matrix/matrix.yaml`。
   - Matrix status 统一承认 `Verified`。
   - Evidence ID 统一为 AC-bound，Test ID 作为 required binding 字段，而不是另一套 ID 轴。

6. 清理 Registry
   - Registry 固定为 6 个业务索引文件。
   - Matrix、Gates、Pipeline、Evidence、Prompts 不再算 Registry 子系统，只作为 Goal config center 的旁路组件。

7. 让工具服从规则
   - `gate-check.sh` 不再硬编码路径和状态。
   - 改为读取 kernel/schema。
   - 增加 drift check：文档、配置、工具里的枚举值必须都在 kernel 里。

## 验收标准

熵减完成后，应该满足这些条件：

```text
1. 任意状态值只在 Rule Kernel 中定义一次。
2. G0-G11 是唯一 Gate 编号。
3. Matrix 只作为横切制品，不作为主流程阶段。
4. Evidence 路径、ID、required fields 在 README / 07 / 15 / tools 中一致。
5. .config/goal/pipeline/state.yaml 没有 kernel 外状态。
6. gate-check.sh 识别 Verified，并使用正确 matrix 路径。
7. 模块专属规则只存在 profile，不污染核心规则。
```

## 评分判断

当前结构分约为 67/100。主要扣分来自状态机分裂、Gate 命名空间泄漏、Evidence/Matrix 路径和状态不一致、Registry 边界漂移、工具与文档规则不一致。

完成本报告建议的第一轮熵减后，结构分可以提升到 88-92/100。若要达到 98 分门禁，需要进一步补齐可执行 schema 校验和自动 drift 检测，让文档、配置、工具无法各自演化规则。
