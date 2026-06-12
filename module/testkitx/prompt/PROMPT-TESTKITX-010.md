# PROMPT-TESTKITX-010

> 文档 + Release DoD

```yaml
prompt_id: PROMPT-TESTKITX-010
task_ref: TASK-TESTKITX-010
spec_ref:
  - "module/testkitx/SPEC.md#22 (Release DoD)"
  - "module/testkitx/SPEC.md#2 (Summary)"
  - "module/testkitx/SPEC.md#16 (Testing)"
  - "module/testkitx/SPEC.md#20 (CI Gate)"
  - "module/testkitx/TRACEABILITY.md#NFR-002 (覆盖率 >= 80%)"
  - "module/testkitx/TRACEABILITY.md#NFR-003 (race 测试通过)"
  - "module/testkitx/TRACEABILITY.md#NFR-004 (不进入生产二进制)"
  - "module/testkitx/TRACEABILITY.md#NFR-005 (golden 文件不泄露 secret)"
task_files:
  - "README.md"
  - "CHANGELOG.md"
  - "example_test.go"
depends_on:
  - "TASK-TESTKITX-001"
  - "TASK-TESTKITX-002"
  - "TASK-TESTKITX-003"
  - "TASK-TESTKITX-004"
  - "TASK-TESTKITX-005"
  - "TASK-TESTKITX-006"
  - "TASK-TESTKITX-007"
  - "TASK-TESTKITX-008"
  - "TASK-TESTKITX-009"
```

---

## 任务

创建 README.md、CHANGELOG.md、example_test.go，并验证全部 Release DoD 条目（SPEC.md §22）。确保所有 Functional Requirements 有对应测试、所有 Edge Cases 有对应测试、覆盖率 >= 80%。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| § | 22 | SPEC.md | Release DoD 全部 16 项 |
| § | 2 | SPEC.md | Summary 模块定位 |
| NFR | NFR-002 | TRACEABILITY.md §3 | 单元测试覆盖率 >= 80% |
| NFR | NFR-003 | TRACEABILITY.md §3 | -race 测试通过 |
| NFR | NFR-004 | TRACEABILITY.md §3 | 不进入生产二进制 |
| NFR | NFR-005 | TRACEABILITY.md §3 | golden 文件不泄露 secret |

## 文件清单

### 1. `README.md`

内容结构：
- **模块定位**：Foundation L1 test-only 工具包，提供 fake/fixture/golden/contract/boundary 工具
- **功能概览**：
  - 6 个 fake：FakeConfig / FakeLogger / FakeMeter / FakeTracer / FakeClock / FakeBreaker
  - 4 个辅助工具：Eventually / GoldenUpdate / BoundaryCheck / GoroutineLeakCheck
- **快速开始**：
  ```go
  import "github.com/ZoneCNH/testkitx"
  ```
- **API 概览表**：列出所有公共函数和类型
- **CI Gate 说明**：build/test/cover/lint/vet/contract-test/no-prod-import
- **许可证**：MIT

### 2. `CHANGELOG.md`

```markdown
# Changelog

## [v1.0.0] - 2026-06-12

### Added
- 6 个 fake 实现：FakeConfig, FakeLogger, FakeMeter, FakeTracer, FakeClock, FakeBreaker
- 4 个辅助工具：Eventually, GoldenUpdate, BoundaryCheck, GoroutineLeakCheck
- contract 测试 harness
- 编译期接口检查
- goroutine 泄漏检测
```

### 3. `example_test.go`

| 示例 | 说明 |
|------|------|
| `Example_fakeConfig` | 演示 FakeConfig 注入配置并读取 |
| `Example_fakeLogger` | 演示 FakeLogger 记录和 AssertNoErrors |
| `Example_fakeMeter` | 演示 FakeMeter 计数器和断言 |
| `Example_fakeTracer` | 演示 FakeTracer span 记录和 AssertSpanCount |
| `Example_fakeClock` | 演示 FakeClock 时间控制 |
| `Example_eventually` | 演示 Eventually 轮询 |
| `Example_goldenUpdate` | 演示 golden file 测试 |
| `Example_goroutineLeakCheck` | 演示 goroutine 泄漏检测 |

### 4. Release DoD 验证清单

逐条验证 SPEC.md §22 的 16 项 DoD：

1. 所有公共接口有 godoc 注释
2. 所有公共类型有示例代码（example_test.go）
3. CHANGELOG.md 已更新
4. README.md 包含：模块定位、快速开始、API 概览
5. 单元测试覆盖率 >= 80%
6. `-race` 测试通过
7. Benchmark 结果无 > 10% 回退
8. `go vet` 无警告
9. `golangci-lint` 无错误
10. 所有 contract test 通过
11. no-production-import 检查通过
12. Go baseline 1.23
13. Secret 扫描通过
14. 公共 API 无破坏性变更
15. 所有 Functional Requirements 有对应测试
16. 所有 Edge Cases 有对应测试

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-DOC-01 | §22 | `cat README.md` | 含模块定位、快速开始、API 概览 |
| AC-DOC-02 | §22 | `cat CHANGELOG.md` | v1.0.0 条目完整 |
| AC-DOC-03 | §22 | `go test ./example_test.go -run Example -v` | 所有示例通过 |
| AC-DOC-04 | NFR-002 | `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 >= 80% |
| AC-DOC-05 | NFR-003 | `go test ./... -race -count=1` | 无 data race |
| AC-DOC-06 | NFR-004 | `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \| grep testkitx` | 无输出 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test ./... -race -count=1` | 全部通过，无 data race |
| `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 >= 80% |
| `go test -bench=. -benchmem -count=3 ./...` | benchmark 通过 |
| `go vet ./...` | 无警告 |
| `golangci-lint run` | 无错误 |
| `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 整洁 |
| `gitleaks detect --no-git` | 无 secret 泄露 |
| `go test ./contract/... -race -count=1` | 全部 contract test 通过 |

## 禁止事项

- 不要遗漏任何 Release DoD 条目
- 不要在 README 中包含未实现的功能
- 不要在 example_test.go 中使用真实的外部依赖
- 不要跳过覆盖率检查
- 不要在 CHANGELOG 中不写初始版本条目

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go tool cover -func=.coverage/cover.out` 覆盖率报告
3. `go vet ./...` 输出
4. `golangci-lint run` 输出
5. `gitleaks detect --no-git` 输出
6. `go test ./contract/... -race -count=1` 输出
7. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-010 状态为 completed
4. 全模块 testkitx prompt 阶段完成
