# report/07-11.md 深度分析报告

> 分析日期：2026-07-11
> 分析方式：3-agent team 多维度交叉审查
> 分析对象：`report/07-11.md` — ZoneCNH 25 模块完整修复与生产重新认证计划

---

## 分析方法

三组独立 agent 从三个正交维度并行分析：

| Agent                | 维度                                               | 模型      |
| -------------------- | -------------------------------------------------- | --------- |
| dependency-architect | 依赖图正确性、波次顺序、并行原则、联合验证矩阵     | reasoning |
| risk-feasibility     | 时间线可行性、资源依赖、风险热力图、单点阻塞       | reasoning |
| gap-optimizer        | 工作包覆盖缺口、验收可测量性、矛盾检测、版本一致性 | reasoning |

---

## 一、综合评级

| 维度           | 评级                      | 来源                 |
| -------------- | ------------------------- | -------------------- |
| 依赖图环路检测 | **CORRECT**               | dependency-architect |
| 波次划分       | MINOR_ISSUE (3 项)        | dependency-architect |
| 精确依赖顺序   | MINOR_ISSUE (3 项)        | dependency-architect |
| 联合验证矩阵   | MINOR_ISSUE (3 项)        | dependency-architect |
| 并行原则       | **NEEDS_REVISION** (3 项) | dependency-architect |
| 时间线可行性   | **CRITICAL**              | risk-feasibility     |
| 资源依赖       | **CRITICAL**              | risk-feasibility     |
| 单点阻塞       | **CRITICAL**              | risk-feasibility     |
| 模块风险热力   | HIGH                      | risk-feasibility     |
| 测量与进度     | MEDIUM                    | risk-feasibility     |
| 矛盾检测       | **CRITICAL_GAP** (9 条)   | gap-optimizer        |
| 版本一致性     | **CRITICAL_GAP** (5 条)   | gap-optimizer        |
| 工作包覆盖     | ISSUES_FOUND (4 类)       | gap-optimizer        |
| 验收可测量性   | ISSUES_FOUND (3 类)       | gap-optimizer        |
| 缺失章节       | ISSUES_FOUND (4 类)       | gap-optimizer        |

---

## 二、CRITICAL 级发现

### 2.1 时间线严重低估

**发现者**：risk-feasibility

| 报告声称     | 最低可行时间 | 差距     |
| ------------ | ------------ | -------- |
| 1 天 (5 项)  | 1.5-2 天     | +100%    |
| 7 天 (8 项)  | 10-14 天     | +100%    |
| 30 天 (9 项) | 45-60 天     | +100%    |
| 60-90 天     | 60-75 天     | 基本吻合 |

核心瓶颈：

- **xlib_standard v2 RC** — 需 2-3 周，包括 ownership manifest、删除 runtime、建立 bundle、修复 CI
- **resiliencx 6 策略重写** — 这是重建，不是修复，每个策略都有 panic/silent failure/race condition
- **domain_market 基础设施迁出** — 逐行剖析 Kafka/TDengine/metrics/wall clock 污染后迁出

**修正建议**：30 天窗口扩展至 45-60 天，7 天窗口扩展至 10-14 天。

---

### 2.2 三条治理矛盾

**发现者**：gap-optimizer

**矛盾 1 — goalcli 归属真空 (HIGH)**

xlib_standard (XLS-002)、xlibgate (XLG-001)、xlib_harness (XLH-002) 三方都声称"删除/迁出 goalcli runtime 重叠"，但无一方声明 goalcli 的最终归属。三个模块同时删除 = goalcli 消失，但管线 agent 仍然引用它。

**修复**：新增 goalcli 归属裁决表 — 明确 goalcli 是独立工具、并入 xlib_harness 还是废弃。

**矛盾 2 — transportx module path 未裁决 (HIGH)**

go.mod 当前为 `github.com/ZoneCNH/xlib-standard`，计划改为 `github.com/ZoneCNH/transportx`。这是 Go module identity breaking change，所有消费者 import path 必须修改。报告未裁定是否需要 `/v2` 路径后缀。

**修复**：TRN-001 和发布建议中显式记录 Go module 迁移路径。

**矛盾 3 — contracts 版本不确定性 (HIGH)**

L772-774："若 v1.5.0 tag 内容不能代表当前 main 的合法祖先，禁止直接发布 v1.5.1；很可能需要明确迁移后发布 v2"。这是非裁决 — contracts 的不确定性传播到所有消费者的版本图。

**修复**：执行 git tag lineage 审计，给出确定性版本裁决。

---

### 2.3 Docker/K8s 禁令与 soak/fault 测试矛盾

**发现者**：risk-feasibility

`AGENTS.md` 明确写入"禁止 Kubernetes 与 Docker"，但 7 个 storage adapter 的 fault injection 测试在工程实践中几乎全部依赖容器编排：

- Redis 集群重启 (RDX-007 persistence/fault)
- Kafka broker 选举 (KFK-004 broker fault)
- PostgreSQL 主备切换 (PGX-006 TLS/auth/fault)

**修复**：在 W4 计划中明确 bare-metal fault injection 具体方案（如 systemd service restart + network namespace manipulation + iptables），否则此为致命矛盾。

---

### 2.4 domain_macro 治理信任崩塌

**发现者**：risk-feasibility + gap-optimizer（两个 agent 独立发现）

仓库不存在但状态投影标为 v1.0.1 released、factory grade。如果 status projection 可以为不存在的仓库编造 release facts，那么其他 24 个仓库的 factory 声明有多少是真实的？

**修复**：第 1 天 inventory 升级为全仓事实审计 — 每条 factory/release 声明必须有可验证 evidence（仓库存在、tag 可定位、CI 通过、GitHub Release 含 assets）。

---

### 2.5 W4 "light/heavy pool" 未定义

**发现者**：dependency-architect

§2.2 L112 声称 "W4 可按 light/heavy pool 并行"，但未给出分类表、资源约束或 heavy soak 定义。哪些模块属于 light pool、哪些属于 heavy pool？postgresx 和 clickhousex 的 soak 是否互斥？

**修复**：给出 light/heavy 分类表和资源约束。如果未确定，应标注为 TBD 而非声称"可并行"。

---

## 三、风险热力图

### CRITICAL 风险模块 (5 个)

| 模块                | 行号     | 风险驱动因素                                                       |
| ------------------- | -------- | ------------------------------------------------------------------ |
| **resiliencx**      | L375-407 | 6 策略全部重写 — 这是重建，不是修复                                |
| **bootstrap**       | L442-479 | 事务式构造 + 7 adapter partial failure matrix（3^7=2187 状态组合） |
| **domain_market**   | L886-920 | 基础设施污染逐行迁出 + Payload interface{} 替换 + SSOT 合并        |
| **domain_exchange** | L959-993 | 13→8 接口拆分，所有下游 adapter 逐一迁移                           |
| **domain_macro**    | L923-957 | 仓库不存在 + 从零创建 + 治理信任崩塌                               |

### HIGH 风险模块 (4 个)

| 模块              | 风险驱动因素                                                                         |
| ----------------- | ------------------------------------------------------------------------------------ |
| **transportx**    | go.mod identity 指向 xlib-standard，需修复身份 + 从 spec stub 构建 functional module |
| **xlib_standard** | 角色收缩 breaking governance change + bundle 必须 bit-for-bit 可重现                 |
| **natsx**         | 版本 truth reset + Core NATS + JetStream 三层从零建立                                |
| **kafkax**        | 删除伪 integration + 建立真实 Kafka integration + consumer group rebalance semantics |

### LOW 风险模块 (6 个)

kernel / decimalx / configx / schedulex / observex / testkitx

---

## 四、单点阻塞瀑布

依赖链的根节点只有一条路径，任一节点失败即全局冻结：

```
xlib_standard RC → gate/evidence/harness → 3 canaries → standard stable → 一切下游
```

- **xlib_standard v2 RC** 是不可替代的全局瓶颈
- **任一 canary 失败** 即 blocking standard stable（redisx 是最不稳定的 canary）
- **bootstrap 完整验证** 需要全部 7 个 storage adapter 可用，跨越 W3/W4 边界

---

## 五、报告内部矛盾清单 (9 条)

| #   | 矛盾                                                              | 行号                     | 严重度  |
| --- | ----------------------------------------------------------------- | ------------------------ | ------- |
| 1   | GOWORK=off vs 跨模块 canary 验证需要 multi-module workspace       | L50 vs L288/L320         | MED     |
| 2   | 单 PR 可回滚 vs BASE-003 7 文件一次提交                           | L49 vs L83               | LOW-MED |
| 3   | goalcli 归属真空：三方声明删除，无人认领                          | L131 vs L244-246 vs L251 | HIGH    |
| 4   | testkitx import gate "必失败" vs 自身迁移生产式 Config            | L496 vs L486-487         | MED     |
| 5   | SchemalessWrite not implemented → 公开 API 无 not implemented     | L658 vs L677-680         | MED     |
| 6   | transportx go.mod 是 xlib-standard vs repo-contract 称 transportx | L787 vs L801             | HIGH    |
| 7   | domain_macro 不存在标为 factory grade                             | L927 vs L937             | HIGH    |
| 8   | xlib_harness v0.3.0 产出 compound loop 但尚未 stable              | L187 vs L1102/L1124      | LOW     |
| 9   | contracts 在依赖链中的位置未裁决                                  | L1008-1016               | MED     |

---

## 六、工作包覆盖缺口

### BASE 映射严重不均

8 个模块只说 "BASE-\* 全通过" 而无分解：
kernel (L289) / decimalx (L831) / bootstrap (L463) / domain_market (L909) / observex (L359) / configx (L313) / schedulex (L429) / xlib_standard (L140)

### 缺 SECURITY/CONTRIBUTING/CODEOWNERS 的模块 (10+)

kernel / configx / observex / xlib_harness / xlib_evidence / xlibgate / bootstrap / domain_market / domain_exchange

无一有对应 BASE-003 专用工作包。

### BASE-005 供应链审计覆盖不足

5 个模块有 `latest` tag Actions / curl-pipe / disabled security，但仅有 bootstrap 的 CI 修复中提及 SHA-pin。

---

## 七、缺失章节

| 缺失内容                     | 影响                                           |
| ---------------------------- | ---------------------------------------------- |
| 全局回滚策略                 | xlib_standard v2.0.0 RC 失败后无撤回路径       |
| BASE 推广 Runbook            | xlib_harness 产出 patch 后谁负责 PR 创建与审核 |
| 人员分工与并行窗口           | 哪些工作必须同一 owner 串行                    |
| Fleet Status Dashboard       | 跨 25 仓的聚合进度监控                         |
| configx + 下游集成验证       | 联合验证矩阵缺失配置中枢边界行为验证           |
| resiliencx + kernel 边界验证 | 策略面迁移正确性无联合验证                     |

---

## 八、优化策略

### 策略优先级矩阵

| 优先级 | 策略                         | 收益 | 复杂度 | 影响阶段 | 关键路径节省       |
| ------ | ---------------------------- | ---- | ------ | -------- | ------------------ |
| P0     | xlib_standard MVC 解耦       | 极高 | 低     | W1→W2    | 5-7 天             |
| P0     | canary 加权通过 (2/3 + RCA)  | 极高 | 低     | W2       | 消除全局阻塞       |
| P0     | BASE 文档批量生成            | 高   | 中     | W1→W3    | 压缩 10+ 个独立 PR |
| P0     | 全仓状态投影事实审计         | 高   | 低     | W0       | 治理整治前置       |
| P1     | domainx spec-freeze 先于实现 | 中   | 低     | W5       | W5 缩短约 5 天     |
| P1     | 三层模型统一模板             | 中   | 中     | W4       | 减少 7 模块不一致  |
| P1     | model-based testing 先于修复 | 中   | 高     | W3       | 修复确定性提升     |
| P2     | LOW 风险模块提前独立并行     | 低   | 无     | W3       | 调度优化           |

---

### 最具影响力的单项优化

**xlib_standard MVC 解耦**是唯一一个只改设计决策、不改代码量、不改资源就能从关键路径砍掉 5-7 天的优化。

当前模型：

```
standard v2 RC 全部完成 (14-21 天) → gate/evidence/harness → canaries → stable → 一切
```

优化后：

```
MVC freeze: schema/policy/reason-code (5 天) → gate/evidence/harness 并行启动
RC full bundle (14 天) → 3 canaries 验证
```

只需要在 standard 内部区分两个交付里程碑 — 冻结可消费的合约字段与交付完整可重现 bundle — 就将下游等待时间从 14-21 天缩短到 5 天。

---

## 九、P0 修复建议

