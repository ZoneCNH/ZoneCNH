# Goal 体系 Go 完整实现分析

> 生成日期：2026-06-09
> 输入：`docs/goal/` 全部 30 份文档
> 目标：分析将 Goal 驱动交付体系完整实现为 Go 工程的路径

---

## 1. 文档 → 代码映射总览

将 30 份文档按可执行性分为三层：

| 层级         | 文档                                                                               | 代码映射                        |
| ------------ | ---------------------------------------------------------------------------------- | ------------------------------- |
| **可执行层** | 03-pipeline, 04-gates, 07-id-system, 10-lint-rules, 13-runtime-engine, 15-registry | 直接翻译为 Go struct + engine   |
| **规则层**   | 01-principles, 05-layer-standards, 06-dod, 11-anti-patterns, 16-ci-cd              | 翻译为 checker / validator 规则 |
| **概念层**   | 02-workflow, 08-glossary, 09-collaboration, 12-hyper-parameters, 14-maturity       | 提供 context，不直接编码        |

---

## 2. Go 工程结构

### 2.1 仓库定位

独立仓库 `github.com/ZoneCNH/goalctl`，不嵌入 kernel 或 x.go。

理由：
- Goal 体系是跨项目治理工具，不绑定单一业务模块
- 独立版本线，独立 CI
- 可被任意 FoundationX 模块引用

### 2.2 三层架构

```
goalctl/
├── types/           # Schema + 数据结构（纯数据，无逻辑）
│   ├── goal.go
│   ├── spec.go
│   ├── task.go
│   ├── matrix.go
│   ├── gate.go
│   ├── evidence.go
│   ├── pipeline.go
│   ├── registry.go
│   ├── id.go
│   └── collection.go   # 泛型 Collection[T]
│
├── engine/          # 核心逻辑（依赖 types，不依赖 cmd）
│   ├── pipeline.go     # 状态机转换
│   ├── gate_check.go   # Gate 检查器
│   ├── lint.go         # Lint 规则引擎
│   ├── matrix.go       # Matrix 操作
│   ├── registry.go     # Registry CRUD
│   ├── evidence.go     # Evidence 生命周期
│   ├── priority.go     # 优先级评分
│   ├── propagation.go  # 变更传播
│   ├── validate.go     # ID 格式校验
│   └── dor_dod.go      # DoR/DoD 检查
│
├── cmd/             # CLI 入口
│   └── goalctl/
│       └── main.go
│       ├── validate.go   # goalctl validate
│       ├── gate.go       # goalctl gate check
│       ├── lint.go       # goalctl lint
│       ├── pipeline.go   # goalctl pipeline status/transition
│       ├── matrix.go     # goalctl matrix coverage/orphans
│       ├── registry.go   # goalctl registry list/add/update
│       ├── evidence.go   # goalctl evidence collect/verify
│       └── ci.go         # goalctl ci preflight
│
├── testdata/        # 测试 fixtures
├── go.mod
└── go.sum
```

---

## 3. 类型定义（types/）

### 3.1 泛型 Collection[T]

用 Go 泛型实现统一的 Registry 容器，替代 6 个独立实现：

```go
// types/collection.go
package types

type Identifiable interface {
    GetID() string
}

type Collection[T Identifiable] struct {
    Items []T `yaml:"items" json:"items"`
}

func (c *Collection[T]) Add(item T)                    { c.Items = append(c.Items, item) }
func (c *Collection[T]) Get(id string) (T, bool)       { /* 遍历查找 */ }
func (c *Collection[T]) Update(id string, fn func(T) T) { /* 查找并更新 */ }
func (c *Collection[T]) Delete(id string)               { /* 查找并删除 */ }
func (c *Collection[T]) Filter(fn func(T) bool) []T     { /* 过滤 */ }
func (c *Collection[T]) Len() int                       { return len(c.Items) }
```

每个 Registry 类型实现 `Identifiable` 接口，复用同一套 CRUD。

### 3.2 Pipeline 状态机

```go
// types/pipeline.go
package types

// 四轴状态模型
type PipelineState string  // 整体阶段
type CurrentPhase string   // 当前阶段
type PhaseStatus string    // 阶段状态
type WorkflowStep string   // 工作流步骤

const (
    // PipelineState — 正常状态
    StateSpecReady    PipelineState = "SPEC_READY"
    StateDesignReady  PipelineState = "DESIGN_READY"
    StatePlanReady    PipelineState = "PLAN_READY"
    StateTasksReady   PipelineState = "TASKS_READY"
    StateExecuting    PipelineState = "EXECUTING"
    StateVerifying    PipelineState = "VERIFYING"
    StateReviewing    PipelineState = "REVIEWING"
    StateReleasing    PipelineState = "RELEASING"
    StateDone         PipelineState = "DONE"

    // PipelineState — 异常状态
    StateBlocked       PipelineState = "BLOCKED"
    StateFailed        PipelineState = "FAILED"
    StateNeedsResearch PipelineState = "NEEDS_RESEARCH"
    StateNeedsDecision PipelineState = "NEEDS_DECISION"
    StateNeedsReplan   PipelineState = "NEEDS_REPLAN"
    StateNeedsRollback PipelineState = "NEEDS_ROLLBACK"
    StateNeedsHuman    PipelineState = "NEEDS_HUMAN_APPROVAL"
    StateInconsistent  PipelineState = "INCONSISTENT_STATE"
)

// CurrentPhase — 11 个主流程阶段
const (
    PhaseGoal    CurrentPhase = "GOAL"
    PhaseSpec    CurrentPhase = "SPEC"
    PhaseDesign  CurrentPhase = "DESIGN"
    PhasePlan    CurrentPhase = "PLAN"
    PhaseTasks   CurrentPhase = "TASKS"
    PhasePrompt  CurrentPhase = "PROMPT"
    PhaseCode    CurrentPhase = "CODE"
    PhaseTest    CurrentPhase = "TEST"
    PhaseReview  CurrentPhase = "REVIEW"
    PhaseRelease CurrentPhase = "RELEASE"
    PhaseRetro   CurrentPhase = "RETROSPECTIVE"
)

// PhaseStatus
const (
    PhaseStatusReady    PhaseStatus = "READY"
    PhaseStatusActive   PhaseStatus = "ACTIVE"
    PhaseStatusBlocked  PhaseStatus = "BLOCKED"
    PhaseStatusComplete PhaseStatus = "COMPLETE"
    PhaseStatusSkipped  PhaseStatus = "SKIPPED"
)

// WorkflowStep
const (
    StepPlanning  WorkflowStep = "PLANNING"
    StepExecuting WorkflowStep = "EXECUTING"
    StepVerifying WorkflowStep = "VERIFYING"
    StepReviewing WorkflowStep = "REVIEWING"
    StepReleasing WorkflowStep = "RELEASING"
    StepDone      WorkflowStep = "DONE"
)

type Pipeline struct {
    PipelineState PipelineState `yaml:"pipeline_state"`
    CurrentPhase  CurrentPhase  `yaml:"current_phase"`
    PhaseStatus   PhaseStatus   `yaml:"phase_status"`
    WorkflowStep  WorkflowStep  `yaml:"workflow_step"`
    GoalID        string        `yaml:"goal_id"`
    UpdatedAt     string        `yaml:"updated_at"`
}
```

### 3.3 Gate 定义

