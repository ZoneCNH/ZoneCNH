# decimalx 完整实现功能清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-30
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [goal.md](./goal.md)
- Scale: 10 FR · 7 BR · 0 NFR

> 本文档是 decimalx **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR/NFR 展开成具体可验收的功能点。
> 它不是 Why（goal.md）、不是规格（SPEC.md）、不是追溯矩阵（TRACEABILITY.md）。
> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）

---

## 1. 功能需求（FR）

- [ ] **FR-DEC-001** `Decimal` 必须不可变，任何系数导出不得暴露内部可变状态。
- [ ] **FR-DEC-002** Parse 必须采用稳定语法，拒绝空白、指数和非规范格式。
- [ ] **FR-DEC-003** 字符串输出必须区分规范输出、固定精度输出与调试输出。
- [ ] **FR-DEC-004** 加减乘必须精确；除法、量化和舍入必须显式携带 rounding/context。
- [ ] **FR-DEC-005** JSON 表达必须是带引号十进制字符串，避免 JavaScript/JSON number 精度损失。
- [ ] **FR-DEC-006** SQL scan 必须拒绝 float 输入，防止静默精度损失。
- [ ] **FR-DEC-007** `Money` 的币种必须参与等价性与运算校验，跨币种加减必须失败。
- [ ] **FR-DEC-008** 公开错误必须可用 `errors.Is` 识别并保持兼容。
- [ ] **FR-DEC-009** money-currency
- [ ] **FR-DEC-010** error-identity

## 2. 业务规则（BR）

- [ ] **BR-DEC-001** `Decimal` 不可变——所有 arithmetic 返回新值，不修改 receiver
- [ ] **BR-DEC-002** `Parse` 默认使用 `DefaultLimits`，拒绝超出 precision/scale 上限的输入
- [ ] **BR-DEC-003** 非精确除法必须显式 rounding，零值 Context 不得静默截断
- [ ] **BR-DEC-004** JSON 序列化仅允许带引号十进制字符串，禁止 JSON number
- [ ] **BR-DEC-005** SQL `Scan(float64)` 必须失败——防止静默精度损失
- [ ] **BR-DEC-006** `Money` 跨币种运算必须失败——防止隐式汇率假设
- [ ] **BR-DEC-007** rounding mode 语义一旦冻结不可在 minor 版本内变更

## 3. 非功能需求（NFR）

> SPEC 中未抽取到 `NFR-` 编号；请人工对照 SPEC §11 非功能需求补全（如有）。

---

## 4. 完整实现判定

本清单 §1-§3 全部 `[x]` 勾选 + ACCEPTANCE.md 全部 TC 通过 + SPEC §19 验收门禁通过 + pipeline-arbiter 翻转 Approved。

## 5. 明确不做

参见 [SPEC.md](./SPEC.md) §4 非目标章节。decimalx 只承担 SPEC 范围内的能力，不做范围外业务语义/集成编排/跨模块横切。

