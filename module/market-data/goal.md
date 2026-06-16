# goal: market-data v0.1.0

- Status: Draft
- Created: 2026-06-17
- Owner: ZoneCNH

## 定位

`market-data` 是交易所行情 adapter 与内部行情消费链路之间的接收侧模块。接收 adapter 已归一化的市场事件，执行接收侧校验、幂等判定、排序键约束和分发结果表达。

## 目标

- 定义 DownstreamDispatchPort 接收侧端口语义
- 定义 AcceptedMarketEvent 输入契约
- 定义 DispatchAck/DispatchReject/DispatchFailure 三级 outcome 分类
- 提供 FR/BR/NFR 完整需求覆盖
- 暴露按 venue/productLine/channel/outcome/reason 维度的可观测性要求

## 边界

| 类型 | 说明 |
| --- | --- |
| Owns | downstream dispatch port 语义、接收侧校验、幂等键约束、排序键约束、ack/reject/failure 分类、分发可观测性要求 |
| Depends on | module/domain-market canonical MarketFactEnvelope/ProductLine/InstrumentKey 语义；module/contracts IngestRequest/IngestResult wire contract |
| Consumed by | module/binance 与其他交易所 adapter |
| Excludes | 交易所 HTTP/WS adapter、provider DTO、gRPC/protobuf 实现、Kafka/NATS/DB 实现、策略/回测/执行逻辑 |

## 不做什么

- 不实现 transport adapter（HTTP、WebSocket、Kafka producer/consumer）
- 不定义 proto/gRPC schema（由 module/contracts 拥有）
- 不拥有 storage engine
- 不暴露 query API
- 不实现策略、因子或回测逻辑
- 不连接远程服务、不读取密钥