```go
// types/gate.go
package types

type GateType string

const (
    GateTypeSemantic   GateType = "Semantic"
    GateTypeExecutable GateType = "Executable"
    GateTypeHybrid     GateType = "Hybrid"
)

type GateResult string

const (
    GatePass         GateResult = "PASS"
    GatePassWithRisk GateResult = "PASS_WITH_RISK"
    GateFail         GateResult = "FAIL"
    GateBlocked      GateResult = "BLOCKED"
)

type Gate struct {
    GateID      string     `yaml:"gate_id"`
    Type        GateType   `yaml:"type"`
    Blocking    bool       `yaml:"blocking"`
    Result      GateResult `yaml:"result"`
    CheckedAt   string     `yaml:"checked_at"`
    EvidenceIDs []string   `yaml:"evidence_ids"`
    Risks       []Risk     `yaml:"risks,omitempty"`
    Notes       string     `yaml:"notes,omitempty"`
}

type Risk struct {
    RiskID      string `yaml:"risk_id"`
    Level       string `yaml:"level"`       // Low / Medium / High
    Description string `yaml:"description"`
    Mitigation  string `yaml:"mitigation"`
    Owner       string `yaml:"owner"`
}

// GateDefinition — Gate 检查项定义
type GateDefinition struct {
    GateID           string
    Name             string
    Type             GateType
    Blocking         bool
    CheckItems       []CheckItem
    PassWithRiskPolicy string // "allowed" / "disallowed"
}

type CheckItem struct {
    CheckID   string
    Name      string
    Automated bool
    Validator string // 对应的 validator 函数名
}

// GateDefinitions — G0-G11 完整定义表
var GateDefinitions = []GateDefinition{
    {GateID: "G0", Name: "Goal Gate", Type: GateTypeSemantic, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G0-C1", Name: "Goal 是否包含 objective", Automated: true, Validator: "goalHasObjective"},
        {CheckID: "G0-C2", Name: "Goal 是否包含 success_metrics", Automated: true, Validator: "goalHasMetrics"},
        {CheckID: "G0-C3", Name: "Goal 是否包含 scope_out", Automated: true, Validator: "goalHasScopeOut"},
        {CheckID: "G0-C4", Name: "Goal 不只描述实现方案", Automated: false},
        {CheckID: "G0-C5", Name: "Goal 包含 target_user", Automated: true, Validator: "goalHasTargetUser"},
        {CheckID: "G0-C6", Name: "Goal 至少一个可验证指标", Automated: true, Validator: "goalHasVerifiableMetric"},
    }},
    {GateID: "G1", Name: "Spec Gate", Type: GateTypeSemantic, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G1-C1", Name: "每条 FR 有唯一 ID", Automated: true, Validator: "specUniqueIDs"},
        {CheckID: "G1-C2", Name: "每条 Requirement 可测试", Automated: true, Validator: "specTestable"},
        {CheckID: "G1-C3", Name: "每条 AC 有明确结果", Automated: true, Validator: "specACClear"},
    }},
    {GateID: "G2", Name: "Design Gate", Type: GateTypeSemantic, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G2-C1", Name: "每个 Spec Requirement 有对应 Module", Automated: true, Validator: "designModuleCoverage"},
        {CheckID: "G2-C2", Name: "模块边界清晰", Automated: false},
        {CheckID: "G2-C3", Name: "接口可测试", Automated: false},
        {CheckID: "G2-C4", Name: "无循环依赖", Automated: true, Validator: "designNoCycles"},
        {CheckID: "G2-C5", Name: "ADR 记录关键决策", Automated: true, Validator: "designADRPresent"},
    }},
    {GateID: "G3", Name: "Plan Gate", Type: GateTypeSemantic, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G3-C1", Name: "执行顺序明确", Automated: false},
        {CheckID: "G3-C2", Name: "阶段产物明确", Automated: false},
        {CheckID: "G3-C3", Name: "每阶段有验证点", Automated: false},
        {CheckID: "G3-C4", Name: "高风险任务提前处理", Automated: false},
        {CheckID: "G3-C5", Name: "有回滚策略", Automated: true, Validator: "planRollbackPresent"},
    }},
    {GateID: "G4", Name: "Task Gate", Type: GateTypeHybrid, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G4-C1", Name: "每个 Task 有明确输入/输出/AC", Automated: true, Validator: "taskComplete"},
        {CheckID: "G4-C2", Name: "每个 Task 可追溯到 Goal", Automated: true, Validator: "taskTracable"},
        {CheckID: "G4-C3", Name: "无无来源 Task", Automated: true, Validator: "taskNoOrphan"},
    }},
    {GateID: "G5", Name: "Matrix Gate", Type: GateTypeExecutable, Blocking: true, CheckItems: []CheckItem{
        {CheckID: "G5-C1", Name: "Matrix 覆盖率 100%", Automated: true, Validator: "matrixCoverage"},
        {CheckID: "G5-C2", Name: "无孤立 Task", Automated: true, Validator: "orphanCheck"},
        {CheckID: "G5-C3", Name: "无孤立 Code", Automated: true, Validator: "orphanCodeCheck"},
    }},
    {GateID: "G6", Name: "Prompt Gate", Type: GateTypeHybrid, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G6-C1", Name: "Prompt 包含 Source", Automated: true, Validator: "promptHasSource"},
        {CheckID: "G6-C2", Name: "Prompt 包含 AC", Automated: true, Validator: "promptHasAC"},
        {CheckID: "G6-C3", Name: "Prompt 不要求多个无关任务", Automated: true, Validator: "promptSingleGoal"},
    }},
    {GateID: "G7", Name: "Test Gate", Type: GateTypeExecutable, Blocking: true, CheckItems: []CheckItem{
        {CheckID: "G7-C1", Name: "单元测试覆盖所有 Task", Automated: true, Validator: "testTaskCoverage"},
        {CheckID: "G7-C2", Name: "集成测试覆盖关键流", Automated: false},
        {CheckID: "G7-C3", Name: "测试结果记录在 Evidence", Automated: true, Validator: "testEvidencePresent"},
    }},
    {GateID: "G8", Name: "Evidence Gate", Type: GateTypeExecutable, Blocking: true, CheckItems: []CheckItem{
        {CheckID: "G8-C1", Name: "Evidence 10 个必填字段完整", Automated: true, Validator: "evidenceFieldComplete"},
        {CheckID: "G8-C2", Name: "Evidence 路径符合规范", Automated: true, Validator: "evidencePathValid"},
        {CheckID: "G8-C3", Name: "Evidence 状态非 FAIL", Automated: true, Validator: "evidenceNotFail"},
    }},
    {GateID: "G9", Name: "Review Gate", Type: GateTypeHybrid, Blocking: true, CheckItems: []CheckItem{
        {CheckID: "G9-C1", Name: "无 CRITICAL/HIGH 问题", Automated: true, Validator: "reviewNoCritical"},
        {CheckID: "G9-C2", Name: "安全要求已验证", Automated: false},
        {CheckID: "G9-C3", Name: "性能要求已验证", Automated: false},
        {CheckID: "G9-C4", Name: "Matrix 覆盖率达标", Automated: true, Validator: "reviewMatrixCoverage"},
    }},
    {GateID: "G10", Name: "Release Gate", Type: GateTypeExecutable, Blocking: true,
        PassWithRiskPolicy: "disallowed",
        CheckItems: []CheckItem{
            {CheckID: "G10-C1", Name: "CI 全部通过", Automated: true, Validator: "releaseCIPass"},
            {CheckID: "G10-C2", Name: "Release Manifest 完整", Automated: true, Validator: "releaseManifest"},
            {CheckID: "G10-C3", Name: "无 P0/P1 STALE 对象", Automated: true, Validator: "releaseNoStaleP0P1"},
            {CheckID: "G10-C4", Name: "风险已接受或关闭", Automated: true, Validator: "releaseRiskClosed"},
        }},
    {GateID: "G11", Name: "Retrospective Gate", Type: GateTypeSemantic, Blocking: false, CheckItems: []CheckItem{
        {CheckID: "G11-C1", Name: "至少识别一个改进点", Automated: false},
        {CheckID: "G11-C2", Name: "至少生成一个 Patch", Automated: true, Validator: "retroPatchGenerated"},
        {CheckID: "G11-C3", Name: "新经验进入 Registry", Automated: true, Validator: "retroRegistryUpdated"},
    }},
}
```

### 3.4 ID 系统

```go
// types/id.go
package types

import "regexp"

type IDFormat struct {
    Name    string
    Pattern *regexp.Regexp
    Example string
}

var IDFormats = map[string]IDFormat{
    "GOAL":   {Name: "Goal", Pattern: regexp.MustCompile(`^GOAL-\d{8}-\d{3}$`), Example: "GOAL-20260608-001"},
    "SPEC":   {Name: "Spec", Pattern: regexp.MustCompile(`^SPEC-[\w]+-v\d+$`), Example: "SPEC-market-data-v1"},
    "REQ":    {Name: "Requirement", Pattern: regexp.MustCompile(`^REQ-SPEC-[\w]+-v\d+-\d{3}$`), Example: "REQ-SPEC-export-v1-001"},
    "AC":     {Name: "Acceptance Criteria", Pattern: regexp.MustCompile(`^AC-[\w]+-v\d+-\d{3}$`), Example: "AC-export-v1-001"},
    "DESIGN": {Name: "Design", Pattern: regexp.MustCompile(`^DESIGN-[\w]+-v\d+$`), Example: "DESIGN-market-data-v1"},
    "ADR":    {Name: "ADR", Pattern: regexp.MustCompile(`^ADR-\d{8}-\d{3}$`), Example: "ADR-20260608-001"},
    "PLAN":   {Name: "Plan", Pattern: regexp.MustCompile(`^PLAN-GOAL-\d{8}-\d{3}-v\d+$`), Example: "PLAN-GOAL-20260608-001-v1"},
    "TASK":   {Name: "Task", Pattern: regexp.MustCompile(`^TASK-GOAL-\d{8}-\d{3}-\d{3}$`), Example: "TASK-GOAL-20260608-001-003"},
    "PROMPT": {Name: "Prompt", Pattern: regexp.MustCompile(`^PROMPT-TASK-[\w]+-\d{3}$`), Example: "PROMPT-TASK-GOAL-20260608-001-003-001"},
    "EVID":   {Name: "Evidence", Pattern: regexp.MustCompile(`^EVID-[\w]+-[\w]+-\d{3}-\d{3}$`), Example: "EVID-TEST-TASK-...-001"},
    "TEST":   {Name: "Test", Pattern: regexp.MustCompile(`^TEST-[\w]+-[\w]+-\d{3}-\d{3}$`), Example: "TEST-AC-export-v1-001-001"},
    "RISK":   {Name: "Risk", Pattern: regexp.MustCompile(`^RISK-GOAL-\d{8}-\d{3}-\d{3}$`), Example: "RISK-GOAL-20260608-001-001"},
    "REL":    {Name: "Release", Pattern: regexp.MustCompile(`^REL-\d{8}-[\w]+$`), Example: "REL-20260608-market-data"},
    "DEC":    {Name: "Decision", Pattern: regexp.MustCompile(`^DEC-\d{8}-\d{3}$`), Example: "DEC-20260608-001"},
    "ISSUE":  {Name: "Issue", Pattern: regexp.MustCompile(`^#\d+$`), Example: "#1393"},
    "GATE":   {Name: "Gate", Pattern: regexp.MustCompile(`^G\d{1,2}$`), Example: "G5"},
    "CI":     {Name: "CI Check", Pattern: regexp.MustCompile(`^CI-CHK\d+$`), Example: "CI-CHK0"},
    "HCHK":   {Name: "Human Check", Pattern: regexp.MustCompile(`^H-CHK\d+$`), Example: "H-CHK1"},
}

func ValidateID(idType, id string) bool {
    fmt, ok := IDFormats[idType]
    if !ok { return false }
    return fmt.Pattern.MatchString(id)
}
```

### 3.5 Registry 类型

```go
// types/registry.go
package types

type Goal struct {
    GoalID          string   `yaml:"goal_id"`
    Title           string   `yaml:"title"`
    Status          string   `yaml:"status"`
    Owner           string   `yaml:"owner"`
    Priority        string   `yaml:"priority"`
    NorthStar       string   `yaml:"north_star"`
    PipelineState   string   `yaml:"pipeline_state"`
    CurrentPhase    string   `yaml:"current_phase"`
    PhaseStatus     string   `yaml:"phase_status"`
    RelatedIssues   []string `yaml:"related_issues"`
    RelatedSpecs    []string `yaml:"related_specs"`
    SuccessCriteria []string `yaml:"success_criteria"`
}
func (g Goal) GetID() string { return g.GoalID }

type Task struct {
    TaskID   string   `yaml:"task_id"`
    GoalID   string   `yaml:"goal_id"`
    Title    string   `yaml:"title"`
    Status   string   `yaml:"status"`
    Owner    string   `yaml:"owner"`
    Priority string   `yaml:"priority"`
    Dod      []string `yaml:"dod"`
    Evidence []string `yaml:"evidence"`
}
func (t Task) GetID() string { return t.TaskID }

