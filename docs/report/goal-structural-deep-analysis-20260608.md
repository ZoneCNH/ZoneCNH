# docs/goal 结构性问题深度分析与评分

- 分析对象：`docs/goal/`、`.config/goal/`、`docs/goal/tools/`
- 分析日期：2026-06-08
- 结论：Changes requested
- 结构健康分：67/100
- 置信度：High
- 停止条件：已完成文档、运行态配置、校验工具三方交叉取证，并运行现有 lint / matrix / gate checks。

## 1. 总评

`docs/goal/` 的问题不是文档数量不足，而是结构主干尚未收敛。当前目录已经覆盖 Goal、Spec、Design、Plan、Gate、Matrix、Registry、Evidence、Runtime、CI/CD 等主题，但多个“权威源”之间存在状态机、Gate 命名空间、Evidence 规范、Matrix schema、Registry 目录模型和工具默认路径的系统性漂移。

最核心风险是：读者按 `docs/goal/README.md` 的流程理解，运行态按 `.config/goal/pipeline/state.yaml` 执行，校验工具按 `docs/goal/tools/*.sh|*.py` 判定时，三者无法稳定闭环。也就是说，体系看起来完整，但不能保证一个 Goal 从定义到发布时被同一套状态、同一套 Gate、同一套追溯与证据规则约束。

当前不建议进入“可执行标准”或“团队默认流程”状态。建议先做一次标准收敛：先固定状态机、Gate namespace、Evidence schema、Matrix schema 和路径契约，再清理章节、链接、工具与示例。

## 2. 评分账本

| 维度                           |    权重 |   得分 | 主要扣分点                                                                            |
| ------------------------------ | ------: | -----: | ------------------------------------------------------------------------------------- |
| 流程 / 状态机一致性            |      20 |     10 | README、`03-pipeline.md`、`.config/goal/pipeline/state.yaml` 的阶段与状态不一致       |
| Gate 体系收敛                  |      15 |      8 | `G0-G11` 被声明为唯一权威，但 Runtime / CI / x.go 又引入 `H-G*`、`CI-G*`、`XG-G*`     |
| ID / Schema / Path 一致性      |      20 |     10 | Evidence、Matrix、Registry 的 ID、字段、路径和工具默认值存在多套定义                  |
| Matrix / Traceability 可执行性 |      15 |      8 | 实际 Matrix 使用 `Verified`，工具只统计 `Done/Implemented/Tested`，且默认路径错误     |
| Evidence / Prompt 闭环         |      15 |      7 | Evidence 目录为空；G7 可通过任务 YAML 里的 evidence 字段，G8 又因实际文件缺失失败     |
| 文档组织 / 维护边界            |      10 |      7 | 通用 Goal 标准混入 x.go 专用规则，Registry 子系统数量口径不一致，存在重复行和失效锚点 |
| 工具校验可信度                 |       5 |      2 | lint 通过但 gate/matrix 失败；修正路径后仍出现 shell arithmetic 错误                  |
| **总分**                       | **100** | **67** | 未达到结构可执行标准                                                                  |

## 3. P0 结构问题

### P0-1 Pipeline 状态机与运行态配置分裂

证据：

- `docs/goal/README.md:20` 描述主流程为 `Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective`。
- `docs/goal/03-pipeline.md:39-42` 描述正常状态流为 `INIT → CONTEXT_READY → GOAL_READY → SPEC_READY → DESIGN_READY → PLAN_READY → TASKS_READY → EXECUTING → VERIFYING → REVIEWING → RELEASING → RETROSPECTING → DONE`。
- `docs/goal/03-pipeline.md:74-87` 的转换表从 `TASKS_READY` 直接进入 `EXECUTING`，没有 `PROMPT_READY`、`CODE_GENERATED`、`TEST_PASSED` 等独立状态。
- `.config/goal/pipeline/state.yaml:2` 声明 authority source 是 `docs/goal/03-pipeline.md`。
- `.config/goal/pipeline/state.yaml:18-26` 又定义 `SPEC_DRAFTING`、`SPEC_REVIEWING`、`SPEC_APPROVED`。
- `.config/goal/pipeline/state.yaml:58-70` 定义 `MATRIX_READY`、`PROMPT_READY`、`CODE_GENERATED`、`TEST_PASSED`。
- `.config/goal/pipeline/state.yaml:105-111` 的 normal flow 还包含 `DESIGN_REVIEWING`、`PLAN_REVIEWING`、`REVIEW_APPROVED`、`RELEASE_READY`、`RELEASED` 等文档主状态机没有的状态。

