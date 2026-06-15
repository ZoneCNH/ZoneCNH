# xlib-evidence 规格

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Layer: 基座 · CI 证据运行时
- Module-Version: v0.1.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `xlib-standard`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

xlib-evidence 是 Foundation 的**证据收集与发布运行时**——收集各模块的覆盖率、门禁结果、发布 manifest，生成统一证据报告，支持远程证据验证。

**证据边界：xlib-evidence 提供 CI/发布期证据（CI/release-time evidence）。** xlib-evidence 在 CI pipeline 中运行，不做测试也不生成原始证据——它从各模块（包括 testkitx）收集已有证据，汇总为标准报告。详细分工：

| 维度 | xlib-evidence（CI/发布期证据） | testkitx（测试期证据） |
|------|------------------------------|----------------------|
| 运行阶段 | CI pipeline | `go test` 进程内 |
| 证据类型 | coverage（FR-001）、manifest（FR-002/003）、remote evidence（FR-004）、report（FR-005） | golden/contract/boundary/leak/manifest |
| 角色 | 证据**收集者与发布者** | 证据**生成者** |
| manifest | 发布期 manifest（汇总所有模块 coverage/gate/manifest，含 hash 链校验） | 测试期 manifest（本次测试的 golden/contract/boundary 结果） |

testkitx 与 xlib-evidence 的分工链：testkitx 在 `go test` 过程中生成 golden/contract/boundary/leak 等原始证据 → xlib-evidence 在 CI pipeline 中收集这些证据，结合 coverage 和 gate 结果，生成发布期 manifest 和统一报告。

## 2. 问题与背景

xlib-standard 的 Evidence Runtime 与其声明式标准定义耦合，导致证据收集逻辑和标准定义无法独立演进。证据运行时是一个独立的观测/报告系统，应有自己的发布周期。

## 3. 目标

- 收集各模块覆盖率报告（`go test -cover`）
- 收集门禁结果（spec-lint / boundary-check / traceability-gate 输出）
- 生成并验证 Release Manifest
- 支持远程证据查询和验证
- 输出统一证据报告供 CI 消费

## 4. 非目标

- 不定义标准（那是 xlib-standard）
- 不执行门禁检查（那是 xlib-harness / xlibgate）
- 不生成模块骨架（那是 xlib-harness）
- 不参与业务运行时

## 5. 消费者

- CI 管线：收集证据作为 gate 输入
- xlibgate：发布就绪检查需要 evidence manifest
- 审计/治理：证据可追溯、可验证

## 6. 功能需求

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-001 | collect-coverage | 模块执行 `go test -cover` | 覆盖率报告被收集并结构化存储 |
| FR-002 | generate-manifest | 模块通过所有门禁 | 生成 Release Manifest（版本号、commit SHA、门禁结果、覆盖率为证） |
| FR-003 | validate-manifest | CI 或运维检查 manifest | 验证 manifest 完整性、签名、内容一致性 |
| FR-004 | remote-evidence | 远程查询模块证据 | 返回结构化证据（覆盖率、门禁历史、manifest） |
| FR-005 | evidence-report | 聚合多模块证据 | 生成跨模块统一报告 |

## 7. 行为约束

| ID | 规则 |
|----|------|
| BR-001 | manifest 必须包含门禁全绿证据 |
| BR-002 | 覆盖率低于 80% 不得发布 |
| BR-003 | manifest 不可事后篡改（hash 链校验） |
| BR-004 | evidence 存储必须不可变追加 |


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-001 | FR-001 | TC-001 | `go test -run TestCollectCoverage` | ✅ | |
| AC-002 | FR-002 | TC-002 | `go test -run TestGenerateManifest` | ✅ | |
| AC-003 | FR-003 | TC-003 | `go test -run TestValidateManifest` | ✅ | |
| AC-004 | FR-004 | TC-004 | `go test -run TestRemoteEvidence` | ✅ | |
| AC-005 | FR-005 | TC-005 | `go test -run TestEvidenceReport` | ✅ | |

## 8. 接口契约

```go
type EvidenceCollector interface {
    CollectCoverage(module string) (*CoverageReport, error)
    CollectGateResults(module string) (*GateResults, error)
}

type ManifestGenerator interface {
    Generate(module string, evidence EvidenceBundle) (*Manifest, error)
}

type ManifestValidator interface {
    Validate(manifest Manifest) (*ValidationResult, error)
}
```

## 9. 数据模型

```go
type CoverageReport struct {
    Module    string
    TotalPct  float64
    PerPkg    map[string]float64
    Timestamp time.Time
}

type Manifest struct {
    Module    string
    Version   string
    CommitSHA string
    Gates     []GateResult
    Coverage  CoverageReport
    Hash      string
}

type EvidenceBundle struct {
    Coverage  CoverageReport
    Gates     []GateResult
    Timestamp time.Time
}
```

## 10. 配置模式

```yaml
xlib_evidence:
  storage_path: "./evidence/"
  manifest_path: "./manifest/"
  coverage_threshold: 80.0
  remote:
    enabled: false
    endpoint: ""
```

## 11. 错误处理

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrCoverageNotFound | 模块无覆盖率数据 | 先执行 go test -cover |
| ErrGateNotPassed | 门禁未全绿 | 修复后重试 |
| ErrManifestTampered | manifest hash 不匹配 | 重新生成或调查篡改 |

## 12. 边界情况

- 覆盖率恰好 80.00%（边界值）
- manifest 文件被手动修改
- 多个 CI job 并发生成同一模块 manifest
- 远程 evidence endpoint 不可用时的降级

## 13. 目录结构

```text
module/xlib-evidence/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 14. 依赖

- 允许：kernel（time/errors）
- 禁止：observex、configx、resiliencx、schedulex
- 禁止：任何存储/网络后端（不连接 Redis/Postgres）
- 允许：读取文件系统上的覆盖率报告和门禁输出

## 15. 测试

- 单元测试：manifest 生成/验证独立可测
- 集成测试：collect → generate → validate 端到端
- Golden 测试：固定覆盖率输入 → 固定 manifest 输出

### 15.1 Traceability Test Cases

**TC-001:** mock 覆盖率输出 → CoverageReport 正确。
**TC-002:** 给定全部门禁通过 → manifest 生成且 hash 有效。
**TC-003:** 合法 manifest 通过；篡改 manifest 拒绝。
**TC-004:** HTTP endpoint 返回 JSON 证据。
**TC-005:** 3 模块输入 → 统合报告列出全部状态。

## 16. 性能预算

| 指标 | 目标 |
|------|------|
| manifest 生成 | < 1s |
| 多模块报告聚合（20 模块） | < 5s |

## 17. 可观测性

- 无运行时指标（不参与业务运行）
- 证据报告格式：JSON

## 18. 安全

- manifest hash 用于完整性校验
- 不读取密钥
- 不连接远程服务（remote evidence 为可选）

## 19. CI 门禁

- `make test`
- `make vet`

## 20. 升级兼容性

- manifest 格式 v1 保持稳定
- 新字段为追加，不删除旧字段

## 21. 发布 DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] collect → generate → validate 闭环
- [ ] 文档齐全

## 22. 待解决问题

- remote evidence 是否需要签名？
- 证据存储是否需要支持 SQLite/文件双后端？
- manifest 是否应包含 reproducible build info？

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-14 | v1.0.0 | 初始版本，从 xlib-standard 拆分 | ZoneCNH |
