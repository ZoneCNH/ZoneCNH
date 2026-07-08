# FRED 模块需求层深度分析报告

**分析人**：ZoneCNH 治理体系专家  
**分析时间**：2026-07-08  
**制品版本**：SPEC v1.1.0 / FEATURES v1.1.0 / Goal v1.0 (Draft)

---

## 执行摘要

FRED 模块需求层制品整体质量处于较高水准，23 节主规格结构完整（实际含第 24 节变更摘要，超标准一节），FR-001..FR-016 覆盖面广，TC 均有具体 Go 命令，链路可追溯。但存在**五项核心问题**：

1. Goal 层 Status 仍为 `Draft`，与 SPEC `Implemented` 状态不对称
2. FR-C007 / FR-C008 在 client/SPEC 中无对应 AC，产生"孤儿 FR"
3. SERIES-API.md 引用的 TC-011 / V-017 在 ACCEPTANCE.md 中缺失
4. 非功能需求（性能、安全）缺少生产级量化指标
5. OPEN-CAT-1 别名不一致（`VXVCLS` vs `VIXCLS`）在核心文档间尚未统一

---

## Goal 层分析

### 目标陈述质量

| 维度 | 评价 | 证据 |
|---|---|---|
| 目标明确性 | ✅ 清晰 | `goal.md` 目标陈述一句话表达了 C/S 服务、领域共享层、持久化、事件发布、no-lookahead 五大能力 |
| 可量化性 | ⚠️ 弱 | G-SC-001~006 均为功能性标准，无性能阈值、无交付里程碑 |
| 可验证性 | ✅ 可对应到 SPEC AC | G-SC-003/G-SC-004/G-SC-006 均能在主 SPEC AC-003~010 中找到映射 |
| 业务与技术对齐 | ✅ 对齐 | G-BD-001~004 边界原则与 SPEC BR-001~010 高度一致 |

### 关键缺陷

**P0 - Goal Status 与 SPEC Status 不对称**

```
goal.md：Status: Draft          ← 未更新
SPEC.md：Status: Implemented    ← 已实现
```

**P1 - 无 OKR/KPI 量化指标**

6 条成功标准（G-SC-001~006）全部是定性描述，无覆盖率阈值、无性能门槛。

---

## Spec 完整性评估

### 23 节标准覆盖情况

| 节号 | 节名 | 状态 | 备注 |
|---|---|---|---|
| §1 | 摘要 | ✅ 完整 | 双服务架构说明清晰 |
| §2 | 目标 | ✅ 完整 | 5 条技术目标 |
| §3 | 非目标 | ✅ 完整 | 5 条边界排除 |
| §4 | 用户与消费者 | ✅ 完整 | 6 类消费者，含 `ms_brain` |
| §5 | 功能需求 | ✅ 完整 | FR-001~016，含端点矩阵、核心包、扩展 |
| §6 | 业务规则 | ✅ 完整 | BR-001~010 |
| §7 | 公共 API 契约 | ✅ 完整 | 12 个 API，含请求/响应/约束 |
| §8 | C/S 服务边界 | ✅ 完整 | 7 个组件明确禁止事项 |
| §9 | 领域共享层 | ✅ 完整 | 8 个领域模型；§9.1 绑定状态有标记 |
| §10 | 持久化模型 | ✅ 完整 | 7 类介质职责与权威性 |
| §11 | 配置模式 | ✅ 完整 | 9 类配置键 + §11.1 采集策略参数 |
| §12 | 错误处理 | ✅ 完整 | 7 类错误场景，含 schema drift |
| §13 | 边界情况 | ✅ 完整 | 6 个边界场景 |
| §14 | 目录结构 | ✅ 完整 | 10 个路径映射 |
| §15 | 依赖 | ✅ 完整 | 12 个依赖，含边界约束 |
| §16 | 测试 | ✅ 完整 | TC-001~010，含具体 Go 命令 |
| §17 | 性能预算 | ⚠️ 部分 | 有 dev P95 / P95 API 数值，但**无生产环境 SLA** |
| §18 | 可观测性 | ✅ 完整 | Logs/Metrics/Traces/Health/Audit 五类 |
| §19 | 安全 | ⚠️ 弱 | 6 控制点，但 Admin API 鉴权策略空缺 |
| §20 | CI 门禁 | ✅ 完整 | 7 道 gate，含 secret-scan |
| §21 | 升级兼容性 | ✅ 完整 | 6 类变更策略 |
| §22 | 发布 DoD | ✅ 完整 | AC-001~010 |
| §23 | 待解决问题 | ✅ 完整 | OPEN-001~009，含关闭进展 |
| **§24** | **v1.1.0 变更摘要** | ⚠️ 超标准 | 非标准节，建议迁入 CHANGELOG.md |

> **结论**：主 SPEC 达到 **21/23 节完整（91.3%）**，§17 性能预算和 §19 安全各有 1 项弱点。§24 超标准节建议移出 SPEC。

---

## FR/AC 覆盖矩阵

### 主 SPEC.md — FR 覆盖率：16/16 = 100% ✅

### client/SPEC.md — FR 覆盖率：7/9 = 77.8% ⚠️

| FR | 描述摘要 | AC | 状态 |
|---|---|---|---|
| FR-C001~006, C009 | 采集、归档、发布、全量同步 | AC-C001~005 | ✅ |
| **FR-C007** | **fail-fast（缺配置键）** | **❌ 无对应 AC** | **孤儿 FR** |
| **FR-C008** | **日志/指标带关联字段** | **❌ 无对应 AC** | **孤儿 FR** |

