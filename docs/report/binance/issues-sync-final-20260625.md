# Binance 生产就绪 — Issues 完整拆解与同步报告（最终）

- Report-Date: 2026-06-25
- Analyst: ZCode (builtin:zai-coding-plan/GLM-5.2)
- Scope: 20 轮深度分析 + 评估报告 §7 全部 18 条建议 → beads + GitHub 双轨 issues
- Decision: 分析/评估/治理 issues 统一归属 **ZoneCNH/ZoneCNH**（文档枢纽 + 治理中心）
- Predecessor: [`deep-analysis-20rounds-20260625.md`](deep-analysis-20rounds-20260625.md)

---

## 0. TL;DR

`[COMPUTED, HIGH]` 基于 20 轮深度分析（7 项硬性要求）+ 评估报告 §7 全部 18 条建议，完整拆解 **21 条 issues**，建立 17 条 blocks 依赖关系图。已同步到 **beads 本地**（`/home/ZoneCNH/.beads`）+ **GitHub ZoneCNH/ZoneCNH**（#1055-#1075），双向链接已建立。

**本次包含一次架构纠偏**：issues 从最初创建在 `ZoneCNH/binance`（#74-#92）迁移到 `ZoneCNH/ZoneCNH`——因为分析/评估/治理产物都在文档枢纽，issue 跟踪应统一归属治理中心。binance 仓库的 #74-#92 已全部关闭（附迁移说明）。

---

## 1. 迁移记录

`[COMPUTED, HIGH]` 本次执行了 issues 归属仓库迁移：

| 维度             | 迁移前                                               | 迁移后                                     |
| ---------------- | ---------------------------------------------------- | ------------------------------------------ |
| beads 数据库     | `/home/binance/.beads`（prefix `binance`）           | `/home/ZoneCNH/.beads`（prefix `ZoneCNH`） |
| GitHub issues    | ZoneCNH/binance #74-#92                              | ZoneCNH/ZoneCNH #1055-#1075                |
| binance 仓库痕迹 | .beads/ + CLAUDE.md + .claude/ + .git/config [beads] | **全部清除**（.gitignore beads 行已回退）  |

**清理验证**：

- `/home/binance` 的 `.beads/`、`CLAUDE.md`、`.claude/` 已删除（均为 untracked，无 git 历史）
- `.git/config` 的 `[beads]` section 已移除
- `.gitignore` 的 beads 行已回退到 HEAD 版本
- binance 仓库其他原有 working tree 改动（Plan007 等遗留）**保持不动，未触碰**
- GitHub ZoneCNH/binance #74-#92 共 19 条全部 CLOSED（附统一迁移说明 comment）

---

## 2. 21 条 Issues 完整映射表

`[COMPUTED, HIGH]` beads↔GitHub 双向链接已建立（beads NOTES 回写 GitHub URL）。

### P0 阻断发布项（8 条）

| Beads ID      | GitHub | 缺口  | 标题                                                    | 依赖            |
| ------------- | ------ | ----- | ------------------------------------------------------- | --------------- |
| `ZoneCNH-t60` | #1055  | G0    | 存储 writer 装配接线 — storageFromEnv 注入 serverConfig | **根节点**      |
| `ZoneCNH-zbq` | #1056  | G0    | 移除 persist() nil 静默跳过，改 fail-fast               | ← t60           |
| `ZoneCNH-m7c` | #1057  | G0+G2 | 端到端落盘集成测试（§7.1#3 补齐）                       | ← t60, 7qs, 2dj |
| `ZoneCNH-7qs` | #1058  | C1    | 清除 testnet 依赖，evidence 用 mainnet 官方 URL 重做    | **根节点**      |
| `ZoneCNH-2dj` | #1059  | C4    | 四产品线 mainnet 覆盖矩阵验证（须证据）                 | ← 7qs           |
| `ZoneCNH-p1t` | #1060  | C6    | 文档侧状态口径同步刷新                                  | ← t60, 7qs      |
| `ZoneCNH-znv` | #1061  | C7    | 新增 ENDPOINTS.md 规范                                  | ← 7qs           |
| `ZoneCNH-b2b` | #1062  | C7    | 新增 PERSISTENCE-WIRING.md 规范                         | ← t60           |
| `ZoneCNH-f4j` | #1063  | C7    | 新增 SECURITY.md（自查补齐）                            | ← t60           |

