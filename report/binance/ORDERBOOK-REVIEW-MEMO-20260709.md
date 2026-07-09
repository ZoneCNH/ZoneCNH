# OrderBook 深度分析评审备忘

> **日期**：2026-07-09
> **性质**：对 [`orderbook-deep-analysis.md`](orderbook-deep-analysis.md)（PR #1739）的补充与异议
> **作者**：Claude（Lead 视角独立评审）
> **证据口径**：源码 `file:line` + 治理制品双重核验 `[COMPUTED]`，置信度 HIGH
> **立场声明**：本备忘不否定 `orderbook-deep-analysis.md` 的对照工作（19 章对齐度量化准确），仅就其**优化建议方向**提出异议，并补充其未覆盖的认识论判断。

---

## 背景说明

`orderbook-deep-analysis.md` 与本备忘同源于对 `knowledge/OrderBook.md`（v2 草稿）vs binance 实现的对比分析。两份分析在**事实层完全一致**（同步协议已实现、Policy/Demand 抽象未落地、Market State Engine 未实现），但在**优化建议方向上存在实质性分歧**。本备忘记录分歧，供架构决策。

---

## 异议一：草稿 v2 修订说明存在事实性错误（已合并报告未指出）

`orderbook-deep-analysis.md` 给出"同步协议 95% 对齐"的结论，但**未指出草稿自身的矛盾**：

`knowledge/OrderBook.md:401-408` 的 v2 修订说明自称修正了"OrderBook 同步协议缺失"这一缺陷（缺陷 #2），并在 `:152-176` 以"原版完全缺失，这才是 OrderBook 的主体"展开整节论述。但实际实现显示：

- 该同步协议已于 **2026-07-06** 经 ADR-011（Accepted）纳入 v4.0.0，FR-052~061 实现。
- 实现比草稿描述更完整：含 staleness 一等公民、持久化 fast recovery、rebuild 频率告警、双模式互斥——草稿均未涉及。

**结论**：草稿 v2 的修订动机（"补缺失的同步协议"）基于过时认知。草稿 `:152-176` 的"原版完全缺失"是**事实性错误**，应修正为"同步协议已落地，以下为现状审计"。

> 已合并报告说"95% 对齐"暗示草稿设计基本被采纳，但真实情况是**实现走在草稿前面**——方向相反。这是认识论差异，影响对草稿有效性的判断。

---

## 异议二：反对在 binance 落地 PolicyManager（已合并报告 P0 建议方向存疑）

`orderbook-deep-analysis.md` P0 建议 #1-#4 主张新增 `internal/client/policy/manager.go`（~200 行）+ `DynamicAllowed` + `StoragePolicy`/`BusPolicy` struct（~100 行），即把草稿的 PolicyManager 抽象落地为代码。

**本备忘反对该方向**，理由：

### 2.1 语义已等价，无需新抽象

草稿 Policy/Demand 双层的语义已被现有机制覆盖：

| 草稿概念             | 现有实现                                                                                   | 证据                                    |
| -------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------- |
| Policy 静态上界      | `configs/whitelist.yaml`（`orderbook_enabled` + `orderbook_features` + `allowed_streams`） | `whitelist.yaml:18-89`                  |
| Demand 运行时需求    | `configs/strategy_acl.yaml`（per-strategy allowed）+ `configs/features.yaml`（per-module） | `strategy_acl.yaml:6-13`                |
| Demand ⊆ Policy 裁决 | server `OrderbookService.AddEntry` 子集校验（orderbook ⊆ stream whitelist）                | `orderbook_service.go:130-145`          |
| 聚合 → 激活          | `syncWhitelistChanges` → `SyncSubscriptions` 原子增删                                      | `runtime.go:1076`, `manager.go:523-568` |

新增 PolicyManager struct 会与现有 `whitelistclient` + server 白名单 + NATS 同步链路**功能重叠**（Anti-Shadowing / W-1 风险）。

### 2.2 binance 是数据采集器，不应承担策略聚合

按 ZoneCNH 架构（`基座→数据域→分析域⇄决策域→执行域`），binance 属**数据域采集器**。策略动态声明需求（Demand 聚合）是**决策域**职责，放在采集层是职责越界。

草稿 `:179-221` 设想的"Strategy 运行时动态声明 Demand"在当前架构中应由上游决策域驱动，通过 server 白名单 API 表达——这正是现有 `orderbook_whitelist` PG 表 + admin API + NATS 同步的设计。**该设计已经是对草稿 Demand 思想的正确工程化**，无需再在 client 侧加一层 PolicyManager。

### 2.3 真实缺口不是抽象，是配置链路

