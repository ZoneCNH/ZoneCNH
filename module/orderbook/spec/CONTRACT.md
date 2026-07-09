# orderbook Contract

> Status: Approved
> Version: v0.1.0

## Adapter Contract

`SnapshotLoader` 加载 venue depth snapshot。[FRAME, HIGH]

`DiffSubscriber` 提供 diff stream，不拥有 book mutation。[FRAME, HIGH]

`SequencePolicy` 判断 diff 连续性，支持 range sequence 与 prev-link sequence。[FRAME, HIGH]

`ExchangeSemantics` 声明 `qty=0` 是否删除档位、sequence 形态和 product line。[FRAME, HIGH]

## Runtime Contract

`Book` 按 side + canonical price 维护档位，输出 deterministic snapshot。[FRAME, HIGH]

`BookHash` 基于 instrument、venue、update id、排序后的 bid/ask levels 生成 sha256。[FRAME, HIGH]

`ReplayRunner` 以 fixture 为输入，输出 state、hash、gap events、quality timeline。[FRAME, HIGH]

## Boundary Contract

`orderbook` runtime 不 import venue internal 包，不连接交易所，不读写密钥，不发布到消息队列。[FRAME, HIGH]

[RULES I BROKE]：无
