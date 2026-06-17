# CEX C/S Module 模板

> 数据域 · 行情交易所接入模块的标准结构。新增 CEX/DEX/聚合数据源的 SPEC 时**必须**遵循本模板。

最后更新：2026-06-17 · Owner: ZoneCNH · 适用范围：`数据域 · 行情`层全部模块

---

## 1. 范式定义

ZoneCNH 数据域 · 行情统一采用 **C/S Module（Client/Server 双端架构）**，从被动 SDK / Provider 模型升级为显式 client/server 双端：

```text
{Exchange} (REST/WebSocket/HTTP-poll)
  ↓
module/{exchange}/client          ← 交易所侧采集器
  ↓ contracts-defined gRPC (MarketDataService)
module/{exchange}/server          ← 摄入受理服务器
  ↓ downstream dispatch port
module/market-data                ← 交易所中立的后续管线
```

`client` 负责连接交易所、解析和规范化行情事件；`server` 负责验证、去重、ACK 和下游分发。

---

## 2. Canonical Reference

`module/binance` 是 CEX C/S Module 的**首个完整范例**，所有结构性约束、CI 边界门禁、Runtime mapping 规范由 binance 拥有权威定义：

| 引用文档 | 用途 |
|----------|------|
| [`module/binance/SPEC.md`](../../binance/SPEC.md) | 23 节标准结构示例 |
| [`module/binance/client/SPEC.md`](../../binance/client/SPEC.md) | client 子模块标准结构 |
| [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) | server 子模块标准结构 |
| [`module/binance/BOUNDARY-GATES.md`](../../binance/BOUNDARY-GATES.md) | 9 项 CI 边界门禁的可执行脚本 |
| [`module/binance/RUNTIME-MAPPING.md`](../../binance/RUNTIME-MAPPING.md) | spec → runtime 仓库映射 |
| [`module/binance/IMPLEMENTATION-PLAN.md`](../../binance/IMPLEMENTATION-PLAN.md) | 推荐 PR 序列 |
| [`module/binance/TRACEABILITY.md`](../../binance/TRACEABILITY.md) | 追溯矩阵 §1-§7 范式 |

**本模板不复制 binance 的内容**，避免产生 12 份近乎相同的巨型重复。新模块通过引用 binance 继承标准结构，仅声明**交易所特异性差异**。

---

## 3. 必填文件清单

每个 `module/{exchange}/` 必须包含：

| 文件 | 必须性 | 是否可引用 binance |
|------|:----:|:----:|
| `goal.md` | ✅ | ❌ 必须独立编写 |
| `README.md` | ✅ | ❌ 必须独立编写 |
| `SPEC.md` | ✅ | ⚠️ §1-§10 必填，§11-§23 可声明"按 binance 范式" |
| `client/SPEC.md` | ✅ | ⚠️ §1-§7 必填，其余可声明"按 binance/client 范式" |
| `server/SPEC.md` | ✅ | ⚠️ 大部分可继承 binance/server |
| `IMPLEMENTATION-PLAN.md` | ✅ | ⚠️ PR 序列结构相同，scope 须改写 |
| `TRACEABILITY.md` | ✅ | ❌ 必须独立编写（FR/AC 编号绑定本模块） |
| `BOUNDARY-GATES.md` | ❌ | ✅ 单行 stub 引用 binance 等价文档 + exchange name 替换 |
| `RUNTIME-MAPPING.md` | ❌ | ✅ 单行 stub 引用 binance 等价文档 + exchange name 替换 |
| `tasks/` | ⏭️ | 推迟到 SPEC Approved 后 |

---

## 4. 客制化点检查清单

新增 `module/{exchange}/SPEC.md` 时必须明确以下交易所特异性内容：

### §1 Metadata
- [ ] Exchange 名称（小写）
- [ ] Repository URL（必须存在的公开仓库）
- [ ] Module-Version（首版统一为 `v1.0.0-spec`，Status `Draft`）

### §2-§4 Summary / Problem / Goals
- [ ] 列出本交易所的**所有 product lines**（Spot / Perp / Futures / Options / Combo / Aggregated）
- [ ] 描述本交易所**特有的身份碰撞场景**（symbol 重用、合约代码、行权价等）

### §7 Functional Requirements（FR）
- [ ] FR-001 Product-Line Support：列出本交易所启用的产品线
- [ ] FR-002 Instrument Identity：用一张表格描述每条 product line 的**身份维度**（必填字段集合）
- [ ] FR-003 ~ FR-007：可基本继承 binance 范式（gRPC、ACK、admin、boundary）

### §10 Data Model
- [ ] **Instrument Identity Dimensions 表格**（按 product line 列出每个维度是否必填）
- [ ] 如有 exchange-specific spool/event format → 显式列出

### §11 Config Schema
- [ ] `{exchange}.endpoints.rest` / `{exchange}.endpoints.ws` — 实际 endpoint URL
- [ ] `{exchange}.product_lines` — 默认启用的产品线
- [ ] 若有 exchange-specific 配置（如 OKX 的 simulated / DEX 的 chain endpoint）→ 显式列出

