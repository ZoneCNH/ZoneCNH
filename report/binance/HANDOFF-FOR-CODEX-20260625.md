# binance 模块交接说明（for codex / 其他 agent）

- Created: 2026-06-25
- Author: ZCode（GLM-5.2 session）
- Purpose: 防止并发 agent 误执行 Draft FR 或重复已完成的工作
- Main-HEAD: `457519db`
- Runtime-Anchor: `/home/binance@f18a329`

> [COMPUTED, HIGH] **如果你是 codex 或其他 agent，在执行 binance 相关 issue 前，必读本文件。** 本文件防止三类错误：(1) 误执行 Draft FR；(2) 重复已完成工作；(3) 基于过期状态操作。

---

## ⛔ 不要执行这些（Draft 规格，未 Approved）

以下 FR 是 **Draft 规格草案**，定义于 `module/binance/SPEC-exchangeinfo-sync.md`，**尚未经 pipeline-arbiter 98 分门禁批准**。在 `Status: Approved` 翻转前，**禁止实现这些 FR 的 runtime 代码**。

| FR | 标题 | 状态 | 原因 |
|----|------|------|------|
| FR-031 | ExchangeInfo Discovery (4 Product Lines) | **Draft** | 待 arbiter |
| FR-032 | ExchangeInfo Persistence & Scheduled Refresh | **Draft** | 待 arbiter |
| FR-033 | Sync Tier Classification | **Draft** | 待 arbiter |
| FR-034 | Selective Sync Whitelist | **Draft** | 待 arbiter |
| FR-035 | Admin Surface Auth Hardening | **Draft** | 待 arbiter |
| FR-036 | Tier-Aware Connection Topology | **Draft** | 待 arbiter + 需 ADR 前置 |

要推进这些 FR，触发 `pipeline binance` 或 `/project:spec-code-pipeline binance` 进入 98 分门禁评审。

---

## ✅ 已完成（不要重复）

| 工作项 | PR | 状态 |
|--------|-----|------|
| exchangeInfo 同步规格（FR-031~036，五轮审查） | #1119 | merged `5dbe0d26` |
| symbol 同步深度分析（3,616 symbol 实测） | #1119 | merged |
| issue 账本修正（#1106 状态漂移 + FR draft 登记） | #1120 | merged `156823c6` |
| #1106 关闭（文档对齐关闭条件逐条验证） | #1121 | merged `457519db`，#1106 CLOSED |

---

## 📋 可执行的 Open Issues（14 个）

以下是已批准的、可执行的 runtime/evidence issue。优先级和关闭条件见 `issues-sync-20260625.md`。

| 优先级 | Issue | 标题 |
|--------|-------|------|
| **P0** | #1104 | 补齐 FR-016 历史回补运行时 REST fetcher 注入 |
| **P0** | #1105 | 厘清 Kafka broker roundtrip 证据冲突 |
| P1 | #1107 | 明确或实现 UM/CM/Options 历史 REST endpoint 支持 |
| P1 | #1108 | 用 mainnet 样本校验 Options ticker 字段归一化 |
| P1 | #1109 | 补齐速率限制平滑与 token bucket 机制 |
| P1 | #1110 | 补齐分布式 tracing 与 trace context 传播 |
| P1 | #1111 | 补齐 Options active symbol live 覆盖 |
| P1 | #1112 | 建立 storage mock 与 fake 的测试标准 |
| P1 | #1113 | 补齐 100K TPS/backpressure 标准与实证 |
| P2 | #1114 | 补齐增量 order book rebuild 状态机 |
| P2 | #1115 | 将 ClickHouse ETL 从内存源升级为持久/多实例来源 |
| P2 | #1116 | 支持增量 hot reload diff 而非全量重连 |
| P2 | #1117 | 持久化历史回补进度 |
| P2 | #1118 | 补齐持久 DLQ wiring 与 replay 流程 |

> #1093（长期#10: 核心交易闭环跑通 live_integration）是长期 issue，非本轮范围。

---

## ⚠️ 依赖交叉（task-split 时注意）

| 现有 issue | 关系 | Draft FR | 影响 |
|-----------|------|---------|------|
| **#1107** | 被包含 | FR-031 | FR-031 实现后 #1107 可关闭（但 FR-031 是 Draft，当前仍应独立执行 #1107） |
| **#1116** | 被依赖 | FR-036 | FR-036 的 tier drain 依赖 #1116；**#1116 应优先执行**，FR-036 Approved 后可复用 |
| **#1104** | 路径复用 | FR-032 | FR-032 复用 #1104 修复的 REST fetcher 路径；**#1104 应优先执行** |
| **#1108** | 数据基础 | FR-031 | FR-031 为 #1108 提供契约；当前独立执行 #1108 无阻塞 |

**建议执行顺序**：#1104 → #1107 → #1116 → 其余 P1 → P2（#1104 和 #1116 是多个 Draft FR 的前置依赖）

---

## 🔄 恢复前必做

```bash
# 1. 确保在 main 最新状态
git checkout main && git pull origin main

# 2. 确认 HEAD
git log -1 --oneline
# 应显示: 457519db docs(binance): 关闭 #1106 ...

# 3. 确认 #1106 已关闭（不要重复执行文档对齐）
gh issue view 1106 --json state --jq '.state'
# 应显示: CLOSED

# 4. 读取最新账本
cat report/binance/issues-sync-20260625.md
```

---

`[RULES I BROKE]`：无。本文件是纯交接说明，所有状态字段来自 GitHub API + git 实证。
