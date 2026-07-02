# contracts 验收清单

- Status: Docs Baseline Synced / Acceptance Closed
- Last-Updated: 2026-06-30
- Layer: 基座 · 跨域接口契约
- Source-of-Truth: `/home/workspace/contracts/pkg/contracts`
- Related: `SPEC.md`, `README.md`, `goal.md`, `TRACEABILITY.md`, `FEATURES.md`, `IMPLEMENTATION-PLAN.md`, `tasks/`

> 本文档只记录当前 runtime truth 的验收口径与退出条件；旧的分层命名、旧版本标记、重大改名故事、旧交易所接入叙事不再保留。

## 1. 验收命令

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 术语回归扫描 | `cd /home/workspace/ZoneCNH && rg -n -e '旧术语' -e '旧命名' -e '旧分层' -e '历史叙事' -e '双向流' -e '兼容层' module/contracts` | 无命中 |
| 文档补丁检查 | `cd /home/workspace/ZoneCNH && git diff --check -- module/contracts` | 无尾随空格或补丁格式问题 |
| 运行时测试 | `cd /home/workspace/contracts && go test ./...` | 全部通过 |
| 竞态检查 | `cd /home/workspace/contracts && go test ./... -race -count=1` | 无 race，测试稳定 |
| 静态检查 | `cd /home/workspace/contracts && go vet ./...` | 零告警 |
| 覆盖率证据 | `cd /home/workspace/contracts && go test ./... -coverprofile=coverage.out` | 生成覆盖率并满足模块门槛 |
| 依赖边界 | `cd /home/workspace/contracts && go list -deps ./...` | 依赖不越过 FOUNDATION-DEPS.yaml 边界 |

## 2. FR 验收登记

| ID | 验收项 | 关联检查 | 当前状态 |
| --- | --- | --- | --- |
| FR-001 | `Event`、`Command`、`Query` 基础封装 | TC-001 | 已同步 |
| FR-002 | `DTO`、`Port`、`ErrorCode` 标记与错误元数据 | TC-001 | 已同步 |
| FR-003 | `RegimeSnapshot`、`RegimeCard`、`DecisionCard` | TC-001 | 已同步 |
| FR-004 | `SignalIntent` 与 `SignalFactoryProvider.Generate(...)` | TC-006 | 已同步 |
| FR-005 | `MarketDataProvider`、`MacroDataProvider`、`DecisionCardProvider`、`SignalFactoryProvider` | TC-002 | 已同步 |
| FR-006 | `MarketDataService.Ingest(...)`、`IngestRequest`、`IngestResult`、`IngestAck`、`IngestReject`、`RejectCode`、`AllRejectCodes()` | TC-003 | 已同步 |
| FR-007 | `RegimeSnapshotEvent`、`RegimeCardEvent`、`DecisionCardEvent`、`MarketRegimePort`、`MacroRegimePort`、`RegimeEnginePort` | TC-004 | 已同步 |
| FR-008 | 文档基线与 runtime truth 同步 | TC-005 | 已同步 |

## 3. BR 验收登记

| ID | 约束项 | 关联检查 | 当前状态 |
| --- | --- | --- | --- |
| BR-001 | 仅定义共享契约，不实现业务或传输逻辑 | TC-008 | 已同步 |
| BR-002 | 不再使用旧分层命名 | TC-005 | 已同步 |
| BR-003 | 不再使用旧 API 名称与旧版本标记 | TC-005 | 已同步 |
| BR-004 | 依赖边界受 `module/FOUNDATION-DEPS.yaml` 约束 | TC-008 | 已同步 |
| BR-005 | DTO 需要明确导出字段与 JSON tag 约定 | TC-001 | 已同步 |
| BR-006 | `AllRejectCodes()` 只返回 10 个 canonical code | TC-003 | 已同步 |
| BR-007 | `RejectUnsupportedChannel` 导出且属于 canonical 列表 | TC-003 | 已同步 |
| BR-008 | 兼容别名只承担迁移，不承载新语义 | TC-004 | 已同步 |
| BR-009 | 文档必须保持同一组事实源 | TC-005 | 已同步 |
| BR-010 | 公开 rename/removal 先修兼容层与追溯文档 | TC-004、TC-005 | 已同步 |

## 4. NFR 验收登记

| ID | 非功能项 | 关联检查 | 当前状态 |
| --- | --- | --- | --- |
| NFR-001 | 可编译、可测试、可复验 | TC-007 | 已同步 |
| NFR-002 | 竞态安全 | `go test ./... -race -count=1` | 已同步 |
| NFR-003 | 静态检查干净 | `go vet ./...` | 已同步 |
| NFR-004 | 文档更新可审计 | `git diff --check`、旧术语扫描 | 已同步 |
| NFR-005 | 公开符号保留可读 godoc | `contracts.go`、`ports.go`、`ingestion.go`、`projections.go` 注释 | 已同步 |
| NFR-006 | canonical reject-code 集合稳定为 10 项 | TC-003 | 已同步 |
| NFR-007 | 不把 transport 实现写成契约本体 | TC-008 | 已同步 |
| NFR-008 | 不回流旧叙事 | TC-005 | 已同步 |

## 5. 发布退出条件

- `module/contracts` 旧术语扫描无命中。
- `git diff --check` 无格式问题。
- `/home/workspace/contracts` 的 `go test ./...`、`go test ./... -race -count=1`、`go vet ./...` 已完成并归档证据。
- `README.md`、`goal.md`、`TRACEABILITY.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md` 与 `SPEC.md` 同源。
- `RejectUnsupportedChannel` 仍为导出常量，并进入 `AllRejectCodes()`。
- 公开符号的新增、删除或重命名必须先更新 `SPEC.md` 再更新本文档。
