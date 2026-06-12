# Definition of Done

> 一个模块实现完成的验收条件。

最后更新：2026-06-07

---

## 检查清单

一个模块实现完成，必须满足以下所有条件：

### 功能完整性

- [ ] 所有 Functional Requirements 已实现
- [ ] 所有 Business Rules 已遵循
- [ ] 所有 Error Handling 已实现
- [ ] 所有 Edge Cases 已处理

### 测试

- [ ] 所有 Test Cases 已通过
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果符合 Performance Budget
- [ ] 集成测试通过（如有）

### 代码质量

- [ ] `go build ./...` 通过
- [ ] `go vet ./...` 无警告
- [ ] `golangci-lint run` 无错误
- [ ] `go mod tidy` 无变更
- [ ] 无硬编码 secret
- [ ] 无 `log.Fatal` / `os.Exit`（非 main 包）
- [ ] 无 `panic`（非测试代码）
- [ ] 错误消息格式正确：`"package: operation: detail"`

### 文档

- [ ] 公共接口有 godoc 注释
- [ ] README.md 已更新（如有需要）
- [ ] CHANGELOG.md 已更新

### 安全

- [ ] 无硬编码凭证
- [ ] 敏感数据不写日志
- [ ] 用户输入已校验
- [ ] Secret 扫描通过

### 追溯

- [ ] 每个实现的 FR 有对应的测试
- [ ] 每个 AC 有验证证据
- [ ] AI 输出了变更报告（修改文件清单、覆盖的 requirements、测试说明）

---

## 验收流程

```text
AI 实现模块
  ↓
AI 运行自查（docs/ai/prompt-templates.md §4）
  ↓
AI 修复 Required fixes
  ↓
AI 运行 CI Gate（docs/ai/prompt-templates.md §6）
  ↓
AI 输出变更报告
  ↓
人类 Review diff
  ↓
人类确认 Definition of Done 全部满足
  ↓
Merge
  ↓
更新 spec 状态为 Implemented
```text

---

## 例外

| 变更类型   | DoD 调整                            |
| ---------- | ----------------------------------- |
| Bug 修复   | 只需：修复 + 回归测试 + 测试通过    |
| 文档更新   | 只需：内容准确 + 无拼写错误         |
| 重构       | 只需：现有测试全部通过 + 无行为变更 |
| 配置调整   | 只需：配置生效 + 相关测试通过       |