影响：

同一个 Goal 的生命周期无法由一个确定状态机解释。读文档的人会把 `Spec/Prompt/Code/Test` 当主流程阶段；运行态 YAML 会把更细的 drafting/reviewing/approved 状态当真实状态；`03-pipeline.md` 又把实现和验证压缩为 `EXECUTING/VERIFYING`。这会直接影响 Gate 触发点、Matrix 更新时间点、Evidence 收集时机和自动化恢复逻辑。

修复方向：

先选择一种状态模型：

- 方案 A：把 README 的 `Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective` 全部定义为一等状态，并把 `.config/goal/pipeline/state.yaml`、Gate 表、工具全部对齐。
- 方案 B：保留 `03-pipeline.md` 的粗粒度状态机，把 `Prompt/Code/Test/MATRIX_READY` 作为状态内 artifact/checkpoint，而不是主状态。

无论选择哪种，`.config/goal/pipeline/state.yaml` 不能继续声明以 `03-pipeline.md` 为 authority source 却定义另一套状态宇宙。

### P0-2 Gate 命名空间失控

证据：

- `docs/goal/04-gates.md:5` 明确声明 Gate `G0-G11` 是权威，其他文档不能引入独立 Gate 编号。
- `docs/goal/13-runtime-engine.md:222-233` 定义 `H-G1 ~ H-G8` 审批门禁。
- `docs/goal/16-ci-cd.md:11-24` 定义 `CI-G0 ~ CI-G9`。
- `docs/goal/16-ci-cd.md:193-204` 定义 `XG-G1 ~ XG-G8`。

影响：

Gate 被声明为单一编号体系，但多个文档继续引入局部 Gate 编号。结果是 Gate 的“谁有资格阻断流程”“谁是主门禁”“哪些只是检查项”没有清晰边界。CI、Runtime 和模块 profile 的 Gate 编号会和 `G0-G11` 形成平行权威，破坏管线判定的可解释性。

修复方向：

保留 `G0-G11` 作为唯一 top-level Gate。把 `H-G*`、`CI-G*`、`XG-G*` 改为：

- `Gx.checks[]` 下的命名检查项；或
- `profile: human-approval|ci|x.go` 的子规则；或
- `gate_id: G7`, `check_id: CI-coverage` 这样的二级标识。

不要让它们继续作为独立 Gate namespace 出现。

## 4. P1 结构问题

### P1-1 Evidence 身份、字段和目录布局处于半迁移状态

证据：

- `docs/goal/07-id-system.md:24` 定义 Evidence ID 为 `EVID-AC-{SPEC}-{NUM}-{NNN}`。
- `docs/goal/07-id-system.md:40` 又要求所有 Evidence 必须绑定 Test ID。
- `docs/goal/07-id-system.md:63` 的迁移表显示从 `EVID-<test-id>-NNN` 迁移到 `EVID-AC-{SPEC}-{NUM}-{NNN}`。
- `docs/goal/13-runtime-engine.md:121-134` 定义 Evidence 文件字段时仍使用泛化 `EVID-xxx`，并要求 `Task ID`、`Goal ID`、`Status`、`Files Changed`、`Commands Run` 等字段。
- `docs/goal/tools/gate-check.sh:89-90` 只检查名为 `evidence.md` 的文件，并要求包含 `"Evidence ID" "Test ID" "Status" "Files Changed" "Commands Run"`。
- `docs/goal/README.md:47-48` 和 `.config/goal/README.md:20` 描述 Evidence 路径为 `.config/goal/evidence/EVID-*.md`。
- `docs/goal/15-registry.md:83-84` 的示例路径是 `.config/goal/evidence/2025-12-26/TASK-.../EVID-AC-....md`。
- 实际 `.config/goal/evidence/` 当前没有 Evidence 文件，`gate-check.sh` 的 G8 因此失败。