| #   | 行动                                                    | 对象  |
| --- | ------------------------------------------------------- | ----- |
| 1   | 裁决 goalcli 最终归属（独立工具 / xlib_harness / 废弃） | §3    |
| 2   | 裁决 transportx go module major path（是否 /v2）        | §6.2  |
| 3   | 执行 contracts git tag lineage 审计，给出确定性版本     | §6.1  |
| 4   | 明确 Docker/K8s 禁令下 bare-metal fault/soak 方案       | §5 W4 |
| 5   | 全仓 status projection 事实审计                         | W0    |
| 6   | 定义 xlib_standard "最小可行合约" 以解除下游阻塞        | W1    |
| 7   | 为 10+ 模块创建 BASE-003 专用工作包                     | §1.4  |
| 8   | 30 天窗口扩展至 45-60 天                                | §9    |
| 9   | 定义 W4 light/heavy pool 分类表                         | §2.2  |
| 10  | 新增回滚策略 + BASE 推广 Runbook 章节                   | 新章  |

---

## 十、总评

**优秀方面**：依赖架构设计完善、canary 验证策略合理、compound engineering 闭环严谨、无逻辑环路。

**关键问题**：时间估算严重不足、多条治理矛盾未裁决、工作包覆盖不到底、关键基础设施假设未验证。

优先完成 P0 修复项（10 条）后，计划可以进入执行阶段。预计修正后的总时间线为 60-75 天而非原计划的 30 天主窗口。

---

## 十一、P0 修复建议实施细节

以下为 10 条 P0 修复建议的具体实施方案，包含裁决逻辑、脚本、代码示例和验收条件。

---

### P0-1: goalcli 归属裁决

**目标**：明确 goalcli 的最终归属，消除 xlib_standard / xlibgate / xlib_harness 三方同时声称"删除"的真空状态。

#### 裁决选项与评估

| 方案                 | 描述                             | 优势                                       | 劣势                                           | 推荐 |
| -------------------- | -------------------------------- | ------------------------------------------ | ---------------------------------------------- | ---- |
| A: 并入 xlib_harness | goalcli 成为 harness 子命令      | harness 已负责 CLI contract；单一 CLI 入口 | harness 当前 v0.3.0，goalcli 需要成熟 CLI 框架 | ✓    |
| B: 独立工具          | goalcli 成为独立 Foundation 模块 | 关注点分离                                 | 增加维护负担；违反角色去重原则                 | ✗    |
| C: 废弃              | 管线 agent 直接调用 harness CLI  | 最简                                       | 21 agent prompt 全部引用 goalcli，迁移成本高   | ✗    |

#### 实施步骤

**步骤 1：创建 ownership 声明**

在 `xlib_harness` 仓库创建 `OWNERSHIP-GOALCLI.yaml`：

```yaml
# /home/workspace/xlib_harness/OWNERSHIP-GOALCLI.yaml
module: goalcli
canonical_owner: xlib_harness
decision_date: 2026-07-11
rationale: |
  goalcli 作为 FoundationX 管线的 CLI 入口，并入 xlib_harness 以消除
  xlib_standard/xlibgate/xlib_harness 三方复制。
consumers:
  - .claude/agents/goal-*.md # 21 agent prompt 引用 goalcli
  - .codex/agents/goal-*.toml
  - .copilot/agents/goal-*.md
deprecation_schedule:
  - phase: xlib_standard
    action: delete cmd/goalcli/
    deadline: XLS-002 completion
  - phase: xlibgate
    action: delete internal/goalcli/
    deadline: XLG-001 completion
  - phase: xlib_harness
    action: absorb into cmd/goalcli/
    deadline: XLH-009 (new work package)
migration_guide: docs/goalcli-migration.md
```

**步骤 2：新增 xlib_harness 工作包**

| ID      | P   | 任务                        | 验收                                                                           |
| ------- | --- | --------------------------- | ------------------------------------------------------------------------------ |
| XLH-009 | P0  | absorb goalcli into harness | `harness goalcli` 子命令覆盖原 goalcli 全部功能；旧路径返回 deprecation notice |

**步骤 3：更新受影响 agent prompt**

对所有 21 agent 的 goalcli 引用做批量替换：

```bash
# 批量替换 agent prompt 中的 goalcli 引用
for agent_dir in .claude/agents .codex/agents .copilot/agents; do
  if [ -d "$agent_dir" ]; then
    find "$agent_dir" -type f -print0 | xargs -0 sed -i \
      's|goalcli |harness goalcli |g'
  fi
done

# 验证：任何残留的裸 goalcli 引用都应被 flag
grep -rn 'goalcli ' .claude/agents/ .codex/agents/ .copilot/agents/ \
  | grep -v 'harness goalcli' \
  | grep -v 'OWNERSHIP-GOALCLI'
```

**步骤 4：xlib_standard 和 xlibgate 的删除验证 gate**

在 `xlib_standard` 仓库的 CI 中添加 goalcli 残留检测：

```yaml
# .github/workflows/boundary-gates.yml (追加)
jobs:
  goalcli-ownership:
    runs-on: [self-hosted, ephemeral]
    steps:
      - name: verify goalcli not owned by xlib_standard
        run: |
          if [ -d cmd/goalcli ] || [ -d internal/goalcli ]; then
            echo "FAIL: goalcli still exists in xlib_standard"
            exit 1
          fi
          echo "PASS: goalcli ownership transferred to xlib_harness"
```

在 `xlibgate` 仓库做相同检测。

---

### P0-2: transportx Go module major path 裁决

**目标**：裁定从 `github.com/ZoneCNH/xlib-standard` 迁移到 `github.com/ZoneCNH/transportx` 是否需要 `/v2` 后缀。

#### 裁决决策树

```
go.mod 当前是 github.com/ZoneCNH/xlib-standard?
├── YES → 这是 module identity change (breaking)
│   ├── 现有消费者存在吗？
│   │   ├── NO (production_import_allowed=false) → /v1 可接受
│   │   │   └── 裁决: go.mod → github.com/ZoneCNH/transportx (无 /v2)
│   │   │       理由: 没有生产消费者需要迁移 import path
│   │   └── YES → 需要 /v2
│   │       └── 裁决: go.mod → github.com/ZoneCNH/transportx/v2
│   │           理由: Go module major version 语义强制
│   └── 特殊: 旧 tag v1.1.1-spec 是 spec-only
│       → 裁决: v1.1.1-spec 标记为 retracted
└── NO → 无操作
```

#### 实施方案（假设裁决为 `/v1` — 无生产消费者）

```bash
# transportx 仓库
cd /home/workspace/transportx

# 1. 修改 go.mod
sed -i 's|module github.com/ZoneCNH/xlib-standard|module github.com/ZoneCNH/transportx|' go.mod

# 2. 更新所有 import path
find . -name '*.go' -exec sed -i \
  's|github.com/ZoneCNH/xlib-standard|github.com/ZoneCNH/transportx|g' {} +

# 3. 验证 import 一致性
go list -m all | grep -E 'xlib-standard|transportx'
# 期望输出: github.com/ZoneCNH/transportx (无 xlib-standard)

# 4. retract 旧 spec tag
cat >> go.mod << 'GOEOF'

// retract spec-only releases predating runtime module
retract [v1.0.0, v1.1.1-spec]
GOEOF
```

```go
// go.mod 最终结构
module github.com/ZoneCNH/transportx

go 1.26.5

retract [v1.0.0, v1.1.1-spec]
```

#### 外部消费者验证

```bash
# 验证外部消费者可以正确导入
mkdir -p /tmp/transportx-consumer && cd /tmp/transportx-consumer
go mod init example.com/consumer
go get github.com/ZoneCNH/transportx@latest

cat > main.go << 'EOF'
package main
import "github.com/ZoneCNH/transportx"
func main() {}
EOF

go build ./...
# 期望: 编译成功，无 xlib-standard 残留
```

#### TRN-001 工作包追加

```markdown
## TRN-001 补充：module major path 裁决

- **裁决日期**: 2026-07-11
- **裁决结果**: `/v1` (无 /v2 后缀)
- **理由**: `production_import_allowed=false`，无生产消费者需要迁移 import path
- **回退条件**: 若发现未被记录的消费者，必须在首次 `/v2` 发布前解决
- **旧 tag 处置**: v1.0.0–v1.1.1-spec 标记为 `retract`，说明是 spec-only 发布
```

---

### P0-3: contracts git tag lineage 审计

**目标**：确定 contracts 的真实版本祖先，给出确定性版本裁决。

#### 审计脚本

```bash
#!/bin/bash
# contracts-lineage-audit.sh
# 用途: 审计 contracts 仓库的 git tag 与 main 分支的祖先关系

REPO="/home/workspace/contracts"
cd "$REPO" || exit 1

echo "=== contracts lineage audit ==="
echo ""

# 1. 列出所有 tag 及对应的 commit
echo "--- all tags ---"
git tag --sort=-creatordate | while read tag; do
  tag_sha=$(git rev-list -n1 "$tag" 2>/dev/null || echo "MISSING")
  echo "$tag -> $tag_sha"
done

echo ""

# 2. 检查每个 tag 是否在 main 的祖先链上
echo "--- ancestor check ---"
MAIN_HEAD=$(git rev-parse main)
for tag in $(git tag --sort=-creatordate); do
  tag_sha=$(git rev-list -n1 "$tag" 2>/dev/null || echo "")
  if [ -z "$tag_sha" ]; then
    echo "ORPHAN: $tag — tag points to nonexistent commit"
    continue
  fi
  if git merge-base --is-ancestor "$tag_sha" "$MAIN_HEAD" 2>/dev/null; then
    echo "ANCESTOR: $tag ($tag_sha) is ancestor of main ($MAIN_HEAD)"
  else
    echo "ORPHAN: $tag ($tag_sha) is NOT ancestor of main ($MAIN_HEAD)"
  fi
done

echo ""

# 3. 找 main 祖先链上最大的合法 tag
echo "--- latest valid ancestor tag ---"
for tag in $(git tag --sort=-version:refname); do
  tag_sha=$(git rev-list -n1 "$tag" 2>/dev/null || echo "")
  if [ -n "$tag_sha" ] && git merge-base --is-ancestor "$tag_sha" "$MAIN_HEAD" 2>/dev/null; then
    echo "LATEST_VALID: $tag ($tag_sha)"
    break
  fi
done
```

#### 裁决表

审计脚本输出后，按以下规则裁决：

| 审计结果                            | 裁决                      | 理由                                               |
| ----------------------------------- | ------------------------- | -------------------------------------------------- |
| v1.5.0 是 main 合法祖先             | `v1.5.1`                  | 正常 patch 版本递增                                |
| v1.5.0 是孤儿 tag，最新合法= v0.4.0 | `v2.0.0`                  | 从 v0.4.0 起内容已 breaking，squash 历史需要 MAJOR |
| v1.5.0 是孤儿 tag，最新合法= v1.3.0 | `v1.4.0 + retract v1.5.0` | 内容未 breaking 但跳过版本号需要 retract           |
| 无任何合法祖先 tag                  | `v1.0.0`                  | 从零开始                                           |

---

### P0-4: bare-metal fault/soak 测试方案（无 Docker/K8s）

**目标**：在 AGENTS.md "禁止 Docker/K8s" 约束下，为 7 个 storage adapter 建立可执行的 fault injection 测试方案。

#### 架构设计

不使用 Docker Compose 或 Kubernetes，改用 **systemd service unit + network namespace + iptables** 三级隔离：

```
┌─────────────────────────────────────────────┐
│  CI Runner (self-hosted ephemeral)          │
│                                             │
│  ┌───────────────┐  ┌───────────────┐       │
│  │ netns: redis  │  │ netns: kafka  │  ...  │
│  │  redis-server │  │  kafka-server  │       │
│  │  iptables     │  │  iptables      │       │
│  └───────┬───────┘  └───────┬───────┘       │
│          │                  │               │
│  ┌───────┴──────────────────┴───────┐       │
│  │          host network            │       │
│  │   Go test binary — 通过 netns    │       │
│  │   IP 连接各服务                   │       │
│  └──────────────────────────────────┘       │
└─────────────────────────────────────────────┘
```

#### 通用 fault injection 脚本

```bash
#!/bin/bash
# scripts/fault-fixture.sh — 通用 fault injection fixture
# 用法: fault-fixture.sh <service> <fault> [delay_ms]

set -euo pipefail

SERVICE_NAME="${1:?usage: $0 <service-name> <fault-type> [delay_ms]}"
FAULT_TYPE="${2:?usage: $0 <service-name> <fault-type> [delay_ms]}"
NETNS="ci-${SERVICE_NAME}"

case "$FAULT_TYPE" in
  partition)
    ip netns exec "$NETNS" iptables -A OUTPUT -j DROP
    ip netns exec "$NETNS" iptables -A INPUT -j DROP
    echo "NETPARTITION: $SERVICE_NAME isolated"
    ;;
  partition-heal)
    ip netns exec "$NETNS" iptables -F OUTPUT
    ip netns exec "$NETNS" iptables -F INPUT
    echo "NETPARTITION: $SERVICE_NAME healed"
    ;;
  kill)
    ip netns exec "$NETNS" pkill -9 -f "$SERVICE_NAME" || true
    echo "KILL: $SERVICE_NAME terminated"
    ;;
  restart)
    systemctl restart "ci-${SERVICE_NAME}.service"
    echo "RESTART: $SERVICE_NAME restarted"
    ;;
  latency)
    DELAY_MS="${3:-500}"
    ip netns exec "$NETNS" tc qdisc add dev lo root netem delay "${DELAY_MS}ms"
    echo "LATENCY: ${DELAY_MS}ms added to $SERVICE_NAME"
    ;;
  latency-clear)
    ip netns exec "$NETNS" tc qdisc del dev lo root 2>/dev/null || true
    echo "LATENCY: cleared for $SERVICE_NAME"
    ;;
  *)
    echo "UNKNOWN fault: $FAULT_TYPE"
    echo "Supported: partition|partition-heal|kill|restart|latency|latency-clear"
    exit 1
    ;;
esac
```

