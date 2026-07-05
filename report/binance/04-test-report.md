# 测试执行报告

> **仓库**：`/home/workspace/binance`
> **测试时间**：2026-07-05
> **测试轮次**：3 轮（单元/集成 → build-tag 测试 → race 检查）

## 1. 测试用例盘点

### 1.1 文件统计

- **主仓库 `_test.go` 文件数**：143 个
- **测试函数总数**：1898 个（`^func Test`）

### 1.2 分布（按目录 Top）

| 目录 | 文件数 | 说明 |
|------|--------|------|
| `internal/client` | 42 | 数据采集客户端核心 |
| `internal/server` | 28 | 服务端核心 |
| `internal/server/storage` | 12 | 存储层 |
| `internal/server/assembly` | 10 | 组装层 |
| `test/e2e` | 6 | 端到端测试（build tag: `e2e`） |
| `test`（根） | 4 | HA/重启/重载/审计集成测试 |
| `pkg/binancex` | 2 | 交易所适配器 |
| `pkg/binancecfg` | 3 | 配置加载 |
| `pkg/whitelistclient` | 2 | 白名单客户端 |
| `internal/ingestcodec` | 1 | 编解码 |

### 1.3 测试分类

| 类别 | build tag | 测试函数数 | 状态 |
|------|-----------|-----------|------|
| 单元测试 | （无） | ~1740 | ✅ 全部 PASS |
| 集成测试 | （无） | 12 | ✅ PASS |
| e2e 测试      | `e2e`      | 18         | ✅ 全部 PASS（2026-07-05 修复冲突测试逻辑） |
| depth 测试 | `depth` | 115 | ✅ PASS |
| chaos 测试 | `chaos` | 12 | ✅ PASS |
| security 测试 | `security` | 9 | ✅ PASS |
| soak 测试 | `soak` | 3 | ⚠️ timeout（环境限制） |

---

## 2. 测试执行结果总览

### 2.1 核心包测试

| # | 包 | 结果 | 测试数 | 耗时 | 备注 |
|---|-----|------|--------|------|------|
| 1 | `pkg/binancex/...` | ✅ PASS | 101 | 0.358s | 覆盖率 100% |
| 2 | `pkg/binancecfg/...` | ✅ PASS | 68 | 0.009s | |
| 3 | `internal/ingestcodec/...` | ✅ PASS | 3 | 0.004s | |
| 4 | `pkg/whitelistclient/...` | ✅ PASS | 16 | 1.119s | |
| 5 | `internal/client/...` | ✅ PASS | — | 43.650s | 含 3 个子包 |
| 6 | `internal/server/...` | ✅ PASS | — | 0.173s+ | 18 个子包全过 |
| 7 | `go vet ./...` | ✅ PASS | — | — | 零告警 |

### 2.2 build-tag 测试

| 包 (tag) | 结果 | 耗时 | 详情 |
|----------|------|------|------|
| `test/depth` (`-tags=depth`) | ✅ PASS | 1.066s | 115 个测试全过 |
| `test/security` (`-tags=security`) | ✅ PASS | 0.013s | 9 个测试全过 |
| `test/chaos` (`-tags=chaos`) | ✅ PASS | 0.459s | 12 个测试全过 |
| `test/e2e` (`-tags=e2e`)           | ✅ PASS    | 0.322s  | 全部通过（2026-07-05 修复） |
| `test/soak` (`-tags=soak`) | ⚠️ TIMEOUT | 60.023s | 长跑测试，60s 超时 |

### 2.3 race 检测（核心包）

| 包 | 结果 | 耗时 |
|----|------|------|
| `pkg/binancex` | ✅ PASS | 1.539s |
| `pkg/binancecfg` | ✅ PASS | 1.038s |
| `internal/ingestcodec` | ✅ PASS | 1.019s |
| `pkg/whitelistclient` | ✅ PASS | 2.143s |

---

## 3. 失败用例详情

### 3.1 ~~TestE2E_ConflictingPayload_Reject~~ ✅ 已修复（2026-07-05）

> **已修复**：修改 `req2.Payload` 内容（而非仅改 PayloadHash 字段），使 server 重算后 hash 不同 → 触发 terminal_conflict。测试 PASS。

```
--- FAIL: TestE2E_ConflictingPayload_Reject (0.00s)
    e2e_test.go:129: second (conflict) should reject
```

**位置**：`test/e2e/e2e_test.go:102-134`

**根因分析**：

测试意图是验证「相同 RequestID + 不同 PayloadHash 触发 `terminal_conflict` 拒绝」。测试通过值拷贝 `req2 = req1` 后手动设置 `req2.PayloadHash = "different-hash"` 来制造冲突。

