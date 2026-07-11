# module/binance ARCHITECTURE-DRIFT-WATCHLIST.md — 漂移监控点

- Module-Version: v4.0.0
- Last-Updated: 2026-06-26
- 用途：列举 `module/binance/` 最易漂移的位置（违反 NAMING/RULES 的高发区），供 PR review / GC agent 逐项检查

---

## D1. product_line 命名漂移

**风险级别**：HIGH
**历史**：2026-06-22 审计发现 4 套不兼容命名（usdm_futures/coinm_futures vs um_perp/cm_perp vs futures_usdt/futures_coin）在 5 处同时使用
**违反规则**：R1
**检测命令**：
```bash
grep -rnE "(usdm_futures|coinm_futures|futures_usdt|futures_coin)" module/binance/ --include="*.md" | grep -vE "NAMING\.md|RULES\.md|ARCHITECTURE-DRIFT|archive/"
```

---

## D2. Options depth subject / topic 缺失

**风险级别**：HIGH
**历史**：2026-06-22 审计发现 `binance.market.options.depth_update.v1`（legacy: `options.depth.v1`）在 natsx subject 表缺失（PR #858 修复；当时未显式记录 `.v1` 后缀）
**违反规则**：R2
**检测命令**：
```bash
# natsx subject
grep -rn "options\.depth_update" module/binance/ --include="*.md"
# Kafka topic
grep -rn "options\.depth_update\.v1" module/binance/ --include="*.md"
# ossx 路径
grep -rnE "options/depth_update" module/binance/ --include="*.md"
```

---

## D3. TRACEABILITY 状态 ≠ runtime 实际

**风险级别**：HIGH
**历史**：FR-001 曾标 "Partial — Spot connector implemented" 但 client/TRACEABILITY 全 Pending（2026-06-22 修复）
**违反规则**：R4
**检测命令**：
```bash
# 根矩阵 Implemented 数量
IMP=$(grep -cE "\| \*\*Implemented\*\*" module/binance/matrix/TRACEABILITY.md)
echo "矩阵声称 Implemented: $IMP"
echo "警告：这些状态需经 runtime CI gate 核验"
```

---

## D4. 模块版本号分裂与脱钩

**风险级别**：MEDIUM（2026-06-23 从"仅 ACCEPTANCE"升级为全量版本统一监控）
**历史**：多次审计显示版本号更新滞后；2026-06-23 发现 5 套异名字段（Doc-Version/Matrix-Version/Version/Module-Version/Spec-Version）+ 顶层版本号不统一 + 子规格 TRACEABILITY 版本字段缺失
**违反规则**：R6（2026-06-23 扩展为全量版本统一）
**检测命令**：
```bash
bash scripts/check-binance-docs.sh   # 含 R6 全量版本统一 + 异名字段禁用 + 子规格对称校验
```
**统一模型**：
- 字段名收敛为 2 种：`Spec-Version`（仅 SPEC.md）+ `Module-Version`（其他治理文档）+ `Runtime-Version`（SPEC.md runtime 版本）
- 顶层 Module-Version == root SPEC Spec-Version
- 子规格 TRACEABILITY Module-Version == 对应子 SPEC Spec-Version

---

## D5. 版本 bump 遗漏

**风险级别**：MEDIUM
**历史**：多轮 session 中出现变更后未 bump 版本号，hook 补 bump
**违反规则**：R3
**检测命令**：
```bash
LAST_BUMP=$(git log --oneline -10 -- module/binance/spec/SPEC.md | head -1)
echo "最近 SPEC.md 变更: $LAST_BUMP"
echo "此位置需人工确认 bump 级别是否正确"
```

---

## D6. 归档文件未物理隔离

**风险级别**：LOW（PR-A 已修复）
**历史**：v2.0.0 前 task 文件留在原地 + `[ARCHIVED]` 标记（2026-06-22 修复）
**违反规则**：R5
**检测命令**：
```bash
grep -lE "^\> \[ARCHIVED" module/binance/ --include="*.md" -r | grep -v "DEEP-ANALYSIS\|archive/"
```

---

## D7. 子规格版本元数据不同步

