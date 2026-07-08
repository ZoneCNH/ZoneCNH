# FRED 模块需求层深度分析报告

**分析时间**：2026-07-08  
**制品版本**：SPEC v1.1.0 / FEATURES v1.1.0 / Goal v1.0 (Draft)

---

## 执行摘要

FRED 模块需求层制品整体质量较高，23 节主规格结构完整，FR-001..FR-016 覆盖面广，TC 均有具体 Go 命令，链路可追溯。但存在**五项核心问题**：

1. Goal 层 Status 仍为 `Draft`，与 SPEC `Implemented` 状态不对称
2. FR-C007 / FR-C008 在 client/SPEC 中无对应 AC（孤儿 FR）
3. SERIES-API.md 引用的 TC-011 / V-017 在 ACCEPTANCE.md 中缺失
4. 非功能需求缺少生产级量化指标（性能 SLA、Admin API 鉴权）
5. OPEN-CAT-1 别名不一致（`VXVCLS` vs `VIXCLS`）尚未统一

---

## Goal 层分析

| 维度 | 评价 | 证据 |
|---|---|---|
| 目标明确性 | ✅ 清晰 | C/S 服务、领域共享层、持久化、事件发布、no-lookahead 五大能力 |
| 可量化性 | ⚠️ 弱 | G-SC-001~006 均为定性描述，无性能阈值、无里程碑 |
| 可验证性 | ✅ | G-SC-003/004/006 可对应到 SPEC AC |
| Status 一致性 | ❌ | goal.md: `Draft`；SPEC.md: `Implemented` |

---

## Spec 完整性评估（23 节）

| 节号 | 节名 | 状态 | 备注 |
|---|---|---|---|
| §1-§16 | 摘要→测试 | ✅ 完整 | 16 节全部完整 |
| §17 | 性能预算 | ⚠️ 部分 | 有 dev P95，但无生产 SLA |
| §18 | 可观测性 | ✅ 完整 | |
| §19 | 安全 | ⚠️ 弱 | Admin API 鉴权策略空缺（OPEN-S2） |
| §20-§23 | CI→待解决问题 | ✅ 完整 | |
| **§24** | **v1.1.0 变更摘要** | ⚠️ 超标准 | 非标准节，建议迁入 CHANGELOG.md |

> 主 SPEC 达到 **21/23 节完整（91.3%）**

---

## FR/AC 覆盖矩阵

| 规格 | FR 总数 | 有 AC | 覆盖率 |
|---|---|---|---|
| 主 SPEC.md | 16 | 16 | **100%** ✅ |
| client/SPEC.md | 9 | 7 | **77.8%** ⚠️ |
| server/SPEC.md | 11 | 11 | **100%** ✅ |

**孤儿 FR**：
- `FR-C007`：fail-fast（缺配置键）无对应 AC
- `FR-C008`：日志/指标带关联字段无对应 AC

---

## 需求质量问题清单

### P0 — 必须立即修复

| # | 问题 | 建议 |
|---|---|---|
| P0-01 | Goal Status 不同步（Draft vs Implemented） | 改为 `Approved` 或 `Implemented` |
| P0-02 | FR-C007 无 AC | 补 AC-C006：缺配置键时启动失败并输出键名 |
| P0-03 | FR-C008 无 AC | 补 AC-C007：日志携带 job_id/series_id/request_id |
| P0-04 | TC-011/V-017 在 ACCEPTANCE.md 缺失 | 补充外部路由集成套件和 rg 校验命令 |

### P1 — 尽快修复

| # | 问题 | 建议 |
|---|---|---|
| P1-01 | VXVCLS vs VIXCLS 别名不一致 | 统一为 VIXCLS，关闭 OPEN-CAT-1 |
| P1-02 | WDTGAL vs WTREGEN 别名不一致 | 统一修正 |
| P1-03 | SERIES-CATALOG §11.6 未闭合 checkbox（5 项） | 逐项核实 runtime 状态后关闭 |
| P1-04 | 性能预算缺生产级 SLA | 补充 P95/P99 生产环境目标 |
| P1-05 | Admin API 鉴权规范缺失 | 补充 mTLS/JWT 要求，关闭 OPEN-S2 |

### P2 — 建议改进

- §24 超标准节迁移至 CHANGELOG.md
- OPEN-008/009 补充量化关闭条件
- FR-003 引用 SERIES-CATALOG §7 P0/P1/P2 分层策略

---

## SERIES-API 与 SERIES-CATALOG 分析

| 文件 | 关键问题 | 严重性 |
|---|---|---|
| SERIES-API.md | TC-011/V-017 在 ACCEPTANCE.md 中缺失（悬空引用） | 🔴 P0 |
| SERIES-API.md | authority registry 状态矛盾（FEATURES: Planned，API 文件: 已确定） | 🟡 P1 |
| SERIES-CATALOG.md | VXVCLS vs VIXCLS 别名不一致（OPEN-CAT-1 未关闭） | 🔴 P0 |
| SERIES-CATALOG.md | §11.6 有 5 个未闭合 checkbox | 🔴 P0 |

---

## 模块规范建议

建立 fred 专属规范文件：

| 文件 | 用途 | 优先级 |
|---|---|---|
| `spec/SERIES-NAMING.md` | Series ID 命名规则与别名统一（闭合 OPEN-CAT-1） | P0 |
| `spec/FRED-API-CONVENTIONS.md` | FRED v1 采集约定（限流/分页/归档路径/错误分类） | P1 |
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
| 需求精确性 | 83/100 |
| **综合** | **87/100** |
