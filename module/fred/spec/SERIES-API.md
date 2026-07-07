# fred 系列 API 路由接口（source_component）

> 范围：定义 `fred` 如何通过 `source_component` 区分 **FRED-native** 序列与 **外部路由** 序列，并给出路由 API 行为、领域模型语义、集成测试用例与运行时映射。
> 关联：
> - `spec/SPEC.md` §7（公共 API 契约）、§9（领域共享层）、§9.2（`ms_brain` 初始数据契约）
> - `spec/SERIES-CATALOG.md` §11（外部路由实施细节）
> - `spec/ACCEPTANCE.md` TC-011、V-017
> - `design/RUNTIME-MAPPING.md` §5

---

## 1. 路由语义总览

`fred` 的公共 API 必须让下游明确知道：某个序列的**真实权威来源**是 FRED 本身，还是 FRED 仅是检索渠道（如欧/日央行资产负债表）。该信息通过 `source_component` 表达。

| 路由类型 | 真实权威 | `provider` | `source_component` | fred 角色 |
| --- | --- | --- | --- | --- |
| **FRED-native** | FRED | `FRED` | `FRED` | 系统记录：revision/vintage + no-lookahead |
| **外部路由** | 其他机构（ECB / BoJ 等） | `FRED`（检索渠道） | `ECB` / `BoJ` / ... | 非系统记录：取数/登记指针，交上游数据域 |

> 规则：当 `source_component != "FRED"` 时，下游不得把该序列视为 FRED 完整采集的一部分，也不得对其实施 FRED-style vintage 断言。

---

## 2. 领域模型（复用 `domain_macro`）

`MacroSeries.source` 同时承担"真实权威"语义，`provider` 仅表示数据被 fred 从哪个渠道取回。

| 字段 | 含义 | 示例 |
| --- | --- | --- |
| `provider` | 检索渠道 | `"FRED"`（所有 fred 服务输出统一为 FRED） |
| `source` | 真实权威（即 `source_component`） | `"FRED"` / `"ECB"` / `"BoJ"` / `"Treasury.gov"` |
| `source_component` | API 显式路由标记 | 与 `source` 一致；新增序列或修复时以此字段驱动路由 |

`MacroObservation` 透传 `source`；`MacroRevision` 仅对 `source == "FRED"` 序列做 FRED vintage 断言。外部路由序列的修订版本由对应权威源的契约描述，fred 不生成 `MacroRevisionObserved`。

---

## 3. 路由 API 接口

### 3.1 `GetSeries` —— 单序列元数据与路由标记

| 属性 | 说明 |
| --- | --- |
| 请求 | `provider`, `series_id` |
| 响应 | `MacroSeries`（含 `provider` + `source` + `source_component`） |
| 约束 | 若 `source_component != "FRED"`，响应必须显式携带 `source_component` 与 `external_source_url`（指向真实权威端），不得隐藏为 FRED-native |

**请求示例**：

```json
{
  "provider": "FRED",
  "series_id": "ECBASSETSW"
}
```

**FRED-native 响应示例**：

```json
{
  "provider": "FRED",
  "source": "FRED",
  "source_component": "FRED",
  "series_id": "GDPC1",
  "title": "Real Gross Domestic Product",
  "frequency": "Quarterly",
  "units": "Billions of Chained 2017 Dollars",
  "seasonal_adjustment": "Seasonally Adjusted Annual Rate",
  ...
}
```

**外部路由响应示例**：

```json
{
  "provider": "FRED",
  "source": "ECB",
  "source_component": "ECB",
  "series_id": "ECBASSETSW",
  "title": "ECB: Total Assets Euro Area ( Consolidated )",
  "frequency": "Weekly",
  "external_source_url": "https://www.ecb.europa.eu/mopo/implement/omt/html/index.en.html",
  "route": "EXTERNAL"
}
```

### 3.2 `GetCatalogCoverage` —— 覆盖审计与外部路由分母

