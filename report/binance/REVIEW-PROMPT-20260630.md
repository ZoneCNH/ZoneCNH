# module/binance 完整审查 Prompt

> **版本**: v1.0.0
> **生成日期**: 2026-06-30
> **目标模块**: `module/binance/`（spec hub）+ `/home/binance/`（runtime 仓）
> **审查基线**: CONSTITUTION.md §0-§20、FoundationX Pipeline (Goal→Spec→Plan→Matrix→Tasks→Prompt→Code→Evidence)
> **适用场景**: AI agent 深度审查、CI 巡检、发布前门禁、治理审计
> **输出**: 结构化审查报告 + 评分卡 + 问题清单

---

## 审查目标

对 `module/binance` 模块执行端到端深度审查，覆盖 11 个治理维度 + 管线 8 阶段，产出：
1. **评分矩阵**（11 维度 × 满分 100，含加权综合分）
2. **红线清单**（违反硬约束的 CRITICAL 问题）
3. **修复优先级排序**（P0 阻塞发布 / P1 影响治理 / P2 优化建议）
4. **发布就绪判定**（release_closeable: YES/NO + 置信度 + 证据链）
5. **对比上轮审查**（如存在历史报告，标注变化趋势）

---

## Part 0: 审查前准备

### 0.1 基线确认

执行以下命令确认当前基线，输出写入报告 §0（基线确认）：

```bash
# Spec hub 基线
echo "=== Spec Hub ==="
git log --oneline -5 -- module/binance/
echo ""
echo "=== Runtime 仓 ==="
cd /home/binance && git log --oneline -5 && git describe --tags --always
echo ""
echo "=== 当前分支 ==="
git branch --show-current
echo ""
echo "=== 未提交变更 ==="
git status --short -- module/binance/
```

### 0.2 文件清单扫描

确认模块文件完整：

```bash
find module/binance/ -type f | sort | wc -l
find module/binance/ -type f -name "*.md" | sort | wc -l
```

### 0.3 历史审查报告加载

如果 `report/binance/` 下存在历史审查报告，必须阅读并标注：
- 上次审查的 CRITICAL 问题是否已修复
- 上次评分是否上升/下降
- 新发现的增量问题

---

## Part 1: Spec Hub 审查（文档治理）

### 1.1 SPEC.md 23 节结构完整性

**入口文件**: `module/binance/spec/SPEC.md`

逐节核验下列 23 节是否存在、内容是否非空：

| 节号 | 节名 | 检查要点 |
|------|------|---------|
| §1 | Goal | 模块目标是否明确、可测量 |
| §2 | Authority | 权威来源声明是否完整（CONSTITUTION/SPEC/Matrix/Evidence） |
| §3 | Scope | 边界是否清楚（包含什么、不包含什么） |
| §4 | Runtime Boundary | Client/Server/Wire/Config 四子系统职责与禁止项 |
| §5 | State Model | 状态模型定义是否单一且无歧义 |
| §6 | Product Lines and Event Types | 产品线 × event_type 矩阵是否完整 |
| §7 | Functional Requirements | FR 表：ID / Scope / Requirement / State / Closure evidence |
| §8 | Business Rules | BR 表：ID / Rule / Verification |
| §9 | Non-Functional Requirements | NFR 表含性能/SLA/安全/合规 |
| §10 | Data Model | DTO/Wire/Envelope 定义是否完整 |
| §11 | API Specification | REST/gRPC/NATS subject 定义 |
| §12 | Configuration | 配置项/环境变量/schema |
| §13 | Error Model | 错误码/错误分类/恢复策略 |
| §14 | Observability | metrics/logs/traces 三件套定义 |
| §15 | Security | 认证/授权/加密/凭证管理 |
| §16 | Deployment | 部署拓扑/HA/DR/资源需求 |
| §17 | Testing Strategy | 测试分层/覆盖率目标/关键测试场景 |
| §18 | Migration | 架构迁移路径/向后兼容策略 |
| §19 | Dependencies | 外部依赖清单/版本约束 |
| §20 | Appendix A-E | 附录内容完整性 |
| §21 | Changelog | 版本变更记录 |
| §22 | Release DoD | Definition of Done 清单 |
| §23 | References | 交叉引用文档列表 |

