# Context Packet: TASK-XLIB-003D

> PR-4d：API 模板 + examples + testkit

## 目标

实现公共 API 模板、examples/basic/main.go、testkit 辅助包，确保 go vet 零警告、go test 全通过。

## 上下文制品

- `module/xlib-standard/SPEC.md` — 完整规格，聚焦 §7（Public API Template）、§10（examples/testkit）
- `module/xlib-standard/goal.md` — 目标定义，聚焦 §10（辅助包）
- `module/xlib-standard/TRACEABILITY.md` — 追溯矩阵

## 允许修改的文件

- `examples/basic/main.go` — 唯一 example
- `testkit/metrics.go` — 测试辅助：NoopMetrics
- `testkit/assertions.go` — 测试辅助：断言函数

## 禁止事项

- 禁止引入新的第三方依赖
- 禁止修改 pkg/templatex/ 核心包
- 禁止添加 examples/ 或 testkit/ 下的其他文件
- 禁止引入 CGO

## 验收标准

- `AC-020`：`GOWORK=off go vet ./...` 零警告
- `AC-021`：`GOWORK=off go test ./...` 全部通过

## 验证命令

```bash
GOWORK=off go vet ./...
GOWORK=off go test ./...
GOWORK=off go test -race ./...
ls pkg/templatex/ | wc -l  # 应为 11
```

## 证据回填
```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-{NNN}-001
- **Status**: PASS
- **Files Changed**: <实际修改的文件列表>
- **Commands Run**: <实际执行的命令及输出>
```

完成后提交：
1. `go vet` 输出截图（零警告）
2. `go test ./...` 输出截图（全通过）
3. `ls pkg/templatex/` 输出（11 个文件）

## Test Case 引用

参见 `module/xlib-standard/TRACEABILITY.md` 中对应的 TC 编号。执行测试时确保所有 TC 通过。