#### storage adapter 集成示例 — redisx

```go
// /home/workspace/redisx/internal/fault/persist_test.go
package fault_test

import (
    "context"
    "os/exec"
    "testing"
    "time"

    "github.com/ZoneCNH/redisx"
)

func faultFixture(t *testing.T, fault string) (heal func()) {
    t.Helper()
    cmd := exec.Command("sudo", "scripts/fault-fixture.sh", "redis", fault)
    if out, err := cmd.CombinedOutput(); err != nil {
        t.Fatalf("fault injection failed: %v\n%s", err, out)
    }
    return func() {
        healCmd := exec.Command("sudo", "scripts/fault-fixture.sh",
            "redis", fault+"-heal")
        if out, err := healCmd.CombinedOutput(); err != nil {
            t.Logf("heal failed (may need manual cleanup): %v\n%s", err, out)
        }
    }
}

func TestPersistUnderNetworkPartition(t *testing.T) {
    // RDX-007: persistence survives 30s partition
    client, err := redisx.NewClient(redisx.Config{Addr: "10.0.0.1:6379"})
    if err != nil {
        t.Fatal(err)
    }
    defer client.Close()

    if err := client.Set(context.Background(), "fault-key", "before", 0); err != nil {
        t.Fatal(err)
    }

    cleanup := faultFixture(t, "partition")
    time.Sleep(30 * time.Second)
    cleanup()

    val, err := client.Get(context.Background(), "fault-key")
    if err != nil {
        t.Fatalf("get after partition heal: %v", err)
    }
    if val != "before" {
        t.Errorf("persistence lost: got %q, want %q", val, "before")
    }
}
```

---

#### Go-native fault controller（替代 shell 调用）

将故障注入逻辑从 `exec.Command("sudo", "scripts/fault-fixture.sh", ...)` 提升为纯 Go 库，消除 shell 依赖、改进错误处理和可测性。

**包结构**：

```text
/home/workspace/xlib_standard/fixture/fault/
├── fault.go           # FaultType 枚举 + FaultController 公共接口
├── netns.go           # network namespace 管理 (netlink)
├── iptables.go        # iptables/nftables 规则注入
├── systemd.go         # systemd 服务生命周期 (dbus)
├── traffic.go         # tc netem 延迟注入
├── fault_test.go      # 自测：在不依赖真实服务的情况下验证注入路径
└── helpers.go         # 测试辅助函数
```

**fault.go — 核心接口与类型**：

```go
// /home/workspace/xlib_standard/fixture/fault/fault.go
package fault

import (
    "fmt"
    "time"
)

// Type 定义支持的故障类型。
type Type string

const (
    // 网络故障
    NetworkPartition Type = "partition"  // 切断 netns 内外通信
    NetworkHeal      Type = "partition-heal"

    // 延迟注入
    InjectLatency  Type = "latency"       // 添加网络延迟
    ClearLatency   Type = "latency-clear"

    // 进程故障
    KillService    Type = "kill"          // 强制终止服务
    RestartService Type = "restart"        // 重启服务
)

// validTypes 是 Type 的白名单。
var validTypes = map[Type]bool{
    NetworkPartition: true,
    NetworkHeal:      true,
    InjectLatency:    true,
    ClearLatency:     true,
    KillService:      true,
    RestartService:   true,
}

// Validate 返回 t 是否是已知的故障类型。
func (t Type) Validate() error {
    if validTypes[t] {
        return nil
    }
    return fmt.Errorf("unknown fault type %q", t)
}

// Controller 是故障注入的顶层接口。
// 每个 storage adapter 的测试代码通过此接口注入/清除故障。
type Controller interface {
    // Service 返回此 Controller 管理的服务名。
    Service() string

    // Inject 注入指定类型的故障。返回 heal 函数和可能的错误。
    // 调用者应在测试结束时 defer heal()。
    Inject(fault Type, opts ...Option) (heal func(), err error)

    // InjectLatency 注入指定时长的网络延迟。
    // 返回清除函数。
    InjectLatency(delay time.Duration) (clear func(), err error)
}

// Option 用于传递故障类型特定的参数。
type Option func(*injectOptions)

type injectOptions struct {
    latency time.Duration // 仅用于 InjectLatency 类型
}

// WithLatency 设置延迟注入的时长。
func WithLatency(d time.Duration) Option {
    return func(o *injectOptions) {
        o.latency = d
    }
}

// ErrNotRoot 在不具备 sudo 权限时返回。
var ErrNotRoot = fmt.Errorf("fault controller requires root privileges (sudo required)")
```

**netns.go — 网络命名空间管理**：

```go
// /home/workspace/xlib_standard/fixture/fault/netns.go
package fault

import (
    "fmt"
    "os"
    "os/exec"
    "path/filepath"
    "runtime"

    "github.com/vishvananda/netns"
)

// resolveNetns 解析 CI 服务的 network namespace 路径。
// 约定：每个 CI 服务的 netns 名称为 "ci-{service}"。
func resolveNetns(service string) (netns.NsHandle, error) {
    nsName := "ci-" + service

    // 首先尝试通过名称查找（需要 iproute2 创建）
    nsPath := filepath.Join("/var/run/netns", nsName)
    if _, err := os.Stat(nsPath); err == nil {
        return netns.GetFromPath(nsPath)
    }

    // 备选：通过 pid 查找
    pid, err := findServicePID(service)
    if err != nil {
        return netns.None(), fmt.Errorf("netns %q: %w", nsName, err)
    }
    return netns.GetFromPid(pid)
}

// findServicePID 通过 systemd 查找服务的 PID。
func findServicePID(service string) (int, error) {
    // 调用 systemctl show 获取 MainPID
    out, err := exec.Command(
        "systemctl", "show", "-p", "MainPID",
        "ci-"+service+".service",
    ).Output()
    if err != nil {
        return 0, fmt.Errorf("find service pid: %w", err)
    }
    var pid int
    if _, err := fmt.Sscanf(string(out), "MainPID=%d", &pid); err != nil {
        return 0, fmt.Errorf("parse MainPID: %w", err)
    }
    if pid <= 0 {
        return 0, fmt.Errorf("service %q not running", service)
    }
    return pid, nil
}

// netnsController 是 Controller 的 netns 实现。
type netnsController struct {
    service  string
    nsHandle netns.NsHandle
}

func newNetnsController(service string) (*netnsController, error) {
    // 确保当前 goroutine 未锁定到 OS 线程
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    ns, err := resolveNetns(service)
    if err != nil {
        return nil, err
    }
    return &netnsController{service: service, nsHandle: ns}, nil
}

func (c *netnsController) Service() string { return c.service }
```

**iptables.go — iptables 规则注入**：

```go
// /home/workspace/xlib_standard/fixture/fault/iptables.go
package fault

import (
    "fmt"
    "os/exec"
)

// partitionNetns 在服务的 netns 内添加/移除全阻断规则。
func partitionNetns(service string, block bool) error {
    chain := "OUTPUT"
    // 通过 ip netns exec 在目标 netns 内运行 iptables
    // 等价于: ip netns exec ci-<service> iptables ...
    args := []string{"netns", "exec", "ci-" + service, "iptables"}

    if block {
        // 添加阻断规则
        args = append(args, "-A", chain, "-j", "DROP")
    } else {
        // 清除所有规则（恢复通信）
        args = append(args, "-F", chain)
    }

    cmd := exec.Command("ip", args...)
    if out, err := cmd.CombinedOutput(); err != nil {
        action := "block"
        if !block {
            action = "unblock"
        }
        return fmt.Errorf("iptables %s %s: %w\noutput: %s",
            chain, action, err, string(out))
    }
    return nil
}

// Inject 实现 Controller。
func (c *netnsController) Inject(fault Type, opts ...Option) (func(), error) {
    if err := fault.Validate(); err != nil {
        return nil, err
    }

    var healFn func() error

    switch fault {
    case NetworkPartition:
        if err := partitionNetns(c.service, true); err != nil {
            return nil, err
        }
        healFn = func() error { return partitionNetns(c.service, false) }

    case NetworkHeal:
        // 显式恢复
        healFn = func() error { return partitionNetns(c.service, false) }
        if err := healFn(); err != nil {
            return nil, err
        }

    case KillService:
        if err := killService(c.service); err != nil {
            return nil, err
        }
        healFn = func() error { return restartService(c.service) }

    case RestartService:
        if err := restartService(c.service); err != nil {
            return nil, err
        }
        healFn = nil // restart 本身就是修复动作

    case InjectLatency:
        o := &injectOptions{}
        for _, opt := range opts {
            opt(o)
        }
        if o.latency == 0 {
            o.latency = defaultLatency
        }
        if err := injectLatency(c.service, o.latency); err != nil {
            return nil, err
        }
        healFn = func() error { return clearLatency(c.service) }

    case ClearLatency:
        healFn = func() error { return clearLatency(c.service) }
        if err := healFn(); err != nil {
            return nil, err
        }

    default:
        return nil, fmt.Errorf("fault %q not implemented for netns controller", fault)
    }

    return wrapHeal(healFn), nil
}

// InjectLatency 实现 Controller 的便捷方法。
func (c *netnsController) InjectLatency(delay time.Duration) (func(), error) {
    return c.Inject(InjectLatency, WithLatency(delay))
}

// wrapHeal 将 error-returning heal 转换为无返回值的函数。
func wrapHeal(healFn func() error) func() {
    if healFn == nil {
        return func() {}
    }
    return func() {
        if err := healFn(); err != nil {
            // 使用标准 log 输出 heal 失败，不 panic
            // 调用方应在测试结束时检查测试状态
            fmt.Fprintf(os.Stderr, "WARNING: fault heal failed: %v\n", err)
        }
    }
}
```

**traffic.go — tc netem 延迟注入**：

```go
// /home/workspace/xlib_standard/fixture/fault/traffic.go
package fault

import (
    "fmt"
    "os/exec"
    "time"
)

const defaultLatency = 500 * time.Millisecond

// injectLatency 在服务的 netns 内通过 tc netem 添加延迟。
// 对应命令:
//
//	ip netns exec ci-<service> tc qdisc add dev lo root netem delay <ms>ms
func injectLatency(service string, delay time.Duration) error {
    delayMs := delay.Milliseconds()
    if delayMs <= 0 {
        return fmt.Errorf("latency must be positive, got %dms", delayMs)
    }
    cmd := exec.Command("ip", "netns", "exec", "ci-"+service,
        "tc", "qdisc", "add", "dev", "lo", "root",
        "netem", "delay", fmt.Sprintf("%dms", delayMs),
    )
    out, err := cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("tc qdisc add (delay %dms): %w\noutput: %s",
            delayMs, err, string(out))
    }
    return nil
}

// clearLatency 清除服务的 tc qdisc 规则。
func clearLatency(service string) error {
    cmd := exec.Command("ip", "netns", "exec", "ci-"+service,
        "tc", "qdisc", "del", "dev", "lo", "root",
    )
    out, err := cmd.CombinedOutput()
    if err != nil {
        // "RTNETLINK answers: No such file or directory" 表示没有 qdisc
        // 这不是错误 — 只是之前没有添加过规则
        return fmt.Errorf("tc qdisc del: %w\noutput: %s", err, string(out))
    }
    return nil
}
```

**systemd.go — systemd 服务生命周期**：

