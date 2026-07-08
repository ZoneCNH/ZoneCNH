# TASK-FRED-SERVER-002 Query API & Admin API

## Objective

实现 `fred-server` 对外查询服务：Series/Observation/Release/Tag/Category 查询，schema-aware TDengine 旁路查询，幂等写入覆盖审计端点，以及下游 `ms_brain` 标准集成契约。

## Covers

- FR-013（observation/catalog 查询 API + schema-aware TDengine 旁路，子规格: FR-S008）
- FR-015（ms_brain 集成契约，子规格: FR-S009）
- FR-016（全量覆盖审计和缺口扫描端点，子规格: FR-S010）
- FR-011（NATS control plane 查询触发，子规格: FR-S010）
- FR-S011（覆盖审计及缺口管理——API 层，从 TASK-FRED-SERVER-001 独立）
- BR-009（ms_brain 通过 domain_macro 接口消费，不直接访问 fred DB）
- BR-010（全量覆盖审计，分母=SERIES-CATALOG FRED-native 序列，OPEN-CAT-1）

## Scope

- `internal/server/query_handler.go`：Series/Observation/Release/Tag/Category 查询端点
- `internal/server/admin_handler.go`：全量覆盖审计、缺口扫描、Admin reload 端点
- `internal/server/taos_schema.go`：schema-aware TDengine 旁路查询适配
- NATS control plane topic 路由（外部缺口扫描触发）
- ms_brain 集成契约实现（domain_macro 接口层）
- `spec/SERIES-CATALOG.md` 驱动的覆盖率分母计算

## Non-Scope

- TDengine observation 写入（属 TASK-FRED-SERVER-001）
- fred-client 采集逻辑
- Kafka event 发布（属 TASK-FRED-SERVER-001）

## Acceptance Criteria

1. Series/Observation/Release/Tag/Category 查询接口响应时间 < 200ms（p95），schema-aware 旁路自动降级。
2. 全量覆盖审计端点以 `spec/SERIES-CATALOG.md` FRED-native 序列为分母，返回 `{total, covered, missing}` 统计。
3. 缺口扫描端点可通过 NATS control plane 外部触发，结果写入 Postgres coverage_gaps 表。
4. ms_brain 通过 domain_macro 接口消费 fred 数据，不访问 fred 内部 Postgres/TDengine 表；集成契约有单测覆盖。
5. Admin reload 端点幂等，不中断进行中的采集任务。

## Verification Commands

```bash
# 查询 API 单元测试
cd /home/workspace/fred && go test ./internal/server/... -run QueryHandler -count=1
cd /home/workspace/fred && go test ./internal/server/... -run AdminHandler -count=1

# schema-aware 旁路测试（fake）
cd /home/workspace/fred && go test ./internal/server/... -run TaosSchemaAware -count=1

# ms_brain 契约单元测试
cd /home/workspace/fred && go test ./internal/server/... -run BrainContract -count=1

# 覆盖审计端点集成测试（CI-gated，需 dev secret）
cd /home/workspace/fred && FRED_DEV_CONFIG=/home/workspace/ZoneCNH/sre/secrets/env/dev.md \
  go test ./internal/integration/... -run CoverageAuditAPI -count=1 -tags integration

# 外部路由序列 source_component 验证
cd /home/workspace/fred && go test ./internal/server/... -run ExternalRoutingSourceComponent -count=1
```

## Dependencies

- `postgresx`（coverage_gaps 表，查询元数据）
- `taosx`（observation 查询 + schema-aware 旁路）
- `natsx`（control plane topic）
- `domain_macro`（ms_brain 集成契约）
- `spec/SERIES-CATALOG.md`（覆盖率分母权威来源）
