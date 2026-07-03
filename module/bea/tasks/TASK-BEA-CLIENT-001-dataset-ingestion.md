# TASK-BEA-CLIENT-001：三层数据集采集与调度

- Status: Planned
- Owner: bea-client
- Depends-On: TASK-BEA-001
- Source: `spec/SPEC.md` §5/§6、`plan/PLAN.md`

## 目标

实现 BEA 三层数据集的参数驱动采集、限流退避、发布日历触发与增量同步主路径。

## Scope

1. `GetDataSetList/GetParameterList/GetParameterValues/GetData` 采集编排。
2. 第一层必采（NIPA/GDPbyIndustry/Regional）全量 + 增量。
3. 第二层与第三层按优先级接入调度器。
4. 速率限制与错误熔断（100 req/min、100MB/min、30 errors/min）。
5. 发布日历触发优先，轮询兜底。

## Non-Scope

- 不实现 server 多存储落地。
- 不实现分析报告展示层。

## 验收

- 数据集目录和参数目录完整输出。
- 增量任务可推进游标。
- 限流与熔断策略在压力测试可触发。

