#!/usr/bin/env bash
# GitHub issue 同步脚本（PLAN-010）
# 用法：bash 010-sync-gh-issues.sh [--dry-run]
# 前置：gh auth login（当前 401 失败）
set -euo pipefail

if [[ "${1:-}" != "--legacy-force" && "${1:-}" != "--dry-run" ]]; then
  echo "⚠️ ARCHIVED: 010 系列为历史脚本，默认禁止执行。"
  echo "如需仅查看请使用 --dry-run；确需旧流程执行请显式传 --legacy-force。"
  exit 2
fi

DRY_RUN="${1:-}"
REPO="xhyperium/binance"

# 校验 gh 认证
if ! gh auth status >/dev/null 2>&1; then
  echo "❌ gh CLI 未认证。请先：gh auth login"
  echo "   或：export GH_TOKEN=<your-token>"
  exit 1
fi

echo "=== 同步到 $REPO ==="
echo ""

# 通用函数
gh_create() {
  local title="$1" body="$2" labels="${3:-runtime-gap}"
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "[dry-run] $title"
    echo "  labels: $labels"
    echo "  body: ${body:0:80}..."
    return 0
  fi
  gh issue create -R "$REPO" --title "$title" --body "$body" --label "$labels" 2>&1 | tail -1
}

# Phase 1 issues（治理分裂，9 项）
echo "=== Phase 1: 治理分裂（7 个 issue） ==="
gh_create "[P0][Phase-1] T0-1/T8-1: Runtime-Version 三处统一为 v0.11.0" "$(cat <<'EOF'
## 现状
- SPEC.md L7: `Runtime-Version: v0.8.0`
- README.md L6: `Runtime-Version: v0.8.0`
- DEPLOY.md: `Runtime-Version: v0.11.0 (anchor: f53303f)`
- 实际 `git -C /home/workspace/binance describe --tags`: `f53303f`（**无 v0.11.0 tag**）

## 修复
1. runtime 仓 `git tag v0.11.0 f53303f`
2. `gh release create v0.11.0 --notes-file ...`
3. SPEC.md + README.md Runtime-Version 改为 v0.11.0

## 验收
- [ ] `git -C /home/workspace/binance tag -l 'v*'` 含 v0.11.0
- [ ] SPEC/README/DEPLOY 三处版本一致
- [ ] gh release view v0.11.0 -R xhyperium/binance 成功

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P0,phase-1,governance-trap,runtime-gap"

gh_create "[P0][Phase-1] T7-1: PRG-006 TRACEABILITY §4 降级 Partial" "$(cat <<'EOF'
## 现状（状态分裂）
- `matrix/TRACEABILITY.md` §4: PRG-006 = PASS
- `todo.md` L23: PRG-006 = **Partial**（gated 测试默认 CI 跑不到）

## 修复
1. `matrix/TRACEABILITY.md` §4 PRG-006 从 PASS → Partial
2. 加 gated 测试说明（todo.md L26-32 已有内容）
3. release_closeable 公式后加"运行时口径注脚"

## 验收
- [ ] diff TRACEABILITY.md §4 vs todo.md PRG-006 一致
- [ ] todo.md L23 仍为 Partial（不改 todo）

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P0,phase-1,governance-trap"

gh_create "[P0][Phase-1] T7-2: 补 v0.11.0 GitHub Release（PRG-002）" "$(cat <<'EOF'
## 现状
- `git -C /home/workspace/binance tag -l 'v*'` 输出**完全为空**
- 连 v0.8.0 都没有，PRG-002 实际不满足

## 修复
1. `git tag v0.11.0 f53303f && git push origin v0.11.0`
2. `gh release create v0.11.0 --notes-file release-notes-v0.11.0.md`
3. release notes: PR #364 gap repair runtime bugs（NATS timeout, kline storage, Kafka topic, stale gate, gap-fill guard）

## 验收
- [ ] `gh release view v0.11.0 -R xhyperium/binance` 成功
- [ ] release notes 含 PR #364 描述

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P0,phase-1,governance-trap"

