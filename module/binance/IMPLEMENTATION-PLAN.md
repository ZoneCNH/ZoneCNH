# binance 实现计划
> 来源：[spec/SPEC.md](./spec/SPEC.md) v3.9.0 | [plan/](./plan/) | 生成日期：2026-06-29
## Phase 1: Client
| Task | Scope |
|------|-------|
| TASK-BINANCE-CLIENT-001~010 | Product-Line Catalog / Instrument Parser / Connectors / Normalization / Mapping / Idempotency / Admin |
## Phase 2: Server
| Task | Scope |
|------|-------|
| TASK-BINANCE-SERVER-* | Ingest / Validation / Idempotency / Dispatch / Health / Admin |
## CI Gate
| Gate | 条件 |
|------|------|
| go build | 零错误 |
| go test -race | 全部通过 |
| go vet | 零警告 |
| gitleaks | 零命中 |
| boundary gate | 通过 |
> 详细计划见 [plan/](./plan/) 目录
