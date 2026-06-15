# xlib-harness 规格

- Status: Review
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-14
- Layer: 基座 · 模块生成器与门禁执行器
- Module-Version: v0.1.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `xlib-standard`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

xlib-harness 是 Foundation 模块的**生成器与门禁执行器**——从标准模板生成新模块骨架，并对已有模块执行机器化合规检查。

## 2. 问题与背景

xlib-standard 同时承载声明式标准定义（Standard Source / Go Reference Template）和主动执行工具（Generator / Harness Gate），导致 52 FR 和 25+ 个文件耦合在一个模块中。Generator 和 Harness 是执行工具而非标准定义，应独立为可演进、可独立测试的模块。

## 3. 目标

- 提供 `xlib-harness generate <module>` 从标准模板生成新模块骨架
- 提供 `xlib-harness check <module>` 对已有模块执行合规门禁
- 与 xlibgate（CI 管线门禁）互补：xlibgate 检查编译/依赖/发布，xlib-harness 检查规格结构/模板/格式
- 读取 xlib-standard 的模板和 schema 作为输入

## 4. 非目标

- 不定义标准（那是 xlib-standard）
- 不收集/存储证据（那是 xlib-evidence）
- 不执行 CI 管线流程（那是 xlibgate）
- 不参与生产运行时

## 5. 消费者

- 模块开发者：生成新模块骨架
- CI 管线：门禁检查
- xlib-standard：被读取，不作为运行时依赖

## 6. 功能需求

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-001 | generate-module | 用户执行 `generate <module>` | 从 xlib-standard 模板生成完整模块骨架（SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPLEMENTATION-PLAN.md） |
| FR-002 | spec-lint | 对模块执行 spec lint | 检查 23 节结构完整性、FR WHEN/THEN 格式、AC 可验证性 |
| FR-003 | boundary-check | 对模块执行边界检查 | 验证允许/禁止依赖、production-import-testkitx 禁止、stdlib-only gate |
| FR-004 | template-validate | 对模板执行 validate | 验证 xlib-standard 模板自举——模板自身符合模板定义 |
| FR-005 | format-check | 对文档执行格式检查 | 检查 Markdown 结构、链接有效性、表格对齐 |
| FR-006 | traceability-gate | 对 TRACEABILITY.md 执行闭合检查 | FR → AC → TC 链路全闭合 |

## 7. 行为约束

| ID | 规则 |
|----|------|
| BR-001 | generate 必须在 5 秒内完成骨架生成 |
| BR-002 | check 不得修改被检模块的任何文件 |
| BR-003 | check 失败退出码必须非零 |


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-001 | FR-001 | TC-001 | `xlib-harness generate test-module && ls module/test-module/` | ✅ | |
| AC-002 | FR-002 | TC-002 | `xlib-harness check  --profile spec` | ✅ | |
| AC-003 | FR-003 | TC-003 | `xlib-harness check  --profile boundary` | ✅ | |
| AC-004 | FR-004 | TC-004 | `xlib-harness validate --template` | ✅ | |
| AC-005 | FR-005 | TC-005 | `xlib-harness check  --profile spec` | ✅ | |
| AC-006 | FR-006 | TC-006 | `xlib-harness check  --profile full` | ✅ | |

## 8. 接口契约

```go
type Generator interface {
    Generate(module string, opts ...GenerateOption) (*GenerateResult, error)
}

type HarnessGate interface {
    Check(module string, profile GateProfile) (*CheckResult, error)
}

type GateProfile string

const (
    ProfileFull     GateProfile = "full"
    ProfileSpec     GateProfile = "spec"
    ProfileBoundary GateProfile = "boundary"
)
```

## 9. 数据模型

```go
type GenerateResult struct {
    FilesCreated []string
    Warnings     []string
}

type CheckResult struct {
    Module  string
    Passed  bool
    Checks  []CheckItem
    Summary string
}

type CheckItem struct {
    Name    string
    Passed  bool
    Detail  string
}
```

## 10. 配置模式

```yaml
xlib_harness:
  template_source: "../xlib-standard/templates/"
  profiles:
    full:
      - spec-lint
      - boundary-check
      - format-check
      - traceability-gate
    spec:
      - spec-lint
      - format-check
    boundary:
      - boundary-check
```

## 11. 错误处理

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrModuleExists | 目标模块已存在 | 使用 --force 覆盖或选择不同名称 |
| ErrTemplateNotFound | xlib-standard 模板路径无效 | 检查 template_source 配置 |
| ErrCheckFailed | 门禁检查未通过 | 查看 CheckResult.Checks 逐项修复 |

## 12. 边界情况

- 模块名包含特殊字符（路径遍历攻击）
- xlib-standard 模板目录不存在
- 生成时目标目录已存在部分文件
- 门禁检查超大 TRACEABILITY 文件

## 13. 目录结构

```text
module/xlib-harness/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 14. 依赖

- 允许：xlib-standard（只读模板文件，非 import 依赖）
- 禁止：observex、configx、resiliencx、schedulex
- 禁止：业务域任何模块

## 15. 测试

- 单元测试：每个 check 独立可测
- 集成测试：generate → check 端到端（生成后立即检查）
- 基准测试：generate 性能 < 5s

### 15.1 Traceability Test Cases

**TC-001:** 空目录执行 generate 后文件齐全。
**TC-002:** 合规模块通过；不合规模块逐项报告。
**TC-003:** 违规依赖被检出。
**TC-004:** 模板自举验证通过。
**TC-005:** 格式问题逐项输出。
**TC-006:** 断开 FR → AC → TC 链路被检出并报告缺口。

## 16. 性能预算

| 指标 | 目标 |
|------|------|
| generate 延迟 | < 5s |
| check 延迟（单模块） | < 10s |

## 17. 可观测性

- 无运行时指标（不参与业务运行）
- 门禁结果输出为结构化 JSON

## 18. 安全

- 不读取密钥
- generate 写入路径必须限制在 module/ 下
- 不执行远程代码

## 19. CI 门禁

- `make test`
- `make vet`
- `make boundary`

## 20. 升级兼容性

- v1 门禁 profile 名称保持稳定
- check 输出格式向后兼容

## 21. 发布 DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] generate → check 自举闭环
- [ ] 文档齐全

## 22. 待解决问题

- generate 应支持哪些模板变体（仅 SPEC / 完整骨架）？
- check 是否应集成到 xlibgate 的统一入口？
- 门禁 profile 是否应允许用户自定义组合？

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-14 | v1.0.0 | 初始版本，从 xlib-standard 拆分 | ZoneCNH |
