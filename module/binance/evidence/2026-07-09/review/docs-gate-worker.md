# Binance Docs Gate Worker Evidence

- Date: 2026-07-09
- Scope: ZoneCNH 主仓文档 gate，不触碰 `/home/workspace/binance` runtime 仓。
- Changed files: `scripts/check-binance-docs.sh`, `module/binance/gate/STANDARD.md`, `module/binance/gate/RULES.md`, `module/binance/ALIGNMENT.md`, `module/binance/todo.md`

## Result

| Check | Result |
| --- | --- |
| `bash scripts/check-binance-docs.sh` | PASS。[COMPUTED, HIGH] |
| `git diff --check` | PASS。[COMPUTED, HIGH] |

## Coverage

[COMPUTED, HIGH] `scripts/check-binance-docs.sh` 已停止旧根 `module/binance/SPEC.md` 缺失即 `SKIP` 的行为，改为扫描 goal-driven 目录：

```text
module/binance/spec/SPEC.md
module/binance/spec/NAMING.md
module/binance/matrix/TRACEABILITY.md
module/binance/gate/RULES.md
module/binance/gate/STANDARD.md
```

[COMPUTED, HIGH] docs gate 覆盖 implemented event_type、planned event_type、product_line、NATS subject、Kafka topic、TDengine stable、REST path、`contracts` 版本线守门锚点和 `stale=true` order book 下游暂停规则。

## Residual Risk

[INFERRED, HIGH] 本 evidence 不关闭 runtime 发布阻断项。`go test ./...`、`spec-runtime-drift-check.sh`、runtime canonical event_type/storage schema 迁移、live capture、release tag/CI/rollback 仍需 runtime worker 提供最终证据。

[RULES I BROKE]：无
