# module/binance 完整审查 Prompt

> **版本**: v2.0.0
> **生成日期**: 2026-07-02
> **前序版本**: v1.0.0（`report/binance/REVIEW-PROMPT-20260630.md`，679 行）
> **目标模块**: `module/binance/`（spec hub）+ `/home/workspace/binance/`（runtime 仓）
> **审查基线**: CONSTITUTION.md §0-§19 + `docs/constitution/20-epistemic-standards.md`（§20）、FoundationX Pipeline (Goal→Spec→Plan→Matrix→Tasks→Prompt→Code→Evidence)、`docs/governance/REVIEW-STRATEGY.md`
> **适用场景**: AI agent 深度审查、CI 巡检、发布前门禁、治理审计、运行时缺口复核
> **输出**: 结构化审查报告 + 评分卡 + 问题清单 + 运行时缺口核验

---

## v2.0 相对 v1.0 的变更

| 变更类型 | 内容 |
| -------- | ---- |
| 新增 Part | Part 11「运行时缺口矩阵审查」——覆盖 GAP-E1~E58（58 项）+ 15 条漏洞链 + MVP 路径 + 源码抽样核验 |
| 新增 Part | Part 12「对抗性反审查」——基于 REVIEW-STRATEGY.md 反审查重点 + 已知陷阱验证 |
| 新增维度 | 双口径审查（规格口径 48 Done vs 运行时口径 58 Fixed（≥80%））贯穿 Part 7/8/13 |
| 新增检查 | Runtime-Version 三处一致性专项（SPEC / README / DEPLOY.md / 实际 HEAD） |
| 新增检查 | PRG-006 状态矛盾专项（SPEC/README/goal "全 PASS" vs todo.md "Partial"） |
| 新增检查 | EXCHANGEINFO symbol 分级体系（Tier/Priority/分层级）零支撑核验 |
| 新增检查 | 测试报告可信度核实（TEST-ANALYSIS-20260630.md 2026-07-02 免责声明） |
| 新增检查 | tag / Release / DEPLOY anchor 三者一致性（v0.8.0 tag vs v0.11.0 声明） |
| 更新基线 | Runtime HEAD `f53303f`（PR #364）、Module-Version v3.9.7、Go 1.26.4 |
| 更新对比 | 上轮基准采用 REVIEW-20260630 专项深度审查综合 97 分（SCORECARD 92 分为全模块快照，两者不矛盾，深度不同） |

---

## 审查目标

对 `module/binance` 模块执行端到端深度审查，覆盖 **15 个治理维度 + 管线 8 阶段 + 运行时缺口 58 项**，产出：

1. **评分矩阵**（15 维度 × 满分 100，含加权综合分 + 双口径分）
2. **红线清单**（违反硬约束的 CRITICAL 问题）
3. **修复优先级排序**（P0 阻塞发布 / P1 影响治理 / P2 优化建议）
4. **发布就绪判定**（双口径：规格口径 release_closeable + 运行时缺口口径）
5. **运行时缺口核验**（GAP-E1~E58 抽样源码验证 + 漏洞链确认）
6. **对比上轮审查**（REVIEW-20260630 综合 97 分，标注变化趋势）

---

## Part 0: 审查前准备

### 0.1 基线确认

执行以下命令确认当前基线，输出写入报告 §0（基线确认）：

```bash
# Spec hub 基线
echo "=== Spec Hub ==="
git -C /home/workspace/ZoneCNH log --oneline -5 -- module/binance/
echo ""
echo "=== Runtime 仓 ==="
git -C /home/workspace/binance log --oneline -5
git -C /home/workspace/binance describe --tags --always
echo ""
echo "=== Runtime tag 列表 ==="
git -C /home/workspace/binance tag -l 'v*'
echo ""
echo "=== 当前分支 ==="
git -C /home/workspace/ZoneCNH branch --show-current
git -C /home/workspace/binance branch --show-current
echo ""
echo "=== 未提交变更 ==="
git -C /home/workspace/ZoneCNH status --short -- module/binance/
git -C /home/workspace/binance status --short
echo ""
echo "=== Go 版本 ==="
go version
```

**已知陷阱验证 T0-1**（Runtime-Version 一致性）：以下四处声明的 Runtime-Version 必须一致，否则为 CRITICAL（状态分裂）：

| 位置 | 字段 | 预期 |
| ---- | ---- | ---- |
| `module/binance/spec/SPEC.md` L7 | `Runtime-Version` | 与实际 HEAD 对应的 tag |
| `module/binance/README.md` L6 | `Runtime-Version` | 同上 |
| `module/binance/deploy/DEPLOY.md` §头部 | `Runtime-Version` + anchor | 同上 |
| `/home/workspace/binance` 实际 | `git describe --tags` | 权威值 |

> **审查者注意**：截至 v2.0 生成时，SPEC.md/README.md 写 v0.8.0，DEPLOY.md 写 v0.11.0（f53303f），实际 HEAD 为 f53303f。runtime 为 shallow clone，本地无任何 tag（含 v0.8.0）。审查时需确认此分裂是否已修复，并用 `gh release view` 验证 GitHub Release。
>
> **2026-07-04 核验结论（已沉淀）**：`gh release view -R ZoneCNH/binance v0.8.0` 与 `v0.11.0` 均返回已发布 release（非 draft / 非 prerelease），Runtime version/tag 可按“历史 tag + 当前 tag 共存”口径解释，不再视为阻断项。

### 0.2 文件清单扫描

```bash
echo "=== Spec Hub 文件数 ==="
find /home/workspace/ZoneCNH/module/binance/ -type f | wc -l
find /home/workspace/ZoneCNH/module/binance/ -type f -name "*.md" | wc -l
echo ""
echo "=== Task 文件数 ==="
find /home/workspace/ZoneCNH/module/binance/tasks/ -name "TASK-*.md" | wc -l
echo ""
echo "=== Evidence 目录 ==="
find /home/workspace/ZoneCNH/module/binance/evidence/ -type d | sort
```

### 0.3 历史审查报告加载

阅读以下历史报告，提取上轮结论用于对比：

| 报告 | 用途 |
| ---- | ---- |
| `report/binance/REVIEW-20260630.md` | 上轮完整审查报告（综合 97 分，L3 Go） |
| `report/binance/SCORECARD.md` | 全模块评分卡（binance 92 分） |
| `report/binance/DEEP-ANALYSIS-20260630.md` | 上轮深度分析 |
| `report/binance/DATA-INTEGRITY-E2E-20260701.md` | 运行时数据完整性 58 缺口来源（v3.9，6358 行） |
| `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md` | symbol 分级体系分析 |
| `report/binance/TEST-ANALYSIS-20260630.md` | 测试体系分析（含 2026-07-02 免责声明） |

必须标注：
- 上次审查的 CRITICAL 问题是否已修复
- 上次评分变化趋势（REVIEW-20260630 综合 97 vs SCORECARD 92，差异原因）
- 07-01/07-02 新发现的增量问题（58 运行时缺口、双口径、EXCHANGEINFO 分级）

---

## Part 1: Spec Hub 审查（文档治理）

### 1.1 SPEC.md 23 节结构完整性

**入口文件**: `module/binance/spec/SPEC.md`

逐节核验下列 23 节是否存在、内容是否非空：