gh_create "[P1][Phase-1] T1-1: CHANGELOG vs SPEC 版本单向追溯" "$(cat <<'EOF'
## 现状
- `CHANGELOG.md`: Module-Version: v3.9.7
- `spec/SPEC.md`: Spec-Version: v3.9.6
- 违反单向追溯（CHANGELOG 应 ≤ SPEC）

## 修复
推荐：SPEC bump 到 v3.9.7（同 PR）
- spec/SPEC.md Spec-Version: v3.9.7
- spec/client/SPEC.md / spec/server/SPEC.md 对齐
- matrix/TRACEABILITY.md Module-Version 同步

## 验收
- [ ] grep Spec-Version SPEC.md = grep Module-Version CHANGELOG.md

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P1,phase-1,governance-trap"

gh_create "[P1][Phase-1] T2-1: evidence/ 补 GAP-E 引用" "$(cat <<'EOF'
## 现状
- `grep -rl "GAP-E" module/binance/evidence/` = 0 文件（断链）

## 修复
1. 新建 evidence/2026-07-02/runtime-gap-closure.md
2. 引用 GAP-E1/E6/E25 等关键缺口
3. 标注 RUNTIME-GAP-MATRIX.md SSOT

## 验收
- [ ] evidence/ 至少 1 个文件含 "GAP-E1" 引用
- [ ] evidence/ 至少 1 个文件含 "RUNTIME-GAP-MATRIX" 引用

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P1,phase-1,governance-trap"

gh_create "[P1][Phase-1] GAP-E44/E45: 新建 SECURITY.md + CONTRIBUTING.md" "$(cat <<'EOF'
## 现状
- `ls module/binance/SECURITY.md` MISSING
- `ls module/binance/CONTRIBUTING.md` MISSING

## 修复
1. SECURITY.md：基于 gate/SECURITY.md 或独立写（admin token / API key / 凭证管理）
2. CONTRIBUTING.md：CONSTITUTION §0 + 分支纪律 + PR 规范 + issue close 时校验 runtime gap

## 验收
- [ ] SECURITY.md ≥ 50 行
- [ ] CONTRIBUTING.md ≥ 50 行
- [ ] CONTRIBUTING.md 含 GAP-E58 issue close 校验流程

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P1,phase-1,governance-trap"

gh_create "[P1][Phase-1] T9-1: SCORECARD 测试维度评分下调" "$(cat <<'EOF'
## 现状
- TEST-ANALYSIS-20260630.md 含 2026-07-02 免责声明
- 部分描述与代码不符（已自爆）
- SCORECARD 测试维度 93 分需重新评分

## 修复
1. 重评 SCORECARD 测试维度（推荐 93 → 85）
2. 标注"基于 gated 测试，默认 CI 覆盖有限"

## 验收
- [ ] SCORECARD.md 测试维度更新
- [ ] 注脚引用 TEST-ANALYSIS 免责声明

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 1
EOF
)" "P1,phase-1,governance-trap"

# Phase 2 issue（GAP-E6）
echo ""
echo "=== Phase 2: GAP-E6 symbol 全量化 ==="
gh_create "[P0][Phase-2] GAP-E6: UM/CM/Options 4 线 ExchangeInfoRefresher 装配" "$(cat <<'EOF'
## 现状
- `internal/client/runtime.go:199-217` 仅 spot 装配（硬编码 ProductLineSpot）
- UM/CM/Options 的 FetchXxxExchangeInfo 函数存在但生产路径从未 wired
- options decode（exchangeinfo_option.go:30-36）无 status 字段，仅按 expiryDate > now 过滤

## 修复
1. exchangeinfo_option.go:30-36 加 `Status string` 字段
2. exchangeinfo_option.go:74-84 加 TRADING 过滤
3. runtime.go:199-217 改为 4 线循环装配
4. cmd/binance-client/main.go 加 ProductLine 多选配置项

## 验收
- [ ] `grep -n "ProductLineSpot" internal/client/runtime.go` ≤ 1 处
- [ ] options entry 全部 status="active"
- [ ] catalog 长度 spot > 1000