影响：

Evidence 是交付体系的审计核心，但当前存在三组没有统一的契约：

- 身份绑定：AC-bound 还是 Test-bound。
- 文件结构：flat `EVID-*.md` 还是按日期和 Task 嵌套。
- 字段 schema：Evidence 文件必须包含 Test ID，还是 Task / Goal / AC / command / artifact 的组合。

这会让 Gate 对 Evidence 的判断不稳定：同一套任务 YAML 里有 evidence 字段时 G7 可通过，但实际 Evidence 文件缺失时 G8 失败。

修复方向：

完成 Evidence 迁移，不要停在半迁移状态。建议采用：

- `evidence_id: EVID-AC-{SPEC}-{AC_NUM}-{NNN}` 作为主 ID。
- `test_ids[]` 作为可选或必填关联字段，但不再嵌入 Evidence ID。
- 目录布局二选一：flat `.config/goal/evidence/EVID-*.md`，或嵌套 `.config/goal/evidence/{date}/{task_id}/EVID-*.md`。选定后同步 README、Registry、Runtime、`evidence-collect.sh` 和 `gate-check.sh`。
- Gate 只检查被标准定义为 required 的字段，不再混用旧字段。

### P1-2 Matrix schema、状态枚举和工具默认路径不能 round-trip

证据：

- `.config/goal/matrix/matrix.yaml:3` 的实际路径是 `.config/goal/matrix/matrix.yaml`。
- `docs/goal/tools/matrix-gen.py:29` 默认路径是 `.config/goal/matrix.yaml`。
- `docs/goal/tools/gate-check.sh:13` 默认路径也是 `.config/goal/matrix.yaml`。
- `.config/goal/matrix/matrix.yaml:14,27,40,53,66` 的实际状态均为 `Verified`。
- `.config/goal/matrix/matrix.yaml:71-73` 的状态枚举是 `Unmapped → Mapped → Linked → Verified → Drifted → Stale`。
- `docs/goal/tools/matrix-gen.py:164-165` 只把 `Done|Implemented|Tested` 计为已完成。
- `docs/goal/tools/gate-check.sh:112` 同样只统计 `Done|Implemented|Tested`。
- `.config/goal/matrix/matrix.yaml:78-82` 的覆盖目标是 95%，但 `matrix-gen.py:205-208` 的通过阈值是 70%。

已验证现象：

- `python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml` 失败，显示总行数 5、已完成 0、覆盖率 0%。
- `bash docs/goal/tools/gate-check.sh /home/ZoneCNH` 失败，默认找不到 `.config/goal/matrix.yaml`。
- 设置 `GOAL_MATRIX_FILE=.config/goal/matrix/matrix.yaml` 后，`gate-check.sh` 仍出现 arithmetic syntax error。

影响：

Matrix 是横切追溯制品，但当前实际文件、文档目标和工具判定无法闭环。最严重的是，真实 Matrix 已经把行标为 `Verified`，工具仍判为 0% 完成。这会导致 false negative；反过来，如果另一个文件按旧 schema 生成，也可能绕过新的 Verified 模型。

修复方向：

- 统一 Matrix path：`.config/goal/matrix/matrix.yaml`。
- 统一状态枚举，至少让工具识别 `Verified`。
- 统一字段名：实际文件与生成器目前在 `requirement` / `requirement_id` / `acceptance_criteria` / `tests` 等字段上不完全一致。
- 把覆盖阈值统一为文档声明的 95%，或明确 70% 是临时 bootstrap 门槛。
- 修复 `gate-check.sh` 在 corrected matrix path 下的 arithmetic 解析错误。