### P1 核心迭代项（5 条）

| Beads ID      | GitHub | 缺口 | 标题                                       | 依赖  |
| ------------- | ------ | ---- | ------------------------------------------ | ----- |
| `ZoneCNH-1yu` | #1064  | G8   | 订单簿 diff 增量维护 + snapshot 重建       | ← t60 |
| `ZoneCNH-dmk` | #1065  | G7   | 合约/期权产品线差异测试                    | ← 2dj |
| `ZoneCNH-5j4` | #1066  | G2   | 真实 Kafka broker fanout 集成测试          | ← 7qs |
| `ZoneCNH-8ji` | #1067  | G5   | GitHub Release tag 产物验证（§7.2#9 补齐） | ← 7qs |
| `ZoneCNH-chr` | #1068  | C7   | 新增 OBSERVABILITY.md                      | ← t60 |

### P2 质量增强项（3 条）

| Beads ID      | GitHub | 缺口   | 标题                         | 依赖  |
| ------------- | ------ | ------ | ---------------------------- | ----- |
| `ZoneCNH-nta` | #1069  | C7     | 新增 OPERATIONS.md Runbook   | ← t60 |
| `ZoneCNH-xeg` | #1070  | FR-010 | ClickHouse OLAP ETL 调度实装 | ← t60 |
| `ZoneCNH-eag` | #1071  | FR-030 | Options Greeks 字段边界测试  | ← 2dj |

### P3 长期演进项（4 条）

| Beads ID      | GitHub | 缺口    | 标题                                                | 依赖       |
| ------------- | ------ | ------- | --------------------------------------------------- | ---------- |
| `ZoneCNH-285` | #1072  | C7      | 新增 DATA-QUALITY-SLA.md                            | **根节点** |
| `ZoneCNH-e30` | #1073  | §20     | 跨模块 boundary-gates 推广                          | ← t60      |
| `ZoneCNH-bx1` | #1074  | ADR-002 | wire 契约迁移到 contracts 仓（§7.4#15 补齐）        | **根节点** |
| `ZoneCNH-o4s` | #1075  | §7.4    | connector 插件化 + 多交易所模板（§7.4#16+#18 补齐） | **根节点** |

---

## 3. 7 项硬性要求覆盖矩阵

`[FRAME, HIGH]` 21 条 issues 对用户 7 项要求的完整覆盖：

| 要求                             | 合规目标                             | 覆盖 issues                              | 缺口数 |
| -------------------------------- | ------------------------------------ | ---------------------------------------- | ------ |
| **1. 禁止 testnet，用官方 URL**  | 清除 testnet + mainnet 重做          | #1058, #1059, #1061                      | 3      |
| **2. 必须持久化，配置在 dev.md** | 存储装配 + fail-fast + 端到端        | #1055, #1056, #1057, #1062               | 4      |
| **3. 四产品线覆盖矩阵须验证**    | mainnet 四线 evidence                | #1059                                    | 1      |
| **4. 业务类型缺口须补齐**        | 订单簿 + 产品线差异 + Kafka + Greeks | #1064, #1065, #1066, #1071               | 4      |
| **5. 外部集成配置在 dev.md**     | （并入要求 2 的存储装配）            | #1055, #1062                             | 已并入 |
| **6. 文档状态口径须同步**        | 文档刷新 + Release 验证              | #1060, #1067                             | 2      |
| **7. 需补充规范**                | 6 个新规范文档                       | #1061, #1062, #1063, #1068, #1069, #1072 | 6      |

**注**：C2（OptionsStreamBaseURL）经官方文档复核后**勘误推翻**（`wss://fstream.binance.com/public/` 是合法期权端点），未列入 issues。

---

## 4. 评估报告 §7 建议覆盖核对

`[COMPUTED, HIGH]` 评估报告 §7 全部 18 条建议逐一核对：

