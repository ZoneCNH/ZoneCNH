# Binance Perfect-10 todo.md 归档

> [COMPUTED, HIGH] 本文件是 `module/binance/todo.md` 在 2026-06-28 的归档快照。
> [COMPUTED, HIGH] 当前任务追踪 SSOT 为 Beads (`bd`) 与 GitHub Issues；本归档不得作为当前 P10 issue 编号映射或关闭状态依据。

---

# Binance Perfect-10 行动方案 TODO

> 基线报告：`report/binance/deep-structural-analysis-20260628.md`
> 行动方案：`report/binance/perfect-10-action-plan-20260628.md`
> 创建日期：2026-06-28
> 目标：10 维度从 7.2 → 10/10
> 追踪：Beads (bd) + GitHub Issues (#1289-#1331)

---

## 评分总览

| 维度        | 当前 | 目标 | 差距 |
| ----------- | :--: | :--: | :--: |
| 架构设计    | 9.0  |  10  | 1.0  |
| 边界强制    | 9.5  |  10  | 0.5  |
| Spec 完整性 | 8.5  |  10  | 1.5  |
| 追溯矩阵    | 8.0  |  10  | 2.0  |
| 代码完成度  | 5.5  |  10  | 4.5  |
| 生产就绪    | 5.0  |  10  | 5.0  |
| 文档治理    | 6.5  |  10  | 3.5  |
| 测试覆盖    | 7.0  |  10  | 3.0  |
| 可观测性    | 7.5  |  10  | 2.5  |
| 安全合规    | 6.0  |  10  | 4.0  |

---

## Phase 1：文档治理 + Spec + 追溯矩阵 + 边界 + 架构（ZoneCNH 仓库）

| #   | Action ID | 任务                         | Beads        | GH Issue | 优先级 |  状态   |
| --- | --------- | ---------------------------- | ------------ | -------- | :----: | :-----: |
| 1   | A-1       | internal/wire 角色明确化     | ZoneCNH-5k4j | #1289    |   P0   | Pending |
| 2   | A-2/E-5   | main.go 配置收敛             | ZoneCNH-lk5q | #1290    |   P0   | Pending |
| 3   | A-3/B-1   | HTTP /ingest gate smoke-only | ZoneCNH-z31g | #1291    |   P0   | Pending |
| 4   | A-4/B-3   | subject 版本化 .v1           | ZoneCNH-5cv5 | #1294    |   P0   | Pending |
| 5   | B-2       | client/SPEC §14 目录修正     | ZoneCNH-886q | #1295    |   P1   | Pending |
| 6   | C-1/G-3   | SPEC 参数表迁移到 design/    | ZoneCNH-o6ge | #1296    |   P0   | Pending |
| 7   | C-2/G-2   | 退役文件物理删除             | ZoneCNH-k2ml | #1297    |   P0   | ✅ Done |
| 8   | C-3       | SPEC 精简至 <1000 行         | ZoneCNH-87x7 | #1298    |   P0   | Pending |
| 9   | C-4       | AC/TC 编号空间清理           | ZoneCNH-l7um | #1299    |   P1   | Pending |
| 10  | D-1       | 废除双态模型 [CRITICAL]      | ZoneCNH-9iaw | #1292    |   P0   | Pending |
| 11  | D-2/G-1   | TRACEABILITY 历史注记迁移    | ZoneCNH-32qf | #1300    |   P0   | Pending |
| 12  | D-3       | release_closeable 标准修正   | ZoneCNH-5gfo | #1293    |   P0   | Pending |
| 13  | D-4/G-5   | todo.md 归档                 | ZoneCNH-bgj0 | #1301    |   P0   | ✅ Done |
| 14  | G-4       | BOUNDARY-GATES §20 迁移      | ZoneCNH-obwk | #1302    |   P1   | ✅ Done |
| 15  | G-6       | 状态一致性 CI gate           | ZoneCNH-s1k2 | #1303    |   P1   | Pending |

## Phase 2：代码闭合（/home/workspace/binance 运行时仓库）

| #   | Action ID | 任务                           | Beads        | GH Issue | 优先级 |  状态   |
| --- | --------- | ------------------------------ | ------------ | -------- | :----: | :-----: |
| 16  | E-1       | P0 核心 FR 闭合 (6 FR)         | ZoneCNH-o1bm | #1304    |   P0   | Pending |
| 17  | E-2       | P1 生产就绪 FR 闭合 (6 FR)     | ZoneCNH-kmvd | #1305    |   P0   | Pending |
| 18  | E-3       | P2 ExchangeInfo FR 闭合 (6 FR) | ZoneCNH-s9v2 | #1306    |   P1   | Pending |
| 19  | E-4       | P2 合规 FR 闭合 (7 FR)         | ZoneCNH-s3hd | #1307    |   P1   | Pending |
| 20  | E-6       | spec-runtime drift 检测脚本    | ZoneCNH-1l30 | #1308    |   P2   | Pending |

## Phase 3：生产部署（/home/workspace/binance 运行时仓库）

| #   | Action ID | 任务                        | Beads        | GH Issue | 优先级 |  状态   |
| --- | --------- | --------------------------- | ------------ | -------- | :----: | :-----: |
| 21  | F-1       | GitHub Actions 远程 CI      | ZoneCNH-2gt4 | #1309    |   P0   | Pending |
| 22  | F-2       | Release tag v0.2.0          | ZoneCNH-pp3h | #1310    |   P0   | Pending |
| 23  | F-3       | PRG 全 PASS (7项)           | ZoneCNH-aqbf | #1311    |   P0   | Pending |
| 24  | F-4       | HA/DR 部署文档 (7份)        | ZoneCNH-laf5 | #1312    |   P0   | Pending |
| 25  | F-5/J-1   | Credential Rotation Runbook | ZoneCNH-9ls5 | #1313    |   P0   | Pending |
| 26  | F-6       | Canary 部署演练             | ZoneCNH-3ej4 | #1314    |   P1   | Pending |
| 27  | F-7       | 容量规划                    | ZoneCNH-4nc8 | #1315    |   P1   | Pending |

## Phase 4：测试覆盖（/home/workspace/binance 运行时仓库）

| #   | Action ID | 任务                    | Beads        | GH Issue | 优先级 |  状态   |
| --- | --------- | ----------------------- | ------------ | -------- | :----: | :-----: |
| 28  | H-1       | Partial FR 深度测试补全 | ZoneCNH-bppf | #1316    |   P0   | Pending |
| 29  | H-2       | 覆盖率 ≥ 98%            | ZoneCNH-a2te | #1317    |   P0   | Pending |
| 30  | H-4       | Soak Test (30min)       | ZoneCNH-qhos | #1318    |   P1   | Pending |
| 31  | H-5       | 混沌测试                | ZoneCNH-4b1b | #1319    |   P1   | Pending |

## Phase 5：可观测性（/home/workspace/binance 运行时仓库）

| #   | Action ID | 任务                    | Beads        | GH Issue | 优先级 |  状态   |
| --- | --------- | ----------------------- | ------------ | -------- | :----: | :-----: |
| 32  | I-1       | cost/audit 指标完整实现 | ZoneCNH-nron | #1320    |   P0   | Pending |
| 33  | I-2       | OTel 端到端可视化       | ZoneCNH-mxmd | #1321    |   P1   | Pending |
| 34  | I-3       | Grafana Dashboard       | ZoneCNH-2kjq | #1322    |   P1   | Pending |
| 35  | I-4       | AlertManager 告警规则   | ZoneCNH-xgrq | #1323    |   P1   | Pending |
| 36  | I-5       | 日志聚合配置            | ZoneCNH-og7z | #1324    |   P2   | Pending |

## Phase 6：安全合规（/home/workspace/binance 运行时仓库）

| #   | Action ID | 任务                 | Beads        | GH Issue | 优先级 |  状态   |
| --- | --------- | -------------------- | ------------ | -------- | :----: | :-----: |
| 37  | J-2       | Admin Auth + mTLS    | ZoneCNH-fbff | #1325    |   P0   | Pending |
| 38  | J-3       | Secrets 扫描 CI gate | ZoneCNH-klgj | #1326    |   P0   | Pending |
| 39  | J-4       | 依赖漏洞扫描 CI gate | ZoneCNH-l2oa | #1327    |   P0   | Pending |
| 40  | J-5       | 网络隔离文档         | ZoneCNH-hjp4 | #1328    |   P1   | Pending |
| 41  | J-6       | 数据分类标注实施     | ZoneCNH-w47o | #1329    |   P1   | Pending |
| 42  | J-7       | 合规销毁演练         | ZoneCNH-ckpf | #1330    |   P2   | Pending |
| 43  | J-8       | API 渗透测试         | ZoneCNH-dvf9 | #1331    |   P2   | Pending |

---

## 执行路径

### 阶段 1（第 1-2 周）：基础修复

Phase 1 全部 15 项 → 维度 1-4 + 7 达到 9.5+

### 阶段 2（第 3-5 周）：代码闭合

Phase 2 全部 5 项 → 维度 5 达到 9.0+

### 阶段 3（第 5-6 周）：生产部署

Phase 3 + 4 + 5 + 6 → 维度 6/8/9/10 达到 9.5+

### 阶段 4（第 6-7 周）：收尾验证

全维度 10/10

---

## 验收标准

| 检查项              | 标准                    |
| ------------------- | ----------------------- |
| FR 完成度           | ≥43/48 Code-Done (≥90%) |
| 远程 CI             | GitHub Actions PASS     |
| Release tag         | v0.2.0 已发布           |
| 覆盖率              | ≥ 98%                   |
| Boundary gates      | 14/14 PASS              |
| PRG                 | 7/7 PASS                |
| HA/DR 文档          | 7 份存在                |
| Credential rotation | runbook 存在            |
| Grafana dashboard   | JSON 存在               |
| AlertManager        | YAML 存在               |
| Soak test           | 30min PASS              |
| 混沌测试            | 全 PASS                 |
| 渗透测试            | 全 PASS                 |
| SPEC                | < 1000 行               |
| TRACEABILITY        | < 200 行                |
| 退役文件            | 0 个存在                |

---

> 任务追踪使用 `bd ready` / `bd show <id>` / `bd close <id>`
> GitHub Issues: #1289-#1331
