# Agent Rules: FoundationX

> AI 代理在 FoundationX 项目中工作时必须遵守的规则。

最后更新：2026-06-07
Status: Approved

---

## 1. 通用规则

- 遵循现有项目结构，不引入未经批准的目录变更
- 不引入新依赖，除非 spec 明确要求或用户明确批准
- 不修改无关文件
- 优先小增量变更，避免大规模重写
- 保留现有行为，除非明确要求改变

---

## 2. 开始编码前必须确认

1. **相关 spec**：找到对应的 `module/*/SPEC.md`
2. **受影响文件**：预判本次变更涉及哪些文件
3. **验收标准**：确认 spec 中的 Acceptance Criteria
4. **测试用例**：确认 spec 中的 Test Cases
5. **风险**：识别可能的破坏性变更

---

## 3. 编码规则

### 3.1 Go 代码风格

- 使用 Go 1.23+
- 遵循 `CONSTITUTION.md` 中的编码约定
- 函数 < 50 行，文件 < 800 行
- 不使用 `init()` 函数
- 不使用 `panic()`（除了测试）
- 错误必须显式处理，不静默吞掉
- 使用 `context.Context` 传播取消和超时

### 3.2 接口设计

- 接口由消费方定义（`contracts` 包）
- 接口尽量小（1-5 个方法）
- 实现方不暴露内部类型
- 使用 `Option` 模式配置，不暴露构造函数细节

### 3.3 错误处理

- 公共错误变量定义在 `errors.go`
- 错误消息格式：`"package: operation: detail"`
- 使用 `%w` 保留错误链
- 不在库中使用 `log.Fatal` 或 `os.Exit`

### 3.4 不可变性

- 优先返回新对象，不修改输入参数
- 配置值读取后不修改
- 并发共享数据使用 `sync.RWMutex` 或 `atomic`

---

## 4. 测试规则

每个行为变更必须：

- 添加或更新测试
- 运行现有测试确认不破坏
- 说明覆盖了哪些 requirements
- 说明哪些场景未覆盖

测试格式：

- 使用 Given/When/Then 注释
- 测试名包含 TC 编号
- 使用 `testdata/` 存放测试数据
- 不在测试中硬编码敏感数据

---

## 5. 安全规则

- 不硬编码 secret、API key、密码
- 不在日志中记录敏感数据
- 不在错误消息中泄露配置细节
- 用户输入必须校验
- 不使用 `unsafe` 包（除非有充分理由并记录）

---

## 6. Spec 遵循规则

- 严格按照 spec 的 Section 7（Functional Requirements）实现
- 遵循 spec 的 Section 8（Business Rules）
- 处理 spec 的 Section 12（Error Handling）中列出的所有错误
- 覆盖 spec 的 Section 13（Edge Cases）
- 满足 spec 的 Section 16（Testing）中的所有测试要求
- 符合 spec 的 Section 17（Performance Budget）

---

## 7. 输出规则

每次变更完成后，必须输出：

1. **修改文件清单**：列出所有新增/修改/删除的文件
2. **变更说明**：每个文件改了什么、为什么改
3. **覆盖的 requirements**：对应 spec 中的 FR/BR 编号
4. **测试说明**：新增/更新了哪些测试，如何运行
5. **验证方法**：如何验证变更正确
6. **风险**：可能的破坏性影响

---

## 8. 禁止事项

| 禁止 | 原因 |
|------|------|
| 引入未经批准的依赖 | 违反 spec 的依赖约束 |
| 修改 `CONSTITUTION.md` 未经审批 | 宪法变更需要人工审批 |
| 在库中使用 `log.Fatal` | 库不应决定进程退出 |
| 静默吞掉错误 | 违反错误处理原则 |
| 在非测试代码中使用 `panic` | 违反错误处理原则 |
| 硬编码配置值 | 违反配置管理原则 |
| 修改无关文件 | 保持变更范围最小 |
| 跳过测试 | 测试是验收的唯一证据 |

---

## 9. Module 实现顺序

当实现新模块时，遵循以下顺序：

1. 阅读 `module/<module>/SPEC.md` 全文
2. 创建 `go.mod` 和目录结构（spec Section 14）
3. 定义接口（spec Section 9）
4. 定义错误变量（spec Section 10）
5. 实现核心逻辑
6. 添加单元测试（spec Section 16）
7. 添加 benchmark（spec Section 17）
8. 运行 CI Gate（spec Section 20）
9. 自查验收标准（spec Section 22）
10. 输出变更报告（本文 Section 7）

---

## 10. 变更分类

| 变更类型 | 审批要求 | 测试要求 |
|----------|----------|----------|
| 新增模块 | 人工审批 | 完整测试套件 |
| 修改公共接口 | 人工审批 | 更新所有调用方测试 |
| 修改内部实现 | AI 自查 | 更新相关测试 |
| 修复 bug | AI 自行修复 | 添加回归测试 |
| 更新文档 | AI 自行更新 | 无需测试 |
| 修改 CONSTITUTION.md | **必须人工审批** | N/A |