### server/SPEC.md — FR 覆盖率：11/11 = 100% ✅

---

## 需求质量问题清单

### P0 — 必须立即修复

| # | 问题 | 位置 | 建议 |
|---|---|---|---|
| P0-01 | Goal Status 不同步 | `goal/goal.md` | 改为 `Approved` 或 `Implemented` |
| P0-02 | FR-C007 无对应 AC | `spec/client/SPEC.md §6` | 补 AC-C006：缺配置键时启动失败并输出键名 |
| P0-03 | FR-C008 无对应 AC | `spec/client/SPEC.md §6` | 补 AC-C007：日志/指标携带 job_id/series_id/request_id |
| P0-04 | TC-011/V-017 在 ACCEPTANCE.md 缺失 | `spec/ACCEPTANCE.md` | 补充 TC-011（集成套件）和 V-017（rg 校验命令） |

### P1 — 应尽快修复

| # | 问题 | 位置 | 建议 |
|---|---|---|---|
| P1-01 | 别名不一致 `VXVCLS` vs `VIXCLS` | SPEC §5.2 vs SERIES-CATALOG §10 | 统一为 VIXCLS，关闭 OPEN-CAT-1 |
| P1-02 | 别名不一致 `WDTGAL` vs `WTREGEN` | 同上 | 统一修正 |
| P1-03 | SERIES-CATALOG §11.6 未闭合 checkbox | `spec/SERIES-CATALOG.md` | 逐项核实 runtime 状态后改为 `[x]` |
| P1-04 | domain_macro 5 类型落地无证据 | `spec/SPEC.md §9.1` | 补充 domain-macro 版本与已有模型的 evidence 路径 |
| P1-05 | 性能预算缺少生产级 SLA | `spec/SPEC.md §17` | 补充生产 P95/P99 目标 |
| P1-06 | Admin API 鉴权规范缺失 | `spec/SPEC.md §19` | 补充 mTLS 或 JWT 鉴权要求，关闭 OPEN-S2 |

### P2 — 建议改进

| # | 问题 | 建议 |
|---|---|---|
| P2-01 | 模糊语言 "应该" | 改为 MUST |
| P2-02 | §24 超出 23 节标准 | 版本变更摘要移入 CHANGELOG.md |
| P2-03 | OPEN-008 无预计关闭日期 | 补充关闭条件 |
| P2-04 | OPEN-009 无结构化关闭条件 | 补充外部路由清单确认条件 |

---

## SERIES-API 与 SERIES-CATALOG 分析

### SERIES-API.md 关键问题

| 问题 | 严重性 |
|---|---|
| TC-011/V-017 在 ACCEPTANCE.md 中缺失（悬空引用） | 🔴 P0 |
| `authority registry` 在 FEATURES.md 标注 Planned，但 API 文件描述语气已确定 | 🟡 P1 |
| 六个集成测试用例（IT-ROUTING-001..006）完整，但无 ACCEPTANCE.md 追溯 | 🟡 P1 |

### SERIES-CATALOG.md 关键问题

| 问题 | 严重性 |
|---|---|
| SPEC §5.2 用 `VXVCLS`，CATALOG §10 用 `VIXCLS`（OPEN-CAT-1 未关闭） | 🔴 P0 |
| §11.6 有 5 个未闭合 `[ ]` checkbox（source_component 路由实施未确认） | 🔴 P0 |

---

## 改进建议

### 即刻可操作（< 1 天）

1. 更新 `goal/goal.md` Status 字段：`Draft` → `Approved`
2. 在 `spec/client/SPEC.md §6` 补充 AC-C006 和 AC-C007
3. 在 `spec/ACCEPTANCE.md` 补充 TC-011 和 V-017
4. 统一别名：`VXVCLS` → `VIXCLS`，`WDTGAL` → `WTREGEN`，关闭 OPEN-CAT-1
5. 关闭 SERIES-CATALOG §11.6 的 checkbox

### 近期可操作（1 周内）

6. §17 性能预算补充生产 SLA（P95/P99 数值）
7. §19 安全补充 Admin API 鉴权规范（闭合 OPEN-S2）
8. 为 OPEN-008 补充量化关闭条件
9. 将 §24 变更摘要迁移出 SPEC.md，保持 23 节结构
10. 子规格补充领域层约束声明（禁止暴露 internal DTO）

---

## 模块规范建议

**结论：需要建立 fred 专属规范，建议新增以下文件：**

| 文件 | 用途 | 优先级 |
|---|---|---|
| `spec/FRED-API-CONVENTIONS.md` | FRED v1 采集约定（限流/分页/归档路径/错误分类） | P1 |
| `spec/SERIES-NAMING.md` | Series ID 命名规则与别名统一（闭合 OPEN-CAT-1） | P0 |
| `spec/NO-LOOKAHEAD-SEMANTICS.md` | no-lookahead 查询语义形式化定义 | P1 |
| `spec/COVERAGE-AUDIT-THRESHOLDS.md` | 六域覆盖审计阈值与通过条件（闭合 OPEN-008） | P1 |

---

## 总体评分

| 维度 | 得分 |
|---|---|
| Goal 层质量 | 72/100 |
| Spec 结构完整性 | 91/100 |
| FR/AC 覆盖率（主） | 100/100 |
| FR/AC 覆盖率（client） | 78/100 |
| FR/AC 覆盖率（server） | 100/100 |
| 需求精确性 | 83/100 |
| **综合** | **87/100** |
