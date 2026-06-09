# Context Packet — TASK-XLIB-005

> 最终验收 — 生成库验证、100 次自检、tag
> 无独立分支，在全部 PR 合并后于 main 执行

## Current Task

TASK-XLIB-005: 最终验收 — 生成库验证、100 次自检、tag

## Related Spec

- module/xlib-standard/SPEC.md (§20 Release DoD, §19 CI Gate)

## Related Requirements

- FR-009: 生成器接受目标模块路径
- FR-010: 生成器输出可编译的 Go 基座库
- FR-012: 自动生成校验
- AC-021: 生成的库满足 spec-lint 通过
- AC-027: selfcheck-100.sh 运行 100 次无失败

## Current Scope

执行最终验收：

1. **生成库验证** — 用生成器创建测试库，验证：
   - `go build ./...` 通过
   - `go test ./... -race` 通过
   - `go vet ./...` 通过
   - 目录结构符合 standard.md
   - spec-lint 通过

2. **100 次自检** — 运行 `selfcheck-100.sh`：
   - 100 次 spec-lint + task-lint + trace-lint
   - 0 失败

3. **Tag** — 打 `v1.0.0` tag

## Out of Scope

- 不修改任何代码
- 不修改文档
- 只做验证和打 tag

## Validation Commands

```bash
# 生成器验证
go run ./cmd/xlib-generate --module-path test.example/xlib-demo --package-name xlibdemo --module-name xlib-demo --output /tmp/xlib-demo
cd /tmp/xlib-demo && go build ./... && go test ./... -race && go vet ./...
bash scripts/spec-lint.sh /tmp/xlib-demo

# 100 次自检
bash scripts/selfcheck-100.sh

# Tag
git tag v1.0.0
```

## Required Output

1. 生成库验证结果
2. 100 次自检结果
3. Tag 信息
4. 最终验收清单确认

## Project Rules

- Follow AGENTS.md
- 验证失败则不打 tag
- 所有验证必须在 main 分支上执行
