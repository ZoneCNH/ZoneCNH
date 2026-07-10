# Binance 兼容窗口与 sunset 计划

> 状态：Proposed / 需 release owner 批准日期
> 日期：2026-07-10
> 关联：`module/binance/todo.md` §5、`spec/NAMING.md`、`gate/STANDARD.md`

## 1. 当前兼容面

| 兼容项 | canonical 形式 | legacy 形式 | 当前行为 |
| --- | --- | --- | --- |
| TDengine child table | `book_ticker_{symbol}`、`kline_{symbol}`、`depth_update_{symbol}`、`mark_price_update_{symbol}` | `tick_`、`bar_`、`depth_`、`mark_price_` 前缀 | 读取/路由层仍有兼容分支；写入必须只产生 canonical |
| REST/history kind | `book_ticker`、`kline`、`trade`、`depth_update` | `ticks`、`bars`、`trades`、`tick`、`bar`、`depth` | 输入兼容；响应和文档使用 canonical |
| event_type | `book_ticker`、`kline`、`depth_update`、`mark_price_update` | `tick`、`bar`、`depth`、`mark_price` | 仅输入归一化；禁止新消息继续发 legacy subject |

以上清单来自 runtime 兼容代码与 `eventtypes.Canonical`，不是 release 完成声明。[COMPUTED, HIGH]

## 2. 建议窗口

日期是建议值，必须由 release owner 在 release packet 中批准后才成为事实。[INFERRED, MED]

| 阶段 | 建议日期 | 必须动作 | 退出条件 |
| --- | --- | --- | --- |
| 公告/迁移 | 2026-07-10 | 发布 canonical 映射、迁移样例和下游 owner 清单；记录 legacy 命中指标 | 所有活动消费者完成登记 |
| 警告窗口 | 2026-08-01 | legacy 输入继续可读但记录 `legacy_compat_hit{surface,alias}`；新写路径只写 canonical | 连续 14 天无未豁免 consumer |
| 删除窗口 | 不早于 2026-09-01 | 删除 legacy child-table 读取分支和 plural/singular API alias；无命中时才允许切换 | preflight、回滚演练和数据迁移证据全部 PASS |

不具备 owner 批准、命中指标、迁移记录或回滚证据时，禁止删除兼容分支；不得把日期提案写成已发布事实。[INFERRED, HIGH]

## 3. 运行时要求

1. canonical writer/subject/table 是唯一新数据写入面；legacy 只允许读取和输入转换。[COMPUTED, HIGH]
2. 每个 legacy alias 必须有命中计数、来源面和豁免截止日期；无观测数据不得推定为零依赖。[INFERRED, HIGH]
3. 到期删除前，`scripts/spec-runtime-drift-check.sh`、API contract tests、TDengine stable tests 和 release preflight 必须验证没有新 legacy 产出。[INFERRED, HIGH]
4. rollback 必须能把读取策略恢复到上一版本，不得恢复 legacy 写入。[INFERRED, HIGH]

## 4. 证据与验收

release packet 必须绑定：

- alias inventory 与每项 owner；
- 14 天命中指标导出及查询时间；
- 数据/consumer 迁移记录；
- sunset 开关、删除 commit 和回滚 commit；
- 删除前后 canonical-only contract test 与 `git diff --check`。

在这些证据产生前，`todo.md` 的兼容窗口项保持 `BLOCKED_BY_RELEASE_OWNER`，而不是标记 `[x]`。[COMPUTED, HIGH]

[RULES I BROKE]：无