### P1-3 Registry 的对象模型和目录模型没有形成稳定权威

证据：

- `docs/goal/README.md:29-34` 和 `README.md:34-40` 口径中 Registry subtree 是 6 个文件。
- `docs/goal/15-registry.md:3` 声称 Registry 是 7 个子系统。
- `docs/goal/15-registry.md:13-23` 的路径表实际包含 6 个 registry 文件，以及 `matrix/`、`gates/`、`pipeline/`、`evidence/`、`prompts/` 等非 registry 域。
- `docs/goal/15-registry.md:30-36` 定义 Goal Registry 字段为 `goal_id`、`title`、`status`、`owner`、`priority`、`north_star`、`current_phase`。
- `docs/goal/15-registry.md:54-65` 再把这些字段映射到 `02-goal-standard.md` 和 `03-pipeline.md`，其中 status anchor 指向 `03-pipeline.md#25-状态枚举汇总`，但当前 `03-pipeline.md` 对应标题是 `2.5 对象状态总表`。

影响：

Registry 应该是系统对象索引的稳定入口，但当前它同时描述 registry 文件、配置中心子目录、对象字段映射、Evidence 路径示例和生命周期状态。边界过宽导致维护成本高，也让“Registry 到底管什么”不清楚。

修复方向：

- 把 Registry 明确定义为“对象索引层”，只负责 Goal / Spec / Design / Plan / Task / Evidence 等对象元数据。
- Matrix、Gate、Pipeline、Prompt 可以被 Registry 引用，但不应被统计为 Registry 子系统。
- 统一“6 个 registry 文件”或“7 个子系统”的口径。若 Evidence Registry 是第七项，应落到 `.config/goal/registry/evidence.yaml`；否则把 7 改为 6。
- 修正 stale anchor，并把对象字段 schema 固化到一处。

## 5. P2 结构问题

### P2-1 链接、章节引用和重复行存在漂移

证据：

- `docs/goal/README.md:73` 称 `03-pipeline.md` 是“12 态状态机”，但 `docs/goal/03-pipeline.md:39-42` 的正常状态流从 `INIT` 到 `DONE` 可数为 13 个状态。
- `docs/goal/03-pipeline.md:99` 中 Task 指向 `05-layer-standards.md §4 Plan`，疑似章节错位。
- `docs/goal/03-pipeline.md:100` 和 `03-pipeline.md:106` 存在重复 Issue 行。
- `docs/goal/03-pipeline.md:105` 使用 `#21-主状态机` 锚点，但当前章节标题是 `### 2.1 正常状态流`。

影响：

这些不是单独的致命问题，但它们会降低标准文档作为长期权威源的可信度。对于 Goal 体系这种以追溯和门禁为核心的文档，失效锚点和重复行会放大维护者对其他表格的怀疑。

修复方向：

补一个轻量 consistency check，至少覆盖：

- docs 内部链接锚点。
- 状态枚举在 README、03、`.config/goal/pipeline/state.yaml` 之间的一致性。
- 重复对象行。
- 章节引用是否存在。

### P2-2 通用 Goal 标准混入模块专用规则

证据：

- `docs/goal/README.md:86` 说明 `16-ci-cd.md` 包含 x.go 专用规则。
- `docs/goal/16-ci-cd.md:137` 开始出现 `x.go 专用规则`。
- `docs/goal/16-ci-cd.md:193-204` 定义 `x.go 专用 Gate`。

影响：

`docs/goal/` 是 Goal 驱动交付体系的通用标准，x.go 是具体模块或 profile。把模块专用规则写进通用 CI/CD 规范，会让其他模块继承不适用的约束，也会让 Gate namespace 更混乱。

修复方向：

将 x.go 规则移动为 profile：

- `docs/goal/profiles/x-go.md`；或
- `.config/goal/profiles/x-go.yaml`；或
- 在 `16-ci-cd.md` 只保留 profile 机制，具体 x.go 规则另文维护。

### P2-3 工具校验能发现问题，但目前不能作为可信门禁

证据：