| 节号 | 节名 | 检查要点 |
| ---- | ---- | -------- |
| §1 | Goal | 模块目标是否明确、可测量 |
| §2 | Authority | 权威来源声明是否完整 |
| §3 | Scope | 边界是否清楚（包含/不包含） |
| §4 | Runtime Boundary | Client/Server/Wire/Config 四子系统职责与禁止项 |
| §5 | State Model | 状态模型是否单一且无歧义（single-state only） |
| §6 | Product Lines and Event Types | 4×6 矩阵是否完整 |
| §7 | Functional Requirements | FR 表：ID / Scope / Requirement / State / Closure evidence |
| §8 | Business Requirements | BR 表：ID / Rule / Verification |
| §9 | Acceptance Criteria | AC 编号 + Requirement + State |
| §10 | NATS and Kafka Contracts | subject/topic 定义 |
| §11 | Configuration | 配置项引用 CONFIG-SCHEMA.md |
| §12 | API Boundary | REST/gRPC 路由定义 |
| §13 | Persistence Boundary | 存储约束 |
| §14 | Error Model | 错误码/错误分类/恢复策略 |
| §15 | Observability | metrics/logs/traces 三件套 |
| §16 | Security | 认证/授权/加密/凭证管理 |
| §17 | Deployment | 部署拓扑/HA/DR |
| §18 | Testing Strategy | 测试分层/覆盖率目标 |
| §19 | Migration | 架构迁移路径 |
| §20 | Dependencies | 外部依赖清单 |
| §21 | Changelog | 版本变更记录引用 |
| §22 | Release DoD + §22a Runtime Gap Matrix Reference | DoD 清单 + 双口径引用 |
| §23 | References | 交叉引用文档列表 |

**产出**：23 节完整性表（✅/⚠️/❌）+ 每节详细问题描述

### 1.2 子模块 SPEC 检查

检查 `spec/client/SPEC.md` 和 `spec/server/SPEC.md`：

- 版本号是否与 root SPEC 对齐
- FR 编号是否与 root SPEC 对齐
- 是否有独立声明的状态与 root SPEC 矛盾
- **GAP-E54 核验**：server/SPEC.md 是否仍只声明 36 FR（root 48 FR，12 FR 未下沉）

```bash
echo "=== 版本一致性 ==="
echo "Root SPEC:"
grep -m1 'Spec-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
echo "Client SPEC:"
grep -m1 'Spec-Version' /home/workspace/ZoneCNH/module/binance/spec/client/SPEC.md
echo "Server SPEC:"
grep -m1 'Spec-Version' /home/workspace/ZoneCNH/module/binance/spec/server/SPEC.md
echo ""
echo "=== FR 数量对比（GAP-E54）==="
echo "Root FR count:"
grep -cE '^\| FR-[0-9]+' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
echo "Server FR count:"
grep -cE '^\| FR-[0-9]+' /home/workspace/ZoneCNH/module/binance/spec/server/SPEC.md
```

### 1.3 FEATURES.md / ACCEPTANCE.md 对齐

- FEATURES.md 的 FR 状态是否与 SPEC.md §7 一致
- ACCEPTANCE.md 的 PRG 状态是否与 matrix/TRACEABILITY.md §4 一致
- ACCEPTANCE.md §4 闭合矩阵的 Evidence 列是否全部填写
- 是否存在"单一状态模型"以外的状态声明

### 1.4 NAMING.md 合规

```bash
grep -rnE "(usdm_futures|coinm_futures|futures_usdt|futures_coin)" \
  /home/workspace/ZoneCNH/module/binance/ --include="*.md" \
  | grep -vE "NAMING\.md|ARCHITECTURE-DRIFT|archive/|DEPRECATED"
```

- product_line 命名是否统一使用 `spot` / `um_perp` / `cm_perp` / `options`
- 是否残留旧命名

### 1.5 SPEC.md 行数门禁

```bash
wc -l /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
wc -l /home/workspace/ZoneCNH/module/binance/matrix/TRACEABILITY.md
```

- AC-005: root SPEC < 1000 行
- AC-006: root TRACEABILITY < 200 行

### 1.6 双口径声明检查【v2.0 新增】

- SPEC.md §22a 是否存在「Runtime Gap Matrix Reference」小节
- §22a 是否引用 `RUNTIME-GAP-MATRIX.md`
- §22a 是否声明双口径正交关系（规格口径 48 Done vs 运行时口径 58 Fixed（≥80%））
- §5 State Model 是否仍为 single-state only（不得引入双态残留）

### 1.7 CHANGELOG 版本一致性【v2.0 新增】

**已知陷阱验证 T1-1**（GAP-E52）：CHANGELOG Module-Version 与 SPEC Spec-Version 的单向追溯关系。

```bash
echo "CHANGELOG Module-Version:"
grep -m1 'Module-Version' /home/workspace/ZoneCNH/module/binance/CHANGELOG.md
echo "SPEC Spec-Version:"
grep -m1 'Spec-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
```

- GAP-E52：CHANGELOG v3.9.7 比 SPEC v3.9.6 提前一版（破坏单向追溯）。审查时确认是否已修复。

---

## Part 2: 追溯矩阵审查

### 2.1 TRACEABILITY.md §1-§7 完整性

**入口文件**: `module/binance/matrix/TRACEABILITY.md`

| 节号 | 内容 | 检查要点 |
| ---- | ---- | -------- |
| §1 | Rule | 矩阵规则声明 |
| §2 | FR Matrix | FR → BR → AC → TC/Evidence → State 映射 |
| §3 | Acceptance Criteria | AC 编号 + Requirement + State |
| §4 | Production Readiness Gates | PRG-001~007 定义与状态 |
| §5 | TC→FR Reverse Trace | 测试用例 → FR 反向追溯 |
| §6 | Coverage Dashboard | FR/BR/NFR/AC/TC 总数/Done/覆盖率 |
| §7 | Change History | 变更记录 |

### 2.2 追溯链闭合验证（R1 跨表走查）

对每个 FR，验证存在从 FR → BR → AC → TC → Task → Evidence 的完整路径：

```bash
# 检查每个 FR 在 TRACEABILITY 中有 AC 和 TC 映射
for fr in $(seq -w 1 48); do
  id="FR-0${fr}"
  in_matrix=$(grep -c "$id" /home/workspace/ZoneCNH/module/binance/matrix/TRACEABILITY.md 2>/dev/null || echo 0)
  if [ "$in_matrix" -eq 0 ]; then
    echo "MISSING: $id not found in TRACEABILITY.md"
  fi
done

# 交叉验证 SPEC.md vs TRACEABILITY.md FR 状态
diff \
  <(grep -P '^\| FR-\d+' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md | awk -F'|' '{print $2, $5}' | sort) \
  <(grep -P '^\| FR-\d+' /home/workspace/ZoneCNH/module/binance/matrix/TRACEABILITY.md | awk -F'|' '{print $2, $6}' | sort)
```

### 2.3 子模块 TRACEABILITY 对齐

- `matrix/client/TRACEABILITY.md` 和 `matrix/server/TRACEABILITY.md` 是否存在
- 子模块的 FR 状态是否与 root TRACEABILITY 一致
- 子模块的 Module-Version 是否正确
- SC 编号（Scenario ID）是否已替代 TC 编号

### 2.4 §6 仪表盘自动统计验证

仪表盘的"实现状态"行必须从 §2 FR 表的 `State` 列派生，不得手写：

```bash
python3 -c "
import re
with open('/home/workspace/ZoneCNH/module/binance/matrix/TRACEABILITY.md') as f:
    content = f.read()
fr_section = content.split('## 2. FR Matrix')[1].split('## 3.')[0] if '## 3.' in content.split('## 2. FR Matrix')[1] else content.split('## 2. FR Matrix')[1]
done = len(re.findall(r'FR-\d+.*\| Done', fr_section))
partial = len(re.findall(r'FR-\d+.*\| Partial', fr_section))
pending = len(re.findall(r'FR-\d+.*\| Pending', fr_section))
drifted = len(re.findall(r'FR-\d+.*\| Drifted', fr_section))
print(f'FR Stats: Done={done}, Partial={partial}, Drifted={drifted}, Pending={pending}')
print(f'Total FR: {done+partial+drifted+pending}')
"
```

- 预期：48 Done / 0 Partial / 0 Drifted / 0 Pending

### 2.5 GAP-E 引用回填检查【v2.0 新增】

**已知陷阱验证 T2-1**（GAP-E57）：evidence 目录是否已补 GAP-E 引用。

```bash
echo "=== TRACEABILITY 是否引用 RUNTIME-GAP-MATRIX ==="
grep -c "RUNTIME-GAP-MATRIX" /home/workspace/ZoneCNH/module/binance/matrix/TRACEABILITY.md
echo ""
echo "=== evidence 目录是否引用 GAP-E ==="
grep -rl "GAP-E" /home/workspace/ZoneCNH/module/binance/evidence/ 2>/dev/null | wc -l
```