type Issue struct {
    IssueID  string   `yaml:"issue_id"`
    Source   string   `yaml:"source"`
    Title    string   `yaml:"title"`
    Status   string   `yaml:"status"`
    Priority string   `yaml:"priority"`
    GoalID   string   `yaml:"goal_id"`
    SpecID   string   `yaml:"spec_id"`
    DesignID string   `yaml:"design_id"`
    Tasks    []string `yaml:"tasks"`
    Labels   []string `yaml:"labels"`
}
func (i Issue) GetID() string { return i.IssueID }

type Release struct {
    ReleaseID        string   `yaml:"release_id"`
    GoalID           string   `yaml:"goal_id"`
    Version          string   `yaml:"version"`
    Status           string   `yaml:"status"`
    LinkedIssues     []string `yaml:"linked_issues"`
    Tests            []string `yaml:"tests"`
    DocsUpdated      []string `yaml:"docs_updated"`
    RollbackPlan     string   `yaml:"rollback_plan"`
    EvidenceManifest string   `yaml:"evidence_manifest"`
}
func (r Release) GetID() string { return r.ReleaseID }

type Decision struct {
    DecisionID string   `yaml:"decision_id"`
    AdrID      string   `yaml:"adr_id"`
    Title      string   `yaml:"title"`
    Status     string   `yaml:"status"`
    Context    string   `yaml:"context"`
    Options    []string `yaml:"options"`
    Decision   string   `yaml:"decision"`
    Rationale  string   `yaml:"rationale"`
    Rollback   string   `yaml:"rollback"`
}
func (d Decision) GetID() string { return d.DecisionID }

type RiskEntry struct {
    RiskID      string `yaml:"risk_id"`
    GoalID      string `yaml:"goal_id"`
    TaskID      string `yaml:"task_id"`
    Type        string `yaml:"type"`
    Description string `yaml:"description"`
    Probability string `yaml:"probability"`
    Impact      string `yaml:"impact"`
    Severity    string `yaml:"severity"`
    Trigger     string `yaml:"trigger"`
    Mitigation  string `yaml:"mitigation"`
    Owner       string `yaml:"owner"`
    Status      string `yaml:"status"`
}
func (r RiskEntry) GetID() string { return r.RiskID }
```

### 3.6 Matrix Edge 模型

```go
// types/matrix.go
package types

type EdgeRelation string

const (
    EdgeImplements   EdgeRelation = "implements"
    EdgeVerifies     EdgeRelation = "verifies"
    EdgeDependsOn    EdgeRelation = "depends_on"
    EdgeDecomposesTo EdgeRelation = "decomposes_to"
    EdgeInstructs    EdgeRelation = "instructs"
    EdgeDrives       EdgeRelation = "drives"
    EdgeProvenBy     EdgeRelation = "proven_by"
    EdgeSupports     EdgeRelation = "supports"
    EdgeUnlocks      EdgeRelation = "unlocks"
    EdgeTriggers     EdgeRelation = "triggers"
    EdgePatches      EdgeRelation = "patches"
)

type EdgeStatus string

const (
    EdgeUnmapped EdgeStatus = "Unmapped"
    EdgeMapped   EdgeStatus = "Mapped"
    EdgeLinked   EdgeStatus = "Linked"
    EdgeVerified EdgeStatus = "Verified"
    EdgeDropped  EdgeStatus = "Dropped"
    EdgeStale    EdgeStatus = "Stale"
)

type MatrixEdge struct {
    SourceID   string       `yaml:"source_id"`
    TargetID   string       `yaml:"target_id"`
    Relation   EdgeRelation `yaml:"relation"`
    Status     EdgeStatus   `yaml:"status"`
    EvidenceID string       `yaml:"evidence_id"`
    GateID     string       `yaml:"gate_id"`
    Owner      string       `yaml:"owner"`
    UpdatedAt  string       `yaml:"updated_at"`
    DropReason string       `yaml:"drop_reason,omitempty"`
}

type Matrix struct {
    Edges []MatrixEdge `yaml:"edges"`
}
```

### 3.7 Evidence

```go
// types/evidence.go
package types

type EvidenceStatus string

const (
    EvidencePass    EvidenceStatus = "PASS"
    EvidenceFail    EvidenceStatus = "FAIL"
    EvidencePartial EvidenceStatus = "PARTIAL"
)

type Evidence struct {
    EvidenceID       string         `yaml:"evidence_id"`
    TaskID           string         `yaml:"task_id"`
    TestID           string         `yaml:"test_id"`
    GoalID           string         `yaml:"goal_id"`
    Date             string         `yaml:"date"`
    Status           EvidenceStatus `yaml:"status"`
    FilesChanged     []string       `yaml:"files_changed"`
    CommandsRun      []string       `yaml:"commands_run"`
    Results          string         `yaml:"results"`
    Logs             string         `yaml:"logs"`
    DiffSummary      string         `yaml:"diff_summary"`
    RequirementProof string         `yaml:"requirement_proof"`
    KnownLimitations string         `yaml:"known_limitations"`
    Risks            string         `yaml:"risks"`
    Rollback         string         `yaml:"rollback"`
}
func (e Evidence) GetID() string { return e.EvidenceID }
```

### 3.8 DoR / DoD 模型

```go
// types/dor_dod.go
package types

type StageName string

const (
    StageGoal    StageName = "GOAL"
    StageSpec    StageName = "SPEC"
    StageDesign  StageName = "DESIGN"
    StagePlan    StageName = "PLAN"
    StageTasks   StageName = "TASKS"
    StageMatrix  StageName = "MATRIX"
    StagePrompt  StageName = "PROMPT"
    StageCode    StageName = "CODE"
    StageTest    StageName = "TEST"
    StageReview  StageName = "REVIEW"
    StageIssue   StageName = "ISSUE"
    StageRelease StageName = "RELEASE"
    StageRetro   StageName = "RETROSPECTIVE"
)

type DoDCheck struct {
    CheckID   string    `yaml:"check_id"`
    Stage     StageName `yaml:"stage"`
    Type      string    `yaml:"type"` // "dor" / "dod"
    Criterion string    `yaml:"criterion"`
    Automated bool      `yaml:"automated"`
    Validator string    `yaml:"validator,omitempty"`
}
```

---

## 4. 引擎实现（engine/）

### 4.1 Pipeline 状态机

```go
// engine/pipeline.go
package engine

import (
    "fmt"
    "time"
    "goalctl/types"
)

// 转换规则表：正常状态 → (目标阶段 → 新状态)
var transitionRules = map[types.PipelineState]map[types.CurrentPhase]types.PipelineState{
    types.StateSpecReady: {
        types.PhaseSpec: types.StateDesignReady,
    },
    types.StateDesignReady: {
        types.PhaseDesign: types.StatePlanReady,
    },
    types.StatePlanReady: {
        types.PhasePlan: types.StateTasksReady,
    },
    types.StateTasksReady: {
        types.PhaseTasks: types.StateExecuting,
    },
    types.StateExecuting: {
        types.PhaseCode: types.StateVerifying,
        types.PhaseTest: types.StateVerifying,
    },
    types.StateVerifying: {
        types.PhaseTest: types.StateReviewing,
        types.PhaseCode: types.StateExecuting, // 回退
    },
    types.StateReviewing: {
        types.PhaseReview: types.StateReleasing,
    },
    types.StateReleasing: {
        types.PhaseRelease: types.StateDone,
    },
}

// 异常状态恢复路径
var abnormalRecovery = map[types.PipelineState]types.PipelineState{
    types.StateFailed:        types.StateExecuting,
    types.StateNeedsResearch: types.StateExecuting,
    types.StateNeedsDecision: types.StateExecuting,
    types.StateNeedsReplan:   types.StatePlanReady,
    types.StateNeedsRollback: types.StateReleasing,
    types.StateNeedsHuman:    types.StateReviewing,
}

// TransitionGuard 检查转换前置条件
func TransitionGuard(from types.PipelineState, to types.CurrentPhase) error {
    allowed, ok := transitionRules[from]
    if !ok {
        return fmt.Errorf("状态 %s 不允许转换（可能处于异常状态）", from)
    }
    if _, ok := allowed[to]; !ok {
        return fmt.Errorf("状态 %s 不允许向阶段 %s 转换", from, to)
    }
    return nil
}

// ExecuteTransition 执行状态转换
func ExecuteTransition(p *types.Pipeline, targetPhase types.CurrentPhase) error {
    if err := TransitionGuard(p.PipelineState, targetPhase); err != nil {
        return err
    }
    newState := transitionRules[p.PipelineState][targetPhase]
    p.PipelineState = newState
    p.CurrentPhase = targetPhase
    p.PhaseStatus = types.PhaseStatusReady
    p.UpdatedAt = time.Now().Format(time.RFC3339)
    return nil
}

// RecoverFromAbnormal 从异常状态恢复
func RecoverFromAbnormal(p *types.Pipeline) error {
    target, ok := abnormalRecovery[p.PipelineState]
    if !ok {
        return fmt.Errorf("状态 %s 无自动恢复路径", p.PipelineState)
    }
    p.PipelineState = target
    p.PhaseStatus = types.PhaseStatusReady
    p.UpdatedAt = time.Now().Format(time.RFC3339)
    return nil
}
```

### 4.2 Gate 检查器

```go
// engine/gate_check.go
package engine

import (
    "fmt"
    "time"
    "goalctl/types"
)

// CheckResult 单个检查项的结果
type CheckResult struct {
    CheckID string `json:"check_id"`
    Status  string `json:"status"`  // PASS / FAIL / WARN
    Score   int    `json:"score"`
    Details string `json:"details"`
}

// CheckerFunc 检查器函数签名
type CheckerFunc func(ctx *CheckContext) CheckResult

// CheckContext 检查上下文
type CheckContext struct {
    Goal     *types.Goal
    Edges    []types.MatrixEdge
    Evidence []types.Evidence
    Tasks    []types.Task
}

// checkerRegistry 所有自动检查器
var checkerRegistry = map[string]CheckerFunc{
    "goalHasObjective":        checkGoalHasObjective,
    "goalHasMetrics":          checkGoalHasMetrics,
    "goalHasScopeOut":         checkGoalHasScopeOut,
    "goalHasTargetUser":       checkGoalHasTargetUser,
    "goalHasVerifiableMetric": checkGoalHasVerifiableMetric,
    "matrixCoverage":          checkMatrixCoverage,
    "orphanCheck":             checkOrphanCheck,
    "evidenceFieldComplete":   checkEvidenceFieldComplete,
    "taskGateCoverage":        checkTaskGateCoverage,
    "reviewNoCritical":        checkReviewNoCritical,
    "releaseManifest":         checkReleaseManifest,
    "releaseRiskClosed":       checkReleaseRiskClosed,
}

