# ossx Traceability Matrix

Last-Updated: 2026-06-19
Source: [module/ossx/SPEC.md](./SPEC.md) v1.2.1
Scope: Local Production Candidate readiness for `/home/ossx` branch `ossx`

> 本矩阵把 v1.2.1 的 `FR/BR -> AC -> TC -> Evidence -> Status` 收敛到当前实现事实。`Complete Locally` 表示本地代码和门禁已闭合；`Blocked External` 表示生产放行所需外部 artifact 尚未归档。

## 1. FR -> AC -> TC

| FR | Requirement | AC | TC | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | 构造入口与配置校验 | AC-OSS-001 | TC-001 | `NewBlobStore` 返回 `*Store`；adapter capability guard；nil hooks 测试 | Complete Locally |
| FR-002 | Key/metadata/checksum 模型 | AC-OSS-002 | TC-002 | validators、checksum verifier、metadata 分支覆盖 | Complete Locally |
| FR-003 | Core object ops | AC-OSS-003 | TC-003/004/005 | Put/Get/Delete/Copy/Head/Exists/List 测试 | Complete Locally |
| FR-004 | Streaming | AC-OSS-004 | TC-003 | `io.Reader` / `io.ReadCloser` adapter SPI | Complete Locally |
| FR-005 | Multipart | AC-OSS-005 | TC-006 | initiate/upload/list/complete/abort 测试 | Complete Locally |
| FR-006 | Presign | AC-OSS-006 | TC-007 | TTL、operation allowlist、audit masking 测试 | Complete Locally |
| FR-007 | Policy | AC-OSS-007 | TC-008 | lifecycle/retention/permission enforcement 测试 | Complete Locally |
| FR-008 | Aliyun adapter isolation | AC-OSS-008 | TC-009/010 | provider SDK 限定 `adapters/aliyun`；error translation；live artifact 待归档 | Partial |
| FR-009 | Observability | AC-OSS-009 | TC-007/011 | hooks no-op、metrics/log label sanitization | Complete Locally |
| FR-010 | Health/Close lifecycle | AC-OSS-010 | TC-012 | health 状态、close 幂等、atomic race 覆盖 | Complete Locally |
| FR-011 | Public interface governance | AC-OSS-011 | TC-013 | `BlobStore` 7 methods；capability interfaces split；reflection regression test | Complete Locally |

## 2. Boundary Requirements

| BR | Boundary | Evidence | Status |
| --- | --- | --- | --- |
| BR-001 | 不直接依赖 `configx` | dependency isolation scan | Complete Locally |
| BR-002 | 不依赖业务基础设施模块 | dependency isolation scan | Complete Locally |
| BR-003 | Provider SDK 不穿透 public API | `pkg/ossx` API 与 dependency scan | Complete Locally |
| BR-004 | Adapter provider error translation | adapter tests and typed error coverage | Complete Locally |
| BR-005 | List bounded pagination | List tests | Complete Locally |
| BR-006 | Multipart part validation | Multipart tests | Complete Locally |
| BR-007 | Presigned URL 不进入日志/label | audit masking tests | Complete Locally |
| BR-008 | Strict delete missing object visible | store + Aliyun strict delete tests | Complete Locally |
| BR-009 | Close 后操作返回 closed typed error | close tests and race test | Complete Locally |
| BR-010 | 公共接口方法数治理 | interface-size regression test | Complete Locally |
| BR-011 | 外部生产证据归档 | release/live/downstream/soak artifacts | Blocked External |

## 3. NFR / Quality Gates

| NFR | Gate | Evidence | Status |
| --- | --- | --- | --- |
| NFR-001 | Release-tag CI | GitHub Actions `v1.2.1` artifact | Blocked External |
| NFR-002 | Gitleaks | CI secret-scan artifact | Blocked External |
| NFR-003 | xlibgate boundary | CI boundary artifact | Blocked External |
| NFR-004 | Live Aliyun integration | Credentialed integration artifact | Blocked External |
| NFR-005 | Coverage | `pkg/ossx` total 100.0% | Complete Locally |
| NFR-006 | Race | `GOWORK=off go test -race ./... -count=1` | Complete Locally |
| NFR-007 | Vet | `GOWORK=off go vet ./...` | Complete Locally |
| NFR-008 | Build | `GOWORK=off go build ./...` | Complete Locally |
| NFR-009 | Lint | `golangci-lint run --allow-parallel-runners ./...` | Complete Locally when tool installed |
| NFR-010 | Secret scope | `scripts/secret-scope-check.sh` | Complete Locally |
| NFR-011 | Dependency isolation | `go list -deps` denylist scan | Complete Locally |
| NFR-012 | Downstream adoption | Downstream PR/commit + regression evidence | Blocked External |
| NFR-013 | Production soak | Soak/failure-profile artifact | Blocked External |
| NFR-014 | Four-source scorer | Claude/Codex/Copilot/rules + arbiter >=98 | Blocked External |

## 4. Production Readiness Closure

| Question | Answer |
| --- | --- |
| Can the module be used in local/pre-release integration? | Yes, as a controlled local production candidate |
| Can it be declared production released? | No |
| Primary reason | External artifacts are missing, not core local implementation gaps |
| Next best work | Archive release-tag CI, Gitleaks/xlibgate, live Aliyun integration, downstream adoption, soak, and arbiter evidence |

## 5. Change History

| Date | Version | Change |
| --- | --- | --- |
| 2026-06-19 | 3.3 | Reconciled matrix to SPEC v1.2.1 local production candidate; marked API governance complete locally and external production evidence blocked |
| 2026-06-19 | 3.2 | v1.2.0 local release-hardening evidence |
| 2026-06-18 | 3.1 | Aliyun-only identity convergence |