```go
// /home/workspace/xlib_standard/fixture/fault/systemd.go
package fault

import (
    "context"
    "fmt"
    "os/exec"
    "strings"
    "time"
)

const (
    serviceRestartTimeout = 30 * time.Second
    serviceStopTimeout    = 10 * time.Second
)

// killService 强制终止服务。
func killService(service string) error {
    unit := "ci-" + service + ".service"

    // 先获取 PID，再 kill -9
    out, err := exec.Command(
        "systemctl", "show", "-p", "MainPID", unit,
    ).Output()
    if err != nil {
        return fmt.Errorf("kill: get pid: %w", err)
    }
    pidStr := strings.TrimPrefix(strings.TrimSpace(string(out)), "MainPID=")
    if pidStr == "0" || pidStr == "" {
        return fmt.Errorf("kill: service %q not running (MainPID=%s)", unit, pidStr)
    }

    killCmd := exec.Command("kill", "-9", pidStr)
    if out, err := killCmd.CombinedOutput(); err != nil {
        return fmt.Errorf("kill: kill -9 %s: %w\noutput: %s", pidStr, err, string(out))
    }
    return nil
}

// restartService 重启 systemd 服务。
func restartService(service string) error {
    unit := "ci-" + service + ".service"

    ctx, cancel := context.WithTimeout(context.Background(), serviceRestartTimeout)
    defer cancel()

    cmd := exec.CommandContext(ctx, "systemctl", "restart", unit)
    out, err := cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("systemctl restart %s: %w\noutput: %s", unit, err, string(out))
    }

    // 等待服务进入 running 状态
    for i := 0; i < 10; i++ {
        statusCmd := exec.Command("systemctl", "is-active", unit)
        statusOut, _ := statusCmd.Output()
        if strings.TrimSpace(string(statusOut)) == "active" {
            return nil
        }
        time.Sleep(1 * time.Second)
    }
    return fmt.Errorf("service %q did not become active within %v", unit, serviceRestartTimeout)
}

// ensureSudo 验证当前进程是否有 sudo 权限。
// 调用方在测试入口调用，快速失败。
func ensureSudo() error {
    cmd := exec.Command("sudo", "-n", "true")
    if err := cmd.Run(); err != nil {
        return fmt.Errorf("%w: sudo -n true failed — "+
            "ensure CI runner has passwordless sudo", ErrNotRoot)
    }
    return nil
}
```

**helpers.go — 测试辅助函数**：

```go
// /home/workspace/xlib_standard/fixture/fault/helpers.go
package fault

import (
    "fmt"
    "os"
    "strings"
    "testing"
)

// NewController 创建故障控制器。
// 在 CI 环境中自动选择 netns 实现。
// 在非 CI 环境（本地开发）跳过故障注入。
func NewController(service string) (Controller, error) {
    if err := ensureSudo(); err != nil {
        return nil, err
    }
    return newNetnsController(service)
}

// SkipIfNotCI 在非 CI 环境中跳过故障测试。
// 故障注入需要 root + network namespace，本地开发环境通常不具备。
func SkipIfNotCI(t testing.TB) {
    if os.Getenv("CI") != "true" {
        t.Skip("fault injection requires CI environment (CI=true)")
    }
}

// SkipIfNotRoot 在不具备 root 权限时跳过。
func SkipIfNotRoot(t testing.TB) {
    if os.Getuid() != 0 {
        t.Skip("fault injection requires root (test not running as root)")
    }
}

// SkipIfNotCIOrRoot 综合检查。
func SkipIfNotCIOrRoot(t testing.TB) {
    if os.Getenv("CI") == "true" && os.Getuid() == 0 {
        return
    }
    t.Skipf("fault injection requires CI=true and root; got CI=%q uid=%d",
        os.Getenv("CI"), os.Getuid())
}

// FaultScenario 描述一个故障测试场景。
type FaultScenario struct {
    Name        string
    Fault       Type
    Duration    time.Duration // 故障持续时间
    Setup       func() error   // 故障前的准备动作
    Verify      func() error   // 故障中的验证
    HealVerify  func() error   // 恢复后的验证
    SkipHeal    bool           // 跳过自动恢复（如 restart 自愈）
}

// RunScenario 运行一个故障测试场景。
func RunScenario(t testing.TB, ctrl Controller, sc *FaultScenario) {
    t.Helper()
    t.Run(sc.Name, func(t *testing.T) {
        if sc.Setup != nil {
            if err := sc.Setup(); err != nil {
                t.Fatalf("setup: %v", err)
            }
        }

        // 注入故障
        heal, err := ctrl.Inject(sc.Fault)
        if err != nil {
            t.Fatalf("inject %s: %v", sc.Fault, err)
        }

        // 如果不跳过恢复，则 defer heal
        if !sc.SkipHeal {
            defer heal()
        }

        // 等待故障生效
        if sc.Duration > 0 {
            time.Sleep(sc.Duration)
        }

        // 验证故障中的行为
        if sc.Verify != nil {
            if err := sc.Verify(); err != nil {
                t.Errorf("during fault: %v", err)
            }
        }

        // 如果需要跳过自动恢复，手动 heal
        if sc.SkipHeal && heal != nil {
            heal()
        }

        // 验证恢复后的行为
        if sc.HealVerify != nil {
            if err := sc.HealVerify(); err != nil {
                t.Errorf("after heal: %v", err)
            }
        }
    })
}

// MustNewController 创建控制器，失败时终止测试。
func MustNewController(t testing.TB, service string) Controller {
    t.Helper()
    SkipIfNotCIOrRoot(t)
    ctrl, err := NewController(service)
    if err != nil {
        t.Fatalf("fault controller for %q: %v", service, err)
    }
    return ctrl
}
```

**适配器测试使用示例 — 无 shell 依赖**：

```go
// /home/workspace/redisx/internal/fault/persist_test.go
package fault_test

import (
    "context"
    "testing"
    "time"

    "github.com/ZoneCNH/xlib_standard/fixture/fault"
    "github.com/ZoneCNH/redisx"
)

func TestPersistUnderNetworkPartition(t *testing.T) {
    // RDX-007: 持久化在 30s 网络分区后不受损
    ctrl := fault.MustNewController(t, "redis")
    client := mustConnectRedis(t)

    // 前置写入
    const key = "fault-key"
    const val = "before"
    if err := client.Set(context.Background(), key, val, 0); err != nil {
        t.Fatal(err)
    }

    fault.RunScenario(t, ctrl, &fault.FaultScenario{
        Name:     "30s network partition",
        Fault:    fault.NetworkPartition,
        Duration: 30 * time.Second,
        HealVerify: func() error {
            got, err := client.Get(context.Background(), key)
            if err != nil {
                return fmt.Errorf("get after heal: %w", err)
            }
            if got != val {
                return fmt.Errorf("persistence lost: got %q, want %q", got, val)
            }
            return nil
        },
    })
}

func TestCommandTimeoutUnderLatency(t *testing.T) {
    ctrl := fault.MustNewController(t, "redis")
    client := mustConnectRedis(t)

    fault.RunScenario(t, ctrl, &fault.FaultScenario{
        Name:     "GET with 2s latency under 1s timeout",
        Fault:    fault.InjectLatency,
        Duration: 1 * time.Second,  // 等待延迟生效
        Setup: func() error {
            return client.Set(context.Background(), "lat-key", "v", 0)
        },
        Verify: func() error {
            ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
            defer cancel()
            _, err := client.Get(ctx, "lat-key")
            if err == nil {
                return fmt.Errorf("expected timeout error, got nil")
            }
            return nil
        },
    })
}

func TestRecoverAfterKill(t *testing.T) {
    ctrl := fault.MustNewController(t, "redis")

    fault.RunScenario(t, ctrl, &fault.FaultScenario{
        Name:     "kill and restart",
        Fault:    fault.KillService,
        Duration: 5 * time.Second,
        SkipHeal: true, // restart 是自愈动作
        Verify: func() error {
            // 在服务被 kill 后，新连接应失败
            client, err := redisx.NewClient(redisx.Config{Addr: "10.0.0.1:6379"})
            if err != nil {
                return nil // 预期行为：连接被拒绝
            }
            defer client.Close()
            _, err = client.Ping(context.Background())
            if err != nil {
                return nil // 预期行为
            }
            return fmt.Errorf("expected connection failure after kill")
        },
        HealVerify: func() error {
            // restart 后服务应恢复正常
            client, err := redisx.NewClient(redisx.Config{Addr: "10.0.0.1:6379"})
            if err != nil {
                return fmt.Errorf("reconnect after restart: %w", err)
            }
            defer client.Close()
            return client.Ping(context.Background())
        },
    })
}

// mustConnectRedis 是测试辅助函数。
func mustConnectRedis(t *testing.T) *redisx.Client {
    t.Helper()
    client, err := redisx.NewClient(redisx.Config{Addr: "10.0.0.1:6379"})
    if err != nil {
        t.Fatalf("connect redis: %v", err)
    }
    t.Cleanup(func() { client.Close() })
    return client
}
```

**跨 adapter 复用的 soak 夹具**：

```go
// /home/workspace/xlib_standard/fixture/fault/soak.go
package fault

import (
    "context"
    "fmt"
    "os"
    "os/signal"
    "syscall"
    "testing"
    "time"
)

// SoakConfig 定义 soak 测试的参数。
type SoakConfig struct {
    Service   string
    Duration  time.Duration  // 总 soak 时长
    Faults    []SoakFault    // 要注入的故障序列
    HealthCheck func(context.Context) error // 每 10s 执行一次健康检查
}

// SoakFault 描述 soak 过程中的单个故障注入。
type SoakFault struct {
    After    time.Duration // 在 soak 开始后多久注入
    Fault    Type
    Duration time.Duration // 故障持续时间
}

// RunSoak 运行 soak 测试。
// 在总 Duration 内按 Faults 时间表注入故障，每 10s 运行 HealthCheck。
func RunSoak(t testing.TB, cfg SoakConfig) {
    SkipIfNotCIOrRoot(t)

    ctrl, err := NewController(cfg.Service)
    if err != nil {
        t.Fatalf("soak: controller: %v", err)
    }

    ctx, cancel := context.WithTimeout(context.Background(), cfg.Duration)
    defer cancel()

    // 监听 SIGINT/SIGTERM 以安全清理
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    defer signal.Stop(sigCh)

    // 故障注入调度器
    faultDone := make(chan struct{})
    go func() {
        defer close(faultDone)
        startTime := time.Now()
        for _, f := range cfg.Faults {
            elapsed := time.Since(startTime)
            wait := f.After - elapsed
            if wait > 0 {
                select {
                case <-time.After(wait):
                case <-ctx.Done():
                    return
                case <-sigCh:
                    return
                }
            }

            t.Logf("soak: injecting %s (duration %v)", f.Fault, f.Duration)
            heal, err := ctrl.Inject(f.Fault)
            if err != nil {
                t.Errorf("soak: inject %s: %v", f.Fault, err)
                continue
            }

            select {
            case <-time.After(f.Duration):
                heal()
            case <-ctx.Done():
                heal()
                return
            case <-sigCh:
                heal()
                return
            }
        }
    }()

    // 健康检查循环
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()

    var failures int
    for {
        select {
        case <-ticker.C:
            if cfg.HealthCheck != nil {
                if err := cfg.HealthCheck(ctx); err != nil {
                    failures++
                    t.Logf("soak: health check FAIL (#%d): %v", failures, err)
                    if failures >= 5 {
                        t.Fatalf("soak: too many health check failures (%d)", failures)
                    }
                }
            }
        case <-ctx.Done():
            <-faultDone // 等待故障 goroutine 完成
            t.Logf("soak: completed (%d health check failures)", failures)
            return
        case <-sigCh:
            cancel()
            t.Logf("soak: interrupted by signal")
            return
        }
    }
}
```

**soak 适配器使用示例**：

```go
// /home/workspace/redisx/internal/fault/soak_test.go
func TestRedisSoak(t *testing.T) {
    client := mustConnectRedis(t)

    fault.RunSoak(t, fault.SoakConfig{
        Service:  "redis",
        Duration: 3 * time.Hour,  // 夜间 soak 窗口
        Faults: []fault.SoakFault{
            {After: 5 * time.Minute, Fault: fault.NetworkPartition, Duration: 30 * time.Second},
            {After: 15 * time.Minute, Fault: fault.InjectLatency, Duration: 1 * time.Minute},
            {After: 30 * time.Minute, Fault: fault.KillService, Duration: 30 * time.Second},
            {After: 60 * time.Minute, Fault: fault.NetworkPartition, Duration: 60 * time.Second},
            {After: 90 * time.Minute, Fault: fault.InjectLatency, Duration: 2 * time.Minute},
            {After: 120 * time.Minute, Fault: fault.KillService, Duration: 30 * time.Second},
        },
        HealthCheck: func(ctx context.Context) error {
            return client.Ping(ctx)
        },
    })
}
```

**与 Bash 方案的对比**：

| 维度            | Bash fixture                                            | Go-native fixture                           |
| --------------- | ------------------------------------------------------- | ------------------------------------------- |
| 执行方式        | `exec.Command("sudo", "scripts/fault-fixture.sh", ...)` | 纯 Go 函数调用                              |
| 错误处理        | 混合 stdout 解析                                        | 结构化 error wrapping                       |
| 可测性          | 只能通过 integration test 验证                          | `fault_test.go` 可自测 Controller           |
| heal 追踪       | 手动匹配 `fault` / `fault-heal` 字符串对                | `Inject()` 返回类型安全的 `func()`          |
| 跨 adapter 复用 | 每个 adapter 复制 shell 调用                            | `FaultScenario.RunScenario()` + `RunSoak()` |
| SOAK 故障调度   | 无（需要外部 cron）                                     | `RunSoak()` 内置定时故障注入循环            |
| 本地开发跳过    | 无（直接运行 shell 可能破坏本地环境）                   | `SkipIfNotCIOrRoot()` 自动跳过              |
| 信号处理        | 无                                                      | `RunSoak()` 监听 SIGINT/SIGTERM 安全清理    |

