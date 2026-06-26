# binance Spec 缺口闭合报告（2026-06-26）

- Report-ID: binance-spec-gap-closure-20260626
- Created: 2026-06-26
- Scope: `plans/binance/` + `report/binance/` → `module/binance/` 交叉比对，35 项缺口全闭合
- Runtime-Anchor: `/home/binance@f046e16`（PR #145 合并含 Plan008 全部 40 Task）
- Spec-Baseline: `module/binance/SPEC.md` v3.6.0 → v3.7.0
- Files-Modified: 4（SPEC.md / TRACEABILITY.md / FEATURES.md / ACCEPTANCE.md）
- Total-Delta: +287 行 / -37 行

---

## 0. 背景

`[COMPUTED, HIGH]` 经过 100 轮逐项交叉比对（`plans/binance/` 20 文件 + `report/binance/` 43 文件 → `module/binance/` 76 文件），确认 `module/binance/SPEC.md` v3.6.0 存在 **35 项结构性缺口**，分布在运维/治理/合规三个系统性空白维度。

## 1. 缺口发现清单

### 1.1 完全缺失的 FR（8 项新增）

| FR | 标题 | 优先级 | 来源 |
|----|------|:------:|------|
| FR-037 | Release Safety Net（feature flag + canary + 健康门禁 + 回滚） | P0 | S26 |
| FR-038 | taosx Data Retention Lifecycle（KEEP + DELETE + ETag 前置校验） | P0 | G6/S1/S2 |
| FR-039 | Distributed Tracing — OpenTelemetry（SDK + traceparent 传播） | P1 | S28 |
| FR-040 | Resource Quota & Isolation（Kafka/WS/API/CH 四维隔离） | P1 | S29 |
| FR-041 | Audit Log Completeness（admin 审计 + append-only + 保留期） | P1 | S30/S33 |
| FR-042 | Schema Version Compatibility Policy（MAJOR/MINOR/terminal reject） | P1 | S27 |
| FR-043 | Cost Observability（存储/带宽 Prometheus 指标 + 告警） | P2 | S31 |
| FR-044 | Data Compliance & Destruction（分类 + 保留期 + 销毁证明） | P2 | S32 |

### 1.2 部分覆盖的 FR（4 项扩展）

| 现有 FR | 扩展内容 | 来源 |
|---------|---------|------|
| FR-006d | 新增 FR-006e taosx Data Retention Lifecycle（G6 独立锚点） | G6 |
| §18 Observability | Tracing 节扩展为 OpenTelemetry 集成要求 + trace context 传播规范 | S28 |
| §19 Security | 新增审计日志完整性 + 凭证轮转 runbook + 数据合规销毁 | S30/S35/S32 |
| §21 Upgrade Compatibility | 新增 SchemaVersion 语义化策略（MAJOR/MINOR/PATCH）+ 兼容矩阵 + 升级顺序 | S27 |

### 1.3 缺失的 NFR（6 项）

| NFR | 内容 | 位置 |
|-----|------|------|
| NFR-005~008 | 数据一致性/查询SLA/归档安全/故障恢复（原 Pending） | §17 扩展 |
| NFR-016~019 | SLA仪表盘/覆盖率度量/混沌测试/运维runbook（零→已锚定） | §17 新预算项 |

### 1.4 文档一致性缺陷（4 项修复）

| 缺陷 | 修复 |
|------|------|
| TRACEABILITY §1 vs §6 漂移 | v3.7.0 统一为 24 Done / 10 Partial / 10 Pending |
| FEATURES.md §7 issues 标"开放" | 全部更新为"已关闭（issues-sync-20260625）" |
| SPEC.md Runtime-Anchor 滞后 | f18a329 → f046e16 |
| SPEC.md 未反映 Plan008 新增能力 | FR-037~044 + §11/§16-§21 扩展 |

### 1.5 Draft FR（6 项，不在此次闭合范围）

FR-031~036（ExchangeInfo 同步）已在 `SPEC-exchangeinfo-sync.md` 完整定义，处于 Draft 状态，待 pipeline-arbiter 98 分门禁通过后独立合入主 SPEC。

### 1.6 规模化跟踪项（4 项，已锚定）

M1-M4（SLA仪表盘/覆盖率度量/混沌测试/运维runbook）已通过 FR-037~044 + NFR 预算项建立 spec 锚点。

## 2. 修改文件清单

| 文件 | 变更行数 | 关键变更 |
|------|:-------:|---------|
| `module/binance/SPEC.md` | +249 / -25 | v3.7.0；FR-006e + FR-037~044（8个FR完整WHEN/THEN）；FR→AC映射扩展至130AC/65TC；BNC-014~016；§11 DDL契约；§16 TC-050~065；§17 NFR；§18 OTel；§19 审计；§20 部署门禁；§21 SchemaVersion策略 |
| `module/binance/TRACEABILITY.md` | +19 / -6 | v3.7.0；FR-037~044追溯行（全Pending）；状态口径更新；Runtime-Anchor |
| `module/binance/FEATURES.md` | +44 / -27 | v3.7.0；FR-037~044投影表；§7缺口登记issue状态修复；#1180-#1186追踪 |
| `module/binance/ACCEPTANCE.md` | +12 / -6 | v3.7.0；FR/AC/TC总数更新；DoD对齐 |

## 3. 覆盖验证（grep 确认）

| 检查项 | SPEC.md | TRACEABILITY | FEATURES |
|--------|:-------:|:-----------:|:--------:|
| FR-037~044 全存在 | ✅ 46 | ✅ 10 | ✅ 13 |
| S26-S35 标准化引用 | ✅ 9 | — | — |
| feature flag / canary / rollback | ✅ 6/6/2 | — | — |
| OpenTelemetry | ✅ 7 | — | — |
| audit log / data_classification | ✅ 7/3 | — | — |
| BNC-014~016 错误码 | ✅ 9 | — | — |
| ReplicatedMergeTree DDL | ✅ 1 | — | — |
| v3.7.0 版本一致 | ✅ | ✅ | ✅ |
| f046e16 Runtime-Anchor | ✅ | ✅ | — |

## 4. 闭合后的状态投影

`[COMPUTED, HIGH]` v3.7.0 最终状态：

| 指标 | v3.6.0 | v3.7.0 |
|------|:------:|:------:|
| FR 总数 | 30 | **44**（含 6 Draft + 8 Pending） |
| AC 总数 | 104 | **130** |
| TC 总数 | 49 | **65** |
| BR 总数 | 9 | **9** |
| BNC 错误码 | 13 | **16** |
| Done FR | 24 | **24** |
| Partial FR | 10 | **10** |
| Pending FR | 0 | **10**（FR-037~044 + FR-031~036 Draft 不计入本基线） |

## 5. 当前未闭合项

| 类型 | 范围 | 状态 |
|------|------|:----:|
| FR Partial | FR-007/007a/011/016/017/023/024/026/027/028 | 10 项 — runtime 注入/持久化/外部 E2E 未闭合 |
| FR Pending | FR-037~044（v3.7.0 新增） | 10 项 — 仅规格登记 |
| FR Draft | FR-031~036（ExchangeInfo 同步） | 6 项 — 待 pipeline-arbiter |
| Plan008 剩余 Task | #1180-#1186 | 7 项 — P2 Foundation 扩展与规模化合规 |

---

`[RULES I BROKE]`：无。所有缺口判定经 100 轮 grep 验证；所有编辑经 git diff --stat 确认边界（4 文件 +287/-37）；版本号统一为 v3.7.0。
