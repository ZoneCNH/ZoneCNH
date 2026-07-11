#!/usr/bin/env bash
# 主仓 ZoneCNH/ZoneCNH issue 同步脚本（PLAN-011，10 轮深度分析后定稿）
# 用法：bash 011-sync-master-issues.sh
# 目标仓：ZoneCNH/ZoneCNH（不是 binance 仓）
# 编号起：#1463（#1462 已是主仓最新 close issue）
set -uo pipefail

REPO="ZoneCNH/ZoneCNH"
MAP_FILE="/home/workspace/ZoneCNH/plans/binance/011-master-issue-map.tsv"
RESULT_LOG="/tmp/011-master-sync.log"
> "$RESULT_LOG"

# 工具函数：创建 issue 并记录编号
create_issue() {
  local title="$1" body="$2" labels="$3"
  local url
  url=$(gh issue create -R "$REPO" --title "$title" --label "$labels" --body "$body" 2>&1 | tail -1)
  local num=""
  if [[ "$url" =~ /issues/([0-9]+) ]]; then
    num="${BASH_REMATCH[1]}"
  fi
  echo "$num	$title" | tee -a "$RESULT_LOG"
  echo "$num"
}

echo "=== PLAN-011 主仓 issue 同步（ZoneCNH/ZoneCNH） ==="
echo "目标仓：$REPO"
echo "起始编号：#1463"
echo "时间：$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo ""

# 验证 gh CLI 认证
if ! gh auth status >/dev/null 2>&1; then
  echo "FATAL: gh CLI 未认证"
  exit 1
fi

echo "=== [1] ROOT EPIC ==="
ROOT_BODY="$(cat <<'EOF'
## 来源

10 轮深度分析（2026-07-02）后定稿的主仓 EPIC issue。

将 `report/binance/` 三份报告（REVIEW-PROMPT v2.1 + DATA-INTEGRITY v3.9 + EXCHANGEINFO）识别的：
- **58 GAP-E** 运行时缺口
- **11 个治理陷阱**（T0-1~T10-1）
- **15 条漏洞链**
- **4 个 EXCHANGEINFO §8 勘误**

转化为可执行修复。总工时 ~55.25 人天（实际求和）+ 治理陷阱 ~8.5d。

详见 `plans/binance/011-runtime-gap-master-plan-20260702.md`。

## 同步策略变更

**之前**（5 轮分析时）：同步到 `xhyperium/binance` 子仓（#365~#402）
**现在**（10 轮分析后）：全部同步到 **主仓 ZoneCNH/ZoneCNH**

子仓历史 issue 保留不删，本主仓 issue 通过 cross-reference 引用。

## 子 Phase

- Phase 1: 治理分裂修复（11 陷阱，1.5d）
- Phase 2: GAP-E6 symbol 全量化（0.5d）
- Phase 3: GAP-E25 评估（0d，大概率 deferred）
- Phase 4: GAP-E1 v3.2 重构（2.5d）
- Phase 5: P1 独立批次（5 项，3.5d）
- Phase 6: EXCHANGEINFO 分级（4d）
- Phase 7: 数据完整性链（7 项，5d）
- Phase 8: P2+P3 治理与长尾（38 项 + 顶层文档，32d）

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
ROOT_NUM=$(create_issue "[EPIC][P0] binance runtime gap closure（PRG-007 真实化，主仓）" "$ROOT_BODY" "p0,runtime-gap")
echo "ROOT_NUM=$ROOT_NUM"

echo ""
echo "=== [2] Phase 1 EPIC + 11 陷阱 ==="
P1_BODY="Phase 1 EPIC: 消除 11 处状态分裂（Runtime-Version / CHANGELOG / PRG-006 / v0.11.0 tag / evidence GAP-E / SECURITY+CONTRIBUTING / SCORECARD / Task 计数 / registry / BR 数量）。详见 plan §Phase 1。父 EPIC: #$ROOT_NUM"
P1_NUM=$(create_issue "[EPIC][Phase-1] binance 治理分裂修复（11 陷阱）" "$P1_BODY" "p0,governance-trap,phase-1")

