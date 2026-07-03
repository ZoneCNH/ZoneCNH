#!/usr/bin/env bash
# beads issue 批量创建脚本（PLAN-010）
# 用法：bash 010-create-beads-issues.sh [--dry-run]
# 前置：cd /home/workspace/ZoneCNH && bd ready
set -euo pipefail

if [[ "${1:-}" != "--legacy-force" && "${1:-}" != "--dry-run" ]]; then
  echo "⚠️ ARCHIVED: 010 系列为历史脚本，默认禁止执行。"
  echo "如需仅查看请使用 --dry-run；确需旧流程执行请显式传 --legacy-force。"
  exit 2
fi

DRY_RUN="${1:-}"
CREATE_ARGS=""
if [[ "$DRY_RUN" == "--dry-run" ]]; then
  echo "=== DRY RUN（不实际创建） ==="
  CREATE_ARGS="--dry-run"  # beads 不支持，用 echo 模拟
fi

# 工具函数
create_epic() {
  local title="$1" desc="$2"
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "[epic dry-run] $title"
    echo "  desc: ${desc:0:80}..."
    echo "  EPIC_ID=TBD"
    return 0
  fi
  bd create --title="$title" --description="$desc" --type=epic --priority=1 2>&1 | tee /tmp/bd-last.log | tail -3
}

create_task() {
  local title="$1" desc="$2" priority="${3:-2}" parent="${4:-}"
  local args=(--title="$title" --description="$desc" --type=task --priority="$priority")
  [[ -n "$parent" ]] && args+=(--parent="$parent")
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "  [task dry-run] $title (P$priority${parent:+, parent=$parent})"
    return 0
  fi
  bd create "${args[@]}" 2>&1 | tail -1
}

create_sub() {
  local title="$1" desc="$2" priority="${3:-3}" parent="${4:-}"
  local args=(--title="$title" --description="$desc" --type=task --priority="$priority")
  [[ -n "$parent" ]] && args+=(--parent="$parent")
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "    [sub dry-run] $title"
    return 0
  fi
  bd create "${args[@]}" 2>&1 | tail -1
}

echo ""
echo "=== [EPIC-0] binance runtime gap closure（root） ==="
ROOT_DESC="将 report/binance/ 三份报告（REVIEW-PROMPT v2.0 + DATA-INTEGRITY v3.9 + EXCHANGEINFO）识别的 58 GAP-E + 9 治理陷阱 + 4 EXCHANGEINFO 勘误 转化为可执行修复。总工时 73.5 人天，分 8 阶段。详见 plans/binance/010-runtime-gap-fix-execution-plan-20260702.md。"
create_epic "binance runtime gap closure（PRG-007 真实化）" "$ROOT_DESC"
ROOT_ID=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")
echo "ROOT_ID=$ROOT_ID"

echo ""
echo "=== [EPIC-1] Phase 1: 治理分裂修复（1.5d） ==="
create_epic "Phase 1: binance 治理分裂修复（9 个陷阱）" "消除 6 处状态分裂：Runtime-Version / CHANGELOG / PRG-006 / v0.11.0 tag / evidence GAP-E / SECURITY+CONTRIBUTING。详见 plan §Phase 1。"
P1_EPIC=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")

create_task "T0-1/T8-1: Runtime-Version 三处统一为 v0.11.0" "SPEC/README/DEPLOY 三处 Runtime-Version 全部对齐到 v0.11.0（当前 SPEC/README=v0.8.0, DEPLOY=v0.11.0, 实际 HEAD=f53303f 无 tag）。前置：runtime 仓打 v0.11.0 tag。" 0 "$P1_EPIC"

create_task "T1-1: CHANGELOG/SPEC 版本单向追溯对齐" "CHANGELOG v3.9.7 > SPEC v3.9.6 违反单向追溯。推荐 SPEC bump 到 v3.9.7（同 PR）。" 1 "$P1_EPIC"

