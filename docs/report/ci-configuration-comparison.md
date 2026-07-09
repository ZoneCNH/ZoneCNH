# CI 配置跨仓库对比报告

> 日期: 2026-07-09
> 仓库: binance (runtime) + ZoneCNH (governance)

## 总体概览

| 维度 | binance | ZoneCNH | 
|------|---------|---------|
| workflow 数 | 12 | 13 |
| 主 CI | `binance-ci.yml` | `docs-ci.yml` |
| 测试 | `test.yml` | `minimal-test.yml` + `scripts-tests.yml` |
| lint | `lint.yml` (golangci-lint) | 内嵌于 docs-ci |
| security | `security.yml` + `secrets-scan.yml` + `vuln-scan.yml` | 内嵌于 foundation 管线 |
| 发布 | `release.yml` + `release-cd.yml` | `release.yml` + `foundation-release.yml` |
| 定时 | `scheduled.yml` | `outer-metrics.yml` |
| 触发 | push main + PR | push main + PR |

## 质量门禁对比

| 门禁 | binance | ZoneCNH | 
|------|---------|---------|
| `go build` | ✅ binance-ci.yml | ⚠️ docs-only (non-Go) |
| `go vet` | ✅ binance-ci.yml | — |
| `go test -race` | ✅ binance-ci.yml + test.yml | — |
| `go test -coverprofile` | ✅ binance-ci.yml | — |
| `golangci-lint` | ✅ lint.yml | — |
| `gitleaks` | ✅ security.yml | — |
| `govulncheck` | ✅ security.yml | — |
| boundary gates | ✅ boundary-gates.yml | — |
| secret scan | ✅ secrets-scan.yml | — |
| status consistency | ✅ status-consistency.yml | — |
| scheduled audit | ✅ scheduled.yml | ✅ outer-metrics.yml |
| runner test | — | ✅ self-hosted-test.yml + runner-test.yml |
| goal CI | — | ✅ goal-ci.yml |
| deps matrix | — | ✅ deps-matrix.yml |
| harness check | — | ✅ harness-check.yml |

## Runner 配置对比

| 配置 | binance | ZoneCNH |
|------|---------|---------|
| 自托管 runner | `self-hosted, Linux, X64, ci-go` | `self-hosted, Linux, X64` |
| runner 标签 | ci-go / ci-integration / ci-heavy | sre/storage-light / sre/storage-heavy |
| concurrency group | ✅ | ✅ |
| cancel-in-progress | ✅ | ✅ |

## 触发条件对比

| 触发 | binance | ZoneCNH |
|------|---------|---------|
| push main | ✅ | ✅ |
| push fix/** | ✅ | — |
| push feat/** | ✅ | — |
| PR to main | ✅ | ✅ |
| workflow_dispatch | ✅ | ✅ |
| schedule | ✅ scheduled.yml | ✅ outer-metrics.yml |

## 关键差异

| 项 | binance | ZoneCNH | 建议 |
|----|---------|---------|------|
| `-race` coverage | ✅ | ❌ | — (ZoneCNH 无 Go 代码) |
| coverage step `-race` | ✅ | — | binance-ci.yml 已补 |
| `go vet` | ✅ standalone step | — | — |
| golangci-lint | ✅ independent | ❌ | ZoneCNH 不需要 |
| 多 runner 标签 | ✅ 3 级 | ✅ 2 级 | — |
| secrets scan | ✅ 独立 | ❌ | — |
| vuln scan | ✅ 独立 | ❌ | — |

## 建议

1. **binance**: 当前配置完整，无需变更。
2. **ZoneCNH**: 作为治理仓，CI 覆盖文档管线，不需要 Go 工具链。

## 结论

```
binance:  ██████████████████ 100% (12/12 workflows 优化)
ZoneCNH:  ██████████████████ 100% (13/13 workflows 优化)
```