- `bash docs/goal/tools/lint-goal.sh docs/goal/` 退出码为 0，仅报 3 个 warning。
- `matrix-gen.py --check-only` 对实际 Matrix 失败，覆盖率显示 0%。
- `gate-check.sh` 默认路径失败；修正路径后仍出现 shell arithmetic syntax error。
- `docs/goal/tools/gate-check.sh:58` 通过任务 YAML 中的 `evidence:` 字段统计 G7 Evidence coverage。
- `docs/goal/tools/gate-check.sh:80-102` 又通过真实 Evidence 文件检查 G8，当前目录为空而失败。

影响：

工具现在是“问题探测器”，还不是“标准门禁”。它们能暴露漂移，但不能稳定证明体系通过。

修复方向：

- 把工具默认路径全部与 `.config/goal/README.md` 对齐。
- 先让工具读取同一份 machine-readable schema，再生成检查逻辑。
- 分清“任务声明了 evidence 引用”和“Evidence 文件存在且字段有效”两个层级，避免 G7/G8 互相矛盾。

## 6. 校验结果

| 命令                                                                                                | 结果               | 说明                                                                    |
| --------------------------------------------------------------------------------------------------- | ------------------ | ----------------------------------------------------------------------- |
| `bash docs/goal/tools/lint-goal.sh docs/goal/`                                                      | PASS with warnings | 退出码 0；3 个 warning，主要是 PR/Commit 缺少 Task 或 Matrix Row 引用   |
| `python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml`       | FAIL               | 总行数 5，已完成 0，覆盖率 0%；原因是工具未识别实际状态 `Verified`      |
| `bash docs/goal/tools/gate-check.sh /home/ZoneCNH`                                                  | FAIL               | G5/G7 PASS，G8 FAIL；Matrix 默认路径错误，找 `.config/goal/matrix.yaml` |
| `GOAL_MATRIX_FILE=.config/goal/matrix/matrix.yaml bash docs/goal/tools/gate-check.sh /home/ZoneCNH` | FAIL               | Matrix 路径修正后仍出现 arithmetic syntax error；G8 仍失败              |
| `find .config/goal/evidence .config/goal/prompts -maxdepth 3 -type f -print`                        | EMPTY              | Evidence 和 prompts 当前没有实际文件                                    |

## 7. 修复优先级

1. 固定 canonical schema：至少覆盖 pipeline states、object statuses、Gate IDs、Matrix row schema、Evidence schema、路径布局。
2. 对齐 `docs/goal/03-pipeline.md` 与 `.config/goal/pipeline/state.yaml`：决定 `Prompt/Code/Test/Matrix` 是主状态还是 checkpoint。
3. 收敛 Gate namespace：`G0-G11` 作为唯一 top-level Gate，`H-G*`、`CI-G*`、`XG-G*` 降级为 checks 或 profiles。
4. 完成 Evidence 迁移：统一 AC-bound / Test-bound、required fields、目录布局、`evidence-collect.sh`、`gate-check.sh`。
5. 对齐 Matrix：统一路径、字段、状态枚举、覆盖率阈值，并修复 `gate-check.sh` arithmetic 错误。
6. 清理 Registry 边界：确认 6 个 registry 文件还是 7 个子系统，去掉非 Registry 域的混算。
7. 修复低层漂移：重复 Issue 行、失效锚点、章节错链、12/13 状态描述不一致。
8. 加一个 docs consistency check：在进入 98 分管线前自动检查链接、路径、枚举和 schema drift。

## 8. 结论

`docs/goal/` 当前结构健康分为 67/100，低于可作为团队默认交付标准的门槛。它已经具备完整体系的骨架，但仍缺少一个真正稳定的结构脊柱。首要任务不是继续扩写文档，而是把状态机、Gate、Evidence、Matrix、Registry 和工具校验压回同一份契约。

推荐判定：`Changes requested`。完成 P0 和 P1 收敛后再重新评分；若状态机、Gate namespace、Evidence / Matrix 工具闭环全部对齐，预计可提升到 85-90 分区间。