// RunGate 执行指定 Gate 的所有自动检查
func RunGate(gateID string, ctx *CheckContext) (types.Gate, error) {
    def := getGateDefinition(gateID)
    if def == nil {
        return types.Gate{}, fmt.Errorf("未知 Gate: %s", gateID)
    }

    var results []CheckResult
    for _, item := range def.CheckItems {
        if !item.Automated {
            continue
        }
        checker, ok := checkerRegistry[item.Validator]
        if !ok {
            results = append(results, CheckResult{
                CheckID: item.CheckID, Status: "WARN",
                Details: fmt.Sprintf("检查器 %s 未实现", item.Validator),
            })
            continue
        }
        results = append(results, checker(ctx))
    }

    gateResult := aggregateResults(results, def)
    return types.Gate{
        GateID:    gateID,
        Type:      def.Type,
        Blocking:  def.Blocking,
        Result:    gateResult,
        CheckedAt: time.Now().Format(time.RFC3339),
    }, nil
}

func aggregateResults(results []CheckResult, def *types.GateDefinition) types.GateResult {
    failCount := 0
    for _, r := range results {
        if r.Status == "FAIL" {
            failCount++
        }
    }
    if failCount > 0 {
        if def.Blocking {
            return types.GateFail
        }
        return types.GatePassWithRisk
    }
    return types.GatePass
}

// --- 具体检查器实现 ---

func checkGoalHasObjective(ctx *CheckContext) CheckResult {
    if ctx.Goal == nil || ctx.Goal.NorthStar == "" {
        return CheckResult{CheckID: "G0-C1", Status: "FAIL", Details: "Goal 缺少 objective"}
    }
    return CheckResult{CheckID: "G0-C1", Status: "PASS", Score: 100}
}

func checkMatrixCoverage(ctx *CheckContext) CheckResult {
    total := len(ctx.Edges)
    if total == 0 {
        return CheckResult{CheckID: "G5-C1", Status: "FAIL", Details: "Matrix 无边"}
    }
    verified := 0
    for _, e := range ctx.Edges {
        if e.Status == types.EdgeVerified {
            verified++
        }
    }
    coverage := float64(verified) / float64(total) * 100
    if coverage < 100 {
        return CheckResult{CheckID: "G5-C1", Status: "FAIL", Score: int(coverage),
            Details: fmt.Sprintf("Matrix 覆盖率 %.1f%%，需要 100%%", coverage)}
    }
    return CheckResult{CheckID: "G5-C1", Status: "PASS", Score: 100}
}

func checkOrphanCheck(ctx *CheckContext) CheckResult {
    taskIDs := make(map[string]bool)
    for _, t := range ctx.Tasks {
        taskIDs[t.TaskID] = true
    }
    for _, e := range ctx.Edges {
        if e.Relation == "decomposes_to" {
            delete(taskIDs, e.TargetID)
        }
    }
    if len(taskIDs) > 0 {
        orphans := make([]string, 0, len(taskIDs))
        for id := range taskIDs {
            orphans = append(orphans, id)
        }
        return CheckResult{CheckID: "M-LINT-006", Status: "FAIL",
            Details: fmt.Sprintf("发现 %d 个孤立 Task: %v", len(orphans), orphans)}
    }
    return CheckResult{CheckID: "M-LINT-006", Status: "PASS", Score: 100}
}
```

### 4.3 Lint 规则引擎

```go
// engine/lint.go
package engine

import "goalctl/types"

// LintRule 单条 Lint 规则
type LintRule struct {
    RuleID    string
    Category  string // G / S / M / P / C
    Name      string
    Automated bool
    Checker   func(data interface{}) LintResult
}

// LintResult Lint 检查结果
type LintResult struct {
    RuleID  string `json:"rule_id"`
    Status  string `json:"status"` // PASS / FAIL / WARN
    Message string `json:"message"`
    Line    int    `json:"line,omitempty"`
}

// 全部 33 条 Lint 规则（22 条可自动化）
var lintRules = []LintRule{
    // Goal Lint (7 条，3 条可自动)
    {RuleID: "G-LINT-001", Category: "G", Name: "Goal 必须包含 objective", Automated: true, Checker: lintGoalHasObjective},
    {RuleID: "G-LINT-002", Category: "G", Name: "Goal 必须包含 success_metrics", Automated: true, Checker: lintGoalHasMetrics},
    {RuleID: "G-LINT-003", Category: "G", Name: "Goal 不能只描述实现方案", Automated: false},
    {RuleID: "G-LINT-004", Category: "G", Name: "Goal 必须包含 scope_out", Automated: true, Checker: lintGoalHasScopeOut},
    {RuleID: "G-LINT-005", Category: "G", Name: "Goal 必须包含 target_user", Automated: false},
    {RuleID: "G-LINT-006", Category: "G", Name: "Goal 至少一个可验证指标", Automated: false},
    {RuleID: "G-LINT-007", Category: "G", Name: "Goal 不应使用模糊词", Automated: true, Checker: lintGoalNoVagueWords},

    // Spec Lint (8 条，3 条可自动)
    {RuleID: "S-LINT-001", Category: "S", Name: "每条 FR 必须有唯一 ID", Automated: true, Checker: lintSpecUniqueIDs},
    {RuleID: "S-LINT-002", Category: "S", Name: "每条 Requirement 必须能被测试", Automated: true, Checker: lintSpecTestable},
    {RuleID: "S-LINT-003", Category: "S", Name: "每条 AC 必须有明确结果", Automated: true, Checker: lintSpecACClear},
    {RuleID: "S-LINT-004", Category: "S", Name: "权限相关必须包含 Security", Automated: false},
    {RuleID: "S-LINT-005", Category: "S", Name: "导入导出必须包含数据量限制", Automated: false},
    {RuleID: "S-LINT-006", Category: "S", Name: "异步任务必须包含状态流转", Automated: false},
    {RuleID: "S-LINT-007", Category: "S", Name: "用户可见错误必须包含 Error Handling", Automated: false},
    {RuleID: "S-LINT-008", Category: "S", Name: "外部服务必须包含失败处理", Automated: false},

    // Matrix Lint (8 条，8 条全部可自动)
    {RuleID: "M-LINT-001", Category: "M", Name: "每个 Goal 至少对应一个 Spec", Automated: true, Checker: lintMatrixGoalSpec},
    {RuleID: "M-LINT-002", Category: "M", Name: "每个 Spec REQ 至少对应一个 Matrix Row", Automated: true, Checker: lintMatrixSpecReq},
    {RuleID: "M-LINT-003", Category: "M", Name: "每个 Matrix Row 必须有 Task", Automated: true, Checker: lintMatrixRowTask},
    {RuleID: "M-LINT-004", Category: "M", Name: "P0/P1 Row 必须有 Test Case", Automated: true, Checker: lintMatrixP0P1Test},
    {RuleID: "M-LINT-005", Category: "M", Name: "每个 Task 必须能追溯到 Matrix Row", Automated: true, Checker: lintMatrixTaskTraceable},
    {RuleID: "M-LINT-006", Category: "M", Name: "不允许 Orphan Task", Automated: true, Checker: lintMatrixNoOrphanTask},
    {RuleID: "M-LINT-007", Category: "M", Name: "不允许 Orphan Code", Automated: true, Checker: lintMatrixNoOrphanCode},
    {RuleID: "M-LINT-008", Category: "M", Name: "Done 必须同时满足 Code + Test", Automated: true, Checker: lintMatrixDoneCodeTest},

    // Prompt Lint (10 条，2 条可自动)
    {RuleID: "P-LINT-001", Category: "P", Name: "Prompt 必须包含 Source", Automated: true, Checker: lintPromptHasSource},
    {RuleID: "P-LINT-002", Category: "P", Name: "Prompt 必须包含 Task Objective", Automated: false},
    {RuleID: "P-LINT-003", Category: "P", Name: "Prompt 必须包含 Requirements", Automated: false},
    {RuleID: "P-LINT-004", Category: "P", Name: "Prompt 必须包含 Constraints", Automated: false},
    {RuleID: "P-LINT-005", Category: "P", Name: "Prompt 必须包含 Output", Automated: false},
    {RuleID: "P-LINT-006", Category: "P", Name: "Prompt 必须包含 AC", Automated: false},
    {RuleID: "P-LINT-007", Category: "P", Name: "Prompt 必须包含 Test Requirements", Automated: false},
    {RuleID: "P-LINT-008", Category: "P", Name: "Prompt 必须包含 Do Not", Automated: false},
    {RuleID: "P-LINT-009", Category: "P", Name: "Prompt 不能要求多个无关任务", Automated: true, Checker: lintPromptSingleGoal},
    {RuleID: "P-LINT-010", Category: "P", Name: "Prompt 不能允许自行扩大范围", Automated: false},

    // Code Lint (5 条，5 条可自动)
    {RuleID: "C-LINT-001", Category: "C", Name: "PR 必须引用至少一个 Task", Automated: true, Checker: lintCodePRTaskRef},
    {RuleID: "C-LINT-002", Category: "C", Name: "PR 必须引用至少一个 Matrix Row", Automated: true, Checker: lintCodePRMatrixRef},
    {RuleID: "C-LINT-003", Category: "C", Name: "PR 必须包含测试说明", Automated: true, Checker: lintCodePRTestDesc},
    {RuleID: "C-LINT-004", Category: "C", Name: "P0/P1 Task 不允许无测试合并", Automated: true, Checker: lintCodeP0P1Test},
    {RuleID: "C-LINT-005", Category: "C", Name: "PR 不能包含未关联 Task 的大改动", Automated: true, Checker: lintCodeNoOrphanChange},
}

// RunLint 执行指定类别的所有自动 Lint 规则
func RunLint(category string, data interface{}) []LintResult {
    var results []LintResult
    for _, rule := range lintRules {
        if rule.Category != category || !rule.Automated {
            continue
        }
        results = append(results, rule.Checker(data))
    }
    return results
}

