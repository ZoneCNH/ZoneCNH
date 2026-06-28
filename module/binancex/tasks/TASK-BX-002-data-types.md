# TASK-BX-002 Data Types

## Objective

实现 `FeedEvent`、`StreamSpec` 和相关数据类型的定义与校验。

## Scope

- `FeedEvent`: 11 字段标准化行情事件，使用 canonical domainmarket 类型
- `StreamSpec`: 逻辑流订阅描述（InstrumentKey/Channel/Interval）
- 所有公开类型不含 vendor SDK 字段

## Covers

- FR-BX-002 (FeedEvent)
- FR-BX-004 (StreamSpec)

## Deliverables

- `FeedEvent` 结构体含 InstrumentKey(domainmarket.InstrumentKey)/EventType(domainmarket.EventType)
- `StreamSpec` 结构体含 InstrumentKey/Channel/Interval
- 类型文档注释完整

## Acceptance Criteria

1. FeedEvent 含全部 11 个字段
2. InstrumentKey 使用 `domainmarket.InstrumentKey` 类型
3. EventType 使用 `domainmarket.EventType` 类型
4. StreamSpec 含 InstrumentKey/Channel/Interval 三字段
5. 所有类型不含 vendor SDK 命名或原始响应字段

## Dependencies

- `runtime-patches/domain-market` (canonical types)
