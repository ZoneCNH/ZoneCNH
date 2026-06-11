# Incident Response Template
> 生成: 2026-06-12 04:57:55

## Severity
- [ ] P0 — 全站不可用
- [ ] P1 — 核心功能受损
- [ ] P2 — 非核心功能异常

## Detection
- **Time**: 2026-06-12 04:57:55
- **Alert**: （填写告警来源）
- **Detected by**: （填写发现人/系统）

## Impact
- **Users affected**: （估计数）
- **Duration**: （持续时长）
- **Data impact**: （有无数据损失）

## Response
```bash
# 1. 确认事故范围
# 2. 执行回滚: git revert <commit> && git push
# 3. 验证回滚: bash docs/goal/tools/goal-workflow.sh validate
# 4. 通知值班: （填写 on-call 联系方式）
```

## Escalation
- **Primary**: （填写主负责人）
- **Secondary**: （填写备份负责人）
- **Management**: （填写管理层联系人）

## Postmortem
- [ ] Root Cause Analysis
- [ ] Improvement Backlog entry
- [ ] Scorecard update