**产出**：
- 23 节完整性表（✅/⚠️/❌）
- 每节的详细问题描述（如有）

### 1.2 子模块 SPEC 检查

检查 `module/binance/spec/client/SPEC.md` 和 `module/binance/spec/server/SPEC.md`：
- 版本号是否与 root SPEC 一致
- FR 编号是否与 root SPEC 对齐
- 是否有独立声明的状态与 root SPEC 矛盾

```bash
# 版本一致性检查
echo "Root SPEC version:"
grep -oP 'Spec-Version:\s*v[\d.]+' module/binance/spec/SPEC.md
echo "Client SPEC version:"
grep -oP 'Spec-Version:\s*v[\d.]+' module/binance/spec/client/SPEC.md
echo "Server SPEC version:"
grep -oP 'Spec-Version:\s*v[\d.]+' module/binance/spec/server/SPEC.md
```

### 1.3 FEATURES.md / ACCEPTANCE.md 对齐

- FEATURES.md 的 FR 状态是否与 SPEC.md §7 一致
- ACCEPTANCE.md 的 PRG 状态是否与 matrix/TRACEABILITY.md §4 一致
- ACCEPTANCE.md §4 闭合矩阵的 Evidence 列是否全部填写
- 是否存在"单一状态模型"以外的状态声明

### 1.4 NAMING.md 合规

检查 `module/binance/spec/NAMING.md`：
- product_line 命名是否统一使用 `spot` / `um_perp` / `cm_perp` / `options`
- 是否残留旧命名 (`usdm_futures` / `coinm_futures` / `futures_usdt` / `futures_coin`)

```bash
grep -rnE "(usdm_futures|coinm_futures|futures_usdt|futures_coin)" \
  module/binance/ --include="*.md" | grep -vE "NAMING\.md|ARCHITECTURE-DRIFT|archive/"
```

### 1.5 SPEC.md 行数门禁

```bash
wc -l module/binance/spec/SPEC.md
wc -l module/binance/matrix/TRACEABILITY.md
```

- AC-005: root SPEC 必须 < 1000 行
- AC-006: root TRACEABILITY 必须 < 200 行

---

## Part 2: 追溯矩阵审查

### 2.1 TRACEABILITY.md §1-§7 完整性

**入口文件**: `module/binance/matrix/TRACEABILITY.md`

核验以下 7 节全部存在且内容非空：

| 节号 | 内容 | 检查要点 |
|------|------|---------|
| §1 | Rule | 矩阵规则声明 |
| §2 | FR Matrix | FR → BR → AC → TC/Evidence → State 映射 |
| §3 | Acceptance Criteria | AC 编号 + Requirement + State |
| §4 | Production Readiness Gates | PRG-001~007 定义与状态 |
| §5 | TC→FR Reverse Trace | 测试用例 → FR 反向追溯 |
| §6 | Coverage Dashboard | FR/BR/NFR/AC/TC 总数/Done/覆盖率（自动统计） |
| §7 | Change History | 变更记录 |

### 2.2 追溯链闭合验证（R1 跨表走查）

对每个 FR，验证存在从 FR → BR → AC → TC → Task → Evidence 的完整路径：

```bash
# 检查每个 FR 在 TRACEABILITY 中有 AC 和 TC 映射
for fr in $(seq -w 1 44); do
  id="FR-0${fr}"
  in_matrix=$(grep -c "$id" module/binance/matrix/TRACEABILITY.md)
  if [ "$in_matrix" -eq 0 ]; then
    echo "MISSING: $id not found in TRACEABILITY.md"
  fi
done

# 交叉验证 SPEC.md vs TRACEABILITY.md FR 状态
diff \
  <(grep -P '^\| FR-\d+' module/binance/spec/SPEC.md | head -44 | awk -F'|' '{print $2, $5}' | sort) \
  <(grep -P '^\| FR-\d+' module/binance/matrix/TRACEABILITY.md | head -44 | awk -F'|' '{print $2, $6}' | sort)
```

