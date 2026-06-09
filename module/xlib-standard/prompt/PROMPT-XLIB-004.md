# Context Packet — TASK-XLIB-004

> PR-5: release 标准 — release manifest、semver 兼容矩阵
> 工作分支: `feat/xlib-v1-release`
> 工作目录: worktree/xlib-v1-release/

## Current Task

TASK-XLIB-004: release 标准 — release manifest、semver 兼容矩阵

## Related Spec

- module/xlib-standard/SPEC.md (§7 FR-013~FR-014, §20 Release DoD, §21 Upgrade Compatibility)

## Related Requirements

- FR-013: 发布制品与版本管理
- FR-014: 版本兼容性矩阵
- AC-025: release 目录仅含 manifest 和兼容性矩阵

## Current Scope

实现以下发布标准：

1. **pkg/templatex/release.go** — Release manifest 生成：
   - `GenerateManifest(cfg ManifestConfig) (*ReleaseManifest, error)`
   - 输出 JSON 格式的 release manifest
   - 包含模块名、版本、Go 版本、依赖列表、校验和

2. **pkg/templatex/compat.go** — Semver 兼容性矩阵：
   - `CompatibilityMatrix` 结构体
   - Go 版本与模块版本的兼容性映射
   - 向前兼容规则定义

3. **pkg/templatex/release_test.go** — 测试

4. **pkg/templatex/compat_test.go** — 测试

## Out of Scope

- 不实现生成器 CLI
- 不修改 CI 配置
- 不修改文档
- 不引入外部依赖

## Validation Commands

```bash
# 编译通过
go build ./...

# 测试通过
go test ./... -race

# manifest 生成可验证
go run -run TestGenerateManifest
```

## Required Output

1. 文件变更清单
2. 需求覆盖表（FR-013, FR-014, AC-025）
3. 测试覆盖报告
4. 验证结果

## Project Rules

- Follow AGENTS.md
- JSON 输出使用 `encoding/json`
- 版本遵循 semver 2.0.0
- 不引入外部依赖