- GAP-E57：evidence 完全无 GAP-E 引用（断链）。审查时确认是否已回填。

---

## Part 3: 架构与设计审查

### 3.1 DESIGN.md 质量

**入口文件**: `module/binance/design/DESIGN.md`

- 是否为 Implemented 状态（非 Draft）
- 数据流图是否与 SPEC.md §2 和 README.md 一致
- 组件数量/名称是否与 ARCHITECTURE.md 状态表一致

### 3.2 ADR 审查

检查 `design/ADR-*.md`：

- ADR-002 (wire boundary): wire 层 contract 是否严格执行
- ADR-003 (order book rebuild exclusion): 决策是否在 runtime 中生效
- ADR-004 (FR-024 vs FR-036 architecture): 设计决策是否有代码锚点
- **GAP-E56 核验**：ADR-001 是否仍缺失（编号跳过）

```bash
ls -1 /home/workspace/ZoneCNH/module/binance/design/ADR-*.md 2>/dev/null
```

### 3.3 ARCHITECTURE-DRIFT-WATCHLIST 漂移扫描

按 `design/ARCHITECTURE-DRIFT-WATCHLIST.md` 的监控点 (D1-D11) 逐项执行检测命令，输出 PASS/FAIL。

特别关注：
- D9（限流模型漂移）
- D10（缺口检测策略漂移）
- D11（双态分歧 / release_closeable 分裂）

### 3.4 Runtime 架构审查

```bash
# 目录结构
find /home/workspace/binance/internal/ -type d | sort
# Client/Server 边界违规检查
grep -r "internal/server" /home/workspace/binance/internal/client/ --include="*.go" && echo "BOUNDARY VIOLATION: client imports server" || echo "OK: no client→server"
grep -r "internal/client" /home/workspace/binance/internal/server/ --include="*.go" && echo "BOUNDARY VIOLATION: server imports client" || echo "OK: no server→client"
# 死代码检查
grep -rn "TODO\|FIXME\|HACK" /home/workspace/binance/internal/ --include="*.go" | head -20 || echo "OK (no TODO/FIXME)"
# panic 检查
grep -rn "panic(" /home/workspace/binance/internal/ --include="*.go" | grep -v "_test.go" | grep -v "init()" || echo "OK (no panic)"
```

### 3.5 EXCHANGEINFO symbol 分级体系审查【v2.0 新增】

**入口报告**: `report/binance/EXCHANGEINFO-SYMBOL-TIER-ANALYSIS-20260702.md`

核验以下三个维度的运行时支撑：

| 维度 | 检查命令 | 预期（当前为零支撑） |
| ---- | -------- | -------------------- |
| Tier（分级） | `grep -rn "tier\|Tier" /home/workspace/binance/internal/client/catalog.go` | 零命中 |
| Priority（优先级） | `grep -rn "priority\|Priority" /home/workspace/binance/internal/client/catalog.go` | 零命中（lifecycle.go 的 priority 是任务排序非 symbol 分级） |
| 分层级 | `grep -rn "level\|Level" /home/workspace/binance/internal/client/catalog.go` | 零命中 |

```bash
echo "=== CatalogEntry 结构 ==="
grep -A 30 "type CatalogEntry struct" /home/workspace/binance/internal/client/catalog.go
echo ""
echo "=== symbol 分级信号全仓扫描 ==="
grep -rn "quoteVolume\|Tier\|tier" /home/workspace/binance/internal/client/ --include="*.go" | head -20
echo ""
echo "=== 采集谓词（是否仅 Status==active）==="
grep -rn 'Status.*active\|status.*TRADING' /home/workspace/binance/internal/client/ --include="*.go" | head -10
```

- 确认 GAP-E6（UM/CM/Options 未装配 ExchangeInfoRefresher）+ GAP-E24（无 Tier/Priority）是否仍为 Open
- 确认 EXCHANGEINFO 报告 §8 勘误（options 归 T4 语义错配、GAP-E25 依赖链倒置）是否已纳入考量

---

## Part 4: 实现计划与任务审查

### 4.1 PLAN.md 质量

**入口文件**: `module/binance/plan/PLAN.md` + `plan/client/PLAN.md` + `plan/server/PLAN.md`

- 是否包含 §1-§8 完整结构
- §8 停止条件是否与 SPEC.md release_closeable 公式一致
- 执行进度百分比是否与 tasks/ 实际完成数一致

### 4.2 Task 覆盖检查

```bash
echo "=== Task 文件总数 ==="
find /home/workspace/ZoneCNH/module/binance/tasks/ -name "TASK-*.md" | wc -l
echo "=== 按目录分组 ==="
find /home/workspace/ZoneCNH/module/binance/tasks/ -name "TASK-*.md" | sed 's|/[^/]*$||' | sort | uniq -c
```

- 每个 FR 是否有 ≥1 个 Task 覆盖
- 每个 Task 文件是否包含：Objective / Scope / Covers / Deliverables / Acceptance Criteria / Dependencies
- 47/47 tasks Done 是否属实

### 4.2.1 Task 计数矛盾专项【v2.0 新增 · 已知陷阱 T4-1】

**已知陷阱验证 T4-1**：实际 TASK 文件数与文档声称不一致。

```bash
echo "=== 实际 TASK 文件数 ==="
find /home/workspace/ZoneCNH/module/binance/tasks/ -name "TASK-*.md" | wc -l
echo "=== 按目录分组 ==="
find /home/workspace/ZoneCNH/module/binance/tasks/ -name "TASK-*.md" | sed 's|/[^/]*$||' | sort | uniq -c
echo "=== README 声称 ==="
grep -oE '[0-9]+/[0-9]+ tasks' /home/workspace/ZoneCNH/module/binance/README.md
echo "=== todo 声称 ==="
grep -oE '[0-9]+/[0-9]+ tasks' /home/workspace/ZoneCNH/module/binance/todo.md
```

- 截至 v2.0 生成时：实际 39 个 TASK 文件（8 root + 14 client + 17 server），但 README 声称 `47/47 tasks Done`
- 差异 8 个。可能原因：(a) 部分 task 已归档到 archive/；(b) README 计数含历史已删除 task；(c) 计数错误
- 审查时须核实 47 的来源，若无法解释 → **HIGH**（文档不可信）

### 4.3 Plan-Task 一致性

- PLAN.md 中的 Task 列表是否与 tasks/ 目录下实际文件一致
- Task 文件的 AC 是否与 SPEC.md 的 AC 编号对应

---

## Part 5: Prompt / Context Package 审查

### 5.1 Prompt 目录检查

**入口文件**: `module/binance/prompt/README.md`

- prompt/ 是否仅含 README.md（空壳）
- 如果为空壳，标注为管线已越过 S5 阶段（Prompt 不是阻塞项）
- 参考其他模块（observex/10 个 PROMPT 文件、ossx/7 个 PROMPT 文件），断言 binance 是否需要补齐

---

## Part 6: 代码质量审查（Runtime）

> 如果 `/home/workspace/binance/` 不可访问，跳过 Part 6，在报告中标注 `[FRAME, LOW] Runtime not accessible`。

### 6.1 构建与编译

```bash
cd /home/workspace/binance
go build ./...
go vet ./...
```

### 6.2 测试执行

```bash
cd /home/workspace/binance
go test ./... -count=1 -timeout=120s 2>&1 | tail -30
go test ./... -race -count=1 -timeout=180s 2>&1 | tail -30
```

### 6.3 测试覆盖率

```bash
cd /home/workspace/binance
go test ./... -coverprofile=coverage.out -count=1 -timeout=120s 2>&1 | tail -5
go tool cover -func=coverage.out | tail -1
```

**门禁**: total coverage ≥ 80%（CONSTITUTION.md 要求）；当前声称 99.9%

### 6.4 安全扫描

```bash
cd /home/workspace/binance
gitleaks detect --no-git 2>&1 | tail -10 || echo "gitleaks not installed"
govulncheck ./... 2>&1 | tail -10 || echo "govulncheck not installed"
```

