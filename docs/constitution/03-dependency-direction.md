> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](02-module-boundaries.md) · [↑ 目录](README.md) · [下一节 →](04-interface-contracts.md)

---

## 第三条：依赖方向

### 3.1 依赖拓扑（不可违反）

```text
x.go ──→ 基座运行时 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域

数据域 ─┐
分析域 ─┼──→ L2.5 Domain Shared
决策域 ─┤
执行域 ─┘
   │
   ├──→ contracts
   │
   └──→ 基座运行时 Foundation
         L0: kernel
         L1: configx · observex · resiliencx · schedulex
         L1 test-only: testkitx
         扩展: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex
```text

### 3.2 依赖规则

| 规则     | 说明                                |
| -------- | ----------------------------------- |
| 单向下行 | 依赖只能沿箭头方向，不可反向        |
| 同层平级 | 同域同层模块之间不存在编译期依赖    |
| 可选引入 | L1 运行时和存储扩展按需引入，非强制 |
| 禁止循环 | 任何两个模块之间不允许循环依赖      |

### 3.3 基座内部层级

| 层级          | 模块                                                       | 可以依赖                          |
| ------------- | ---------------------------------------------------------- | --------------------------------- |
| L0            | kernel                                                     | stdlib only                       |
| L1            | configx, observex, resiliencx, schedulex                   | kernel                            |
| L1 test-only  | testkitx                                                   | kernel, observex (interface-only) |
| 标准源 / 门禁 | xlib_standard, xlibgate                                    | 无运行时依赖                      |
| 存储扩展      | redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex | kernel, observex (interface-only) |
| 契约          | contracts                                                  | L2.5 领域共享层                   |

### 3.4 禁止依赖矩阵

| 模块类型      | 禁止依赖                                                  |
| ------------- | --------------------------------------------------------- |
| L0 (kernel)   | 任何非 stdlib 包                                          |
| L1 运行时     | 其他 L1 模块、业务域、存储扩展                            |
| 存储扩展      | configx、业务域、其他存储扩展（存储间不得互依）           |
| 契约          | L1 运行时、业务域实现（contracts 只定义接口，不依赖实现） |
| 标准源 / 门禁 | 所有运行时模块（仅扫描，不 import）                       |

---
