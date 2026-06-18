# bootstrap Goal

- Status: Active
- Last-Updated: 2026-06-18
- Target-Version: v0.1.x -> v0.2.0
- Runtime-Repo: /home/bootstrap
- Layer: L1 Assembly
- Source: SPEC.md, TRACEABILITY.md

## 1. 目标

bootstrap 的目标是把服务入口重复胶水收敛为一个可审计、可复用、可边界约束的 Build/Run/Shutdown 装配层。它只负责配置、观测、弹性、生命周期和可选存储客户端的组装，不承载业务语义、采集逻辑、传输协议服务端或跨进程编排。

## 2. 成功标准

| ID | 成功标准 | 追溯 |
| --- | --- | --- |
| G-BS-001 | adapter 进程可以用 `Build(ctx, Spec{Stores: None})` 获得可运行 App，且默认不构造任何存储连接 | FR-001, FR-004, BR-005, NFR-005, AC-001, AC-004 |
| G-BS-002 | configx、observex、resiliencx 与 lifecycx 的入口初始化口径统一，暴露可审计的 ConfigHash | FR-002, FR-003, FR-005, FR-006, FR-007, FR-008, AC-002, AC-003 |
| G-BS-003 | bootstrap 不依赖 domain、contracts、数据域子模块或 server listener，依赖方向只向下 | BR-001, BR-002, BR-003, BR-004, AC-005 |
| G-BS-004 | 存储位掩码明确表达 None、All 与部分组合；非 None 仅供聚合进程使用 | FR-004, BR-006, BR-007, AC-004 |
| G-BS-005 | v0.1.1/v0.2.0 前关闭 foundationx 遗留依赖，并为非 None 存储组合补足测试证据 | OQ-004, TASK-BS-005, AC-006 |

## 3. 非目标

- 不实现 HTTP/gRPC server、router、中间件或协议绑定。
- 不实现业务领域 DTO、事件、因子、订单、策略或风控语义。
- 不实现数据采集、清洗、回放或跨进程 composer。
- 不替代各存储适配器自己的配置、连接池、查询或迁移能力。

## 4. 当前发布状态

| 版本 | 状态 | 范围 |
| --- | --- | --- |
| v0.1.0 | 已发布，需复验归档 | Build/Run/Shutdown 基线、Stores=None、基础 boundary gate |
| v0.1.1 | 建议修复 | 移除 foundationx 遗留依赖，保持 API 不破坏 |
| v0.2.0 | 准入目标 | Stores=All、TD/PG 部分组合、聚合进程非 None 冒烟和 Spec Approved |

## 5. 风险与约束

- SPEC 当前仍为 Draft，运行时代码扩展必须受文档批准状态约束。
- 非 None 存储组合未完成前，不得把 bootstrap 视为聚合进程完整存储装配层。
- 当前文档只记录目标与追溯闭合，不替代 `/home/bootstrap` 的最新 CI、race、vet、coverage 与 boundary gate 证据。