`orderbook-deep-analysis.md` 把 PolicyManager 列为 P0，但**真正的工程缺口**是：

- **订阅分片**（`stream_control.go:399` 单 URL 全拼接，超 combined stream 上限会静默失败）——已合并报告列为 P1 #5，本备忘认为应升为 **P0**（symbol 扩量前必修，否则静默丢订阅）。
- **DepthLevel 配置断裂**（YAML `WhitelistEntry` 无 `depth_level` 字段，运行时硬编码 L4，`manager.go:388`）——档位定义 L1(10)/L3(100) 悬空，未映射到真实 Binance stream 后缀。

这两项是**可操作的工程缺口**，比新增 ~300 行 PolicyManager struct 的 ROI 更高。

---

## 异议三：Market State Engine 域归属（已合并报告 P2 建议隐含归属错误）

`orderbook-deep-analysis.md` P2 #8-#10 建议 Feature Registry / Feature Scheduler / Market State Engine，工作量标为 binance 内部工程。

**本备忘认为该归属错误**：

- binance 模块当前定位是**采集 + 持久化 + 转发**，OrderBook 维护本地 book 后只产出 `TopNUpdate` + `IncrementalEvent` 发 NATS（`topn.go:6-29`, `runtime.go:1216+`）。
- 实时 Feature 计算（MicroPrice/Imbalance/OFI/VPIN）属**分析域**（`factor_engine`），不应在 binance 实现。
- 草稿 `:414-1332` 的 Market Digital Twin 是**系统级愿景**，正确归属是 `x.go`（Composition Root）或独立 market-state 模块。
- binance 的正确贡献是**提供经过序号校验的增量事件流**——这部分**已实现**（`IncrementalEvent` → NATS → 下游），草稿愿景的"统一事件源"基础已具备。

> 已合并报告把 Feature Engine 列为 binance 的 P2 工程，会误导后续在采集层堆叠分析职责，违背域边界。

---

## 修正后的优化优先级建议

综合本备忘三项异议，建议调整 `orderbook-deep-analysis.md` 的优化优先级：

| 优先级        | 建议项                                                                    | 与已合并报告的差异                                                    |
| ------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **P0**        | 订阅分片（combined stream 上限处理）                                      | 已合并报告列为 P1 #5，**建议升 P0**                                   |
| **P0**        | 修正草稿 `:152-176` 事实性错误（knowledge/ 内）                           | 已合并报告未涉及                                                      |
| **P1**        | DepthLevel 配置链路打通（YAML 加 `depth_level` + 档位映射 stream 后缀）   | 已合并报告 P0 #3 StreamRate 相关，**建议聚焦配置断裂而非新增 struct** |
| **P2**        | options depth 协议确认（ADR-011 待确认项）                                | 已合并报告未涉及                                                      |
| **降级/否决** | PolicyManager / Demand 聚合 / StoragePolicy struct（已合并报告 P0 #1-#4） | **建议否决**——语义已等价，域归属错误，Anti-Shadowing 风险             |
| **降级/否决** | binance 内 Feature Registry / Market State Engine（已合并报告 P2 #8-#10） | **建议否决在 binance 实现**——属分析域，binance 仅提供事件源           |

---

## 认识论声明

- 本备忘事实层结论与 `orderbook-deep-analysis.md` 一致，均来自源码 grep + Read 双重验证 `[COMPUTED]`。
- 优化建议方向的异议属 `[INFERRED]`（基于 ZoneCNH 域边界架构原则的工程推断），置信度 HIGH——域归属判断有 `CLAUDE.md` 架构模型明确支撑。
- 本备忘**未否定**已合并报告的对照工作，仅对其 P0 优化方向提出否决性异议。最终架构决策权在 repo owner。

## 关键证据索引

| 主题                 | 文件                                                            | 关键行               |
| -------------------- | --------------------------------------------------------------- | -------------------- |
| 同步协议已实现       | `internal/client/orderbook/align.go`                            | `:27-94`（9 步对齐） |
| ADR-011 纳入决策     | `module/binance/design/ADR-011-order-book-rebuild-inclusion.md` | Accepted 2026-07-06  |
| 白名单等价 Policy    | `configs/whitelist.yaml`                                        | `:18-89`             |
| 策略 ACL 等价 Demand | `configs/strategy_acl.yaml`                                     | `:6-13`              |
| server 子集校验      | `internal/server/whitelist/orderbook_service.go`                | `:130-145`           |
| 订阅无分片           | `internal/client/stream_control.go`                             | `:399`               |
| DepthLevel 硬编码    | `internal/client/orderbook/manager.go`                          | `:388`               |
| 增量事件源已实现     | `internal/client/orderbook/topn.go`                             | `:6-29`              |
