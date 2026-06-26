# module/binance/server SECURITY.md — Security Controls Standard

## Metadata

| Field | Value |
| --- | --- |
| Status | Active |
| Module-Version | v3.7.1 |
| Last-Updated | 2026-06-25 |
| Scope | `module/binance` API 认证、限流、凭据管理、漏洞扫描流程 |
| Spec-Impact | FR-028（API 认证）+ NFR 安全性要求 |
| Source | `cmd/binance-server/main.go`、`internal/server/api/`、`pkg/binancecfg/` |

> [FRAME, HIGH] 本文档定义 binance 模块的安全控制规范：凭据经 configx 流转（禁止硬编码/裸 os.Getenv）、API Bearer 认证、限流、定期漏洞扫描。

## 1. Scope

[FRAME, HIGH] 覆盖：凭据生命周期（加载→使用→遮蔽→扫描）、API 访问控制、限流策略、依赖漏洞扫描流程。

[FRAME, HIGH] 不覆盖：交易所 API key 的获取与轮换（SRE 运维范畴）、网络层 TLS/mTLS（infra 仓范畴）。

## 2. 凭据管理（C7 核心）

[COMPUTED, HIGH] 凭据流转路径（单一权威源）：
1. **加载**：`binancecfg.Load(ctx)` 经 configx 从 `FOUNDATIONX_*` 环境变量加载
2. **类型**：所有凭据字段为 `configx.SecretString`（自动遮蔽日志/JSON/Sanitize）
3. **使用**：经 `.Reveal()` 解包传给 infra client（**严禁 `.String()`——返回 `***`**，见 `server/docs/PERSISTENCE-WIRING.md` §4）
4. **存储**：`.env`（本地 dev）已被 `.gitignore` 排除（commit `e02b190`）；`sre/secrets/` 不进 git

[FRAME, HIGH] 禁止事项：
- 禁止在 Go 源码硬编码任何凭据（API key/secret/password/token）
- 禁止用裸 `os.Getenv` 读取凭据字段（非凭据控制开关如 MODE/SMOKE 可用）
- 禁止把 `.env` 提交到 git
- 禁止在日志/错误信息/commit message 中输出真实凭据值

## 3. API 认证（FR-028）

[COMPUTED, HIGH] Gin REST API 用 Bearer token 认证：
- 配置：`FOUNDATIONX_BINANCE_API_TOKEN`（SecretString）
- 验证：`internal/server/api/` 中间件校验 `Authorization: Bearer <token>`
- 未设置 token 时：API 端点返回 401（fail-closed，非 fail-open）

[FRAME, HIGH] 健康检查端点（`/healthz`、`/readyz`、`/metrics`）豁免认证（Prometheus scrape 与 k8s probe 需要）。

## 4. 限流

[FRAME, HIGH] API 限流策略（NFR）：
- 默认 1000 req/min（per-IP）
- 超限返回 429 + `Retry-After` header
- 实现位置：`internal/server/api/` 限流中间件（若已实现；否则标注 TODO）

[INFERRED, MED] 当前限流实现状态需核实——本规范定义目标，实际实现以 runtime 代码为准。

## 5. 漏洞扫描流程

[FRAME, HIGH] 定期安全扫描（release gate）：

| 扫描类型 | 工具 | 频率 | 阈值 |
| --- | --- | --- | --- |
| Go 依赖漏洞 | `govulncheck ./...` | 每次 release + CI | 零 HIGH/CRITICAL |
| 凭据泄露 | `gitleaks detect` | 每次 commit（pre-commit hook） | 零命中 |
| 静态分析 | `golangci-lint run` | 每次 CI | 零 error |

[FRAME, HIGH] 发现漏洞的处理流程：
1. HIGH/CRITICAL：阻断 release，创建 hotfix branch
2. MEDIUM/LOW：记录到 ARCHITECTURE-DRIFT-WATCHLIST.md，下个 release 修复
3. 依赖升级：经 `go get -u` + 全量 `go test ./...` 验证后合入

## 6. Evidence Gates

[FRAME, HIGH] 安全控制就绪的证据要求：

| Gate | 证据 |
| --- | --- |
| 凭据遮蔽 | `binancecfg.Config` 所有凭据字段为 SecretString |
| git 无凭据 | `.gitignore` 排除 `.env`；`gitleaks detect` 零命中 |
| API 认证 | Bearer token 中间件存在且 fail-closed |
| 漏洞扫描 | `govulncheck ./...` 零 HIGH/CRITICAL（release evidence） |

## 7. Document Synchronization

[FRAME, HIGH] 本文档与 `SPEC.md` §11（配置）、`ACCEPTANCE.md` 安全相关 AC 同步。