create_task "T7-1: PRG-006 TRACEABILITY §4 降级 Partial（与 todo.md 一致）" "TRACEABILITY.md §4 PRG-006 从 PASS 改为 Partial，加 gated 测试说明（todo.md L23-32 已有内容）。消除 PRG-006 状态分裂。" 0 "$P1_EPIC"

create_task "T7-2: 补 v0.11.0 GitHub Release（PRG-002 真实化）" "runtime 仓 git tag -l 'v*' 当前为空。需 git tag v0.11.0 f53303f + gh release create v0.11.0 --notes-file ...。修复后 PRG-002 才真实 PASS。" 0 "$P1_EPIC"

create_task "T2-1: evidence/ 补 GAP-E 引用（≥3 文件）" "evidence 中 GAP-E 引用数当前为 0（断链）。在 evidence/2026-07-02/runtime-gap-closure.md 引用 GAP-E1/E6/E25 等关键缺口。" 1 "$P1_EPIC"

create_task "T8-2: 新建 SECURITY.md + CONTRIBUTING.md（GAP-E44/E45）" "module/binance/ 根目录两者均 MISSING。基于 gate/SECURITY.md 或独立写。" 1 "$P1_EPIC"

create_task "T9-1: SCORECARD 测试维度评分下调（93→85）" "TEST-ANALYSIS-20260630.md 含 2026-07-02 免责声明，部分描述与代码不符。SCORECARD 测试维度需重新评分。" 1 "$P1_EPIC"

echo ""
echo "=== [TASK] Phase 2: GAP-E6 symbol 全量化（0.5d） ==="
create_task "GAP-E6: UM/CM/Options 4 线 ExchangeInfoRefresher 装配" "runtime.go:199-217 当前仅 spot 装配。改为 for 循环 4 线装配 + options decode 加 status 字段过滤 TRADING。详见 plan Phase 2。" 0 "$ROOT_ID"

echo ""
echo "=== [TASK] Phase 3: GAP-E25 评估（0d，监控触发） ==="
create_task "GAP-E25: 评估单副本负载（§8.2 勘误，默认 deferred）" "EXCHANGEINFO §8.2 勘误：分级后单副本 940 stream（2 连接）富余。GAP-E25 不再是必做项。监控 1 周，资源紧张才启动。" 2 "$ROOT_ID"

echo ""
echo "=== [EPIC-4] Phase 4: GAP-E1 v3.2 重构（2.5d） ==="
create_epic "Phase 4: GAP-E1 v3.2 重构（server 端 coverage SSOT）" "删除 client/ history_state_postgres.go（违宪）+ server 端 PG 持久化 coverage + client NATS 上报。前置：GAP-E7 SPEC §75 vs §509 矛盾裁决。" ""
P4_EPIC=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")

create_sub "GAP-E7: SPEC §509 移除 history_state_postgres.go（前置）" "SPEC §75 禁止 client 写 DB，但 §509 文件清单含 history_state_postgres.go。裁决：从 §509 删除。" 1 "$P4_EPIC"
create_sub "P4.1: server coverage store（PG 持久化）" "internal/server/coverage/store.go：PG schema + CRUD。" 1 "$P4_EPIC"
create_sub "P4.2: server NATS subscriber（binance.coverage.heartbeat）" "internal/server/coverage/subscriber.go：监听 client 心跳。" 1 "$P4_EPIC"
create_sub "P4.3: client coverage_reporter（周期 NATS 上报）" "internal/client/coverage_reporter.go：替代违宪的 PG 直写。" 1 "$P4_EPIC"
create_sub "P4.4: 删除 internal/client/history_state_postgres.go（违宪）" "物理删除文件。" 1 "$P4_EPIC"
create_sub "P4.5: cmd/binance-client/main.go 移除 postgresx 装配" "grep -rn 'postgresx\\.' cmd/ 应为 0。" 1 "$P4_EPIC"
create_sub "P4.6: 测试覆盖（单元 + 集成）" "coverage store/reporter 单元测试 + NATS 心跳集成测试。" 1 "$P4_EPIC"