## ROI
**最高 ROI 缺口**（0.5d，约 80 行）

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 2
EOF
)" "P0,phase-2,runtime-gap"

# Phase 4 issues（GAP-E1 重构，含 7 个 subtask）
echo ""
echo "=== Phase 4: GAP-E1 重构（7 个 issue） ==="
gh_create "[P0][Phase-4] GAP-E1: 删除违宪 history_state_postgres.go + server 端 coverage SSOT" "$(cat <<'EOF'
## 现状
- `internal/client/history_state_postgres.go` 违宪（SPEC §75/§166 禁止 client 写 DB）
- client/server 边界 SSOT 与 §509 文件清单内部矛盾

## 修复（v3.2 重构方案）
1. **GAP-E7 前置**：SPEC §509 移除 history_state_postgres.go
2. server 端 PG 持久化 coverage（internal/server/coverage/store.go）
3. server NATS subscriber（binance.coverage.heartbeat）
4. client coverage_reporter（周期 NATS 上报）
5. 删除 internal/client/history_state_postgres.go
6. cmd/binance-client/main.go 移除 postgresx 装配
7. 测试：单元 + 集成

## 验收
- [ ] `grep -rn "history_state_postgres" internal/client/` = 0
- [ ] `grep -rn "postgresx\\." internal/client/` = 0
- [ ] server coverage 表存在 + client 上报可查

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 4
EOF
)" "P0,phase-4,runtime-gap"

# Phase 5 issues（5 个并行）
echo ""
echo "=== Phase 5: P1 独立批次（5 个并行 issue） ==="

gh_create "[P1][Phase-5] GAP-E32: 7 处 goroutine 加 recover 包装" "$(cat <<'EOF'
## 落点（7 处）
1. client/runtime.go（2 处）
2. server/admin.go
3. history_lifecycle.go
4. lifecycle_worker.go
5. client/admin.go
6. controlplane/lifecycle.go
7. assembly/assemble.go（2 处）

## 修复
每处 `go func() {...}` 加 `defer func() { if r := recover(); r != nil { log.Error(...) } }()`

## 验收
- [ ] `grep -rn "go func()" internal/ | wc -l` ≤ `grep -rn "recover()" internal/ | wc -l`

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 5
EOF
)" "P1,phase-5,runtime-gap,independent"

gh_create "[P1][Phase-5] GAP-E27: WebSocket SetReadLimit（OOM 保护）" "$(cat <<'EOF'
## 现状
- WebSocket 无 SetReadLimit，1GB 异常消息致 client OOM killed
- 6 处 json.Unmarshal 信任 ws msg 大小

## 修复
1. internal/client/spot.go 或 stream_control.go 加 `conn.SetReadLimit(10 * 1024 * 1024)`
2. json.NewDecoder + io.LimitReader

## 验收
- [ ] `grep -n "SetReadLimit" internal/client/` ≥ 1

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 5
EOF
)" "P1,phase-5,runtime-gap,independent"

gh_create "[P1][Phase-5] GAP-E34: HTTP server 完整超时" "$(cat <<'EOF'
## 落点
- client/admin.go:87 + server/admin.go:65

## 修复
加 ReadTimeout: 10s / WriteTimeout: 30s / IdleTimeout: 120s

## 验收
- [ ] grep "ReadTimeout\|WriteTimeout\|IdleTimeout" admin.go ≥ 6 处（client+server 各 3）

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 5
EOF
)" "P1,phase-5,runtime-gap,independent"

gh_create "[P1][Phase-5] GAP-E36: ldflags 注入 buildinfo" "$(cat <<'EOF'
## 现状
零 build info。生产事故无法从二进制反查版本。