### 6.5 边界门禁

```bash
cd /home/workspace/binance
bash -n scripts/boundary-gates.sh && ./scripts/boundary-gates.sh 2>&1 | tail -20
```

- 预期 15/15 PASS

### 6.6 代码规范

- 是否存在 `panic()` 调用（非 init/test 场景）
- 是否存在未处理的 error 返回值
- 是否存在 > 800 行的单文件
- `golangci-lint run` 是否通过

```bash
cd /home/workspace/binance
echo "=== 单文件行数 TOP 10 ==="
find internal/ cmd/ pkg/ -name "*.go" ! -name "*_test.go" -exec wc -l {} + | sort -rn | head -10
echo ""
echo "=== fmt.Errorf 用 %s 而非 %w（错误链断裂，GAP-E39）==="
grep -rn 'fmt.Errorf.*%s' /home/workspace/binance/internal/client/ --include="*.go" | head -10
```

### 6.7 运行时缺口抽样源码核验【v2.0 新增】

从 58 个运行时缺口中抽取以下高风险项，逐一源码验证（核对报告声称的文件+行号是否属实）：

| GAP-ID | 验证命令 | 预期（若缺口仍 Open） |
| ------ | -------- | --------------------- |
| GAP-E1 | `grep -rn "history_state_postgres\|coverage" /home/workspace/binance/internal/client/ --include="*.go"` | client 端存在 coverage 持久化（违宪） |
| GAP-E6 | `grep -n "ExchangeInfoRefresher\|ProductLine" /home/workspace/binance/internal/client/runtime.go` | 仅 spot 装配（L201 `ProductLine: ProductLineSpot`），UM/CM/Options 未装配 |
| GAP-E18 | `grep -n "Partial" /home/workspace/binance/internal/server/storage/taos_writer.go` | 部分成功被 `_` 忽略 |
| GAP-E25 | `grep -rn "ClientID\|clientID\|ShardKey" /home/workspace/binance/cmd/binance-client/ --include="*.go"` | 零命中（无分片机制） |
| GAP-E27 | `grep -n "SetReadLimit" /home/workspace/binance/internal/client/spot.go` | 零命中（无 OOM 保护） |
| GAP-E28 | `grep -rn "pgx\.Tx\|BeginTx\|\.Commit(" /home/workspace/binance/internal/server/storage/ --include="*.go"` | 零命中（PG 无事务） |
| GAP-E32 | `grep -rn "go func" /home/workspace/binance/internal/client/runtime.go /home/workspace/binance/internal/client/history_lifecycle.go` | 7 处 goroutine 无 recover |
| GAP-E37 | `grep -rn "csrf\|CSRF" /home/workspace/binance/internal/client/admin.go /home/workspace/binance/internal/server/admin.go` | 零命中（无 CSRF 防护） |

> **核验纪律**：每项必须记录 `[COMPUTED]` 实际 grep 结果，不得直接采信报告结论。若源码已修复，标注 GAP 状态从 Open → Fixed 并附证据。

---

## Part 7: 发布就绪审查

### 7.1 PRG 门禁核验

按 `matrix/TRACEABILITY.md §4`（权威来源），逐项核验 PRG-001~007：

| Gate | 检查内容 | 验证命令 |
| ---- | -------- | -------- |
| PRG-001 | CI runner 为 ubuntu-latest | 检查 CI workflow 文件 |
| PRG-002 | Release tag + GitHub Release 存在 | `git -C /home/workspace/binance tag -l 'v*'` + `gh release view` |
| PRG-003 | PRG 7/7 全 PASS | 逐项确认 |
| PRG-004 | Observability 全在线 | 确认 Jaeger/Grafana/Loki/AlertManager 可访问 |
| PRG-005 | Security 扫描清洁 | gitleaks + govulncheck PASS |
| PRG-006 | soak/chaos/canary 测试 PASS | 检查 evidence + 测试代码 gated 状态 |
| PRG-007 | GitHub + Beads issue 全关闭 | `gh issue list --state open` |

### 7.2 PRG-006 状态矛盾专项【v2.0 新增 · 已知陷阱 T7-1】

**已知陷阱验证 T7-1**：PRG-006 在不同文档中状态矛盾。

| 位置 | 声明 | 来源 |
| ---- | ---- | ---- |
| `spec/SPEC.md` L10 | `release_closeable: YES`（PRG-001~007 全 PASS） | `[COMPUTED]` |
| `README.md` L7 | `release_closeable=YES（PRG-001~007 全 PASS）` | `[COMPUTED]` |
| `goal/goal.md` L12 | `PRG-001~007 全 PASS` | `[COMPUTED]` |
| `todo.md` L23 | `PRG-006 = Partial`（gated 测试默认 CI 跑不到） | `[COMPUTED]` |

```bash
echo "=== 各文档 PRG-006 声明 ==="
echo "--- SPEC.md ---"
grep -i "PRG-006\|PRG.*006\|PRG-001~007" /home/workspace/ZoneCNH/module/binance/spec/SPEC.md | head -3
echo "--- README.md ---"
grep -i "PRG-006\|PRG.*006\|PRG-001~007" /home/workspace/ZoneCNH/module/binance/README.md | head -3
echo "--- goal.md ---"
grep -i "PRG-006\|PRG.*006\|PRG-001~007" /home/workspace/ZoneCNH/module/binance/goal/goal.md | head -3
echo "--- todo.md ---"
grep -i "PRG-006\|PRG.*006\|PRG-001~007" /home/workspace/ZoneCNH/module/binance/todo.md | head -5
echo "--- TRACEABILITY.md ---"
grep -i "PRG-006\|PRG.*006\|PRG-001~007" /home/workspace/ZoneCNH/module/binance/matrix/TRACEABILITY.md | head -5
```

**判定规则**：
- 若 todo.md 标 Partial 而 SPEC/README/goal 标"全 PASS" → **CRITICAL（状态分裂）**
- 审查者需独立核实 PRG-006 真实状态：soak/chaos/canary 测试是否 gated、默认 CI 是否覆盖
- 参考 `todo.md` L26-32 的 2026-07-02 复核修正（测试描述与代码不符的免责声明）

### 7.3 多源交叉验证 release_closeable

在以下至少 6 处检查 `release_closeable` 状态：

| 位置 | 预期状态 |
| ---- | -------- |
| `spec/SPEC.md` header | release_closeable: YES |
| `matrix/TRACEABILITY.md` header | release_closeable: YES |
| `README.md` Delivery-State | release_closeable=YES |
| `spec/ACCEPTANCE.md` Module-State | release_closeable=YES |
| `todo.md` | release_closeable=YES |
| `goal/goal.md` 状态 | L3 Production / Released |

如果任意两处不一致 → CRITICAL（状态分裂）

### 7.4 tag / Release / DEPLOY anchor 一致性【v2.0 新增 · 已知陷阱 T7-2】

**已知陷阱验证 T7-2**：runtime tag 与文档声明可能不一致。

```bash
echo "=== Runtime tags ==="
git -C /home/workspace/binance tag -l 'v*' | sort -V
echo ""
echo "=== DEPLOY.md 声明的版本 ==="
grep -m3 'Runtime-Version\|anchor' /home/workspace/ZoneCNH/module/binance/deploy/DEPLOY.md | head -3
echo ""
echo "=== GitHub Releases ==="
gh release list -R ZoneCNH/binance 2>/dev/null | head -5 || echo "gh not available or no access"
```

- 确认 runtime 仓 tag 状态：截至 v2.0 生成时，runtime 为 **shallow clone**（`git rev-parse --is-shallow-repository` = true），`git tag -l 'v*'` 返回**空**——本地无任何 tag（含 v0.8.0）
- 须用 `gh release view v0.8.0 -R ZoneCNH/binance` 验证 GitHub Release 是否真实存在（PRG-002 声称 PASS 的依据）
- 若 DEPLOY.md 声称 v0.11.0 但无对应 GitHub Release → PRG-002 实际不满足该版本