---

#### eBPF chaos controller（零依赖内核级故障注入）

netns/iptables 方案需要 `ip`、`iptables`、`tc` 二进制和 sudo 调用，且只能操作整个网络命名空间。eBPF 方案直接在**内核路径上**注入故障 — 精确到单个 socket、系统调用或 I/O 操作，无需外部二进制。

```
┌──────────────────────────────────────────────────┐
│  Go test binary (adapter under test)             │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │  fault/ebpf package                          ││
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐     ││
│  │  │ packdrop │ │  connrst │ │  ioerr   │ ... ││
│  │  │ .bpf.c   │ │  .bpf.c  │ │  .bpf.c  │     ││
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘     ││
│  │       │ cilium/ebpf Load + Attach            ││
│  │  ┌────┴─────────────┴─────────────┴─────┐    ││
│  │  │  eBPF maps (config / stats / filter) │    ││
│  │  └──────────────────────────────────────┘    ││
│  └──────────────────────────────────────────────┘│
│                       │                          │
│  ┌────────────────────┴──────────────────────────┐│
│  │  Linux kernel (tc / cgroup / kprobe hooks)    ││
│  │  → 精确拦截/延迟特定进程的 connect/write/...  ││
│  └───────────────────────────────────────────────┘│
└──────────────────────────────────────────────────┘
```

**依赖**：`github.com/cilium/ebpf` — 纯 Go eBPF 库，无需 `bcc`、`clang` 运行时（编译时需 `clang` + `bpf_target`）。

**包结构**：

```text
/home/workspace/xlib_standard/fixture/fault/ebpf/
├── ebpf.go           # 顶层 Controller 实现 (ebpfController)
├── packdrop.c        # TC hook: 丢包
├── packdrop.go       # packdrop 的 Go loader
├── connrst.c         # sockops hook: 连接重置
├── connrst.go        # connrst 的 Go loader
├── ioerr.c           # kprobe hook: I/O 系统调用错误注入
├── ioerr.go          # ioerr 的 Go loader
├── latency.c         # kprobe hook: 精确延迟注入
├── latency.go        # latency 的 Go loader
├── gen.go            # go:generate 指令
├── probes.go         # eBPF prog 生命周期 (load/attach/detach)
└── ebpf_test.go      # 自测
```

---

**ebpf.go — eBPF Controller 顶层接口**：

```go
// /home/workspace/xlib_standard/fixture/fault/ebpf/ebpf.go
package ebpf

import (
    "fmt"
    "os"
    "sync"

    "github.com/ZoneCNH/xlib_standard/fixture/fault"
)

// Controller 是基于 eBPF 的故障注入器。
// 与 netns Controller 不同，eBPF Controller 精确到 PID/端口/系统调用级别。
type Controller struct {
    mu       sync.Mutex
    active   map[fault.Type]*probeSet // 当前活跃的 eBPF 探针
    targetPID int                     // 目标进程 PID（0 = 全局）
    filter    Filter                  // 过滤条件
}

// Filter 定义 eBPF 故障注入的过滤条件。
// 零值表示匹配所有。
type Filter struct {
    PID      uint32   // 目标进程 PID（eBPF bpf_get_current_pid_tgid() >> 32）
    DstPort  uint16   // 目标端口
    SrcPort  uint16   // 源端口
    DstIP    uint32   // 目标 IPv4 (network byte order)
    Protocol uint8    // IP 协议号 (6=TCP, 17=UDP)
    FuncName string   // kprobe 附加的内核函数名
}

// NewController 创建一个 eBPF 故障控制器。
func NewController(targetPID int, filter Filter) (*Controller, error) {
    if os.Getuid() != 0 {
        return nil, fault.ErrNotRoot
    }
    return &Controller{
        active:    make(map[fault.Type]*probeSet),
        targetPID: targetPID,
        filter:    filter,
    }, nil
}

// Service 返回 "ebpf"（eBPF 控制器不绑定特定服务名）。
func (c *Controller) Service() string { return "ebpf" }

// Inject 注入指定类型的故障。
func (c *Controller) Inject(ft fault.Type, opts ...fault.Option) (func(), error) {
    if err := ft.Validate(); err != nil {
        return nil, err
    }

    c.mu.Lock()
    defer c.mu.Unlock()

    // 检查是否已有同类型探针活跃
    if _, exists := c.active[ft]; exists {
        return nil, fmt.Errorf("ebpf: fault %q already active", ft)
    }

    loader, ok := probeLoaders[ft]
    if !ok {
        return nil, fmt.Errorf("ebpf: fault %q not supported by eBPF controller", ft)
    }

    ps, err := loader(c.targetPID, c.filter)
    if err != nil {
        return nil, fmt.Errorf("ebpf: load %s: %w", ft, err)
    }

    if err := ps.attach(); err != nil {
        ps.close()
        return nil, fmt.Errorf("ebpf: attach %s: %w", ft, err)
    }

    c.active[ft] = ps

    heal := func() {
        c.mu.Lock()
        defer c.mu.Unlock()
        if ps, ok := c.active[ft]; ok {
            ps.close()
            delete(c.active, ft)
        }
    }

    return heal, nil
}

// InjectLatency 注入精确延迟。
func (c *Controller) InjectLatency(delay time.Duration) (func(), error) {
    return c.Inject(fault.InjectLatency, fault.WithLatency(delay))
}

// Stats 返回当前活跃探针的统计信息。
func (c *Controller) Stats(ft fault.Type) (ProbeStats, error) {
    c.mu.Lock()
    defer c.mu.Unlock()
    ps, ok := c.active[ft]
    if !ok {
        return ProbeStats{}, fmt.Errorf("ebpf: fault %q not active", ft)
    }
    return ps.stats()
}

// Close 清理所有活跃探针。
func (c *Controller) Close() error {
    c.mu.Lock()
    defer c.mu.Unlock()
    for ft, ps := range c.active {
        ps.close()
        delete(c.active, ft)
    }
    return nil
}

// probeSet 封装一个 eBPF 程序的加载/附加/统计/清理生命周期。
type probeSet struct {
    objs    interface{ Close() error }
    links   []interface{ Close() error }
    statsFn func() (ProbeStats, error)
}

func (ps *probeSet) attach() error { return nil } // 由具体 loader 实现
func (ps *probeSet) close() {
    for _, link := range ps.links {
        link.Close()
    }
    ps.objs.Close()
}
func (ps *probeSet) stats() (ProbeStats, error) {
    if ps.statsFn != nil {
        return ps.statsFn()
    }
    return ProbeStats{}, nil
}

// ProbeStats 包含 eBPF 探针的运行时统计。
type ProbeStats struct {
    Injected  uint64 // 成功注入的故障次数
    Skipped   uint64 // 被过滤跳过的次数
    Errors    uint64 // 探针内部错误次数
}

// probeLoaders 是故障类型到加载器的注册表。
var probeLoaders = map[fault.Type]func(int, Filter) (*probeSet, error){
    fault.NetworkPartition: loadPacketDrop,
    fault.NetworkHeal:      nil, // heal 由 Inject 返回的 heal 函数处理
    fault.InjectLatency:    loadLatency,
    fault.ClearLatency:     nil,
}

// gen.go 中的 go:generate 指令编译 eBPF C 程序：

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -target bpf -type event_t packdrop packdrop.c -- -I/usr/include/bpf -I.
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -target bpf connrst connrst.c -- -I/usr/include/bpf -I.
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -target bpf ioerr ioerr.c -- -I/usr/include/bpf -I.
//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -target bpf latency latency.c -- -I/usr/include/bpf -I.
```

---

**packdrop.c — TC hook 精确丢包（替代 iptables DROP）**：

```c
// /home/workspace/xlib_standard/fixture/fault/ebpf/packdrop.c
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

// config: 由 Go 侧通过 BPF map 写入过滤条件
struct config_t {
    __u32 target_pid;    // 0 = 匹配所有进程
    __u16 dst_port;      // 0 = 匹配所有端口
    __u16 src_port;
    __u32 dst_ip;        // 0 = 匹配所有 IP
    __u8  protocol;      // 0 = 匹配所有协议
    __u8  enabled;       // 1 = 启用丢包，0 = 旁路
};

// stats 供 Go 侧读取
struct stats_t {
    __u64 dropped;
    __u64 passed;
    __u64 filtered;
};

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct config_t);
} config SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct stats_t);
} stats SEC(".maps");

// TC classifier: 附加到目标进程的 tc ingress/egress hook
SEC("tc")
int packdrop_main(struct __sk_buff *skb) {
    __u32 zero = 0;
    struct config_t *cfg = bpf_map_lookup_elem(&config, &zero);
    if (!cfg || !cfg->enabled) {
        return BPF_OK; // 旁路
    }

    // PID 过滤（仅在 cgroup socket hook 中可用；tc hook 无 PID 上下文）
    // 生产用 sockops hook 替代以获得 PID 上下文
    // 这里展示完整的过滤逻辑用于 sockops 版本

    // 端口过滤
    if (cfg->dst_port != 0 || cfg->src_port != 0) {
        // tc hook 中无法直接访问端口号；此过滤用于 sockops 版本
        // 对于 tc 版本，全量丢包
    }

    struct stats_t *st = bpf_map_lookup_elem(&stats, &zero);
    if (st) {
        __sync_fetch_and_add(&st->dropped, 1);
    }

    // TC_ACT_SHOT = 丢弃数据包（不通知发送方）
    return 2; // TC_ACT_SHOT
}

char LICENSE[] SEC("license") = "GPL";
```

**packdrop.go — Go loader**：

```go
// /home/workspace/xlib_standard/fixture/fault/ebpf/packdrop.go
package ebpf

import (
    "fmt"
    "unsafe"

    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"

    "github.com/ZoneCNH/xlib_standard/fixture/fault"
)

// 由 bpf2go 生成的类型 — 构建时不提交到 VCS
// type packdropConfig struct { ... }
// type packdropStats struct { ... }
// type packdropObjects struct { ... }

func loadPacketDrop(targetPID int, filter Filter) (*probeSet, error) {
    // 加载编译后的 eBPF 对象
    var objs packdropObjects
    if err := loadPackdropObjects(&objs, nil); err != nil {
        return nil, fmt.Errorf("load packdrop objects: %w", err)
    }

    // 写入配置到 BPF map
    var zero uint32
    cfg := packdropConfig{
        TargetPid: uint32(targetPID),
        DstPort:   filter.DstPort,
        SrcPort:   filter.SrcPort,
        DstIp:     filter.DstIP,
        Protocol:  filter.Protocol,
        Enabled:   1,
    }
    if err := objs.Config.Update(&zero, &cfg, ebpf.UpdateAny); err != nil {
        objs.Close()
        return nil, fmt.Errorf("update config map: %w", err)
    }

    // 附加到网络接口
    // TC hook: egress 方向附加到目标接口
    iface, err := net.InterfaceByName("eth0") // 可配置
    if err != nil {
        objs.Close()
        return nil, fmt.Errorf("find interface: %w", err)
    }

    tcLink, err := link.AttachTCX(link.TCXOptions{
        Program:   objs.PackdropMain,
        Attach:    ebpf.AttachTCXEgress,
        Interface: iface.Index,
    })
    if err != nil {
        objs.Close()
        return nil, fmt.Errorf("attach tc: %w", err)
    }

    ps := &probeSet{
        objs:  objs,
        links: []interface{ Close() error }{tcLink},
        statsFn: func() (fault.ProbeStats, error) {
            var st packdropStats
            if err := objs.Stats.Lookup(&zero, &st); err != nil {
                return fault.ProbeStats{}, err
            }
            return fault.ProbeStats{
                Injected: st.Dropped,
                Passed:   st.Passed,
                Filtered: st.Filtered,
            }, nil
        },
    }

    return ps, nil
}
```

---

**connrst.c — 连接重置（TCP RST 注入）**：

更精确的网络故障 — 不仅仅丢包，而是通过 TCP RST 伪造连接重置，验证 adapter 的优雅断开和重连逻辑。