// RunAllLint 执行所有可自动化的 Lint 规则
func RunAllLint(data map[string]interface{}) map[string][]LintResult {
    results := make(map[string][]LintResult)
    for _, rule := range lintRules {
        if !rule.Automated {
            continue
        }
        results[rule.Category] = append(results[rule.Category], rule.Checker(data[rule.Category]))
    }
    return results
}
```

### 4.4 变更传播引擎

```go
// engine/propagation.go
package engine

import "goalctl/types"

// 变更传播矩阵（12 种变更类型 → 必须同步的下游对象）
var propagationMatrix = map[string][]string{
    "goal":        {"spec", "design", "plan", "tasks", "registry", "issue"},
    "spec":        {"design", "plan", "tasks", "test", "matrix"},
    "requirement": {"ac", "tasks", "tests", "evidence"},
    "design":      {"adr", "plan", "tasks", "risk", "docs"},
    "plan":        {"tasks", "dependency_graph", "registry"},
    "task":        {"prompt", "code", "test", "evidence", "registry", "issue", "pr"},
    "public_api":  {"docs", "tests", "changelog", "adr", "release_manifest"},
    "storage":     {"migration", "rollback", "tests", "release_manifest"},
    "config":      {"example", "docs", "tests", "release_manifest"},
    "ci":          {"harness", "docs", "release_manifest"},
    "risk":        {"review", "release", "retrospective"},
    "release":     {"changelog", "manifest", "rollback", "registry"},
}

// Propagate 标记下游对象为 STALE
func Propagate(changedType string, edges []types.MatrixEdge) []string {
    downstream, ok := propagationMatrix[changedType]
    if !ok {
        return nil
    }

    downstreamSet := make(map[string]bool)
    for _, d := range downstream {
        downstreamSet[d] = true
    }

    var staleIDs []string
    for i, edge := range edges {
        if downstreamSet[string(edge.Relation)] {
            edges[i].Status = types.EdgeStale
            staleIDs = append(staleIDs, edge.TargetID)
        }
    }
    return staleIDs
}
```

### 4.5 变更级别评估

```go
// engine/change_level.go
package engine

// ChangeLevel 变更影响级别
type ChangeLevel int

const (
    CL0 ChangeLevel = iota // 文档修正
    CL1                     // 局部实现修复
    CL2                     // 模块行为变化
    CL3                     // 公共接口变化
    CL4                     // 架构边界变化
    CL5                     // 数据模型/存储/迁移变化
)

// ExecutionMode 返回执行模式
func (cl ChangeLevel) ExecutionMode() string {
    switch {
    case cl <= CL1:
        return "lite"
    case cl == CL2:
        return "standard"
    default:
        return "full"
    }
}

// RequiredGates 返回该级别强制要求的 Gate
func (cl ChangeLevel) RequiredGates() []string {
    switch cl {
    case CL0:
        return []string{"G8", "G9"}
    case CL1:
        return []string{"G5", "G7", "G8", "G9"}
    default:
        return []string{"G0", "G1", "G2", "G3", "G4", "G5", "G6", "G7", "G8", "G9", "G10", "G11"}
    }
}

// RequiresHumanApproval CL3+ 需要人工审批
func (cl ChangeLevel) RequiresHumanApproval() bool {
    return cl >= CL3
}
```

### 4.6 优先级评分

```go
// engine/priority.go
package engine

// PriorityScore 计算优先级评分
// 公式: (Impact × 0.30) + (Urgency × 0.20) + (DepUnlock × 0.20) + (RiskReduction × 0.20) + (UserValue × 0.10) - (Effort × 0.15)
func PriorityScore(impact, urgency, depUnlock, riskReduction, userValue, effort float64) float64 {
    return (impact * 0.30) +
        (urgency * 0.20) +
        (depUnlock * 0.20) +
        (riskReduction * 0.20) +
        (userValue * 0.10) -
        (effort * 0.15)
}

// MapPriority 分数 → 优先级
func MapPriority(score float64) string {
    switch {
    case score >= 4.0:
        return "P0"
    case score >= 3.0:
        return "P1"
    case score >= 2.0:
        return "P2"
    default:
        return "P3"
    }
}
```

### 4.7 Evidence 收集与验证

```go
// engine/evidence.go
package engine

import (
    "fmt"
    "os/exec"
    "strings"
    "time"
    "goalctl/types"
)

// CollectEvidence 从 git diff + 测试结果收集 Evidence
func CollectEvidence(taskID, goalID string) (*types.Evidence, error) {
    diff, _ := exec.Command("git", "diff", "--stat").Output()
    files, _ := exec.Command("git", "diff", "--name-only").Output()
    testResult := detectAndRunTests()

    evidID := fmt.Sprintf("EVID-TEST-%s-%s-001", taskID, time.Now().Format("20060102"))

    return &types.Evidence{
        EvidenceID:   evidID,
        TaskID:       taskID,
        GoalID:       goalID,
        Date:         time.Now().Format("2006-01-02"),
        Status:       testResult.Status,
        FilesChanged: splitLines(string(files)),
        CommandsRun:  []string{"git diff --stat", testResult.Command},
        Results:      testResult.Output,
        DiffSummary:  string(diff),
    }, nil
}

// VerifyEvidence 验证 Evidence 10 个必填字段完整性
func VerifyEvidence(e *types.Evidence) []LintResult {
    var results []LintResult
    required := map[string]string{
        "evidence_id":       e.EvidenceID,
        "task_id":           e.TaskID,
        "goal_id":           e.GoalID,
        "date":              e.Date,
        "status":            string(e.Status),
        "files_changed":     fmt.Sprintf("%v", e.FilesChanged),
        "commands_run":      fmt.Sprintf("%v", e.CommandsRun),
        "results":           e.Results,
        "diff_summary":      e.DiffSummary,
        "requirement_proof": e.RequirementProof,
    }
    for field, val := range required {
        if val == "" || val == "[]" {
            results = append(results, LintResult{
                RuleID:  "EVID-FIELD",
                Status:  "FAIL",
                Message: fmt.Sprintf("Evidence 缺少必填字段: %s", field),
            })
        }
    }
    return results
}

func splitLines(s string) []string {
    lines := strings.Split(strings.TrimSpace(s), "\n")
    var result []string
    for _, l := range lines {
        if l = strings.TrimSpace(l); l != "" {
            result = append(result, l)
        }
    }
    return result
}
```

### 4.8 DoR / DoD 检查

```go
// engine/dor_dod.go
package engine

import "goalctl/types"