echo ""
echo "=== [EPIC-5] Phase 5: P1 独立批次（3.5d，5 项并行） ==="
create_epic "Phase 5: P1 独立批次（5 项无依赖并行）" "GAP-E32/E27/E34/E36/E29 五项无相互依赖，独立 PR 并行。" ""
P5_EPIC=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")

create_task "GAP-E32: 7 处 goroutine 加 recover 包装" "client/runtime.go / server/admin.go / history_lifecycle.go / lifecycle_worker.go / client/admin.go / controlplane/lifecycle.go / assembly/assemble.go 共 7 处 go func() 无 defer recover()。" 1 "$P5_EPIC"

create_task "GAP-E27: WebSocket SetReadLimit（OOM 保护）" "internal/client/spot.go 或 stream_control.go 加 SetReadLimit(10 * 1024 * 1024) + json.Decoder 大小校验。" 1 "$P5_EPIC"

create_task "GAP-E34: HTTP server 完整超时（Read/Write/Idle）" "client/admin.go:87 + server/admin.go:65 仅设 ReadHeaderTimeout 5s。补 ReadTimeout/WriteTimeout/IdleTimeout。" 1 "$P5_EPIC"

create_task "GAP-E36: ldflags 注入 buildinfo" "Makefile 加 -ldflags '-X main.gitCommit=...' + 新建 internal/buildinfo/buildinfo.go + cmd/*/main.go --version 输出。" 1 "$P5_EPIC"

create_task "GAP-E29: 集成 golang-migrate migration runner" "10 个 .sql 当前需手动 psql。集成 golang-migrate/migrate/v4，cmd/binance-server migrate up 自动执行。" 1 "$P5_EPIC"

echo ""
echo "=== [EPIC-6] Phase 6: EXCHANGEINFO 分级（4d） ==="
create_epic "Phase 6: EXCHANGEINFO symbol 分级体系（白名单 MVP → 动态分级）" "EXCHANGEINFO 报告 §8.3：先白名单（0.5d 覆盖 90%）→ 再动态分级（3.5d 覆盖 100%）。§8.1 options 独立维度。" ""
P6_EPIC=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")

create_task "GAP-E26: interval SSOT（前置）" "新建 internal/client/intervals.go 常量。4 处独立定义改为引用。eventTypeToInterval 解析后缀去 1m fallback。" 1 "$P6_EPIC"

create_task "EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS）" "binancecfg 加 STREAM_SYMBOLS 配置 + stream_control.go:337 加白名单过滤。覆盖 ~90% 业务需求。改动 ~20 行。" 1 "$P6_EPIC"

create_task "GAP-E24: CatalogEntry Tier/SymbolPriority/Collection 动态分级" "CatalogEntry 加 4 字段 + decode 加 quoteVolume + classifyTier 三层降级 + binancecfg tiers YAML + lifecycle/WS 路由。" 1 "$P6_EPIC"

create_task "EXCHANGEINFO §8.1: options 独立维度（不进 Tier）" "期权按 (距到期天数, moneyness) 分桶。新建 internal/client/options_classification.go。近月 ATM → stream / 远月 OTM → 不采。" 1 "$P6_EPIC"

echo ""
echo "=== [EPIC-7] Phase 7: 数据完整性链（5d，7 项） ==="
create_epic "Phase 7: 数据完整性链（漏洞链 #1/#2/#4/#5/#14）" "GAP-E2/E3/E10/E12/E17/E18/E28 七项系列修复。" ""
P7_EPIC=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")