**风险级别**：MEDIUM
**历史**：client/TRACEABILITY.md 数据来源引用 v2.0.0 但实际为 v2.1.0（2026-06-22 修复）
**违反规则**：R3
**检测命令**：
```bash
echo "=== client/TRACEABILITY 引用 ==="
grep -oP "v[0-9.]+" module/binance/matrix/client/TRACEABILITY.md | head -1
echo "=== server/TRACEABILITY 引用 ==="
grep -oP "v[0-9.]+" module/binance/matrix/server/TRACEABILITY.md | head -1
echo "=== root SPEC ==="
grep -oP "Spec-Version: \Kv[0-9.]+" module/binance/spec/SPEC.md
```

---

## D8. Boundary gate 输出与 BR 状态不匹配

**风险级别**：LOW（PR-D 已修复，CI workflow [boundary-gates.yml](https://github.com/xhyperium/binance/actions/workflows/boundary-gates.yml) 已集成，runtime SHA `bae80d6`）
**违反规则**：R4
**检测命令**（需 runtime 仓）：
```bash
cd /home/workspace/binance && bash scripts/boundary-gates.sh 2>&1 | grep -E "(PASS|FAIL)"
```

---

## D9. 限流模型漂移（秒 vs 分钟 weight）

**风险级别**：HIGH
**历史**：v3.8.0 及之前 SPEC FR-013/FR-025/§11.2.10 使用「每秒 weight」模型（`max_weight_per_second`、`backfill_token_rate=100 tokens/s`），与 Binance 实际的「每分钟滑动窗口 weight」（`X-MBX-USED-WEIGHT-1M` header）机制不匹配。v3.9.0 全面修正为分钟模型。
**违反规则**：R11（v3.9.0 新增）
**检测命令**：
```bash
# 检测 spec 中是否残留旧限流模型
rg "max_weight_per_second|token_rate.*100" module/binance/spec/SPEC.md && echo "DRIFT D9: 限流模型回退到旧秒模型" || echo "OK"
```

---

## D10. 缺口检测策略漂移（时间差 vs 序列）

**风险级别**：HIGH
**历史**：v3.8.0 FR-017 使用统一「相邻事件间隔 > 2× 预期间隔」检测所有事件类型的缺口，无法区分 trade（由 trade_id 序列驱动）、depth（由 updateId 序列驱动）、tick（事件驱动无固定间隔）。v3.9.0 重写为按事件类型的差异化策略。
**违反规则**：R12（v3.9.0 新增）
**检测命令**：
```bash
# 检测代码中是否使用通用时间间隔 gap 检测
rg "2\s*\*\s*interval|2\s*\*\s*expected" /home/workspace/binance/internal/ -l --include='*.go' && echo "DRIFT D10: 缺口检测使用统一时间间隔法" || echo "OK"
```

---

## D11. 状态模型回归（禁止代码/证据双状态）

**风险级别**：HIGH
**历史**：v3.8.0 及之前 FEATURES.md/ACCEPTANCE.md/TRACEABILITY.md 三份文档对同一 FR 的「Done」状态定义互相矛盾，导致无法从单一文档判断真实完成状态。v3.9.0 曾引入代码完成/证据完成分层；P10 D-1 已撤销该结论，当前只能使用单一 Done/Partial/Drifted/Pending 状态。[COMPUTED, HIGH] 2026-07-10 root 当前状态为 13 Done / 52 Partial / 0 Drifted / 0 Pending，`release_closeable_spec=NO`、`release_closeable_runtime=NO`；旧 55/10 与 YES 只能出现在明确历史上下文。
**违反规则**：R4
**检测命令**：
```bash
# 检测当前文档是否重新引入代码/证据双状态或发布可关闭误判
rg "Code[-]State|Evidence[-]State|Evidence[-]Done|Code[-]Done|release_closeable[=]YES|44[[:space:]]Done" module/binance
```

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|---|---|---|---|
| 2026-06-22 | v1.0.0 | 首次建立。列出 8 个漂移监控点（D1-D8），全部源自 2026-06-22 治理审计发现 | ZoneCNH |
