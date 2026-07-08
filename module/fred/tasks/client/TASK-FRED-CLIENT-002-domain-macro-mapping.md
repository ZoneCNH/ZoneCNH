# TASK-FRED-CLIENT-002 domain_macro Mapping

## Objective

实现 FRED DTO 到 `domain_macro` 的稳定映射，确保 observation + catalog（category/tag/source）所需字段完整且携带正确的时间可见性语义（no-lookahead）。

## Covers

- FR-005（domain_macro 归一化 + available_at 信息集时间，子规格: FR-C004）
- FR-003（外部路由序列 source_component 标记）
- BR-001（不输出 provider DTO 作为跨模块契约，子规格: BR-C001）
- BR-003（available_at no-lookahead 判定，子规格: BR-C003）
- BR-008（不依赖 macro_data 内部包）
- FR-C007（缺配置键时 fail-fast，子规格: 同 FR-003 边界）
- FR-C008（日志/指标带 job_id/series_id/request_id 关联字段）

## Scope

- `internal/domain/models.go`：MacroSeries/MacroObservation/MacroRelease 等领域模型
- `internal/client/normalizer.go`：FRED DTO → domain_macro 映射
- `internal/client/ingester.go`：available_at/released_at/vintage_at 三时间戳填充
- `pkg/fredx/normalizer.go`：归一化辅助函数
- fail-fast 配置校验（缺必要键时 startup 失败，输出键名）
- 结构化日志关联字段注入（job_id/series_id/request_id）

## Non-Scope

- NATS 发布（属 TASK-FRED-CLIENT-001）
- OSS 归档（属 TASK-FRED-CLIENT-001）
- server 侧持久化
- domain_macro 包本身（只消费不修改）

## Acceptance Criteria

1. 映射结果包含 `released_at`/`available_at`/`vintage_at`/`observed_at` 四字段，且 `IsVisibleAt()` no-lookahead 断言通过。
2. 不输出 provider DTO（如 `pkg/fredx` 原始响应类型）作为外部契约；出域模型统一为 `domain_macro` 类型。
3. category/tag/source 元数据映射具备单测覆盖。
4. 缺少必要配置键时，服务启动 fail-fast，日志输出具体缺失键名（可通过 `-run FailFastMissingConfig` 验证）。
5. 所有采集日志与指标携带 `job_id`、`series_id`、`request_id` 关联字段（可通过结构化日志字段解析验证）。

## Verification Commands

```bash
# 领域映射单元测试
cd /home/workspace/fred && go test ./internal/domain/... -count=1
cd /home/workspace/fred && go test ./internal/client/... -run DomainMacroMapping -count=1

# no-lookahead 可见性验证
cd /home/workspace/fred && go test ./internal/domain/... -run IsVisibleAt -count=1

# fail-fast 配置键缺失验证
cd /home/workspace/fred && go test ./internal/client/... -run FailFastMissingConfig -count=1

# 结构化日志字段验证
cd /home/workspace/fred && go test ./internal/client/... -run StructuredLogFields -count=1

# normalizer SDK 测试
cd /home/workspace/fred && go test ./pkg/fredx/... -count=1
```

## Dependencies

- `domain_macro`（MacroSeries/MacroObservation 等领域模型）
- `pkg/fredx`（FRED SDK，仅消费）
- `observex`（结构化日志和指标）
