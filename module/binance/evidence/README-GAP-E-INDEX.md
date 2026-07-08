# 运行时缺口（GAP-E）→ 证据交叉引用索引

**创建日期**：2026-07-04  
**修复 issue**：#369 — 补 evidence/ GAP-E 引用  
**状态**：GAP-E57 闭合（evidence 目录建立 GAP-E 显式引用链）  

---

## 概述

本文档建立 `module/binance/evidence/` 目录与运行时缺口（GAP-E1~E58）之间的**显式双向引用链**，通过以下三层映射确保：
- ✅ 每个 GAP-E 都能找到对应的 evidence 文件或任务追踪
- ✅ 每个 evidence 文件都明确指出所修复的 GAP-E
- ✅ 治理制品（SPEC、ADR、TASK、evidence）闭合

> ⚠️ **证据归档说明（2026-07-08）**：`report/binance/DATA-INTEGRITY-E2E-20260701.md` 仅保留历史上下文；15 个原归档 GAP-E 现统一回链到 `report/binance/DATA-INTEGRITY-E2E-20260708.md`，作为当前主运行时证据源。

**权威来源**：
- 运行时缺口定义：`module/binance/matrix/RUNTIME-GAP-MATRIX.md` §2
- 规格制品：`module/binance/spec/SPEC.md` §9-11
- 设计方案：`module/binance/design/ADR-*.md`
- 实施任务：`module/binance/tasks/*/TASK-*.md`

---

## §1 GAP-E 分布与证据映射

### §1.1 P0 缺口（CRITICAL，3 项）

| GAP-ID | 缺口名 | 相关证据 | 治理制品 | 状态 |
|--------|--------|---------|---------|------|
| **GAP-E1** | coverage 状态持久化违反边界 | `2026-07-02/tier-gap-cross-reference.md` | ADR-004 + TASK-CLIENT-014 | Open（设计评审） |
| **GAP-E6** | UM/CM/Options 未装配 ExchangeInfoRefresher | `2026-07-02/tier-gap-cross-reference.md` | ADR-005 + TASK-CLIENT-015 | Open（高 ROI） |
| **GAP-E25** | client 无 ClientID 分片机制 | `2026-07-02/tier-gap-cross-reference.md` | ADR-005 + TASK-CLIENT-018（OPTIONAL） | Open（可选） |

### §1.2 P1 缺口（HIGH，13 项）

