# ossx Implementation Plan

## Objective

Close the ossx documentation and implementation handoff chain so Goal -> Spec -> Matrix -> Tasks -> Prompts -> Evidence is explicit, dependency-safe, and identity-converged on the Aliyun OSS adapter.

## Constraints

- Scope is `module/ossx`.
- ossx is the Aliyun OSS adapter (single provider); no adapter SPI or S3-compatible / multi-provider abstraction.
- ossx must not directly depend on `configx`.
- ossx may depend on `kernel` and observex interface contracts only.
- Other storage extensions and unrelated worktrees are out of scope.

## Slices

1. `TASK-OSSX-000` — module skeleton and dependency guard.
2. `TASK-OSSX-001` — object identity, metadata, checksum, lifecycle policy model.
3. `TASK-OSSX-002` — BlobStore basic and streaming operations.
4. `TASK-OSSX-003` — multipart lifecycle.
5. `TASK-OSSX-004` — presigned URL policy and audit masking.
6. `TASK-OSSX-005` — Aliyun OSS adapter boundary (SDK isolation behind typed contracts).
7. `TASK-OSSX-006` — observability, health, release evidence, and examples.

## Validation Strategy

- Structural docs: `bash .github/ci/spec-lint.sh`.
- Traceability: `TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh`.
- Task metadata: `bash .github/ci/task-spec-validate.sh`.
- Dependency guard after implementation: `go list -deps ./module/ossx/... | grep -v configx` plus dedicated import tests.
- Unit and contract tests per task once implementation code exists.

## Handoff Notes

Implement tasks in numeric order unless the Aliyun adapter task (TASK-OSSX-005) is split into a separate branch. Preserve public API names only after contract tests are added; before then, update this plan and traceability if naming changes.

## Risks and Rollback

| 风险 | 级别 | 缓解 | 回滚 |
|------|------|------|------|
| API 破坏性变更 | LOW | 当前为首次实现（远程仓库 0 pkg 源码），尚无下游消费者 | `git revert` |
| 外部依赖不可用（Aliyun OSS） | MEDIUM | 健康检查 + 降级策略；测试用 fake adapter | 回退到上一稳定版本 |
| 配置兼容性回归 | LOW | canonical + legacy 测试覆盖 | 回退配置变更 |

> 注：远程仓库 `github.com/ZoneCNH/ossx` 当前 0 pkg 源码（BLK-010 open），本计划描述的是首次实现，不存在"已有可工作实现"。

## Phased Rollout

1. Phase 1: Foundation — 实现核心 BlobStore 接口与 Aliyun OSS adapter 骨架（TASK-OSSX-000/001/002/005）。
2. Phase 2: Features — 分片上传、预签名 URL、策略校验（TASK-OSSX-003/004）。
3. Phase 3: Quality — 可观测性、健康检查、CI gates + benchmark + docs（TASK-OSSX-006）。