## 修复
1. Makefile 加 ldflags 注入 gitCommit/buildtime/version
2. 新建 internal/buildinfo/buildinfo.go
3. cmd/*/main.go 加 --version flag

## 验收
- [ ] `binance-client --version` 输出 gitCommit + buildtime + version

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 5
EOF
)" "P1,phase-5,runtime-gap,independent"

gh_create "[P1][Phase-5] GAP-E29: 集成 golang-migrate migration runner" "$(cat <<'EOF'
## 现状
10 个 .sql 文件需手动 psql，部署 schema 漂移。

## 修复
1. 引入 github.com/golang-migrate/migrate/v4
2. cmd/binance-server 加 migrate 子命令
3. migrations/ 目录组织

## 验收
- [ ] `binance-server migrate up` 后所有 schema 就绪
- [ ] `binance-server migrate version` 输出当前版本

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 5
EOF
)" "P1,phase-5,runtime-gap,independent"

# Phase 6 issues（4 个）
echo ""
echo "=== Phase 6: EXCHANGEINFO 分级（4 个 issue） ==="
gh_create "[P1][Phase-6] GAP-E26: interval SSOT（前置）" "$(cat <<'EOF'
## 现状
4 处独立定义：product_line / history_rest / mapper / 测试。REST backfill 硬编码 fallback 1m。WebSocket 覆盖率 40%。

## 修复
1. 新建 internal/client/intervals.go SSOT 常量
2. 4 处独立定义改为引用
3. eventTypeToInterval() 解析 eventType 后缀（不 fallback）
4. WebSocket RequiredBarIntervals 扩展到 9 个标准 interval

## 验收
- [ ] grep RequiredBarIntervals 含 9 个 interval
- [ ] grep "fallback.*1m" internal/client/ = 0

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 6.0
EOF
)" "P1,phase-6,runtime-gap"

gh_create "[P1][Phase-6] EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS）" "$(cat <<'EOF'
## 设计（EXCHANGEINFO 报告 §8.3）
更便宜的替代方案，覆盖 ~90% 业务需求，0.5d。

## 修复
1. binancecfg 加 STREAM_SYMBOLS 配置字段（逗号分隔）
2. stream_control.go:337 加白名单过滤
3. 配置文档 + .env.example 更新

## 验收
- [ ] STREAM_SYMBOLS=BTCUSDT,ETHUSDT 时仅订阅 2 symbol
- [ ] 空白名单回退全量

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 6.1
EOF
)" "P1,phase-6,runtime-gap"

gh_create "[P1][Phase-6] GAP-E24: CatalogEntry 动态分级（Tier/SymbolPriority/Collection）" "$(cat <<'EOF'
## 设计
CatalogEntry 加 4 字段（Tier/SymbolPriority/Collection/QuoteVolumeUSD）+ decode 加 quoteVolume + classifyTier 三层降级 + binancecfg tiers YAML + lifecycle/WS 路由。

## 修复
1. CatalogEntry 扩展 4 字段
2. spot/um/cm decode 结构体加 QuoteVolume
3. classifyTier(symbol, quoteAsset, quoteVolumeUSD)
4. binancecfg tiers 配置
5. lifecycle SyncCatalog 加 Collection != "disabled" 过滤
6. stream_control 按 Collection 过滤

## 验收
- [ ] WS 订阅数 ≤ 1000（分级后）
- [ ] T0 配置生效（BTC/ETH 进 full_stream）

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 6.2
EOF
)" "P1,phase-6,runtime-gap"

gh_create "[P1][Phase-6] EXCHANGEINFO §8.1: options 独立维度（不进 Tier）" "$(cat <<'EOF'
## §8.1 勘误
options 按 quoteVolume 分级语义错配（末日/近月期权 gamma 交易最活跃）。改为按 (距到期天数, moneyness) 分桶。

## 修复
1. 新建 internal/client/options_classification.go
2. options refresher 装配 OptionsClassification 字段（不进 Tier）
3. lifecycle options 路由：近月 ATM → stream / 远月 OTM → 不采

## 验收
- [ ] options decode 加 status 字段（GAP-E6 协同）
- [ ] options_classification.go 存在

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 6.3
EOF
)" "P1,phase-6,runtime-gap"

# Phase 7 issues（7 个）
echo ""
echo "=== Phase 7: 数据完整性链（7 个 issue） ==="
for gap in E2 E3 E10 E12 E17 E18 E28; do
  case $gap in
    E2) title="GAP-E2: server CompletenessScanner"; desc="internal/server/completeness/scanner.go 周期扫描 server-side coverage 缺口。";;
    E3) title="GAP-E3: E2E 二向对账 + OSS checksum"; desc="reconciler + OSS 校验脚本。report/binance/e2e-reconcile-*.md。";;
    E10) title="GAP-E10: catalog diff NATS pub/sub"; desc="server 订阅 client catalog diff，更新 SSOT。subject: binance.catalog.diff。";;
    E12) title="GAP-E12: AckWait 30s → 5min + backfill 小批次"; desc="AckWait 与 backfill timeout 对齐（5min）。批次 ≤ 100 symbol。";;
    E17) title="GAP-E17: server time.Now().UTC() 强制"; desc="25+ 处 time.Now() 改为 UTC。跨时区部署时间戳漂移。";;
    E18) title="GAP-E18: TDengine 部分成功捕获（不重投）"; desc="Partial=true 时记录 metric binance_storage_partial_writes_total 不重投。";;
    E28) title="GAP-E28: PG 事务管理（多步写入原子性）"; desc="internal/server/storage/pg_tx.go: WithTx 包装。catalog/audit/idempotency 原子性。";;
  esac
  gh_create "[P1][Phase-7] $title" "## 摘要
$desc

## Plan Ref
plans/binance/010-runtime-gap-fix-execution-plan-20260702.md §Phase 7" "P1,phase-7,runtime-gap"
done

# Phase 8 issues（9 批次 + P3 文档）
echo ""
echo "=== Phase 8: P2+P3 治理与长尾（10 个 issue） ==="
gh_create "[P2][Phase-8.1] 可观测性补强（E9+E30+E35）" "client metrics 聚合 + pprof/debug endpoint + metric 命名规范化。3d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.2] 安全加固（E37+E44+E45）" "CSRF 防护 + SECURITY.md + CONTRIBUTING.md（注：SECURITY/CONTRIBUTING 已在 Phase 1 创建）。1.5d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.3] 部署治理（E41~E50）" "probe 深度 + 容器 hardening + distroless + K8s strategy。4d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.4] Schema 演进（E8+E19+E23）" "SchemaVersion 配置化 + PayloadHash server 重算 + 精度校验。4d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.5] 配置治理（E31+E4）" "NATS 拓扑配置化 + throttle 配置化。2d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.6] 容错与韧性（E11+E16+E33）" "REST fallback + 启动 retry + resiliencx 熔断接入。3d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.7] 优雅运行（E14+E15+E20+E22）" "retention cron + 内存预算 + drain + 背压。3.5d。" "P2,phase-8,runtime-gap"
gh_create "[P2][Phase-8.8] 测试与质量（E21+E40）" "CI race 强制 + HTTP client timeout。1d。" "P2,phase-8,runtime-gap"
gh_create "[P3][Phase-8.9] 长尾低优（E38+E39）" "regexp 包级 var + 错误链 %w。0.5d。" "P3,phase-8,runtime-gap"
gh_create "[P3][Phase-8.10] 治理文档批次（E51~E58）" "SPEC 章节 / BR 编号补全 / server FR 下沉 / STANDARD+FEATURES+ACCEPTANCE+TRACEABILITY 补全 / ADR-001 / GAP-E58 issue close 校验。3.7d。" "P3,phase-8,governance-trap"

echo ""
echo "=== GitHub 同步完成 ==="
echo "总计：~30 个 issue（Phase 1: 7 + Phase 2: 1 + Phase 4: 1 + Phase 5: 5 + Phase 6: 4 + Phase 7: 7 + Phase 8: 10）"
echo ""
echo "下一步："
echo "  1. gh issue list -R xhyperium/binance --state open  验证"
echo "  2. 在每个 issue 内补充 acceptance criteria + evidence 路径"
echo "  3. 配置 GitHub Projects 看板（可选）"
