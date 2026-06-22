# module/binance 业务类型覆盖深度分析

- Report-Date: 2026-06-22
- Scope: `module/binance/`
- Method: 读取 `SPEC.md`、`TRACEABILITY.md`、client/server 子规格、任务文档与本地 runtime 验证结果，按“规格包含”“任务规划”“当前落地状态”分层判断。
- Confidence: HIGH

## 结论摘要

[COMPUTED][HIGH] `module/binance/` 在规格层明确覆盖 Spot、USDⓈ-M Futures、COIN-M Futures、Options 四条 Binance 产品线。
[COMPUTED][HIGH] 订单簿/订单薄在本模块中被建模为行情数据类型 `depth`，不是交易执行或下单系统。
[COMPUTED][HIGH] 当前文档已统一产品线枚举为 `spot` / `um_perp` / `cm_perp` / `options`，并在 client connector、server storage、Kafka topic 和 Gin API 参数中补齐四产品线口径。
[COMPUTED][HIGH] 当前落地状态不是全量实现：root/client/server 追溯矩阵中产品采集、存储、缓存、API、OLAP 和归档类 FR 仍为 Pending；已被 runtime 证明的是边界 gate、适配器编译和基础 smoke/test。

## 覆盖矩阵

| 类型 | 是否包含 | 规格/任务覆盖 | 当前实现证明 |
|---|---|---|---|
| Spot | 是 | `spot` connector、subject、storage tag、topic、API 参数均覆盖 | 业务 FR 仍待追溯矩阵证明 |
| USDⓈ-M Futures | 是 | `um_perp` connector、subject、storage tag、topic、API 参数均覆盖 | 业务 FR 仍待追溯矩阵证明 |
| COIN-M Futures | 是 | `cm_perp` connector、subject、storage tag、topic、API 参数均覆盖 | 业务 FR 仍待追溯矩阵证明 |
| Options | 是 | `options` connector、subject、storage tag、topic、API 参数均覆盖；Options depth 已补入 client/root 口径 | 业务 FR 仍待追溯矩阵证明 |
| Depth | 是，但不是产品线 | 作为 `depth` 行情事件进入采集、传输、存储、缓存、API 与 fanout 规划 | 具体业务路径仍待实现测试证明 |
| 订单执行 / 下单 | 否 | 规格明确排除交易决策、交易执行和订单执行 | 无实现目标 |

## 已修复的文档缺口

[COMPUTED][HIGH] 产品线枚举不一致已在文档层收敛到 `spot` / `um_perp` / `cm_perp` / `options`。
[COMPUTED][HIGH] Options depth 缺漏已在根 SPEC/root TRACEABILITY/client task/server task 口径中补齐。
[COMPUTED][HIGH] 追溯状态冲突已修正：root FR-001 不再声称现货 connector 已完成，client/server 业务 FR 继续保持 Pending。
[COMPUTED][HIGH] 子规格版本不一致已修正：client TRACEABILITY 指向 `client/SPEC.md` v2.1.1；server TRACEABILITY 指向 `server/SPEC.md` v2.1.0。

## 剩余风险

[COMPUTED][HIGH] 产品能力实现仍是主 backlog：Spot/USDⓈ-M/COIN-M/Options connector、natsx publish/consume、redisx/taosx/postgresx/clickhousex/ossx/Gin/kafkax 业务路径还没有被追溯矩阵标为 Implemented。
[COMPUTED][HIGH] `github.com/ZoneCNH/decimalx@v1.0.0` 的远端发布/校验链路仍需治理；本地 `replace` 能通过开发测试，但不能证明无 replace 的外部消费者可拉取。
[COMPUTED][MED] 后续若新增 product_line 或 event_type，需要用结构化检查守住 SPEC、TRACEABILITY、client task、server task、topic/API 参数的一致性。

## Runtime 核对结果

[COMPUTED][HIGH] 本地 runtime 核对已完成，结果如下：

| # | 核对事实 | 结果 | 证据 |
|---|---|---|---|
| 1 | Binance runtime 基础代码可编译 | 通过 | `/home/binance` 执行 `go test ./...` 通过 |
| 2 | `BinanceAdapter` 满足 `domain_exchange.VenueAdapter` | 通过 | `/home/binance/pkg/binancex` 测试通过；execution 方法使用 `VenueExecution` |
| 3 | C/S 边界 gate 可真实运行 | 通过 | `/home/binance/scripts/boundary-gates.sh` 输出 10 passed, 0 failed |
| 4 | 旧 `internal/cs` / 同进程 adapter 已移除 | 通过 | runtime SHA `bae80d6` 删除 `internal/cs/`；CI [boundary-gates.yml](https://github.com/ZoneCNH/binance/actions/workflows/boundary-gates.yml) §5、§6 自动验证；runtime 迁移为 `internal/wire` |
| 5 | `domain_market` 与 `domain_exchange` 适配当前 `decimalx` API | 通过 | `/home/domain-market` 与 `/home/domain-exchange` 执行 `go test ./...` 通过 |
| 6 | Binance runtime 直接依赖 gate 通过 | 通过 | boundary gate §11 通过；`natsx/redisx/postgresx/taosx/clickhousex/kafkax/ossx/gin` 保持 direct 依赖 |

## 最终判断

[COMPUTED][HIGH] 若问题是“业务范围是否包含现货、合约、期权、订单簿”，答案是包含前三类产品线和订单簿行情；订单簿是 `depth` 行情，不是下单/交易执行。
[COMPUTED][HIGH] 若问题是“是否已经全部实现”，答案是否定的；当前能证明的是边界和基础适配已通过，本地业务全链路仍待实现与追溯矩阵证明。

[RULES I BROKE]：无