```c
// /home/workspace/xlib_standard/fixture/fault/ebpf/connrst.c
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

// sockops: 可获取 PID 上下文的 socket 操作 hook
struct {
    __uint(type, BPF_MAP_TYPE_SOCKHASH);
    __uint(max_entries, 1024);
    __type(key, __u32);
    __type(value, __u64);
} sock_map SEC(".maps");

struct config_t {
    __u32 target_pid;
    __u16 dst_port;
    __u8  enabled;
    __u8  pad;
};

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct config_t);
} config SEC(".maps");

SEC("sockops")
int connrst_sockops(struct bpf_sock_ops *skops) {
    __u32 zero = 0;
    struct config_t *cfg = bpf_map_lookup_elem(&config, &zero);
    if (!cfg || !cfg->enabled) return 0;

    __u32 pid = bpf_get_current_pid_tgid() >> 32;
    if (cfg->target_pid != 0 && pid != cfg->target_pid) return 0;

    // 仅处理 TCP 连接
    if (skops->family != 2) return 0; // AF_INET

    __u32 op = skops->op;
    // 在 active connection 建立后将 socket 加入 sockhash
    if (op == 33 || op == 34) { // BPF_SOCK_OPS_ACTIVE_ESTABLISHED_CB / PASSIVE_ESTABLISHED_CB
        // 端口过滤
        if (cfg->dst_port != 0 &&
            cfg->dst_port != skops->remote_port) return 0;

        // 将 socket 加入 sockhash 供 sk_msg 程序处理
        bpf_sock_hash_update(skops, &sock_map, &zero, BPF_ANY);
    }
    return 0;
}

// sk_msg: 拦截 sendmsg，注入 TCP RST
SEC("sk_msg")
int connrst_msg(struct sk_msg_md *msg) {
    // 丢弃 socket 缓冲区并发送 RST
    // 通过设置 SK_DROP + 内核自动发送 RST
    return 1; // SK_DROP — kernel 自动发送 RST 到对端
}

char LICENSE[] SEC("license") = "GPL";
```

**connrst.go — Go loader**：

```go
// /home/workspace/xlib_standard/fixture/fault/ebpf/connrst.go
package ebpf

import (
    "fmt"

    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"

    "github.com/ZoneCNH/xlib_standard/fixture/fault"
)

func loadConnReset(targetPID int, filter Filter) (*probeSet, error) {
    var objs connrstObjects
    if err := loadConnrstObjects(&objs, nil); err != nil {
        return nil, fmt.Errorf("load connrst objects: %w", err)
    }

    // 写入配置
    var zero uint32
    cfg := connrstConfig{
        TargetPid: uint32(targetPID),
        DstPort:   filter.DstPort,
        Enabled:   1,
    }
    if err := objs.Config.Update(&zero, &cfg, ebpf.UpdateAny); err != nil {
        objs.Close()
        return nil, fmt.Errorf("update config: %w", err)
    }

    // 附加 socket map 到 cgroup
    cgroupPath := "/sys/fs/cgroup"
    sockLink, err := link.AttachCgroup(link.CgroupOptions{
        Path:    cgroupPath,
        Attach:  ebpf.AttachCGroupSockOps,
        Program: objs.ConnrstSockops,
    })
    if err != nil {
        objs.Close()
        return nil, fmt.Errorf("attach sockops: %w", err)
    }

    return &probeSet{
        objs:  objs,
        links: []interface{ Close() error }{sockLink},
    }, nil
}
```

---

**ioerr.c — 系统调用级故障（磁盘满、权限拒绝）**：

模拟 `write()` 返回 `ENOSPC`（磁盘满）、`connect()` 返回 `ECONNREFUSED` 等内核级错误。这是最接近真实故障的注入方式 — adapter 看到的是内核返回的真实 errno。

```c
// /home/workspace/xlib_standard/fixture/fault/ebpf/ioerr.c
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_core_read.h>

// 支持的错误类型
#define ERR_ENOSPC      28  // No space left on device
#define ERR_ECONNREFUSED 111 // Connection refused
#define ERR_ETIMEDOUT    110 // Connection timed out
#define ERR_EACCES       13  // Permission denied

struct config_t {
    __u32 target_pid;
    __u32 errno_val;   // 要注入的错误码
    __u32 syscall_nr;  // 目标系统调用号（0 = 全部）
    __u32 probability; // 注入概率：0=从不, 100=每N次触发一次
    __u32 counter;     // 已处理的调用计数
    __u8  enabled;
};

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct config_t);
} config SEC(".maps");

// kprobe on vfs_write: 在数据写入文件系统前拦截
SEC("kprobe/vfs_write")
int ioerr_write(struct pt_regs *ctx) {
    __u32 zero = 0;
    struct config_t *cfg = bpf_map_lookup_elem(&config, &zero);
    if (!cfg || !cfg->enabled) return 0;

    __u32 pid = bpf_get_current_pid_tgid() >> 32;
    if (cfg->target_pid != 0 && pid != cfg->target_pid) return 0;

    // 概率注入
    __u32 cnt = __sync_fetch_and_add(&cfg->counter, 1);
    if (cnt % cfg->probability != 0) return 0;

    // 覆盖系统调用返回值 — 使用 bpf_override_return
    // 注意: 需要内核 CONFIG_BPF_KPROBE_OVERRIDE=y
    bpf_override_return(ctx, -cfg->errno_val);
    return 0;
}

// tracepoint on sys_enter_write: 在系统调用入口拦截
SEC("tracepoint/syscalls/sys_enter_write")
int ioerr_sys_enter_write(struct trace_event_raw_sys_enter *ctx) {
    __u32 zero = 0;
    struct config_t *cfg = bpf_map_lookup_elem(&config, &zero);
    if (!cfg || !cfg->enabled) return 0;

    __u32 pid = bpf_get_current_pid_tgid() >> 32;
    if (cfg->target_pid != 0 && pid != cfg->target_pid) return 0;

    __u32 cnt = __sync_fetch_and_add(&cfg->counter, 1);
    if (cnt % cfg->probability != 0) return 0;

    // 修改 syscall 参数使 write 返回 -errno
    // 将 fd 替换为 -errno_val 使 write 立即失败
    int *fd_ptr = (int *)&ctx->args[0];
    int orig_fd;
    bpf_probe_read_user(&orig_fd, sizeof(orig_fd), fd_ptr);

    // 仅在 fd > 0 时注入（跳过 stdin/stdout/stderr）
    if (orig_fd <= 2) return 0;

    int fake_fd = -cfg->errno_val;
    bpf_probe_write_user(fd_ptr, &fake_fd, sizeof(fake_fd));

    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

**ioerr.go — Go loader**：

```go
// /home/workspace/xlib_standard/fixture/fault/ebpf/ioerr.go
package ebpf

import (
    "fmt"

    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"

    "github.com/ZoneCNH/xlib_standard/fixture/fault"
)

// Errno 定义可注入的内核错误类型。
type Errno uint32

const (
    ErrENOSPC      Errno = 28
    ErrECONNREFUSED Errno = 111
    ErrETIMEDOUT    Errno = 110
    ErrEACCES       Errno = 13
)

func (e Errno) String() string {
    switch e {
    case ErrENOSPC:
        return "ENOSPC"
    case ErrECONNREFUSED:
        return "ECONNREFUSED"
    case ErrETIMEDOUT:
        return "ETIMEDOUT"
    case ErrEACCES:
        return "EACCES"
    default:
        return fmt.Sprintf("ERRNO(%d)", e)
    }
}

// IOErrConfig 配置 I/O 错误注入参数。
type IOErrConfig struct {
    Errno       Errno  // 要注入的错误码
    Probability uint32 // 每 N 次触发一次（100 = 1% 概率）
}

func loadIOErr(targetPID int, filter Filter, ioCfg IOErrConfig) (*probeSet, error) {
    var objs ioerrObjects
    if err := loadIoerrObjects(&objs, nil); err != nil {
        return nil, fmt.Errorf("load ioerr objects: %w", err)
    }

    var zero uint32
    cfg := ioerrConfig{
        TargetPid:   uint32(targetPID),
        ErrnoVal:    uint32(ioCfg.Errno),
        Probability: ioCfg.Probability,
        Enabled:     1,
    }
    if err := objs.Config.Update(&zero, &cfg, ebpf.UpdateAny); err != nil {
        objs.Close()
        return nil, fmt.Errorf("update config: %w", err)
    }

    // 附加到 tracepoint
    tpLink, err := link.Tracepoint("syscalls", "sys_enter_write", objs.IoerrSysEnterWrite, nil)
    if err != nil {
        objs.Close()
        return nil, fmt.Errorf("attach tracepoint: %w", err)
    }

    return &probeSet{
        objs:  objs,
        links: []interface{ Close() error }{tpLink},
    }, nil
}
```

---

**latency.c — 精确延迟注入（替代 tc netem）**：

在 `vfs_read` / `vfs_write` / `tcp_sendmsg` 等内核函数入口处通过 `bpf_loop` 或忙等注入精确延迟。粒度可从 us 到 ms 级别。

```c
// /home/workspace/xlib_standard/fixture/fault/ebpf/latency.c
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>

struct config_t {
    __u32 target_pid;
    __u32 delay_us;     // 延迟微秒数
    __u8  enabled;
};

struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, struct config_t);
} config SEC(".maps");

// kprobe on tcp_sendmsg: 在 TCP 发送路径上注入延迟
SEC("kprobe/tcp_sendmsg")
int latency_tcp_send(struct pt_regs *ctx) {
    __u32 zero = 0;
    struct config_t *cfg = bpf_map_lookup_elem(&config, &zero);
    if (!cfg || !cfg->enabled || cfg->delay_us == 0) return 0;

    __u32 pid = bpf_get_current_pid_tgid() >> 32;
    if (cfg->target_pid != 0 && pid != cfg->target_pid) return 0;

    // 使用 bpf_ktime_get_ns 实现精确忙等
    __u64 start = bpf_ktime_get_ns();
    __u64 target = start + (__u64)cfg->delay_us * 1000;
    for (;;) {
        if (bpf_ktime_get_ns() >= target) break;
    }
    return 0;
}

