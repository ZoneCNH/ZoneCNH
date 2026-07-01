# .foundationx/ — 机器可读治理事实源

本目录为 FoundationX v2 Trust Alignment 的**机器可读事实契约层**，供 `xlibgate` 和 CI 消费。

## 文件清单

| 文件 | 用途 | 消费者 |
|------|------|--------|
| `repo-contract.schema.json` | `foundation.repo-contract/v1` 聚合 JSON Schema | xlibgate, CI validators |
| `blockers.json` | 已知阻塞项清单（按严重度/模块/类别索引，含 open/resolved 派生索引） | xlibgate maturity-check, CI |
| `status/index.json` | 20 模块聚合状态（fleet status） | xlibgate fleet-status, 生成投影 |

## 投影链路

```text
module/*/SPEC.md + module/FOUNDATION-DEPS.yaml
        ↓
xlibgate fleet-status --repos-root /home --output .foundationx/status/index.json
        ↓
.foundationx/status/index.json + .foundationx/blockers.json
        ↓ (生成 / 投影)
README.md / ARCHITECTURE.md / STATUS.md generated blocks
```

## 更新方式

- **自动**：`xlibgate fleet-status` 扫描 `/home/workspace/{module}` 下的 `.repo-contract.yaml` 生成
- **手动**：仅在尚无 `.repo-contract.yaml` 的模块中编辑 `index.json`
- **验证**：`xlibgate trust all --repo /home/workspace/{module}` 逐模块验证

## 成熟度维度

每个模块按 8 个维度评估（不再使用单一百分比）：

| 维度 | 字段 | 说明 |
|------|------|------|
| SPEC | `spec` | 规格完成 |
| IMPL | `impl` | 实现完成 |
| RELEASE | `release` | tag/release/manifest 一致 |
| LIVE INT | `live` | 真实服务集成 |
| EXT CI | `ci` | 外部 CI artifact |
| ADOPT | `adopt` | 下游真实采用 |
| SOAK | `soak` | 生产长时间运行 |
| FACTORY | `factory` | 最高综合等级 |

`status/index.json.summary` 使用长字段名（`spec_complete`、`impl_complete`、`release_published`、`live_integration`、`factory_grade`），必须从 `modules` 中的短字段派生。

## Trust hardening invariants

- `summary` 计数必须等于 `modules` 明细派生结果。
- `release=false` 必须同时 `factory=false`。
- `blockers.json.factory_blocking_modules` 必须枚举所有 `factory=false` 模块。
- `blockers.json` 中任一 `status=open` 的模块必须 `factory=false`。
- `category=release` 且 `status=open` 的 blocker 必须使对应模块 `release=false`。
- README / ARCHITECTURE / STATUS 等公开投影不得高于 `.foundationx/status/index.json` 事实层。