但 `internal/server/ingest.go:91-92` 存在 GAP-E19 安全加固：

```go
// server 端重算 PayloadHash，避免信任上游传入值（GAP-E19）。
req.PayloadHash = computePayloadHash(req.Payload)
```

server 在 `CheckAndSet` 之前会用 `req.Payload` 重算 PayloadHash，覆盖客户端传入值。由于 `req2 = req1` 是值拷贝，`req2.Payload` 与 `req1.Payload` 完全相同，重算后两者 PayloadHash 一致，因此第二次请求被当作重复请求 ACK 而非冲突拒绝。

**结论**：这是**测试用例自身缺陷**，非生产代码 bug。GAP-E19 加固使「篡改客户端 PayloadHash 触发冲突」这一测试路径失效。修复方式应改为修改 `req2.Payload`（如改变 TradeID/EventTime）使重算后 hash 不同。

**严重程度**：低（测试逻辑问题，不影响生产行为）

### 3.2 test/soak 超时

```
goroutine 20 [select]: TestSoak_ServerStability.func1 ... soak_test.go:581
FAIL    github.com/ZoneCNH/binance/test/soak    60.023s
```

**根因**：`TestSoak_ServerStability` 是设计为长时间运行的服务器稳定性压测，持续并发请求直到外部停止，**没有 `t.Skip` 守卫**。60s 超时是测试环境限制。

**建议**：为该测试添加 `testing.Short()` 跳过守卫。

**严重程度**：低（环境/配置问题）

---

## 4. 测试覆盖率

### 4.1 核心包覆盖率

| 包 | 覆盖率 |
|----|--------|
| `pkg/binancex` | **100.0%** |
| 全仓库（coverage.out） | **89.7%** |

### 4.2 低覆盖函数

| 函数 | 覆盖率 | 包 |
|------|--------|-----|
| `refreshFull` | 77.8% | whitelistclient |
| `refreshIncremental` | 69.6% | whitelistclient |

这两个是涉及 HTTP 往返的刷新逻辑，部分错误分支未覆盖。

---

## 5. 测试用例设计清单（针对 pkg/binancex/adapter.go）

### 5.1 已覆盖测试用例

| # | 场景 | 类型 | 目标方法 | 已覆盖测试 |
|---|------|------|----------|-----------|
| 1 | 市价单正常下单 | 正常 | SubmitOrder | ✅ TestSubmitOrder_Market |
| 2 | 限价单正常下单 | 正常 | SubmitOrder | ✅ TestSubmitOrder_Limit |
| 3 | 止损限价单 | 正常 | SubmitOrder | ✅ TestSubmitOrder_StopLimit |
| 4 | 带 ClientOrderID 下单 | 正常 | SubmitOrder | ✅ TestSubmitOrder_WithClientOrderID |
| 5 | 限价单缺 price | 异常 | SubmitOrder | ✅ TestSubmitOrder_LimitWithoutPrice |
| 6 | Binance API 返回错误码 | 异常 | SubmitOrder | ✅ TestSubmitOrder_APIError |
| 7 | quantity 解析失败 | 异常 | SubmitOrder | ✅ TestSubmitOrder_InvalidQuantityParse |
| 8 | price 解析失败 | 异常 | SubmitOrder | ✅ TestSubmitOrder_InvalidPriceParse |
| 9 | stopPrice 解析失败 | 异常 | SubmitOrder | ✅ TestSubmitOrder_InvalidStopPriceParse |
| 10 | 正常撤单 | 正常 | CancelOrder | ✅ TestCancelOrder_Success |
| 11 | 无效 orderId 撤单 | 异常 | CancelOrder | ✅ TestCancelOrder_InvalidOrderID |
| 12 | 撤单 API 错误 | 异常 | CancelOrder | ✅ TestCancelOrder_APIError |
| 13 | 批量撤单混合结果 | 边界 | CancelOrders | ✅ TestCancelOrders_MixedResults |
| 14 | 正常查询订单 | 正常 | GetOrder | ✅ TestGetOrder_Success |
| 15 | 无效 orderId 查询 | 异常 | GetOrder | ✅ TestGetOrder_InvalidOrderID |
| 16 | 查询 API 错误 | 异常 | GetOrder | ✅ TestGetOrder_APIError |
| 17 | 按 ClientOrderID 查询 | 正常 | GetOrderByClientOrderID | ✅ TestGetOrderByClientOrderID_Success |
| 18 | 响应缺 clientOrderID | 边界 | GetOrderByClientOrderID | ✅ ...EmptyClientOrderIDInResponse |
| 19 | ClientOrderID 查询 API 错误 | 异常 | GetOrderByClientOrderID | ✅ TestGetOrderByClientOrderID_APIError |
| 20 | 正常返回余额 | 正常 | GetBalances | ✅ TestGetBalances_Success |
| 21 | 全零余额 | 边界 | GetBalances | ✅ TestGetBalances_AllZero |
| 22 | 余额 API 错误 | 异常 | GetBalances | ✅ TestGetBalances_APIError |
| 23 | 无凭证健康检查 | 异常 | HealthCheck | ✅ ..._NoCredentials |
| 24 | 无凭证各方法降级 | 异常 | 全部 | ✅ *_NoCredentials 系列 |
| 25 | Stream listenKey 错误 | 异常 | StreamExecutions | ✅ ..._ListenKeyError |
| 26 | WS 拨号失败 | 异常 | StreamExecutions | ✅ ..._WebSocketDialError |
| 27 | WS 读错误 | 异常 | StreamExecutions | ✅ ..._ReadError |
| 28 | 非 trade 消息跳过 | 边界 | StreamExecutions | ✅ ..._NonTradeMessageSkipped |
| 29 | context 取消 | 边界 | StreamExecutions | ✅ ..._ContextCancellation |
| 30 | keepAlive ticker 触发 | 正常 | keepAliveListenKey | ✅ ..._TickerFires |
| 31 | 订单状态全映射 | 边界 | binanceOrderStatusFromResponse | ✅ ..._AllStatuses |
| 32 | 未知订单状态 | 边界 | binanceOrderStatusFromResponse | ✅ ..._UnknownStatus |
| 33 | safeFloat64 Inf | 边界 | safeFloat64 | ✅ TestSafeFloat64_Inf |
| 34 | safeFloat64 NaN | 边界 | safeFloat64 | ✅ TestSafeFloat64_NaN |
| 35 | unixMilli 溢出 | 边界 | unixMilliFromUint64 | ✅ .../overflow |

