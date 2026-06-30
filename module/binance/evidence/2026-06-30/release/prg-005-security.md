# PRG-005: Security 验证

| 字段 | 值 |
|------|-----|
| 日期 | 2026-06-30 |
| 验证人 | PRG gate agent |
| 结论 | **Partial** |

## 验证命令

```bash
grep -E "secret|govulncheck|gitleaks" Makefile
make secret
make govulncheck
```

## 证据

### Makefile 安全 Target

| Target | 工具 | 状态 |
|--------|------|------|
| `make secret` | gitleaks | target 存在，本地 gitleaks 未安装（skipped） |
| `make govulncheck` | govulncheck | target 存在，已执行 |
| `make vuln-scan` | secret + govulncheck | 聚合 target |
| `make all` | 全量门禁含 secret-scan | 已集成到 `make all` |

### CI Security Workflow

| Workflow 文件 | 职责 | Runner |
|---------------|------|--------|
| `.github/workflows/secrets-scan.yml` | gitleaks 全历史 + 工作目录扫描 | self-hosted |
| `.github/workflows/security.yml` | gitleaks 凭据扫描 + govulncheck CVE 扫描 | self-hosted |
| `.github/workflows/vuln-scan.yml` | govulncheck + go mod audit | self-hosted |

三个 security workflow 均配置完毕，指定 `runs-on: [self-hosted, Linux, X64, ci-go]`。（注：因 PRG-001 runner 未注册，这些 workflow 当前无法实际执行。）

### gitleaks 扫描结果

```
gitleaks not installed; skipping
```

本地未安装 gitleaks，Make target 优雅跳过。CI workflow（secrets-scan.yml）使用 `gitleaks/gitleaks-action@v2` action，配置 `.gitleaks.toml` 规则文件。仓内零凭据声明：所有 infra 连接凭据存放于 `sre/secrets/env/dev.md`（`.gitignore` 排除 `/sre/`）。

### govulncheck 扫描结果

**2 个漏洞影响代码（called vulnerabilities）：**

| CVE | 漏洞 | 模块 | 当前版本 | 修复版本 | 调用点 |
|-----|------|------|----------|----------|--------|
| GO-2026-4985 | OTLP HTTP 响应体内存耗尽 | `go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp` | v1.37.0 | v1.43.0 | `pkg/binancex/tracing.go:33` `InitTracer` |
| GO-2026-4394 | OpenTelemetry SDK PATH 劫持 RCE | `go.opentelemetry.io/otel/sdk` | v1.37.0 | v1.40.0 | `pkg/binancex/tracing.go:40,48` |

另发现 2 个 imported-package 漏洞 + 5 个 required-module 漏洞，但代码未调用。

### Admin API 认证状态

| 检查项 | 状态 | 代码位置 |
|--------|------|----------|
| Bearer token 认证 | ✅ 已实现 | `internal/server/admin.go:77-86` |
| 非 loopback 绑定强制 TLS | ✅ 已实现 | `AdminConfig.ValidateAuth()` :177-185 |
| 非 loopback 缺 token 报错 | ✅ `ErrAdminRequiresToken` | :193-194 |
| constant-time 比较 | ✅ `subtle.ConstantTimeCompare` | :85 |

Admin API 认证链完整：非 loopback 绑定要求 TLS + Bearer token，否则启动报错。

## 阻塞项

1. **2 个未修补 CVE（affects code）**：OpenTelemetry v1.37.0 存在 GO-2026-4985（内存耗尽）和 GO-2026-4394（RCE），代码直接调用受影响路径。需升级到 v1.43.0+。
2. **CI security scan 未执行**：因 PRG-001 runner 未注册，3 个 security workflow 无法在 CI 中实际运行。本地 gitleaks 未安装。

## 结论

**Partial** — 安全扫描基础设施（Make target + CI workflow + Admin API 认证）完整，但 govulncheck 发现 2 个影响代码的未修补 CVE，需升级 OpenTelemetry 依赖后方可闭合。

[KNOWN] govulncheck 输出明确列出 2 个 called vulnerabilities；[COMPUTED] Admin API 认证链代码审查通过；[INFERRED] CI security scan 因 runner 缺失无法验证。

[RULES I BROKE]：无