create_task "GAP-E2: server CompletenessScanner（完整性扫描器）" "internal/server/completeness/scanner.go：周期扫描 server-side coverage 缺口。" 1 "$P7_EPIC"
create_task "GAP-E3: E2E 二向对账 + OSS checksum" "reconciler + OSS 校验脚本。report/binance/e2e-reconcile-*.md。" 1 "$P7_EPIC"
create_task "GAP-E10: catalog diff NATS pub/sub" "server 订阅 client catalog diff，更新 SSOT。" 1 "$P7_EPIC"
create_task "GAP-E12: AckWait 30s → 5min + backfill 小批次" "AckWait 与 backfill timeout 对齐。批次 ≤ 100 symbol。" 1 "$P7_EPIC"
create_task "GAP-E17: server time.Now().UTC() 强制" "25+ 处 time.Now() 改为 UTC。" 1 "$P7_EPIC"
create_task "GAP-E18: TDengine 部分成功捕获（不重投）" "Partial=true 时记录 metric 不重投。" 1 "$P7_EPIC"
create_task "GAP-E28: PG 事务管理" "internal/server/storage/pg_tx.go：WithTx 包装。catalog/audit/idempotency 多步原子性。" 1 "$P7_EPIC"

echo ""
echo "=== [EPIC-8] Phase 8: P2+P3 治理与长尾（32d，9 批次） ==="
create_epic "Phase 8: P2+P3 治理与长尾（38 项 + 顶层文档）" "9 批次独立 PR：可观测性/安全/部署/Schema/配置/容错/优雅运行/测试/长尾 + P3 治理文档。" ""
P8_EPIC=$(grep -oP 'beads-\S+' /tmp/bd-last.log 2>/dev/null | head -1 || echo "TBD")

create_task "8.1 可观测性补强（E9+E30+E35）" "client metrics 聚合 + pprof/debug endpoint + metric 命名规范化。3d。" 2 "$P8_EPIC"
create_task "8.2 安全加固（E37+E44+E45）" "CSRF 防护 + SECURITY.md + CONTRIBUTING.md。1.5d。" 2 "$P8_EPIC"
create_task "8.3 部署治理（E41~E50）" "probe 深度 + 容器 hardening + distroless + K8s strategy。4d。" 2 "$P8_EPIC"
create_task "8.4 Schema 演进（E8+E19+E23）" "SchemaVersion 配置化 + PayloadHash server 重算 + 精度校验。4d。" 2 "$P8_EPIC"
create_task "8.5 配置治理（E31+E4）" "NATS 拓扑配置化 + throttle 配置化。2d。" 2 "$P8_EPIC"
create_task "8.6 容错与韧性（E11+E16+E33）" "REST fallback + 启动 retry + resiliencx 熔断接入。3d。" 2 "$P8_EPIC"
create_task "8.7 优雅运行（E14+E15+E20+E22）" "retention cron + 内存预算 + drain + 背压。3.5d。" 2 "$P8_EPIC"
create_task "8.8 测试与质量（E21+E40）" "CI race 强制 + HTTP client timeout。1d。" 2 "$P8_EPIC"
create_task "8.9 长尾低优（E38+E39）" "regexp 包级 var + 错误链 %w。0.5d。" 3 "$P8_EPIC"
create_task "P3 治理文档批次（E51~E58）" "SPEC 章节 / BR 编号补全 / server FR 下沉 / STANDARD+FEATURES+ACCEPTANCE+TRACEABILITY 补全 / ADR-001 / evidence 引用 / GAP-E58 issue close 校验。3.7d。" 3 "$P8_EPIC"

echo ""
echo "=== beads 创建完成 ==="
echo "总数：1 root + 8 phase epic + ~35 task + ~7 subtask = ~50 个 issue"
echo ""
echo "下一步："
echo "  1. 修复 gh auth login（当前 401）"
echo "  2. 运行 bash 010-sync-gh-issues.sh 同步到 GitHub"
echo "  3. bd dep add 配置依赖（见 plan §3.2）"