# 11 陷阱
T_BODY_T01="T0-1/T8-1: SPEC/README Runtime-Version = v0.8.0 vs DEPLOY = v0.11.0 vs HEAD = f53303f（无 tag）。前置：runtime 仓打 v0.11.0 tag（T7-2）。修复后 SPEC/README/DEPLOY 三处全部对齐到 v0.11.0。"
T01_NUM=$(create_issue "[P0][Phase-1] T0-1/T8-1: Runtime-Version 三处统一为 v0.11.0" "$T_BODY_T01" "p0,governance-trap,phase-1")

T_BODY_T71="T7-1: TRACEABILITY.md §4 PRG-006 标 PASS，但 todo.md 曾标 Partial（含 gated 测试说明），现 todo.md 已空。修复：TRACEABILITY §4 PRG-006 从 PASS 改为 Partial，加 gated 测试说明。"
T71_NUM=$(create_issue "[P0][Phase-1] T7-1: PRG-006 TRACEABILITY §4 降级 Partial" "$T_BODY_T71" "p0,governance-trap,phase-1")

T_BODY_T72="T7-2: runtime 仓 \`git tag -l 'v*'\` 输出为空（连 v0.8.0 都没有）。`git rev-parse --is-shallow-repository = true`，需先 \`git fetch --unshallow\`。然后 \`git tag v0.11.0 f53303f\` + \`gh release create v0.11.0 --notes-file ...\`。⚠️ **tag 创建需用户显式授权**。"
T72_NUM=$(create_issue "[P0][Phase-1] T7-2: 补 v0.11.0 GitHub Release（PRG-002 真实化，shallow clone）" "$T_BODY_T72" "p0,governance-trap,phase-1")

T_BODY_T11="T1-1: CHANGELOG Module-Version: v3.9.7 > SPEC Spec-Version: v3.9.6，违反单向追溯。推荐 SPEC bump 到 v3.9.7（同 PR）。"
T11_NUM=$(create_issue "[P1][Phase-1] T1-1: CHANGELOG vs SPEC 版本单向追溯" "$T_BODY_T11" "p1,governance-trap,phase-1")

T_BODY_T21="T2-1: \`grep -rl 'GAP-E' module/binance/evidence/\` = 0 文件（断链）。修复：在 evidence/2026-07-02/runtime-gap-closure.md 引用 GAP-E1/E6/E25/E52/E57 等关键缺口。"
T21_NUM=$(create_issue "[P1][Phase-1] T2-1: evidence/ 补 GAP-E 引用（GAP-E57）" "$T_BODY_T21" "p1,governance-trap,phase-1")

T_BODY_T82="T8-2: module/binance/ 根目录 SECURITY.md + CONTRIBUTING.md 均 MISSING（GAP-E44/E45）。基于 gate/SECURITY.md 或独立写。"
T82_NUM=$(create_issue "[P1][Phase-1] T8-2: 新建 SECURITY.md + CONTRIBUTING.md（GAP-E44/E45）" "$T_BODY_T82" "p1,governance-trap,phase-1")

T_BODY_T91="T9-1: TEST-ANALYSIS-20260630.md 含 2026-07-02 免责声明，部分描述与代码不符。SCORECARD 测试维度需重新评分（93→85）。"
T91_NUM=$(create_issue "[P1][Phase-1] T9-1: SCORECARD 测试维度评分下调（93→85）" "$T_BODY_T91" "p1,governance-trap,phase-1")

T_BODY_T41="T4-1: \`find module/binance/tasks/ -name 'TASK-*.md' | wc -l\` = 39，README 声明 '47/47 tasks'，差 8 个。方案 A 补齐 8 个 TASK 文件 vs 方案 B 更新 README 为 39/39。"
T41_NUM=$(create_issue "[P1][Phase-1] T4-1: Task 计数矛盾对齐（实际 39 vs README 47/47）" "$T_BODY_T41" "p1,governance-trap,phase-1")

T_BODY_T101="T10-1: registry.yaml lifecycle: production + maturity: L3 已存在（看似 OK），但 **release.latest_tag: v0.8.0 与 DEPLOY.md v0.11.0 矛盾**（同源 T0-1）。修复依赖 T7-2 v0.11.0 tag，然后改 registry.yaml latest_tag。"
T101_NUM=$(create_issue "[P1][Phase-1] T10-1: registry.yaml latest_tag 修正（v0.8.0→v0.11.0）" "$T_BODY_T101" "p1,governance-trap,phase-1")