| 属性 | 说明 |
| --- | --- |
| 请求 | `as_of`, `domain_filter`（可选）, `include_external`（bool） |
| 响应 | `coverage_ratio`, `native_count`, `missing_native`, `external_routed_count`, `external_routed_list`, `last_sync_cursor` |
| 约束 | `coverage_ratio` 仅基于 FRED-native 序列计算；`external_routed_count` 单列，不混入分母 |

**响应字段含义**：

| 字段 | 含义 |
| --- | --- |
| `native_count` | 已采集的 FRED-native 序列数 |
| `native_total` | FRED-native 目标总数（来自 `spec/SERIES-CATALOG.md` §10） |
| `coverage_ratio` | `native_count / native_total` |
| `missing_native` | 缺失的 FRED-native 序列列表，含建议回补优先级 |
| `external_routed_count` | 已采集/登记的外部路由序列数 |
| `external_routed_list` | 外部路由序列清单（含 `source_component`），不计入 FRED 完整性 |
| `last_sync_cursor` | 最后成功游标 |

### 3.3 `QueryObservations` —— 支持按 source 过滤

| 请求字段 | 说明 |
| --- | --- |
| `series_id` | 序列 ID |
| `time range` | 时间区间 |
| `vintage selector` | vintage 选择（仅对 FRED-native 有效） |
| `as_of` | no-lookahead 查询时点 |
| `source_filter` | 可选：只返回 `source` 在指定列表的观测 |
| `include_external` | 默认 `false`；为 `true` 时显式包含外部路由序列 |

**约束**：外部路由序列的 `as_of` 仍以 FRED retrieval 可见时间为准，但 no-lookahead 语义由 fred 执行；下游若需要权威源的 PIT 语义，应路由到上游数据域。

---

## 4. 配置：authority registry

`fred` 通过配置（来自 `sre/secrets/env/dev.md` 经 `configx` 映射）维护一个 **authority registry**，用于判定每个 `series_id` 的真实权威来源。

```yaml
# 配置示例（仅说明键类别，不保存 secret 值）
fred:
  authority_registry:
    - series_id: ECBASSETSW
      source_component: ECB
      route: EXTERNAL
      upstream_module: "domain_macro/ecb"   # 非强制：路由建议
    - series_id: JPNASSETS
      source_component: BoJ
      route: EXTERNAL
    - series_id: GDPC1
      source_component: FRED
      route: NATIVE
    # ... 其余目录序列默认 route: NATIVE
```

**规则**：
- 未命中 registry 的 `series_id` 默认按 `source_component: FRED` 处理（NATIVE）。
- registry 变更需走配置 reload，并通过 NATS admin `ReloadConfig` 生效（SPEC §7 API）。
- 边界 gate 必须校验：registry 中 `route: EXTERNAL` 的序列不得被计入 "FRED 完整采集" 断言。

---

## 5. 错误码

| 错误码 | 触发场景 | 响应行为 |
| --- | --- | --- |
| `ROUTE_EXTERNAL` | 查询外部路由序列但请求缺少 `include_external=true` | 返回 200 + `source_component` 与 `external_source_url`，观测体为空；不报错 |
| `VINTAGE_NOT_SUPPORTED` | 对外部路由序列请求 vintage/revision 语义 | 返回 400，提示"外部路由序列不支持 FRED vintage 断言" |
| `AUTHORITY_NOT_FOUND` | registry 未配置且无法从 FRED 元数据推断 `source` | 按 `FRED` 默认处理，并记录 warning metric |
| `UPSTREAM_ROUTING_FAILED` | fred 经 FRED 端点无法取回外部路由序列，需转交上游 | 返回 202 已登记 + 异步路由事件，不阻塞 API |

---

## 6. 外部路由集成测试用例（IT-ROUTING-001..004）