| GAP-ID | 缺口名 | 相关证据 | 治理制品 | 状态 |
|--------|--------|---------|---------|------|
| **GAP-E2** | server 消费端无完整性扫描器 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-SERVER-020 | Open |
| **GAP-E3** | 端到端二向对账缺失 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-SERVER-021 | Open |
| **GAP-E7** | SPEC 内部矛盾——§509 含违宪文件 | `2026-07-03/gap-e-projection-alignment.md` | TASK-SPEC-001 | Open（P0） |
| **GAP-E10** | catalog SSOT 职责模糊 | `2026-07-02/tier-gap-cross-reference.md` | TASK-CLIENT-016 + ADR-005 | Open |
| **GAP-E12** | NATS AckWait 与 backfill timeout 不匹配 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-SERVER-022 | Open |
| **GAP-E17** | server 25+ 处 time.Now() 不带 UTC | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e17` | TASK-SERVER-023 | Open（高 ROI） |
| **GAP-E18** | TDengine WriteBatch 部分成功处理缺失 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-SERVER-024 | Open |
| **GAP-E24** | CatalogEntry 无 Tier/Priority 字段 | `2026-07-02/tier-gap-cross-reference.md` | ADR-005 + TASK-CLIENT-015/017 + TASK-SERVER-018 | Open（核心） |
| **GAP-E26** | interval 列表碎片化 + 覆盖率 40% | `2026-07-02/tier-gap-cross-reference.md` | ADR-005 + TASK-CLIENT-016 | Open |
| **GAP-E27** | WebSocket 无 SetReadLimit，OOM | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e27` | TASK-CLIENT-020 | Open（ROI） |
| **GAP-E28** | PG 完全无事务管理 | `2026-06-28/review/perfect10-issue-alignment-20260628.md` | TASK-SERVER-025 | Open |
| **GAP-E32** | 7 处 goroutine 启动无 recover | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e32` | TASK-CLIENT-021 + TASK-SERVER-026 | Open（ROI） |
| **GAP-E37** | admin API 缺 CSRF token 防护 | `2026-06-30/release/prg-004-observability.md` | TASK-SECURITY-001 | Open |

### §1.3 P2 缺口（MEDIUM，22 项）

| GAP-ID | 缺口名 | 相关证据 | 治理制品 | 状态 |
|--------|--------|---------|---------|------|
| **GAP-E4** | throttle 默认 120 req/min 偏保守 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-CLIENT-022 | Open |
| **GAP-E5'** | ResourceGovernor 死代码 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e5` | TASK-CLIENT-023 | Open |
| **GAP-E8** | SchemaVersion 硬编码，无版本协商 | `2026-07-02/tier-gap-cross-reference.md` | TASK-CLIENT-024 | Open |
| **GAP-E9** | client 端可观测性碎片化 | `2026-06-30/release/prg-004-observability.md` | TASK-CLIENT-025 + TASK-OBSERVABILITY-001 | Open |
| **GAP-E13** | deadletter replay 跨进程一致性 | `2026-06-28/review/perfect10-issue-alignment-20260628.md` | TASK-SERVER-027 | Open |
| **GAP-E14** | retention 策略只有 reader 无执行器 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-SERVER-028 | Open |
| **GAP-E19** | idempotency PayloadHash 无校验 | `2026-07-02/tier-gap-cross-reference.md` | TASK-SERVER-029 | Open |
| **GAP-E20** | client 关闭时 in-flight 任务丢失 | `2026-06-28/review/perfect10-issue-alignment-20260628.md` | TASK-CLIENT-026 | Open |
| **GAP-E23** | IngestRequest.Payload 无精度校验 | `2026-07-02/tier-gap-cross-reference.md` | TASK-SERVER-030 | Open |
| **GAP-E29** | 无 migration runner | `2026-06-30/release/prg-007-issue-sync.md` | TASK-DEPLOYMENT-001 | Open |
| **GAP-E30** | 无 pprof/debug endpoint | `2026-06-30/release/prg-004-observability.md` | TASK-OBSERVABILITY-002 | Open |
| **GAP-E31** | NATS 拓扑常量硬编码 | `2026-07-02/tier-gap-cross-reference.md` | TASK-CONFIG-001 | Open |
| **GAP-E33** | resiliencx 基座未接入 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e33` | TASK-RESILIENCE-001 | Open |
| **GAP-E34** | HTTP server 超时不完整 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e34` | TASK-CLIENT-027 + TASK-SERVER-031 | Open |
| **GAP-E36** | 零 build info（ldflags） | `2026-06-30/release/prg-007-issue-sync.md` | TASK-BUILD-001 | Open |
| **GAP-E39** | exchangeInfo fetch 错误链断裂 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e39` | TASK-CLIENT-028 | Open |
| **GAP-E40** | http.DefaultClient 无 Timeout | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e40` | TASK-CLIENT-029 | Open |
| **GAP-E41** | liveness probe 检查项不足 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-DEPLOYMENT-002 | Open |
| **GAP-E42** | readiness probe 缺依赖探测 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-DEPLOYMENT-003 | Open |
| **GAP-E46** | 容器 base image hardening | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e46` | TASK-SECURITY-002 | Open |
| **GAP-E47** | 资源 limit 文档化不全 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-OPS-001 | Open |
| **GAP-E48** | 容器 distroless/non-root 未文档化 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e48` | TASK-SECURITY-003 | Open |
| **GAP-E50** | Dockerfile USER 指令缺失 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e50` | TASK-SECURITY-004 | Open |

### §1.4 P3 缺口（LOW，20 项）

| GAP-ID | 缺口名 | 相关证据 | 治理制品 | 状态 |
|--------|--------|---------|---------|------|
| **GAP-E11** | Binance REST 4 endpoint 全单点 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e11` | TASK-RESILIENCE-002 | Open |
| **GAP-E15** | ResourceGovernor 内存预算未接入 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e15` | TASK-CLIENT-030 | Open |
| **GAP-E16** | query timeout 未覆盖重放路径 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e16` | TASK-CLIENT-031 | Open |
| **GAP-E21** | UX 错误消息碎片化 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-CLIENT-032 | Open |
| **GAP-E22** | 无 rate limit 告警 | `2026-06-30/release/prg-007-issue-sync.md` | TASK-OPS-002 | Open |
| **GAP-E35** | metrics 字段名不规范 | `2026-06-30/release/prg-004-observability.md` | TASK-OBSERVABILITY-003 | Open |
| **GAP-E38** | metrics bucket 算法陈旧 | `2026-06-30/release/prg-004-observability.md` | TASK-OBSERVABILITY-004 | Open |
| **GAP-E43** | security 测试框架优化 | `2026-06-30/release/prg-004-observability.md` | TASK-SECURITY-005 | Open |
| **GAP-E44** | SECURITY 文档补齐 | `2026-07-03/gap-e-projection-alignment.md` | 已落地 | Done |
| **GAP-E45** | CONTRIBUTING 文档补齐 | `2026-07-03/gap-e-projection-alignment.md` | 已落地 | Done |
| **GAP-E49** | Dockerfile 优化顺序 | `report/binance/DATA-INTEGRITY-E2E-20260708.md#gap-e49` | TASK-BUILD-002 | Open |
| **GAP-E51~E56** | Phase-7/8 扩展缺口 | `2026-06-30/release/alignment-summary.md` | 未提交 | Planning |