### 5.2 建议补充的测试用例（当前未覆盖）

| # | 场景 | 类型 | 说明 |
|---|------|------|------|
| G1 | context timeout（网络失败） | 异常 | 用 `httptest.Server` 注入延迟 + 短 ctx timeout，验证返回 context.DeadlineExceeded |
| G2 | 签名错误（invalid secret） | 异常 | 用错误 secret 构造 client，验证 API 返回 -1021 签名错误被正确包装 |
| G3 | 空 symbol 下单 | 异常 | `SubmitOrder` 传 `Symbol=""`，验证返回参数校验错误 |
| G4 | 数量为负 | 边界 | `qty="-0.01"`，验证拒绝 |
| G5 | 价格为 0 | 边界 | LIMIT 单 price=0，验证拒绝 |
| G6 | MIN_NOTIONAL 边界 | 边界 | qty*price < 5 USDT，验证 -1013 错误透传 |
| G7 | 精度超 stepSize | 边界 | qty 精度超过 stepSize，验证 -1111 拒绝 |
| G8 | 最大下单量 | 边界 | qty 超过 MAX_QTY，验证 -1101 拒绝 |

> 说明：G3-G8 目前依赖 Binance 真实 API 校验，单测中以 mock HTTP server 注入对应错误码即可覆盖错误透传逻辑。

---

## 6. 风险评估

| 风险项 | 等级 | 说明 |
|--------|------|------|
| e2e 测试 `TestE2E_ConflictingPayload_Reject` | ✅ 已修复 | 2026-07-05 修复测试逻辑（改 req2.Payload 而非 PayloadHash） |
| soak 测试无 skip 守卫 | 🟡 低 | CI 会 timeout，建议加 `testing.Short()` |
| whitelistclient 覆盖率 69-78% | 🟡 低 | HTTP 重试/退避错误分支未完全覆盖 |
| adapter.go 边界校验前置不足 | 🟡 中 | 空 symbol、负数量等未在 adapter 层前置校验 |
| `go vet` / race 检测 | 🟢 无风险 | 全部通过，零告警 |

### 总体结论

- **核心包（pkg/binancex）质量高**：100% 覆盖率，101 个测试全过，race 检测通过。
- **生产代码无阻断性缺陷**：唯一失败是 e2e 测试用例自身逻辑问题。
- **建议优先处理**：① 修复 `TestE2E_ConflictingPayload_Reject` 测试逻辑；② 为 soak 测试加 skip 守卫；③ 补充 adapter 层参数前置校验及对应单测（G3-G8）。