### 2.3 子模块 TRACEABILITY 对齐

- `matrix/client/TRACEABILITY.md` 和 `matrix/server/TRACEABILITY.md` 是否存在
- 子模块的 FR 状态是否与 root TRACEABILITY 一致
- 子模块的 Module-Version 是否正确

### 2.4 §6 仪表盘自动统计验证

仪表盘的"实现状态"行必须从 §2 FR 表的 `State` 列派生，不得手写：

```bash
python3 -c "
import re
with open('module/binance/matrix/TRACEABILITY.md') as f:
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

---

## Part 3: 架构与设计审查

### 3.1 DESIGN.md 质量

**入口文件**: `module/binance/design/DESIGN.md`

- 是否仍为 Draft 状态？如果是，缺少哪些章节？
- 数据流图是否与 SPEC.md 和 README.md 一致
- 组件数量/名称是否与 ARCHITECTURE.md 状态表一致

### 3.2 ADR 审查

检查 `module/binance/design/ADR-*.md`：
- ADR-002 (wire boundary): wire 层的 contract 是否严格执行
- ADR-003 (order book rebuild exclusion): 决策是否在 runtime 中生效
- ADR-004 (FR-024 vs FR-036 architecture): 设计决策是否有代码锚点

### 3.3 ARCHITECTURE-DRIFT-WATCHLIST 漂移扫描

按 `module/binance/design/ARCHITECTURE-DRIFT-WATCHLIST.md` 的 11 个监控点 (D1-D11) 逐项执行检测命令，输出 PASS/FAIL。

### 3.4 Runtime 架构审查（如果 /home/binance 可访问）

```bash
cd /home/binance
# 目录结构
find internal/ -type d | sort
# Client/Server 边界违规检查
grep -r "internal/server" internal/client/ --include="*.go" && echo "BOUNDARY VIOLATION: client imports server" || echo "OK"
grep -r "internal/client" internal/server/ --include="*.go" && echo "BOUNDARY VIOLATION: server imports client" || echo "OK"
# 死代码检查
grep -r "TODO\|FIXME\|HACK" internal/ --include="*.go" || echo "OK (no TODO/FIXME)"
```

---

## Part 4: 实现计划与任务审查

### 4.1 PLAN.md 质量

**入口文件**: `module/binance/plan/PLAN.md`

- 是否包含 §1-§8 完整结构
- §8 停止条件是否与 SPEC.md release_closeable 一致
- 执行进度百分比是否与 tasks/ 实际完成数一致

### 4.2 Task 覆盖检查

- `tasks/` 下总计多少个 TASK 文件（预期 ~43 个：4 root + 14 client + 25 server）
- 每个 FR 是否有 >=1 个 Task 覆盖
- 每个 Task 文件是否包含：Objective / Scope / Covers / Deliverables / Acceptance Criteria / Dependencies

```bash
# Task 文件计数
echo "=== Task 文件总数 ==="
find module/binance/tasks/ -name "TASK-*.md" | wc -l
echo "=== 按目录分组 ==="
find module/binance/tasks/ -name "TASK-*.md" | sed 's|/[^/]*$||' | sort | uniq -c
```

### 4.3 Plan-Task 一致性

- PLAN.md 中的 Task 列表是否与 tasks/ 目录下实际文件一致
- Task 文件的 AC 是否与 SPEC.md 的 AC 编号对应

---

## Part 5: Prompt / Context Package 审查

### 5.1 Prompt 目录检查

**入口文件**: `module/binance/prompt/README.md`

- prompt/ 是否仅含 README.md（空壳）？
- 如果为空壳，标注为管线已越过 S5 阶段（Prompt 不是阻塞项）
- 参考其他模块（observex/10 个 PROMPT 文件、ossx/7 个 PROMPT 文件），断言 binance 是否需要补齐

---

## Part 6: 代码质量审查（Runtime）

> 如果 `/home/binance/` 不可访问，跳过 Part 6，在报告中标注 `[FRAME, LOW] Runtime not accessible`。

### 6.1 构建与编译

```bash
cd /home/binance
go build ./...
go vet ./...
```

### 6.2 测试执行

```bash
cd /home/binance
go test ./... -count=1 -timeout=120s
go test ./... -race -count=1 -timeout=180s
```

### 6.3 测试覆盖率

```bash
cd /home/binance
go test ./... -coverprofile=coverage.out -count=1 -timeout=120s
go tool cover -func=coverage.out | tail -1
go tool cover -func=coverage.out | grep -E "(assembly\.go|adapter\.go|total)"
```

**门禁**: total coverage ≥ 80%（CONSTITUTION.md 要求）

### 6.4 安全扫描

```bash
cd /home/binance
gitleaks detect --no-git 2>&1
govulncheck ./... 2>&1
```

### 6.5 边界门禁

```bash
cd /home/binance
bash -n scripts/boundary-gates.sh && ./scripts/boundary-gates.sh
```

### 6.6 代码规范

- 是否存在 `panic()` 调用（非 init/test 场景）
- 是否存在未处理的 error 返回值
- 是否存在 > 800 行的单文件
- `golangci-lint run` 是否通过

---

## Part 7: 发布就绪审查

### 7.1 PRG 门禁核验

按 `matrix/TRACEABILITY.md §4`（权威来源），逐项核验 PRG-001~007：

| Gate | 检查内容 | 验证命令 |
|------|---------|---------|
| PRG-001 | CI runner 为 ubuntu-latest（非 self-hosted） | 检查 CI workflow 文件 |
| PRG-002 | Release tag + GitHub Release 存在 | `cd /home/binance && git tag -l 'v*'` `gh release view v0.8.0` |
| PRG-003 | PRG 7/7 全 PASS | 逐项确认 PRG-001~007 |
| PRG-004 | Observability 全在线 | 确认 Jaeger/Grafana/Loki/AlertManager 可访问 |
| PRG-005 | Security 扫描清洁 | gitleaks + govulncheck PASS |
| PRG-006 | soak/chaos/canary 测试 PASS | 检查 evidence/ 目录下的 soak/chaos 证据 |
| PRG-007 | GitHub + Beads issue 全关闭 | 检查 #1289-#1331 是否全部 closed |

### 7.2 多源交叉验证 release_closeable

在以下至少 5 处检查 `release_closeable` 状态：

| 位置 | 预期状态 |
|------|---------|
| `spec/SPEC.md` header | release_closeable: YES |
| `matrix/TRACEABILITY.md` header | release_closeable: YES |
| `README.md` Delivery-State | release_closeable=YES |
| `ACCEPTANCE.md` Module-State | release_closeable=YES |
| `todo.md` | release_closeable=YES |
| `goal/goal.md` 状态 | L3 Production / Released |

如果任意两处不一致 → CRITICAL（状态分裂）

### 7.3 治理等级判定

| 等级 | 条件 |
|------|------|
| L1 Prototype | goal + SPEC 骨架 + 边界声明 + 命名 |
| L2 Active | L1 + matrix + boundary gates + plan/tasks + runtime 编译与本地测试 |
| L3 Production | L2 + PRG 全 PASS + live_integration ≥ 15 + 外部 E2E/soak/release/rollback 证据 |

---

## Part 8: 文档一致性审查

### 8.1 核心文档版本一致性

| 文档 | Spec-Version / Module-Version | last-updated |
|------|------------------------------|-------------|
| `spec/SPEC.md` | | |
| `spec/ACCEPTANCE.md` | | |
| `spec/FEATURES.md` | | |
| `matrix/TRACEABILITY.md` | | |
| `spec/client/SPEC.md` | | |
| `spec/server/SPEC.md` | | |
| `matrix/client/TRACEABILITY.md` | | |
| `matrix/server/TRACEABILITY.md` | | |
| `README.md` | | |
| `goal/goal.md` | | |
| `gate/BOUNDARY-GATES.md` | | |
| `design/DESIGN.md` | | |

### 8.2 跨文档 FR 总数一致性

检查 SPEC.md / TRACEABILITY.md / FEATURES.md / ACCEPTANCE.md 中声明的 FR 总数是否一致（预期 48）。

### 8.3 链接有效性

```bash
grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' module/binance/ --include="*.md" -r \
  | sort -u | while read u; do
    repo=${u#ZoneCNH/}
    gh api "repos/ZoneCNH/$repo" >/dev/null 2>&1 || echo "404: $repo"
  done
```

### 8.4 文档同步检查表

交叉验证 README.md / ARCHITECTURE.md / STATUS.md 中 binance 模块的：
- 组件数量
- 版本号
- 状态描述
- 所属域

---

## Part 9: 证据体系审查

### 9.1 Evidence 目录结构

```bash
find module/binance/evidence/ -type f | sort
```

按日期目录检查：
- `2026-06-26/`: release / retrospective / review / test
- `2026-06-27/`: review / test (3 workers)
- `2026-06-28/`: review / release / p10-alignment
- `2026-06-30/`: release (PRG-001~007) / verification

### 9.2 每条 PRG 的 Evidence 闭环

| PRG | Evidence 文件 | 证据充分性 |
|-----|--------------|-----------|
| PRG-001 | `evidence/2026-06-30/release/prg-001-ci-runner.md` | |
| PRG-002 | `evidence/2026-06-30/release/prg-002-release-tag.md` | |
| PRG-003 | `evidence/2026-06-30/release/prg-003-production-readiness.md` | |
| PRG-004 | `evidence/2026-06-30/release/prg-004-observability.md` | |
| PRG-005 | `evidence/2026-06-30/release/prg-005-security.md` | |
| PRG-006 | `evidence/2026-06-30/release/prg-006-resilience.md` | |
| PRG-007 | `evidence/2026-06-30/release/prg-007-issue-sync.md` | |

---

## Part 10: 治理合规审查

### 10.1 CONSTITUTION.md 对齐

按 CONSTITUTION.md §0-§20 逐条核验：
- §0 分支纪律：当前 branch 是否从 main HEAD 创建
- §4 规格标准：23 节结构完整
- §10 变更管理：版本号递增合规
- §14 质量门禁：覆盖率 ≥ 80% / race/vet/lint/secret scan
- §20 认识论标准：证据标签 [KNOWN]/[COMPUTED]/[INFERRED] 是否正确使用

### 10.2 管线阶段门禁

按 FoundationX Pipeline（Goal→Spec→Plan→Matrix→Tasks→Prompt→Code→Evidence）逐阶段评分：

| 阶段 | 产物 | 状态 | 得分 |
|------|------|------|------|
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

---

## Part 11: 评分

### 11.1 多维度评分矩阵

对下列 11 个维度按 0-100 评分，输出得分 + 等级 + 扣分原因：

| 维度 | 满分 | 扣分项 | 得分 |
|------|------|--------|------|
| A. Spec 结构完整性 | 100 | | |
| B. 追溯矩阵闭合 | 100 | | |
| C. Design 架构质量 | 100 | | |
| D. Runtime 代码质量 | 100 | | |
| E. Client/Server 边界 | 100 | | |
| F. 测试与验证 | 100 | | |
| G. CI/CD 管线 | 100 | | |
| H. 安全与合规 | 100 | | |
| I. 可观测性 | 100 | | |
| J. 生产就绪 (L3) | 100 | | |
| K. 文档一致性 | 100 | | |
| **加权综合** | 100 | | |

### 11.2 评分纪律

- **R0 措辞强度分级**：只对【硬】约束（必须/不得/禁止/触发）扣分
- **R1 跨表走查**：遍历 §1-§5 全部验证列
- **R2 辅助元数据排除**：覆盖率仪表盘/变更历史不参与评分
- **R3 形式降级抑制**：所有可验证机制形式视为有效，仅空白/缺失扣分

---

## Part 12: 问题汇总

### 12.1 按严重度分类

| 严重度 | 数量 | 描述 |
|--------|------|------|
| 🔴 CRITICAL | | 阻碍发布或安全漏洞 |
| 🟠 HIGH | | 影响治理可信度 |
| 🟡 MEDIUM | | 建议修复 |
| 🟢 LOW | | 优化建议 |

### 12.2 CRITICAL 问题详情

对每个 CRITICAL 问题，记录：
- 位置（文件 + 行号）
- 严重性评估
- 影响范围
- 修复建议
- 预估工时

### 12.3 对比上轮审查

| 指标 | 上轮 | 本轮 | Δ |
|------|------|------|---|
| 综合得分 | | | |
| CRITICAL 数量 | | | |
| PRG 通过数 | | | |
| release_closeable | | | |
| 治理等级 | | | |

---

## Part 13: 发布建议

### 13.1 Go/No-Go 判定

- **Go**: 综合 ≥ 85 分 + 0 CRITICAL + 全部 PRG PASS
- **Conditional Go**: 综合 ≥ 75 分 + 0 CRITICAL + ≥5/7 PRG PASS
- **No-Go**: 综合 < 75 分 或 存在 CRITICAL 或 <5/7 PRG PASS

### 13.2 阻塞清单

| 阻塞项 | 严重度 | 预计修复时间 | 阻塞什么 |
|--------|--------|-------------|---------|

### 13.3 修复路线图

建议按 Phase 组织修复：
- Phase 1: 文档一致性（状态分裂修复）
- Phase 2: 追溯矩阵闭合
- Phase 3: PRG 门禁闭合
- Phase 4: 覆盖率补齐
- Phase 5: 生产证据补全

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
## 11. 评分
## 12. 问题汇总
## 13. 发布建议
## 附录: 对比上轮审查
```

### 证据要求

所有判定必须附带：
- 证据标签: `[KNOWN]` / `[COMPUTED]` / `[INFERRED]` / `[COMMON]` / `[FRAME]` / `[GUESS]`
- 置信度: `HIGH` / `MED` / `LOW` / `VERY LOW` / `UNKNOWN`
- `[FRAME]` 和 `[GUESS]` 置信度上限为 `LOW`

### 输出末尾

```
[RULES I BROKE]: <如有违反规则，列出；如无则写 "NONE">
```

---

## 执行说明

本 Prompt 设计为可由 AI agent 或其他审查者按顺序执行。预期执行时间：

| 阶段 | 预计时间 |
|------|---------|
| Part 0-1 (Spec Hub) | ~30 min |
| Part 2 (Traceability) | ~45 min |
| Part 3-5 (Design/Plan/Prompt) | ~30 min |
| Part 6 (Code Quality) | ~60 min |
| Part 7-8 (Release/Docs) | ~45 min |
| Part 9-13 (Evidence/Governance/Scoring) | ~60 min |
| **总计** | **~4.5 hours** |

如果 Runtime 仓不可访问，Part 6 和部分 Part 7 标记为 `[FRAME, LOW] Runtime not accessible`。

---

**审查原则**：
1. 消除信息差：验证前确认基线，禁止凭记忆假设
2. 发现问题即修复：发现系统性问题直接标注，不先分类再等指令
3. 跨表走查：不限于单表，遍历 TRACEABILITY.md §1-§5
4. 证据驱动：每个判定绑定具体文件/行号/命令输出
5. 反奉承：宁可保守（标注 UNKNOWN）也不美化

Co-Authored-By: Claude <noreply@anthropic.com>