### 7.5 双口径发布判定【v2.0 新增】

| 口径 | SSOT | 当前声称 | 含义 |
| ---- | ---- | -------- | ---- |
| 规格口径 | `spec/SPEC.md` | 48 Done / release_closeable=YES | FR 功能面已闭合 |
| 运行时口径 | `RUNTIME-GAP-MATRIX.md` | 58 Fixed（≥80%） | 进入维护态，需持续对账防回退 |

**GAP-E58 元缺口**：issue 已 close ≠ 运行时缺口天然已修复。当前已回刷至 58 Fixed（≥80%），但仍需持续对账以防回退。

**审查者须回答**：
1. 规格口径 release_closeable=YES 是否合理（FR 功能面确实闭合）
2. 运行时口径 58 Fixed（≥80%）是否足以维持 L3 Production 维护态
3. todo.md L32 建议"补齐默认 CI 覆盖前不应标记为 L3 Production"是否应被采纳
4. 双口径是否需要在 SPEC/goal 中显式声明（而非仅在 RUNTIME-GAP-MATRIX.md）

### 7.6 治理等级判定

| 等级 | 条件 |
| ---- | ---- |
| L1 Prototype | goal + SPEC 骨架 + 边界声明 + 命名 |
| L2 Active | L1 + matrix + boundary gates + plan/tasks + runtime 编译与本地测试 |
| L3 Production | L2 + PRG 全 PASS + live_integration ≥ 15 + 外部 E2E/soak/release/rollback 证据 |

> **审查者注意**：当前 goal.md 声称 L3 Production / Released。结合 PRG-006 矛盾 + 58 运行时缺口，审查时须独立判定 L3 是否成立。

---

## Part 8: 文档一致性审查

### 8.1 核心文档版本一致性

| 文档 | Spec-Version / Module-Version | Runtime-Version | last-updated |
| ---- | ----------------------------- | --------------- | ------------ |
| `spec/SPEC.md` | | | |
| `spec/ACCEPTANCE.md` | | | |
| `spec/FEATURES.md` | | | |
| `matrix/TRACEABILITY.md` | | | |
| `spec/client/SPEC.md` | | | |
| `spec/server/SPEC.md` | | | |
| `matrix/client/TRACEABILITY.md` | | | |
| `matrix/server/TRACEABILITY.md` | | | |
| `README.md` | | | |
| `goal/goal.md` | | | |
| `gate/BOUNDARY-GATES.md` | | | |
| `design/DESIGN.md` | | | |
| `CHANGELOG.md` | | | |
| `deploy/DEPLOY.md` | | | |

### 8.2 Runtime-Version 分裂专项【v2.0 新增 · 已知陷阱 T8-1】

**已知陷阱验证 T8-1**：Runtime-Version 在 SPEC / README / DEPLOY.md / 实际 HEAD 四处可能不一致。

```bash
echo "=== Runtime-Version 全文档扫描 ==="
echo "--- SPEC.md ---"
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
echo "--- README.md ---"
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/README.md
echo "--- DEPLOY.md ---"
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/deploy/DEPLOY.md
echo "--- client/SPEC.md ---"
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/spec/client/SPEC.md
echo "--- server/SPEC.md ---"
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/spec/server/SPEC.md
echo "--- goal.md ---"
grep -m1 'v0\.' /home/workspace/ZoneCNH/module/binance/goal/goal.md
echo "--- 实际 runtime ---"
git -C /home/workspace/binance describe --tags --always
```

- 若任意两处 Runtime-Version 不一致 → **CRITICAL**
- 截至 v2.0 生成时：SPEC/README = v0.8.0，DEPLOY.md = v0.11.0，实际 HEAD = f53303f（无 v0.11.0 tag）

### 8.3 跨文档 FR 总数一致性

```bash
echo "=== FR 总数对比 ==="
for f in spec/SPEC.md matrix/TRACEABILITY.md spec/FEATURES.md spec/ACCEPTANCE.md; do
  cnt=$(grep -cE '^\| FR-[0-9]+' /home/workspace/ZoneCNH/module/binance/$f 2>/dev/null || echo "N/A")
  echo "$f: $cnt"
done
```

- 预期 48 FR

### 8.4 链接有效性

```bash
grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' /home/workspace/ZoneCNH/module/binance/ --include="*.md" -r \
  | sort -u | while read u; do
    repo=${u#ZoneCNH/}
    gh api "repos/ZoneCNH/$repo" >/dev/null 2>&1 || echo "404: $repo"
  done
```

### 8.5 文档同步检查表

交叉验证 `README.md` / `ARCHITECTURE.md` / `STATUS.md` 中 binance 模块的：
- 组件数量
- 版本号
- 状态描述
- 所属域

### 8.6 治理文档完整性【v2.0 新增】

**已知陷阱验证 T8-2**（GAP-E44/E45）：

```bash
echo "=== SECURITY.md 是否存在 ==="
ls /home/workspace/ZoneCNH/module/binance/SECURITY.md 2>/dev/null || echo "MISSING (GAP-E44)"
echo "=== CONTRIBUTING.md 是否存在 ==="
ls /home/workspace/ZoneCNH/module/binance/CONTRIBUTING.md 2>/dev/null || echo "MISSING (GAP-E45)"
echo "=== gate/ 目录治理文档 ==="
ls /home/workspace/ZoneCNH/module/binance/gate/
```

> 注：`gate/SECURITY.md` 存在但模块根 `SECURITY.md` 可能缺失（GAP-E44 指模块根）。审查时区分 gate/SECURITY.md 与根 SECURITY.md。

### 8.7 BR 编号连续性【v2.0 新增】

**已知陷阱验证 T8-3**（GAP-E53）：BR 编号数量与历史不一致。

```bash
echo "=== 当前 SPEC BR 编号 ==="
grep -oE 'BR-[0-9]+' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md | sort -t- -k2 -n | uniq
echo "=== 历史 CHANGELOG BR 记载 ==="
grep -i "BR.*总数\|BR-00[6-9]" /home/workspace/ZoneCNH/module/binance/CHANGELOG.md | head -5
```

- 截至 v2.0 生成时：当前 SPEC §8 仅有 BR-001~005（5 个），但 CHANGELOG v1.2.0/v2.1.0 记载历史"BR 总数 9"，v2.2.1 记载"BR-001~BR-009 → Implemented"
- BR-006~009 从 SPEC 消失（非"跳号"，是数量缩减）。审查时确认是否有意删除及 TRACEABILITY 是否同步

---

## Part 9: 证据体系审查

### 9.1 Evidence 目录结构

```bash
find /home/workspace/ZoneCNH/module/binance/evidence/ -type f | sort
```

按日期目录检查（截至 v2.0 生成时实际存在的目录）：
- `2026-06-26/`: release / retrospective / review / test
- `2026-06-27/`: review / test
- `2026-06-28/`: review / release / p10-alignment
- `2026-06-30/`: release / verification
- `2026-07-01/`: ⚠️ **不存在**——DATA-INTEGRITY 报告在 `report/binance/` 而非 `evidence/`

### 9.2 每条 PRG 的 Evidence 闭环

| PRG | Evidence 文件 | 证据充分性 |
| --- | ------------- | ---------- |
| PRG-001 | evidence/2026-06-30/release/ | |
| PRG-002 | evidence/2026-06-30/release/ | |
| PRG-003 | evidence/2026-06-30/release/ | |
| PRG-004 | evidence/2026-06-30/release/ | |
| PRG-005 | evidence/2026-06-30/release/ | |
| PRG-006 | evidence/2026-06-30/release/ | ⚠️ 重点核验（gated 测试） |
| PRG-007 | evidence/2026-06-30/release/ | ⚠️ 结合 GAP-E58 元缺口 |

### 9.3 测试报告可信度核实【v2.0 新增 · 已知陷阱 T9-1】

**已知陷阱验证 T9-1**：`TEST-ANALYSIS-20260630.md` 含 2026-07-02 复核免责声明（部分描述与代码不符）。