// 预定义 DoR/DoD 检查项（来自 06-dod.md）
var dorDodChecks = []types.DoDCheck{
    // Goal DoR
    {CheckID: "GOAL-DOR-1", Stage: types.StageGoal, Type: "dor", Criterion: "已说明业务背景"},
    {CheckID: "GOAL-DOR-2", Stage: types.StageGoal, Type: "dor", Criterion: "已说明目标用户"},
    {CheckID: "GOAL-DOR-3", Stage: types.StageGoal, Type: "dor", Criterion: "已说明期望结果"},
    {CheckID: "GOAL-DOR-4", Stage: types.StageGoal, Type: "dor", Criterion: "已说明成功指标"},
    {CheckID: "GOAL-DOR-5", Stage: types.StageGoal, Type: "dor", Criterion: "已说明范围边界"},
    {CheckID: "GOAL-DOR-6", Stage: types.StageGoal, Type: "dor", Criterion: "已说明 Non-goals"},
    {CheckID: "GOAL-DOR-7", Stage: types.StageGoal, Type: "dor", Criterion: "已说明关键约束"},

    // Goal DoD
    {CheckID: "GOAL-DOD-1", Stage: types.StageGoal, Type: "dod", Criterion: "所有关联 Issue 完成", Automated: true, Validator: "goalAllIssuesDone"},
    {CheckID: "GOAL-DOD-2", Stage: types.StageGoal, Type: "dod", Criterion: "Success Criteria 满足"},
    {CheckID: "GOAL-DOD-3", Stage: types.StageGoal, Type: "dod", Criterion: "P0/P1 Requirement PASS", Automated: true, Validator: "goalP0P1Pass"},
    {CheckID: "GOAL-DOD-4", Stage: types.StageGoal, Type: "dod", Criterion: "Release Manifest 完整", Automated: true, Validator: "goalReleaseManifest"},
    {CheckID: "GOAL-DOD-5", Stage: types.StageGoal, Type: "dod", Criterion: "Retrospective 完成"},

    // Spec DoR/DoD (4+3)
    {CheckID: "SPEC-DOR-1", Stage: types.StageSpec, Type: "dor", Criterion: "Goal 已明确", Automated: true, Validator: "specGoalClear"},
    {CheckID: "SPEC-DOR-2", Stage: types.StageSpec, Type: "dor", Criterion: "业务规则基本清楚"},
    {CheckID: "SPEC-DOR-3", Stage: types.StageSpec, Type: "dor", Criterion: "用户角色已明确"},
    {CheckID: "SPEC-DOR-4", Stage: types.StageSpec, Type: "dor", Criterion: "核心流程已明确"},
    {CheckID: "SPEC-DOD-1", Stage: types.StageSpec, Type: "dod", Criterion: "每条需求原子化、可实现、可测试", Automated: true, Validator: "specAtomic"},
    {CheckID: "SPEC-DOD-2", Stage: types.StageSpec, Type: "dod", Criterion: "正常/异常/边界路径有描述"},
    {CheckID: "SPEC-DOD-3", Stage: types.StageSpec, Type: "dod", Criterion: "安全/性能/权限/数据要求无遗漏"},

    // Design DoR/DoD (3+4)
    {CheckID: "DESIGN-DOR-1", Stage: types.StageDesign, Type: "dor", Criterion: "Spec 已审批", Automated: true, Validator: "designSpecApproved"},
    {CheckID: "DESIGN-DOR-2", Stage: types.StageDesign, Type: "dor", Criterion: "核心需求已明确"},
    {CheckID: "DESIGN-DOR-3", Stage: types.StageDesign, Type: "dor", Criterion: "技术约束已识别"},
    {CheckID: "DESIGN-DOD-1", Stage: types.StageDesign, Type: "dod", Criterion: "每个 Spec Requirement 有对应 Module", Automated: true, Validator: "designModuleCoverage"},
    {CheckID: "DESIGN-DOD-2", Stage: types.StageDesign, Type: "dod", Criterion: "模块边界清晰"},
    {CheckID: "DESIGN-DOD-3", Stage: types.StageDesign, Type: "dod", Criterion: "接口可测试"},
    {CheckID: "DESIGN-DOD-4", Stage: types.StageDesign, Type: "dod", Criterion: "无循环依赖", Automated: true, Validator: "designNoCycles"},

    // Plan DoR/DoD (3+7)
    {CheckID: "PLAN-DOR-1", Stage: types.StagePlan, Type: "dor", Criterion: "Design 已完成", Automated: true, Validator: "planDesignDone"},
    {CheckID: "PLAN-DOR-2", Stage: types.StagePlan, Type: "dor", Criterion: "主要模块和依赖已知"},
    {CheckID: "PLAN-DOR-3", Stage: types.StagePlan, Type: "dor", Criterion: "风险点已识别"},
    {CheckID: "PLAN-DOD-1", Stage: types.StagePlan, Type: "dod", Criterion: "执行顺序明确"},
    {CheckID: "PLAN-DOD-2", Stage: types.StagePlan, Type: "dod", Criterion: "阶段产物明确"},
    {CheckID: "PLAN-DOD-3", Stage: types.StagePlan, Type: "dod", Criterion: "每阶段有验证点"},
    {CheckID: "PLAN-DOD-4", Stage: types.StagePlan, Type: "dod", Criterion: "高风险任务提前处理"},
    {CheckID: "PLAN-DOD-5", Stage: types.StagePlan, Type: "dod", Criterion: "有回滚策略", Automated: true, Validator: "planRollback"},
    {CheckID: "PLAN-DOD-6", Stage: types.StagePlan, Type: "dod", Criterion: "可增量交付"},
    {CheckID: "PLAN-DOD-7", Stage: types.StagePlan, Type: "dod", Criterion: "已定义 Task 拆分边界"},

    // Tasks DoR/DoD (3+5)
    {CheckID: "TASKS-DOR-1", Stage: types.StageTasks, Type: "dor", Criterion: "Plan 已完成", Automated: true, Validator: "tasksPlanDone"},
    {CheckID: "TASKS-DOR-2", Stage: types.StageTasks, Type: "dor", Criterion: "Task 拆分边界已明确"},
    {CheckID: "TASKS-DOR-3", Stage: types.StageTasks, Type: "dor", Criterion: "Matrix 可记录覆盖关系"},
    {CheckID: "TASKS-DOD-1", Stage: types.StageTasks, Type: "dod", Criterion: "每个 Task 有明确输入/输出/AC", Automated: true, Validator: "taskComplete"},
    {CheckID: "TASKS-DOD-2", Stage: types.StageTasks, Type: "dod", Criterion: "每个 Task 足够小"},
    {CheckID: "TASKS-DOD-3", Stage: types.StageTasks, Type: "dod", Criterion: "每个 Task 能追溯到 Goal", Automated: true, Validator: "taskTracable"},
    {CheckID: "TASKS-DOD-4", Stage: types.StageTasks, Type: "dod", Criterion: "每个 Task 有明确 DoD"},
    {CheckID: "TASKS-DOD-5", Stage: types.StageTasks, Type: "dod", Criterion: "无无来源 Task", Automated: true, Validator: "taskNoOrphan"},

    // Prompt DoR/DoD (3+6)
    {CheckID: "PROMPT-DOR-1", Stage: types.StagePrompt, Type: "dor", Criterion: "Task 已明确", Automated: true, Validator: "promptTaskClear"},
    {CheckID: "PROMPT-DOR-2", Stage: types.StagePrompt, Type: "dor", Criterion: "上下文已准备"},
    {CheckID: "PROMPT-DOR-3", Stage: types.StagePrompt, Type: "dor", Criterion: "技术约束已明确"},
    {CheckID: "PROMPT-DOD-1", Stage: types.StagePrompt, Type: "dod", Criterion: "包含 Goal/Spec/Task"},
    {CheckID: "PROMPT-DOD-2", Stage: types.StagePrompt, Type: "dod", Criterion: "输入输出要求明确"},
    {CheckID: "PROMPT-DOD-3", Stage: types.StagePrompt, Type: "dod", Criterion: "约束和禁止事项明确"},
    {CheckID: "PROMPT-DOD-4", Stage: types.StagePrompt, Type: "dod", Criterion: "验收标准明确"},
    {CheckID: "PROMPT-DOD-5", Stage: types.StagePrompt, Type: "dod", Criterion: "测试要求明确"},
    {CheckID: "PROMPT-DOD-6", Stage: types.StagePrompt, Type: "dod", Criterion: "AI 可直接执行"},

    // Code DoR/DoD (3+6)
    {CheckID: "CODE-DOR-1", Stage: types.StageCode, Type: "dor", Criterion: "Prompt 已清晰"},
    {CheckID: "CODE-DOR-2", Stage: types.StageCode, Type: "dor", Criterion: "依赖已准备"},
    {CheckID: "CODE-DOR-3", Stage: types.StageCode, Type: "dor", Criterion: "测试要求已明确"},
    {CheckID: "CODE-DOD-1", Stage: types.StageCode, Type: "dod", Criterion: "代码实现对应 Task"},
    {CheckID: "CODE-DOD-2", Stage: types.StageCode, Type: "dod", Criterion: "测试覆盖验收标准"},
    {CheckID: "CODE-DOD-3", Stage: types.StageCode, Type: "dod", Criterion: "Matrix 状态已更新", Automated: true, Validator: "codeMatrixUpdated"},
    {CheckID: "CODE-DOD-4", Stage: types.StageCode, Type: "dod", Criterion: "PR 描述能追溯到 Goal"},
    {CheckID: "CODE-DOD-5", Stage: types.StageCode, Type: "dod", Criterion: "不包含无关功能"},
    {CheckID: "CODE-DOD-6", Stage: types.StageCode, Type: "dod", Criterion: "没有破坏已有能力"},

    // Test DoR/DoD (3+5)
    {CheckID: "TEST-DOR-1", Stage: types.StageTest, Type: "dor", Criterion: "验收标准已明确"},
    {CheckID: "TEST-DOR-2", Stage: types.StageTest, Type: "dor", Criterion: "测试环境已就绪"},
    {CheckID: "TEST-DOR-3", Stage: types.StageTest, Type: "dor", Criterion: "测试数据已准备"},
    {CheckID: "TEST-DOD-1", Stage: types.StageTest, Type: "dod", Criterion: "单元测试覆盖所有 Task", Automated: true, Validator: "testTaskCoverage"},
    {CheckID: "TEST-DOD-2", Stage: types.StageTest, Type: "dod", Criterion: "集成测试覆盖关键流"},
    {CheckID: "TEST-DOD-3", Stage: types.StageTest, Type: "dod", Criterion: "E2E 测试覆盖 Goal 级 AC"},
    {CheckID: "TEST-DOD-4", Stage: types.StageTest, Type: "dod", Criterion: "性能测试覆盖 Success Metrics"},
    {CheckID: "TEST-DOD-5", Stage: types.StageTest, Type: "dod", Criterion: "测试结果记录在 Evidence", Automated: true, Validator: "testEvidencePresent"},

    // Review DoR/DoD (3+6)
    {CheckID: "REVIEW-DOR-1", Stage: types.StageReview, Type: "dor", Criterion: "实现完成"},
    {CheckID: "REVIEW-DOR-2", Stage: types.StageReview, Type: "dor", Criterion: "测试通过"},
    {CheckID: "REVIEW-DOR-3", Stage: types.StageReview, Type: "dor", Criterion: "Evidence 已生成", Automated: true, Validator: "reviewEvidenceGenerated"},
    {CheckID: "REVIEW-DOD-1", Stage: types.StageReview, Type: "dod", Criterion: "代码满足 Task 要求"},
    {CheckID: "REVIEW-DOD-2", Stage: types.StageReview, Type: "dod", Criterion: "代码满足 Spec 要求"},
    {CheckID: "REVIEW-DOD-3", Stage: types.StageReview, Type: "dod", Criterion: "Matrix 覆盖率达标", Automated: true, Validator: "reviewMatrixCoverage"},
    {CheckID: "REVIEW-DOD-4", Stage: types.StageReview, Type: "dod", Criterion: "无 CRITICAL/HIGH 问题", Automated: true, Validator: "reviewNoCritical"},
    {CheckID: "REVIEW-DOD-5", Stage: types.StageReview, Type: "dod", Criterion: "安全要求已验证"},
    {CheckID: "REVIEW-DOD-6", Stage: types.StageReview, Type: "dod", Criterion: "性能要求已验证"},

    // Issue DoD (5)
    {CheckID: "ISSUE-DOD-1", Stage: types.StageIssue, Type: "dod", Criterion: "所有关联 Task 完成", Automated: true, Validator: "issueAllTasksDone"},
    {CheckID: "ISSUE-DOD-2", Stage: types.StageIssue, Type: "dod", Criterion: "Traceability Matrix 更新"},
    {CheckID: "ISSUE-DOD-3", Stage: types.StageIssue, Type: "dod", Criterion: "Issue 状态更新"},
    {CheckID: "ISSUE-DOD-4", Stage: types.StageIssue, Type: "dod", Criterion: "PR 关联"},
    {CheckID: "ISSUE-DOD-5", Stage: types.StageIssue, Type: "dod", Criterion: "Evidence 汇总"},

    // Release DoD (7)
    {CheckID: "RELEASE-DOD-1", Stage: types.StageRelease, Type: "dod", Criterion: "CI 通过", Automated: true, Validator: "releaseCIPass"},
    {CheckID: "RELEASE-DOD-2", Stage: types.StageRelease, Type: "dod", Criterion: "PR 描述完整"},
    {CheckID: "RELEASE-DOD-3", Stage: types.StageRelease, Type: "dod", Criterion: "CHANGELOG 更新"},
    {CheckID: "RELEASE-DOD-4", Stage: types.StageRelease, Type: "dod", Criterion: "Docs 更新"},
    {CheckID: "RELEASE-DOD-5", Stage: types.StageRelease, Type: "dod", Criterion: "Release Manifest 完整", Automated: true, Validator: "releaseManifest"},
    {CheckID: "RELEASE-DOD-6", Stage: types.StageRelease, Type: "dod", Criterion: "Rollback Plan 完整"},
    {CheckID: "RELEASE-DOD-7", Stage: types.StageRelease, Type: "dod", Criterion: "风险已接受或关闭", Automated: true, Validator: "releaseRiskClosed"},

    // Retrospective DoD (4)
    {CheckID: "RETRO-DOD-1", Stage: types.StageRetro, Type: "dod", Criterion: "至少识别一个改进点"},
    {CheckID: "RETRO-DOD-2", Stage: types.StageRetro, Type: "dod", Criterion: "至少生成一个 Patch", Automated: true, Validator: "retroPatchGenerated"},
    {CheckID: "RETRO-DOD-3", Stage: types.StageRetro, Type: "dod", Criterion: "至少提出一个自动化建议"},
    {CheckID: "RETRO-DOD-4", Stage: types.StageRetro, Type: "dod", Criterion: "新经验进入 Registry", Automated: true, Validator: "retroRegistryUpdated"},

    // Matrix Coverage DoR/DoD (横切)
    {CheckID: "MATRIX-DOR-1", Stage: types.StageMatrix, Type: "dor", Criterion: "Goal/Spec/AC 已编号", Automated: true, Validator: "matrixIDsValid"},
    {CheckID: "MATRIX-DOR-2", Stage: types.StageMatrix, Type: "dor", Criterion: "Plan 已完成"},
    {CheckID: "MATRIX-DOR-3", Stage: types.StageMatrix, Type: "dor", Criterion: "Tasks 已拆分"},
    {CheckID: "MATRIX-DOD-1", Stage: types.StageMatrix, Type: "dod", Criterion: "每个 Goal Item 有 Spec 覆盖", Automated: true, Validator: "matrixGoalItemCoverage"},
    {CheckID: "MATRIX-DOD-2", Stage: types.StageMatrix, Type: "dod", Criterion: "每条 Spec 有 Task 覆盖", Automated: true, Validator: "matrixSpecTaskCoverage"},
    {CheckID: "MATRIX-DOD-3", Stage: types.StageMatrix, Type: "dod", Criterion: "关键 AC 有 Test 覆盖计划"},
    {CheckID: "MATRIX-DOD-4", Stage: types.StageMatrix, Type: "dod", Criterion: "无孤立 Task/Code/需求", Automated: true, Validator: "matrixNoOrphans"},
    {CheckID: "MATRIX-DOD-5", Stage: types.StageMatrix, Type: "dod", Criterion: "覆盖检查结果可作为 G5 证据"},
}

