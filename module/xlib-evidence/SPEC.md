# xlib-evidence — 证据收集与发布运行时

## 1. Metadata

| 字段 | 值 |
|------|-----|
| Status | Draft |
| Owner | Foundation |
| Source | 从 xlib-standard 拆分：承接 Evidence Runtime 职责 |
| Last Updated | 2026-06-14 |

## 2. Summary

xlib-evidence 是 Foundation 的**证据收集与发布运行时**——收集各模块的覆盖率、门禁结果、发布 manifest，生成统一证据报告，支持远程证据验证。

## 3. Problem

xlib-standard 的 Evidence Runtime 与其声明式标准定义耦合，导致证据收集逻辑和标准定义无法独立演进。证据运行时是一个独立的观测/报告系统，应有自己的发布周期。

## 4. Goals

- 收集各模块覆盖率报告（`go test -cover`）
- 收集门禁结果（spec-lint / boundary-check / traceability-gate 输出）
- 生成并验证 Release Manifest
- 支持远程证据查询和验证
- 输出统一证据报告供 CI 消费

## 5. Non-goals

- 不定义标准（那是 xlib-standard）
- 不执行门禁检查（那是 xlib-harness / xlibgate）
- 不生成模块骨架（那是 xlib-harness）
- 不参与业务运行时

## 6. Consumers

- CI 管线：收集证据作为 gate 输入
- xlibgate：发布就绪检查需要 evidence manifest
- 审计/治理：证据可追溯、可验证

## 7. Functional Requirements

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-001 | collect-coverage | 模块执行 `go test -cover` | 覆盖率报告被收集并结构化存储 |
| FR-002 | generate-manifest | 模块通过所有门禁 | 生成 Release Manifest（版本号、commit SHA、门禁结果、覆盖率为证） |
| FR-003 | validate-manifest | CI 或运维检查 manifest | 验证 manifest 完整性、签名、内容一致性 |
| FR-004 | remote-evidence | 远程查询模块证据 | 返回结构化证据（覆盖率、门禁历史、manifest） |
| FR-005 | evidence-report | 聚合多模块证据 | 生成跨模块统一报告 |

## 8. Business Rules

| ID | 规则 |
|----|------|
| BR-001 | manifest 必须包含门禁全绿证据 |
| BR-002 | 覆盖率低于 80% 不得发布 |
| BR-003 | manifest 不可事后篡改（hash 链校验） |
| BR-004 | evidence 存储必须不可变追加 |

## 9. Interface Contract

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

## 10. Data Model

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

## 11. Config Schema

```yaml
xlib_evidence:
  storage_path: "./evidence/"
  manifest_path: "./manifest/"
  coverage_threshold: 80.0
  remote:
    enabled: false
    endpoint: ""
```

## 12. Error Handling

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrCoverageNotFound | 模块无覆盖率数据 | 先执行 go test -cover |
| ErrGateNotPassed | 门禁未全绿 | 修复后重试 |
| ErrManifestTampered | manifest hash 不匹配 | 重新生成或调查篡改 |

## 13. Edge Cases

- 覆盖率恰好 80.00%（边界值）
- manifest 文件被手动修改
- 多个 CI job 并发生成同一模块 manifest
- 远程 evidence endpoint 不可用时的降级

## 14. Directory Structure

```text
module/xlib-evidence/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. Dependencies

- 允许：kernel（time/errors）
- 禁止：observex、configx、resiliencx、schedulex
- 禁止：任何存储/网络后端（不连接 Redis/Postgres）
- 允许：读取文件系统上的覆盖率报告和门禁输出

## 16. Testing

- 单元测试：manifest 生成/验证独立可测
- 集成测试：collect → generate → validate 端到端
- Golden 测试：固定覆盖率输入 → 固定 manifest 输出

## 17. Performance Budget

| 指标 | 目标 |
|------|------|
| manifest 生成 | < 1s |
| 多模块报告聚合（20 模块） | < 5s |

## 18. Observability

- 无运行时指标（不参与业务运行）
- 证据报告格式：JSON

## 19. Security

- manifest hash 用于完整性校验
- 不读取密钥
- 不连接远程服务（remote evidence 为可选）

## 20. CI Gate

- `make test`
- `make vet`

## 21. Upgrade Compatibility

- manifest 格式 v1 保持稳定
- 新字段为追加，不删除旧字段

## 22. Release DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] collect → generate → validate 闭环
- [ ] 文档齐全

## 23. Open Questions

- remote evidence 是否需要签名？
- 证据存储是否需要支持 SQLite/文件双后端？
- manifest 是否应包含 reproducible build info？