```bash
head -30 /home/workspace/ZoneCNH/report/binance/TEST-ANALYSIS-20260630.md
```

- 确认免责声明内容
- 重新核实报告中的关键声称：soak（3 个测试）、chaos（12 个测试）、security（9 个函数）、depth（76 个 Test / 125 处 Skip）
- 若 SCORECARD 测试维度 93 分基于该报告，标注评分可能需下调

### 9.4 GAP-E 引用断链核验【v2.0 新增】

```bash
echo "=== evidence 中 GAP-E 引用数 ==="
grep -rl "GAP-E" /home/workspace/ZoneCNH/module/binance/evidence/ 2>/dev/null | wc -l
echo "=== RUNTIME-GAP-MATRIX 是否被 evidence 引用 ==="
grep -rl "RUNTIME-GAP-MATRIX" /home/workspace/ZoneCNH/module/binance/evidence/ 2>/dev/null | wc -l
```

- GAP-E57：evidence 完全无 GAP-E 引用（断链）。确认是否已回填。

---

## Part 10: 治理合规审查

### 10.1 CONSTITUTION.md 对齐

按 CONSTITUTION.md §0-§19 + `docs/constitution/20-epistemic-standards.md`（§20）逐条核验：

- §0 分支纪律：当前 branch 是否从 main HEAD 创建
- §4 规格标准：23 节结构完整
- §10 变更管理：版本号递增合规（R3 bump 触发器）
- §14 质量门禁：覆盖率 ≥ 80% / race/vet/lint/secret scan
- §20 认识论标准：证据标签 `[KNOWN]`/`[COMPUTED]`/`[INFERRED]` 是否正确使用

### 10.2 管线阶段门禁

按 FoundationX Pipeline（Goal→Spec→Plan→Matrix→Tasks→Prompt→Code→Evidence）逐阶段评分：

| 阶段 | 产物 | 状态 | 得分 |
| ---- | ---- | ---- | ---- |
| S0-Goal | `goal/goal.md` | | |
| S1-Spec | `spec/SPEC.md` 23 节 | | |
| S2-Matrix | `matrix/TRACEABILITY.md` §1-§7 | | |
| S3-Design | `design/DESIGN.md` | | |
| S4-Tasks | `tasks/*.md` | | |
| S5-Plan | `plan/PLAN.md` | | |
| S6-Prompt | `prompt/*.md` | | |
| S7-Code | Runtime 代码 | | |
| S8-Test | 测试覆盖率 | | |
| S9-Review | Evidence 归档 | | |
| S10-Release | PRG 全 PASS | | |
| S11-Retrospective | `evidence/*/retrospective/` | | |

composite = min(S0...S11)，门禁为 98 分。

### 10.3 治理注册表合规【v2.0 新增】

#### registry.yaml 声明核验

**已知陷阱验证 T10-1**：CHANGELOG 2026-06-30 声称"registry.yaml：lifecycle 更新为 production，添加 maturity: L3"。

> ⚠️ **20 轮自审修正（轮 20）**：经验证 registry.yaml 中 binance 条目**已包含** `lifecycle: production` + `maturity: L3`（第 7-8 行）。此陷阱为**假阳性**——首次验证使用 `grep -A5` 未覆盖到第 7 行。保留验证命令供审查者复核值与 goal.md 声称一致。

```bash
echo "=== registry.yaml binance 完整声明 ==="
grep -A10 "^binance:" /home/workspace/ZoneCNH/module/registry.yaml
echo ""
echo "=== lifecycle 字段 ==="
grep -A10 "^binance:" /home/workspace/ZoneCNH/module/registry.yaml | grep -i "lifecycle\|maturity"
echo ""
echo "=== CHANGELOG 声称 ==="
grep "registry.yaml.*lifecycle\|registry.yaml.*maturity" /home/workspace/ZoneCNH/module/binance/CHANGELOG.md
```

- 确认 registry.yaml 中 binance 是否有 `lifecycle: production` 和 `maturity: L3`
- 若 CHANGELOG 声称已添加但实际缺失 → **HIGH**（治理 SSOT 与声称不一致）
- 确认 `domain: data`、`layer: business`、`arch_type: cs_module` 与 CONSTITUTION §1.1 一致

#### FOUNDATION-DEPS.yaml 依赖边核验

```bash
echo "=== binance 下游依赖（允许的依赖边）==="
grep -A1 "^  binance:" /home/workspace/ZoneCNH/module/FOUNDATION-DEPS.yaml
echo ""
echo "=== binance 上游依赖 ==="
grep "binance" /home/workspace/ZoneCNH/module/FOUNDATION-DEPS.yaml | grep -v "^  binance:"
```

- 确认 binance 的依赖边符合 FOUNDATION-DEPS.yaml 声明
- binance 作为数据域模块，下游应为分析域/决策域模块（factor_engine 等）
- 确认无禁止依赖边（如 binance 依赖 orderx/positionx 等执行域模块）

#### ci-workflow.yaml 核验

```bash
echo "=== ci-workflow.yaml 存在性 ==="
ls /home/workspace/ZoneCNH/module/binance/ci-workflow.yaml
echo "=== CI runner 类型（PRG-001）==="
grep -i "runs-on\|runner" /home/workspace/ZoneCNH/module/binance/ci-workflow.yaml
```

- 确认 CI runner 为 ubuntu-latest（PRG-001 要求）
- 确认 CI workflow 覆盖 build/vet/test/race/lint/boundary-gates

---

## Part 11: 运行时缺口矩阵审查【v2.0 新增】

> 本 Part 基于 `module/binance/RUNTIME-GAP-MATRIX.md`（58 项缺口）+ `report/binance/DATA-INTEGRITY-E2E-20260701.md`（v3.9，6358 行，27 轮对抗性自审）。

### 11.1 缺口总览核验

```bash
echo "=== RUNTIME-GAP-MATRIX 存在性 ==="
ls -la /home/workspace/ZoneCNH/module/binance/RUNTIME-GAP-MATRIX.md
echo ""
echo "=== 缺口统计（唯一 GAP-ID 计数）==="
grep -oE 'GAP-E[0-9]+' /home/workspace/ZoneCNH/module/binance/RUNTIME-GAP-MATRIX.md | sort -u | wc -l
```

确认以下统计是否准确：

| 维度 | 声称值 | 核验结果 |
| ---- | ------ | -------- |
| 总缺口数 | 58 | |
| P0 (CRITICAL) | 3（GAP-E1, E6, E25） | |
| P1 (HIGH) | 13 | |
| P2 (MEDIUM) | 22 | |
| P3 (LOW) | 20 | |
| 漏洞链 | 15 | |
| 总工时 | ~73.5 人天 | |

### 11.2 P0 缺口源码验证

对 3 个 CRITICAL 缺口逐一源码核验（详见 Part 6.7）：

| GAP-ID | 类别 | 一句话 | 核验结果 |
| ------ | ---- | ------ | -------- |
| GAP-E1 | 边界合宪 | coverage 状态持久化违反 client/server 边界 | |
| GAP-E6 | 目录覆盖 | UM/CM/Options 未装配 ExchangeInfoRefresher | |
| GAP-E25 | 水平扩展 | client 无 ClientID/分片机制 | |

### 11.3 漏洞链确认

核验 15 条漏洞链是否仍然成立（多缺口协同放大效应）：

| # | 链路名称 | 组成 | 是否仍成立 |
| - | -------- | ---- | ---------- |
| 1 | TDengine 数据双写漏洞链 | E12 + E18 + E19 | |
| 2 | catalog/coverage SSOT 链 | E1 + E10 + E20 | |
| 3 | schema 演进链 | E8 + E19 + E23 | |
| ... | （其余 12 条见 RUNTIME-GAP-MATRIX §3） | | |

> 审查者须至少抽样验证 3 条漏洞链的源码锚点是否仍存在。

### 11.4 MVP 路径合理性评估

评估 `RUNTIME-GAP-MATRIX.md §5` 的 MVP 分批建议是否合理：