| ID | 目标 | 前置条件 | 触发条件 | 期望结果 | 验证命令 | 覆盖需求 |
| --- | --- | --- | --- | --- | --- | --- |
| **IT-ROUTING-001** | `GetSeries` 对 ECBASSETSW/JPNASSETS 返回 `source_component=ECB/BoJ` | authority registry 配置 ECBASSETSW/JPNASSETS 为 EXTERNAL | 调用 `GetSeries` | 响应 `provider="FRED"`、`source_component="ECB"`/`"BoJ"`、`route="EXTERNAL"`，并含 `external_source_url` | `go test ./internal/server/... -run ExternalRoutingGetSeries` | FR-013、BR-001 |
| **IT-ROUTING-002** | `GetCatalogCoverage` 分母不包含外部路由序列 | 目录已注册 ECBASSETSW/JPNASSETS 为 EXTERNAL，其余 native | 调用 `GetCatalogCoverage` | `coverage_ratio = native_count / native_total`，`external_routed_count=2` 且单列；外部序列不出现在 `missing_native` | `go test ./internal/integration/... -run ExternalCoverageDenominator` | FR-016、BR-010 |
| **IT-ROUTING-003** | 外部路由序列不触发 FRED vintage/revision 断言 | ECBASSETSW 已采集 | 调用 `QueryObservations` 带 vintage selector | 返回 `VINTAGE_NOT_SUPPORTED` 或 vintage 字段为空；不生成 `MacroRevisionObserved` | `go test ./internal/server/... -run ExternalNoVintage` | FR-005、BR-003 |
| **IT-ROUTING-004** | authority registry reload 后路由判定可热切换 | 初始 JPNASSETS 为 NATIVE，reload 后改为 EXTERNAL | 调用 NATS admin `ReloadConfig` 后查询 `GetSeries` | reload 后响应 `source_component="BoJ"`/EXTERNAL；reload 前仍返回 FRED-native | `go test ./internal/integration/... -run AuthorityRegistryReload` | FR-013、FR-011 |
| **IT-ROUTING-005** | `source_component` 透传至 `MacroObservation` 与 Kafka event | ECBASSETSW 已采集 | 消费 `MacroObservationUpserted` 事件 | 事件 payload 中 `source="ECB"`，下游可据此路由到对应上游域 | `go test ./internal/integration/... -run ExternalEventSourceComponent` | FR-010、BR-004 |
| **IT-ROUTING-006** | 边界 gate 阻止外部路由序列被误写入"FRED 完整采集"断言 | CI 脚本已扫描 `scripts/boundary-gates.sh` | 运行 `bash scripts/boundary-gates.sh` | 外部路由序列（ECBASSETSW/JPNASSETS）不出现在 FRED 完整性断言硬编码清单中 | `bash scripts/boundary-gates.sh` | FR-014、BR-001 |

---

## 7. 与运行时映射

| 模块文档 | Runtime 目标 | 说明 |
| --- | --- | --- |
| `spec/SERIES-API.md` 路由判定 | `internal/domain/source_router.go` | 基于 authority registry 判定 `source_component` |
| `GetSeries` 路由响应 | `internal/server/api/series.go` | 返回 `source_component` 与 `external_source_url` |
| `GetCatalogCoverage` 外部路由分母 | `internal/server/api/coverage.go` | 分母仅 native，单列 `external_routed_count` |
| `QueryObservations` vintage 校验 | `internal/server/query/no_lookahead.go` | 外部路由序列拒绝 vintage 断言 |
| authority registry 配置 | `config/fred-server` | 来源 `sre/secrets/env/dev.md` 经 `configx` 映射 |
| 集成测试 | `internal/integration/...` | IT-ROUTING-001..006 对应 Go 测试 |

---

> 所有 secret 仅引用 `sre/secrets/env/dev.md` 键名，不保存值；本文件不引入新 FR/BR/AC/TC 编号，仅细化 §7 公共 API 与 §9 领域模型的路由语义。集成测试用例在 `spec/ACCEPTANCE.md` 注册为 TC-011 / V-017。