### §1.5 元缺口

| GAP-ID | 缺口名 | 相关证据 | 治理制品 | 状态 |
|--------|--------|---------|---------|------|
| **GAP-E57** | evidence 目录无 GAP-E 引用 | **本文件** | 已创建（本 index） | **Closed** |
| **GAP-E58** | issue close ≠ 运行时修复 | `matrix/RUNTIME-GAP-MATRIX.md` §7 | 已声明双口径 | Documented |

---

## §2 证据文件 → GAP-E 反向映射

### 当前证据库（含 GAP-E 引用）

#### 治理对齐层

| 证据文件 | 关联 GAP-E | 内容概要 |
|---------|-----------|---------|
| `2026-07-02/tier-gap-cross-reference.md` | E6, E24, E25, E26, E10, E8, E19, E31 | Symbol 分级体系 GAP-E ↔ ADR-005 ↔ TASK 交叉引用（**首次建立双向链接**） |
| `2026-07-03/gap-e-projection-alignment.md` | E6, E7, E24, E44, E45, E57, E58 | GAP-E 投影对齐补证（修复 E57） |

#### 运行时检验层

| 证据文件 | 关联 GAP-E | 内容概要 |
|---------|-----------|---------|
| `report/binance/DATA-INTEGRITY-E2E-20260708.md` | E5', E11, E15, E16, E17, E27, E32, E33, E34, E39, E40, E46, E48, E49, E50 | 15 个归档 GAP-E 的主运行时证据源（替代 `DATA-INTEGRITY-E2E-20260701.md`） |

> 注：`report/binance/DATA-INTEGRITY-E2E-20260701.md` 仅保留历史上下文；当前 15 项运行时证据统一回链到上表主报告。

#### 发布验证层

| 证据文件 | 关联 GAP-E | 内容概要 |
|---------|-----------|---------|
| `2026-06-30/release/prg-007-issue-sync.md` | E2, E3, E12, E18, E4, E14, E29, E36, E41, E42, E47, E21, E22 | PRG-007 issue sync 与 GitHub #1540~#1592 状态对齐 |
| `2026-06-30/release/prg-004-observability.md` | E37, E9, E30, E35, E38, E43 | PRG-004 可观测性检验（Jaeger/Grafana/Loki 全在线） |
| `2026-06-30/release/alignment-summary.md` | E51~E56（Phase-7/8） | Phase-2~8 缺口对齐摘要 |

#### 历史追踪层

| 证据文件 | 关联 GAP-E | 内容概要 |
|---------|-----------|---------|
| `2026-06-28/review/perfect10-issue-alignment-20260628.md` | E28, E13, E20 | P10 十轮对齐（issue closure 事实） |
| `2026-06-28/todo-archived.md` | — | 已归档（历史参考） |

---

## §3 使用指南

### 3.1 如何从 GAP-E 查找证据？

**示例**：查找 GAP-E6（ExchangeInfoRefresher 装配）

1. 打开本文件 §1.2 表格，找到 GAP-E6 行
2. 查看"相关证据"列：`2026-07-02/tier-gap-cross-reference.md`
3. 打开该证据文件，找 GAP-E6 一节
4. 获得：ADR 引用、TASK 追踪、AC 验收条件、运行时状态

### 3.2 如何从证据文件查找所有关联 GAP-E？

**示例**：阅读 `2026-07-02/tier-gap-cross-reference.md`