```
MVP-M（工程基线）→ MVP-J（安全运维）→ MVP-A+（单机加速）→ MVP-F（分级采集）→ MVP-G（水平扩展）→ MVP-I（完整治理）→ MVP-O（终极完整）
```

- 独立可上项（GAP-E6/E27/E32/E34/E36 等）是否真的无依赖
- 关键路径（GAP-E6 → E26 → E24 → E31 → E25 → E28 → E1/E7/E10/E20）顺序是否正确

### 11.5 双口径正交性验证

确认以下声明是否成立：
- 规格口径 48 Done 与运行时口径 58 Fixed（≥80%）正交（不矛盾）
- 规格 Done 是必要条件，不是充分条件
- CI 脚本 `binance-status-consistency-check.sh` 校验规格口径，运行时缺口在独立制品追踪
- GAP-E58 元缺口（issue close ≠ 运行时修复）是否被正确理解

---

## Part 12: 对抗性反审查【v2.0 新增】

> 基于 `docs/governance/REVIEW-STRATEGY.md` 的反审查原则：「刻意寻找这一层哪里可能错、漏、偏、被误用、被模型误解」。
> FoundationX 量化交易属于高风险（涉及资金、交易所接口），每一层都必须审查，关键层做反审查。

### 12.1 Spec 反审查

- 有没有隐藏假设？SPEC §5 single-state only 是否掩盖了真实复杂度（双口径问题）
- §22a 双口径声明是否只是「声明」而无治理约束（即声明了但没人执行）
- 48 FR Done 是否存在「形式 Done 但实质未 Done」（如 GAP-E58 元缺口揭示的 issue close ≠ 修复）

### 12.2 Matrix 反审查

- 有没有「看起来合理但 Spec 没要求」的 FR
- PRG-006 "全 PASS" 声称是否是伪闭合（gated 测试默认 CI 不跑）
- TRACEABILITY §6 仪表盘 100% Done 是否过于完美（反奉承红旗）

### 12.3 Code 反审查

- 有没有边界条件错误（GAP-E18 部分成功被忽略）
- 有没有竞态条件（GAP-E13 deadletter replay 跨进程内存 map）
- 有没有数据泄露（GAP-E37 CSRF 缺失、GAP-E27 OOM）
- 有没有模型编造的 API 或不存在的库
- resiliencx 基座 import 未接入（GAP-E33）—— 熔断/重试能力零使用

### 12.4 已知陷阱验证总表

汇总所有已知陷阱验证点，逐一确认状态：

| 陷阱 ID | 描述 | 验证方法 | 结果 |
| ------- | ---- | -------- | ---- |
| T0-1 | Runtime-Version 四处不一致（SPEC/README=v0.8.0 vs DEPLOY.md=v0.11.0 vs HEAD=f53303f） | Part 0.1 / Part 8.2 | |
| T1-1 | CHANGELOG v3.9.7 比 SPEC v3.9.6 提前一版（GAP-E52） | Part 1.7 | |
| T2-1 | evidence 无 GAP-E 引用（GAP-E57，0 文件） | Part 2.5 / Part 9.4 | |
| T4-1 | Task 计数矛盾：实际 39 文件 vs README 声称 47/47 | Part 4.2.1 | |
| T7-1 | PRG-006 "全 PASS"（SPEC/README/goal）vs todo.md "Partial" | Part 7.2 | |
| T7-2 | shallow clone 本地无任何 tag（含 v0.8.0）；DEPLOY.md 声称 v0.11.0 | Part 7.4 | |
| T8-1 | Runtime-Version 分裂（SPEC/README vs DEPLOY.md） | Part 8.2 | |
| T8-2 | 根 SECURITY.md / CONTRIBUTING.md 缺失（GAP-E44/E45） | Part 8.6 | |
| T8-3 | BR 数量缩减：历史 9 个（BR-001~009）现仅 5 个（GAP-E53） | Part 8.7 | |
| T9-1 | TEST-ANALYSIS 报告含 2026-07-02 免责声明（部分描述与代码不符） | Part 9.3 | |
| T10-1 | registry.yaml lifecycle/maturity（自审验证：已存在，假阳性，审查时复核值） | Part 10.3 | |

### 12.5 反向验收（Code → Spec）

从下往上看：

```
Code → Prompt → Plan → Tasks → Matrix → Spec
```

- 这段代码真的服务于原始 Spec 吗
- 有没有代码实现了一个看似合理、但并非 Spec 要求的东西（野生需求）
- 58 个运行时缺口是否说明 Spec 的 "Done" 定义过宽（应纳入运行时口径）

### 12.6 转换损耗检查

四个最危险转换点：

| 转换点 | 检查 |
| ------ | ---- |
| Spec → Matrix | 48 FR 是否全部进入 Matrix，有无信息丢失 |
| Matrix → Tasks | 每个 FR 是否有 Task 覆盖，有无新假设注入 |
| Prompt → Code | （prompt 空壳，标注为已越过） |
| Code → Spec | runtime 代码是否真的满足 Spec，58 缺口是否说明不满足 |

---

## Part 13: 评分

### 13.1 多维度评分矩阵

对下列 15 个维度按 0-100 评分，输出得分 + 等级 + 扣分原因：

| 维度 | 满分 | 上轮（REVIEW-20260630） | 本轮 | Δ | 扣分项 |
| ---- | ---- | ----------------------- | ---- | - | ------ |
| A. Spec 结构完整性 | 100 | 96 | | | |
| B. 追溯矩阵闭合 | 100 | 98 | | | |
| C. Design 架构质量 | 100 | 95 | | | |
| D. Runtime 代码质量 | 100 | 100 | | | |
| E. Client/Server 边界 | 100 | 97 | | | |
| F. 测试与验证 | 100 | 98 | | | |
| G. CI/CD 管线 | 100 | 98 | | | |
| H. 安全与合规 | 100 | 96 | | | |
| I. 可观测性 | 100 | 95 | | | |
| J. 生产就绪 (L3) | 100 | 95 | | | |
| K. 文档一致性 | 100 | 96 | | | |
| L. 运行时缺口覆盖【新】 | 100 | N/A | | | |
| M. EXCHANGEINFO 分级【新】 | 100 | N/A | | | |
| N. 双口径治理【新】 | 100 | N/A | | | |
| O. 证据可信度【新】 | 100 | N/A | | | |
| **加权综合** | 100 | **97** | | | |

### 13.2 双口径评分【v2.0 新增】

| 口径 | 得分 | 含义 |
| ---- | ---- | ---- |
| 规格口径综合分 | | FR 功能面闭合度 |
| 运行时口径综合分 | | 生产部署实际健康度（受 58 缺口影响） |
| **发布判定分** | min(规格, 运行时) | 保守取低值 |

### 13.3 评分纪律

- **R0 措辞强度分级**：只对【硬】约束（必须/不得/禁止/触发）扣分
- **R1 跨表走查**：遍历 §1-§5 全部验证列
- **R2 辅助元数据排除**：覆盖率仪表盘/变更历史不参与评分
- **R3 形式降级抑制**：所有可验证机制形式视为有效，仅空白/缺失扣分
- **R4 反奉承**：100% Done / 满分项需额外质疑（反奉承红旗）
- **R5 双口径分离**：规格口径评分不得因运行时缺口扣分，反之亦然；但发布判定取低值

---

## Part 14: 问题汇总

### 14.1 按严重度分类

| 严重度 | 数量 | 描述 |
| ------ | ---- | ---- |
| 🔴 CRITICAL | | 阻碍发布或安全漏洞 |
| 🟠 HIGH | | 影响治理可信度 |
| 🟡 MEDIUM | | 建议修复 |
| 🟢 LOW | | 优化建议 |

### 14.2 CRITICAL 问题详情

对每个 CRITICAL 问题，记录：
- 位置（文件 + 行号）
- 严重性评估
- 影响范围
- 修复建议
- 预估工时
- 关联 GAP-ID（如适用）

### 14.3 运行时缺口状态汇总【v2.0 新增】

