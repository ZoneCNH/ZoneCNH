# module/_exchange-template — 多交易所接入模板

- Created: 2026-06-25
- Status: Template（骨架，待第二个交易所接入时实例化）
- Source: binance v0.2.0 规范体系
- Related: ZoneCNH/ZoneCNH#1075、评估报告 §7.4#16+#18

---

## 1. 目的

`[FRAME, HIGH]` 本模板把 binance 模块验证有效的规范体系提炼为可复用骨架，供 okx/hyperlinear/coinglass 等同类交易所接入模块快速启动。

binance 是首个完整落地此体系的交易所模块（v0.2.0 生产就绪），其 20 个规范文档 + 13 道 boundary-gates + 6 个运行时控制文档构成完整模板。

---

## 2. 规范文档骨架（从 binance 复制并适配）

接入新交易所时，复制以下文档并替换交易所特定内容：

| 文档 | 用途 | binance 源 | 适配点 |
| --- | --- | --- | --- |
| `SPEC.md` | 23 节完整规格 | binance v3.7.1 | FR/BR/NFR 按交易所能力调整 |
| `FEATURES.md` | FR 实现状态矩阵 | binance | 状态口径 + 装配级证据标准 |
| `TRACEABILITY.md` | FR/BR/AC/TC 追溯 | binance | 矩阵结构复用 |
| `ACCEPTANCE.md` | AC/TC 验收标准 | binance | 按交易所 AC 调整 |
| `BOUNDARY-GATES.md` | 边界门禁定义 | binance §2-§14 + §20 | gate 按模块特性裁剪 |
| `RULES.md` | 命名/矩阵/版本规则 | binance R1-R9 | snake_case 强制 |
| `NAMING.md` | canonical 命名 | binance | product_line/event_type 按交易所 |
| `DATA-LIFECYCLE.md` | 数据生命周期 | binance | 采集/存储/归档/回热 |
| `RUNTIME-MAPPING.md` | docs→runtime 映射 | binance | 路径映射 |
| `CHANGELOG.md` | 变更记录 | binance | Keep-a-Changelog |
| `README.md` | 模块入口 | binance | Delivery-State |

### 运行时控制文档（C7，binance 新增）

| 文档 | 用途 |
| --- | --- |
| `ENDPOINTS.md` | 交易所 mainnet 端点清单 + mainnet-only 策略 |
| `PERSISTENCE-WIRING.md` | storageFromEnv 装配契约 |
| `SECURITY.md` | API 认证/限流/凭据/扫描 |
| `OBSERVABILITY.md` | metrics 语义 + 告警 + SLO |
| `OPERATIONS.md` | 部署/扩缩容/灾恢复 Runbook |
| `DATA-QUALITY-SLA.md` | freshness SLA + stale 告警 |

---

## 3. CI 骨架

```
scripts/boundary-gates.sh      # 边界门禁（参照 binance 13 gates 裁剪）
.github/workflows/build.yml    # go build + vet
.github/workflows/test.yml     # go test + race + cover
.github/workflows/lint.yml     # golangci-lint
.github/workflows/security.yml # gitleaks + govulncheck
.github/workflows/release.yml  # release tag 产物
```

详见 `docs/governance/boundary-gates-cross-module-promotion.md`。

---

## 4. 接入新交易所的步骤

`[FRAME, HIGH]`

1. **创建模块仓** `ZoneCNH/<exchange>` + `module/<exchange>/` 规格目录
2. **复制模板文档**：从本 README §2 表列文档复制，替换 `<exchange>` 占位
3. **定义 product_line**：按交易所产品线（如 okx: spot/swap/futures/option）
4. **定义 endpoints**：交易所 mainnet WS/REST 端点清单
5. **实现 connector**：参照 binance `NewProductLineConnector` 模式
6. **落地 boundary-gates**：按推广指南裁剪 gate 子集
7. **CI 配置**：复制 workflow 骨架 + GOPRIVATE/domain 依赖处理（参照 binance CI 修复）

---

## 5. 触发条件

`[INFERRED, MED]` 本模板在以下条件触发实例化：
- 实际接入第二个交易所（okx/hyperlinear/coinglass）
- 产品线差异增大需插件化 connector

当前 binance 四产品线共享 engine 是合理设计（WS 协议同构），无需插件化。

---

## 6. connector 插件化路径（未来）

若产品线差异增大：
1. 定义 `ConnectorPlugin` 接口（normalize/dispatch/symbol 解析）
2. 每产品线/交易所实现独立 plugin
3. main.go 按 product_line 动态加载 plugin

当前 binance 的 `productLineSpecs` map 驱动差异已足够，无需此层。

---

> 本模板基于 binance v0.2.0（首个生产就绪交易所模块）。待第二个交易所接入时实例化。