| §7 编号 | 建议                | 覆盖 issue                    | 状态             |
| ------- | ------------------- | ----------------------------- | ---------------- |
| §7.1#1  | 存储装配接线        | #1055                         | ✅               |
| §7.1#2  | persist fail-fast   | #1056                         | ✅               |
| §7.1#3  | 端到端落盘集成测试  | #1057                         | ✅（补齐）       |
| §7.1#4  | 文档状态同步        | #1060                         | ✅               |
| §7.2#5  | 合约/期权 live 验证 | #1058+#1059（纠正为 mainnet） | ✅               |
| §7.2#6  | 产品线差异测试      | #1065                         | ✅               |
| §7.2#7  | 订单簿 diff 重建    | #1064                         | ✅               |
| §7.2#8  | Kafka broker 集成   | #1066                         | ✅               |
| §7.2#9  | Release tag 验证    | #1067                         | ✅（补齐）       |
| §7.3#10 | OPERATIONS.md       | #1069                         | ✅               |
| §7.3#11 | OBSERVABILITY.md    | #1068                         | ✅               |
| §7.3#12 | SECURITY.md         | #1063                         | ✅（补齐）       |
| §7.3#13 | CH OLAP ETL         | #1070                         | ✅               |
| §7.3#14 | Options Greeks      | #1071                         | ✅               |
| §7.4#15 | wire→contracts 迁移 | #1074                         | ✅（补齐）       |
| §7.4#16 | connector 插件化    | #1075                         | ✅（补齐，合并） |
| §7.4#17 | §20 跨模块推广      | #1073                         | ✅               |
| §7.4#18 | 多交易所模板        | #1075                         | ✅（补齐，合并） |

**20 轮分析新增规范**：ENDPOINTS.md（#1061）、PERSISTENCE-WIRING.md（#1062）

**覆盖率：18/18 = 100%**，无遗漏。

---

## 5. 依赖图说明

`[COMPUTED, HIGH]` 17 条 blocks 依赖关系（`bd link` 建立）：

```text
根节点（可立即开工，bd ready）：
  ZoneCNH-t60 (#1055) 存储 writer 装配     ← 解除最多阻塞（8 条下游）
  ZoneCNH-7qs (#1058) testnet 清除          ← 解除 5 条下游
  ZoneCNH-285 (#1072) DATA-QUALITY-SLA.md   ← 独立 P3
  ZoneCNH-bx1 (#1074) wire 迁移             ← 独立 P3（待 contracts 仓）
  ZoneCNH-o4s (#1075) 插件化+模板           ← 独立 P3

汇聚点（多重依赖）：
  ZoneCNH-m7c (#1057) 端到端测试  ← 依赖 t60 + 7qs + 2dj（生产就绪的最终验证）

关键路径（到生产的最短路径）：
  t60(存储装配) → m7c(端到端验证) → 生产就绪
  7qs(mainnet清除) → 2dj(四线验证) → m7c(端到端验证)
```

---

## 6. 执行入口

```bash
# 查看可立即开工的 issues
cd /home/ZoneCNH && bd ready

# 查看某 issue 详情
bd show ZoneCNH-t60

# 认领并开始工作
bd update ZoneCNH-t60 --claim
```

**最高杠杆切入点**：

1. **#1055（t60）存储装配** — 解除 8 条下游阻塞，到生产的最短路径
2. **#1058（7qs）testnet 清除** — 已确认 mainnet 公开行情无需凭据，无阻塞
3. **#1060（p1t）文档同步** — 风险最低，1 天消除认知分裂

---

## 7. beads 数据治理说明

`[COMPUTED, HIGH]` ZoneCNH/ZoneCNH 的 beads 数据库现状：

- **总计 48 条**（27 条 Plan006/Plan007 历史 + 21 条本次生产就绪评估）
- prefix `ZoneCNH`，issue ID 格式 `ZoneCNH-xxx`
- 本地 stealth 模式：`.beads/` 被 `.gitignore` 排除，不进 git，不影响分支纪律
- 与 GitHub 双轨：beads 跟踪依赖图与本地状态，GitHub issues 作为公开协作面

---

> **报告结束。** 21 条 issues 完整覆盖 7 项硬性要求 + 评估报告 §7 全部 18 条建议，无遗漏。beads 本地（48 条，含依赖图）+ GitHub ZoneCNH/ZoneCNH（#1055-#1075）双轨同步完成。binance 仓库 #74-#92 已全部迁移关闭。

`[RULES I BROKE]：无。迁移决策由用户明确授权（AskUserQuestion 确认归属 ZoneCNH/ZoneCNH）；清理 binance 仓库时精确区分了「我引入的痕迹」（.beads/CLAUDE.md/.claude/.gitignore beads 行/.git/config [beads]）与「binance 仓库原有 working tree 改动」（Plan007 遗留，保持不动）；C2 勘误公开记录未掩盖。`