T_BODY_T83="T8-3: CHANGELOG line 566 声明 'BR-001/002/003/005/006/007/008/009 → Implemented'（8 个），当前 SPEC 仅 BR-001~BR-005（5 个），BR-006~009 静默删除 4 个。方案 A 恢复 vs 方案 B 记录删除原因 + 同步 CHANGELOG。"
T83_NUM=$(create_issue "[P3][Phase-1] T8-3 修正: BR 数量缩减（9→5）vs CHANGELOG 声明 Implemented（GAP-E53）" "$T_BODY_T83" "P3,governance-trap,phase-1")

echo ""
echo "=== [3] Phase 2 ==="
T_BODY_E6="GAP-E6: runtime.go:199-217 当前仅 spot 装配。改为 for 循环 4 线装配（spot/um/cm/options）+ options decode 加 status 字段过滤 TRADING。详见 plan Phase 2。父 EPIC: #$ROOT_NUM"
E6_NUM=$(create_issue "[P0][Phase-2] GAP-E6: UM/CM/Options 4 线 ExchangeInfoRefresher 装配" "$T_BODY_E6" "p0,runtime-gap,phase-2")

echo ""
echo "=== [4] Phase 3 ==="
T_BODY_E25="GAP-E25: EXCHANGEINFO §8.2 勘误：分级后单副本 940 stream（2 连接）富余。GAP-E25 不再是必做项。监控 1 周，资源紧张才启动。默认 deferred。父 EPIC: #$ROOT_NUM"
E25_NUM=$(create_issue "[P2][Phase-3] GAP-E25: 评估单副本负载（§8.2 勘误，默认 deferred）" "$T_BODY_E25" "p2,runtime-gap,phase-3")

echo ""
echo "=== [5] Phase 4 EPIC + 7 subtask ==="
P4_BODY="Phase 4 EPIC: 删除 client/history_state_postgres.go（违宪）+ server 端 PG 持久化 coverage + client NATS 上报。前置：GAP-E7 SPEC §75 vs §509 矛盾裁决。父 EPIC: #$ROOT_NUM"
P4_NUM=$(create_issue "[EPIC][P0][Phase-4] GAP-E1 v3.2 重构（server 端 coverage SSOT）" "$P4_BODY" "p0,runtime-gap,phase-4")

for sub in "GAP-E7: SPEC §509 移除 history_state_postgres.go（前置）" \
           "P4.1: server coverage store（PG 持久化）" \
           "P4.2: server NATS subscriber（binance.coverage.heartbeat）" \
           "P4.3: client coverage_reporter（周期 NATS 上报）" \
           "P4.4: 删除 internal/client/history_state_postgres.go（违宪）" \
           "P4.5: cmd/binance-client/main.go 移除 postgresx 装配" \
           "P4.6: 测试覆盖（单元 + 集成）"; do
  create_issue "[P1][Phase-4] $sub" "Phase 4 subtask: $sub. 父 EPIC: #$P4_NUM" "p1,runtime-gap,phase-4" > /dev/null
  echo "  ✓ [$sub]"
done

echo ""
echo "=== [6] Phase 5 EPIC + 5 独立项 ==="
P5_BODY="Phase 5 EPIC: GAP-E32/E27/E34/E36/E29 五项无相互依赖，独立 PR 并行。父 EPIC: #$ROOT_NUM"
P5_NUM=$(create_issue "[EPIC][P1][Phase-5] P1 独立批次（5 项无依赖并行）" "$P5_BODY" "p1,runtime-gap,phase-5")

for sub in "GAP-E32: 7 处 goroutine 加 recover 包装" \
           "GAP-E27: WebSocket SetReadLimit（OOM 保护）" \
           "GAP-E34: HTTP server 完整超时（Read/Write/Idle）" \
           "GAP-E36: ldflags 注入 buildinfo" \
           "GAP-E29: 集成 golang-migrate migration runner"; do
  create_issue "[P1][Phase-5] $sub" "Phase 5 独立项: $sub. 父 EPIC: #$P5_NUM" "p1,runtime-gap,phase-5,independent" > /dev/null
  echo "  ✓ [$sub]"
done

