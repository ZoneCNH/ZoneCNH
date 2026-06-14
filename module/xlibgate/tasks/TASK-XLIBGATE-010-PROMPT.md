# Context Packet — TASK-XLIBGATE-010

> trust 子命令框架 + 统一 JSON 输出
> 来源：SPEC.md v1.1.1 §7 FR-012~FR-019, §9.3.1

## Current Task

TASK-XLIBGATE-010: 实现 trust 父命令注册、统一 JSON 输出 schema、reason_code 枚举定义

## Related Spec

- module/xlibgate/SPEC.md §7 FR-012~FR-019 (trust 子命令组)
- module/xlibgate/SPEC.md §9.3.1 (Trust Alignment 统一输出格式)
- module/xlibgate/SPEC.md BR-007 (machine-readable status)

## Related Requirements

- FR-006: 输出格式（JSON 含 status/checks[]/summary）
- §9.3.1: 统一 JSON schema `{check, repo, status, severity, findings, reason_code, evidence}`

## Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust.go | trust 父命令注册到 root.go，8 子命令列表 |
| scanner/trust/common.go | reason_code 枚举（10 值）、TrustResult 结构体、MarshalJSON |

### reason_code 枚举（10 值）

`IDENTITY_MISMATCH`, `TEMPLATE_RESIDUE`, `TEMPLATE_RESIDUE_SELF_SKIP`, `RELEASE_DRIFT`, `FACTORY_GATE_BLOCKED`, `IMPORT_BOUNDARY_VIOLATION`, `TESTKIT_PROD_IMPORT`, `SECRET_LEAK`, `PRIVATE_ENDPOINT_LEAK`, `CONTRACT_PARSE_ERROR`

## Non-Scope

- 不实现具体 trust 检查逻辑（由 TASK-011~018 负责）
- 不修改 check/l2 子命令

## Acceptance Criteria

- `xlibgate trust --help` 输出 8 子命令列表
- 所有 trust 子命令输出统一 JSON 格式
- reason_code 10 值枚举定义完整
- `go build ./...` 通过

## Constraints

- 不依赖 Foundation 运行时模块（纯 CLI）
- JSON 序列化使用 `encoding/json` 标准库
- exit code 协议：0=pass, 1=fail, 2=error

## Validation

```bash
go build ./... && xlibgate trust --help 2>&1 | grep -q "identity\|template\|release-consistency\|maturity\|import-boundary\|testkit-prod-import\|secret-redaction\|fleet-status"
```