// CheckDoRDoD 检查指定 stage 的 DoR 或 DoD
func CheckDoRDoD(stage types.StageName, dorOrDod string, ctx *CheckContext) []LintResult {
    var results []LintResult
    for _, check := range dorDodChecks {
        if check.Stage != stage || check.Type != dorOrDod {
            continue
        }
        if !check.Automated {
            results = append(results, LintResult{
                RuleID: check.CheckID, Status: "WARN",
                Message: "需人工确认: " + check.Criterion,
            })
            continue
        }
        if checker, ok := checkerRegistry[check.Validator]; ok {
            results = append(results, LintResult{
                RuleID: check.CheckID,
                Status: checker(ctx).Status,
                Message: check.Criterion,
            })
        }
    }
    return results
}
```

---

## 5. CLI 命令设计（cmd/）

### 5.1 命令总览

```
goalctl validate <id-type> <id>       # 校验 ID 格式
goalctl gate check <gate-id>          # 执行 Gate 检查
goalctl gate status                   # 查看所有 Gate 状态
goalctl lint [category]               # 执行 Lint (G/S/M/P/C/all)
goalctl pipeline status               # 查看 Pipeline 状态
goalctl pipeline transition <phase>   # 执行状态转换
goalctl matrix coverage               # 检查 Matrix 覆盖率
goalctl matrix orphans                # 检查孤立节点
goalctl matrix add-edge               # 添加 Matrix 边
goalctl registry list <type>          # 列出 Registry 条目
goalctl registry add <type> <file>    # 添加 Registry 条目
goalctl registry update <type> <id>   # 更新 Registry 条目
goalctl evidence collect <task-id>    # 收集 Evidence
goalctl evidence verify <evid-id>     # 验证 Evidence 完整性
goalctl dor check <stage>             # 检查 DoR
goalctl dod check <stage>             # 检查 DoD
goalctl ci preflight                  # CI Pre-flight 检查
goalctl ci verify                     # CI Verification 检查
goalctl propagate <type>              # 执行变更传播
goalctl status                        # 全局状态总览
```

### 5.2 实现示例

```go
// cmd/goalctl/main.go
package main

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
    "goalctl/engine"
    "goalctl/types"
)