echo ""
echo "=== [7] Phase 6 EPIC + 4 项 ==="
P6_BODY="Phase 6 EPIC: EXCHANGEINFO §8.3 先白名单（0.5d 覆盖 90%）→ 再动态分级（3.5d 覆盖 100%）。§8.1 options 独立维度。父 EPIC: #$ROOT_NUM"
P6_NUM=$(create_issue "[EPIC][P1][Phase-6] EXCHANGEINFO symbol 分级体系（白名单 MVP → 动态分级）" "$P6_BODY" "p1,runtime-gap,phase-6")

for sub in "GAP-E26: interval SSOT（前置）" \
           "EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS）" \
           "GAP-E24: CatalogEntry 动态分级（Tier/SymbolPriority/Collection）" \
           "EXCHANGEINFO §8.1: options 独立维度（不进 Tier）"; do
  create_issue "[P1][Phase-6] $sub" "Phase 6 项: $sub. 父 EPIC: #$P6_NUM" "p1,runtime-gap,phase-6" > /dev/null
  echo "  ✓ [$sub]"
done

echo ""
echo "=== [8] Phase 7 EPIC + 8 项 ==="
P7_BODY="Phase 7 EPIC: GAP-E2/E3/E10/E12/E17/E18/E19/E28 八项系列修复（含 TDengine 双写漏洞链 #1）。父 EPIC: #$ROOT_NUM"
P7_NUM=$(create_issue "[EPIC][P1][Phase-7] 数据完整性链（漏洞链 #1/#2/#4/#5/#14）" "$P7_BODY" "p1,runtime-gap,phase-7")

for sub in "GAP-E2: server CompletenessScanner（完整性扫描器）" \
           "GAP-E3: E2E 二向对账 + OSS checksum" \
           "GAP-E10: catalog diff NATS pub/sub" \
           "GAP-E12: AckWait 30s → 5min + backfill 小批次" \
           "GAP-E17: server time.Now().UTC() 强制" \
           "GAP-E18: TDengine 部分成功捕获（不重投）" \
           "GAP-E19: PayloadHash server 重算（漏洞链 #1 同 PR）" \
           "GAP-E28: PG 事务管理（多步写入原子性）"; do
  create_issue "[P1][Phase-7] $sub" "Phase 7 项: $sub. 父 EPIC: #$P7_NUM" "p1,runtime-gap,phase-7" > /dev/null
  echo "  ✓ [$sub]"
done

echo ""
echo "=== [9] Phase 8 EPIC + 10 批次 ==="
P8_BODY="Phase 8 EPIC: 9 批次独立 PR：可观测性/安全/部署/Schema/配置/容错/优雅运行/测试/长尾 + P3 治理文档。父 EPIC: #$ROOT_NUM"
P8_NUM=$(create_issue "[EPIC][P2][Phase-8] P2+P3 治理与长尾（38 项 + 顶层文档）" "$P8_BODY" "p2,runtime-gap,phase-8")

for sub in "8.1 可观测性补强（E9+E30+E35）" \
           "8.2 安全加固（E37+E44+E45）" \
           "8.3 部署治理（E41~E50）" \
           "8.4 Schema 演进（E8+E19+E23）" \
           "8.5 配置治理（E31+E4）" \
           "8.6 容错与韧性（E11+E16+E33）" \
           "8.7 优雅运行（E14+E15+E20+E22）" \
           "8.8 测试与质量（E21+E40）"; do
  create_issue "[P2][Phase-8] $sub" "Phase 8 批次: $sub. 父 EPIC: #$P8_NUM" "p2,runtime-gap,phase-8" > /dev/null
  echo "  ✓ [$sub]"
done

create_issue "[P3][Phase-8] 8.9 长尾低优（E38+E39）" "Phase 8 P3 长尾. 父 EPIC: #$P8_NUM" "P3,runtime-gap,phase-8" > /dev/null
echo "  ✓ [8.9 长尾低优]"
create_issue "[P3][Phase-8] 8.10 P3 治理文档批次（E51~E58）" "Phase 8 P3 治理文档. 父 EPIC: #$P8_NUM" "P3,governance-trap,phase-8" > /dev/null
echo "  ✓ [8.10 P3 治理文档]"

echo ""
echo "=== 同步完成 ==="
echo "总计创建 issue 数:"
wc -l < "$RESULT_LOG"
echo ""
echo "issue 编号清单:"
cat "$RESULT_LOG"