### §15 Dependencies
- [ ] 与 binance 同：`contracts` / `domain-market` / `market-data` / `transportx`
- [ ] 若依赖 exchange-specific 第三方 SDK → 显式列出

### §17 Performance Budget
- [ ] 可继承 binance 默认值；若交易所性能特征显著不同（如 DEX 链上确认延迟）→ 调整

### §19 Security
- [ ] 列出 API key / secret / passphrase 的环境变量名
- [ ] 注明是否需要 IP 白名单 / 子账号配置

---

## 5. BOUNDARY-GATES.md / RUNTIME-MAPPING.md 引用模式

允许使用单行 stub 引用 binance 等价文档：

```markdown
# module/{exchange} BOUNDARY GATES

本模块的 9 项 CI 边界门禁结构与 [`module/binance/BOUNDARY-GATES.md`](../binance/BOUNDARY-GATES.md) 一致。

替换规则：
- `binance` → `{exchange}`
- `binance-market` → `{exchange}-market`（如该 legacy 模块存在；否则忽略 §2 gate）
- `Binance` → `{Exchange}`（首字母大写，仅文档措辞）

CI 集成时复制 binance 脚本并应用上述替换。
```

`RUNTIME-MAPPING.md` 同理：directory tree 结构相同，仅 `github.com/ZoneCNH/{exchange}` repo 名替换。

---

## 6. 编号约定

为避免与 binance 的 FR/AC/TC/Task 编号冲突，每个模块使用**模块前缀**：

| 编号类型 | binance 范式 | okx 范式 | hyperliquid 范式 | coinglass 范式 |
|----------|-------------|---------|------------------|----------------|
| FR | `FR-001` | `FR-001` | `FR-001` | `FR-001` |
| BR | `BR-001` | `BR-001` | `BR-001` | `BR-001` |
| AC | `AC-001` | `AC-001` | `AC-001` | `AC-001` |
| TC | `TC-001` | `TC-001` | `TC-001` | `TC-001` |
| Error code | `BNC-001` | `OKX-001` | `HYP-001` | `CGS-001` |
| Task | `TASK-BINANCE-{ROOT/CLIENT/SERVER}-NNN` | `TASK-OKX-{...}-NNN` | `TASK-HYP-{...}-NNN` | `TASK-CGS-{...}-NNN` |

模块内编号自治，不需全局唯一。

---

## 7. 移除 SDK 模型

按 CLAUDE.md 用户决策（2026-06-17），**12 个旧 SDK 模式硬切，不保留兼容层**：

- 对 `okx / bybit / bitget / kucoin / gate / mexc / htx / coinbase / hyperliquid / lighter / upbit / coinglass` 12 个 GitHub 仓库的代码改造按 binance PR-000 模式执行：legacy SDK 引用清除 + no-legacy CI gate 接入
- 文档侧（本仓库）只标注新的 C/S Module 类型，不保留"SDK 模式" provider table

---

## 8. PR 节奏

| 阶段 | 范围 | 当前状态 |
|------|------|---------|
| **A** | 本模板 + okx + hyperliquid + coinglass 三个示范 → 1 个 PR | 🔧 进行中 |
| **B** | 剩余 9 个 CEX：bybit, bitget, kucoin, gate, mexc, htx, coinbase, lighter, upbit → 2 个 PR（4-5 个一组） | ⏭️ 待启动 |
| **C** | STATUS.md / ARCHITECTURE.md / module/README.md / README.md 全量同步 + 版本 bump → 1 个 PR | ⏭️ 待启动 |

---

## 9. 验收清单

新模块通过本模板验收的标准：

- [ ] 必填文件全部存在
- [ ] §1-§10 / §15 / §19 充分客制化（不只是 binance 复印件）
- [ ] FR/AC/TC 编号体系自洽（与 §6 约定一致）
- [ ] BOUNDARY-GATES / RUNTIME-MAPPING 通过 stub 引用 binance 或独立编写
- [ ] STATUS.md 中模块类型由 SDK 改为 C/S Module
- [ ] 模块下属 GitHub 仓库存在并可访问

---

## Appendix: 命令骨架

```bash
# 新增 CEX C/S Module 时执行：
EXCHANGE=newcex   # 替换为目标交易所
mkdir -p module/$EXCHANGE/client module/$EXCHANGE/server

# 拷贝必填文件骨架（人工补内容）
touch module/$EXCHANGE/{goal.md,README.md,SPEC.md,IMPLEMENTATION-PLAN.md,TRACEABILITY.md,BOUNDARY-GATES.md,RUNTIME-MAPPING.md}
touch module/$EXCHANGE/client/SPEC.md
touch module/$EXCHANGE/server/SPEC.md

# 验收前自检
ls module/$EXCHANGE/
ls module/$EXCHANGE/client/
ls module/$EXCHANGE/server/
```
