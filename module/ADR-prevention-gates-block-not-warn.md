# ADR-005: 预防门禁采用阻断而非告警

> 状态：Accepted
> 日期：2026-06-15
> 决策者：ZoneCNH (audit session)
> 关联：PR #399, #408; CLAUDE.md §数量验证门禁

---

## 背景

2026-06-15 三文档审计发现 7+ 处凭空编造的数量，需 13+ 个 PR 修复。根因：agent 凭常识编造计数而非逐表逐行统计。告警不足以阻止——agent 在快速编辑循环中会忽略 stderr 输出。

设计了三级预防体系：L1 CountGuard hook（会话内）、L2 audit-status.py（本地验证）、L3 CI gate（合并阻断）。

---

## 决策

**CountGuard 高危模式采用 BLOCK（exit 2）而非 WARN-only。CI gate 采用阻断合并（FAIL=阻断）而非仅告警。**

具体设计：

| 层级 | 工具 | 触发 | 行为 |
|------|------|------|------|
| L1 | count-guard.mjs | Write/Edit 三文档 | BLOCK（组件总数/平均进度/有版本号），WARN（其余） |
| L2 | audit-status.py | 手动 | 输出 PASS/FAIL |
| L3 | audit-status.yml | PR/push 三文档 | FAIL 阻断 merge |

逃生舱：`COUNT_GUARD_STRICT=false` 降级 L1 为全 WARN 模式。

---

## 替代方案

### 方案 A：全 WARN-only 不阻断

所有层级仅告警不阻断。

- 未选择原因：告警在 agent 快速编辑循环中不可见。本次审计的教训是 agent 多次忽略 stderr 输出。不阻断的告警等于没有告警。

### 方案 B：全 BLOCK 所有数量变更

无逃生舱，所有数量变更一律阻断。

- 未选择原因：合理变更（如新增模块）被阻断会阻塞工作流。需要逃生舱支持已验证后的提交。

---

## 后果

### 正面

- 阻断机制在本次审计后已被验证有效（后续 PR 中 CountGuard 正确阻断了多次未验证的数量变更）
- 逃生舱设计平衡了安全性与可用性

### 负面影响

- `COUNT_GUARD_STRICT=false` 可能被滥用。当前无日志或监控检测其使用频率

### 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|:---:|:---:|------|
| 逃生舱被滥用 | 中 | 中：绕过阻断引入新漂移 | audit-status.py CI gate 为第二防线；L2 不受 STRICT 变量影响 |
| CI gate 假阳性阻断合法 PR | 极低 | 高：阻塞工作流 | audit-status.py 是确定性工具，假阳性概率为零 |

---

## 约束

- CountGuard 仅作用于 STATUS.md / README.md / ARCHITECTURE.md
- L2 和 L3 不受 `COUNT_GUARD_STRICT` 影响
- 阻断仅在 PR 触及三文档时触发

---

## 参考

- PR #399 (CountGuard), #408 (CI gate)
- `.claude/hooks/count-guard.mjs`
- `scripts/audit-status.py`
- `.github/workflows/audit-status.yml`