| GAP 严重度 | 声称 Open 数 | 源码验证后实际 Open 数 | 已修复数 |
| ---------- | ------------ | ---------------------- | -------- |
| P0 (CRITICAL) | 3 | | |
| P1 (HIGH) | 13 | | |
| P2 (MEDIUM) | 22 | | |
| P3 (LOW) | 20 | | |
| **合计** | **58** | | |

### 14.4 对比上轮审查

| 指标 | 上轮（REVIEW-20260630） | 本轮 | Δ |
| ---- | ----------------------- | ---- | - |
| 综合得分 | 97 | | |
| CRITICAL 数量 | 0 | | |
| PRG 通过数 | 7/7 | | |
| release_closeable（规格口径） | YES | | |
| 运行时缺口数 | N/A（未审查） | | |
| Runtime HEAD | 8d11b0a | | |
| 治理等级 | L3 Production | | |

---

## Part 15: 发布建议

### 15.1 双口径 Go/No-Go 判定【v2.0 升级】

**规格口径**：
- **Go**: 综合 ≥ 85 + 0 CRITICAL + 全部 PRG PASS
- **Conditional Go**: 综合 ≥ 75 + 0 CRITICAL + ≥5/7 PRG PASS
- **No-Go**: 综合 < 75 或 存在 CRITICAL 或 <5/7 PRG PASS

**运行时口径**：
- **Go**: 0 P0 Open + 0 P1 Open
- **Conditional Go**: 0 P0 Open + ≤3 P1 Open（附修复计划）
- **No-Go**: 任何 P0 Open 或 >3 P1 Open

**综合判定**：min(规格, 运行时)

### 15.2 阻塞清单

| 阻塞项 | 严重度 | 口径 | 预计修复时间 | 阻塞什么 |
| ------ | ------ | ---- | ------------ | -------- |
| | | | | |

### 15.3 修复路线图

建议按 Phase 组织修复：

- **Phase 1**: 状态分裂修复（Runtime-Version 统一 + PRG-006 矛盾消除 + tag 补齐）
- **Phase 2**: MVP-M 工程基线（GAP-E32/E34/E36，2d，全部独立可上）
- **Phase 3**: MVP-J 安全运维（GAP-E27/E29/E30，2.5d，全部独立可上）
- **Phase 4**: GAP-E6 symbol 全量化（0.5d，ROI 最高）
- **Phase 5**: 分级采集体系（GAP-E24/E26 + EXCHANGEINFO 分级）
- **Phase 6**: 水平扩展（GAP-E25 + E1/E7/E10/E20 同 PR）
- **Phase 7**: 数据完整性闭环（GAP-E2/E3 + schema 治理 E8/E19/E23）
- **Phase 8**: 剩余 P2/P3 缺口

---

## 输出格式要求

### 报告文件

```
report/binance/REVIEW-{YYYYMMDD}.md
```

### 报告结构

```markdown
# binance 模块完整审查报告

> 审查日期 / 审查范围 / 审查方法 / 基线信息

## 执行摘要

## 基线确认

## 1. Spec Hub 审查
## 2. 追溯矩阵审查
## 3. 架构与设计审查
## 4. 实现计划与任务审查
## 5. Prompt 审查
## 6. 代码质量审查（Runtime）
## 7. 发布就绪审查
## 8. 文档一致性审查
## 9. 证据体系审查
## 10. 治理合规审查
## 11. 运行时缺口矩阵审查
## 12. 对抗性反审查
## 13. 评分
## 14. 问题汇总
## 15. 发布建议

## 附录 A: 已知陷阱验证总表
## 附录 B: 对比上轮审查
```

### 证据要求

所有判定必须附带：
- 证据标签: `[KNOWN]` / `[COMPUTED]` / `[INFERRED]` / `[COMMON]` / `[FRAME]` / `[GUESS]`
- 置信度: `HIGH` / `MED` / `LOW` / `VERY LOW` / `UNKNOWN`
- `[FRAME]` 和 `[GUESS]` 置信度上限为 `LOW`
- 不知道时，第一行必须写：`我不知道。`

### 输出末尾

```
[RULES I BROKE]: <如有违反规则，列出；如无则写 "NONE">
```

---

## 执行说明

本 Prompt 设计为可由 AI agent 或其他审查者按顺序执行。预期执行时间：

| 阶段 | 预计时间 |
| ---- | -------- |
| Part 0-1 (Spec Hub) | ~30 min |
| Part 2 (Traceability) | ~45 min |
| Part 3-5 (Design/Plan/Prompt) | ~40 min |
| Part 6 (Code Quality + 缺口抽样) | ~90 min |
| Part 7-8 (Release/Docs + 状态分裂专项) | ~60 min |
| Part 9-10 (Evidence/Governance) | ~45 min |
| Part 11 (运行时缺口矩阵) | ~60 min |
| Part 12 (对抗性反审查) | ~45 min |
| Part 13-15 (Scoring/Issues/Verdict) | ~45 min |
| **总计** | **~7 hours** |

如果 Runtime 仓不可访问，Part 6/7.4/11.2/11.3 和部分 Part 3.4 标记为 `[FRAME, LOW] Runtime not accessible`。

---

## 审查原则

1. **消除信息差**：验证前确认基线，禁止凭记忆假设
2. **发现问题即标注**：发现系统性问题直接标注，不先分类再等指令
3. **跨表走查**：不限于单表，遍历 TRACEABILITY.md §1-§5
4. **证据驱动**：每个判定绑定具体文件/行号/命令输出
5. **反奉承**：宁可保守（标注 UNKNOWN）也不美化；100% Done / 满分项需额外质疑
6. **双口径分离**：规格口径与运行时口径独立评分，发布判定取低值
7. **已知陷阱优先**：T0-1 ~ T10-1 共**十一个**已知陷阱验证点须逐一确认，这些是基于 v2.0 生成时深度分析 + 20 轮自审验证发现的真实问题

---

## 附录：审查者快速检查清单

执行审查前，审查者可先用以下命令快速扫描已知问题是否存在：

```bash
# T0-1 / T8-1: Runtime-Version 分裂
echo "=== T0-1/T8-1: Runtime-Version 一致性 ==="
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/README.md
grep -m1 'Runtime-Version' /home/workspace/ZoneCNH/module/binance/deploy/DEPLOY.md
git -C /home/workspace/binance describe --tags --always

# T7-1: PRG-006 矛盾
echo "=== T7-1: PRG-006 ==="
grep -i "PRG-006" /home/workspace/ZoneCNH/module/binance/todo.md
grep -i "PRG-001~007" /home/workspace/ZoneCNH/module/binance/spec/SPEC.md | head -1

# T1-1: CHANGELOG 版本超前
echo "=== T1-1: 版本追溯 ==="
grep -m1 'Module-Version' /home/workspace/ZoneCNH/module/binance/CHANGELOG.md
grep -m1 'Spec-Version' /home/workspace/ZoneCNH/module/binance/spec/SPEC.md

# T4-1: Task 计数矛盾
echo "=== T4-1: Task 计数 ==="
echo "实际: $(find /home/workspace/ZoneCNH/module/binance/tasks/ -name 'TASK-*.md' | wc -l)"
grep -oE '[0-9]+/[0-9]+ tasks' /home/workspace/ZoneCNH/module/binance/README.md | head -1

# T7-2: tag 缺失（shallow clone）
echo "=== T7-2: tag + shallow clone ==="
git -C /home/workspace/binance rev-parse --is-shallow-repository
git -C /home/workspace/binance tag -l 'v*'

# T9-1: 测试报告免责声明
echo "=== T9-1: 测试报告免责 ==="
head -5 /home/workspace/ZoneCNH/report/binance/TEST-ANALYSIS-20260630.md

# 运行时缺口总览（唯一 GAP-ID 计数）
echo "=== 运行时缺口（唯一 ID）==="
grep -oE 'GAP-E[0-9]+' /home/workspace/ZoneCNH/module/binance/RUNTIME-GAP-MATRIX.md 2>/dev/null | sort -u | wc -l || echo "RUNTIME-GAP-MATRIX.md not found"
```

若以上任一检查显示不一致，审查报告中须作为 CRITICAL 或 HIGH 优先记录。
