# module/binance ARCHITECTURE-DRIFT-WATCHLIST.md — 漂移监控点

- Module-Version: v3.3.0
- Last-Updated: 2026-06-23
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
**历史**：2026-06-22 审计发现 `binance.market.options.depth` 在 natsx subject 表缺失（PR #858 修复）
**违反规则**：R2
**检测命令**：
```bash
# natsx subject
grep -rn "options\.depth" module/binance/ --include="*.md"
# Kafka topic
grep -rn "options\.depth\.v1" module/binance/ --include="*.md"
# ossx 路径
grep -rnE "options/depth" module/binance/ --include="*.md"
```

---

## D3. TRACEABILITY 状态 ≠ runtime 实际

**风险级别**：HIGH
**历史**：FR-001 曾标 "Partial — Spot connector implemented" 但 client/TRACEABILITY 全 Pending（2026-06-22 修复）
**违反规则**：R4
**检测命令**：
```bash
# 根矩阵 Implemented 数量
IMP=$(grep -cE "\| \*\*Implemented\*\*" module/binance/TRACEABILITY.md)
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
LAST_BUMP=$(git log --oneline -10 -- module/binance/SPEC.md | head -1)
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
grep -oP "v[0-9.]+" module/binance/client/TRACEABILITY.md | head -1
echo "=== server/TRACEABILITY 引用 ==="
grep -oP "v[0-9.]+" module/binance/server/TRACEABILITY.md | head -1
echo "=== root SPEC ==="
grep -oP "Spec-Version: \Kv[0-9.]+" module/binance/SPEC.md
```

---

## D8. Boundary gate 输出与 BR 状态不匹配

**风险级别**：LOW（PR-D 已修复，CI workflow [boundary-gates.yml](https://github.com/ZoneCNH/binance/actions/workflows/boundary-gates.yml) 已集成，runtime SHA `bae80d6`）
**违反规则**：R4
**检测命令**（需 runtime 仓）：
```bash
cd /home/binance && bash scripts/boundary-gates.sh 2>&1 | grep -E "(PASS|FAIL)"
```

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|---|---|---|---|
| 2026-06-22 | v1.0.0 | 首次建立。列出 8 个漂移监控点（D1-D8），全部源自 2026-06-22 治理审计发现 | ZoneCNH |