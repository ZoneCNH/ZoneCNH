# TASK-TESTKITX-010 开发 Prompt

> 文档 + Release DoD 验证
>
> 上游 Task：[TASK-TESTKITX-010.md](../tasks/TASK-TESTKITX-010.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §22

---

## 任务

创建 README.md、CHANGELOG.md、example_test.go，验证全部 Release DoD 条目。确保所有 Functional Requirements 有对应测试、所有 Edge Cases 有对应测试。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| § | 22 | SPEC.md | Release DoD 全部条目 |
| NFR | NFR-002 | TRACEABILITY.md §3 | 单元测试覆盖率 >= 80% |
| NFR | NFR-003 | TRACEABILITY.md §3 | -race 测试通过 |
| NFR | NFR-004 | TRACEABILITY.md §3 | 不进入生产二进制 |
| NFR | NFR-005 | TRACEABILITY.md §3 | golden 文件不泄露 secret |

## 文件清单

### 1. `README.md`

内容结构：
- 模块定位：Foundation L1 test-only 工具包
- 功能概览：FakeConfig / FakeLogger / FakeMeter / FakeTracer / FakeClock / FakeBreaker
- 辅助工具：Eventually / GoldenUpdate / BoundaryCheck / GoroutineLeakCheck
- 快速开始示例
- API 概览表
- CI Gate 说明

### 2. `CHANGELOG.md`

- v1.0.0 条目：初始版本，6 个 fake + 4 个辅助工具 + contract tests

### 3. `example_test.go`

- `Example_fakeConfig`：演示 FakeConfig 注入配置
- `Example_fakeLogger`：演示 FakeLogger 记录和断言
- `Example_eventually`：演示 Eventually 轮询
- `Example_goldenUpdate`：演示 golden file 测试

### 4. Release DoD 验证

逐条验证 SPEC.md §22 的 Release DoD 清单：
- 覆盖率 >= 80%
- -race 测试通过
- go vet 无警告
- golangci-lint 无错误
- 所有 contract test 通过
- no-production-import 检查通过
- Secret 扫描通过

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-010-01 | §22 | `cat README.md` | 含模块定位、快速开始、API 概览 |
| AC-010-02 | §22 | `cat CHANGELOG.md` | v1.0.0 条目完整 |
| AC-010-03 | NFR-002 | `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 >= 80% |
| AC-010-04 | NFR-003 | `go test ./... -race -count=1` | 无 data race |
| AC-010-05 | NFR-004 | `go list -deps ... \| grep testkitx` | 生产包不含 testkitx |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test ./... -race -count=1` | 全部测试通过，无 data race |
| `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 >= 80% |
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

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-010/`：

1. `go test ./... -race -count=1` 输出
2. 覆盖率报告（`go tool cover -func=.coverage/cover.out`）
3. `go vet ./...` 输出
4. `golangci-lint run` 输出
5. `gitleaks detect --no-git` 输出
6. `go test ./contract/... -race -count=1` 输出
7. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-010 状态为 completed
4. 全模块实现完成