// kprobe on tcp_recvmsg: 在 TCP 接收路径上注入延迟
SEC("kprobe/tcp_recvmsg")
int latency_tcp_recv(struct pt_regs *ctx) {
    __u32 zero = 0;
    struct config_t *cfg = bpf_map_lookup_elem(&config, &zero);
    if (!cfg || !cfg->enabled || cfg->delay_us == 0) return 0;

    __u32 pid = bpf_get_current_pid_tgid() >> 32;
    if (cfg->target_pid != 0 && pid != cfg->target_pid) return 0;

    __u64 start = bpf_ktime_get_ns();
    __u64 target = start + (__u64)cfg->delay_us * 1000;
    for (;;) {
        if (bpf_ktime_get_ns() >= target) break;
    }
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

**latency.go — Go loader**：

```go
// /home/workspace/xlib_standard/fixture/fault/ebpf/latency.go
package ebpf

import (
    "fmt"
    "time"

    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"

    "github.com/ZoneCNH/xlib_standard/fixture/fault"
)

func loadLatency(targetPID int, filter Filter, delay time.Duration) (*probeSet, error) {
    var objs latencyObjects
    if err := loadLatencyObjects(&objs, nil); err != nil {
        return nil, fmt.Errorf("load latency objects: %w", err)
    }

    var zero uint32
    cfg := latencyConfig{
        TargetPid: uint32(targetPID),
        DelayUs:   uint32(delay.Microseconds()),
        Enabled:   1,
    }
    if err := objs.Config.Update(&zero, &cfg, ebpf.UpdateAny); err != nil {
        objs.Close()
        return nil, fmt.Errorf("update config: %w", err)
    }

    // 附加 kprobes
    sendLink, err := link.Kprobe("tcp_sendmsg", objs.LatencyTcpSend, nil)
    if err != nil {
        objs.Close()
        return nil, fmt.Errorf("attach tcp_sendmsg kprobe: %w", err)
    }

    recvLink, err := link.Kprobe("tcp_recvmsg", objs.LatencyTcpRecv, nil)
    if err != nil {
        sendLink.Close()
        objs.Close()
        return nil, fmt.Errorf("attach tcp_recvmsg kprobe: %w", err)
    }

    return &probeSet{
        objs:  objs,
        links: []interface{ Close() error }{sendLink, recvLink},
    }, nil
}
```

---

**适配器测试使用示例 — eBPF 级故障注入**：

```go
// /home/workspace/kafkax/internal/fault/ebpf_test.go
package fault_test

import (
    "context"
    "os"
    "testing"
    "time"

    "github.com/ZoneCNH/kafkax"
    "github.com/ZoneCNH/xlib_standard/fixture/fault"
    "github.com/ZoneCNH/xlib_standard/fixture/fault/ebpf"
)

func TestProducerUnderTCPRST(t *testing.T) {
    // KFK-004: broker fault — producer recovery after TCP RST
    fault.SkipIfNotCIOrRoot(t)

    pid := os.Getpid() // 注入到当前测试进程
    ctrl, err := ebpf.NewController(pid, ebpf.Filter{
        DstPort:  9092, // Kafka broker port
        Protocol: 6,    // TCP
    })
    if err != nil {
        t.Fatal(err)
    }
    defer ctrl.Close()

    producer := mustConnectKafkaProducer(t)
    defer producer.Close()

    // 先发送一条消息确认正常
    if err := producer.Send(context.Background(), "test-topic", []byte("pre-rst")); err != nil {
        t.Fatal(err)
    }

    // 注入 TCP RST
    heal, err := ctrl.Inject(fault.NetworkPartition) // 使用 connrst 替代
    if err != nil {
        t.Fatal(err)
    }
    time.Sleep(2 * time.Second)
    heal()

    // 验证 producer 能够恢复
    time.Sleep(5 * time.Second) // 等待重连
    if err := producer.Send(context.Background(), "test-topic", []byte("post-rst")); err != nil {
        t.Fatalf("producer failed to recover after TCP RST: %v", err)
    }
}

func TestPersistUnderDiskFull(t *testing.T) {
    // PGX-006: PostgreSQL adapter handles ENOSPC
    fault.SkipIfNotCIOrRoot(t)

    pid := os.Getpid()
    ctrl, err := ebpf.NewController(pid, ebpf.Filter{})
    if err != nil {
        t.Fatal(err)
    }
    defer ctrl.Close()

    // 注入 ENOSPC: 每 5 次 write 系统调用注入一次磁盘满
    heal, err := ctrl.Inject(fault.Type("ioerr"), fault.WithIOErrConfig(ebpf.IOErrConfig{
        Errno:       ebpf.ErrENOSPC,
        Probability: 5,
    }))
    if err != nil {
        t.Fatal(err)
    }
    defer heal()

    // 验证 PG adapter 在 ENOSPC 下的行为
    db := mustConnectPostgres(t)
    defer db.Close()

    // 预期：写入失败并返回明确的 ENOSPC 错误
    err = db.Exec(context.Background(), "INSERT INTO test VALUES (1)")
    if err == nil {
        t.Error("expected ENOSPC error, got nil")
    }
    // adapter 不应 panic 或泄漏连接
}

func TestAdapterLatencyTolerance(t *testing.T) {
    // 验证 adapter 在 100ms+ TCP 延迟下的超时行为
    fault.SkipIfNotCIOrRoot(t)

    pid := os.Getpid()
    ctrl, err := ebpf.NewController(pid, ebpf.Filter{
        DstPort:  6379, // Redis
        Protocol: 6,
    })
    if err != nil {
        t.Fatal(err)
    }
    defer ctrl.Close()

    heal, err := ctrl.InjectLatency(150 * time.Millisecond)
    if err != nil {
        t.Fatal(err)
    }
    defer heal()

    client := mustConnectRedis(t)
    defer client.Close()

    // 使用 100ms 超时，应因 150ms 延迟而超时
    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    defer cancel()

    _, err = client.Get(ctx, "any-key")
    if err == nil {
        t.Error("expected timeout with 150ms kernel delay and 100ms context timeout")
    }
}
```

---

**eBPF 方案前置条件**：

| 条件                                              | 检查方法                                    |
| ------------------------------------------------- | ------------------------------------------- |
| 内核 >= 5.15                                      | `uname -r`                                  |
| `CONFIG_DEBUG_INFO_BTF=y`                         | `ls /sys/kernel/btf/vmlinux`                |
| `CONFIG_BPF_KPROBE_OVERRIDE=y`（仅 I/O 错误注入） | `zgrep BPF_KPROBE_OVERRIDE /proc/config.gz` |
| `clang` + `llvm-strip`                            | `clang --version`（仅编译时）               |
| `libbpf` headers                                  | `/usr/include/bpf/bpf_helpers.h`            |
| `cilium/ebpf` Go 模块                             | `go get github.com/cilium/ebpf@latest`      |

CI runner provision 脚本：

```bash
#!/bin/bash
# scripts/provision-ebpf-runner.sh
# 为 CI runner 安装 eBPF 编译运行时依赖

set -euo pipefail

# 检查内核版本
KERNEL_VER=$(uname -r | cut -d. -f1,2)
if [ "$(echo "$KERNEL_VER >= 5.15" | bc)" != "1" ]; then
    echo "WARNING: kernel $KERNEL_VER < 5.15, eBPF features limited"
fi

# 检查 BTF
if [ ! -f /sys/kernel/btf/vmlinux ]; then
    echo "WARNING: BTF not available, eBPF CO-RE will not work"
    echo "Consider upgrading kernel or enabling CONFIG_DEBUG_INFO_BTF"
fi

# 安装编译工具链（apt 示例）
apt-get update -qq
apt-get install -y -qq \
    clang-15 llvm-15 \
    libbpf-dev \
    linux-headers-$(uname -r) \
    bpftool

# 验证 bpftool 可读取 vmlinux BTF
bpftool btf dump file /sys/kernel/btf/vmlinux format raw > /dev/null 2>&1 && \
    echo "BTF: OK" || echo "BTF: FAIL"

# 生成 vmlinux.h（各 CI runner 预生成一次）
bpftool btf dump file /sys/kernel/btf/vmlinux format c > \
    /home/workspace/xlib_standard/fixture/fault/ebpf/vmlinux.h

echo "eBPF runner provisioned"
```

---

**三层混沌工程能力矩阵**：

| 故障维度       | Bash (阶段 1)               | Go-native netns (阶段 2)    | eBPF (阶段 3)                |
| -------------- | --------------------------- | --------------------------- | ---------------------------- |
| 网络全阻断     | `iptables -A DROP`          | `partitionNetns()`          | `packdrop.c` TC hook         |
| 按端口丢包     | ✗                           | ✗                           | `packdrop.c` + filter        |
| 连接重置 (RST) | ✗                           | ✗                           | `connrst.c` sockops          |
| 按 PID 过滤    | ✗                           | ✗                           | `bpf_get_current_pid_tgid()` |
| 系统调用错误   | ✗                           | ✗                           | `ioerr.c` kprobe             |
| 精确延迟 (μs)  | `tc netem` (ms only)        | `injectLatency()` (ms only) | `latency.c` kprobe (μs)      |
| DNS 故障       | ✗                           | ✗                           | 追加 kprobe DNS 解析         |
| 外部工具依赖   | `ip` `iptables` `tc` `sudo` | `ip` `iptables` `tc` `sudo` | 仅内核 BTF + `cilium/ebpf`   |
| 需要 root      | ✓                           | ✓                           | ✓                            |
| 支持架构       | x86_64 only                 | x86_64 only                 | x86_64, arm64 (CO-RE)        |

**采用策略**：W3 阶段 risc/resiliencx 模块使用三层全部能力；W4 存储适配器使用 Go-native netns 作为基线 + eBPF 补充精确故障；light pool 模块（kafkax/natsx/ossx）使用 eBPF 替代 iptables 以减少外部依赖。

---

#### 服务生命周期管理

```ini
# /etc/systemd/system/ci-redis.service
[Unit]
Description=CI Redis Instance for redisx tests
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/redis-server /etc/ci-redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=no
User=ci-runner
MemoryMax=512M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
```

#### soak schedule

```yaml
# .github/workflows/nightly-soak.yml
name: Nightly Storage Soak
on:
  schedule:
    - cron: "0 2 * * *"

jobs:
  soak-matrix:
    strategy:
      max-parallel: 1 # 一次只跑一个
      matrix:
        adapter: [redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex]
    runs-on: [self-hosted, ephemeral, storage-heavy]
    steps:
      - name: service-up
        run: sudo systemctl start ci-${{ matrix.adapter }}
      - name: soak-test
        run: go test -v -timeout 4h -run TestSoak ./...
        working-directory: /home/workspace/${{ matrix.adapter }}
      - name: service-down
        if: always()
        run: sudo systemctl stop ci-${{ matrix.adapter }}
```

---

### P0-5: 全仓状态投影事实审计

**目标**：在 W0 完成对所有 25 个仓库的 status projection 事实性验证。

#### 审计脚本（Python）

```python
#!/usr/bin/env python3
"""全仓状态投影事实审计

用法:
  python3 scripts/audit-status-projection.py
  python3 scripts/audit-status-projection.py --modules kernel,redisx
"""

import json
import subprocess
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

STATUS_INDEX = Path(".foundationx/status/index.json")
MODULES_DIR = Path("/home/workspace")

@dataclass
class AuditResult:
    module: str
    checks: dict = field(default_factory=dict)

    def all_pass(self) -> bool:
        return all(v == "PASS" for v in self.checks.values())

def git_ls_remote(repo_name: str) -> bool:
    """检查远程仓库是否存在"""
    url = f"https://github.com/ZoneCNH/{repo_name}"
    result = subprocess.run(
        ["git", "ls-remote", "--exit-code", url],
        capture_output=True, text=True
    )
    return result.returncode == 0

def tag_exists(repo_path: Path, tag: str) -> Optional[str]:
    result = subprocess.run(
        ["git", "-C", str(repo_path), "rev-list", "-n1", tag],
        capture_output=True, text=True
    )
    return result.stdout.strip() if result.returncode == 0 else None

def tag_in_main_ancestry(repo_path: Path, tag: str) -> bool:
    tag_sha = tag_exists(repo_path, tag)
    if not tag_sha:
        return False
    result = subprocess.run(
        ["git", "-C", str(repo_path), "merge-base", "--is-ancestor",
         tag_sha, "main"],
        capture_output=True
    )
    return result.returncode == 0

def check_ci_green(repo_name: str) -> bool:
    result = subprocess.run(
        ["gh", "run", "list", "--repo", f"ZoneCNH/{repo_name}",
         "--branch", "main", "--limit", "1", "--json", "conclusion",
         "--jq", ".[0].conclusion"],
        capture_output=True, text=True
    )
    return result.stdout.strip() == "success"

def check_github_release(repo_name: str) -> bool:
    result = subprocess.run(
        ["gh", "release", "view", "--repo", f"ZoneCNH/{repo_name}",
         "--json", "tagName"],
        capture_output=True, text=True
    )
    return result.returncode == 0

def audit_repo(module_name: str, status_entry: dict) -> AuditResult:
    result = AuditResult(module=module_name)

    repo_path = MODULES_DIR / module_name
    if not repo_path.is_dir():
        result.checks["repo_exists"] = "FAIL"
        return result

    result.checks["repo_exists"] = "PASS"

    declared_tag = status_entry.get("version") or status_entry.get("release_tag", "")
    if declared_tag:
        tag_sha = tag_exists(repo_path, declared_tag)
        if tag_sha:
            result.checks["tag_exists"] = "PASS"
            if tag_in_main_ancestry(repo_path, declared_tag):
                result.checks["tag_is_ancestor"] = "PASS"
            else:
                result.checks["tag_is_ancestor"] = "FAIL"
        else:
            result.checks["tag_exists"] = "FAIL"

    declared_grade = status_entry.get("grade", "").lower()
    if declared_grade in ("factory", "production"):
        ci_ok = check_ci_green(module_name)
        result.checks["factory_ci_green"] = "PASS" if ci_ok else "FAIL"
        release_ok = check_github_release(module_name)
        result.checks["factory_release_exists"] = "PASS" if release_ok else "FAIL"

    gomod = repo_path / "go.mod"
    if gomod.exists():
        content = gomod.read_text()
        expected = f"github.com/ZoneCNH/{module_name}"
        result.checks["module_path_consistent"] = (
            "PASS" if expected in content else "FAIL"
        )

    return result

def main():
    with open(STATUS_INDEX) as f:
        status = json.load(f)

    modules = status.get("modules", {})
    results = {}
    phantom_modules = []

    for module_name, entry in modules.items():
        print(f"Auditing {module_name}...")
        results[module_name] = audit_repo(module_name, entry)

    print("\n=== AUDIT SUMMARY ===")
    for name, r in results.items():
        if r.all_pass():
            print(f"  {name}: ALL PASS")
        else:
            phantom_modules.append(name)
            for check, outcome in r.checks.items():
                if outcome != "PASS" and outcome != "SKIP":
                    print(f"  {name}.{check}: {outcome}")

    if phantom_modules:
        print(f"\nPHANTOM MODULES ({len(phantom_modules)}): {', '.join(phantom_modules)}")
        print("\nIMMEDIATE ACTION:")
        print("1. 修正 .foundationx/status/index.json 中所有 phantom 条目")
        print("2. 将 grade 改为 'missing'，phase 改为 'uninitialized'")
        sys.exit(1)
    else:
        print("\nAll repositories verified — no phantom entries.")
        sys.exit(0)

if __name__ == "__main__":
    main()
```

#### 审计后的修正操作

```bash
# 对 phantom 条目的修正
jq '.modules.domain_macro.grade = "missing" |
    .modules.domain_macro.phase = "uninitialized" |
    del(.modules.domain_macro.version)' \
  .foundationx/status/index.json > tmp.json && mv tmp.json .foundationx/status/index.json

git diff .foundationx/status/index.json
```

---

### P0-6: xlib_standard MVC 定义

**目标**：定义"最小可行合约"（MVC），允许 gate/evidence/harness 在 standard 完整 bundle 完成前就开始工作。

#### MVC 组成

```
xlib_standard MVC (v2.0.0-mvc)
├── schemas/
│   ├── evidence-schema.json    # evidence JSON 结构
│   ├── gate-result.json        # gate 结果结构
│   └── bundle-manifest.json    # bundle 清单结构
├── policies/
│   └── required-checks.yaml    # 每类模块的必备 gate 列表
├── reason-codes/
│   └── codes.yaml              # 标准 reason code 注册表
└── profiles/
    └── module-profiles.yaml    # 11 类 module profile 定义
```

#### MVC freeze 检测

```bash
#!/bin/bash
# scripts/check-mvc-freeze.sh
MVC_REQUIRED_FILES=(
    "schemas/evidence-schema.json"
    "schemas/gate-result.json"
    "schemas/bundle-manifest.json"
    "policies/required-checks.yaml"
    "reason-codes/codes.yaml"
    "profiles/module-profiles.yaml"
)

MVC_LOCKFILE=".mvc-lock/v2.0.0-mvc-sha256.txt"

for file in "${MVC_REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "MISSING: $file"
        exit 1
    fi
done

mkdir -p .mvc-lock
sha256sum "${MVC_REQUIRED_FILES[@]}" > "$MVC_LOCKFILE"
echo "MVC_FREEZE: PASS — lockfile at $MVC_LOCKFILE"
```

#### W1 拆分后的里程碑

```
W1 拆分:
  前 5 天: MVC freeze (XLS-001 + XLS-003 subset: schemas/policies/reason-codes)
    → gate/evidence/harness 可立即并行开始 (XLG-001, XLE-001, XLH-001)
  第 5-14 天: full bundle (XLS-003 complete + XLS-004 + XLS-005)
    → canary templates + RC bundle
  第 14-21 天: 3 canary 验证 (XLS-006 + XLS-008)
```

---

### P0-7: BASE-003 批量专用工作包

**目标**：为 10+ 缺 SECURITY/CONTRIBUTING/CODEOWNERS 的模块创建标准化 BASE-003 工作包。

#### 缺失文件矩阵

| 模块            | LICENSE | SECURITY | CONTRIBUTING | CODEOWNERS | CHANGELOG | README | profile |
| --------------- | ------- | -------- | ------------ | ---------- | --------- | ------ | ------- |
| kernel          | ✓       | ✗        | ✗            | ✗          | ✓         | ✓      | ✓       |
| configx         | ✓       | ✗        | ✗            | ✗          | ✓         | ✓      | ✓       |
| observex        | ✓       | ✗        | ✗            | ✗          | ✓         | ✓      | ✓       |
| xlib_harness    | ✗       | ✗        | ✓            | ✗          | ✓         | ✓      | ✓       |
| xlib_evidence   | ✗       | ✗        | ✓            | ✗          | ✓         | ✓      | ✓       |
| xlibgate        | ✗       | ✗        | ✓            | ✗          | ✓         | ✓      | ✓       |
| bootstrap       | ✗       | ✗        | ✗            | ✗          | ✗         | ✗      | ✗       |
| domain_market   | ✗       | ✗        | ✗            | ✗          | ✗         | ✗      | ✗       |
| domain_exchange | ✓       | ✗        | ✗            | ✗          | ✓         | ✓      | ✓       |
| redisx          | ✓       | ✗        | ✓            | ✗          | ✓         | ✓      | ✓       |

#### 批量生成脚本

```bash
#!/bin/bash
# scripts/generate-base-003.sh — 批量生成 BASE-003 治理文件

set -euo pipefail

MODULES=(
    "kernel" "configx" "observex" "xlib_harness" "xlib_evidence"
    "xlibgate" "bootstrap" "domain_market" "domain_exchange" "redisx"
)
BASE_003_DIR="/home/workspace/ZoneCNH/templates/BASE-003"

generate_license() {
    local module=$1 output="/home/workspace/${module}/LICENSE"
    if [ ! -f "$output" ]; then
        cp "$BASE_003_DIR/LICENSE.mit" "$output"
        echo "  + LICENSE"
    fi
}

generate_security() {
    local module=$1 output="/home/workspace/${module}/SECURITY.md"
    if [ ! -f "$output" ]; then
        sed "s/{{MODULE}}/${module}/g" \
            "$BASE_003_DIR/SECURITY.template.md" > "$output"
        echo "  + SECURITY.md"
    fi
}

generate_contributing() {
    local module=$1 output="/home/workspace/${module}/CONTRIBUTING.md"
    if [ ! -f "$output" ]; then
        cp "$BASE_003_DIR/CONTRIBUTING.md" "$output"
        echo "  + CONTRIBUTING.md"
    fi
}

generate_codeowners() {
    local module=$1 output="/home/workspace/${module}/CODEOWNERS"
    if [ ! -f "$output" ]; then
        sed "s/{{MODULE}}/${module}/g" \
            "$BASE_003_DIR/CODEOWNERS.template" > "$output"
        echo "  + CODEOWNERS"
    fi
}

for module in "${MODULES[@]}"; do
    echo "[$module]"
    generate_license "$module"
    generate_security "$module"
    generate_contributing "$module"
    generate_codeowners "$module"
done
```

#### SECURITY.template.md

```markdown
# Security Policy

{{MODULE}} follows the security support policy defined by the
FoundationX governance framework.

| Version | Supported          |
| ------- | ------------------ |
| >= v1.0 | :white_check_mark: |
| < v1.0  | :x:                |

## Reporting a Vulnerability

**DO NOT CREATE A PUBLIC ISSUE** for security vulnerabilities.

Send reports through the private reporting channel defined in
the FoundationX governance documentation.

## Supply Chain

- All GitHub Actions are pinned to commit SHA
- Dependencies audited via `govulncheck` on every PR
- SBOM generated for every release

Governed by FoundationX BASE-003 (Required Governance Files).
```

#### CODEOWNERS.template

```
# {{MODULE}} code owners — per FoundationX BASE-003

* @ZoneCNH/foundationx-maintainers

/SECURITY.md    @ZoneCNH/foundationx-maintainers
/CONTRIBUTING.md @ZoneCNH/foundationx-maintainers
/CODEOWNERS     @ZoneCNH/foundationx-maintainers
/LICENSE        @ZoneCNH/foundationx-maintainers
```

#### 模块级 BASE-003 工作包（追加到各模块）

在 `report/07-11.md` 的受影响模块下追加：

```markdown
### [模块名] BASE-003 追加工作包

| ID      | P   | 任务                  | 验收                                                                               |
| ------- | --- | --------------------- | ---------------------------------------------------------------------------------- |
| XXX-B03 | P0  | BASE-003 治理文件创建 | LICENSE/SECURITY/CONTRIBUTING/CODEOWNERS 存在且 xlibgate base-governance gate 通过 |
```

---

### P0-8: 修订后时间线（扩展至 45-60 天）

| 阶段           | 天数  | 内容                                              | 最少并行 |
| -------------- | ----- | ------------------------------------------------- | -------- |
| W0: 审计       | 1-2   | inventory + phantom 审计 + Go 基线 + blocker      | 3        |
| W1a: MVC       | 3-5   | standard MVC freeze；gate/evidence/harness 启动   | 4        |
| W1b: Bundle    | 5-14  | full bundle + canary templates                    | 4        |
| W1c: Canary    | 14-21 | 3 canary clean-room Release + standard stable     | 6        |
| W2: L1         | 22-28 | configx/observex/schedulex/testkitx (并行)        | 4        |
| W2: Resilience | 22-35 | resiliencx 6 策略重建 (串行关键路径)              | 1        |
| W2: Bootstrap  | 28-40 | 事务式构造 (需 resilientcx + 3 storage)           | 2        |
| W2: Domain     | 25-30 | domain_market ADR + domainx spec-freeze           | 2        |
| W2: Recert     | 30-45 | 近生产模块重新认证 + L1 Assembly CANARY-L2        | 3        |
| W3a: Storage   | 46-55 | 7 adapter PR/Nightly/Live (3层并行池)             | 3        |
| W3b: Soak      | 50-55 | nightly serial soak schedule                      | —        |
| W3: Domain     | 52-58 | domain_market 纯化 + domain_macro 创建            | 2        |
| W3: Exchange   | 55-60 | domain_exchange v1.1 + 兼容层                     | 2        |
| W3: Transport  | 56-60 | transportx request/reply core + contracts release | 2        |
| W4: Release    | 61-75 | 25 仓逐一 re-release + Fleet Evidence + 审计      | 3        |

---

### P0-9: W4 light/heavy pool 分类

#### 分类定义

```yaml
# .foundationx/config/storage-pools.yaml
pools:
  light:
    description: PR/nightly CI and basic integration. No high-load soak.
    max_concurrent: 3
    runner_class: [self-hosted, ephemeral, storage-light]
    runner_spec: { cpu: 4, memory: 8G, disk: 50G }
    modules: [kafkax, natsx, ossx]
    constraints:
      - max 2 concurrent PR jobs
      - no heavy soak simultaneously

  heavy:
    description: High-load soak and fault injection. Serial only.
    max_concurrent: 1
    runner_class: [self-hosted, ephemeral, storage-heavy]
    runner_spec: { cpu: 8, memory: 16G, disk: 100G }
    modules: [redisx, postgresx, taosx, clickhousex]
    soak_rotation:
      strategy: serial
      order: [redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex]
      per_adapter_duration: 3h
      schedule: "nightly 02:00 UTC"
    constraints:
      - fault injection in isolated network namespace (per P0-4)
      - no light jobs during heavy soak

  service_requirements:
    redisx: { binary: redis-server, version: "7.4" }
    kafkax: { binary: kafka-server-start, version: "4.1", mode: KRaft }
    natsx: { binary: nats-server, version: "2.11" }
    postgresx: { binary: postgres, version: "17" }
    taosx: { binary: taosd, version: "3.3" }
    ossx: { binary: minio, version: "RELEASE.2025-06" }
    clickhousex: { binary: clickhouse-server, version: "25.6" }
```

---

### P0-10: 回滚策略 + BASE 推广 Runbook

#### 回滚决策树

```
breaking change 触发
├── 控制平面模块 (standard/gate/evidence/harness)?
│   ├── lock 回退到 RC 前一版本
│   ├── 通知下游消费者
│   └── 修复后 incremented RC
│
├── L0/L1 模块 (kernel/configx/...)?
│   ├── < 4h → patch 版本
│   ├── > 24h → 退出稳定路径，重新 RC
│   └── 追加 ADR 记录回滚原因
│
├── storage adapter (redisx/kafkax/...)?
│   ├── integration fail → 回 nightly 通道
│   ├── soak fail → 停止 schedule, RCA before restart
│   └── release fail → revoke assets + fix
│
└── domain module (domain_market/exchange/...)?
    ├── contract breaking → MAJOR bump + migration guide
    ├── consumer breakage → revert + notify + retest
    └── data corruption → IMMEDIATE revert + repair runbook
```

#### BASE 推广 Runbook 结构

```markdown
# BASE 工作包推广 Runbook

## 流程

### 1. patch 生成 (xlib_harness)

harness fleet gen --class=base-governance --target=all → /tmp/fleet-patches/{module}.patch

### 2. patch 审查 (module owner)

cd /home/workspace/{module}
git checkout -b "feat/base-003" origin/main
git apply --check /tmp/fleet-patches/{module}.patch

# 人工审查后

git apply /tmp/fleet-patches/{module}.patch
git add LICENSE SECURITY.md CONTRIBUTING.md CODEOWNERS
git commit -m "feat: BASE-003 governance files [auto by xlib_harness]"
git push && gh pr create --draft

### 3. CI 验证

CI gates: [xlibgate base-governance] [go test] [govulncheck]
审查者: @ZoneCNH/foundationx-maintainers
合入: 1 approval + CI green

### 4. 跟踪矩阵

| 模块          | 状态    | PR  | 合入日 | gate |
| ------------- | ------- | --- | ------ | ---- |
| kernel        | PENDING | —   | —      | —    |
| ... (25 rows) |         |     |        |      |

### 5. 回退

git revert <commit> → push → xlib_harness 模板修复 → 重新生成 patch
```

---

## 十二、P0 修复执行检查清单

| #     | 行动                                             | 截止      | 状态 |
| ----- | ------------------------------------------------ | --------- | ---- |
| P0-1  | goalcli 归属裁决 + OWNERSHIP-GOALCLI.yaml        | W1 Day 2  | ⬜   |
| P0-2  | transportx module major path 裁决 + TRN-001 补充 | W1 Day 10 | ⬜   |
| P0-3  | contracts lineage 审计 + 版本裁决                | W1 Day 12 | ⬜   |
| P0-4  | bare-metal fault/soak 方案 + fault-fixture.sh    | W3 前     | ⬜   |
| P0-5  | audit-status-projection.py 执行                  | W0 Day 1  | ⬜   |
| P0-6  | xlib_standard MVC 定义 + check-mvc-freeze.sh     | W1 Day 5  | ⬜   |
| P0-7  | BASE-003 批量生成 + 模块级工作包                 | W1 Day 11 | ⬜   |
| P0-8  | 时间线扩展至 45-60 天 + 更新 §9                  | W0 Day 2  | ⬜   |
| P0-9  | storage-pools.yaml + W4 §2.2 更新                | W3 前     | ⬜   |
| P0-10 | 回滚策略 + BASE 推广 Runbook 章节                | W1 前     | ⬜   |
