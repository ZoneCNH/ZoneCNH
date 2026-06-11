# RSI Improvement Scorecard
> 自动生成: 2026-06-12 04:54:04

## Metrics

| 指标 | 值 | 目标 | 状态 |
|------|-----|------|------|
| Matrix 覆盖率 | 100% | ≥ 95% | ✅ |
| Gate 通过率 | 9/12 | ≥ 10/12 | ⚠️ |
| Evidence 文件数 | 19 | ≥ 5 | ✅ |
| Dropped edges | 27 | 全部有原因 | ⚠️ |
| Capture Rate | N/A | ≥ 80% | — |
| Gate Escape Rate | N/A | 0 | — |

## RSI Trigger Signals

- 测试覆盖声称完整但 Gate 通过率低 (9/12) → 检查 Matrix 是否连接真实指标
- 存在 27 个 Dropped edge → 检查是否有未说明的 drop_reason

## Improvement Backlog

- [ ] 测试覆盖声称完整但 Gate 通过率低 (9/12) → 检查 Matrix 是否连接真实指标...
- [ ] 存在 27 个 Dropped edge → 检查是否有未说明的 drop_reason...

## Next Steps

1. 审查 Improvement Backlog 中的候选改进项
2. 对每个改进项执行 R0-R9 Gate 检查（见 21-controlled-rsi.md）
3. 通过 R0-R9 的改进项 → 提交 Improvement Proposal
4. 需要 Human Approval 的改进项 → 生成 Change Request