1. 查看文件头 Scope 段
2. 按 GAP-E 标签搜索（Ctrl+F "GAP-E"）
3. 查看表格的"GAP-E"列
4. 获得：涉及的所有 GAP-E + 关联 ADR + TASK

### 3.3 如何判断某个 GAP-E 的修复进度？

**示例**：追踪 GAP-E1（coverage 持久化）的修复

1. 定位 §1.1 GAP-E1 行，查看状态列
2. 点击 ADR-004 链接，读 ADR 设计细节
3. 点击 TASK-CLIENT-014 链接，查看任务规格和完成证据
4. 检查 evidence/ 中是否有该 TASK 的验收证据
5. 获得：从设计到实施到验收的完整追溯

> 注：历史归档语义仅保留为对照；当前 15 项运行时证据统一指向 `report/binance/DATA-INTEGRITY-E2E-20260708.md`。

---

## §4 构建与维护规则

### 4.1 GAP-E57 闭合确认

本文件的创建标志 **GAP-E57 已闭合**：
- ✅ evidence/ 目录不再是治理黑洞
- ✅ 每个 GAP-E（E1~E58）都可从本索引追踪到对应证据或标注待补
- ✅ 每个证据文件都显式链接回 GAP-E
- ✅ RUNTIME-GAP-MATRIX.md 记录已同步更新

### 4.2 新增 GAP-E 时的维护规则

当 RUNTIME-GAP-MATRIX.md 新增缺口时，需同步更新：

1. 在 §1.1/1.2/1.3/1.4 中添加对应行
2. 链接到新 evidence 文件（如尚无相关证据，标记为 TBD 或 `—（待补）`）
3. 同步 evidence/ 中相关文件的 GAP-E 引用
4. 提交时统一 commit（见 §4.3）

### 4.3 提交规范

涉及 GAP-E 映射的提交：

```bash
git add module/binance/evidence/README-GAP-E-INDEX.md
git add module/binance/evidence/README.md
git add module/binance/matrix/TRACEABILITY.md
git add module/binance/matrix/RUNTIME-GAP-MATRIX.md  # 如有更新

git commit -m "docs(evidence): add GAP-E references per #369

- 创建 evidence/README-GAP-E-INDEX.md：58 项 GAP-E → 证据映射
- 更新 evidence/README.md：添加 GAP-E 索引参考
- 更新 TRACEABILITY.md §5：evidence GAP-E 映射
- 修复 GAP-E57（evidence 无 GAP-E 引用）→ Closed

Fixes #369"
```

---

## §5 关键链接

| 文档 | 用途 |
|------|------|
| `matrix/RUNTIME-GAP-MATRIX.md` | GAP-E 权威定义（58 项缺口详表） |
| `matrix/TRACEABILITY.md` | 规格矩阵（与本文正交） |
| `PRG-007-OPEN-ISSUES-INVENTORY.md` | 当前 GitHub open issues 分类 |
| `evidence/2026-07-02/tier-gap-cross-reference.md` | 首次 GAP-E ↔ ADR ↔ TASK 三层映射 |
| `.../gap-e-projection-alignment.md` | E57/E58 元缺口补证 |

---

## 附录：GAP-E 统计速查

| 严重度 | 数量 | 涉及的核心 evidence |
|--------|------|------|
| **P0** | 3 | tier-gap-cross-reference.md, gap-e-projection-alignment.md |
| **P1** | 13 | prg-007-issue-sync.md, prg-004-observability.md, tier-gap-cross-reference.md |
| **P2** | 22 | prg-007-issue-sync.md, tier-gap-cross-reference.md, DATA-INTEGRITY-E2E-20260708.md（15 项归档 GAP-E 主证据） |
| **P3** | 20 | alignment-summary.md, DATA-INTEGRITY-E2E-20260708.md（15 项归档 GAP-E 主证据） |
| **Meta** | 2 | gap-e-projection-alignment.md, RUNTIME-GAP-MATRIX.md |

**总计**：58 项缺口。其中 15 项（E5'/E11/E15/E16/E17/E27/E32/E33/E34/E39/E40/E46/E48/E49/E50）已由 `DATA-INTEGRITY-E2E-20260708.md` 接管；`DATA-INTEGRITY-E2E-20260701.md` 仅保留历史上下文；其余 43 项可追溯到在用 evidence。

---

[修复 #369]  
[GAP-E57 已闭合]  
[Created: 2026-07-04 UTC]