func main() {
    root := &cobra.Command{
        Use:   "goalctl",
        Short: "Goal 驱动交付体系 CLI",
    }

    // goalctl validate GOAL GOAL-20260608-001
    validateCmd := &cobra.Command{
        Use:   "validate <id-type> <id>",
        Short: "校验 ID 格式",
        Args:  cobra.ExactArgs(2),
        RunE: func(cmd *cobra.Command, args []string) error {
            if types.ValidateID(args[0], args[1]) {
                fmt.Printf("✅ %s 格式正确\n", args[1])
            } else {
                fmt.Printf("❌ %s 不符合 %s 规范\n", args[1], args[0])
                os.Exit(1)
            }
            return nil
        },
    }

    // goalctl gate check G5
    gateCmd := &cobra.Command{Use: "gate", Short: "Gate 检查"}
    gateCheckCmd := &cobra.Command{
        Use:   "check <gate-id>",
        Short: "执行 Gate 检查",
        Args:  cobra.ExactArgs(1),
        RunE: func(cmd *cobra.Command, args []string) error {
            ctx := loadCheckContext()
            gate, err := engine.RunGate(args[0], ctx)
            if err != nil {
                return err
            }
            printGateResult(gate)
            return nil
        },
    }

    // goalctl lint M
    lintCmd := &cobra.Command{
        Use:   "lint [category]",
        Short: "执行 Lint 规则 (G/S/M/P/C/all)",
        Args:  cobra.MaximumNArgs(1),
        RunE: func(cmd *cobra.Command, args []string) error {
            category := "all"
            if len(args) > 0 {
                category = args[0]
            }
            data := loadLintData(category)
            results := engine.RunLint(category, data)
            printLintResults(results)
            return nil
        },
    }

    // goalctl pipeline status / transition
    pipelineCmd := &cobra.Command{Use: "pipeline", Short: "Pipeline 状态管理"}
    pipelineStatusCmd := &cobra.Command{
        Use: "status", Short: "查看 Pipeline 状态",
        RunE: func(cmd *cobra.Command, args []string) error {
            p := loadPipelineState()
            printPipelineStatus(p)
            return nil
        },
    }
    pipelineTransitionCmd := &cobra.Command{
        Use:   "transition <phase>",
        Short: "执行状态转换",
        Args:  cobra.ExactArgs(1),
        RunE: func(cmd *cobra.Command, args []string) error {
            p := loadPipelineState()
            if err := engine.ExecuteTransition(p, types.CurrentPhase(args[0])); err != nil {
                return err
            }
            savePipelineState(p)
            fmt.Printf("✅ 转换到 %s 完成\n", args[0])
            return nil
        },
    }

    // goalctl evidence collect TASK-...
    evidenceCmd := &cobra.Command{Use: "evidence", Short: "Evidence 管理"}
    evidenceCollectCmd := &cobra.Command{
        Use:   "collect <task-id>",
        Short: "收集 Evidence",
        Args:  cobra.ExactArgs(1),
        RunE: func(cmd *cobra.Command, args []string) error {
            evid, err := engine.CollectEvidence(args[0], loadGoalID())
            if err != nil {
                return err
            }
            saveEvidence(evid)
            fmt.Printf("✅ Evidence %s 已生成\n", evid.EvidenceID)
            return nil
        },
    }

    // goalctl matrix coverage / orphans
    matrixCmd := &cobra.Command{Use: "matrix", Short: "Matrix 管理"}
    matrixCoverageCmd := &cobra.Command{
        Use: "coverage", Short: "检查 Matrix 覆盖率",
        RunE: func(cmd *cobra.Command, args []string) error {
            matrix := loadMatrix()
            coverage := engine.CalculateCoverage(matrix)
            printCoverageReport(coverage)
            return nil
        },
    }
    matrixOrphansCmd := &cobra.Command{
        Use: "orphans", Short: "检查孤立节点",
        RunE: func(cmd *cobra.Command, args []string) error {
            matrix := loadMatrix()
            tasks := loadTasks()
            orphans := engine.FindOrphans(matrix, tasks)
            printOrphans(orphans)
            return nil
        },
    }

    // goalctl ci preflight
    ciCmd := &cobra.Command{Use: "ci", Short: "CI 检查"}
    ciPreflightCmd := &cobra.Command{
        Use: "preflight", Short: "CI Pre-flight 检查",
        RunE: func(cmd *cobra.Command, args []string) error {
            results := engine.RunPreflight()
            printCIResults(results)
            return nil
        },
    }

    // 注册子命令
    gateCmd.AddCommand(gateCheckCmd)
    pipelineCmd.AddCommand(pipelineStatusCmd, pipelineTransitionCmd)
    evidenceCmd.AddCommand(evidenceCollectCmd)
    matrixCmd.AddCommand(matrixCoverageCmd, matrixOrphansCmd)
    ciCmd.AddCommand(ciPreflightCmd)

    root.AddCommand(validateCmd, gateCmd, lintCmd, pipelineCmd, evidenceCmd, matrixCmd, ciCmd)
    root.Execute()
}
```

---

## 6. 数据流：文档 → 运行时

```
docs/goal/*.md              .config/goal/              goalctl engine
─────────────────           ──────────────────         ──────────────
03-pipeline.md        →     pipeline/state.yaml   →    Pipeline 状态机
04-gates.md           →     gates/state.yaml      →    Gate 检查器
05-layer-standards.md →     (内嵌为 checker 规则)  →    Gate CheckItems
06-dod.md             →     (内嵌为 checker 规则)  →    DoR/DoD Checker
07-id-system.md       →     (内嵌为 regex 表)      →    ID Validator
10-lint-rules.md      →     (内嵌为 lint 规则)     →    Lint Engine
13-runtime-engine.md  →     (内嵌为转换规则)       →    ChangeLevel / Propagation
15-registry.md        →     registry/*.yaml       →    Collection[T] CRUD
16-ci-cd.md           →     (内嵌为 CI checker)    →    CI Preflight / Verify

matrix.yaml           →     Matrix 边模型          →    覆盖率 / 孤立检查
evidence/*.md         →     Evidence 结构体        →    完整性验证
```

---

## 7. 与现有工具的关系

现有 shell 脚本（`docs/goal/tools/`）与 Go 实现的对应关系：

| 现有工具              | 行数   | Go 等价                | 迁移策略                  |
| --------------------- | ------ | ---------------------- | ------------------------- |
| `gate-check.sh`       | 278    | `engine/gate_check.go` | 直接替换                  |
| `lint-goal.sh`        | 304    | `engine/lint.go`       | 直接替换，消除内嵌 Python |
| `self-test.sh`        | 433    | `engine/*_test.go`     | 转化为 Go 单元测试        |
| `evidence-collect.sh` | 156    | `engine/evidence.go`   | 直接替换                  |
| `matrix-gen.py`       | ~100   | `engine/matrix.go`     | 整合进 Go engine          |

迁移路径：Go 版本先与 shell 版本并行运行，结果对比一致后切换。

---

## 8. CI/CD 集成

### 8.1 CI Checks 实现

```go
// engine/ci.go
package engine

type CICheckResult struct {
    CheckID string `json:"check_id"`
    Name    string `json:"name"`
    Status  string `json:"status"` // PASS / FAIL / WARN
    Details string `json:"details"`
}

// RunPreflight Phase 0: Pre-flight 检查
func RunPreflight() []CICheckResult {
    return []CICheckResult{
        checkWorkingDirClean(),   // CI-CHK0
        checkBuild(),             // CI-CHK1
        checkUnitTests(),         // CI-CHK2
        checkIntegrationTests(),  // CI-CHK3
        checkLint(),              // CI-CHK4
        checkArchRules(),         // CI-CHK5
        checkDocsSync(),          // CI-CHK6
        checkChangelogSync(),     // CI-CHK7
        checkEvidenceManifest(),  // CI-CHK8
        checkReleaseManifest(),   // CI-CHK9
    }
}

// RunXGoChecks x.go 专用检查（XG-CHK1 ~ XG-CHK8）
func RunXGoChecks() []CICheckResult {
    return []CICheckResult{
        checkModuleBoundary(),  // XG-CHK1
        checkNoFakeImpl(),      // XG-CHK2
        checkConfigExample(),   // XG-CHK3
        checkDocsChangelog(),   // XG-CHK4
        checkReleaseManifest(), // XG-CHK5
        checkGoFirst(),         // XG-CHK6
        checkSecretsPath(),     // XG-CHK7
        checkIssueSync(),       // XG-CHK8
    }
}
```

---

## 9. 测试策略

### 9.1 测试金字塔

```
                    ┌─────────────┐
                    │  E2E 测试   │  goalctl ci preflight 完整流程
                    │  (少量)     │
                    ├─────────────┤
                    │  集成测试   │  Gate check + Matrix + Registry 联动
                    │  (中量)     │
                    ├─────────────┤
                    │  单元测试   │  每个 checker、每个 lint rule、状态机转换
                    │  (大量)     │
                    └─────────────┘
```

### 9.2 关键测试用例

| 测试类型      | 覆盖内容                               | 数量     |
| ------------- | -------------------------------------- | -------- |
| ID 格式校验   | 18 种 ID 格式的正例/反例               | ~40      |
| 状态机转换    | 正常转换 + 异常转换 + Guard 拒绝       | ~30      |
| Gate 检查器   | 11 个 Gate 的 PASS/FAIL/PASS_WITH_RISK | ~50      |
| Lint 规则     | 33 条规则的正例/反例                   | ~70      |
| Matrix 操作   | 覆盖率计算、孤立检查、状态转换         | ~20      |
| Evidence 验证 | 10 个必填字段的完整性                  | ~15      |
| DoR/DoD       | 13 个 stage 的检查项                   | ~30      |
| CI 检查       | 10 个 CI-CHK + 8 个 XG-CHK             | ~20      |
| 变更传播      | 12 种变更类型的传播链                  | ~15      |
| **总计**      |                                        | **~290** |

### 9.3 表驱动测试示例

```go
// engine/gate_check_test.go
func TestGateChecks(t *testing.T) {
    tests := []struct {
        name     string
        gateID   string
        ctx      *CheckContext
        expected types.GateResult
    }{
        {"G0 全部通过", "G0", fullContext(), types.GatePass},
        {"G0 缺少 objective", "G0", noObjectContext(), types.GateFail},
        {"G5 Matrix 覆盖率不足", "G5", lowCoverageContext(), types.GateFail},
        {"G10 PASS_WITH_RISK 策略禁止", "G10", riskContext(), types.GateFail},
        {"G11 在 G10 之前执行", "G11", beforeG10Context(), types.GateBlocked},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            gate, _ := RunGate(tt.gateID, tt.ctx)
            if gate.Result != tt.expected {
                t.Errorf("期望 %s，实际 %s", tt.expected, gate.Result)
            }
        })
    }
}

// engine/pipeline_test.go
func TestPipelineTransitions(t *testing.T) {
    tests := []struct {
        name      string
        from      types.PipelineState
        phase     types.CurrentPhase
        expectErr bool
        expectTo  types.PipelineState
    }{
        {"SPEC_READY → SPEC → DESIGN_READY", types.StateSpecReady, types.PhaseSpec, false, types.StateDesignReady},
        {"DONE 不允许转换", types.StateDone, types.PhaseSpec, true, ""},
        {"BLOCKED 不允许直接转换", types.StateBlocked, types.PhaseSpec, true, ""},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            p := &types.Pipeline{PipelineState: tt.from}
            err := ExecuteTransition(p, tt.phase)
            if tt.expectErr {
                if err == nil { t.Error("期望错误但未返回") }
            } else {
                if err != nil { t.Errorf("意外错误: %v", err) }
                if p.PipelineState != tt.expectTo { t.Errorf("期望 %s，实际 %s", tt.expectTo, p.PipelineState) }
            }
        })
    }
}
```

---

## 10. 实现路线图

### Phase 1: 核心骨架（2-3 天）

| 天   | 任务                                   | 产出                   |
| ---- | -------------------------------------- | ---------------------- |
| D1   | types/ 全部结构体 + ID 格式校验        | `types/*.go`           |
| D1   | Pipeline 状态机 + 转换规则             | `engine/pipeline.go`   |
| D2   | Gate 检查器框架 + G0/G5/G8/G9 实现     | `engine/gate_check.go` |
| D2   | CLI 骨架 + validate/gate/pipeline 命令 | `cmd/goalctl/main.go`  |
| D3   | Lint 引擎 + G-LINT/M-LINT 自动规则     | `engine/lint.go`       |
| D3   | 核心测试（状态机 + Gate + Lint）       | `*_test.go`            |

**MVP 交付物**：`goalctl validate`、`goalctl gate check`、`goalctl pipeline status`、`goalctl lint`

### Phase 2: Registry + Matrix（2 天）

| 天   | 任务                                     | 产出                  |
| ---- | ---------------------------------------- | --------------------- |
| D4   | Collection[T] 泛型容器 + YAML 序列化     | `types/collection.go` |
| D4   | 6 个 Registry 的 CRUD + CLI 命令         | `engine/registry.go`  |
| D5   | Matrix Edge 操作 + 覆盖率计算 + 孤立检查 | `engine/matrix.go`    |
| D5   | Registry + Matrix 测试                   | `*_test.go`           |

### Phase 3: Evidence + CI（1-2 天）

| 天   | 任务                            | 产出                    |
| ---- | ------------------------------- | ----------------------- |
| D6   | Evidence 收集 + 验证 + CLI 命令 | `engine/evidence.go`    |
| D6   | CI Preflight + x.go 专用检查    | `engine/ci.go`          |
| D7   | 变更传播 + DoR/DoD 检查         | `engine/propagation.go` |
| D7   | 集成测试 + self-test.sh 迁移    | `*_test.go`             |

### Phase 4: 完善（1 天）

| 天   | 任务                           | 产出                 |
| ---- | ------------------------------ | -------------------- |
| D8   | 优先级评分 + AutoResearch 协议 | `engine/priority.go` |
| D8   | 文档 + README + 使用示例       | `README.md`          |
| D8   | 与 shell 脚本并行验证          | 对比报告             |

**总计：5-8 天**

---

## 11. 依赖清单

```go
// go.mod
module github.com/ZoneCNH/goalctl

go 1.22

require (
    github.com/spf13/cobra v1.8.0     // CLI 框架
    gopkg.in/yaml.v3 v3.0.1            // YAML 序列化
    github.com/stretchr/testify v1.9.0 // 测试断言
)
```

零外部业务依赖。仅标准库 + cobra + yaml + testify。

---

## 12. 风险与缓解

| 风险          | 影响               | 缓解                                     |
| ------------- | ------------------ | ---------------------------------------- |
| 规则翻译遗漏  | 检查不完整         | self-test.sh 全部用例迁移后对比          |
| YAML 格式兼容 | 现有数据不可读     | 使用相同的 yaml.v3 库                    |
| 性能不足      | CI 变慢            | Go 编译后单二进制，启动 < 10ms           |
| 维护负担      | 规则更新需同步代码 | 规则内嵌为代码，文档是参考而非运行时输入 |

---

## 13. 总结

| 维度           | 数据                         |
| -------------- | ---------------------------- |
| 文档总数       | 30 份                        |
| 可执行文档     | 6 份（直接翻译为代码）       |
| 规则文档       | 5 份（翻译为 checker 规则）  |
| 概念文档       | 4 份（提供 context）         |
| Go 结构体      | ~25 个                       |
| Gate 检查器    | 14 个自动 checker            |
| Lint 规则      | 33 条（22 条可自动化）       |
| DoR/DoD 检查项 | ~80 条（~20 条可自动化）     |
| CI 检查项      | 18 个（10 CI + 8 x.go）      |
| 测试用例       | ~290 个                      |
| 外部依赖       | 3 个（cobra, yaml, testify） |
| 预估工期       | 5-8 天                       |
| 代码量预估     | ~2,500 行                    |
