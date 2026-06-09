# Context Packet — TASK-XLIB-003

> PR-4: 核心包 — pkg/templatex、contracts、examples、testkit
> 工作分支: `feat/xlib-v1-packages`
> 工作目录: worktree/xlib-v1-packages/

## Current Task

TASK-XLIB-003: 核心包 — pkg/templatex、contracts、examples、testkit

## Related Spec

- module/xlib-standard/SPEC.md (§7 功能需求 FR-001~FR-008, §9 接口契约, §10 数据模型)

## Related Requirements

- FR-001: 定义基座库标准规范
- FR-002: 标准规范包含目录结构模板
- FR-003: 标准规范包含命名规则
- FR-004: 标准规范包含 go.mod 要求
- FR-005: 标准规范包含错误处理规范
- FR-006: 文档与示例管理
- FR-007: Go 参考模板可编译
- FR-008: 参考模板遵循全部标准规则
- AC-001~AC-017

## Current Scope

实现以下核心包：

1. **pkg/templatex/validator.go** — 校验函数集：
   - `ValidateModuleName(name string) error` — 校验模块名格式
   - `ValidateGoMod(mod *GoModInfo) error` — 校验 go.mod 规则
   - `ValidateDirectory(dir string, expected []string) error` — 校验目录结构
   - `ValidateErrorHandling(pkgDir string) error` — 校验错误处理规范
   - `ValidateContract(contractDir string) error` — 校验契约规范

2. **pkg/templatex/types.go** — 共享类型：
   - `GoModInfo` 结构体
   - `ValidationResult` 结构体

3. **pkg/templatex/validator_test.go** — 完整测试

4. **contracts/contracts.go** — 最小契约示例

5. **examples/main.go** — 最小可运行示例

6. **testkit/testkit.go** — 测试辅助工具

## Out of Scope

- 不实现生成器 CLI（`cmd/xlib-generate` 不在本 PR）
- 不实现 release manifest
- 不修改 CI 配置
- 不引入外部依赖（仅标准库）

## Validation Commands

```bash
# 编译通过
go build ./...

# 测试通过
go test ./... -race

# vet 通过
go vet ./...

# 示例可运行
cd examples && go run main.go
```

## Required Output

1. 文件变更清单
2. 需求覆盖表（FR-001~FR-008, AC-001~AC-017）
3. 测试覆盖报告
4. 验证结果

## Evidence Format

完成后提交 evidence 到 `.config/goal/evidence/` 目录，格式如下：

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-003-001
- **Status**: PASS
- **Files Changed**: <实际修改的文件列表>
- **Commands Run**: <实际执行的命令及输出>
```

## Project Rules

- Follow AGENTS.md
- 遵循 Go 惯用风格
- 错误处理使用 `fmt.Errorf` + `%w`
- 不引入外部依赖
- 每个导出函数/类型必须有注释
