# .foundationx/ — 机器可读治理事实源

本目录为 FoundationX v2 Trust Alignment 的**机器可读事实契约层**，供 `xlibgate` 和 CI 消费。

## 文件清单

| 文件 | 用途 | 消费者 |
|------|------|--------|
| `repo-contract.schema.json` | repo-contract/v1 JSON Schema | xlibgate, CI validators |
| `status/index.json` | 20 模块聚合状态（fleet status） | xlibgate fleet-status, 生成投影 |
| `status.generated.json` | 生成型状态块（用于 README/ARCHITECTURE/STATUS） | 文档生成器 |

## 投影链路

```text
module/*/SPEC.md + module/FOUNDATION-DEPS.yaml
        ↓
xlibgate fleet-status --repos-root /home --output .foundationx/status/index.json
        ↓
.foundationx/status/index.json
        ↓ (生成)
status.generated.json → README.md / ARCHITECTURE.md / STATUS.md generated blocks
```

## 更新方式

- **自动**：`xlibgate fleet-status` 扫描 `/home/{module}` 下的 `.repo-contract.yaml` 生成
- **手动**：仅在尚无 `.repo-contract.yaml` 的模块中编辑 `index.json`
- **验证**：`xlibgate trust all --repo /home/{module}` 逐模块验证

## 成熟度维度

每个模块按 8 个维度评估（不再使用单一百分比）：

| 维度 | 字段 | 说明 |
|------|------|------|
| SPEC | `spec_complete` | 规格完成 |
| IMPL | `implementation_complete` | 实现完成 |
| RELEASE | `release_published` | tag/release/manifest 一致 |
| LIVE INT | `live_integration` | 真实服务集成 |
| EXT CI | `external_ci` | 外部 CI artifact |
| ADOPT | `downstream_adoption` | 下游真实采用 |
| SOAK | `production_soak` | 生产长时间运行 |
| FACTORY | `factory_grade` | 最高综合等级 |
